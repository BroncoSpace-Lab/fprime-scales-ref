module JetsonDeployment {
  constant CMD_SPLITTER_OFFSET = 0x10000000

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

  instance jetson_lucidCamera: Components.RunLucidCamera base id CMD_SPLITTER_OFFSET + 0x1000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance jetson_mlManager: Components.MLComponent base id CMD_SPLITTER_OFFSET + 0x1100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance jetson_pwrModeManager: scalesSvc.JetsonPowerModeManager base id CMD_SPLITTER_OFFSET + 0x1200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance jetson_thermalManager: scalesSvc.JetsonThermalManager base id CMD_SPLITTER_OFFSET + 0x1300 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance jetson_watchdogManager: scalesSvc.WatchdogManager base id CMD_SPLITTER_OFFSET + 0x1400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance jetson_rateGroup1: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x4000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 120

  instance jetson_rateGroup2: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x4100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 119

  instance jetson_rateGroup3: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x4200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 118

  instance jetson_cmdSeq: Svc.CmdSequencer base id CMD_SPLITTER_OFFSET + 0x4400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  instance jetson_proxySequencer: Components.CmdSequenceForwarder base id CMD_SPLITTER_OFFSET + 0x9700 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100 \

  instance jetson_proxyGroundInterface: Components.CmdSequenceForwarder base id CMD_SPLITTER_OFFSET + 0x9800 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100 \

  instance jetson_thermalManager: scalesSvc.JetsonThermalManager base id CMD_SPLITTER_OFFSET + 0x1700 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------


  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  @ Communications driver. May be swapped with other com drivers like UART or TCP

  instance jetson_systemResources: Svc.SystemResources base id CMD_SPLITTER_OFFSET + 0x2000

  instance jetson_hub: Svc.GenericHub base id CMD_SPLITTER_OFFSET + 0x3000

  instance jetson_hubComDriver: Drv.TcpClient base id CMD_SPLITTER_OFFSET + 0x3100

  instance jetson_hubComAdapter: scalesSvc.HubComAdapter base id CMD_SPLITTER_OFFSET + 0x3200

  instance jetson_hubBufferManager: Svc.BufferManager base id CMD_SPLITTER_OFFSET + 0x3300

  instance jetson_hubFramer: Svc.FprimeFramer base id CMD_SPLITTER_OFFSET + 0x3500

  instance jetson_hubFrameAccumulator: Svc.FrameAccumulator base id CMD_SPLITTER_OFFSET + 0x3600

  instance jetson_hubDeframer: Svc.FprimeDeframer base id CMD_SPLITTER_OFFSET + 0x3700

  instance jetson_hubComStub: Svc.ComStub base id CMD_SPLITTER_OFFSET + 0x3800

  instance jetson_hubIoBufferManager: Svc.BufferManager base id CMD_SPLITTER_OFFSET + 0x3A00

  instance jetson_rateGroupDriver: Svc.RateGroupDriver base id CMD_SPLITTER_OFFSET + 0x4300

  instance jetson_chronoTime: Svc.ChronoTime base id CMD_SPLITTER_OFFSET + 0x4500

  instance jetson_timer: Svc.LinuxTimer base id CMD_SPLITTER_OFFSET + 0x4600

  instance jetson_comDriver: Drv.TcpServer base id CMD_SPLITTER_OFFSET + 0x4700
  
  instance jetson_gpioWatchdogDriver: Drv.LinuxGpioDriver base id CMD_SPLITTER_OFFSET + 0x4800

}
