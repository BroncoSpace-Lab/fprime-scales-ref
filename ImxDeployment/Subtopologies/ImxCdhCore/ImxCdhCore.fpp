module ImxCdhCore {
    # ----------------------------------------------------------------------
    # Active Components
    # ----------------------------------------------------------------------
    instance cmdDisp: Svc.CommandDispatcher base id ImxCdhCoreConfig.BASE_ID + 0x00000 \
        queue size ImxCdhCoreConfig.QueueSizes.cmdDisp \
        stack size ImxCdhCoreConfig.StackSizes.cmdDisp \
        priority ImxCdhCoreConfig.Priorities.cmdDisp

    instance events: Svc.EventManager base id ImxCdhCoreConfig.BASE_ID + 0x001000 \
        queue size ImxCdhCoreConfig.QueueSizes.events \
        stack size ImxCdhCoreConfig.StackSizes.events \
        priority ImxCdhCoreConfig.Priorities.events

    # ----------------------------------------------------------------------
    # Queued Components
    # ----------------------------------------------------------------------
    instance $health: Svc.Health base id ImxCdhCoreConfig.BASE_ID + 0x002000 \
        queue size ImxCdhCoreConfig.QueueSizes.$health \
    {
        phase Fpp.ToCpp.Phases.configConstants """
        enum {
            HEALTH_WATCHDOG_CODE = 0x123
        };
        """
        phase Fpp.ToCpp.Phases.configComponents """
        // Health is supplied a set of ping entires.
        ImxCdhCore::health.setPingEntries(
            ConfigObjects::ImxCdhCore_health::pingEntries,
            FW_NUM_ARRAY_ELEMENTS(ConfigObjects::ImxCdhCore_health::pingEntries),
            ConfigConstants::ImxCdhCore_health::HEALTH_WATCHDOG_CODE
        );
        """
    }

    # ----------------------------------------------------------------------
    # Passive Components
    # ----------------------------------------------------------------------
    instance version: Svc.Version base id ImxCdhCoreConfig.BASE_ID + 0x003000 \
    {
        phase Fpp.ToCpp.Phases.configComponents """
        // Startup TLM and Config verbosity for Versions
        ImxCdhCore::version.config(true);
        """
    }

    instance textLogger: Svc.PassiveTextLogger base id ImxCdhCoreConfig.BASE_ID + 0x004000

    instance fatalAdapter: Svc.AssertFatalAdapter base id ImxCdhCoreConfig.BASE_ID + 0x005000

    topology Subtopology {
        #Active Components
        instance cmdDisp
        instance events
        instance tlmSend

        #Queued Components
        instance $health

        #Passive Components
        instance version
        instance textLogger
        instance fatalAdapter
        instance fatalHandler

        connections FaultProtection {
            events.FatalAnnounce -> fatalHandler.FatalReceive
        }

        # ----------------------------------------------------------------------
        # Topology ports
        # ----------------------------------------------------------------------

        @ Input port for receiving command buffers from sequencers or other command buffer sources
        port seqCmdBuff   = cmdDisp.seqCmdBuff

        @ Output port returning command execution status to the command source
        port seqCmdStatus = cmdDisp.seqCmdStatus

        @ Output port for sending event packets from the EventManager
        port eventsPktSend  = events.PktSend

        @ Output port sending packetized telemetry to the comm stack for downlink
        port tlmSendPktSend = tlmSend.PktSend

        @ Input port to trigger a telemetry packet send cycle
        port tlmSendRun = tlmSend.Run

        @ Input port for scheduling the command dispatcher
        port cmdDispRun = cmdDisp.run

        @ Input port for scheduling the Health component
        port healthRun  = $health.Run

    } # end topology
} # end ImxCdhCore Subtopology
