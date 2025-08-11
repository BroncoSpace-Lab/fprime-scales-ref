####
# F prime CMakeLists.txt:
#
# SOURCE_FILES: combined list of source and autocoding files
# MOD_DEPS: (optional) module dependencies
####

restrict_platforms(aarch64-linux)

set(SOURCE_FILES
  "${CMAKE_CURRENT_LIST_DIR}/instances.fpp"
  # Note: Uncomment when using Svc:TlmPacketizer
  #"${CMAKE_CURRENT_LIST_DIR}/JetsonDeploymentPackets.xml"
  "${CMAKE_CURRENT_LIST_DIR}/topology.fpp"
  "${CMAKE_CURRENT_LIST_DIR}/JetsonDeploymentTopology.cpp"
)
set(MOD_DEPS
  Fw/Logger
  # Communication Implementations
  Drv/Udp
  Drv/TcpServer
  pybind
)

register_fprime_module()
