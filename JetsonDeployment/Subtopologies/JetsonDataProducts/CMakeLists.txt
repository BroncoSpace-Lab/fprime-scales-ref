add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/JetsonDataProductsConfig/")

register_fprime_module(
    EXCLUDE_FROM_ALL
    AUTOCODER_INPUTS
        "${CMAKE_CURRENT_LIST_DIR}/JetsonDataProducts.fpp"
    HEADERS
        "${CMAKE_CURRENT_LIST_DIR}/SubtopologyTopologyDefs.hpp"
        "${CMAKE_CURRENT_LIST_DIR}/PingEntries.hpp"
    DEPENDS
        JetsonDeployment_Subtopologies_JetsonDataProducts_JetsonDataProductsConfig
    INTERFACE
)
