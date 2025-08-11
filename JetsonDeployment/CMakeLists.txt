#####
# 'JetsonDeployment' Deployment:
#
# This registers the 'JetsonDeployment' deployment to the build system. 
# Custom components that have not been added at the project-level should be added to 
# the list below.
#
#####

restrict_platforms("aarch64-linux")

include(implementation)

###
# Topology and Components
###
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Top/")
# register_fprime_target("${CMAKE_SOURCE_DIR}/lib/fprime-python/cmake/target/pybind.cmake")


# Add custom components to this specific deployment here
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MyComponent/")


set(SOURCE_FILES "${CMAKE_CURRENT_LIST_DIR}/Main.cpp")
set(MOD_DEPS ${FPRIME_CURRENT_MODULE}_Top)

skip_on_sub_build()
add_library(python_extension SHARED ${SOURCE_FILES})
add_dependencies(python_extension ${MOD_DEPS})
target_link_libraries(python_extension PUBLIC ${MOD_DEPS})
set_target_properties(python_extension PROPERTIES
    SUFFIX ".so"
)
target_compile_options(python_extension PUBLIC "-fPIC")
setup_executable_implementations(python_extension)

register_fprime_deployment()
