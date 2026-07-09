module CdhCoreConfig {
    # Jetson CdhCore subtopology range: 0x11000000 - 0x11FFFFFF
    constant BASE_ID = 0x11000000

    module QueueSizes {
        constant cmdDisp = 10
        constant events = 10
        constant tlmSend = 10
        constant $health = 25
    }

    module StackSizes {
        constant cmdDisp = 64 * 1024
        constant events = 64 * 1024
        constant tlmSend = 64 * 1024
    }

    module Priorities {
        constant cmdDisp = 35
        constant $health = 24
        constant events = 23
        constant tlmSend = 22
    }
}
