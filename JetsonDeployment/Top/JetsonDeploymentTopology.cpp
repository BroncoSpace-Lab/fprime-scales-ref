// ======================================================================
// \title  JetsonDeploymentTopology.cpp
// \brief cpp file containing the topology instantiation code
//
// ======================================================================
// Provides access to autocoded functions
#include <JetsonDeployment/Top/JetsonDeploymentTopologyAc.hpp>
// Note: Uncomment when using Svc:TlmPacketizer
//#include <JetsonDeployment/Top/JetsonDeploymentPacketsAc.hpp>
#include <pybind11/pybind11.h> // fprime-python includes

// Necessary project-specified types
#include <Fw/Types/MallocAllocator.hpp>
#include <Fw/Logger/Logger.hpp>
#include <string>

static std::string topology_hostname_storage;
// Public functions for use in main program are namespaced with deployment module JetsonDeployment
// This is also the namespace where the topology components are instantiated by FPP.
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

enum TopologyConstants {
    COMM_PRIORITY = 34,
};

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

    Os::File::Status jetson_gpio_status = jetson_gpioWatchdogDriver.open("/dev/gpiochip0", 85, Drv::LinuxGpioDriver::GpioConfiguration::GPIO_OUTPUT);
    if (jetson_gpio_status != Os::File::Status::OP_OK) {
        Fw::Logger::log("[ERROR] Failed to open GPIO pin: %d\n", jetson_gpio_status);
    }
}

void setupTopology(const TopologyState& state) {
    // Autocoded initialization. Function provided by autocoder.
    initComponents(state);
    // Autocoded id setup. Function provided by autocoder.
    setBaseIds();
    // Autocoded connection wiring. Function provided by autocoder.
    connectComponents();
    // Autocoded command registration. Function provided by autocoder.
    regCommands();
    // Autocoded configuration. Function provided by autocoder.
    configComponents(state);
    if (state.hostname != nullptr && state.port != 0) {
        jetson_comDriver.configure(state.hostname, state.port);
    }
    // Project-specific component configuration. Function provided above. May be inlined, if desired.
    configureTopology();
    // Autocoded parameter loading. Function provided by autocoder.
    loadParameters();
    // Autocoded task kick-off (active components). Function provided by autocoder.
    startTasks(state);
    // Initialize socket communication if and only if there is a valid specification
    if (state.hostname != nullptr && state.port != 0) {
        Os::TaskString name("ReceiveTask");
        // Uplink is configured for receive so a socket task is started
        jetson_comDriver.start(name, COMM_PRIORITY, Default::STACK_SIZE);
    }
}

void startRateGroups(const Fw::TimeInterval& interval) {
    // The timer component drives the fundamental tick rate of the system.
    // Svc::RateGroupDriver will divide this down to the slower rate groups.
    // This call will block until the stopRateGroups() call is made.
    // For this Linux demo, that call is made from a signal handler.
    jetson_timer.startTimer(interval);
}

void stopRateGroups() {
    jetson_timer.quit();
}

void teardownTopology(const TopologyState& state) {
    // Autocoded (active component) task clean-up. Functions provided by topology autocoder.
    stopTasks(state);
    freeThreads(state);

    // Other task clean-up.
    jetson_comDriver.terminate();
    jetson_comDriver.stop();
    (void)jetson_comDriver.join();

    // Resource deallocation
    jetson_cmdSeq.deallocateBuffer(mallocator);

    tearDownComponents(state);
    deinitComponents(state);
}
};  // namespace JetsonDeployment

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
        JetsonDeployment::teardownTopology(state);
    });
}