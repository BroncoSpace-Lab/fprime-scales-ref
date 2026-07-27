module CdhCore {

    # Swapped in for the default Svc.FatalHandler so a FATAL announcement is
    # routed through FPManager (to shut down the Jetson, peripherals, and i.MX
    # board) before it reaches the real, process-terminating fatal handler.
    # See ImxDeployment/Top/topology.fpp for the downstream wiring:
    #   fatalHandler.fatalOut -> imx_fpManager.fatalIn -> imx_realFatalHandler.FatalReceive
    instance fatalHandler: scalesSvc.FatalRelay base id CdhCoreConfig.BASE_ID + 0x07000

}
