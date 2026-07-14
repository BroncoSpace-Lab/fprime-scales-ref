module FileHandlingConfig {
    # IMX FileHandling subtopology range: 0x05000000 - 0x05FFFFFF
    constant BASE_ID = 0x05000000

    module QueueSizes {
        # The i.MX receives Jetson files through the hub and writes them
        # locally before downlinking to GDS. Size the active queues for the
        # packet count of a 20 MiB transfer with margin.
        constant fileUplink = 50000
        constant fileDownlink = 8192
        constant fileManager = 10
        constant prmDb = 10
    }

    module StackSizes {
        constant fileUplink = 64 * 1024
        constant fileDownlink = 64 * 1024
        constant fileManager = 64 * 1024
        constant prmDb = 64 * 1024
    }

    module Priorities {
        constant fileUplink = 24
        constant fileDownlink = 23
        constant fileManager = 22
        constant prmDb = 21
    }

    module DownlinkConfig {
        constant cooldown = 1000
        constant cycleTime = 1000
        # Request queue depth; this is number of pending files, not packets.
        constant fileQueueDepth = 256
    }
}
