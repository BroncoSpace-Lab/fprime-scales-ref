module ImxDataProducts{

    # ----------------------------------------------------------------------
    # Active Components
    # ----------------------------------------------------------------------
    
    instance dpCat: Svc.DpCatalog base id ImxDataProductsConfig.BASE_ID + 0x00000 \
        queue size ImxDataProductsConfig.QueueSizes.dpCat \
        stack size ImxDataProductsConfig.StackSizes.dpCat \
        priority ImxDataProductsConfig.Priorities.dpCat \
    {
        phase Fpp.ToCpp.Phases.configComponents """
            Fw::FileNameString dpDir(ImxDataProductsConfig::Paths::dpDir);
            Fw::FileNameString dpState(ImxDataProductsConfig::Paths::dpState);
            Os::FileSystem::createDirectory(dpDir.toChar());
            ImxDataProducts::dpCat.configure(&dpDir,1,dpState,0, ImxDataProducts::Allocation::memAllocator);
        """
    }

    instance dpMgr: Svc.DpManager base id ImxDataProductsConfig.BASE_ID + 0x01000 \
        queue size ImxDataProductsConfig.QueueSizes.dpMgr \
        stack size ImxDataProductsConfig.StackSizes.dpMgr \
        priority ImxDataProductsConfig.Priorities.dpMgr

    instance dpWriter: Svc.DpWriter base id ImxDataProductsConfig.BASE_ID + 0x02000 \
        queue size ImxDataProductsConfig.QueueSizes.dpWriter \
        stack size ImxDataProductsConfig.StackSizes.dpWriter \
        priority ImxDataProductsConfig.Priorities.dpWriter \
    {
        phase Fpp.ToCpp.Phases.configComponents """
            ImxDataProducts::dpWriter.configure(dpDir);
        """
    }
    
    # ----------------------------------------------------------------------
    # Passive Components
    # ----------------------------------------------------------------------
    
    instance dpBufferManager: Svc.BufferManager base id ImxDataProductsConfig.BASE_ID + 0x03000 \ 
    {
        phase Fpp.ToCpp.Phases.configObjects """
        Svc::BufferManager::BufferBins bins;
        """
        phase Fpp.ToCpp.Phases.configComponents """
        memset(&ConfigObjects::ImxDataProducts_dpBufferManager::bins, 0, sizeof(ConfigObjects::ImxDataProducts_dpBufferManager::bins));
        ConfigObjects::ImxDataProducts_dpBufferManager::bins.bins[0].bufferSize = ImxDataProductsConfig::BuffMgr::dpBufferStoreSize;
        ConfigObjects::ImxDataProducts_dpBufferManager::bins.bins[0].numBuffers = ImxDataProductsConfig::BuffMgr::dpBufferStoreCount;
        ImxDataProducts::dpBufferManager.setup(
            ImxDataProductsConfig::BuffMgr::dpBufferManagerId,
            0,
            ImxDataProducts::Allocation::memAllocator,
            ConfigObjects::ImxDataProducts_dpBufferManager::bins
        );
        """
        phase Fpp.ToCpp.Phases.tearDownComponents """
        ImxDataProducts::dpCat.shutdown();
        ImxDataProducts::dpBufferManager.cleanup();
        """
    }
    topology Subtopology {
        #Active Components
        instance dpCat
        instance dpMgr
        instance dpWriter

        #Passive Components
        instance dpBufferManager

        connections ImxDataProducts {
            # DpMgr and DpWriter connections. Have explicit port indexes for demo
            dpMgr.bufferGetOut[0] -> dpBufferManager.bufferGetCallee
            dpMgr.productSendOut[0] -> dpWriter.bufferSendIn
            dpWriter.deallocBufferSendOut -> dpBufferManager.bufferSendIn

            dpWriter.dpWrittenOut -> dpCat.addToCat
        }

        # ----------------------------------------------------------------------
        # Topology ports
        # ----------------------------------------------------------------------

        @ Input port array for responding to data product get requests from client components
        port productGetIn       = dpMgr.productGetIn

        @ Input port array for receiving data product buffer requests from client components
        port productRequestIn   = dpMgr.productRequestIn

        @ Input port array for receiving filled data product buffers from client components
        port productSendIn      = dpMgr.productSendIn

        @ Output port array for sending requested data product buffers to client components
        port productResponseOut = dpMgr.productResponseOut

        @ Output port for sending file downlink requests to a file downlink component
        port dpCatFileOut  = dpCat.fileOut

        @ Input port for receiving file downlink completion notifications
        port dpCatFileDone = dpCat.fileDone

        @ Input port for scheduling dpBufferManager telemetry output
        port dpBufferManagerSchedIn = dpBufferManager.schedIn

        @ Input port for scheduling dpWriter telemetry output
        port dpWriterSchedIn        = dpWriter.schedIn

        @ Input port for scheduling dpMgr telemetry output
        port dpMgrSchedIn           = dpMgr.schedIn

    } # end topology
} # end ImxDataProducts Subtopology
