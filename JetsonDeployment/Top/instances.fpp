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

  instance jetson_blockDrv: Drv.BlockDriver base id CMD_SPLITTER_OFFSET + 0x0100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 140

  instance jetson_rateGroup1: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x0200 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 120

  instance jetson_rateGroup2: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x0300 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 119

  instance jetson_rateGroup3: Svc.ActiveRateGroup base id CMD_SPLITTER_OFFSET + 0x0400 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 118

  instance jetson_cmdDisp: Svc.CommandDispatcher base id CMD_SPLITTER_OFFSET + 0x0500 \
    queue size 20 \
    stack size Default.STACK_SIZE \
    priority 101

  instance jetson_cmdSeq: Svc.CmdSequencer base id CMD_SPLITTER_OFFSET + 0x0600 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  instance jetson_comQueue: Svc.ComQueue base id CMD_SPLITTER_OFFSET + 0x0700 \
      queue size Default.QUEUE_SIZE \
      stack size Default.STACK_SIZE \
      priority 100 \

  instance jetson_fileDownlink: Svc.FileDownlink base id CMD_SPLITTER_OFFSET + 0x0800 \
    queue size 30 \
    stack size Default.STACK_SIZE \
    priority 100

  instance jetson_fileManager: Svc.FileManager base id CMD_SPLITTER_OFFSET + 0x0900 \
    queue size 30 \
    stack size Default.STACK_SIZE \
    priority 100

  instance jetson_fileUplink: Svc.FileUplink base id CMD_SPLITTER_OFFSET + 0x0A00 \
    queue size 30 \
    stack size Default.STACK_SIZE \
    priority 100

  instance jetson_eventLogger: Svc.ActiveLogger base id CMD_SPLITTER_OFFSET + 0x0B00 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 98

  # comment in Svc.TlmChan or Svc.TlmPacketizer
  # depending on which form of telemetry downlink
  # you wish to use

  instance jetson_tlmSend: Svc.TlmChan base id CMD_SPLITTER_OFFSET + 0x0C00 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 97

  #instance tlmSend: Svc.TlmPacketizer base id 0x0C00 \
  #    queue size Default.QUEUE_SIZE \
  #    stack size Default.STACK_SIZE \
  #    priority 97

  instance jetson_prmDb: Svc.PrmDb base id CMD_SPLITTER_OFFSET + 0x0D00 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 96

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

  instance jetson_health: Svc.Health base id CMD_SPLITTER_OFFSET + 0x2000 \
    queue size 25

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  @ Communications driver. May be swapped with other com drivers like UART or TCP
  instance jetson_comDriver: Drv.TcpServer base id CMD_SPLITTER_OFFSET + 0x4000

  instance jetson_framer: Svc.Framer base id CMD_SPLITTER_OFFSET + 0x4100

  instance jetson_fatalAdapter: Svc.AssertFatalAdapter base id CMD_SPLITTER_OFFSET + 0x4200

  instance jetson_fatalHandler: Svc.FatalHandler base id CMD_SPLITTER_OFFSET + 0x4300

  instance jetson_bufferManager: Svc.BufferManager base id CMD_SPLITTER_OFFSET + 0x4400

  instance jetson_chronoTime: Svc.ChronoTime base id CMD_SPLITTER_OFFSET + 0x4500

  instance jetson_rateGroupDriver: Svc.RateGroupDriver base id CMD_SPLITTER_OFFSET + 0x4600

  instance jetson_textLogger: Svc.PassiveTextLogger base id CMD_SPLITTER_OFFSET + 0x4800

  instance jetson_deframer: Svc.Deframer base id CMD_SPLITTER_OFFSET + 0x4900

  instance jetson_systemResources: Svc.SystemResources base id CMD_SPLITTER_OFFSET + 0x4A00

  instance jetson_comStub: Svc.ComStub base id CMD_SPLITTER_OFFSET + 0x4B00

  instance jetson_hub: Svc.GenericHub base id CMD_SPLITTER_OFFSET + 0x9000

  instance jetson_hubComDriver: Drv.TcpClient base id CMD_SPLITTER_OFFSET + 0x9100
  
  instance jetson_hubComStub: Svc.ComStub base id CMD_SPLITTER_OFFSET + 0x9200

  instance jetson_hubDeframer: Svc.Deframer base id CMD_SPLITTER_OFFSET + 0x9300

  instance jetson_hubFramer: Svc.Framer base id CMD_SPLITTER_OFFSET + 0x9400

}
