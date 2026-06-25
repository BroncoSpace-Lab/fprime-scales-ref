module ImxDeployment {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

  enum Ports_RateGroups {
    rateGroup1
    rateGroup2
    rateGroup3
  }

  enum Ports_ComPacketQueue{
        EVENTS,
        TELEMETRY
    }

  enum Ports_ComBufferQueue{
        FILE_DOWNLINK
    }

  topology ImxDeployment {

    # ----------------------------------------------------------------------
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance imx_health
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
    instance imx_timer

    instance imx_hub
    instance imx_hubComDriver
    instance imx_hubBufferManager
    instance imx_hubByteStreamAdapter
    # instance imx_hubComStub
    # instance imx_hubComQueue
    # instance imx_hubDeframer
    # instance imx_hubFramer
    instance imx_cmdSplitter
    instance imx_hubFileUplink

    instance imx_fprimeRouter
    instance imx_frameAccumulator
    instance hub_frameAccumulator

    
    instance imx_proxySequencer
    instance imx_proxyGroundInterface
    
    # Drivers and managers for SCALES-specific hardware components
    
    # SCALES SVC Drivers
    instance imx_mcpI2CbusDriver
    instance imx_inaI2CbusDriver
    instance imx_perifGpioDriver
    instance imx_jetsonGpioDriver
    instance gpioWatchDogDriver
    

    # SCALES SVC Managers
    instance imx_inaManager
    instance imx_thermalManager
    instance imx_mcpManager
    instance imx_perifBoardManager
    instance imx_jetsonManager
    instance imx_watchdogManager

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

      # Inputs to ComQueue (events, telemetry, file)
      imx_eventLogger.PktSend -> imx_comQueue.comPacketQueueIn[Ports_ComPacketQueue.EVENTS]
      imx_tlmSend.PktSend -> imx_comQueue.comPacketQueueIn[Ports_ComPacketQueue.TELEMETRY]
      imx_fileDownlink.bufferSendOut -> imx_comQueue.bufferQueueIn[Ports_ComBufferQueue.FILE_DOWNLINK]
      imx_comQueue.bufferReturnOut[Ports_ComBufferQueue.FILE_DOWNLINK] -> imx_fileDownlink.bufferReturn

      # ComQueue <-> Framer 
      imx_comQueue.dataOut -> imx_framer.dataIn
      imx_framer.dataReturnOut -> imx_comQueue.dataReturnIn
      # imx_comQueue.buffQueueSend -> imx_framer.bufferIn

      # Buffer Management for Framer
      imx_framer.bufferAllocate -> imx_bufferManager.bufferGetCallee
      imx_framer.bufferDeallocate -> imx_bufferManager.bufferSendIn

      # Framer <-> ComStub
      imx_framer.dataOut -> imx_comStub.dataIn
      imx_comStub.dataReturnOut -> imx_framer.dataReturnIn

      # ComStub <-> ComDriver
      imx_comStub.drvSendOut -> imx_comDriver.$send
      #imx_comDriver.sendReturnOut -> imx_comStub.drvSendReturnIn
      # imx_comDriver.$recv -> imx_comStub.drvAsyncSendReturnIn
      imx_comDriver.ready -> imx_comStub.drvConnected
      
      # ComStatus
      imx_comStub.comStatusOut -> imx_framer.comStatusIn
      imx_framer.comStatusOut -> imx_comQueue.comStatusIn

      # imx_comDriver.deallocate -> imx_bufferManager.bufferSendIn
      # imx_comDriver.ready -> imx_comStub.drvConnected

      # imx_comStub.comStatus -> imx_framer.comStatusIn
      # imx_framer.comStatusOut -> imx_comQueue.comStatusIn
      # imx_comStub.drvDataOut -> imx_comDriver.$send

    }

    connections FaultProtection {
      imx_eventLogger.FatalAnnounce -> imx_fatalHandler.FatalReceive
    }

    connections RateGroups {
      # Block driver deprecated after 4.0.0, changes to linux timer example in hello world
      imx_timer.CycleOut -> imx_rateGroupDriver.CycleIn

      # Rate group 1
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> imx_rateGroup1.CycleIn
      imx_rateGroup1.RateGroupMemberOut[0] -> imx_tlmSend.Run
      imx_rateGroup1.RateGroupMemberOut[1] -> imx_fileDownlink.Run
      imx_rateGroup1.RateGroupMemberOut[2] -> imx_systemResources.run
      imx_rateGroup1.RateGroupMemberOut[3] -> imx_comQueue.run

      # Rate group 2
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup2] -> imx_rateGroup2.CycleIn
      imx_rateGroup2.RateGroupMemberOut[1] -> imx_cmdSeq.schedIn
      imx_rateGroup2.RateGroupMemberOut[2] -> imx_watchdogManager.run
      imx_rateGroup2.RateGroupMemberOut[3] -> imx_perifBoardManager.run
      imx_rateGroup2.RateGroupMemberOut[4] -> imx_thermalManager.imxCpuTemp
      imx_rateGroup2.RateGroupMemberOut[5] -> imx_inaManager.run
      imx_rateGroup2.RateGroupMemberOut[6] -> imx_mcpManager.run
      imx_rateGroup2.RateGroupMemberOut[7] -> imx_jetsonManager.schedIn
      

      # Rate group 3
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup3] -> imx_rateGroup3.CycleIn
      imx_rateGroup3.RateGroupMemberOut[0] -> imx_health.Run
      imx_rateGroup3.RateGroupMemberOut[1] -> imx_bufferManager.schedIn
      imx_rateGroup3.RateGroupMemberOut[2] -> imx_hubBufferManager.schedIn
    }

    connections Sequencer {
      # imx_cmdSeq.comCmdOut -> imx_cmdDisp.seqCmdBuff
      imx_cmdSeq.comCmdOut -> imx_cmdSplitter.CmdBuff[1]
      imx_cmdSplitter.forwardSeqCmdStatus[1] -> imx_cmdSeq.cmdResponseIn
      # imx_cmdDisp.seqCmdStatus -> imx_cmdSeq.cmdResponseIn
    }

 connections Uplink {

      # ComDriver buffer allocations
      imx_comDriver.allocate      -> imx_bufferManager.bufferGetCallee
      imx_comDriver.deallocate    -> imx_bufferManager.bufferSendIn

      # ComDriver <-> ComStub
      imx_comDriver.$recv             -> imx_comStub.drvReceiveIn
      imx_comStub.drvReceiveReturnOut -> imx_comDriver.recvReturnIn

      # ComStub <-> FrameAccumulator
      imx_comStub.dataOut -> imx_frameAccumulator.dataIn
      imx_frameAccumulator.dataReturnOut -> imx_comStub.dataReturnIn

      # FrameAccumulator buffer allocations
      imx_frameAccumulator.bufferDeallocate -> imx_bufferManager.bufferSendIn
      imx_frameAccumulator.bufferAllocate   -> imx_bufferManager.bufferGetCallee

      # FrameAccumulator <-> Deframer
      imx_frameAccumulator.dataOut -> imx_deframer.dataIn
      imx_deframer.dataReturnOut   -> imx_frameAccumulator.dataReturnIn
    
      # Deframer <-> Router
      imx_deframer.dataOut           -> imx_fprimeRouter.dataIn
      imx_fprimeRouter.dataReturnOut -> imx_deframer.dataReturnIn

      # Router buffer allocations
      imx_fprimeRouter.bufferAllocate   -> imx_bufferManager.bufferGetCallee
      imx_fprimeRouter.bufferDeallocate -> imx_bufferManager.bufferSendIn

      # Router <-> CmdDispatcher/FileUplink
      imx_fprimeRouter.commandOut  -> imx_cmdDisp.seqCmdBuff
      imx_cmdDisp.seqCmdStatus     -> imx_fprimeRouter.cmdResponseIn
      imx_fprimeRouter.fileOut     -> imx_fileUplink.bufferSendIn
      imx_fileUplink.bufferSendOut -> imx_fprimeRouter.fileBufferReturnIn

      # # imx_comDriver.$recv -> imx_comStub.drvDataIn
      # # imx_comStub.comDataOut -> imx_deframer.framedIn

      # imx_deframer.framedDeallocate -> imx_bufferManager.bufferSendIn
      # # imx_deframer.comOut -> imx_cmdDisp.seqCmdBuff
      # imx_deframer.comOut -> imx_cmdSplitter.CmdBuff[0]
      # imx_cmdSplitter.LocalCmd[0] -> imx_proxyGroundInterface.seqCmdBuf
      # imx_cmdSplitter.LocalCmd[1] -> imx_proxySequencer.seqCmdBuf

      # imx_proxyGroundInterface.comCmdOut -> imx_cmdDisp.seqCmdBuff
      # imx_proxySequencer.comCmdOut -> imx_cmdDisp.seqCmdBuff

      # # imx_cmdDisp.seqCmdStatus -> imx_deframer.cmdResponseIn
      # imx_cmdDisp.seqCmdStatus -> imx_proxyGroundInterface.cmdResponseIn
      # imx_cmdDisp.seqCmdStatus -> imx_proxySequencer.cmdResponseIn

      # imx_proxyGroundInterface.seqCmdStatus -> imx_cmdSplitter.seqCmdStatus[0]
      # imx_proxySequencer.seqCmdStatus -> imx_cmdSplitter.seqCmdStatus[1]

      # imx_cmdSplitter.forwardSeqCmdStatus[0] -> imx_deframer.cmdResponseIn

      # imx_deframer.bufferAllocate -> imx_bufferManager.bufferGetCallee
      # imx_deframer.bufferOut -> imx_fileUplink.bufferSendIn
      # imx_deframer.bufferDeallocate -> imx_bufferManager.bufferSendIn
      # imx_fileUplink.bufferSendOut -> imx_bufferManager.bufferSendIn
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

      imx_watchdogManager.gpioWatchDog -> gpioWatchDogDriver.gpioWrite
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

      # # Commands going from this deployment to the remote deployment
      # imx_cmdSplitter.RemoteCmd[0] -> imx_hub.cmdDispIn[0]
      # imx_hub.cmdRespOut[0] -> imx_cmdSplitter.seqCmdStatus[0]

      # imx_cmdSplitter.RemoteCmd[1] -> imx_hub.cmdDispIn[1]
      # imx_hub.cmdRespOut[1] -> imx_cmdSplitter.seqCmdStatus[1]
      
    }

  }

}
