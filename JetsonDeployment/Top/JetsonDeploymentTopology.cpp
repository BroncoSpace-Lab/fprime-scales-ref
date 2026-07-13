// ======================================================================
// \title  JetsonDeploymentTopology.cpp
// \brief cpp file containing the topology instantiation code
//
// ======================================================================

// Provides access to autocoded functions
#include <JetsonDeployment/Top/JetsonDeploymentTopologyAc.hpp>
#include <Svc/FrameAccumulator/FrameDetector/FprimeFrameDetector.hpp>

// fprime-python includes
#include <pybind11/pybind11.h>

// Necessary project-specified types
#include <Fw/Logger/Logger.hpp>
#include <Fw/Types/MallocAllocator.hpp>
#include <Os/Task.hpp>

#include <cstdio>
#include <cstring>

namespace JetsonDeployment {

// Instantiate a malloc allocator for cmdSeq buffer allocation
Fw::MallocAllocator mallocator;

// The reference topology divides the incoming clock signal (1Hz) into sub-signals: 1Hz, 1/2Hz, and 1/4Hz with 0 offset
Svc::RateGroupDriver::DividerSet rateGroupDivisorsSet{{{1, 0}, {2, 0}, {4, 0}}};

// Rate groups may supply a context token to each of the attached children whose purpose is set by the project. The
// reference topology sets each token to zero as these contexts are unused in this project.
U32 rateGroup1Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};
U32 rateGroup2Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};
U32 rateGroup3Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};

const char* IMX_HUB_IP_ADDRESS = "10.3.2.10";
const U32 IMX_HUB_PORT = 50500;
const U32 JETSON_HUB_PORT = 50501;

Svc::FrameDetectors::FprimeFrameDetector hubFrameDetector;

enum TopologyConstants {
    COMM_PRIORITY = 34,
    HUB_PACKET_BUFFER_SIZE = 2048,
    HUB_PACKET_BUFFER_COUNT = 256,
    HUB_BUFFER_SIZE = 64 * 1024,
    HUB_UDP_RECEIVE_SIZE = 65507,
    HUB_IO_BUFFER_COUNT = 8,
    HUB_CONNECT_WAIT_ATTEMPTS = 100,
    HUB_CONNECT_WAIT_USEC = 50000
};

bool isComDriverConnected(const TopologyState& state) {
    return state.hostname != nullptr &&
           state.hostname[0] != '\0' &&
           state.port != 0;
}

bool waitForHubReady() {
    for (U32 attempt = 0; attempt < HUB_CONNECT_WAIT_ATTEMPTS; ++attempt) {
        if (jetson_hubComDriver.isOpened()) {
            // Give the UDP ready port time to mark the adapter ready.
            (void)Os::Task::delay(Fw::TimeInterval(0, 10000));
            return true;
        }
        (void)Os::Task::delay(Fw::TimeInterval(0, HUB_CONNECT_WAIT_USEC));
    }
    return false;
}

/**
 * \brief configure/setup components in project-specific way
 *
 * This is a *helper* function which configures/sets up each component requiring project specific input. This includes
 * allocating resources, passing-in arguments, etc. This function may be inlined into the topology setup function if
 * desired, but is extracted here for clarity.
 */
void configureTopology() {
    // Rate group driver needs a divisor list
    jetson_rateGroupDriver.configure(rateGroupDivisorsSet);

    // Rate groups require context arrays.
    jetson_rateGroup1.configure(rateGroup1Context, FW_NUM_ARRAY_ELEMENTS(rateGroup1Context));
    jetson_rateGroup2.configure(rateGroup2Context, FW_NUM_ARRAY_ELEMENTS(rateGroup2Context));
    jetson_rateGroup3.configure(rateGroup3Context, FW_NUM_ARRAY_ELEMENTS(rateGroup3Context));

    // Command sequencer needs to allocate memory to hold contents of command sequences
    jetson_cmdSeq.allocateBuffer(0, mallocator, 5 * 1024);

    Svc::BufferManager::BufferBins hubPacketBins;
    memset(&hubPacketBins, 0, sizeof(hubPacketBins));

    // Deframed hub records can be retained by asynchronous consumers. Size
    // this pool above the ComQueue active and file queue depths.
    hubPacketBins.bins[0].bufferSize = HUB_PACKET_BUFFER_SIZE;
    hubPacketBins.bins[0].numBuffers = HUB_PACKET_BUFFER_COUNT;
    jetson_hubBufferManager.setup(201, 0, mallocator, hubPacketBins);

    Svc::BufferManager::BufferBins hubIoBins;
    memset(&hubIoBins, 0, sizeof(hubIoBins));
    hubIoBins.bins[0].bufferSize = HUB_BUFFER_SIZE;
    hubIoBins.bins[0].numBuffers = HUB_IO_BUFFER_COUNT;
    jetson_hubIoBufferManager.setup(202, 0, mallocator, hubIoBins);
    jetson_hubFrameAccumulator.configure(hubFrameDetector, 2, mallocator, HUB_BUFFER_SIZE);

    Os::File::Status jetson_gpio_status = jetson_gpioWatchdogDriver.open("/dev/gpiochip0", 108, Drv::LinuxGpioDriver::GpioConfiguration::GPIO_OUTPUT);
    if (jetson_gpio_status != Os::File::Status::OP_OK) {
        Fw::Logger::log("[ERROR] Failed to open GPIO pin: %d\n", jetson_gpio_status);
    }
}

void setupTopology(const TopologyState& state) {
    initComponents(state);
    setBaseIds();
    connectComponents();
    regCommands();
    configComponents(state);

    if (isComDriverConnected(state)) {
        jetson_comDriver.configure(state.hostname, state.port);
    }

    configureTopology();

    // Start comm drivers before active tasks begin producing traffic.
    // This reduces early hub drops logged as ByteStreamAdapter DriverNotReady.
    if (isComDriverConnected(state)) {
        Os::TaskString name("ReceiveTask");
        jetson_comDriver.start(name, COMM_PRIORITY, Default::STACK_SIZE);
    }

    // Use UDP for the GenericHub transport so each hub buffer is received as
    // one datagram. Raw TCP is a byte stream and can split/coalesce hub records.
    jetson_hubComDriver.configureRecv("0.0.0.0", JETSON_HUB_PORT, HUB_UDP_RECEIVE_SIZE);
    jetson_hubComDriver.configureSend(IMX_HUB_IP_ADDRESS, IMX_HUB_PORT);

    Os::TaskString hubName("hub");
    jetson_hubComDriver.start(hubName, COMM_PRIORITY, Default::STACK_SIZE);
    if (!waitForHubReady()) {
        Fw::Logger::log(
            "[WARNING] Jetson hub UDP driver did not open before startup traffic began. Remote=%s:%u local=%u\n",
            IMX_HUB_IP_ADDRESS,
            static_cast<unsigned>(IMX_HUB_PORT),
            static_cast<unsigned>(JETSON_HUB_PORT)
        );
    }

    loadParameters();
    startTasks(state);
}

void startRateGroups(const Fw::TimeInterval& interval) {
    jetson_timer.startTimer(interval);
}

void stopRateGroups() {
    jetson_timer.quit();
}

void teardownTopology(const TopologyState& state) {
    stopTasks(state);
    freeThreads(state);

    jetson_comDriver.terminate();
    jetson_comDriver.stop();
    (void)jetson_comDriver.join();

    jetson_hubComDriver.stop();
    (void)jetson_hubComDriver.join();

    jetson_cmdSeq.deallocateBuffer(mallocator);
    jetson_hubFrameAccumulator.cleanup();
    jetson_hubIoBufferManager.cleanup();
    jetson_hubBufferManager.cleanup();

    tearDownComponents(state);
    deinitComponents(state);
}

}  // namespace JetsonDeployment

void setup_user_deployment(pybind11::module_& module) {
    pybind11::class_<JetsonDeployment::TopologyState>(module, "TopologyState")
        .def(pybind11::init<>())
        .def_readwrite("hostname", &JetsonDeployment::TopologyState::hostname)
        .def_readwrite("port", &JetsonDeployment::TopologyState::port);

    pybind11::module_ jetsonDeploymentModule =
        module.attr("JetsonDeployment").cast<pybind11::module_>();

    jetsonDeploymentModule.def("setup_custom", [](JetsonDeployment::TopologyState& state) {
        std::printf(
            "DEBUG setup_custom: hostname=%s port=%u\n",
            (state.hostname == nullptr || state.hostname[0] == '\0') ? "<empty>" : state.hostname,
            static_cast<unsigned>(state.port)
        );
        std::fflush(stdout);

        JetsonDeployment::setupTopology(state);
    });

    jetsonDeploymentModule.def("is_com_driver_connected_custom", [](JetsonDeployment::TopologyState& state) {
        return JetsonDeployment::isComDriverConnected(state);
    });

    jetsonDeploymentModule.def(
        "start_rate_groups_custom",
        []() {
            JetsonDeployment::startRateGroups(Fw::TimeInterval(1, 0));
        },
        pybind11::call_guard<pybind11::gil_scoped_release>()
    );

    jetsonDeploymentModule.def("stop_rate_groups_custom", []() {
        JetsonDeployment::stopRateGroups();
    });

    jetsonDeploymentModule.def("teardown_custom", [](JetsonDeployment::TopologyState& state) {
        std::printf("DEBUG teardown_custom: requested\n");
        std::fflush(stdout);

        JetsonDeployment::teardownTopology(state);
    });
}
