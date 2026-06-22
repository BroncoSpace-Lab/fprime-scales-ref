####
# This sets up the build system for the 'fprime-scales-ref' project, including
# components and deployments from project.cmake. In addition, it imports the core F Prime components.
####

cmake_minimum_required(VERSION 3.24.2)
project(PPythonF3 C CXX)
add_compile_options(-fPIC)

###
# F' Core Setup
# This includes all of the F prime core components, and imports the make-system.
###
set(FPRIME_ENABLE_JSON_MODEL_GENERATION ON)
include("${CMAKE_CURRENT_LIST_DIR}/lib/fprime/cmake/FPrime.cmake")

# Register fprime_python build target
if (NOT DEFINED FPRIME_SUB_BUILD_TARGETS)
    # FPP locations must come at the front of the list, then build
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(PYBIND11_FINDPYTHON ON)
    find_package(pybind11 CONFIG REQUIRED PATHS "$ENV{VIRTUAL_ENV}/lib/*/site-packages/")
    link_libraries("pybind11::module" "pybind11::headers")
    register_fprime_target(target/fprime_python)
endif()

# NOTE: register custom targets between these two lines
fprime_setup_included_code()


# This includes project-wide objects
include("${CMAKE_CURRENT_LIST_DIR}/project.cmake")
include_directories("${FPRIME_PROJECT_ROOT}")
set(FPRIME_CURRENT_BUILD_ROOT "${CMAKE_CURRENT_LIST_DIR}/..")
message(STATUS "F prime BUILD_ROOT currently set to: ${FPRIME_CURRENT_BUILD_ROOT}")
