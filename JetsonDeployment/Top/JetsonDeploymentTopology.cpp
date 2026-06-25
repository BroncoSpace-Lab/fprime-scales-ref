// ======================================================================
// \title  JetsonDeploymentTopology.cpp
// \brief cpp file containing the topology instantiation code
//
// ======================================================================

// Provides access to autocoded functions
#include <JetsonDeployment/Top/JetsonDeploymentTopologyAc.hpp>
#include <Svc/FrameAccumulator/FrameDetector/FprimeFrameDetector.hpp>
#include <Svc/FprimeProtocol/FrameHeaderSerializableAc.hpp>
#include <Svc/FprimeProtocol/FrameTrailerSerializableAc.hpp>
// fprime-python includes
#include <pybind11/pybind11.h>

// Note: Uncomment when using Svc:TlmPacketizer
//#include <JetsonDeployment/Top/JetsonDeploymentPacketsAc.hpp>

// Necessary project-specified types
#include <Fw/Types/MallocAllocator.hpp>
#include <Fw/Logger/Logger.hpp>

// Allows easy reference to objects in FPP/autocoder required namespaces
using namespace JetsonDeployment;

// The reference topology uses a malloc-based allocator for components that need to allocate memory during the
// initialization phase.
Fw::MallocAllocator mallocator;

// FrameAccumulator uses this detector to identify complete F Prime frames in the receive byte stream.
Svc::FrameDetectors::FprimeFrameDetector jetson_frameDetector;
Svc::ComQueue::QueueConfigurationTable configurationTable;

// Hub pattern disabled/commented out
// Svc::FrameDetectors::FprimeFrameDetector hub_frameDetector;

// Hub pattern disabled/commented out
// const char* REMOTE_HUIP_ADDRESS = "10.3.2.10"; // ip of JPL IMX
// const char* REMOTE_HUIP_ADDRESS = "10.3.2.6"; // ip of CPP IMX
// const U32 REMOTE_HUPORT = 50500;

// The reference topology divides the incoming clock signal (1Hz) into sub-signals: 1Hz, 1/2Hz, and 1/4Hz with 0 offset
Svc::RateGroupDriver::DividerSet rateGroupDivisorsSet{{{1, 0}, {2, 0}, {4, 0}}};

// Rate groups may supply a context token to each of the attached children whose purpose is set by the project. The
// reference topology sets each token to zero as these contexts are unused in this project.
U32 rateGroup1Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};
U32 rateGroup2Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};
U32 rateGroup3Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};

// A number of constants are needed for construction of the topology. These are specified here.
enum TopologyConstants {
    CMD_SEQ_BUFFER_SIZE = 5 * 1024,
    FILE_DOWNLINK_TIMEOUT = 1000,
    FILE_DOWNLINK_COOLDOWN = 1000,
    FILE_DOWNLINK_CYCLE_TIME = 1000,
    FILE_DOWNLINK_FILE_QUEUE_DEPTH = 10,
    HEALTH_WATCHDOG_CODE = 0x123,
    COMM_PRIORITY = 100,
    FRAME_ACCUMULATOR_BUFFER_SIZE = 2048,

    // bufferManager constants
    FRAMER_BUFFER_SIZE = FW_MAX(FW_COM_BUFFER_MAX_SIZE, FW_FILE_BUFFER_MAX_SIZE + sizeof(U32)) +
                         Svc::FprimeProtocol::FrameHeader::SERIALIZED_SIZE +
                         Svc::FprimeProtocol::FrameTrailer::SERIALIZED_SIZE,
    FRAMER_BUFFER_COUNT = 30,
    DEFRAMER_BUFFER_SIZE = FW_MAX(FW_COM_BUFFER_MAX_SIZE, FW_FILE_BUFFER_MAX_SIZE + sizeof(U32)),
    DEFRAMER_BUFFER_COUNT = 30,
    COM_DRIVER_BUFFER_SIZE = 3000,
    COM_DRIVER_BUFFER_COUNT = 30,
    BUFFER_MANAGER_ID = 200
};

// Ping entries are autocoded, however; this code is not properly exported. Thus, it is copied here.
Svc::Health::PingEntry pingEntries[] = {
    {PingEntries::JetsonDeployment_jetson_blockDrv::WARN, PingEntries::JetsonDeployment_jetson_blockDrv::FATAL, "jetson_blockDrv"},
    {PingEntries::JetsonDeployment_jetson_tlmSend::WARN, PingEntries::JetsonDeployment_jetson_tlmSend::FATAL, "jetson_chanTlm"},
    {PingEntries::JetsonDeployment_jetson_cmdDisp::WARN, PingEntries::JetsonDeployment_jetson_cmdDisp::FATAL, "jetson_cmdDisp"},
    {PingEntries::JetsonDeployment_jetson_cmdSeq::WARN, PingEntries::JetsonDeployment_jetson_cmdSeq::FATAL, "jetson_cmdSeq"},
    {PingEntries::JetsonDeployment_jetson_eventLogger::WARN, PingEntries::JetsonDeployment_jetson_eventLogger::FATAL, "jetson_eventLogger"},
    {PingEntries::JetsonDeployment_jetson_fileDownlink::WARN, PingEntries::JetsonDeployment_jetson_fileDownlink::FATAL, "jetson_fileDownlink"},
    {PingEntries::JetsonDeployment_jetson_fileManager::WARN, PingEntries::JetsonDeployment_jetson_fileManager::FATAL, "jetson_fileManager"},
    {PingEntries::JetsonDeployment_jetson_fileUplink::WARN, PingEntries::JetsonDeployment_jetson_fileUplink::FATAL, "jetson_fileUplink"},
    {PingEntries::JetsonDeployment_jetson_prmDb::WARN, PingEntries::JetsonDeployment_jetson_prmDb::FATAL, "jetson_prmDb"},
    {PingEntries::JetsonDeployment_jetson_rateGroup1::WARN, PingEntries::JetsonDeployment_jetson_rateGroup1::FATAL, "jetson_rateGroup1"},
    {PingEntries::JetsonDeployment_jetson_rateGroup2::WARN, PingEntries::JetsonDeployment_jetson_rateGroup2::FATAL, "jetson_rateGroup2"},
    {PingEntries::JetsonDeployment_jetson_rateGroup3::WARN, PingEntries::JetsonDeployment_jetson_rateGroup3::FATAL, "jetson_rateGroup3"},
};

/**
 * \brief configure/setup components in project-specific way
 *
 * This is a *helper* function which configures/sets up each component requiring project specific input. This includes
 * allocating resources, passing-in arguments, etc. This function may be inlined into the topology setup function if
 * desired, but is extracted here for clarity.
 */
void configureTopology(const TopologyState& state) {
    // Buffer managers need a configured set of buckets and an allocator used to allocate memory for those buckets.
    Svc::BufferManager::BufferBins upBuffMgrBins;
    memset(&upBuffMgrBins, 0, sizeof(upBuffMgrBins));
    upBuffMgrBins.bins[0].bufferSize = FRAMER_BUFFER_SIZE;
    upBuffMgrBins.bins[0].numBuffers = FRAMER_BUFFER_COUNT;
    upBuffMgrBins.bins[1].bufferSize = DEFRAMER_BUFFER_SIZE;
    upBuffMgrBins.bins[1].numBuffers = DEFRAMER_BUFFER_COUNT;
    upBuffMgrBins.bins[2].bufferSize = COM_DRIVER_BUFFER_SIZE;
    upBuffMgrBins.bins[2].numBuffers = COM_DRIVER_BUFFER_COUNT;
    jetson_bufferManager.setup(BUFFER_MANAGER_ID, 0, mallocator, upBuffMgrBins);

    // FrameAccumulator needs a frame detector and working buffer.
    jetson_frameAccumulator.configure(jetson_frameDetector, 1, mallocator, FRAME_ACCUMULATOR_BUFFER_SIZE);

    // Hub pattern disabled/commented out
    // hub_frameAccumulator.configure(hub_frameDetector, 2, mallocator, FRAME_ACCUMULATOR_BUFFER_SIZE);

    // Command sequencer needs to allocate memory to hold contents of command sequences
    jetson_cmdSeq.allocateBuffer(0, mallocator, CMD_SEQ_BUFFER_SIZE);

    // Rate group driver needs a divisor list
    jetson_rateGroupDriver.configure(rateGroupDivisorsSet);

    // Rate groups require context arrays.
    jetson_rateGroup1.configure(rateGroup1Context, FW_NUM_ARRAY_ELEMENTS(rateGroup1Context));
    jetson_rateGroup2.configure(rateGroup2Context, FW_NUM_ARRAY_ELEMENTS(rateGroup2Context));
    jetson_rateGroup3.configure(rateGroup3Context, FW_NUM_ARRAY_ELEMENTS(rateGroup3Context));

    // File downlink requires some project-derived properties.
    jetson_fileDownlink.configure(FILE_DOWNLINK_TIMEOUT, FILE_DOWNLINK_COOLDOWN, FILE_DOWNLINK_FILE_QUEUE_DEPTH);

    // Parameter database is configured with a database file name, and that file must be initially read.
    jetson_prmDb.configure("PrmDb.dat");
    jetson_prmDb.readParamFile();

    // Health is supplied a set of ping entires.
    jetson_health.setPingEntries(pingEntries, FW_NUM_ARRAY_ELEMENTS(pingEntries), HEALTH_WATCHDOG_CODE);

    // Note: Uncomment when using Svc:TlmPacketizer
    // tlmSend.setPacketList(JetsonDeploymentPacketsPkts, JetsonDeploymentPacketsIgnore, 1);

    // Events (highest-priority)
    configurationTable.entries[0] = {.depth = 100, .priority = 0};
    // Telemetry
    configurationTable.entries[1] = {.depth = 500, .priority = 2};
    // File Downlink
    configurationTable.entries[2] = {.depth = 100, .priority = 1};

    // Allocation identifier is 0 as the MallocAllocator discards it
    jetson_comQueue.configure(configurationTable, 0, mallocator);
    if (state.hostname != nullptr && state.port != 0) {
        jetson_comDriver.configure(state.hostname, state.port);
    }
    // Hub pattern disabled/commented out
    // jetson_hubComQueue.configure(configurationTable, 0, mallocator);

    // Hardware Manager Definitions
    Os::File::Status jetson_gpio_status = gpioWatchdogDriver.open("/dev/gpiochip0", 112, Drv::LinuxGpioDriver::GpioConfiguration::GPIO_OUTPUT);
    if (jetson_gpio_status != Os::File::Status::OP_OK) {
        Fw::Logger::log("[ERROR] Failed to open GPIO pin: %d\n", jetson_gpio_status);
    }
}

// Public functions for use in main program are namespaced with deployment name JetsonDeployment
namespace JetsonDeployment {

void setupTopology(const TopologyState& state) {
    // Autocoded initialization. Function provided by autocoder.
    initComponents(state);
    // Autocoded id setup. Function provided by autocoder.
    setBaseIds();
    // Autocoded connection wiring. Function provided by autocoder.
    connectComponents();
    // Autocoded configuration. Function provided by autocoder.
    configComponents(state);
    // Deployment-specific component configuration. Function provided above. May be inlined, if desired.
    configureTopology(state);
    // Autocoded command registration. Function provided by autocoder.
    regCommands();
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

    // Hub pattern disabled/commented out
    // jetson_hubComDriver.configure(REMOTE_HUIP_ADDRESS, REMOTE_HUPORT);
    // Os::TaskString hubName("hub");
    // jetson_hubComDriver.start(hubName, COMM_PRIORITY, Default::STACK_SIZE);
}

void startSimulatedCycle(const Fw::TimeInterval& interval) {
    jetson_timer.startTimer(interval);
}

void stopSimulatedCycle() {
    jetson_timer.quit();
}

void teardownTopology(const TopologyState& state) {
    // Autocoded (active component) task clean-up. Functions provided by topology autocoder.
    stopTasks(state);
    freeThreads(state);

    // Other task clean-up.
    jetson_comDriver.stop();
    (void)jetson_comDriver.join();

    // Hub pattern disabled/commented out
    // jetson_hubComDriver.stop();
    // (void)jetson_hubComDriver.join();

    // Resource deallocation
    jetson_cmdSeq.deallocateBuffer(mallocator);
    jetson_frameAccumulator.cleanup();
    jetson_bufferManager.cleanup();
}

};  // namespace JetsonDeployment

void setup_user_deployment(pybind11::module_& module) {
    pybind11::class_<JetsonDeployment::TopologyState>(module, "TopologyState")
        .def(pybind11::init<>())
        .def_readwrite("hostname", &JetsonDeployment::TopologyState::hostname)
        .def_readwrite("port", &JetsonDeployment::TopologyState::port);
}