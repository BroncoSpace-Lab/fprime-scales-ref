add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/JetsonFileHandlingConfig/")

register_fprime_module(
    EXCLUDE_FROM_ALL
    AUTOCODER_INPUTS
        "${CMAKE_CURRENT_LIST_DIR}/JetsonFileHandling.fpp"
    HEADERS
        "${CMAKE_CURRENT_LIST_DIR}/SubtopologyTopologyDefs.hpp"
        "${CMAKE_CURRENT_LIST_DIR}/PingEntries.hpp"
    INTERFACE
    DEPENDS
        JetsonDeployment_Subtopologies_JetsonFileHandling_JetsonFileHandlingConfig
)
