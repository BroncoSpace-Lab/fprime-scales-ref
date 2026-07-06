module JetsonFileHandling {

    # ----------------------------------------------------------------------
    # Active Components
    # ----------------------------------------------------------------------
    instance fileUplink: Svc.FileUplink base id JetsonFileHandlingConfig.BASE_ID + 0x00000 \
        queue size JetsonFileHandlingConfig.QueueSizes.fileUplink \
        stack size JetsonFileHandlingConfig.StackSizes.fileUplink \
        priority JetsonFileHandlingConfig.Priorities.fileUplink 

    instance fileDownlink: Svc.FileDownlink base id JetsonFileHandlingConfig.BASE_ID + 0x01000 \
        queue size JetsonFileHandlingConfig.QueueSizes.fileDownlink \
        stack size JetsonFileHandlingConfig.StackSizes.fileDownlink \
        priority JetsonFileHandlingConfig.Priorities.fileDownlink \
    {
        phase Fpp.ToCpp.Phases.configComponents """
        JetsonFileHandling::fileDownlink.configure(
            JetsonFileHandlingConfig::DownlinkConfig::cooldown,
            JetsonFileHandlingConfig::DownlinkConfig::cycleTime,
            JetsonFileHandlingConfig::DownlinkConfig::fileQueueDepth
        );
        """
    }

    instance fileManager: Svc.FileManager base id JetsonFileHandlingConfig.BASE_ID + 0x02000 \
        queue size JetsonFileHandlingConfig.QueueSizes.fileManager \
        stack size JetsonFileHandlingConfig.StackSizes.fileManager \
        priority JetsonFileHandlingConfig.Priorities.fileManager

    instance prmDb: Svc.PrmDb base id JetsonFileHandlingConfig.BASE_ID + 0x03000 \
        queue size JetsonFileHandlingConfig.QueueSizes.prmDb \
        stack size JetsonFileHandlingConfig.StackSizes.prmDb \
        priority JetsonFileHandlingConfig.Priorities.prmDb \
    {
        phase Fpp.ToCpp.Phases.configComponents """
            JetsonFileHandling::prmDb.configure("PrmDb.dat");
        """
        phase Fpp.ToCpp.Phases.readParameters """
            JetsonFileHandling::prmDb.readParamFile();
        """
    }

    topology Subtopology {
        #Active Components
        instance fileUplink
        instance fileDownlink
        instance fileManager
        instance prmDb

        # ----------------------------------------------------------------------
        # Topology ports
        # ----------------------------------------------------------------------

        @ Output port for sending file buffers to a downlink component
        port fileDownlinkBufferSendOut = fileDownlink.bufferSendOut

        @ Input port for returning ownership of buffers sent on fileDownlinkBufferSendOut
        port fileDownlinkBufferReturn  = fileDownlink.bufferReturn

        @ Mutex-locked input port for requesting a file downlink
        port fileDownlinkSendFile      = fileDownlink.SendFile

        @ Output port for notifying that a file downlink has completed
        port fileDownlinkFileComplete  = fileDownlink.FileComplete

        @ Input port for scheduling fileDownlink
        port fileDownlinkRun           = fileDownlink.Run

        @ Input port for receiving uplinked file packets
        port fileUplinkBufferSendIn  = fileUplink.bufferSendIn

        @ Output port for returning ownership of received uplink buffers
        port fileUplinkBufferSendOut = fileUplink.bufferSendOut

        @ Input port for scheduling fileManager operations
        port fileManagerSchedIn = fileManager.schedIn

    } # end topology
} # end JetsonFileHandling Subtopology
