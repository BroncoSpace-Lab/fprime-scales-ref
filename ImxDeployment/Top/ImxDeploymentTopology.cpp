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

// Public functions for use in main program are namespaced with deployment module ImxDeployment
// This is also the namespace where the topology components are instantiated by FPP.
namespace ImxDeployment {

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
    COM_DRIVER_BUFFER_SIZE = 3000,
    COM_DRIVER_BUFFER_COUNT = 30
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
    imx_rateGroupDriver.configure(rateGroupDivisorsSet);

    // Rate groups require context arrays.
    imx_rateGroup1.configure(rateGroup1Context, FW_NUM_ARRAY_ELEMENTS(rateGroup1Context));
    imx_rateGroup2.configure(rateGroup2Context, FW_NUM_ARRAY_ELEMENTS(rateGroup2Context));
    imx_rateGroup3.configure(rateGroup3Context, FW_NUM_ARRAY_ELEMENTS(rateGroup3Context));

    // Command sequencer needs to allocate memory to hold contents of command sequences
    imx_cmdSeq.allocateBuffer(0, mallocator, 5 * 1024);


    Svc::BufferManager::BufferBins hubBuffMgrBins; // For the hub buffer manager
    memset(&hubBuffMgrBins, 0, sizeof(hubBuffMgrBins));
    hubBuffMgrBins.bins[0].bufferSize = COM_DRIVER_BUFFER_SIZE;
    hubBuffMgrBins.bins[0].numBuffers = COM_DRIVER_BUFFER_COUNT;
    imx_hubBufferManager.setup(201, 0, mallocator, hubBuffMgrBins);


    // Hardware Manager Definitions

    Os::File::Status watchdog_gpio_status = imx_gpioWatchDogDriver.open("/dev/gpiochip2", 20, Drv::LinuxGpioDriver::GpioConfiguration::GPIO_OUTPUT);
    if (watchdog_gpio_status!= Os::File::Status::OP_OK) {
        Fw::Logger::log("[ERROR] Failed to open GPIO pin: %d\n", watchdog_gpio_status);

    }

    Os::File::Status perif_gpio_status = imx_perifGpioDriver.open("/dev/gpiochip2", 18, Drv::LinuxGpioDriver::GpioConfiguration::GPIO_OUTPUT);
    if (perif_gpio_status != Os::File::Status::OP_OK) {
        Fw::Logger::log("[ERROR] Failed to open GPIO pin: %d\n", perif_gpio_status);

    }

    Os::File::Status jetson_gpio_status = imx_jetsonGpioDriver.open("/dev/gpiochip2", 19, Drv::LinuxGpioDriver::GpioConfiguration::GPIO_OUTPUT);
    if (jetson_gpio_status != Os::File::Status::OP_OK) {
        Fw::Logger::log("[ERROR] Failed to open GPIO pin: %d\n", jetson_gpio_status);
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
        imx_comDriver.configure(state.hostname, state.port);
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
        imx_comDriver.start(name, COMM_PRIORITY, Default::STACK_SIZE);
    }

    /* Hub com driver configs */
    imx_hubComDriver.configure("0.0.0.0", 50500);
    imx_cmdSplitter.configure(0x10000);    
    Os::TaskString hubName("hub");
    imx_hubComDriver.start(hubName, COMM_PRIORITY, Default::STACK_SIZE);
}

void startRateGroups(const Fw::TimeInterval& interval) {
    // The timer component drives the fundamental tick rate of the system.
    // Svc::RateGroupDriver will divide this down to the slower rate groups.
    // This call will block until the stopRateGroups() call is made.
    // For this Linux demo, that call is made from a signal handler.
    imx_timer.startTimer(interval);
}

void stopRateGroups() {
    imx_timer.quit();
}

void teardownTopology(const TopologyState& state) {
    // Autocoded (active component) task clean-up. Functions provided by topology autocoder.
    stopTasks(state);
    freeThreads(state);

    // Other task clean-up.
    imx_comDriver.terminate();
    imx_comDriver.stop();
    (void)imx_comDriver.join();

    imx_hubComDriver.terminate();
    imx_hubComDriver.stop();
    (void)imx_hubComDriver.join();

    // Resource deallocation
    imx_cmdSeq.deallocateBuffer(mallocator);
    imx_hubBufferManager.cleanup();

    tearDownComponents(state);
    deinitComponents(state);
}
};  // namespace ImxDeployment
