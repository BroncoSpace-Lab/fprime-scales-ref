module QualcommDeployment {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

  enum Ports_RateGroups {
    rateGroup1
    rateGroup2
    rateGroup3
  }

  topology QualcommDeployment {

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
    instance qualcomm_lucidCamera
    instance qualcomm_mlManager
    # instance qualcomm_pwrModeManager
    # instance qualcomm_thermalManager
    # instance qualcomm_watchdogManager

    instance qualcomm_systemResources

    instance qualcomm_hub
    instance qualcomm_hubComDriver
    instance qualcomm_hubComAdapter
    instance qualcomm_hubBufferManager
    instance qualcomm_hubFramer
    instance qualcomm_hubFrameAccumulator
    instance qualcomm_hubDeframer
    instance qualcomm_hubComStub
    instance qualcomm_hubIoBufferManager

    instance qualcomm_rateGroup1
    instance qualcomm_rateGroup2
    instance qualcomm_rateGroup3
    instance qualcomm_rateGroupDriver

    instance qualcomm_cmdSeq
    instance qualcomm_chronoTime
    instance qualcomm_timer
    instance qualcomm_comDriver

    # instance qualcomm_gpioWatchdogDriver
    instance qualcomm_proxySequencer
    instance qualcomm_proxyGroundInterface

  # ----------------------------------------------------------------------
  # Pattern graph specifiers
  # ----------------------------------------------------------------------

    command connections instance CdhCore.cmdDisp
    event connections instance CdhCore.events
    telemetry connections instance CdhCore.tlmSend
    text event connections instance CdhCore.textLogger
    health connections instance CdhCore.$health
    param connections instance FileHandling.prmDb
    time connections instance qualcomm_chronoTime

  # ----------------------------------------------------------------------
  # Telemetry packets (only used when TlmPacketizer is used)
  # ----------------------------------------------------------------------

    # include "QualcommDeploymentPackets.fppi"

  # ----------------------------------------------------------------------
  # Direct graph specifiers
  # ----------------------------------------------------------------------

  connections ComCcsds_CdhCore {

      # Core events and telemetry are forwarded over hub to i.MX.
      # i.MX injects these packets into its local ComFprime queue for host GDS downlink.
      CdhCore.events.PktSend -> qualcomm_hub.serialIn[2]
      CdhCore.tlmSend.PktSend -> qualcomm_hub.serialIn[3]

      # Router to Command Dispatcher
      ComCcsds.fprimeRouter.commandOut -> CdhCore.cmdDisp.seqCmdBuff[0]
      CdhCore.cmdDisp.seqCmdStatus[0] -> ComCcsds.fprimeRouter.cmdResponseIn

    }

    connections Communications {

      # ComDriver buffer allocations
      qualcomm_comDriver.allocate -> ComCcsds.commsBufferManager.bufferGetCallee
      qualcomm_comDriver.deallocate -> ComCcsds.commsBufferManager.bufferSendIn

      # ComDriver <-> ComStub (Uplink)
      qualcomm_comDriver.$recv -> ComCcsds.comStub.drvReceiveIn
      ComCcsds.comStub.drvReceiveReturnOut -> qualcomm_comDriver.recvReturnIn

      # ComStub <-> ComDriver (Downlink)
      ComCcsds.comStub.drvSendOut -> qualcomm_comDriver.$send
      qualcomm_comDriver.ready -> ComCcsds.comStub.drvConnected

    }

    connections FileHandling_DataProducts {

      # Data Products to File Downlink
      DataProducts.dpCat.fileOut -> FileHandling.fileDownlink.SendFile
      FileHandling.fileDownlink.FileComplete -> DataProducts.dpCat.fileDone

    }

    connections RateGroups {

      # timer to drive rate group
      qualcomm_timer.CycleOut -> qualcomm_rateGroupDriver.CycleIn

      # Rate group 1
      qualcomm_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> qualcomm_rateGroup1.CycleIn
      qualcomm_rateGroup1.RateGroupMemberOut[0] -> CdhCore.tlmSend.Run
      qualcomm_rateGroup1.RateGroupMemberOut[1] -> FileHandling.fileDownlink.Run
      qualcomm_rateGroup1.RateGroupMemberOut[2] -> qualcomm_systemResources.run
      qualcomm_rateGroup1.RateGroupMemberOut[3] -> ComCcsds.comQueue.run
      qualcomm_rateGroup1.RateGroupMemberOut[4] -> ComCcsds.aggregator.timeout

      # Rate group 2
      qualcomm_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup2] -> qualcomm_rateGroup2.CycleIn
      qualcomm_rateGroup2.RateGroupMemberOut[0] -> qualcomm_cmdSeq.schedIn
      qualcomm_rateGroup2.RateGroupMemberOut[1] -> qualcomm_pwrModeManager.schedIn
      qualcomm_rateGroup2.RateGroupMemberOut[2] -> qualcomm_thermalManager.run
      qualcomm_rateGroup2.RateGroupMemberOut[3] -> qualcomm_watchdogManager.run

      # Rate group 3
      qualcomm_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup3] -> qualcomm_rateGroup3.CycleIn
      qualcomm_rateGroup3.RateGroupMemberOut[0] -> CdhCore.$health.Run
      qualcomm_rateGroup3.RateGroupMemberOut[1] -> ComCcsds.commsBufferManager.schedIn
      qualcomm_rateGroup3.RateGroupMemberOut[2] -> DataProducts.dpBufferManager.schedIn
      qualcomm_rateGroup3.RateGroupMemberOut[3] -> DataProducts.dpWriter.schedIn
      qualcomm_rateGroup3.RateGroupMemberOut[4] -> DataProducts.dpMgr.schedIn
      qualcomm_rateGroup3.RateGroupMemberOut[5] -> qualcomm_hubBufferManager.schedIn
      qualcomm_rateGroup3.RateGroupMemberOut[6] -> qualcomm_hubIoBufferManager.schedIn

    }

    connections CdhCore_cmdSeq {

      # Command Sequencer
      qualcomm_cmdSeq.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff[1]
      CdhCore.cmdDisp.seqCmdStatus[1] -> qualcomm_cmdSeq.cmdResponseIn

    }

    connections QualcommDeployment {

      # Add here connections to user-defined components
      qualcomm_lucidCamera.sendFile -> FileHandling.fileDownlink.SendFile

      # Power mode: Jetson -> i.MX
      # qualcomm_pwrModeManager.powerModeSend -> qualcomm_hub.serialIn[0]

      # Power mode request/state from i.MX -> Jetson
      # qualcomm_hub.serialOut[0] -> qualcomm_pwrModeManager.powerModeReceive

      # Jetson power state: Jetson -> i.MX
      # qualcomm_pwrModeManager.jetsonPowerStateSend -> qualcomm_hub.serialIn[1]

      # Jetson power state request from i.MX -> Jetson
      # qualcomm_hub.serialOut[1] -> qualcomm_pwrModeManager.jetsonPowerStateReceive

      # Local (non-hub) mode-change notification: JetsonPowerModeManager -> i.MX JetsonManager
      # SET_POWER_MODE_cmdHandler's mismatch branch fires this
      # unconditionally right before invoking nvpmodel, so the i.MX side
      # learns about a locally-triggered reboot it would otherwise have zero
      # visibility into (JPSM-013/JM-014/FP-022).
      # qualcomm_pwrModeManager.localModeChangeStarted -> qualcomm_hub.serialIn[6]

      # Jetson thermal readings to data prodcuer
      # qualcomm_thermalManager.jetsonThermalReadOut -> qualcomm_hub.serialIn[5]

      # Jetson thermal readings: all nine sensor readings -> i.MX FPManager
      # qualcomm_thermalManager.jetsonThermalReadingOut -> qualcomm_hub.serialIn[4]

      # qualcomm_watchdogManager.gpioWatchDog -> qualcomm_gpioWatchdogDriver.gpioWrite

    }

    connections send_hub {

      # Frame each complete GenericHub record before passing it to TCP.
      qualcomm_hub.toBufferDriver -> qualcomm_hubComAdapter.bufferIn
      qualcomm_hubComAdapter.bufferInReturn -> qualcomm_hub.toBufferDriverReturn

      qualcomm_hubComAdapter.comOut -> qualcomm_hubFramer.dataIn
      qualcomm_hubFramer.dataReturnOut -> qualcomm_hubComAdapter.comReturnIn

      qualcomm_hubFramer.dataOut -> qualcomm_hubComStub.dataIn
      qualcomm_hubComStub.dataReturnOut -> qualcomm_hubFramer.dataReturnIn
      qualcomm_hubComStub.comStatusOut -> qualcomm_hubFramer.comStatusIn

      qualcomm_hubComStub.drvSendOut -> qualcomm_hubComDriver.$send

    }

    connections recv_hub {

      # Accumulate TCP stream reads into complete frames, then deframe to hub records.
      qualcomm_hubComDriver.$recv -> qualcomm_hubComStub.drvReceiveIn
      qualcomm_hubComStub.drvReceiveReturnOut -> qualcomm_hubComDriver.recvReturnIn

      qualcomm_hubComStub.dataOut -> qualcomm_hubFrameAccumulator.dataIn
      qualcomm_hubFrameAccumulator.dataReturnOut -> qualcomm_hubComStub.dataReturnIn

      qualcomm_hubFrameAccumulator.dataOut -> qualcomm_hubDeframer.dataIn
      qualcomm_hubDeframer.dataReturnOut -> qualcomm_hubFrameAccumulator.dataReturnIn

      qualcomm_hubDeframer.dataOut -> qualcomm_hubComAdapter.comIn
      qualcomm_hubComAdapter.comInReturn -> qualcomm_hubDeframer.dataReturnIn

      qualcomm_hubComAdapter.bufferOut -> qualcomm_hub.fromBufferDriver
      qualcomm_hub.fromBufferDriverReturn -> qualcomm_hubComAdapter.bufferOutReturn

    }

    connections hub {

      # GenericHub retained records use the large packet pool.
      qualcomm_hub.allocate -> qualcomm_hubBufferManager.bufferGetCallee
      qualcomm_hub.deallocate -> qualcomm_hubBufferManager.bufferSendIn

      # TCP driver receive buffers use the IO pool.
      qualcomm_hubComDriver.allocate -> qualcomm_hubIoBufferManager.bufferGetCallee
      qualcomm_hubComDriver.deallocate -> qualcomm_hubIoBufferManager.bufferSendIn

      # Framer output buffers go directly to TCP, so they use the IO pool.
      qualcomm_hubFramer.bufferAllocate -> qualcomm_hubIoBufferManager.bufferGetCallee
      qualcomm_hubFramer.bufferDeallocate -> qualcomm_hubIoBufferManager.bufferSendIn

      # FrameAccumulator output buffers become retained hub records.
      qualcomm_hubFrameAccumulator.bufferAllocate -> qualcomm_hubBufferManager.bufferGetCallee
      qualcomm_hubFrameAccumulator.bufferDeallocate -> qualcomm_hubBufferManager.bufferSendIn

      qualcomm_hubComDriver.ready -> qualcomm_hubComStub.drvConnected

      # Channel 0 carries Qualcomm file-downlink packets to the i.MX downlink stack.
      FileHandling.fileDownlink.bufferSendOut -> qualcomm_hub.bufferIn[0]
      qualcomm_hub.bufferInReturn[0] -> FileHandling.fileDownlink.bufferReturn

      # Channel 1 carries file-uplink packets received and routed by the i.MX.
      qualcomm_hub.bufferOut[1] -> FileHandling.fileUplink.bufferSendIn
      FileHandling.fileUplink.bufferSendOut -> qualcomm_hub.bufferOutReturn[1]

      # Channel 0: GDS remote commands from i.MX
      qualcomm_hub.cmdDispOut[0] -> qualcomm_proxyGroundInterface.seqCmdBuf
      qualcomm_proxyGroundInterface.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff[2]
      CdhCore.cmdDisp.seqCmdStatus[2] -> qualcomm_proxyGroundInterface.cmdResponseIn
      qualcomm_proxyGroundInterface.seqCmdStatus -> qualcomm_hub.cmdRespIn[0]

      # Channel 1: i.MX command-sequencer remote commands
      qualcomm_hub.cmdDispOut[1] -> qualcomm_proxySequencer.seqCmdBuf
      qualcomm_proxySequencer.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff[3]
      CdhCore.cmdDisp.seqCmdStatus[3] -> qualcomm_proxySequencer.cmdResponseIn
      qualcomm_proxySequencer.seqCmdStatus -> qualcomm_hub.cmdRespIn[1]

    }

  }

}
