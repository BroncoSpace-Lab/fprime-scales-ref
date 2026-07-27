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
    import ComFprime.Subtopology
    import DataProducts.Subtopology
    import FileHandling.Subtopology

    # ----------------------------------------------------------------------
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance imx_jetsonManager
    instance imx_inaManager
    instance imx_thermalManager
    instance imx_mcpManager
    instance imx_perifBoardManager
    instance imx_fpManager
    instance imx_watchdogManager
    instance imx_dataProducer

    instance imx_systemResources
    instance imx_realFatalHandler

    instance imx_hub
    instance imx_hubComDriver
    instance imx_hubComAdapter
    instance imx_hubBufferManager
    instance imx_hubFramer
    instance imx_hubFrameAccumulator
    instance imx_hubDeframer
    instance imx_hubComStub
    instance imx_hubIoBufferManager
    instance imx_cmdSplitter
    instance imx_seqCmdSplitter
    instance imx_gdsCmdAuthMux

    instance imx_uartGdsEventSplitter
    instance imx_uartGdsTlmSplitter
    instance imx_uartGdsComQueue
    instance imx_uartGdsFramer
    instance imx_uartGdsComStub
    instance imx_uartGdsDriver
    instance imx_uartGdsBufferManager
    instance imx_uartGdsFrameAccumulator
    instance imx_uartGdsDeframer
    instance imx_uartGdsRouter

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

    command connections instance CdhCore.cmdDisp
    event connections instance CdhCore.events
    telemetry connections instance CdhCore.tlmSend
    text event connections instance CdhCore.textLogger
    health connections instance CdhCore.$health
    param connections instance FileHandling.prmDb
    time connections instance imx_chronoTime

    # ----------------------------------------------------------------------
    # Telemetry packets
    # ----------------------------------------------------------------------

    # include "ImxDeploymentPackets.fppi"

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections ComFprime_CdhCore {

      # Core events and telemetry to TCP/UART GDS splitters
      CdhCore.events.PktSend -> imx_uartGdsEventSplitter.comIn
      CdhCore.tlmSend.PktSend -> imx_uartGdsTlmSplitter.comIn

      # Splitter output 0 -> Route events and telemetry to normal TCP/IP GDS Path
      imx_uartGdsEventSplitter.comOut[0] -> ComFprime.comQueue.comPacketQueueIn[ComFprime.Ports_ComPacketQueue.EVENTS]
      imx_uartGdsTlmSplitter.comOut[0] -> ComFprime.comQueue.comPacketQueueIn[ComFprime.Ports_ComPacketQueue.TELEMETRY]

      # Splitter output 1 feeds the UART/serial GDS path
      imx_uartGdsEventSplitter.comOut[1] -> imx_uartGdsComQueue.comPacketQueueIn[ComFprime.Ports_ComPacketQueue.EVENTS]
      imx_uartGdsTlmSplitter.comOut[1] -> imx_uartGdsComQueue.comPacketQueueIn[ComFprime.Ports_ComPacketQueue.TELEMETRY]

      # Router to command authority mux.
      # Local commands are dispatched on the i.MX.
      # Jetson commands are forwarded over the hub.
      ComFprime.fprimeRouter.commandOut -> imx_gdsCmdAuthMux.tcpCmdIn
      imx_gdsCmdAuthMux.tcpCmdResponseOut -> ComFprime.fprimeRouter.cmdResponseIn

    }

    connections ComFprime_FileHandling {

      # Local i.MX file downlinks go directly to the GDS-facing file queue.
      FileHandling.fileDownlink.bufferSendOut -> ComFprime.comQueue.bufferQueueIn[ComFprime.Ports_ComBufferQueue.FILE]
      ComFprime.comQueue.bufferReturnOut[ComFprime.Ports_ComBufferQueue.FILE] -> FileHandling.fileDownlink.bufferReturn

      # File uplinks are forwarded to the Jetson over hub buffer channel 1.

    }

    connections Communications {

      # ComDriver buffer allocations
      imx_comDriver.allocate -> ComFprime.commsBufferManager.bufferGetCallee
      imx_comDriver.deallocate -> ComFprime.commsBufferManager.bufferSendIn

      # ComDriver <-> ComStub (Uplink)
      imx_comDriver.$recv -> ComFprime.comStub.drvReceiveIn
      ComFprime.comStub.drvReceiveReturnOut -> imx_comDriver.recvReturnIn

      # ComStub <-> ComDriver (Downlink)
      ComFprime.comStub.drvSendOut -> imx_comDriver.$send
      imx_comDriver.ready -> ComFprime.comStub.drvConnected

    }

    connections UartGdsDownlink {

      # UART ComQueue to F Prime framer
      imx_uartGdsComQueue.dataOut -> imx_uartGdsFramer.dataIn
      imx_uartGdsFramer.dataReturnOut -> imx_uartGdsComQueue.dataReturnIn

      # UART framer to ComStub
      imx_uartGdsFramer.dataOut -> imx_uartGdsComStub.dataIn
      imx_uartGdsComStub.dataReturnOut -> imx_uartGdsFramer.dataReturnIn
      imx_uartGdsComStub.comStatusOut -> imx_uartGdsComQueue.comStatusIn

      # ComStub to Linux UART driver
      imx_uartGdsComStub.drvSendOut -> imx_uartGdsDriver.$send

      # Linux UART driver to ComStub for UART GDS command uplink
      imx_uartGdsDriver.$recv -> imx_uartGdsComStub.drvReceiveIn
      imx_uartGdsComStub.drvReceiveReturnOut -> imx_uartGdsDriver.recvReturnIn

      # UART driver ready signal starts/restarts the queue
      imx_uartGdsDriver.ready -> imx_uartGdsComStub.drvConnected

    }

    connections UartGdsBuffers {

      # UART driver buffer allocations
      imx_uartGdsDriver.allocate -> imx_uartGdsBufferManager.bufferGetCallee
      imx_uartGdsDriver.deallocate -> imx_uartGdsBufferManager.bufferSendIn

      # UART framer output buffers
      imx_uartGdsFramer.bufferAllocate -> imx_uartGdsBufferManager.bufferGetCallee
      imx_uartGdsFramer.bufferDeallocate -> imx_uartGdsBufferManager.bufferSendIn

      # UART command-uplink frame accumulator buffers
      imx_uartGdsFrameAccumulator.bufferAllocate -> imx_uartGdsBufferManager.bufferGetCallee
      imx_uartGdsFrameAccumulator.bufferDeallocate -> imx_uartGdsBufferManager.bufferSendIn

      # UART command router buffers
      imx_uartGdsRouter.bufferAllocate -> imx_uartGdsBufferManager.bufferGetCallee
      imx_uartGdsRouter.bufferDeallocate -> imx_uartGdsBufferManager.bufferSendIn

    }

    connections UartGdsUplink {

      # UART ComStub to frame accumulator
      imx_uartGdsComStub.dataOut -> imx_uartGdsFrameAccumulator.dataIn
      imx_uartGdsFrameAccumulator.dataReturnOut -> imx_uartGdsComStub.dataReturnIn

      # Frame accumulator to F Prime deframer
      imx_uartGdsFrameAccumulator.dataOut -> imx_uartGdsDeframer.dataIn
      imx_uartGdsDeframer.dataReturnOut -> imx_uartGdsFrameAccumulator.dataReturnIn

      # Deframer to router
      imx_uartGdsDeframer.dataOut -> imx_uartGdsRouter.dataIn
      imx_uartGdsRouter.dataReturnOut -> imx_uartGdsDeframer.dataReturnIn

      # Router command path through authority mux
      imx_uartGdsRouter.commandOut -> imx_gdsCmdAuthMux.uartCmdIn
      imx_gdsCmdAuthMux.uartCmdResponseOut -> imx_uartGdsRouter.cmdResponseIn

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
      imx_rateGroup1.RateGroupMemberOut[3] -> ComFprime.comQueue.run
      imx_rateGroup1.RateGroupMemberOut[4] -> imx_uartGdsComQueue.run

      # Rate group 2
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup2] -> imx_rateGroup2.CycleIn
      imx_rateGroup2.RateGroupMemberOut[0] -> imx_cmdSeq.schedIn
      imx_rateGroup2.RateGroupMemberOut[1] -> imx_watchdogManager.run
      imx_rateGroup2.RateGroupMemberOut[2] -> imx_perifBoardManager.run
      imx_rateGroup2.RateGroupMemberOut[3] -> imx_thermalManager.run
      imx_rateGroup2.RateGroupMemberOut[4] -> imx_inaManager.run
      imx_rateGroup2.RateGroupMemberOut[5] -> imx_mcpManager.run
      imx_rateGroup2.RateGroupMemberOut[6] -> imx_jetsonManager.schedIn
      imx_rateGroup2.RateGroupMemberOut[7] -> imx_gdsCmdAuthMux.run
      imx_rateGroup2.RateGroupMemberOut[8] -> imx_dataProducer.run
      imx_rateGroup2.RateGroupMemberOut[9] -> imx_fpManager.run

      # Rate group 3
      imx_rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup3] -> imx_rateGroup3.CycleIn
      imx_rateGroup3.RateGroupMemberOut[0] -> CdhCore.$health.Run
      imx_rateGroup3.RateGroupMemberOut[1] -> ComFprime.commsBufferManager.schedIn
      imx_rateGroup3.RateGroupMemberOut[2] -> DataProducts.dpBufferManager.schedIn
      imx_rateGroup3.RateGroupMemberOut[3] -> DataProducts.dpWriter.schedIn
      imx_rateGroup3.RateGroupMemberOut[4] -> DataProducts.dpMgr.schedIn
      imx_rateGroup3.RateGroupMemberOut[5] -> imx_hubBufferManager.schedIn
      imx_rateGroup3.RateGroupMemberOut[6] -> imx_hubIoBufferManager.schedIn
      imx_rateGroup3.RateGroupMemberOut[7] -> imx_uartGdsBufferManager.schedIn
      imx_rateGroup3.RateGroupMemberOut[8] -> imx_uartGdsDriver.run

    }

    connections CdhCore_cmdSeq {

      # Command Sequencer through the same local/remote split path
      imx_cmdSeq.comCmdOut -> imx_seqCmdSplitter.CmdBuff[0]
      imx_seqCmdSplitter.forwardSeqCmdStatus[0] -> imx_cmdSeq.cmdResponseIn

    }

    connections DataProducers {
        imx_dataProducer.productGetOut  -> DataProducts.Subtopology.productGetIn
        imx_dataProducer.productSendOut -> DataProducts.Subtopology.productSendIn
    }

    connections ImxDeployment {

      # Jetson packetized events/tlm forwarded over hub serial channels.
      # Route into GDS Splitter so both GDS Paths can recieve them
      imx_hub.serialOut[2] -> imx_uartGdsEventSplitter.comIn
      imx_hub.serialOut[3] -> imx_uartGdsTlmSplitter.comIn

      # powerModeSend: Jetson JetsonPowerModeManager -> hub -> JetsonManager
      imx_hub.serialOut[0] -> imx_jetsonManager.currentPwrMode

      # powerModeReceive: JetsonManager -> hub -> Jetson JetsonPowerModeManager
      imx_jetsonManager.reqPwrMode -> imx_hub.serialIn[0]

      # jetsonPowerStateSend: Jetson JetsonPowerModeManager -> hub -> PowerManager
      imx_hub.serialOut[1] -> imx_jetsonManager.currentJetsonPwrState

      # jetsonPowerStateReceive: PowerManager -> hub -> Jetson JetsonPowerModeManager
      imx_jetsonManager.reqJetsonPwrState -> imx_hub.serialIn[1]

      # McpManager send thermal readings to DataProducer
      imx_mcpManager.mcpThermalReadOut -> imx_dataProducer.McpThermalReadingIn

      # ImxThermalManager send thermal readings to DataProducer
      imx_thermalManager.cpuThermalReadOut -> imx_dataProducer.cpuThermalReadIn

      # InaManager send power readings to DataProducer
      imx_inaManager.inaPowerReadOut -> imx_dataProducer.inaPowerReadIn
      # Jetson thermal readings: hub -> FPManager
      imx_hub.serialOut[4] -> imx_fpManager.jetsonThermalReadingIn

      # JetsonManager retains command ownership; FPManager authorizes first.
      imx_jetsonManager.fpJetsonPowerAuthorize -> imx_fpManager.jetsonPowerAuthorizeIn
      imx_jetsonManager.fpJetsonPowerStateOut -> imx_fpManager.jetsonPowerStateIn

      # Internal FP recovery and emergency power-off actions.
      imx_fpManager.jetsonPowerRequestOut -> imx_jetsonManager.fpJetsonPowerRequestIn
      imx_fpManager.peripheralPowerOff -> imx_perifBoardManager.emergencyPowerOff

      # Route fatal through FPManager before the standard process-level handler.
      # CdhCore.fpp always wires events.FatalAnnounce -> fatalHandler.FatalReceive
      # internally and both of those ports allow only a single connection, so
      # CdhCoreFatalHandlerConfig.fpp swaps FatalRelay in as the fatalHandler
      # instance; it re-announces the FATAL on a fresh port that is free to be
      # routed through FPManager before reaching the real terminating handler.
      CdhCore.fatalHandler.fatalOut -> imx_fpManager.fatalIn
      imx_fpManager.fatalOut -> imx_realFatalHandler.FatalReceive

      # I2C bus connections for MCP9808 and INA
      imx_mcpManager.mcpWriteRead -> imx_mcpI2CbusDriver.writeRead
      imx_inaManager.busWriteRead -> imx_inaI2CbusDriver.writeRead

      # i.MX GPIO connection to the GpioDriver for Peripheral Board control
      imx_perifBoardManager.gpioSet -> imx_perifGpioDriver.gpioWrite

      # Local thermal readings into FPManager.
      imx_thermalManager.imxThermalReadingOut -> imx_fpManager.imxThermalReadingIn
      imx_mcpManager.thermalReadingOut -> imx_fpManager.mcpThermalReadingIn

      # i.MX GPIO connection to the GpioDriver for Jetson power control
      imx_jetsonManager.gpioSet -> imx_jetsonGpioDriver.gpioWrite
      imx_watchdogManager.gpioWatchDog -> imx_gpioWatchDogDriver.gpioWrite

    }

    connections send_hub {

      # Frame each complete GenericHub record before passing it to TCP.
      imx_hub.toBufferDriver -> imx_hubComAdapter.bufferIn
      imx_hubComAdapter.bufferInReturn -> imx_hub.toBufferDriverReturn

      imx_hubComAdapter.comOut -> imx_hubFramer.dataIn
      imx_hubFramer.dataReturnOut -> imx_hubComAdapter.comReturnIn

      imx_hubFramer.dataOut -> imx_hubComStub.dataIn
      imx_hubComStub.dataReturnOut -> imx_hubFramer.dataReturnIn
      imx_hubComStub.comStatusOut -> imx_hubFramer.comStatusIn

      imx_hubComStub.drvSendOut -> imx_hubComDriver.$send

    }

    connections recv_hub {

      # Accumulate TCP stream reads into complete frames, then deframe to hub records.
      imx_hubComDriver.$recv -> imx_hubComStub.drvReceiveIn
      imx_hubComStub.drvReceiveReturnOut -> imx_hubComDriver.recvReturnIn

      imx_hubComStub.dataOut -> imx_hubFrameAccumulator.dataIn
      imx_hubFrameAccumulator.dataReturnOut -> imx_hubComStub.dataReturnIn

      imx_hubFrameAccumulator.dataOut -> imx_hubDeframer.dataIn
      imx_hubDeframer.dataReturnOut -> imx_hubFrameAccumulator.dataReturnIn

      imx_hubDeframer.dataOut -> imx_hubComAdapter.comIn
      imx_hubComAdapter.comInReturn -> imx_hubDeframer.dataReturnIn

      imx_hubComAdapter.bufferOut -> imx_hub.fromBufferDriver
      imx_hub.fromBufferDriverReturn -> imx_hubComAdapter.bufferOutReturn

    }

    connections hub {

      # GenericHub retained records use the large packet pool.
      imx_hub.allocate -> imx_hubBufferManager.bufferGetCallee
      imx_hub.deallocate -> imx_hubBufferManager.bufferSendIn

      # TCP driver receive buffers use the IO pool.
      imx_hubComDriver.allocate -> imx_hubIoBufferManager.bufferGetCallee
      imx_hubComDriver.deallocate -> imx_hubIoBufferManager.bufferSendIn

      # Framer output buffers go directly to TCP, so they use the IO pool.
      imx_hubFramer.bufferAllocate -> imx_hubIoBufferManager.bufferGetCallee
      imx_hubFramer.bufferDeallocate -> imx_hubIoBufferManager.bufferSendIn

      # FrameAccumulator output buffers become retained hub records.
      imx_hubFrameAccumulator.bufferAllocate -> imx_hubBufferManager.bufferGetCallee
      imx_hubFrameAccumulator.bufferDeallocate -> imx_hubBufferManager.bufferSendIn

      imx_hubComDriver.ready -> imx_hubComStub.drvConnected

      # Channel 0 stages Jetson file-downlink packets through the local
      # FileUplink service first, saving the file on the i.MX filesystem.
      # The saved file can then be downlinked locally from the i.MX to GDS.
      imx_hub.bufferOut[0] -> FileHandling.fileUplink.bufferSendIn
      FileHandling.fileUplink.bufferSendOut -> imx_hub.bufferOutReturn[0]

      # Channel 1 forwards i.MX/GDS file-uplink packets to the Jetson.
      ComFprime.fprimeRouter.fileOut -> imx_hub.bufferIn[1]
      imx_hub.bufferInReturn[1] -> ComFprime.fprimeRouter.fileBufferReturnIn

      # Local command dispatch after splitting
      imx_gdsCmdAuthMux.cmdOut -> imx_cmdSplitter.CmdBuff[0]
      imx_cmdSplitter.forwardSeqCmdStatus[0] -> imx_gdsCmdAuthMux.cmdResponseIn

      imx_cmdSplitter.LocalCmd[0] -> CdhCore.cmdDisp.seqCmdBuff[0]
      CdhCore.cmdDisp.seqCmdStatus[0] -> imx_cmdSplitter.seqCmdStatus[0]

      imx_seqCmdSplitter.LocalCmd[0] -> CdhCore.cmdDisp.seqCmdBuff[1]
      CdhCore.cmdDisp.seqCmdStatus[1] -> imx_seqCmdSplitter.seqCmdStatus[0]

      # Commands going from this deployment to the remote deployment.
      # FPManager gates both remote paths (GDS-direct on index 0, and
      # CmdSequencer-originated on index 1) so commands are not transmitted
      # when the Jetson power state is OFF and the hub transport is
      # unavailable. A sequence targeting the Jetson while it is powered off
      # would otherwise reach imx_hubComStub directly and trip its
      # never-connected assert instead of being rejected gracefully.
      imx_cmdSplitter.RemoteCmd[0] -> imx_fpManager.remoteJetsonCmdIn[0]
      imx_fpManager.remoteJetsonCmdResponseOut[0] -> imx_cmdSplitter.seqCmdStatus[0]
      imx_fpManager.remoteJetsonCmdOut[0] -> imx_hub.cmdDispIn[0]
      imx_hub.cmdRespOut[0] -> imx_fpManager.remoteJetsonCmdResponseIn[0]

      imx_seqCmdSplitter.RemoteCmd[0] -> imx_fpManager.remoteJetsonCmdIn[1]
      imx_fpManager.remoteJetsonCmdResponseOut[1] -> imx_seqCmdSplitter.seqCmdStatus[0]
      imx_fpManager.remoteJetsonCmdOut[1] -> imx_hub.cmdDispIn[1]
      imx_hub.cmdRespOut[1] -> imx_fpManager.remoteJetsonCmdResponseIn[1]

    }

  }

}
