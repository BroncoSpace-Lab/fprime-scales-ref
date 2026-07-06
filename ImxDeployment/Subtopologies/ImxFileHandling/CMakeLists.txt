add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/ImxFileHandlingConfig/")

register_fprime_module(
    EXCLUDE_FROM_ALL
    AUTOCODER_INPUTS
        "${CMAKE_CURRENT_LIST_DIR}/ImxFileHandling.fpp"
    HEADERS
        "${CMAKE_CURRENT_LIST_DIR}/SubtopologyTopologyDefs.hpp"
        "${CMAKE_CURRENT_LIST_DIR}/PingEntries.hpp"
    INTERFACE
    DEPENDS
        ImxDeployment_Subtopologies_ImxFileHandling_ImxFileHandlingConfig
)
