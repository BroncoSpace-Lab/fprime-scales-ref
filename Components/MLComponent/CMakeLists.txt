####
# FPrime CMakeLists.txt:
#
# SOURCE_FILES: combined list of source and autocoding files
# MOD_DEPS: (optional) module dependencies
# UT_SOURCE_FILES: list of source files for unit tests
#
# More information in the F´ CMake API documentation:
# https://fprime.jpl.nasa.gov/latest/documentation/reference
#
####
restrict_platforms(aarch64-linux)
register_fprime_library(
  AUTOCODER_INPUTS
    "${CMAKE_CURRENT_LIST_DIR}/MLComponent.fpp"
  SOURCES
    "${CMAKE_CURRENT_LIST_DIR}/MLComponent.py"
)

# Uncomment and add any modules that this component depends on, else
# they might not be available when cmake tries to build this component.
#
# Module names are derived from the path from the nearest project/library/framework
# root when not specifically overridden by the developer. i.e. The module defined by
# `Ref/SignalGen/CMakeLists.txt` will be named `Ref_SignalGen`.  `Ref/SignalGen`
# is an acceptable alternative and will be internally converted to `Ref_SignalGen`.
#
# set(MOD_DEPS
#   MyPackage_MyOtherModule
# )

#register_python_component("${CMAKE_BINARY_DIR}/Components/MLComponent/MLComponentComponentAi.xml" "${CMAKE_CURRENT_LIST_DIR}/MLComponent.py")
# Luca here, the line above^ was the original call. Here is why ive commented it out
# The direct register_python_component call fails during F Prime's info-cache
# sub-build because pybind.cmake is not loaded in that pass, so the command is
# not defined yet.
#
# Guard the call so the info-cache pass can skip Python binding registration,
# while the main build can register MLComponent with pybind once the command
# exists. MLComponent must not be platform-restricted out of the main build, or
# PYTHON_BINDINGS remains empty and pybind_gen.py is invoked as "--ai" with no
# XML path.


#egister_fprime_module()
#register_python_component("${CMAKE_BINARY_DIR}/Components/MLComponent/MLComponentComponentAi.json" "${CMAKE_CURRENT_LIST_DIR}/MLComponent.py")

# if(COMMAND register_python_component)
#   register_python_component(
#     "${CMAKE_BINARY_DIR}/Components/MLComponent/MLComponentComponentAi.xml"
#     "${CMAKE_CURRENT_LIST_DIR}/MLComponent.py"
#   )
# endif()

### Unit Tests ###
# set(UT_SOURCE_FILES
#   "${CMAKE_CURRENT_LIST_DIR}/MLComponent.fpp"
#   "${CMAKE_CURRENT_LIST_DIR}/test/ut/MLComponentTestMain.cpp"
#   "${CMAKE_CURRENT_LIST_DIR}/test/ut/MLComponentTester.cpp"
# )
# set(UT_MOD_DEPS
#   STest
# )
# set(UT_AUTO_HELPERS ON)
# register_fprime_ut()
