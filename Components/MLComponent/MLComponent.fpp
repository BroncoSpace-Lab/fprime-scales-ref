module Components {
    @ Component for F Prime FSW framework.
    active component MLComponent {

        # One async command/port is required for active components
        # This should be overridden by the developers with a useful command/port
        
        async command SET_ML_PATH(
            path: string size 254
        )

        event MLSet(
            status: string size 254
        ) severity activity high format "ML Path Set: {}"

        async command SET_INFERENCE_PATH(
            path: string size 254
        )

        event InferenceSet(
            status: string size 254
        ) severity activity high format "Inference Path Set: {}"
        
        async command MULTI_INFERENCE(
            
        )

        event InferenceOutput(
            path: string size 128
            classification: string size 256
        ) severity activity high format "{} is an image of a {}"

        async command CLEAR_INFERENCE_PATH(

        )

        ##############################################################################
        #### Uncomment the following examples to start customizing your component ####
        ##############################################################################

        # @ Example async command
        # async command COMMAND_NAME(param_name: U32)

        # @ Example telemetry counter
        # telemetry ExampleCounter: U64

        # @ Example event
        # event ExampleStateEvent(example_state: Fw.On) severity activity high id 0 format "State set to {}"

        # @ Example port: receiving calls from the rate group
        # sync input port run: Svc.Sched

        # @ Example parameter
        # param PARAMETER_NAME: U32

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

        # @ Port to return the value of a parameter
        # param get port prmGetOut

        # @Port to set the value of a parameter
        # param set port prmSetOut

    }
}