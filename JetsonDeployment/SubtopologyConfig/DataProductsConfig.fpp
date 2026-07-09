module DataProductsConfig {
    # Jetson DataProducts subtopology range: 0x14000000 - 0x14FFFFFF
    constant BASE_ID = 0x14000000

    module QueueSizes {
        constant dpCat = 10
        constant dpMgr = 10
        constant dpWriter = 10
        constant dpBufferManager = 10
    }

    module StackSizes {
        constant dpCat = 64 * 1024
        constant dpMgr = 64 * 1024
        constant dpWriter = 64 * 1024
        constant dpBufferManager = 64 * 1024
    }

    module Priorities {
        constant dpCat = 24
        constant dpMgr = 23
        constant dpWriter = 22
        constant dpBufferManager = 21
    }

    module BuffMgr {
        constant dpBufferStoreSize = 10000
        constant dpBufferStoreCount = 10
        constant dpBufferManagerId = 300
    }

    module Paths {
        constant dpDir = "./DpCat"
        constant dpState = "./DpCat/DpState.dat"
    }
}
