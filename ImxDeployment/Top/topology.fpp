module ImxDeployment {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

  enum Ports_RateGroups {
    rateGroup1
    rateGroup2
    rateGroup3
  }

  topology ImxDeployment {

    # ----------------------------------------------------------------------
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance imx_health
    instance imx_blockDrv
    instance imx_tlmSend
    instance imx_cmdDisp
    instance imx_cmdSeq
    instance imx_comDriver
    instance imx_comQueue
    instance imx_comStub
    instance imx_deframer
    instance imx_eventLogger
    instance imx_fatalAdapter
    instance imx_fatalHandler
    instance imx_fileDownlink
    instance imx_fileManager
    instance imx_fileUplink
    instance imx_bufferManager
    instance imx_framer
    instance imx_chronoTime
    instance imx_prmDb
    instance imx_rateGroup1
    instance imx_rateGroup2
    instance imx_rateGroup3
    instance imx_rateGroupDriver
    instance imx_textLogger
    instance imx_systemResources

    instance imx_hub
    instance imx_hubComDriver
    instance imx_hubComStub
    instance imx_hubComQueue
    instance imx_hubDeframer
    instance imx_hubFramer
    instance imx_cmdSplitter
    
    instance imx_proxySequencer
    instance imx_proxyGroundInterface

    # ----------------------------------------------------------------------
    # Pattern graph specifiers
    # ----------------------------------------------------------------------

    command connections instance imx_cmdDisp

    event connections instance imx_eventLogger

    param connections instance imx_prmDb

    telemetry connections instance imx_tlmSend

    text event connections instance imx_textLogger

    time connections instance imx_chronoTime

    health connections instance imx_health

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections Downlink {

      imx_eventLogger.PktSend -> imx_comQueue.comQueueIn[0]
      imx_tlmSend.PktSend -> imx_comQueue.comQueueIn[1]
      imx_fileDownlink.bufferSendOut -> imx_comQueue.buffQueueIn[0]

      imx_comQueue.comQueueSend -> imx_framer.comIn
      imx_comQueue.buffQueueSend -> imx_framer.bufferIn

      imx_framer.framedAllocate -> imx_bufferManager.bufferGetCallee
      imx_framer.framedOut -> imx_comStub.comDataIn
      imx_framer.bufferDeallocate -> imx_fileDownlink.bufferReturn

      imx_comDriver.deallocate -> imx_bufferManager.bufferSendIn
      imx_comDriver.ready -> imx_comStub.drvConnected

      imx_comStub.comStatus -> imx_framer.comStatusIn
      imx_framer.comStatusOut -> imx_comQueue.comStatusIn
      imx_comStub.drvDataOut -> imx_comDriver.$send

    }

    connections FaultProtection {
      imx_eventLogger.FatalAnnounce -> imx_fatalHandler.FatalReceive
    }

    connections RateGroups {
      # Block driver
      imx_blockDrv.CycleOut -> imx_rateGroupDriver.CycleIn

      # Rate group 1
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> imx_rateGroup1.CycleIn
      imx_rateGroup1.RateGroupMemberOut[0] -> imx_tlmSend.Run
      imx_rateGroup1.RateGroupMemberOut[1] -> imx_fileDownlink.Run
      imx_rateGroup1.RateGroupMemberOut[2] -> imx_systemResources.run

      # Rate group 2
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup2] -> imx_rateGroup2.CycleIn
      imx_rateGroup2.RateGroupMemberOut[1] -> imx_cmdSeq.schedIn

      # Rate group 3
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup3] -> imx_rateGroup3.CycleIn
      imx_rateGroup3.RateGroupMemberOut[0] -> imx_health.Run
      imx_rateGroup3.RateGroupMemberOut[1] -> imx_blockDrv.Sched
      imx_rateGroup3.RateGroupMemberOut[2] -> imx_bufferManager.schedIn
    }

    connections Sequencer {
      # imx_cmdSeq.comCmdOut -> imx_cmdDisp.seqCmdBuff
      imx_cmdSeq.comCmdOut -> imx_cmdSplitter.CmdBuff[1]
      imx_cmdSplitter.forwardSeqCmdStatus[1] -> imx_cmdSeq.cmdResponseIn
      # imx_cmdDisp.seqCmdStatus -> imx_cmdSeq.cmdResponseIn
    }

    connections Uplink {

      imx_comDriver.allocate -> imx_bufferManager.bufferGetCallee
      imx_comDriver.$recv -> imx_comStub.drvDataIn
      imx_comStub.comDataOut -> imx_deframer.framedIn

      imx_deframer.framedDeallocate -> imx_bufferManager.bufferSendIn
      # imx_deframer.comOut -> imx_cmdDisp.seqCmdBuff
      imx_deframer.comOut -> imx_cmdSplitter.CmdBuff[0]
      imx_cmdSplitter.LocalCmd[0] -> imx_proxyGroundInterface.seqCmdBuf
      imx_cmdSplitter.LocalCmd[1] -> imx_proxySequencer.seqCmdBuf

      imx_proxyGroundInterface.comCmdOut -> imx_cmdDisp.seqCmdBuff
      imx_proxySequencer.comCmdOut -> imx_cmdDisp.seqCmdBuff

      # imx_cmdDisp.seqCmdStatus -> imx_deframer.cmdResponseIn
      imx_cmdDisp.seqCmdStatus -> imx_proxyGroundInterface.cmdResponseIn
      imx_cmdDisp.seqCmdStatus -> imx_proxySequencer.cmdResponseIn

      imx_proxyGroundInterface.seqCmdStatus -> imx_cmdSplitter.seqCmdStatus[0]
      imx_proxySequencer.seqCmdStatus -> imx_cmdSplitter.seqCmdStatus[1]

      imx_cmdSplitter.forwardSeqCmdStatus[0] -> imx_deframer.cmdResponseIn

      imx_deframer.bufferAllocate -> imx_bufferManager.bufferGetCallee
      imx_deframer.bufferOut -> imx_fileUplink.bufferSendIn
      imx_deframer.bufferDeallocate -> imx_bufferManager.bufferSendIn
      imx_fileUplink.bufferSendOut -> imx_bufferManager.bufferSendIn
    }

    connections ImxDeployment {
      # Add here connections to user-defined components
    }

    connections send_hub {
      imx_hub.dataOut -> imx_hubFramer.bufferIn
      imx_hub.dataOutAllocate -> imx_bufferManager.bufferGetCallee

      imx_hubFramer.framedOut -> imx_hubComDriver.$send
      imx_hubFramer.bufferDeallocate -> imx_bufferManager.bufferSendIn
      imx_hubFramer.framedAllocate -> imx_bufferManager.bufferGetCallee

      imx_hubComDriver.deallocate -> imx_bufferManager.bufferSendIn
    }

    connections recv_hub {
      imx_hubComDriver.$recv -> imx_hubDeframer.framedIn
      imx_hubComDriver.allocate -> imx_bufferManager.bufferGetCallee
      
      imx_hubDeframer.bufferOut -> imx_hub.dataIn 
      imx_hubDeframer.framedDeallocate -> imx_bufferManager.bufferSendIn
      imx_hubDeframer.bufferAllocate -> imx_bufferManager.bufferGetCallee

      imx_hub.dataInDeallocate -> imx_bufferManager.bufferSendIn
    }

    connections hub {
      imx_hub.LogSend -> imx_eventLogger.LogRecv
      imx_hub.TlmSend -> imx_tlmSend.TlmRecv
      
      imx_cmdSplitter.RemoteCmd[0] -> imx_hub.portIn[0]
      imx_cmdSplitter.RemoteCmd[1] -> imx_hub.portIn[1]
      imx_hub.portOut[0] -> imx_cmdSplitter.seqCmdStatus[0]
      imx_hub.portOut[1] -> imx_cmdSplitter.seqCmdStatus[1]
    }

  }

}
