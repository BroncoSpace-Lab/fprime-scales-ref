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

restrict_platforms(aarch64-linux)

set(SOURCE_FILES
  "${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera.fpp"
  "${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera.cpp"
)

# Uncomment and add any modules that this component depends on, else
# they might not be available when cmake tries to build this component.
#
# Module names are derived from the path from the nearest project/library/framework
# root when not specifically overridden by the developer. i.e. The module defined by
# `Ref/SignalGen/CMakeLists.txt` will be named `Ref_SignalGen`.  `Ref/SignalGen`
# is an acceptable alternative and will be internally converted to `Ref_SignalGen`.
#
set(MOD_DEPS
  "${PROJECT_SOURCE_DIR}/lib/ArenaSDK"
)

register_fprime_module()

# add_fprime_subdirectory(${PROJECT_SOURCE_DIR}/libs)


### Unit Tests ###
# set(UT_SOURCE_FILES
#   "${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera.fpp"
#   "${CMAKE_CURRENT_LIST_DIR}/test/ut/RunLucidCameraTestMain.cpp"
#   "${CMAKE_CURRENT_LIST_DIR}/test/ut/RunLucidCameraTester.cpp"
# )
# set(UT_MOD_DEPS
#   STest
# )
# set(UT_AUTO_HELPERS ON)
# register_fprime_ut()

# # Retrieve the name of the module that converts the root path of your project to a underscore, i.e. Fw/Types becomes Fw_Types.
# get_module_name("${CMAKE_CURRENT_LIST_DIR}")

# # # Tell the compiler the path to the library header file.
# include_directories("${PROJECT_SOURCE_DIR}/libs")

# include_directories("${PROJECT_SOURCE_DIR}/libs/ArenaSDK_Linux_ARM64/include/Arena/")
# include_directories("${PROJECT_SOURCE_DIR}/libs/ArenaSDK_Linux_ARM64/include/GenTL/")
# include_directories("${PROJECT_SOURCE_DIR}/libs/ArenaSDK_Linux_ARM64/include/Save/")
# include_directories("${PROJECT_SOURCE_DIR}/libs/ArenaSDK_Linux_ARM64/GenICam/")
# include_directories("${PROJECT_SOURCE_DIR}/libs/ArenaSDK_Linux_ARM64/ffmpeg")
# # Find all the libraries contained in the directory you specified.
# find_library(LIBARENA ${Arena} "${PROJECT_SOURCE_DIR}/libs")
# include_directories(${})

# add_subdirectory(${PROJECT_SOURCE_DIR}/libs/ArenaSDK_Linux_ARM64 arena)
# target_link_libraries("${MODULE_NAME}" ${Arena})
# add_library(MyArena
#   ${PROJECT_SOURCE_DIR}/libs/ArenaSDK_Linux_ARM64/include/Arena/ArenaApi.h
# )
# set_target_properties(MyArena PROPERTIES LINKER_LANGUAGE CXX)
# target_link_libraries(${MODULE_NAME} ${MyArena})

# add_library(ComponentArena INTERFACE)
# target_include_directories(ComponentArena INTERFACE ${PROJECT_SOURCE_DIR}/libs/ArenaSDK_Linux_ARM64/include/Arena/ArenaApi.h)
# target_link_libraries(${MODULE_NAME} ${ComponentArena})

# message("[TESTING BED]: ${LIBARENA}")

# # Specify to the linker the libraries to use when linking the given component and its dependents. 
# target_link_libraries("${MODULE_NAME}" "${LIBARENA}")
