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
    import JetsonCdhCore.Subtopology
    import JetsonComCcsds.Subtopology
    import JetsonDataProducts.Subtopology
    import JetsonFileHandling.Subtopology
    
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
    instance jetson_hubByteStreamAdapter
    instance jetson_hubBufferManager

    instance jetson_rateGroup1
    instance jetson_rateGroup2
    instance jetson_rateGroup3
    instance jetson_rateGroupDriver
    instance jetson_cmdSeq
    instance jetson_chronoTime
    instance jetson_timer
    instance jetson_comDriver
    instance jetson_gpioWatchdogDriver

  # ----------------------------------------------------------------------
  # Pattern graph specifiers
  # ----------------------------------------------------------------------

    command connections instance JetsonCdhCore.cmdDisp
    event connections instance JetsonCdhCore.events
    telemetry connections instance JetsonCdhCore.tlmSend
    text event connections instance JetsonCdhCore.textLogger
    health connections instance JetsonCdhCore.$health
    param connections instance JetsonFileHandling.prmDb
    time connections instance jetson_chronoTime

  # ----------------------------------------------------------------------
  # Telemetry packets (only used when TlmPacketizer is used)
  # ----------------------------------------------------------------------

    # include "JetsonDeploymentPackets.fppi"

  # ----------------------------------------------------------------------
  # Direct graph specifiers
  # ----------------------------------------------------------------------

    connections JetsonComCcsds_JetsonCdhCore {
      # Core events and telemetry are forwarded over hub to i.MX.
      # i.MX injects these packets into its local JetsonComCcsds queue for host GDS downlink.
      JetsonCdhCore.events.PktSend -> jetson_hub.serialIn[2]
      JetsonCdhCore.tlmSend.PktSend -> jetson_hub.serialIn[3]

      # Router to Command Dispatcher
      JetsonComCcsds.fprimeRouter.commandOut -> JetsonCdhCore.cmdDisp.seqCmdBuff
      JetsonCdhCore.cmdDisp.seqCmdStatus -> JetsonComCcsds.fprimeRouter.cmdResponseIn
      
    }

    connections JetsonComCcsds_JetsonFileHandling {
      # File Downlink to Communication Queue
      # JetsonFileHandling.fileDownlink.bufferSendOut -> JetsonComCcsds.comQueue.bufferQueueIn[JetsonComCcsds.Ports_ComBufferQueue.FILE]
      # JetsonComCcsds.comQueue.bufferReturnOut[JetsonComCcsds.Ports_ComBufferQueue.FILE] -> JetsonFileHandling.fileDownlink.bufferReturn

      # File downlink to the hub
      JetsonFileHandling.fileDownlink.bufferSendOut -> jetson_hub.bufferIn[0]
      jetson_hub.bufferInReturn[0] -> JetsonFileHandling.fileDownlink.bufferReturn

      # Router to File Uplink
      JetsonComCcsds.fprimeRouter.fileOut -> JetsonFileHandling.fileUplink.bufferSendIn
      JetsonFileHandling.fileUplink.bufferSendOut -> JetsonComCcsds.fprimeRouter.fileBufferReturnIn
    }

    connections Communications {
      # ComDriver buffer allocations
      jetson_comDriver.allocate      -> JetsonComCcsds.commsBufferManager.bufferGetCallee
      jetson_comDriver.deallocate    -> JetsonComCcsds.commsBufferManager.bufferSendIn
      
      # ComDriver <-> ComStub (Uplink)
      jetson_comDriver.$recv                     -> JetsonComCcsds.comStub.drvReceiveIn
      JetsonComCcsds.comStub.drvReceiveReturnOut -> jetson_comDriver.recvReturnIn
      
      # ComStub <-> ComDriver (Downlink)
      JetsonComCcsds.comStub.drvSendOut      -> jetson_comDriver.$send
      jetson_comDriver.ready         -> JetsonComCcsds.comStub.drvConnected
    }

    connections JetsonFileHandling_JetsonDataProducts {
      # Data Products to File Downlink
      JetsonDataProducts.dpCat.fileOut -> JetsonFileHandling.fileDownlink.SendFile
      JetsonFileHandling.fileDownlink.FileComplete -> JetsonDataProducts.dpCat.fileDone
    }

    connections RateGroups {
      # timer to drive rate group
      jetson_timer.CycleOut -> jetson_rateGroupDriver.CycleIn

      # Rate group 1
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> jetson_rateGroup1.CycleIn
      jetson_rateGroup1.RateGroupMemberOut[0] -> JetsonCdhCore.tlmSend.Run
      jetson_rateGroup1.RateGroupMemberOut[1] -> JetsonFileHandling.fileDownlink.Run
      jetson_rateGroup1.RateGroupMemberOut[2] -> jetson_systemResources.run
      jetson_rateGroup1.RateGroupMemberOut[3] -> JetsonComCcsds.comQueue.run
      jetson_rateGroup1.RateGroupMemberOut[4] -> JetsonComCcsds.aggregator.timeout

      # Rate group 2
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup2] -> jetson_rateGroup2.CycleIn
      jetson_rateGroup2.RateGroupMemberOut[0] -> jetson_cmdSeq.schedIn
      jetson_rateGroup2.RateGroupMemberOut[1] -> jetson_pwrModeManager.schedIn
      jetson_rateGroup2.RateGroupMemberOut[2] -> jetson_thermalManager.run
      jetson_rateGroup2.RateGroupMemberOut[3] -> jetson_watchdogManager.run

      # Rate group 3
      jetson_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup3] -> jetson_rateGroup3.CycleIn
      jetson_rateGroup3.RateGroupMemberOut[0] -> JetsonCdhCore.$health.Run
      jetson_rateGroup3.RateGroupMemberOut[1] -> JetsonComCcsds.commsBufferManager.schedIn
      jetson_rateGroup3.RateGroupMemberOut[2] -> JetsonDataProducts.dpBufferManager.schedIn
      jetson_rateGroup3.RateGroupMemberOut[3] -> JetsonDataProducts.dpWriter.schedIn
      jetson_rateGroup3.RateGroupMemberOut[4] -> JetsonDataProducts.dpMgr.schedIn
      jetson_rateGroup3.RateGroupMemberOut[5] -> jetson_hubBufferManager.schedIn
    }

    connections JetsonCdhCore_cmdSeq {
      # Command Sequencer
      jetson_cmdSeq.comCmdOut -> JetsonCdhCore.cmdDisp.seqCmdBuff
      JetsonCdhCore.cmdDisp.seqCmdStatus -> jetson_cmdSeq.cmdResponseIn
    }

    connections JetsonDeployment {

      # Add here connections to user-defined components

      jetson_lucidCamera.sendFile -> JetsonFileHandling.fileDownlink.SendFile

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
      jetson_hub.toBufferDriver -> jetson_hubByteStreamAdapter.bufferIn
      jetson_hubByteStreamAdapter.bufferInReturn -> jetson_hub.toBufferDriverReturn

      jetson_hubByteStreamAdapter.toByteStreamDriver -> jetson_hubComDriver.$send
    }


    connections recv_hub {
      jetson_hubComDriver.$recv -> jetson_hubByteStreamAdapter.fromByteStreamDriver
      jetson_hubByteStreamAdapter.fromByteStreamDriverReturn -> jetson_hubComDriver.recvReturnIn

      jetson_hubByteStreamAdapter.bufferOut -> jetson_hub.fromBufferDriver
      jetson_hub.fromBufferDriverReturn -> jetson_hubByteStreamAdapter.bufferOutReturn
    }

    connections hub {
      jetson_hub.allocate -> jetson_hubBufferManager.bufferGetCallee
      jetson_hub.deallocate -> jetson_hubBufferManager.bufferSendIn

      jetson_hubComDriver.allocate -> jetson_hubBufferManager.bufferGetCallee
      jetson_hubComDriver.deallocate -> jetson_hubBufferManager.bufferSendIn

      jetson_hubComDriver.ready -> jetson_hubByteStreamAdapter.byteStreamDriverReady

      # Commands arriving from the i.MX hub are dispatched locally on the Jetson.
      # Responses return over the same hub command channel.
      jetson_hub.cmdDispOut[0] -> JetsonCdhCore.cmdDisp.seqCmdBuff
      JetsonCdhCore.cmdDisp.seqCmdStatus -> jetson_hub.cmdRespIn[0]
    }
  }

}
