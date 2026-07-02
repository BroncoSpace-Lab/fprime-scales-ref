cmake_minimum_required(VERSION 3.24.2)
project(PPythonF3 C CXX)

set(FPRIME_PROJECT_VENV "$ENV{VIRTUAL_ENV}")
if (NOT FPRIME_PROJECT_VENV AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/fprime-venv/bin/python")
    set(FPRIME_PROJECT_VENV "${CMAKE_CURRENT_LIST_DIR}/fprime-venv")
endif()

if (FPRIME_PROJECT_VENV AND EXISTS "${FPRIME_PROJECT_VENV}/bin")
    list(PREPEND CMAKE_PROGRAM_PATH "${FPRIME_PROJECT_VENV}/bin")
    if (NOT DEFINED PYTHON AND EXISTS "${FPRIME_PROJECT_VENV}/bin/python")
        set(PYTHON "${FPRIME_PROJECT_VENV}/bin/python" CACHE FILEPATH "Python interpreter for F Prime tools")
    endif()
endif()

set(FPRIME_ENABLE_JSON_MODEL_GENERATION ON)

include("${CMAKE_CURRENT_LIST_DIR}/lib/fprime/cmake/FPrime.cmake")

if (NOT DEFINED FPRIME_SUB_BUILD_TARGETS)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(PYBIND11_FINDPYTHON ON)

    execute_process(
        COMMAND "${PYTHON}" -m pybind11 --cmakedir
        RESULT_VARIABLE PYBIND11_CMAKEDIR_RESULT
        OUTPUT_VARIABLE PYBIND11_CMAKEDIR
        ERROR_VARIABLE PYBIND11_CMAKEDIR_ERROR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
    )

    if (NOT PYBIND11_CMAKEDIR_RESULT EQUAL 0)
        message(FATAL_ERROR "Unable to locate pybind11 CMake package using ${PYTHON}: ${PYBIND11_CMAKEDIR_ERROR}")
    endif()

    find_package(pybind11 CONFIG REQUIRED PATHS "${PYBIND11_CMAKEDIR}" NO_CMAKE_FIND_ROOT_PATH)
    #link_libraries("pybind11::module" "pybind11::headers")

    register_fprime_target(target/fprime_python)
endif()

fprime_setup_included_code()

include("${CMAKE_CURRENT_LIST_DIR}/project.cmake")
include_directories("${FPRIME_PROJECT_ROOT}")