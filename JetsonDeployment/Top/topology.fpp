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
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance jetson_health
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

    instance jetson_fileManager
    instance jetson_fileUplink
    instance jetson_fileDownlink
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
    instance jetson_timer

    instance jetson_frameAccumulator
    instance jetson_fprimeRouter

    # Hub-pattern instances commented out for now
    instance jetson_hub
    instance jetson_hubComDriver
    instance jetson_hubByteStreamAdapter
    instance jetson_proxySequencer
    instance jetson_proxyGroundInterface
    

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
    # Subtopology imports
    # ----------------------------------------------------------------------
      import CdhCore.Subtopology
      import ComCcsds.Subtopology
      import DataProducts.Subtopology
      import FileHandling.Subtopology
   

    # ----------------------------------------------------------------------
    # Pattern graph specifiers
    # ----------------------------------------------------------------------

    command connections instance CdhCore.cmdDisp
    
    event connections instance CdhCore.events
    
    telemetry connections instance CdhCore.tlmSend
    
    text event connections instance CdhCore.textLogger
    
    health connections instance CdhCore.$health

    # new things above ^

    #command connections instance jetson_cmdDisp

    #event connections instance jetson_eventLogger

    param connections instance jetson_prmDb

    #telemetry connections instance jetson_tlmSend

    #text event connections instance jetson_textLogger

    time connections instance jetson_chronoTime

    #health connections instance jetson_health

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections Downlink {

      # Jetson downlink packets are forwarded through the hub to the IMX downlink.
      jetson_eventLogger.PktSend -> jetson_hub.serialIn[0]
      jetson_tlmSend.PktSend -> jetson_hub.serialIn[1]
      jetson_fileDownlink.bufferSendOut -> jetson_hub.bufferIn[0]
      jetson_hub.bufferInReturn[0] -> jetson_fileDownlink.bufferReturn

      # ComQueue <-> FprimeFramer
      jetson_comQueue.dataOut -> jetson_framer.dataIn
      jetson_framer.dataReturnOut -> jetson_comQueue.dataReturnIn

      # Buffer management for FprimeFramer
      jetson_framer.bufferAllocate -> jetson_bufferManager.bufferGetCallee
      jetson_framer.bufferDeallocate -> jetson_bufferManager.bufferSendIn

      # FprimeFramer <-> ComStub
      jetson_framer.dataOut -> jetson_comStub.dataIn
      jetson_comStub.dataReturnOut -> jetson_framer.dataReturnIn

      # ComStub <-> ComDriver
      jetson_comStub.drvSendOut -> jetson_comDriver.$send
      jetson_comDriver.ready -> jetson_comStub.drvConnected

      # ComStatus path
      jetson_comStub.comStatusOut -> jetson_framer.comStatusIn
      jetson_framer.comStatusOut -> jetson_comQueue.comStatusIn

    }

    connections FaultProtection {
      jetson_eventLogger.FatalAnnounce -> jetson_fatalHandler.FatalReceive
    }

    connections RateGroups {

      # Linux timer drives rate groups
      jetson_timer.CycleOut -> jetson_rateGroupDriver.CycleIn

      # Rate group 1
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> jetson_rateGroup1.CycleIn
      jetson_rateGroup1.RateGroupMemberOut[0] -> jetson_tlmSend.Run
      jetson_rateGroup1.RateGroupMemberOut[1] -> jetson_fileDownlink.Run
      jetson_rateGroup1.RateGroupMemberOut[2] -> jetson_systemResources.run
      jetson_rateGroup1.RateGroupMemberOut[3] -> jetson_comQueue.run

      # Rate group 2
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup2] -> jetson_rateGroup2.CycleIn
      jetson_rateGroup2.RateGroupMemberOut[0] -> jetson_cmdSeq.schedIn
      jetson_rateGroup2.RateGroupMemberOut[1] -> jetson_pwrModeManager.schedIn
      jetson_rateGroup2.RateGroupMemberOut[2] -> jetson_thermalManager.run
      jetson_rateGroup2.RateGroupMemberOut[3] -> jetson_watchdogManager.run

      # Rate group 3
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup3] -> jetson_rateGroup3.CycleIn
      jetson_rateGroup3.RateGroupMemberOut[0] -> jetson_health.Run
      jetson_rateGroup3.RateGroupMemberOut[1] -> jetson_bufferManager.schedIn

    }

    connections Sequencer {
      jetson_cmdSeq.comCmdOut -> jetson_cmdDisp.seqCmdBuff[2]
      jetson_cmdDisp.seqCmdStatus[2] -> jetson_cmdSeq.cmdResponseIn
    }

    connections Uplink {

      # ComDriver buffer allocations
      jetson_comDriver.allocate -> jetson_bufferManager.bufferGetCallee
      jetson_comDriver.deallocate -> jetson_bufferManager.bufferSendIn

      # ComDriver <-> ComStub
      jetson_comDriver.$recv -> jetson_comStub.drvReceiveIn
      jetson_comStub.drvReceiveReturnOut -> jetson_comDriver.recvReturnIn

      # ComStub <-> FrameAccumulator
      jetson_comStub.dataOut -> jetson_frameAccumulator.dataIn
      jetson_frameAccumulator.dataReturnOut -> jetson_comStub.dataReturnIn

      # FrameAccumulator buffer allocations
      jetson_frameAccumulator.bufferDeallocate -> jetson_bufferManager.bufferSendIn
      jetson_frameAccumulator.bufferAllocate -> jetson_bufferManager.bufferGetCallee

      # FrameAccumulator <-> FprimeDeframer
      jetson_frameAccumulator.dataOut -> jetson_deframer.dataIn
      jetson_deframer.dataReturnOut -> jetson_frameAccumulator.dataReturnIn

      # FprimeDeframer <-> FprimeRouter
      jetson_deframer.dataOut -> jetson_fprimeRouter.dataIn
      jetson_fprimeRouter.dataReturnOut -> jetson_deframer.dataReturnIn

      # FprimeRouter buffer allocations
      jetson_fprimeRouter.bufferAllocate -> jetson_bufferManager.bufferGetCallee
      jetson_fprimeRouter.bufferDeallocate -> jetson_bufferManager.bufferSendIn

      # FprimeRouter <-> FileUplink
      # Commands are routed through the IMX hub path.
      jetson_fprimeRouter.fileOut -> jetson_fileUplink.bufferSendIn
      jetson_fileUplink.bufferSendOut -> jetson_fprimeRouter.fileBufferReturnIn

    }

    connections JetsonDeployment {
      # Add here connections to user-defined components
      jetson_lucidCamera.sendFile -> jetson_fileDownlink.SendFile
      jetson_watchdogManager.gpioWatchDog -> gpioWatchdogDriver.gpioWrite

      # JetsonManager -> hub -> JetsonPowerModeManager
      jetson_hub.serialOut[2] -> jetson_pwrModeManager.powerModeReceive

      # JetsonPowerModeManager -> hub -> JetsonManager
      jetson_pwrModeManager.powerModeSend -> jetson_hub.serialIn[2]

      # JetsonManager -> hub -> JetsonPowerModeManager
      jetson_hub.serialOut[3] -> jetson_pwrModeManager.jetsonPowerStateReceive

      # JetsonPowerModeManager -> hub -> JetsonManager
      jetson_pwrModeManager.jetsonPowerStateSend -> jetson_hub.serialIn[3]

    }

     connections send_hub {
      jetson_hub.cmdDispOut[0] -> jetson_proxyGroundInterface.seqCmdBuf
      jetson_proxyGroundInterface.comCmdOut -> jetson_cmdDisp.seqCmdBuff[0]
      jetson_cmdDisp.seqCmdStatus[0] -> jetson_proxyGroundInterface.cmdResponseIn
      jetson_proxyGroundInterface.seqCmdStatus -> jetson_hub.cmdRespIn[0]

      jetson_hub.cmdDispOut[1] -> jetson_proxySequencer.seqCmdBuf
      jetson_proxySequencer.comCmdOut -> jetson_cmdDisp.seqCmdBuff[1]
      jetson_cmdDisp.seqCmdStatus[1] -> jetson_proxySequencer.cmdResponseIn
      jetson_proxySequencer.seqCmdStatus -> jetson_hub.cmdRespIn[1]
     }

     connections recv_hub {
      jetson_hubComDriver.$recv -> jetson_hubByteStreamAdapter.fromByteStreamDriver
      jetson_hubByteStreamAdapter.bufferOut -> jetson_hub.fromBufferDriver
      jetson_hub.fromBufferDriverReturn -> jetson_hubByteStreamAdapter.bufferOutReturn
     }

     connections hub {
      jetson_hub.toBufferDriver -> jetson_hubByteStreamAdapter.bufferIn
      jetson_hubByteStreamAdapter.bufferInReturn -> jetson_hub.toBufferDriverReturn

      jetson_hubByteStreamAdapter.toByteStreamDriver -> jetson_hubComDriver.$send
      jetson_hubByteStreamAdapter.fromByteStreamDriverReturn -> jetson_hubComDriver.recvReturnIn

      jetson_hub.allocate -> jetson_bufferManager.bufferGetCallee
      jetson_hub.deallocate -> jetson_bufferManager.bufferSendIn

      jetson_hubComDriver.allocate -> jetson_bufferManager.bufferGetCallee
      jetson_hubComDriver.deallocate -> jetson_bufferManager.bufferSendIn
      jetson_hubComDriver.ready -> jetson_hubByteStreamAdapter.byteStreamDriverReady
     }

  }

}
