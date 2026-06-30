module JetsonDeployment {
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

  # Rate Groups

  instance rateGroup1: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x5200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 120

  instance rateGroup2: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x5300 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 119

  instance rateGroup3: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x5400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 118

  # instance jetson_cmdDisp: Svc.CommandDispatcher base id CMD_SPLITTER_OFFSET + 0x5500 \
  #   queue size 20 \
  #   stack size Default.STACK_SIZE \
  #   priority 101

  instance cmdSeq: Svc.CmdSequencer base id CMD_SPLITTER_OFFSET + 0x5600 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

# ----------------------------------------------------
# SCALES Service Managers

  instance jetson_watchdogManager: scalesSvc.WatchdogManager base id CMD_SPLITTER_OFFSET + 0x1600 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance jetson_thermalManager: scalesSvc.JetsonThermalManager base id CMD_SPLITTER_OFFSET + 0x1800 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

   instance jetson_pwrModeManager: scalesSvc.JetsonPowerModeManager base id CMD_SPLITTER_OFFSET + 0x1700 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

# ----------------------------------------------------
# Core SCALES Components

  instance jetson_lucidCamera: Components.RunLucidCamera base id CMD_SPLITTER_OFFSET + 0x1400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 99

  instance jetson_mlManager: Components.MLComponent base id CMD_SPLITTER_OFFSET + 0x1500 \
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

  instance chronoTime: Svc.ChronoTime base id CMD_SPLITTER_OFFSET + 0x7500

  instance rateGroupDriver: Svc.RateGroupDriver base id CMD_SPLITTER_OFFSET + 0x7600

  instance systemResources: Svc.SystemResources base id CMD_SPLITTER_OFFSET + 0x7A00

  instance timer: Svc.LinuxTimer base id CMD_SPLITTER_OFFSET + 0x9600

  instance comDriver: Drv.TcpServer base id CMD_SPLITTER_OFFSET + 0x7000
  
  instance gpioWatchdogDriver: Drv.LinuxGpioDriver base id CMD_SPLITTER_OFFSET + 0x9650

}
