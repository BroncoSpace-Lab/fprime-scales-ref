// ======================================================================
// \title  ImxDeploymentTopology.cpp
// \brief cpp file containing the topology instantiation code
//
// ======================================================================

// Provides access to autocoded functions
#include <ImxDeployment/Top/ImxDeploymentTopologyAc.hpp>

// Note: Uncomment when using Svc:TlmPacketizer
//#include <ImxDeployment/Top/ImxDeploymentPacketsAc.hpp>

// Necessary project-specified types
#include <Fw/Types/MallocAllocator.hpp>
#include <Fw/Logger/Logger.hpp>

// Public functions for use in main program are namespaced with deployment module ImxDeployment.
// This is also the namespace where the topology components are instantiated by FPP.
namespace ImxDeployment {

// Instantiate a malloc allocator for cmdSeq buffer allocation
Fw::MallocAllocator mallocator;

// The reference topology divides the incoming clock signal into sub-signals:
// 1Hz, 1/2Hz, and 1/4Hz with 0 offset.
Svc::RateGroupDriver::DividerSet rateGroupDivisorsSet{{{1, 0}, {2, 0}, {4, 0}}};

// Rate groups may supply a context token to each attached child.
U32 rateGroup1Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};
U32 rateGroup2Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};
U32 rateGroup3Context[Svc::ActiveRateGroup::CONNECTION_COUNT_MAX] = {};

enum TopologyConstants {
    COMM_PRIORITY = 34,
    COM_DRIVER_BUFFER_SIZE = 3000,
    COM_DRIVER_BUFFER_COUNT = 30,

    // Commands with opcodes >= REMOTE_JETSON_COMMAND_BASE are routed to the Jetson over the hub.
    //
    // Important:
    // The old value was 0x10000. That was too low because framework/CDH commands
    // like CdhCore.cmdDisp.CMD_NO_OP live around 0x01000000, causing NO_OP to be
    // incorrectly routed to the Jetson hub path.
    //
    // With this value:
    //   local IMX/CDH commands: opcode <  0x10000000
    //   remote Jetson commands: opcode >= 0x10000000
    REMOTE_JETSON_COMMAND_BASE = 0x10000000
};

/**
 * \brief configure/setup components in project-specific way
 *
 * This helper configures/sets up each component requiring project-specific input.
 */
void configureTopology() {
    // Rate group driver needs a divisor list
    imx_rateGroupDriver.configure(rateGroupDivisorsSet);

    // Rate groups require context arrays.
    imx_rateGroup1.configure(rateGroup1Context, FW_NUM_ARRAY_ELEMENTS(rateGroup1Context));
    imx_rateGroup2.configure(rateGroup2Context, FW_NUM_ARRAY_ELEMENTS(rateGroup2Context));
    imx_rateGroup3.configure(rateGroup3Context, FW_NUM_ARRAY_ELEMENTS(rateGroup3Context));

    // Command sequencer needs memory for command sequences.
    imx_cmdSeq.allocateBuffer(0, mallocator, 5 * 1024);

    // Hub buffer manager
    Svc::BufferManager::BufferBins hubBuffMgrBins;
    memset(&hubBuffMgrBins, 0, sizeof(hubBuffMgrBins));
    hubBuffMgrBins.bins[0].bufferSize = COM_DRIVER_BUFFER_SIZE;
    hubBuffMgrBins.bins[0].numBuffers = COM_DRIVER_BUFFER_COUNT;
    imx_hubBufferManager.setup(201, 0, mallocator, hubBuffMgrBins);

    // Hardware Manager Definitions

    Os::File::Status watchdog_gpio_status =
        imx_gpioWatchDogDriver.open(
            "/dev/gpiochip2",
            20,
            Drv::LinuxGpioDriver::GpioConfiguration::GPIO_OUTPUT
        );

    if (watchdog_gpio_status != Os::File::Status::OP_OK) {
        Fw::Logger::log("[ERROR] Failed to open watchdog GPIO pin: %d\n", watchdog_gpio_status);
    }

    Os::File::Status perif_gpio_status =
        imx_perifGpioDriver.open(
            "/dev/gpiochip2",
            18,
            Drv::LinuxGpioDriver::GpioConfiguration::GPIO_OUTPUT
        );

    if (perif_gpio_status != Os::File::Status::OP_OK) {
        Fw::Logger::log("[ERROR] Failed to open peripheral GPIO pin: %d\n", perif_gpio_status);
    }

    Os::File::Status jetson_gpio_status =
        imx_jetsonGpioDriver.open(
            "/dev/gpiochip2",
            19,
            Drv::LinuxGpioDriver::GpioConfiguration::GPIO_OUTPUT
        );

    if (jetson_gpio_status != Os::File::Status::OP_OK) {
        Fw::Logger::log("[ERROR] Failed to open Jetson GPIO pin: %d\n", jetson_gpio_status);
    }

    // Manager Definitions

    bool mcp_status = imx_mcpI2CbusDriver.open("/dev/i2c-0");
    if (!mcp_status) {
        Fw::Logger::log("[ERROR] Failed to open MCP I2C bus driver\n");
    }

    bool ina_status = imx_inaI2CbusDriver.open("/dev/i2c-0");
    if (!ina_status) {
        Fw::Logger::log("[ERROR] Failed to open INA I2C bus driver\n");
    }
}

void setupTopology(const TopologyState& state) {
    // Autocoded initialization
    initComponents(state);

    // Autocoded ID setup
    setBaseIds();

    // Autocoded connection wiring
    connectComponents();

    // Autocoded command registration
    regCommands();

    // Autocoded configuration
    configComponents(state);

    // Configure direct GDS-facing comm driver
    if (state.hostname != nullptr && state.port != 0) {
        imx_comDriver.configure(state.hostname, state.port);
    }

    // Project-specific component configuration
    configureTopology();

    // Autocoded parameter loading
    loadParameters();

    // Autocoded task kick-off
    startTasks(state);

    // Start direct GDS-facing TCP server
    if (state.hostname != nullptr && state.port != 0) {
        Os::TaskString name("ReceiveTask");
        imx_comDriver.start(name, COMM_PRIORITY, Default::STACK_SIZE);
    }

    // ----------------------------------------------------------------------
    // Hub communication path
    // ----------------------------------------------------------------------

    // IMX hub server listens for the Jetson hub client.
    imx_hubComDriver.configure("0.0.0.0", 50500);

    // CRITICAL FIX:
    //
    // Old value:
    //   0x10000
    //
    // That incorrectly classified framework/CDH commands such as NO_OP
    // as remote Jetson commands because NO_OP is around 0x01000000.
    //
    // New value:
    //   0x10000000
    //
    // This keeps IMX/CDH commands local and only routes Jetson commands
    // in the high 0x10000000+ range over the hub.
    imx_cmdSplitter.configure(REMOTE_JETSON_COMMAND_BASE);
    imx_seqCmdSplitter.configure(REMOTE_JETSON_COMMAND_BASE);

    Os::TaskString hubName("hub");
    imx_hubComDriver.start(hubName, COMM_PRIORITY, Default::STACK_SIZE);
}

void startRateGroups(const Fw::TimeInterval& interval) {
    // The timer component drives the fundamental tick rate of the system.
    // Svc::RateGroupDriver divides this down to the slower rate groups.
    imx_timer.startTimer(interval);
}

void stopRateGroups() {
    imx_timer.quit();
}

void teardownTopology(const TopologyState& state) {
    // Autocoded active component task cleanup
    stopTasks(state);
    freeThreads(state);

    // Direct GDS comm cleanup
    imx_comDriver.terminate();
    imx_comDriver.stop();
    (void)imx_comDriver.join();

    // Hub comm cleanup
    imx_hubComDriver.terminate();
    imx_hubComDriver.stop();
    (void)imx_hubComDriver.join();

    // Resource deallocation
    imx_cmdSeq.deallocateBuffer(mallocator);
    imx_hubBufferManager.cleanup();

    tearDownComponents(state);
    deinitComponents(state);
}

}  // namespace ImxDeployment