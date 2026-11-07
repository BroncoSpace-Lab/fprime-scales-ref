module QualcommDeployment {
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

  instance qualcomm_lucidCamera: Components.RunLucidCamera base id CMD_SPLITTER_OFFSET + 0x1000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance qualcomm_mlManager: Components.MLComponent base id CMD_SPLITTER_OFFSET + 0x1100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  # instance qualcomm_pwrModeManager: scalesSvc.JetsonPowerModeManager base id CMD_SPLITTER_OFFSET + 0x1200 \
  #   queue size Default.QUEUE_SIZE \
  #   stack size Default.STACK_SIZE \
  #   priority 99

  # instance qualcomm_thermalManager: scalesSvc.JetsonThermalManager base id CMD_SPLITTER_OFFSET + 0x1300 \
  #   queue size Default.QUEUE_SIZE \
  #   stack size Default.STACK_SIZE \
  #   priority 99

  # instance qualcomm_watchdogManager: scalesSvc.WatchdogManager base id CMD_SPLITTER_OFFSET + 0x1400 \
  #   queue size Default.QUEUE_SIZE \
  #   stack size Default.STACK_SIZE \
  #   priority 99

  instance qualcomm_rateGroup1: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x4000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 120

  instance qualcomm_rateGroup2: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x4100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 119

  instance qualcomm_rateGroup3: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x4200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 118

  instance qualcomm_cmdSeq: Svc.CmdSequencer base id CMD_SPLITTER_OFFSET + 0x4400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  instance qualcomm_proxySequencer: Components.CmdSequenceForwarder base id CMD_SPLITTER_OFFSET + 0x9700 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100 \

  instance qualcomm_proxyGroundInterface: Components.CmdSequenceForwarder base id CMD_SPLITTER_OFFSET + 0x9800 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100 \

  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------


  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  @ Communications driver. May be swapped with other com drivers like UART or TCP

  instance qualcomm_systemResources: Svc.SystemResources base id CMD_SPLITTER_OFFSET + 0x2000

  instance qualcomm_hub: Svc.GenericHub base id CMD_SPLITTER_OFFSET + 0x3000

  instance qualcomm_hubComDriver: Drv.TcpClient base id CMD_SPLITTER_OFFSET + 0x3100

  instance qualcomm_hubComAdapter: scalesSvc.HubComAdapter base id CMD_SPLITTER_OFFSET + 0x3200

  instance qualcomm_hubBufferManager: Svc.BufferManager base id CMD_SPLITTER_OFFSET + 0x3300

  instance qualcomm_hubFramer: Svc.FprimeFramer base id CMD_SPLITTER_OFFSET + 0x3500

  instance qualcomm_hubFrameAccumulator: Svc.FrameAccumulator base id CMD_SPLITTER_OFFSET + 0x3600

  instance qualcomm_hubDeframer: Svc.FprimeDeframer base id CMD_SPLITTER_OFFSET + 0x3700

  instance qualcomm_hubComStub: Svc.ComStub base id CMD_SPLITTER_OFFSET + 0x3800

  instance qualcomm_hubIoBufferManager: Svc.BufferManager base id CMD_SPLITTER_OFFSET + 0x3A00

  instance qualcomm_rateGroupDriver: Svc.RateGroupDriver base id CMD_SPLITTER_OFFSET + 0x4300

  instance qualcomm_chronoTime: Svc.ChronoTime base id CMD_SPLITTER_OFFSET + 0x4500

  instance qualcomm_timer: Svc.LinuxTimer base id CMD_SPLITTER_OFFSET + 0x4600

  instance qualcomm_comDriver: Drv.TcpServer base id CMD_SPLITTER_OFFSET + 0x4700
  
  # instance qualcomm_gpioWatchdogDriver: Drv.LinuxGpioDriver base id CMD_SPLITTER_OFFSET + 0x4800

}
