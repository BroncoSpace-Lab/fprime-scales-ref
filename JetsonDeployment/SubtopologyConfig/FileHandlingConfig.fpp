module FileHandlingConfig {
    # Jetson FileHandling subtopology range: 0x15000000 - 0x15FFFFFF
    constant BASE_ID = 0x15000000

    module QueueSizes {
        # Jetson primarily produces large file downlinks into the hub. Keep
        # enough queue headroom for bursty scheduling and future reverse-path
        # tests without mirroring the full i.MX sink sizing.
        constant fileUplink = 8192
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
        constant fileQueueDepth = 64
    }
}
