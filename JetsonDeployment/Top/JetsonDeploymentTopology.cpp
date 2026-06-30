// ======================================================================
// \title  JetsonDeploymentTopology.cpp
// \brief cpp file containing the topology instantiation code
//
// ======================================================================

// Provides access to autocoded functions
#include <JetsonDeployment/Top/JetsonDeploymentTopologyAc.hpp>
#include <Svc/FprimeProtocol/FrameHeaderSerializableAc.hpp>
#include <Svc/FprimeProtocol/FrameTrailerSerializableAc.hpp>

// fprime-python includes
#include <pybind11/pybind11.h>

// Necessary project-specified types
#include <Fw/Logger/Logger.hpp>
#include <Fw/Types/MallocAllocator.hpp>

#include <cstdio>
#include <string>

static std::string topology_hostname_storage;

// Allows easy reference to objects in FPP/autocoder required namespaces
namespace JetsonDeployment {

// The reference topology uses a malloc-based allocator for components that need memory during topology setup.
Fw::MallocAllocator mallocator;

const char* REMOTE_HUB_IP_ADDRESS = "10.3.2.10";  // IP of IMX
const U16 REMOTE_HUB_SEND_PORT = 50500;
const U16 REMOTE_HUB_RECV_PORT = 50501;

// The reference topology divides the incoming clock signal into sub-signals:
// 1Hz, 1/2Hz, and 1/4Hz with 0 offset.
Svc::RateGroupDriver::DividerSet rateGroupDivisorsSet{{{1, 0}, {2, 0}, {4, 0}}};

// Rate groups may supply a context token to each attached child.
U32 rateGroup1Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};
U32 rateGroup2Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};
U32 rateGroup3Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};

// Track whether we started the C++ timer.
static bool rateGroupsStarted = false;

// Constants needed for construction/configuration of the topology.
enum TopologyConstants {
    CMD_SEQ_BUFFER_SIZE = 5 * 1024,
    FILE_DOWNLINK_TIMEOUT = 1000,
    FILE_DOWNLINK_COOLDOWN = 1000,
    FILE_DOWNLINK_CYCLE_TIME = 1000,
    FILE_DOWNLINK_FILE_QUEUE_DEPTH = 10,
    HEALTH_WATCHDOG_CODE = 0x123,
    COMM_PRIORITY = 100,
    FRAME_ACCUMULATOR_BUFFER_SIZE = 2048,

    // Buffer manager constants
    FRAMER_BUFFER_SIZE = FW_MAX(FW_COM_BUFFER_MAX_SIZE, FW_FILE_BUFFER_MAX_SIZE + sizeof(U32)) +
                         Svc::FprimeProtocol::FrameHeader::SERIALIZED_SIZE +
                         Svc::FprimeProtocol::FrameTrailer::SERIALIZED_SIZE,
    HUB_DRIVER_BUFFER_SIZE = FRAMER_BUFFER_SIZE,
    FRAMER_BUFFER_COUNT = 30,
    DEFRAMER_BUFFER_SIZE = FW_MAX(FW_COM_BUFFER_MAX_SIZE, FW_FILE_BUFFER_MAX_SIZE + sizeof(U32)),
    DEFRAMER_BUFFER_COUNT = 30,
    COM_DRIVER_BUFFER_SIZE = 3000,
    COM_DRIVER_BUFFER_COUNT = 30,
    BUFFER_MANAGER_ID = 200
};

/**
 * \brief configure/setup components in project-specific way
 *
 * This helper configures project-specific resources such as rate groups,
 * command sequencer memory, and GPIO drivers.
 */
void configureTopology(const TopologyState& state) {
    (void)state;

    std::printf("DEBUG configureTopology: enter\n");
    std::fflush(stdout);

    // Rate group driver needs a divisor list.
    rateGroupDriver.configure(rateGroupDivisorsSet);

    // Rate groups require context arrays.
    rateGroup1.configure(rateGroup1Context, FW_NUM_ARRAY_ELEMENTS(rateGroup1Context));
    rateGroup2.configure(rateGroup2Context, FW_NUM_ARRAY_ELEMENTS(rateGroup2Context));
    rateGroup3.configure(rateGroup3Context, FW_NUM_ARRAY_ELEMENTS(rateGroup3Context));

    // Command sequencer needs memory for command sequences.
    cmdSeq.allocateBuffer(0, mallocator, CMD_SEQ_BUFFER_SIZE);

    // Hardware manager definitions.
    Os::File::Status jetson_gpio_status =
        gpioWatchdogDriver.open(
            "/dev/gpiochip0",
            112,
            Drv::LinuxGpioDriver::GpioConfiguration::GPIO_OUTPUT
        );

    if (jetson_gpio_status != Os::File::Status::OP_OK) {
        Fw::Logger::log("[ERROR] Failed to open GPIO pin: %d\n", jetson_gpio_status);
    }

    std::printf("DEBUG configureTopology: complete\n");
    std::fflush(stdout);
}

/**
 * \brief Native C++ timer driver.
 *
 * This deployment now uses a C++ timer to drive C++ rate groups.
 *
 * Required instances.fpp setting:
 *
 *   instance timer: Svc.LinuxTimer ...
 *
 * Flow:
 *
 *   timer.CycleOut
 *     -> rateGroupDriver.CycleIn
 *     -> rateGroup1/rateGroup2/rateGroup3
 *     -> CdhCore.tlmSend.Run, ComCcsds.comQueue.run, managers, etc.
 */
void startRateGroups(const Fw::TimeInterval& interval) {
    if (rateGroupsStarted) {
        std::printf("DEBUG startRateGroups: already started; skipping\n");
        std::fflush(stdout);
        return;
    }

    std::printf(
        "DEBUG startRateGroups: starting C++ timer interval=%u sec %u usec\n",
        static_cast<unsigned>(interval.getSeconds()),
        static_cast<unsigned>(interval.getUSeconds())
    );
    std::fflush(stdout);

    timer.startTimer(interval);
    rateGroupsStarted = true;

    std::printf("DEBUG startRateGroups: C++ timer started\n");
    std::fflush(stdout);
}

void stopRateGroups() {
    if (!rateGroupsStarted) {
        std::printf("DEBUG stopRateGroups: timer was not started; skipping\n");
        std::fflush(stdout);
        return;
    }

    std::printf("DEBUG stopRateGroups: quitting C++ timer\n");
    std::fflush(stdout);

    timer.quit();
    rateGroupsStarted = false;

    std::printf("DEBUG stopRateGroups: C++ timer stopped\n");
    std::fflush(stdout);
}

/**
 * \brief Setup the JetsonDeployment topology.
 *
 * This is called by both:
 *   - the native C++ binary path
 *   - the fprime-python setup_custom(...) binding below
 */
void setupTopology(const TopologyState& state) {
    std::printf(
        "DEBUG setupTopology: enter hostname=%s port=%u\n",
        state.hostname == nullptr ? "<null>" : state.hostname,
        static_cast<unsigned>(state.port)
    );
    std::fflush(stdout);

    // Autocoded initialization.
    std::printf("DEBUG setupTopology: before initComponents\n");
    std::fflush(stdout);
    initComponents(state);

    // Autocoded ID setup.
    std::printf("DEBUG setupTopology: before setBaseIds\n");
    std::fflush(stdout);
    setBaseIds();

    // Autocoded connection wiring.
    std::printf("DEBUG setupTopology: before connectComponents\n");
    std::fflush(stdout);
    connectComponents();

    // Autocoded configuration from imported subtopologies.
    std::printf("DEBUG setupTopology: before configComponents\n");
    std::fflush(stdout);
    configComponents(state);

    // Configure the TCP server/listening driver before start().
    if (state.hostname != nullptr && state.port != 0) {
        std::printf(
            "DEBUG setupTopology: comDriver.configure hostname=%s port=%u\n",
            state.hostname,
            static_cast<unsigned>(state.port)
        );
        std::fflush(stdout);

        comDriver.configure(state.hostname, state.port);

        std::printf("DEBUG setupTopology: comDriver.configure complete\n");
        std::fflush(stdout);
    } else {
        std::printf(
            "DEBUG setupTopology: comDriver.configure skipped hostname=%s port=%u\n",
            state.hostname == nullptr ? "<null>" : state.hostname,
            static_cast<unsigned>(state.port)
        );
        std::fflush(stdout);
    }

    // Deployment-specific component configuration.
    std::printf("DEBUG setupTopology: before configureTopology\n");
    std::fflush(stdout);
    configureTopology(state);

    // Autocoded command registration.
    std::printf("DEBUG setupTopology: before regCommands\n");
    std::fflush(stdout);
    regCommands();

    // Autocoded parameter loading.
    std::printf("DEBUG setupTopology: before loadParameters\n");
    std::fflush(stdout);
    loadParameters();

    // Autocoded task kick-off for active components.
    std::printf("DEBUG setupTopology: before startTasks\n");
    std::fflush(stdout);
    startTasks(state);

    // Start the C++ timer after active component tasks are running.
    // This is what actually drives:
    //
    //   timer.CycleOut -> rateGroupDriver.CycleIn
    //
    // Without this, RateGroupStarted can appear, but rate group member
    // handlers such as WatchdogManager::run_handler will never fire.
    std::printf("DEBUG setupTopology: before startRateGroups\n");
    std::fflush(stdout);
    startRateGroups(Fw::TimeInterval(1, 0));
    std::printf("DEBUG setupTopology: after startRateGroups\n");
    std::fflush(stdout);

    // Start the TCP receive task if hostname/port were supplied.
    if (state.hostname != nullptr && state.port != 0) {
        Os::TaskString name("ReceiveTask");

        std::printf("DEBUG setupTopology: before comDriver.start\n");
        std::fflush(stdout);

        comDriver.start(name, COMM_PRIORITY, Default::STACK_SIZE);

        std::printf("DEBUG setupTopology: comDriver.start returned\n");
        std::fflush(stdout);
    } else {
        std::printf(
            "DEBUG setupTopology: comDriver.start skipped hostname=%s port=%u\n",
            state.hostname == nullptr ? "<null>" : state.hostname,
            static_cast<unsigned>(state.port)
        );
        std::fflush(stdout);
    }

    // Hub communication path currently disabled.
    // jetson_hubComDriver.configureSend(REMOTE_HUB_IP_ADDRESS, REMOTE_HUB_SEND_PORT);
    // jetson_hubComDriver.configureRecv("0.0.0.0", REMOTE_HUB_RECV_PORT, HUB_DRIVER_BUFFER_SIZE);
    // Os::TaskString hubName("hub");
    // jetson_hubComDriver.start(hubName, COMM_PRIORITY, Default::STACK_SIZE);

    std::printf("DEBUG setupTopology: complete\n");
    std::fflush(stdout);
}

void teardownTopology(const TopologyState& state) {
    std::printf("DEBUG teardownTopology: enter\n");
    std::fflush(stdout);

    // Stop the timer first so no new rate group cycles are queued while
    // tasks are being stopped.
    stopRateGroups();

    stopTasks(state);
    freeThreads(state);

    comDriver.stop();
    (void)comDriver.join();

    cmdSeq.deallocateBuffer(mallocator);

    tearDownComponents(state);
    deinitComponents(state);

    std::printf("DEBUG teardownTopology: complete\n");
    std::fflush(stdout);
}

}  // namespace JetsonDeployment

/**
 * \brief Custom fprime-python bindings for JetsonDeployment.
 *
 * Keep this minimal:
 *   - expose TopologyState safely
 *   - expose setup_custom(...)
 *   - expose teardown_custom(...)
 *
 * Python should only launch and keep the process alive.
 * The C++ timer now drives the rate groups.
 */
void setup_user_deployment(pybind11::module_& module) {
    pybind11::class_<JetsonDeployment::TopologyState>(module, "TopologyState")
        .def(pybind11::init<>())
        .def_property(
            "hostname",
            [](const JetsonDeployment::TopologyState& state) {
                return state.hostname == nullptr ? "" : state.hostname;
            },
            [](JetsonDeployment::TopologyState& state, const std::string& hostname) {
                topology_hostname_storage = hostname;
                state.hostname = topology_hostname_storage.c_str();
            }
        )
        .def_readwrite("port", &JetsonDeployment::TopologyState::port);

    pybind11::module_ jetsonDeploymentModule =
        module.attr("JetsonDeployment").cast<pybind11::module_>();

    jetsonDeploymentModule.def("setup_custom", [](JetsonDeployment::TopologyState& state) {
        std::printf(
            "DEBUG setup_custom: hostname=%s port=%u\n",
            state.hostname == nullptr ? "<null>" : state.hostname,
            static_cast<unsigned>(state.port)
        );
        std::fflush(stdout);

        JetsonDeployment::setupTopology(state);
    });

    jetsonDeploymentModule.def("teardown_custom", [](JetsonDeployment::TopologyState& state) {
        std::printf("DEBUG teardown_custom: requested\n");
        std::fflush(stdout);

        JetsonDeployment::teardownTopology(state);
    });
}