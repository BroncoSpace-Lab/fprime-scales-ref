module Components {
    @ Acts as a proxy sequencer or ground interface for use in remote hubs
    active component CmdSequenceForwarder {

        # One async command/port is required for active components
        # This should be overridden by the developers with a useful command/port
        @ TODO
        async command TODO opcode 0

        ##############################################################################
        #### General Ports ####
        ##############################################################################

        @ Port for receiving seqCmdBuf from hub (Remote)
        async input port seqCmdBuf: Fw.Com

        @ Port for forwarding comCmdOut (Local)
        output port comCmdOut: Fw.Com

        @ Port for receiving cmdResponseIn (Local)
        async input port cmdResponseIn: Fw.CmdResponse

        @ Port for forwarding seqCmdStatus to hub (Remote)
        output port seqCmdStatus: Fw.CmdResponse

        ###############################################################################
        # Standard AC Ports: Required for Channels, Events, Commands, and Parameters  #
        ###############################################################################
        @ Port for requesting the current time
        time get port timeCaller

        @ Port for sending command registrations
        command reg port cmdRegOut

        @ Port for receiving commands
        command recv port cmdIn

        @ Port for sending command responses
        command resp port cmdResponseOut

        @ Port for sending textual representation of events
        text event port logTextOut

        @ Port for sending events to downlink
        event port logOut

        @ Port for sending telemetry channels to downlink
        telemetry port tlmOut

        @ Port to return the value of a parameter
        param get port prmGetOut

        @Port to set the value of a parameter
        param set port prmSetOut

    }
}