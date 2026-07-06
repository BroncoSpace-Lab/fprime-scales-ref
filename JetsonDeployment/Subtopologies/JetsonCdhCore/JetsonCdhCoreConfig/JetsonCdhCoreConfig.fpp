module JetsonCdhCoreConfig {
    # Base ID for the JetsonCdhCore subtopology, all components are offsets from this base ID
    constant BASE_ID = 0x11000000

    module QueueSizes {
        constant cmdDisp     = 10
        # Jetson tends to emit a burst of startup and command-related events,
        # so give the EventManager more headroom before packets start dropping.
        constant events      = 50
        constant tlmSend     = 10
        constant $health     = 25
    }

    module StackSizes {
        constant cmdDisp     = 64 * 1024
        constant events      = 64 * 1024
        constant tlmSend     = 64 * 1024
    }

    module Priorities {
        constant cmdDisp     = 35
        constant $health     = 24
        constant events      = 23
        constant tlmSend     = 22
    }
}
