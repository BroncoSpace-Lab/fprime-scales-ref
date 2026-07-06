module JetsonDataProducts{

    # ----------------------------------------------------------------------
    # Active Components
    # ----------------------------------------------------------------------
    
    instance dpCat: Svc.DpCatalog base id JetsonDataProductsConfig.BASE_ID + 0x00000 \
        queue size JetsonDataProductsConfig.QueueSizes.dpCat \
        stack size JetsonDataProductsConfig.StackSizes.dpCat \
        priority JetsonDataProductsConfig.Priorities.dpCat \
    {
        phase Fpp.ToCpp.Phases.configComponents """
            Fw::FileNameString dpDir(JetsonDataProductsConfig::Paths::dpDir);
            Fw::FileNameString dpState(JetsonDataProductsConfig::Paths::dpState);
            Os::FileSystem::createDirectory(dpDir.toChar());
            JetsonDataProducts::dpCat.configure(&dpDir,1,dpState,0, JetsonDataProducts::Allocation::memAllocator);
        """
    }

    instance dpMgr: Svc.DpManager base id JetsonDataProductsConfig.BASE_ID + 0x01000 \
        queue size JetsonDataProductsConfig.QueueSizes.dpMgr \
        stack size JetsonDataProductsConfig.StackSizes.dpMgr \
        priority JetsonDataProductsConfig.Priorities.dpMgr

    instance dpWriter: Svc.DpWriter base id JetsonDataProductsConfig.BASE_ID + 0x02000 \
        queue size JetsonDataProductsConfig.QueueSizes.dpWriter \
        stack size JetsonDataProductsConfig.StackSizes.dpWriter \
        priority JetsonDataProductsConfig.Priorities.dpWriter \
    {
        phase Fpp.ToCpp.Phases.configComponents """
            JetsonDataProducts::dpWriter.configure(dpDir);
        """
    }
    
    # ----------------------------------------------------------------------
    # Passive Components
    # ----------------------------------------------------------------------
    
    instance dpBufferManager: Svc.BufferManager base id JetsonDataProductsConfig.BASE_ID + 0x03000 \ 
    {
        phase Fpp.ToCpp.Phases.configObjects """
        Svc::BufferManager::BufferBins bins;
        """
        phase Fpp.ToCpp.Phases.configComponents """
        memset(&ConfigObjects::JetsonDataProducts_dpBufferManager::bins, 0, sizeof(ConfigObjects::JetsonDataProducts_dpBufferManager::bins));
        ConfigObjects::JetsonDataProducts_dpBufferManager::bins.bins[0].bufferSize = JetsonDataProductsConfig::BuffMgr::dpBufferStoreSize;
        ConfigObjects::JetsonDataProducts_dpBufferManager::bins.bins[0].numBuffers = JetsonDataProductsConfig::BuffMgr::dpBufferStoreCount;
        JetsonDataProducts::dpBufferManager.setup(
            JetsonDataProductsConfig::BuffMgr::dpBufferManagerId,
            0,
            JetsonDataProducts::Allocation::memAllocator,
            ConfigObjects::JetsonDataProducts_dpBufferManager::bins
        );
        """
        phase Fpp.ToCpp.Phases.tearDownComponents """
        JetsonDataProducts::dpCat.shutdown();
        JetsonDataProducts::dpBufferManager.cleanup();
        """
    }
    topology Subtopology {
        #Active Components
        instance dpCat
        instance dpMgr
        instance dpWriter

        #Passive Components
        instance dpBufferManager

        connections JetsonDataProducts {
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
} # end JetsonDataProducts Subtopology
