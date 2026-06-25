#####
# JetsonDeployment Topology
#####

set(SOURCE_FILES
    "${CMAKE_CURRENT_LIST_DIR}/topology.fpp"
    "${CMAKE_CURRENT_LIST_DIR}/instances.fpp"
    "${CMAKE_CURRENT_LIST_DIR}/JetsonDeploymentTopology.cpp"
)

set(MOD_DEPS
    Fw/Logger
    Drv/Udp
    Drv/TcpServer
    Components_MLComponent
    scales_scalesSvc_JetsonPowerModeManager
)

register_fprime_module()