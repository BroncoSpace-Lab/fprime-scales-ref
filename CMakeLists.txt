####
# This sets up the build system for the 'fprime-scales-ref' project, including
# components and deployments from project.cmake. In addition, it imports the core F Prime components.
####

cmake_minimum_required(VERSION 3.13)
project(fprime-scales-ref C CXX)

###
# F' Core Setup
# This includes all of the F prime core components, and imports the make-system.
###
include("${CMAKE_CURRENT_LIST_DIR}/lib/fprime/cmake/FPrime.cmake")
# NOTE: register custom targets between these two lines
fprime_setup_included_code()


# This includes project-wide objects
include("${CMAKE_CURRENT_LIST_DIR}/project.cmake")
include_directories("${FPRIME_PROJECT_ROOT}")
set(FPRIME_CURRENT_BUILD_ROOT "${CMAKE_CURRENT_LIST_DIR}/..")
message(STATUS "F prime BUILD_ROOT currently set to: ${FPRIME_CURRENT_BUILD_ROOT}")