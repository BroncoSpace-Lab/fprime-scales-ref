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
    import ImxCdhCore.Subtopology
    import ImxComCcsds.Subtopology
    import ImxDataProducts.Subtopology
    import ImxFileHandling.Subtopology
    
  # ----------------------------------------------------------------------
  # Instances used in the topology
  # ----------------------------------------------------------------------
    instance imx_jetsonManager
    instance imx_inaManager
    instance imx_thermalManager
    instance imx_mcpManager
    instance imx_perifBoardManager
    instance imx_watchdogManager

    instance imx_systemResources

    instance imx_hub
    instance imx_hubComDriver
    instance imx_hubByteStreamAdapter
    instance imx_hubBufferManager
    instance imx_cmdSplitter
    instance imx_seqCmdSplitter

    instance imx_rateGroup1
    instance imx_rateGroup2
    instance imx_rateGroup3
    instance imx_rateGroupDriver
    instance imx_cmdSeq
    instance imx_chronoTime
    instance imx_timer
    instance imx_comDriver

    instance imx_mcpI2CbusDriver
    instance imx_inaI2CbusDriver
    instance imx_perifGpioDriver
    instance imx_jetsonGpioDriver
    instance imx_gpioWatchDogDriver

  # ----------------------------------------------------------------------
  # Pattern graph specifiers
  # ----------------------------------------------------------------------

    command connections instance ImxCdhCore.cmdDisp
    event connections instance ImxCdhCore.events
    telemetry connections instance ImxCdhCore.tlmSend
    text event connections instance ImxCdhCore.textLogger
    health connections instance ImxCdhCore.$health
    param connections instance ImxFileHandling.prmDb
    time connections instance imx_chronoTime

  # ----------------------------------------------------------------------
  # Telemetry packets (only used when TlmPacketizer is used)
  # ----------------------------------------------------------------------

    # include "ImxDeploymentPackets.fppi"

  # ----------------------------------------------------------------------
  # Direct graph specifiers
  # ----------------------------------------------------------------------

    connections ImxComCcsds_CdhCore {
      # Core events and telemetry to communication queue
      ImxCdhCore.events.PktSend -> ImxComCcsds.comQueue.comPacketQueueIn[ImxComCcsds.Ports_ComPacketQueue.EVENTS]
      ImxCdhCore.tlmSend.PktSend -> ImxComCcsds.comQueue.comPacketQueueIn[ImxComCcsds.Ports_ComPacketQueue.TELEMETRY]

      # Router to command splitter. Local commands are dispatched on the i.MX;
      # Jetson commands are forwarded over the hub.
      ImxComCcsds.fprimeRouter.commandOut -> imx_cmdSplitter.CmdBuff[0]
      imx_cmdSplitter.forwardSeqCmdStatus[0] -> ImxComCcsds.fprimeRouter.cmdResponseIn
      
    }

    connections ImxComCcsds_ImxFileHandling {
      # File Downlink to Communication Queue
      ImxFileHandling.fileDownlink.bufferSendOut -> ImxComCcsds.comQueue.bufferQueueIn[ImxComCcsds.Ports_ComBufferQueue.FILE]
      ImxComCcsds.comQueue.bufferReturnOut[ImxComCcsds.Ports_ComBufferQueue.FILE] -> ImxFileHandling.fileDownlink.bufferReturn

      # Router to File Uplink
      ImxComCcsds.fprimeRouter.fileOut -> ImxFileHandling.fileUplink.bufferSendIn
      ImxFileHandling.fileUplink.bufferSendOut -> ImxComCcsds.fprimeRouter.fileBufferReturnIn
    }

    connections Communications {
      # ComDriver buffer allocations
      imx_comDriver.allocate      -> ImxComCcsds.commsBufferManager.bufferGetCallee
      imx_comDriver.deallocate    -> ImxComCcsds.commsBufferManager.bufferSendIn
      
      # ComDriver <-> ComStub (Uplink)
      imx_comDriver.$recv                     -> ImxComCcsds.comStub.drvReceiveIn
      ImxComCcsds.comStub.drvReceiveReturnOut -> imx_comDriver.recvReturnIn
      
      # ComStub <-> ComDriver (Downlink)
      ImxComCcsds.comStub.drvSendOut      -> imx_comDriver.$send
      imx_comDriver.ready         -> ImxComCcsds.comStub.drvConnected
    }

    connections ImxFileHandling_ImxDataProducts {
      # Data Products to File Downlink
      ImxDataProducts.dpCat.fileOut -> ImxFileHandling.fileDownlink.SendFile
      ImxFileHandling.fileDownlink.FileComplete -> ImxDataProducts.dpCat.fileDone
    }

    connections RateGroups {
      # timer to drive rate group
      imx_timer.CycleOut -> imx_rateGroupDriver.CycleIn

      # Rate group 1
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1] -> imx_rateGroup1.CycleIn
      imx_rateGroup1.RateGroupMemberOut[0] -> ImxCdhCore.tlmSend.Run
      imx_rateGroup1.RateGroupMemberOut[1] -> ImxFileHandling.fileDownlink.Run
      imx_rateGroup1.RateGroupMemberOut[2] -> imx_systemResources.run
      imx_rateGroup1.RateGroupMemberOut[3] -> ImxComCcsds.comQueue.run
      imx_rateGroup1.RateGroupMemberOut[4] -> ImxComCcsds.aggregator.timeout

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
      imx_rateGroup3.RateGroupMemberOut[0] -> ImxCdhCore.$health.Run
      imx_rateGroup3.RateGroupMemberOut[1] -> ImxComCcsds.commsBufferManager.schedIn
      imx_rateGroup3.RateGroupMemberOut[2] -> ImxDataProducts.dpBufferManager.schedIn
      imx_rateGroup3.RateGroupMemberOut[3] -> ImxDataProducts.dpWriter.schedIn
      imx_rateGroup3.RateGroupMemberOut[4] -> ImxDataProducts.dpMgr.schedIn
      imx_rateGroup3.RateGroupMemberOut[5] -> imx_hubBufferManager.schedIn
    }

    connections CdhCore_cmdSeq {
      # Command Sequencer through the same local/remote split path
      imx_cmdSeq.comCmdOut -> imx_seqCmdSplitter.CmdBuff[0]
      imx_seqCmdSplitter.forwardSeqCmdStatus[0] -> imx_cmdSeq.cmdResponseIn
    }

    connections ImxDeployment {
      # Add here connections to user-defined components

      # Jetson packetized events/tlm forwarded over hub serial channels.
      # Route directly into IMX ImxComCcsds packet queues for host GDS downlink.
      imx_hub.serialOut[2] -> ImxComCcsds.comQueue.comPacketQueueIn[ImxComCcsds.Ports_ComPacketQueue.EVENTS]
      imx_hub.serialOut[3] -> ImxComCcsds.comQueue.comPacketQueueIn[ImxComCcsds.Ports_ComPacketQueue.TELEMETRY]

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

      # Local command dispatch after splitting
      imx_cmdSplitter.LocalCmd[0] -> ImxCdhCore.cmdDisp.seqCmdBuff[0]
      ImxCdhCore.cmdDisp.seqCmdStatus[0] -> imx_cmdSplitter.seqCmdStatus[0]

      imx_seqCmdSplitter.LocalCmd[0] -> ImxCdhCore.cmdDisp.seqCmdBuff[1]
      ImxCdhCore.cmdDisp.seqCmdStatus[1] -> imx_seqCmdSplitter.seqCmdStatus[0]

      # Commands going from this deployment to the remote deployment
      imx_cmdSplitter.RemoteCmd[0] -> imx_hub.cmdDispIn[0]
      imx_hub.cmdRespOut[0] -> imx_cmdSplitter.seqCmdStatus[0]

      imx_seqCmdSplitter.RemoteCmd[0] -> imx_hub.cmdDispIn[1]
      imx_hub.cmdRespOut[1] -> imx_seqCmdSplitter.seqCmdStatus[0]
      
    }

  }

}
