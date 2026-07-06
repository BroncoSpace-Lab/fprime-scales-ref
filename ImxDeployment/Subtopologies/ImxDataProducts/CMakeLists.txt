add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/ImxDataProductsConfig/")

register_fprime_module(
    EXCLUDE_FROM_ALL
    AUTOCODER_INPUTS
        "${CMAKE_CURRENT_LIST_DIR}/ImxDataProducts.fpp"
    HEADERS
        "${CMAKE_CURRENT_LIST_DIR}/SubtopologyTopologyDefs.hpp"
        "${CMAKE_CURRENT_LIST_DIR}/PingEntries.hpp"
    DEPENDS
        ImxDeployment_Subtopologies_ImxDataProducts_ImxDataProductsConfig
    INTERFACE
)
