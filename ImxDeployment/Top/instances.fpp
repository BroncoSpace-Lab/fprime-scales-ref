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

  instance imx_rateGroup1: Svc.ActiveRateGroup base id 0x0200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 120

  instance imx_rateGroup2: Svc.ActiveRateGroup base id 0x0300 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 119

  instance imx_rateGroup3: Svc.ActiveRateGroup base id 0x0400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 118

  instance imx_cmdSeq: Svc.CmdSequencer base id 0x0500 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100
  
  # ----------------------------------------------------
  # SCALES Service Managers

  instance imx_watchdogManager: scalesSvc.WatchdogManager base id 0x5000 \
      queue size Default.QUEUE_SIZE \
      stack size Default.STACK_SIZE \
      priority 99

  instance imx_thermalManager: scalesSvc.ImxThermalManager base id 0x5100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_inaManager: scalesSvc.InaManager base id 0x5200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_mcpManager: scalesSvc.McpManager base id 0x5300 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_perifBoardManager: scalesSvc.PerifBoardManager base id 0x5400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_jetsonManager: scalesSvc.JetsonManager base id 0x5500 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------


  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance imx_chronoTime: Svc.ChronoTime base id 0x10010000

  instance imx_rateGroupDriver: Svc.RateGroupDriver base id 0x10011000

  instance imx_systemResources: Svc.SystemResources base id 0x10012000

  instance imx_timer: Svc.LinuxTimer base id 0x10013000

  instance imx_comDriver: Drv.TcpServer base id 0x10014000

  # SCALES SVC Driver Instances

  instance imx_mcpI2CbusDriver: Drv.LinuxI2cDriver base id 0x6000

  instance imx_inaI2CbusDriver: Drv.LinuxI2cDriver base id 0x6010

  instance imx_perifGpioDriver: Drv.LinuxGpioDriver base id 0x6020

  instance imx_jetsonGpioDriver: Drv.LinuxGpioDriver base id 0x6030

  instance imx_gpioWatchDogDriver: Drv.LinuxGpioDriver base id 0x6040

  # IMX HUB PATTERN SPECIFIC INSTANCES

  instance imx_hub: Svc.GenericHub base id 0x4000

  instance imx_hubComDriver: Drv.TcpServer base id 0x4100

  instance imx_hubBufferManager: Svc.BufferManager base id 0x4200

  instance imx_hubByteStreamAdapter: Drv.ByteStreamBufferAdapter base id 0x4300

  instance imx_cmdSplitter: Svc.CmdSplitter base id 0x4600

}
