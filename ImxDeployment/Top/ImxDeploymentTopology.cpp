// ======================================================================
// \title  ImxDeploymentTopology.cpp
// \brief cpp file containing the topology instantiation code
//
// ======================================================================

// Provides access to autocoded functions
#include <ImxDeployment/Top/ImxDeploymentTopologyAc.hpp>
#include <Svc/FrameAccumulator/FrameDetector/FprimeFrameDetector.hpp>

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

    // Buffers retained by GenericHub after deserializing hub records.
    // These must be large enough for file-packet hub payloads.
    HUB_PACKET_BUFFER_SIZE = 4 * 1024,
    HUB_PACKET_BUFFER_COUNT = 8192,

    // Buffers used on the wire/framed side of the hub.
    // TCP gives reliable byte delivery, but it is still a byte stream.
    // The framer/accumulator path is still required to recover complete F Prime frames.
    HUB_WIRE_BUFFER_SIZE = 8 * 1024,
    HUB_IO_BUFFER_COUNT = 32,

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

const char* JETSON_HUB_IP_ADDRESS = "10.3.2.12";
const U32 IMX_HUB_PORT = 50500;
const U32 JETSON_HUB_PORT = 50501;

const char* UART_GDS_DEVICE = "/dev/ttyUSB0";
const U32 UART_GDS_BUFFER_SIZE = 8 * 1024;
const U32 UART_GDS_BUFFER_COUNT = 32;

Svc::FrameDetectors::FprimeFrameDetector hubFrameDetector;

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

    // Hub packet buffer manager.
    // These buffers are retained by GenericHub and downstream async consumers.
    Svc::BufferManager::BufferBins hubPacketBins;
    memset(&hubPacketBins, 0, sizeof(hubPacketBins));
    hubPacketBins.bins[0].bufferSize = HUB_PACKET_BUFFER_SIZE;
    hubPacketBins.bins[0].numBuffers = HUB_PACKET_BUFFER_COUNT;
    imx_hubBufferManager.setup(201, 0, mallocator, hubPacketBins);

    // Hub wire/transport buffer manager.
    // These buffers are used by the framed TCP transport path.
    Svc::BufferManager::BufferBins hubIoBins;
    memset(&hubIoBins, 0, sizeof(hubIoBins));
    hubIoBins.bins[0].bufferSize = HUB_WIRE_BUFFER_SIZE;
    hubIoBins.bins[0].numBuffers = HUB_IO_BUFFER_COUNT;
    imx_hubIoBufferManager.setup(202, 0, mallocator, hubIoBins);

    // TCP is a byte stream, so the frame accumulator is still needed to rebuild
    // complete F Prime frames before deframing.
    imx_hubFrameAccumulator.configure(hubFrameDetector, 2, mallocator, HUB_WIRE_BUFFER_SIZE);

    // UART GDS wire/transport buffer manager.
    // These buffers are used by the framed UART downlink path.
    Svc::BufferManager::BufferBins uartGdsBins;
    memset(&uartGdsBins, 0, sizeof(uartGdsBins));
    uartGdsBins.bins[0].bufferSize = UART_GDS_BUFFER_SIZE;
    uartGdsBins.bins[0].numBuffers = UART_GDS_BUFFER_COUNT;
    imx_uartGdsBufferManager.setup(203, 0, mallocator, uartGdsBins);

    // UART GDS downlink driver.
    // For now this is transmit-only from flight software to the serial GDS.
    bool uartOpened = imx_uartGdsDriver.open(
        UART_GDS_DEVICE,
        Drv::LinuxUartDriver::BAUD_115K,
        Drv::LinuxUartDriver::NO_FLOW,
        Drv::LinuxUartDriver::PARITY_NONE,
        UART_GDS_BUFFER_SIZE
    );

    if (!uartOpened) {
        Fw::Logger::log("[ERROR] Failed to open UART GDS device: %s\n", UART_GDS_DEVICE);
    }

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

    // Configure command splitters before active tasks can route commands.
    imx_cmdSplitter.configure(REMOTE_JETSON_COMMAND_BASE);
    imx_seqCmdSplitter.configure(REMOTE_JETSON_COMMAND_BASE);

    // ----------------------------------------------------------------------
    // Hub communication path
    // ----------------------------------------------------------------------
    //
    // The i.MX is the hub TCP server. It must be listening before active tasks
    // begin producing hub traffic. The Jetson connects to this listener as the
    // TCP client.
    //
    // TCP gives reliable ordered byte delivery, avoiding the UDP loss/reordering
    // problems that corrupted larger image/file traffic. However, TCP does not
    // preserve message boundaries, so the FprimeFramer/FrameAccumulator/
    // FprimeDeframer stack is still required.
    imx_hubComDriver.configure(
        "0.0.0.0",
        IMX_HUB_PORT,
        1,
        0,
        HUB_WIRE_BUFFER_SIZE
    );

    Os::TaskString hubName("hub");
    imx_hubComDriver.start(hubName, COMM_PRIORITY, Default::STACK_SIZE);

    // Autocoded parameter loading
    loadParameters();

    // Autocoded task kick-off
    startTasks(state);

    // Start direct GDS-facing TCP server
    if (state.hostname != nullptr && state.port != 0) {
        Os::TaskString name("ReceiveTask");
        imx_comDriver.start(name, COMM_PRIORITY, Default::STACK_SIZE);
    }
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
    imx_hubComDriver.stop();
    (void)imx_hubComDriver.join();

    // Resource deallocation
    imx_cmdSeq.deallocateBuffer(mallocator);
    imx_hubFrameAccumulator.cleanup();
    imx_hubIoBufferManager.cleanup();
    imx_hubBufferManager.cleanup();
    imx_uartGdsBufferManager.cleanup();

    tearDownComponents(state);
    deinitComponents(state);
}

}  // namespace ImxDeployment