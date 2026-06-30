module JetsonDeployment {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

  enum Ports_RateGroups {
    rateGroup1
    rateGroup2
    rateGroup3
  }

  enum Ports_ComPacketQueue {
    EVENTS,
    TELEMETRY
  }

   enum Ports_ComBufferQueue{
        FILE_DOWNLINK
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
    instance chronoTime
    instance rateGroup1
    instance rateGroup2
    instance rateGroup3
    instance rateGroupDriver
    instance systemResources
    instance timer
    instance comDriver
    instance cmdSeq

  # ----------------------------------------------------------------------
  # Pattern graph specifiers
  # ----------------------------------------------------------------------

    command connections instance CdhCore.cmdDisp
    event connections instance CdhCore.events
    telemetry connections instance CdhCore.tlmSend
    text event connections instance CdhCore.textLogger
    health connections instance CdhCore.$health
    param connections instance FileHandling.prmDb
    time connections instance chronoTime

  # ----------------------------------------------------------------------
  # Telemetry packets (only used when TlmPacketizer is used)
  # ----------------------------------------------------------------------

    # include "JetsonDeploymentPackets.fppi"

  # ----------------------------------------------------------------------
  # Direct graph specifiers
  # ----------------------------------------------------------------------
  # ----------------------------------------------------------------------
  # Instances used in the topology
  # ----------------------------------------------------------------------

    # Core SCALES Components
    instance jetson_lucidCamera
    instance jetson_mlManager

    # SCALES SVC Drivers
    instance gpioWatchdogDriver

    # SCALES SVC Managers
    instance jetson_pwrModeManager
    instance jetson_thermalManager
    instance jetson_watchdogManager


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
      comDriver.allocate      -> ComCcsds.commsBufferManager.bufferGetCallee
      comDriver.deallocate    -> ComCcsds.commsBufferManager.bufferSendIn
      
      # ComDriver <-> ComStub (Uplink)
      comDriver.$recv                     -> ComCcsds.comStub.drvReceiveIn
      ComCcsds.comStub.drvReceiveReturnOut -> comDriver.recvReturnIn
      
      # ComStub <-> ComDriver (Downlink)
      ComCcsds.comStub.drvSendOut      -> comDriver.$send
      comDriver.ready         -> ComCcsds.comStub.drvConnected
    }

    connections FileHandling_DataProducts {
      # Data Products to File Downlink
      DataProducts.dpCat.fileOut -> FileHandling.fileDownlink.SendFile
      FileHandling.fileDownlink.FileComplete -> DataProducts.dpCat.fileDone
    }

    connections RateGroups {
      # timer to drive rate group
      timer.CycleOut -> rateGroupDriver.CycleIn

      # Rate group 1
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> rateGroup1.CycleIn
      rateGroup1.RateGroupMemberOut[0] -> CdhCore.tlmSend.Run
      rateGroup1.RateGroupMemberOut[1] -> FileHandling.fileDownlink.Run
      rateGroup1.RateGroupMemberOut[2] -> systemResources.run
      rateGroup1.RateGroupMemberOut[3] -> ComCcsds.comQueue.run
      rateGroup1.RateGroupMemberOut[4] -> ComCcsds.aggregator.timeout

      # Rate group 2
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup2] -> rateGroup2.CycleIn
      rateGroup2.RateGroupMemberOut[0] -> cmdSeq.schedIn
      rateGroup2.RateGroupMemberOut[1] -> jetson_pwrModeManager.schedIn
      rateGroup2.RateGroupMemberOut[2] -> jetson_thermalManager.run
      rateGroup2.RateGroupMemberOut[3] -> jetson_watchdogManager.run

      # Rate group 3
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup3] -> rateGroup3.CycleIn
      rateGroup3.RateGroupMemberOut[0] -> CdhCore.$health.Run
      rateGroup3.RateGroupMemberOut[1] -> ComCcsds.commsBufferManager.schedIn
      rateGroup3.RateGroupMemberOut[2] -> DataProducts.dpBufferManager.schedIn
      rateGroup3.RateGroupMemberOut[3] -> DataProducts.dpWriter.schedIn
      rateGroup3.RateGroupMemberOut[4] -> DataProducts.dpMgr.schedIn
    }
    
    
    connections CdhCore_cmdSeq {
      # Command Sequencer
      cmdSeq.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff
      CdhCore.cmdDisp.seqCmdStatus -> cmdSeq.cmdResponseIn
    }

    connections JetsonDeployment {
      # Add here connections to user-defined components

      #jetson_lucidCamera.sendFile -> jetson_fileDownlink.SendFile
      jetson_watchdogManager.gpioWatchDog -> gpioWatchdogDriver.gpioWrite
      
      # JetsonManager -> hub -> JetsonPowerModeManager
      # jetson_hub.serialOut[2] -> jetson_pwrModeManager.powerModeReceive
      # JetsonPowerModeManager -> hub -> JetsonManager
      # jetson_pwrModeManager.powerModeSend -> jetson_hub.serialIn[2]
      # JetsonManager -> hub -> JetsonPowerModeManager
      # jetson_hub.serialOut[3] -> jetson_pwrModeManager.jetsonPowerStateReceive
      # JetsonPowerModeManager -> hub -> JetsonManager
      # jetson_pwrModeManager.jetsonPowerStateSend -> jetson_hub.serialIn[3]

    }

    #  connections send_hub {
    #   jetson_hub.cmdDispOut[0] -> jetson_proxyGroundInterface.seqCmdBuf
    #   jetson_proxyGroundInterface.comCmdOut -> jetson_cmdDisp.seqCmdBuff[0]
    #   jetson_cmdDisp.seqCmdStatus[0] -> jetson_proxyGroundInterface.cmdResponseIn
    #   jetson_proxyGroundInterface.seqCmdStatus -> jetson_hub.cmdRespIn[0]

    #   jetson_hub.cmdDispOut[1] -> jetson_proxySequencer.seqCmdBuf
    #   jetson_proxySequencer.comCmdOut -> jetson_cmdDisp.seqCmdBuff[1]
    #   jetson_cmdDisp.seqCmdStatus[1] -> jetson_proxySequencer.cmdResponseIn
    #   jetson_proxySequencer.seqCmdStatus -> jetson_hub.cmdRespIn[1]
    #  }

    #  connections recv_hub {
    #   jetson_hubComDriver.$recv -> jetson_hubByteStreamAdapter.fromByteStreamDriver
    #   jetson_hubByteStreamAdapter.bufferOut -> jetson_hub.fromBufferDriver
    #   jetson_hub.fromBufferDriverReturn -> jetson_hubByteStreamAdapter.bufferOutReturn
    #  }

    #  connections hub {
    #   jetson_hub.toBufferDriver -> jetson_hubByteStreamAdapter.bufferIn
    #   jetson_hubByteStreamAdapter.bufferInReturn -> jetson_hub.toBufferDriverReturn

    #   jetson_hubByteStreamAdapter.toByteStreamDriver -> jetson_hubComDriver.$send
    #   jetson_hubByteStreamAdapter.fromByteStreamDriverReturn -> jetson_hubComDriver.recvReturnIn

    #   jetson_hub.allocate -> jetson_bufferManager.bufferGetCallee
    #   jetson_hub.deallocate -> jetson_bufferManager.bufferSendIn

    #   jetson_hubComDriver.allocate -> jetson_bufferManager.bufferGetCallee
    #   jetson_hubComDriver.deallocate -> jetson_bufferManager.bufferSendIn
    #   jetson_hubComDriver.ready -> jetson_hubByteStreamAdapter.byteStreamDriverReady
    #  }

  }

}
