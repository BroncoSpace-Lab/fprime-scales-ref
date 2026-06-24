#####
# JetsonDeployment
#####

restrict_platforms("aarch64-linux")

include(implementation)

add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Top/")

register_fprime_deployment(
    SOURCES
        "${CMAKE_CURRENT_LIST_DIR}/Main.cpp"
        "${CMAKE_CURRENT_LIST_DIR}/fsw_main.py"
    CHOOSES_IMPLEMENTATIONS
        FprimePython_PythonConsole
    DEPENDS
        ${FPRIME_CURRENT_MODULE}_Top
)
if (NOT DEFINED FPRIME_SUB_BUILD_TARGETS)
    find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
    target_link_libraries(JetsonDeployment PRIVATE Python3::Python)
endif()