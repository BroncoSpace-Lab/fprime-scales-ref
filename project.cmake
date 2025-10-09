# This CMake file is intended to register project-wide objects.
# This allows for reuse between deployments, or other projects.

<<<<<<< HEAD
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Components")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/ImxDeployment/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/JetsonDeployment/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/lib/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/lib/fprime-scales/scales/scalesSvc")
=======
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/ImxDeployment/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/JetsonDeployment/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/lib/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Components/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/lib/fprime-scales/scales/scalesSvc")
>>>>>>> d6b4fd2b8701b9c2bc49f92a1064cec42ceb1590
