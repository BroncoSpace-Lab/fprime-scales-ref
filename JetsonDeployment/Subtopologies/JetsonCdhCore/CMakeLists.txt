add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/JetsonCdhCoreConfig/")

register_fprime_module(
    EXCLUDE_FROM_ALL
    AUTOCODER_INPUTS
        "${CMAKE_CURRENT_LIST_DIR}/JetsonCdhCore.fpp"
    HEADERS
        "${CMAKE_CURRENT_LIST_DIR}/SubtopologyTopologyDefs.hpp"
        "${CMAKE_CURRENT_LIST_DIR}/PingEntries.hpp"
    INTERFACE
    DEPENDS
        JetsonDeployment_Subtopologies_JetsonCdhCore_JetsonCdhCoreConfig
)
