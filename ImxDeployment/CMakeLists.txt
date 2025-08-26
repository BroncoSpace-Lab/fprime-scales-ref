#####
# 'ImxDeployment' Deployment:
#
# This registers the 'ImxDeployment' deployment to the build system. 
# Custom components that have not been added at the project-level should be added to 
# the list below.
#
#####
restrict_platforms(imx8x)
set_target_properties(fprime-python_FprimePy PROPERTIES EXCLUDE_FROM_ALL TRUE)
set_target_properties(pybind PROPERTIES EXCLUDE_FROM_ALL TRUE)
###
# Topology and Components
###
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Top/")

# Add custom components to this specific deployment here
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MyComponent/")


set(SOURCE_FILES "${CMAKE_CURRENT_LIST_DIR}/Main.cpp")
set(MOD_DEPS ${FPRIME_CURRENT_MODULE}/Top)

register_fprime_deployment()
