module ComCcsdsConfig {
    # IMX ComCcsds subtopology range: 0x02000000 - 0x02FFFFFF
    constant BASE_ID = 0x02000000

    module QueueSizes {
        constant comQueue = 128
        constant aggregator = 256
    }

    module StackSizes {
        constant comQueue = 64 * 1024
        constant aggregator = 64 * 1024
    }

    module Priorities {
        constant aggregator = 30
        constant comQueue = 29
    }

    module QueueDepths {
        constant events = 200
        constant tlm = 500
        # 20 MiB file downlinks produce roughly 42k file packets with the
        # current 512-byte F Prime file packet size. Leave margin for packet
        # overhead and other queued traffic.
        constant file = 50000
    }

    module QueuePriorities {
        constant events = 0
        constant tlm = 2
        constant file = 1
    }

    module BuffMgr {
        constant frameAccumulatorSize = 2048
        # The i.MX GDS-facing CCSDS path creates one Space Packet buffer per
        # FileDownlink packet before aggregating it into TM frames. Keep this
        # pool sized for a full 20 MiB file burst plus margin.
        constant commsBuffSize = 1024
        constant commsFileBuffSize = 2048
        constant commsBuffCount = 50000
        constant commsFileBuffCount = 2048
        constant commsBuffMgrId = 200
    }
}
