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
  # Subtopology imports
  # ----------------------------------------------------------------------
    import CdhCore.Subtopology
    import ComCcsds.Subtopology
    import DataProducts.Subtopology
    import FileHandling.Subtopology
    
  # ----------------------------------------------------------------------
  # Instances used in the topology
  # ----------------------------------------------------------------------
    instance jetson_lucidCamera
    instance jetson_mlManager
    instance jetson_pwrModeManager
    instance jetson_thermalManager
    instance jetson_watchdogManager

    instance jetson_systemResources

    instance jetson_hub
    instance jetson_hubComDriver
    instance jetson_hubComAdapter
    instance jetson_hubBufferManager
    instance jetson_hubFramer
    instance jetson_hubFrameAccumulator
    instance jetson_hubDeframer
    instance jetson_hubComStub
    instance jetson_hubIoBufferManager

    instance jetson_rateGroup1
    instance jetson_rateGroup2
    instance jetson_rateGroup3
    instance jetson_rateGroupDriver
    instance jetson_cmdSeq
    instance jetson_chronoTime
    instance jetson_timer
    instance jetson_comDriver
    instance jetson_gpioWatchdogDriver
    instance jetson_proxySequencer
    instance jetson_proxyGroundInterface

  # ----------------------------------------------------------------------
  # Pattern graph specifiers
  # ----------------------------------------------------------------------

    command connections instance CdhCore.cmdDisp
    event connections instance CdhCore.events
    telemetry connections instance CdhCore.tlmSend
    text event connections instance CdhCore.textLogger
    health connections instance CdhCore.$health
    param connections instance FileHandling.prmDb
    time connections instance jetson_chronoTime

  # ----------------------------------------------------------------------
  # Telemetry packets (only used when TlmPacketizer is used)
  # ----------------------------------------------------------------------

    # include "JetsonDeploymentPackets.fppi"

  # ----------------------------------------------------------------------
  # Direct graph specifiers
  # ----------------------------------------------------------------------

    connections ComCcsds_CdhCore {
      # Core events and telemetry are forwarded over hub to i.MX.
      # i.MX injects these packets into its local ComCcsds queue for host GDS downlink.
      CdhCore.events.PktSend -> jetson_hub.serialIn[2]
      CdhCore.tlmSend.PktSend -> jetson_hub.serialIn[3]

      # Router to Command Dispatcher
      ComCcsds.fprimeRouter.commandOut -> CdhCore.cmdDisp.seqCmdBuff[0]
      CdhCore.cmdDisp.seqCmdStatus[0] -> ComCcsds.fprimeRouter.cmdResponseIn
      
    }

    connections Communications {
      # ComDriver buffer allocations
      jetson_comDriver.allocate      -> ComCcsds.commsBufferManager.bufferGetCallee
      jetson_comDriver.deallocate    -> ComCcsds.commsBufferManager.bufferSendIn
      
      # ComDriver <-> ComStub (Uplink)
      jetson_comDriver.$recv                     -> ComCcsds.comStub.drvReceiveIn
      ComCcsds.comStub.drvReceiveReturnOut -> jetson_comDriver.recvReturnIn
      
      # ComStub <-> ComDriver (Downlink)
      ComCcsds.comStub.drvSendOut      -> jetson_comDriver.$send
      jetson_comDriver.ready         -> ComCcsds.comStub.drvConnected
    }

    connections FileHandling_DataProducts {
      # Data Products to File Downlink
      DataProducts.dpCat.fileOut -> FileHandling.fileDownlink.SendFile
      FileHandling.fileDownlink.FileComplete -> DataProducts.dpCat.fileDone
    }

    connections RateGroups {
      # timer to drive rate group
      jetson_timer.CycleOut -> jetson_rateGroupDriver.CycleIn

      # Rate group 1
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> jetson_rateGroup1.CycleIn
      jetson_rateGroup1.RateGroupMemberOut[0] -> CdhCore.tlmSend.Run
      jetson_rateGroup1.RateGroupMemberOut[1] -> FileHandling.fileDownlink.Run
      jetson_rateGroup1.RateGroupMemberOut[2] -> jetson_systemResources.run
      jetson_rateGroup1.RateGroupMemberOut[3] -> ComCcsds.comQueue.run
      jetson_rateGroup1.RateGroupMemberOut[4] -> ComCcsds.aggregator.timeout

      # Rate group 2
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup2] -> jetson_rateGroup2.CycleIn
      jetson_rateGroup2.RateGroupMemberOut[0] -> jetson_cmdSeq.schedIn
      jetson_rateGroup2.RateGroupMemberOut[1] -> jetson_pwrModeManager.schedIn
      jetson_rateGroup2.RateGroupMemberOut[2] -> jetson_thermalManager.run
      jetson_rateGroup2.RateGroupMemberOut[3] -> jetson_watchdogManager.run

      # Rate group 3
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup3] -> jetson_rateGroup3.CycleIn
      jetson_rateGroup3.RateGroupMemberOut[0] -> CdhCore.$health.Run
      jetson_rateGroup3.RateGroupMemberOut[1] -> ComCcsds.commsBufferManager.schedIn
      jetson_rateGroup3.RateGroupMemberOut[2] -> DataProducts.dpBufferManager.schedIn
      jetson_rateGroup3.RateGroupMemberOut[3] -> DataProducts.dpWriter.schedIn
      jetson_rateGroup3.RateGroupMemberOut[4] -> DataProducts.dpMgr.schedIn
      jetson_rateGroup3.RateGroupMemberOut[5] -> jetson_hubBufferManager.schedIn
      jetson_rateGroup3.RateGroupMemberOut[6] -> jetson_hubIoBufferManager.schedIn
    }

    connections CdhCore_cmdSeq {
      # Command Sequencer
      jetson_cmdSeq.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff[1]
      CdhCore.cmdDisp.seqCmdStatus[1] -> jetson_cmdSeq.cmdResponseIn
    }

    connections JetsonDeployment {

      # Add here connections to user-defined components

      jetson_lucidCamera.sendFile -> FileHandling.fileDownlink.SendFile

      # Power mode: Jetson -> i.MX
      jetson_pwrModeManager.powerModeSend -> jetson_hub.serialIn[0]

      # Power mode request/state from i.MX -> Jetson
      jetson_hub.serialOut[0] -> jetson_pwrModeManager.powerModeReceive

      # Jetson power state: Jetson -> i.MX
      jetson_pwrModeManager.jetsonPowerStateSend -> jetson_hub.serialIn[1]

      # Jetson power state request from i.MX -> Jetson
      jetson_hub.serialOut[1] -> jetson_pwrModeManager.jetsonPowerStateReceive

      jetson_watchdogManager.gpioWatchDog -> jetson_gpioWatchdogDriver.gpioWrite
      

    }

    connections send_hub {
      # Frame each complete GenericHub record before passing it to the UDP link.
      jetson_hub.toBufferDriver -> jetson_hubComAdapter.bufferIn
      jetson_hubComAdapter.bufferInReturn -> jetson_hub.toBufferDriverReturn
      jetson_hubComAdapter.comOut -> jetson_hubFramer.dataIn
      jetson_hubFramer.dataReturnOut -> jetson_hubComAdapter.comReturnIn

      jetson_hubFramer.dataOut -> jetson_hubComStub.dataIn
      jetson_hubComStub.dataReturnOut -> jetson_hubFramer.dataReturnIn
      jetson_hubComStub.comStatusOut -> jetson_hubFramer.comStatusIn
      jetson_hubComStub.drvSendOut -> jetson_hubComDriver.$send
    }


    connections recv_hub {
      # Accumulate transport reads into complete frames, then deframe to hub records.
      jetson_hubComDriver.$recv -> jetson_hubComStub.drvReceiveIn
      jetson_hubComStub.drvReceiveReturnOut -> jetson_hubComDriver.recvReturnIn
      jetson_hubComStub.dataOut -> jetson_hubFrameAccumulator.dataIn
      jetson_hubFrameAccumulator.dataReturnOut -> jetson_hubComStub.dataReturnIn

      jetson_hubFrameAccumulator.dataOut -> jetson_hubDeframer.dataIn
      jetson_hubDeframer.dataReturnOut -> jetson_hubFrameAccumulator.dataReturnIn
      jetson_hubDeframer.dataOut -> jetson_hubComAdapter.comIn
      jetson_hubComAdapter.comInReturn -> jetson_hubDeframer.dataReturnIn

      jetson_hubComAdapter.bufferOut -> jetson_hub.fromBufferDriver
      jetson_hub.fromBufferDriverReturn -> jetson_hubComAdapter.bufferOutReturn
    }

    connections hub {
      jetson_hub.allocate -> jetson_hubBufferManager.bufferGetCallee
      jetson_hub.deallocate -> jetson_hubBufferManager.bufferSendIn

      # Keep transport receive buffers separate from retained packet buffers so
      # a file burst cannot starve the UDP receive task.
      jetson_hubComDriver.allocate -> jetson_hubIoBufferManager.bufferGetCallee
      jetson_hubComDriver.deallocate -> jetson_hubIoBufferManager.bufferSendIn

      jetson_hubFramer.bufferAllocate -> jetson_hubBufferManager.bufferGetCallee
      jetson_hubFramer.bufferDeallocate -> jetson_hubBufferManager.bufferSendIn

      jetson_hubFrameAccumulator.bufferAllocate -> jetson_hubBufferManager.bufferGetCallee
      jetson_hubFrameAccumulator.bufferDeallocate -> jetson_hubBufferManager.bufferSendIn

      jetson_hubComDriver.ready -> jetson_hubComStub.drvConnected

      # Channel 0 carries Jetson file-downlink packets to the i.MX downlink stack.
      FileHandling.fileDownlink.bufferSendOut -> jetson_hub.bufferIn[0]
      jetson_hub.bufferInReturn[0] -> FileHandling.fileDownlink.bufferReturn

      # Channel 1 carries file-uplink packets received and routed by the i.MX.
      jetson_hub.bufferOut[1] -> FileHandling.fileUplink.bufferSendIn
      FileHandling.fileUplink.bufferSendOut -> jetson_hub.bufferOutReturn[1]

      # Channel 0: GDS remote commands from i.MX
      jetson_hub.cmdDispOut[0] -> jetson_proxyGroundInterface.seqCmdBuf
      jetson_proxyGroundInterface.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff[2]
      CdhCore.cmdDisp.seqCmdStatus[2] -> jetson_proxyGroundInterface.cmdResponseIn
      jetson_proxyGroundInterface.seqCmdStatus -> jetson_hub.cmdRespIn[0]

      # Channel 1: i.MX command-sequencer remote commands
      jetson_hub.cmdDispOut[1] -> jetson_proxySequencer.seqCmdBuf
      jetson_proxySequencer.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff[3]
      CdhCore.cmdDisp.seqCmdStatus[3] -> jetson_proxySequencer.cmdResponseIn
      jetson_proxySequencer.seqCmdStatus -> jetson_hub.cmdRespIn[1]
    }
  }

}
