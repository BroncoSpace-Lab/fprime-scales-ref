module ImxDeployment {

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

  instance imx_blockDrv: Drv.BlockDriver base id 0x0100 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 140

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

  instance imx_cmdDisp: Svc.CommandDispatcher base id 0x0500 \
    queue size 20 \
    stack size Default.STACK_SIZE \
    priority 101

  instance imx_cmdSeq: Svc.CmdSequencer base id 0x0600 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  instance imx_comQueue: Svc.ComQueue base id 0x0700 \
      queue size Default.QUEUE_SIZE \
      stack size Default.STACK_SIZE \
      priority 100 \

  instance imx_fileDownlink: Svc.FileDownlink base id 0x0800 \
    queue size 30 \
    stack size Default.STACK_SIZE \
    priority 100

  instance imx_fileManager: Svc.FileManager base id 0x0900 \
    queue size 30 \
    stack size Default.STACK_SIZE \
    priority 100

  instance imx_fileUplink: Svc.FileUplink base id 0x0A00 \
    queue size 30 \
    stack size Default.STACK_SIZE \
    priority 100

  instance imx_eventLogger: Svc.ActiveLogger base id 0x0B00 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 98

  # comment in Svc.TlmChan or Svc.TlmPacketizer
  # depending on which form of telemetry downlink
  # you wish to use

  instance imx_tlmSend: Svc.TlmChan base id 0x0C00 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 97

  #instance tlmSend: Svc.TlmPacketizer base id 0x0C00 \
  #    queue size Default.QUEUE_SIZE \
  #    stack size Default.STACK_SIZE \
  #    priority 97

  instance imx_prmDb: Svc.PrmDb base id 0x0D00 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 96

  instance imx_hubComQueue: Svc.ComQueue base id 0x4500 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 100

  instance imx_proxySequencer: Components.CmdSequenceForwarder base id 0x4700 \
      queue size Default.QUEUE_SIZE \
      stack size Default.STACK_SIZE \
      priority 100 \

  instance imx_proxyGroundInterface: Components.CmdSequenceForwarder base id 0x4800 \
      queue size Default.QUEUE_SIZE \
      stack size Default.STACK_SIZE \
      priority 100 \

  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------

  instance imx_health: Svc.Health base id 0x1000 \
    queue size 25

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  @ Communications driver. May be swapped with other com drivers like UART or TCP
  instance imx_comDriver: Drv.TcpServer base id 0x2000

  instance imx_framer: Svc.Framer base id 0x2100

  instance imx_fatalAdapter: Svc.AssertFatalAdapter base id 0x2200

  instance imx_fatalHandler: Svc.FatalHandler base id 0x2300

  instance imx_bufferManager: Svc.BufferManager base id 0x2400

  instance imx_chronoTime: Svc.ChronoTime base id 0x2500

  instance imx_rateGroupDriver: Svc.RateGroupDriver base id 0x2600

  instance imx_textLogger: Svc.PassiveTextLogger base id 0x2800

  instance imx_deframer: Svc.Deframer base id 0x2900

  instance imx_systemResources: Svc.SystemResources base id 0x2A00

  instance imx_comStub: Svc.ComStub base id 0x2B00

  instance imx_hub: Svc.GenericHub base id 0x4000

  instance imx_hubComDriver: Drv.TcpServer base id 0x4100

  instance imx_hubComStub: Svc.ComStub base id 0x4200

  instance imx_hubDeframer: Svc.Deframer base id 0x4300

  instance imx_hubFramer: Svc.Framer base id 0x4400

  instance imx_cmdSplitter: Svc.CmdSplitter base id 0x4600

}