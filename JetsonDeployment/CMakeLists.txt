#####
# 'JetsonDeployment' Deployment:
#
# This registers the 'JetsonDeployment' deployment to the build system. 
# Custom components that have not been added at the project-level should be added to 
# the list below.
#
#####

restrict_platforms("aarch64-linux")
###
# Topology and Components
###
include(implementation)

add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Top/")

# Add custom components to this specific deployment here
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MyComponent/")


register_fprime_deployment(
    SOURCES
        "${CMAKE_CURRENT_LIST_DIR}/Main.cpp"
        "${CMAKE_CURRENT_LIST_DIR}/fsw_main.py"
    CHOOSES_IMPLEMENTATIONS
        Os_Generic_PriorityQueue
        Os_File_Posix
        Os_Task_Posix
        Os_Mutex_Posix
        Os_RawTime_Posix
        Os_Console_Posix 
    DEPENDS
        ${FPRIME_CURRENT_MODULE}_Top
)

if (NOT DEFINED FPRIME_SUB_BUILD_TARGETS)
    find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
    target_link_libraries(JetsonDeployment PRIVATE Python3::Python)
endif()