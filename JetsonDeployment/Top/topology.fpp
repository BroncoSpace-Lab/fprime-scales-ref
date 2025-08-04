module JetsonDeployment {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

  enum Ports_RateGroups {
    rateGroup1
    rateGroup2
    rateGroup3
  }

  topology JetsonDeployment {

    # ----------------------------------------------------------------------
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance jetson_health
    instance jetson_blockDrv
    instance jetson_tlmSend
    instance jetson_cmdDisp
    instance jetson_cmdSeq
    instance jetson_comDriver
    instance jetson_comQueue
    instance jetson_comStub
    instance jetson_deframer
    instance jetson_eventLogger
    instance jetson_fatalAdapter
    instance jetson_fatalHandler
    instance jetson_fileDownlink
    instance jetson_fileManager
    instance jetson_fileUplink
    instance jetson_bufferManager
    instance jetson_framer
    instance jetson_chronoTime
    instance jetson_prmDb
    instance jetson_rateGroup1
    instance jetson_rateGroup2
    instance jetson_rateGroup3
    instance jetson_rateGroupDriver
    instance jetson_textLogger
    instance jetson_systemResources

    instance jetson_hub
    instance jetson_hubComDriver
    instance jetson_hubComStub
    instance jetson_hubComQueue
    instance jetson_hubDeframer
    instance jetson_hubFramer
    instance jetson_proxyGroundInterface
    instance jetson_proxySequencer
    instance jetson_timer

    instance jetson_lucidCamera
    instance jetson_mlManager

    # ----------------------------------------------------------------------
    # Pattern graph specifiers
    # ----------------------------------------------------------------------

    command connections instance jetson_cmdDisp

    # event connections instance jetson_eventLogger
    event connections instance jetson_hub

    param connections instance jetson_prmDb

    # telemetry connections instance jetson_tlmSend
    telemetry connections instance jetson_hub

    text event connections instance jetson_textLogger

    time connections instance jetson_chronoTime

    health connections instance jetson_health

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections Downlink {

      # jetson_eventLogger.PktSend -> jetson_comQueue.comQueueIn[0]
      # jetson_tlmSend.PktSend -> jetson_comQueue.comQueueIn[1]
      # jetson_fileDownlink.bufferSendOut -> jetson_comQueue.buffQueueIn[0]

      # jetson_comQueue.comQueueSend -> jetson_framer.comIn
      # jetson_comQueue.buffQueueSend -> jetson_framer.bufferIn

      # jetson_framer.framedAllocate -> jetson_bufferManager.bufferGetCallee
      # jetson_framer.framedOut -> jetson_comStub.comDataIn
      # jetson_framer.bufferDeallocate -> jetson_fileDownlink.bufferReturn

      # jetson_comDriver.deallocate -> jetson_bufferManager.bufferSendIn
      # jetson_comDriver.ready -> jetson_comStub.drvConnected

      # jetson_comStub.comStatus -> jetson_framer.comStatusIn
      # jetson_framer.comStatusOut -> jetson_comQueue.comStatusIn
      # jetson_comStub.drvDataOut -> jetson_comDriver.$send
<<<<<<< HEAD

      jetson_eventLogger.PktSend -> jetson_comQueue.comQueueIn[0]
      jetson_tlmSend.PktSend -> jetson_comQueue.comQueueIn[1]
      #jetson_fileDownlink.bufferSendOut -> jetson_comQueue.buffQueueIn[0]
=======
      
      jetson_eventLogger.PktSend -> jetson_comQueue.comQueueIn[0]
      jetson_tlmSend.PktSend -> jetson_comQueue.comQueueIn[1]
      jetson_fileDownlink.bufferSendOut -> jetson_comQueue.buffQueueIn[0]
>>>>>>> 8c3dcb4c7dbd6e78eb1818b658493725b5e51351

      jetson_comQueue.comQueueSend -> jetson_hubFramer.comIn
      jetson_comQueue.buffQueueSend -> jetson_hubFramer.bufferIn

      jetson_hubFramer.framedAllocate -> jetson_bufferManager.bufferGetCallee
      jetson_hubFramer.framedOut -> jetson_comStub.comDataIn
      jetson_hubFramer.bufferDeallocate -> jetson_fileDownlink.bufferReturn

      jetson_comDriver.deallocate -> jetson_bufferManager.bufferSendIn
      jetson_comDriver.ready -> jetson_comStub.drvConnected

      jetson_comStub.comStatus -> jetson_framer.comStatusIn
      jetson_framer.comStatusOut -> jetson_comQueue.comStatusIn
      jetson_comStub.drvDataOut -> jetson_comDriver.$send

    }

    connections FaultProtection {
      jetson_eventLogger.FatalAnnounce -> jetson_fatalHandler.FatalReceive
    }

    connections RateGroups {
      # Block driver
      jetson_timer.CycleOut -> jetson_rateGroupDriver.CycleIn

      # Rate group 1
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> jetson_rateGroup1.CycleIn
      # rateGroup1.RateGroupMemberOut[0] -> tlmSend.Run
      jetson_rateGroup1.RateGroupMemberOut[1] -> jetson_fileDownlink.Run
      jetson_rateGroup1.RateGroupMemberOut[2] -> jetson_systemResources.run

      # Rate group 2
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup2] -> jetson_rateGroup2.CycleIn
      # rateGroup2.RateGroupMemberOut[0] -> cmdSeq.schedIn

      # Rate group 3
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup3] -> jetson_rateGroup3.CycleIn
      jetson_rateGroup3.RateGroupMemberOut[0] -> jetson_health.Run
      jetson_rateGroup3.RateGroupMemberOut[1] -> jetson_blockDrv.Sched
      jetson_rateGroup3.RateGroupMemberOut[2] -> jetson_bufferManager.schedIn
    }

    connections Sequencer {
      jetson_cmdSeq.comCmdOut -> jetson_cmdDisp.seqCmdBuff
      jetson_cmdDisp.seqCmdStatus -> jetson_cmdSeq.cmdResponseIn
    }

    connections Uplink {

      jetson_comDriver.allocate -> jetson_bufferManager.bufferGetCallee
      jetson_comDriver.$recv -> jetson_comStub.drvDataIn
      jetson_comStub.comDataOut -> jetson_deframer.framedIn

      jetson_deframer.framedDeallocate -> jetson_bufferManager.bufferSendIn
      jetson_deframer.comOut -> jetson_cmdDisp.seqCmdBuff

      jetson_cmdDisp.seqCmdStatus -> jetson_deframer.cmdResponseIn

      jetson_deframer.bufferAllocate -> jetson_bufferManager.bufferGetCallee
      jetson_deframer.bufferOut -> jetson_fileUplink.bufferSendIn
      jetson_deframer.bufferDeallocate -> jetson_bufferManager.bufferSendIn
      jetson_fileUplink.bufferSendOut -> jetson_bufferManager.bufferSendIn
    }

    connections JetsonDeployment {
      # Add here connections to user-defined components

      jetson_lucidCamera.sendFile -> jetson_fileDownlink.SendFile

    }

    connections send_hub {
      jetson_hub.dataOut -> jetson_hubFramer.bufferIn
      jetson_hub.dataOutAllocate -> jetson_bufferManager.bufferGetCallee
      
      jetson_hubFramer.framedOut -> jetson_hubComDriver.$send
      jetson_hubFramer.bufferDeallocate -> jetson_bufferManager.bufferSendIn
      jetson_hubFramer.framedAllocate -> jetson_bufferManager.bufferGetCallee
      
      jetson_hubComDriver.deallocate -> jetson_bufferManager.bufferSendIn

    }

    connections recv_hub {
      jetson_hubComDriver.$recv -> jetson_hubDeframer.framedIn
      jetson_hubComDriver.allocate -> jetson_bufferManager.bufferGetCallee

      jetson_hubDeframer.bufferOut -> jetson_hub.dataIn
      jetson_hubDeframer.bufferAllocate -> jetson_bufferManager.bufferGetCallee
      jetson_hubDeframer.framedDeallocate -> jetson_bufferManager.bufferSendIn

      jetson_hub.dataInDeallocate -> jetson_bufferManager.bufferSendIn
    }

    connections hub {
      jetson_fileDownlink.bufferSendOut -> jetson_hub.buffersIn[0]
      jetson_hub.bufferDeallocate -> jetson_fileDownlink.bufferReturn

      jetson_hub.portOut[0] -> jetson_proxyGroundInterface.seqCmdBuf
      jetson_hub.portOut[1] -> jetson_proxySequencer.seqCmdBuf

      jetson_proxyGroundInterface.comCmdOut -> jetson_cmdDisp.seqCmdBuff
      jetson_proxySequencer.comCmdOut -> jetson_cmdDisp.seqCmdBuff
      
      jetson_cmdDisp.seqCmdStatus -> jetson_proxyGroundInterface.cmdResponseIn
      jetson_cmdDisp.seqCmdStatus -> jetson_proxySequencer.cmdResponseIn

      jetson_proxyGroundInterface.seqCmdStatus -> jetson_hub.portIn[0]
      jetson_proxySequencer.seqCmdStatus -> jetson_hub.portIn[1]

      jetson_hub.buffersOut -> jetson_bufferManager.bufferSendIn
    }

  }

}
