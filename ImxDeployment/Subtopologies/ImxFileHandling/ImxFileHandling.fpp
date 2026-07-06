module ImxFileHandling {

    # ----------------------------------------------------------------------
    # Active Components
    # ----------------------------------------------------------------------
    instance fileUplink: Svc.FileUplink base id ImxFileHandlingConfig.BASE_ID + 0x00000 \
        queue size ImxFileHandlingConfig.QueueSizes.fileUplink \
        stack size ImxFileHandlingConfig.StackSizes.fileUplink \
        priority ImxFileHandlingConfig.Priorities.fileUplink 

    instance fileDownlink: Svc.FileDownlink base id ImxFileHandlingConfig.BASE_ID + 0x01000 \
        queue size ImxFileHandlingConfig.QueueSizes.fileDownlink \
        stack size ImxFileHandlingConfig.StackSizes.fileDownlink \
        priority ImxFileHandlingConfig.Priorities.fileDownlink \
    {
        phase Fpp.ToCpp.Phases.configComponents """
        ImxFileHandling::fileDownlink.configure(
            ImxFileHandlingConfig::DownlinkConfig::cooldown,
            ImxFileHandlingConfig::DownlinkConfig::cycleTime,
            ImxFileHandlingConfig::DownlinkConfig::fileQueueDepth
        );
        """
    }

    instance fileManager: Svc.FileManager base id ImxFileHandlingConfig.BASE_ID + 0x02000 \
        queue size ImxFileHandlingConfig.QueueSizes.fileManager \
        stack size ImxFileHandlingConfig.StackSizes.fileManager \
        priority ImxFileHandlingConfig.Priorities.fileManager

    instance prmDb: Svc.PrmDb base id ImxFileHandlingConfig.BASE_ID + 0x03000 \
        queue size ImxFileHandlingConfig.QueueSizes.prmDb \
        stack size ImxFileHandlingConfig.StackSizes.prmDb \
        priority ImxFileHandlingConfig.Priorities.prmDb \
    {
        phase Fpp.ToCpp.Phases.configComponents """
            ImxFileHandling::prmDb.configure("PrmDb.dat");
        """
        phase Fpp.ToCpp.Phases.readParameters """
            ImxFileHandling::prmDb.readParamFile();
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
} # end ImxFileHandling Subtopology
