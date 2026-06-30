module JetsonDeployment {

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

  constant CMD_SPLITTER_OFFSET = 0x10000

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

  instance jetson_rateGroup1: Svc.ActiveRateGroup base id 0x10001000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 120

  instance jetson_rateGroup2: Svc.ActiveRateGroup base id 0x10002000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 119

  instance jetson_rateGroup3: Svc.ActiveRateGroup base id 0x10003000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 118

  instance jetson_cmdSeq: Svc.CmdSequencer base id 0x10004000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  # SCALES SVC MANAGERS
  instance jetson_lucidCamera: Components.RunLucidCamera base id CMD_SPLITTER_OFFSET + 0x1400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99
  
  instance jetson_mlManager: Components.MLComponent base id CMD_SPLITTER_OFFSET + 0x1500 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance jetson_watchdogManager: scalesSvc.WatchdogManager base id CMD_SPLITTER_OFFSET + 0x1600 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance jetson_pwrModeManager: scalesSvc.JetsonPowerModeManager base id CMD_SPLITTER_OFFSET + 0x1700 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance jetson_thermalManager: scalesSvc.JetsonThermalManager base id CMD_SPLITTER_OFFSET + 0x1800 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99


  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------


  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance jetson_chronoTime: Svc.ChronoTime base id 0x10010000

  instance jetson_rateGroupDriver: Svc.RateGroupDriver base id 0x10011000

  instance jetson_systemResources: Svc.SystemResources base id 0x10012000

  instance jetson_timer: Svc.LinuxTimer base id 0x10013000

  instance jetson_comDriver: Drv.TcpServer base id 0x10014000

  instance jetson_gpioWatchdogDriver: Drv.LinuxGpioDriver base id CMD_SPLITTER_OFFSET + 0x9650

}
