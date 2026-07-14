module ComFprimeConfig {
    # IMX ComFprime subtopology range: 0x02000000 - 0x02FFFFFF
    # This is the direct GDS-facing path. It intentionally uses F Prime
    # framing, not CCSDS TM framing.
    constant BASE_ID = 0x02000000

    module QueueSizes {
        constant comQueue = 50
    }

    module StackSizes {
        constant comQueue = 64 * 1024
    }

    module Priorities {
        constant comQueue = 29
    }

    module QueueDepths {
        constant events = 100
        constant tlm = 500
        constant file = 100
    }

    module QueuePriorities {
        constant events = 0
        constant tlm = 2
        constant file = 1
    }

    module BuffMgr {
        constant frameAccumulatorSize = 2048
        constant commsBuffSize = 2048
        constant commsFileBuffSize = 3000
        constant commsBuffCount = 20
        constant commsFileBuffCount = 30
        constant commsBuffMgrId = 200
    }
}
