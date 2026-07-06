
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/JetsonComCcsdsConfig/")

register_fprime_module(
    EXCLUDE_FROM_ALL
    AUTOCODER_INPUTS
        "${CMAKE_CURRENT_LIST_DIR}/JetsonComCcsds.fpp"
    HEADERS
        "${CMAKE_CURRENT_LIST_DIR}/SubtopologyTopologyDefs.hpp"
        "${CMAKE_CURRENT_LIST_DIR}/PingEntries.hpp"
    DEPENDS
        JetsonDeployment_Subtopologies_JetsonComCcsds_JetsonComCcsdsConfig
    INTERFACE
)
