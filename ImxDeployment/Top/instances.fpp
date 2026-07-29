module ImxDeployment {

  # ----------------------------------------------------------------------
  # Base ID Convention
  # ----------------------------------------------------------------------
  #
  # IDs are grouped by operator-facing telemetry order. Local i.MX deployment
  # components stay below 0x10000 so the command splitter keeps them local;
  # Jetson deployment components use IDs at or above 0x10000.
  #

  # ----------------------------------------------------------------------
  # Defaults
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 10
    constant STACK_SIZE = 64 * 1024
  }

  # imx_uartGdsComQueue carries every event, every telemetry point, comStatusIn
  # acks, and the run tick through one active-component queue -- the same
  # workload shape as ComFprime.comQueue (sized 50 in ComFprimeConfig.fpp), not
  # the occasional-command components Default.QUEUE_SIZE (10) is sized for. A
  # burst of events/telemetry (e.g. a Jetson reboot re-announcing version,
  # param, and watchdog status) can fill 10 slots and hit Os::Queue::FULL,
  # asserting inside Svc::ComQueue and forwarding a FATAL to FPManager.
  module UartGds {
    constant QUEUE_SIZE = 50
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

  instance imx_fpManager: scalesSvc.FPManager base id 0x1600 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_watchdogManager: scalesSvc.WatchdogManager base id 0x1500 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance imx_dataProducer: scalesSvc.DataProducer base id 0x1800 \
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

  instance imx_gdsCmdAuthMux: scalesSvc.GdsCmdAuthMux base id 0x5900 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  # Active UART GDS downlink transport instances

  instance imx_uartGdsComQueue: Svc.ComQueue base id 0x5400 \
    queue size UartGds.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------


  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance imx_systemResources: Svc.SystemResources base id 0x2000

  # Real, process-terminating FATAL handler. FPManager forwards to this after
  # it has finished shutting down the Jetson, peripherals, and i.MX board.
  instance imx_realFatalHandler: Svc.FatalHandler base id 0x1700

  instance imx_hub: Svc.GenericHub base id 0x3000

  instance imx_hubComDriver: Drv.TcpServer base id 0x3100

  instance imx_hubComAdapter: scalesSvc.HubComAdapter base id 0x3200

  instance imx_hubBufferManager: Svc.BufferManager base id 0x3300

  instance imx_hubFramer: Svc.FprimeFramer base id 0x3500

  instance imx_hubFrameAccumulator: Svc.FrameAccumulator base id 0x3600

  instance imx_hubDeframer: Svc.FprimeDeframer base id 0x3700

  instance imx_hubComStub: Svc.ComStub base id 0x3800

  instance imx_hubIoBufferManager: Svc.BufferManager base id 0x3A00

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

  # SCALES UART Splitter GDS Instances

  instance imx_uartGdsEventSplitter: Svc.ComSplitter base id 0x5050

  instance imx_uartGdsTlmSplitter: Svc.ComSplitter base id 0x5060

  # UART GDS downlink transport instances

  instance imx_uartGdsFramer: Svc.FprimeFramer base id 0x5500

  instance imx_uartGdsComStub: Svc.ComStub base id 0x5600

  instance imx_uartGdsDriver: Drv.LinuxUartDriver base id 0x5700

  instance imx_uartGdsBufferManager: Svc.BufferManager base id 0x5800 \

  instance imx_uartGdsFrameAccumulator: Svc.FrameAccumulator base id 0x5A00

  instance imx_uartGdsDeframer: Svc.FprimeDeframer base id 0x5B00

  instance imx_uartGdsRouter: Svc.FprimeRouter base id 0x5C00

}
