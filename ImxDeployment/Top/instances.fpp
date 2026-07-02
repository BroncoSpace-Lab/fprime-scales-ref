module ImxDeployment {

  # ----------------------------------------------------------------------
  # Base ID Convention
  # ----------------------------------------------------------------------
  #
  # All Base IDs follow the 8-digit hex format: 0xDSSCCxxx
  #
  # Where:
  #   D   = Deployment digit (1 for this deployment)
  #   SS  = Subtopology digits (00 for main topology, 01-05 for subtopologies)
  #   CC  = Component digits (00, 01, 02, etc.)
  #   xxx = Reserved for internal component items (events, commands, telemetry)
  #

  # ----------------------------------------------------------------------
  # Defaults
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 10
    constant STACK_SIZE = 64 * 1024
  }

  # ----------------------------------------------------------------------
  # Active component instances
  # ----------------------------------------------------------------------

  instance imx_jetsonManager: scalesSvc.JetsonManager base id 0x1000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_inaManager: scalesSvc.InaManager base id 0x1100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_thermalManager: scalesSvc.ImxThermalManager base id 0x1200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_mcpManager: scalesSvc.McpManager base id 0x1300 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_perifBoardManager: scalesSvc.PerifBoardManager base id 0x1400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_watchdogManager: scalesSvc.WatchdogManager base id 0x1500 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_rateGroup1: Svc.ActiveRateGroup base id 0x4000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 120

  instance imx_rateGroup2: Svc.ActiveRateGroup base id 0x4100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 119

  instance imx_rateGroup3: Svc.ActiveRateGroup base id 0x4200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 118

  instance imx_cmdSeq: Svc.CmdSequencer base id 0x4400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------


  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance imx_systemResources: Svc.SystemResources base id 0x2000

  instance imx_hub: Svc.GenericHub base id 0x3000

  instance imx_hubComDriver: Drv.TcpServer base id 0x3100

  instance imx_hubByteStreamAdapter: Drv.ByteStreamBufferAdapter base id 0x3200

  instance imx_hubBufferManager: Svc.BufferManager base id 0x3300

  instance imx_cmdSplitter: Svc.CmdSplitter base id 0x3400

  instance imx_seqCmdSplitter: Svc.CmdSplitter base id 0x3410

  instance imx_rateGroupDriver: Svc.RateGroupDriver base id 0x4300

  instance imx_chronoTime: Svc.ChronoTime base id 0x4500

  instance imx_timer: Svc.LinuxTimer base id 0x4600

  instance imx_comDriver: Drv.TcpServer base id 0x4700

  # SCALES SVC Driver Instances

  instance imx_mcpI2CbusDriver: Drv.LinuxI2cDriver base id 0x5000

  instance imx_inaI2CbusDriver: Drv.LinuxI2cDriver base id 0x5010

  instance imx_perifGpioDriver: Drv.LinuxGpioDriver base id 0x5020

  instance imx_jetsonGpioDriver: Drv.LinuxGpioDriver base id 0x5030

  instance imx_gpioWatchDogDriver: Drv.LinuxGpioDriver base id 0x5040

}
