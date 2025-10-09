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

  instance jetson_blockDrv: Drv.BlockDriver base id CMD_SPLITTER_OFFSET + 0x5100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 140

  instance jetson_rateGroup1: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x5200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 120

  instance jetson_rateGroup2: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x5300 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 119

  instance jetson_rateGroup3: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x5400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 118

  instance jetson_cmdDisp: Svc.CommandDispatcher base id CMD_SPLITTER_OFFSET + 0x5500 \
    queue size 20 \
    stack size Default.STACK_SIZE \
    priority 101

  instance jetson_cmdSeq: Svc.CmdSequencer base id CMD_SPLITTER_OFFSET + 0x5600 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  instance jetson_comQueue: Svc.ComQueue base id CMD_SPLITTER_OFFSET + 0x5700 \
      queue size Default.QUEUE_SIZE \
      stack size Default.STACK_SIZE \
      priority 100 \

  instance jetson_fileDownlink: Svc.FileDownlink base id CMD_SPLITTER_OFFSET + 0x5800 \
    queue size 30 \
    stack size Default.STACK_SIZE \
    priority 100

  instance jetson_fileManager: Svc.FileManager base id CMD_SPLITTER_OFFSET + 0x5900 \
    queue size 30 \
    stack size Default.STACK_SIZE \
    priority 100

  instance jetson_fileUplink: Svc.FileUplink base id CMD_SPLITTER_OFFSET + 0x5A00 \
    queue size 30 \
    stack size Default.STACK_SIZE \
    priority 100

  instance jetson_eventLogger: Svc.ActiveLogger base id CMD_SPLITTER_OFFSET + 0x5B00 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 98

  # comment in Svc.TlmChan or Svc.TlmPacketizer
  # depending on which form of telemetry downlink
  # you wish to use

  instance jetson_tlmSend: Svc.TlmChan base id CMD_SPLITTER_OFFSET + 0x5C00 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 97

  #instance tlmSend: Svc.TlmPacketizer base id 0x0C00 \
  #    queue size Default.QUEUE_SIZE \
  #    stack size Default.STACK_SIZE \
  #    priority 97

  instance jetson_prmDb: Svc.PrmDb base id CMD_SPLITTER_OFFSET + 0x5D00 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 96

  instance jetson_hubComQueue: Svc.ComQueue base id CMD_SPLITTER_OFFSET + 0x9500 \
      queue size Default.QUEUE_SIZE \
      stack size Default.STACK_SIZE \
      priority 100 \

  instance jetson_proxySequencer: Components.CmdSequenceForwarder base id CMD_SPLITTER_OFFSET + 0x9700 \
      queue size Default.QUEUE_SIZE \
      stack size Default.STACK_SIZE \
      priority 100 \

  instance jetson_proxyGroundInterface: Components.CmdSequenceForwarder base id CMD_SPLITTER_OFFSET + 0x9800 \
      queue size Default.QUEUE_SIZE \
      stack size Default.STACK_SIZE \
      priority 100 \

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

  instance jetson_health: Svc.Health base id CMD_SPLITTER_OFFSET + 0x6000 \
    queue size 25

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  @ Communications driver. May be swapped with other com drivers like UART or TCP
  instance jetson_comDriver: Drv.TcpServer base id CMD_SPLITTER_OFFSET + 0x7000

  instance jetson_framer: Svc.Framer base id CMD_SPLITTER_OFFSET + 0x7100

  instance jetson_fatalAdapter: Svc.AssertFatalAdapter base id CMD_SPLITTER_OFFSET + 0x7200

  instance jetson_fatalHandler: Svc.FatalHandler base id CMD_SPLITTER_OFFSET + 0x7300

  instance jetson_bufferManager: Svc.BufferManager base id CMD_SPLITTER_OFFSET + 0x7400

  instance jetson_chronoTime: Svc.ChronoTime base id CMD_SPLITTER_OFFSET + 0x7500

  instance jetson_rateGroupDriver: Svc.RateGroupDriver base id CMD_SPLITTER_OFFSET + 0x7600

  instance jetson_textLogger: Svc.PassiveTextLogger base id CMD_SPLITTER_OFFSET + 0x7800

  instance jetson_deframer: Svc.Deframer base id CMD_SPLITTER_OFFSET + 0x7900

  instance jetson_systemResources: Svc.SystemResources base id CMD_SPLITTER_OFFSET + 0x7A00

  instance jetson_comStub: Svc.ComStub base id CMD_SPLITTER_OFFSET + 0x7B00

  instance jetson_hub: Svc.GenericHub base id CMD_SPLITTER_OFFSET + 0x9000

  instance jetson_hubComDriver: Drv.TcpClient base id CMD_SPLITTER_OFFSET + 0x9100
  
  instance jetson_hubComStub: Svc.ComStub base id CMD_SPLITTER_OFFSET + 0x9200

  instance jetson_hubDeframer: Svc.Deframer base id CMD_SPLITTER_OFFSET + 0x9300

  instance jetson_hubFramer: Svc.Framer base id CMD_SPLITTER_OFFSET + 0x9400
<<<<<<< HEAD
=======

  instance jetson_timer: Svc.LinuxTimer base id CMD_SPLITTER_OFFSET + 0x11000
>>>>>>> d6b4fd2b8701b9c2bc49f92a1064cec42ceb1590

  instance jetson_timer: Svc.LinuxTimer base id CMD_SPLITTER_OFFSET + 0x9600

}