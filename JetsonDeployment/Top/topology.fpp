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
    instance jetson_chronoTime
    instance jetson_rateGroup1
    instance jetson_rateGroup2
    instance jetson_rateGroup3
    instance jetson_rateGroupDriver
    instance jetson_systemResources
    instance jetson_timer
    instance jetson_comDriver
    instance jetson_cmdSeq

    # SCALES SVC MANAGERS
    instance jetson_lucidCamera
    instance jetson_mlManager
    instance jetson_watchdogManager
    instance jetson_pwrModeManager
    instance jetson_thermalManager
    instance jetson_gpioWatchdogDriver

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
      # Core events and telemetry to communication queue
      CdhCore.events.PktSend -> ComCcsds.comQueue.comPacketQueueIn[ComCcsds.Ports_ComPacketQueue.EVENTS]
      CdhCore.tlmSend.PktSend -> ComCcsds.comQueue.comPacketQueueIn[ComCcsds.Ports_ComPacketQueue.TELEMETRY]

      # Router to Command Dispatcher
      ComCcsds.fprimeRouter.commandOut -> CdhCore.cmdDisp.seqCmdBuff
      CdhCore.cmdDisp.seqCmdStatus -> ComCcsds.fprimeRouter.cmdResponseIn
      
    }

    connections ComCcsds_FileHandling {
      # File Downlink to Communication Queue
      FileHandling.fileDownlink.bufferSendOut -> ComCcsds.comQueue.bufferQueueIn[ComCcsds.Ports_ComBufferQueue.FILE]
      ComCcsds.comQueue.bufferReturnOut[ComCcsds.Ports_ComBufferQueue.FILE] -> FileHandling.fileDownlink.bufferReturn

      # Router to File Uplink
      ComCcsds.fprimeRouter.fileOut -> FileHandling.fileUplink.bufferSendIn
      FileHandling.fileUplink.bufferSendOut -> ComCcsds.fprimeRouter.fileBufferReturnIn
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
    }

    connections CdhCore_cmdSeq {
      # Command Sequencer
      jetson_cmdSeq.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff
      CdhCore.cmdDisp.seqCmdStatus -> jetson_cmdSeq.cmdResponseIn
    }

    connections JetsonDeployment {

      # Add here connections to user-defined components

      jetson_lucidCamera.sendFile -> FileHandling.fileDownlink.SendFile

      # powerModeSend: JetsonPowerModeManager → hub → IMX PowerManager
      # jetson_pwrModeManager.powerModeSend -> jetson_hub.portIn[2]

      # powerModeRecieve: IMX PowerManager → hub → JetsonPowerModeManager
      # jetson_hub.portOut[2] -> jetson_pwrModeManager.powerModeReceive

      # jetsonPowerStateSend: JetsonPowerModeManager → hub → IMX PowerManager
      # jetson_pwrModeManager.jetsonPowerStateSend -> jetson_hub.portIn[3]

      # jetsonPowerStateReceive: IMX PowerManager → hub → JetsonPowerModeManager
      # jetson_hub.portOut[3] -> jetson_pwrModeManager.jetsonPowerStateReceive

      jetson_watchdogManager.gpioWatchDog -> jetson_gpioWatchdogDriver.gpioWrite

    }

  }

}
