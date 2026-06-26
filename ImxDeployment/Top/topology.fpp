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
  # Subtopology imports
  # ----------------------------------------------------------------------
    import CdhCore.Subtopology
    import ComCcsds.Subtopology
    import DataProducts.Subtopology
    import FileHandling.Subtopology
    
  # ----------------------------------------------------------------------
  # Instances used in the topology
  # ----------------------------------------------------------------------
    instance imx_chronoTime
    instance imx_rateGroup1
    instance imx_rateGroup2
    instance imx_rateGroup3
    instance imx_rateGroupDriver
    instance imx_systemResources
    instance imx_timer
    instance imx_comDriver
    instance imx_cmdSeq

    # Drivers and managers for SCALES-specific hardware components
    
    # SCALES SVC Drivers
    instance imx_mcpI2CbusDriver
    instance imx_inaI2CbusDriver
    instance imx_perifGpioDriver
    instance imx_jetsonGpioDriver
    instance imx_gpioWatchDogDriver
    

    # SCALES SVC Managers
    instance imx_inaManager
    instance imx_thermalManager
    instance imx_mcpManager
    instance imx_perifBoardManager
    instance imx_jetsonManager
    instance imx_watchdogManager

    # IMX HUB PATTERN SPECIFIC INSTANCES
    instance imx_hub
    instance imx_hubComDriver
    instance imx_hubBufferManager
    instance imx_hubByteStreamAdapter
    instance imx_cmdSplitter

  # ----------------------------------------------------------------------
  # Pattern graph specifiers
  # ----------------------------------------------------------------------

    command connections instance CdhCore.cmdDisp
    event connections instance CdhCore.events
    telemetry connections instance CdhCore.tlmSend
    text event connections instance CdhCore.textLogger
    health connections instance CdhCore.$health
    param connections instance FileHandling.prmDb
    time connections instance imx_chronoTime

  # ----------------------------------------------------------------------
  # Telemetry packets (only used when TlmPacketizer is used)
  # ----------------------------------------------------------------------

    # include "ImxDeploymentPackets.fppi"

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
      imx_comDriver.allocate      -> ComCcsds.commsBufferManager.bufferGetCallee
      imx_comDriver.deallocate    -> ComCcsds.commsBufferManager.bufferSendIn
      
      # ComDriver <-> ComStub (Uplink)
      imx_comDriver.$recv                     -> ComCcsds.comStub.drvReceiveIn
      ComCcsds.comStub.drvReceiveReturnOut -> imx_comDriver.recvReturnIn
      
      # ComStub <-> ComDriver (Downlink)
      ComCcsds.comStub.drvSendOut      -> imx_comDriver.$send
      imx_comDriver.ready         -> ComCcsds.comStub.drvConnected
    }

    connections FileHandling_DataProducts {
      # Data Products to File Downlink
      DataProducts.dpCat.fileOut -> FileHandling.fileDownlink.SendFile
      FileHandling.fileDownlink.FileComplete -> DataProducts.dpCat.fileDone
    }

    connections RateGroups {
      # timer to drive rate group
      imx_timer.CycleOut -> imx_rateGroupDriver.CycleIn

      # Rate group 1
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> imx_rateGroup1.CycleIn
      imx_rateGroup1.RateGroupMemberOut[0] -> CdhCore.tlmSend.Run
      imx_rateGroup1.RateGroupMemberOut[1] -> FileHandling.fileDownlink.Run
      imx_rateGroup1.RateGroupMemberOut[2] -> imx_systemResources.run
      imx_rateGroup1.RateGroupMemberOut[3] -> ComCcsds.comQueue.run
      imx_rateGroup1.RateGroupMemberOut[4] -> ComCcsds.aggregator.timeout

      # Rate group 2
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup2] -> imx_rateGroup2.CycleIn
      imx_rateGroup2.RateGroupMemberOut[0] -> imx_cmdSeq.schedIn
      imx_rateGroup2.RateGroupMemberOut[1] -> imx_watchdogManager.run
      imx_rateGroup2.RateGroupMemberOut[2] -> imx_perifBoardManager.run
      imx_rateGroup2.RateGroupMemberOut[3] -> imx_thermalManager.imxCpuTemp
      imx_rateGroup2.RateGroupMemberOut[4] -> imx_inaManager.run
      imx_rateGroup2.RateGroupMemberOut[5] -> imx_mcpManager.run
      imx_rateGroup2.RateGroupMemberOut[6] -> imx_jetsonManager.schedIn
  
      # Rate group 3
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup3] -> imx_rateGroup3.CycleIn
      imx_rateGroup3.RateGroupMemberOut[0] -> CdhCore.$health.Run
      imx_rateGroup3.RateGroupMemberOut[1] -> ComCcsds.commsBufferManager.schedIn
      imx_rateGroup3.RateGroupMemberOut[2] -> DataProducts.dpBufferManager.schedIn
      imx_rateGroup3.RateGroupMemberOut[3] -> DataProducts.dpWriter.schedIn
      imx_rateGroup3.RateGroupMemberOut[4] -> DataProducts.dpMgr.schedIn
      imx_rateGroup3.RateGroupMemberOut[5] -> imx_hubBufferManager.schedIn
    }

    connections CdhCore_cmdSeq {
      # Command Sequencer
      imx_cmdSeq.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff
      CdhCore.cmdDisp.seqCmdStatus -> imx_cmdSeq.cmdResponseIn
    }

    connections ImxDeployment {
      # Add here connections to user-defined components

      # powerModeSend: Jetson JetsonPowerModeManager → hub → JetsonManager
      imx_hub.serialOut[0] -> imx_jetsonManager.currentPwrMode

      # powerModeRecieve: JetsonManager → hub → Jetson JetsonPowerModeManager
      imx_jetsonManager.reqPwrMode -> imx_hub.serialIn[0]

      # jetsonPowerStateSend: Jetson JetsonPowerModeManager → hub → PowerManager
      imx_hub.serialOut[1] -> imx_jetsonManager.currentJetsonPwrState

      # jetsonPowerStateReceive: PowerManager → hub → Jetson JetsonPowerModeManager
      imx_jetsonManager.reqJetsonPwrState -> imx_hub.serialIn[1]

      # I2C bus connections for MCP9808 and INA
      imx_mcpManager.mcpWriteRead -> imx_mcpI2CbusDriver.writeRead

      imx_inaManager.busWriteRead -> imx_inaI2CbusDriver.writeRead
      

      # imx GPIO connection to the GpioDriver for Peripheral Board control
      imx_perifBoardManager.gpioSet -> imx_perifGpioDriver.gpioWrite

      # imx GPIO connection to the GpioDriver for Jetson power control
      imx_jetsonManager.gpioSet -> imx_jetsonGpioDriver.gpioWrite

      imx_watchdogManager.gpioWatchDog -> imx_gpioWatchDogDriver.gpioWrite
      

    }

    connections send_hub {
      # Hub -> ByteStream adapter
      imx_hub.toBufferDriver -> imx_hubByteStreamAdapter.bufferIn
      imx_hubByteStreamAdapter.bufferInReturn -> imx_hub.toBufferDriverReturn

      # ByteStream adapter -> TCP driver
      imx_hubByteStreamAdapter.toByteStreamDriver -> imx_hubComDriver.$send
    }

    connections recv_hub {
      # TCP driver -> ByteStream adapter
      imx_hubComDriver.$recv -> imx_hubByteStreamAdapter.fromByteStreamDriver
      imx_hubByteStreamAdapter.fromByteStreamDriverReturn -> imx_hubComDriver.recvReturnIn

      # ByteStream adapter -> Hub
      imx_hubByteStreamAdapter.bufferOut -> imx_hub.fromBufferDriver
      imx_hub.fromBufferDriverReturn -> imx_hubByteStreamAdapter.bufferOutReturn
    }

    connections hub {
      # Hub buffer allocation/deallocation
      imx_hub.allocate -> imx_hubBufferManager.bufferGetCallee
      imx_hub.deallocate -> imx_hubBufferManager.bufferSendIn

      # TCP driver buffer allocation/deallocation
      imx_hubComDriver.allocate -> imx_hubBufferManager.bufferGetCallee
      imx_hubComDriver.deallocate -> imx_hubBufferManager.bufferSendIn

      # TCP driver ready signal
      imx_hubComDriver.ready -> imx_hubByteStreamAdapter.byteStreamDriverReady

      # Commands going from this deployment to the remote deployment
      imx_cmdSplitter.RemoteCmd[0] -> imx_hub.cmdDispIn[0]
      imx_hub.cmdRespOut[0] -> imx_cmdSplitter.seqCmdStatus[0]

      imx_cmdSplitter.RemoteCmd[1] -> imx_hub.cmdDispIn[1]
      imx_hub.cmdRespOut[1] -> imx_cmdSplitter.seqCmdStatus[1]
      
    }

  }

}
