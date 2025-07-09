# fprime-scales-ref F' project

## How to Clone

There are a few git submodules used here, so when cloning be sure to init and update them.

```
git clone https://github.com/BroncoSpace-Lab/fprime-scales-ref.git
cd fprime-scales-ref
git checkout kellydev
python3.11 -m venv fprime-venv
source fprime-venv/bin/activate
cd libs
git submodule init && git submodule update
pip install -r fprime/requirements.txt
cd fprime-python
git submodule init && git submodule update
cd ../..
cd Components/MLcomponent
git submodule init && git submodule update
cd ../..
```

### Necessary Changes

Some lines need to be commented in `lib/fprime/cmake/API.cmake` in order to use `fprime-python`. Comment out lines [545](https://github.com/nasa/fprime/blob/5a3b873854fe4d646d6874d134585535652fddb9/cmake/API.cmake#L545) and [562](https://github.com/nasa/fprime/blob/5a3b873854fe4d646d6874d134585535652fddb9/cmake/API.cmake#L562).

---

## JetsonDeployment Build Configuration

Your `settings.ini` should look like this:

```
[fprime]
project_root: .
framework_path:     ./lib/fprime
; uncomment this line for JetsonDeployment
library_locations:  ./lib/fprime-python:./lib/fprime-scales
; uncomment this line for ImxDeployment
; library_locations:  ./lib/fprime-scales:

default_cmake_options:  FPRIME_ENABLE_FRAMEWORK_UTS=OFF
                        FPRIME_ENABLE_AUTOCODER_UTS=OFF
```

Your `project.cmake` should look like this:

```
# This CMake file is intended to register project-wide objects.
# This allows for reuse between deployments, or other projects.

add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Components")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/ImxDeployment/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/JetsonDeployment/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/lib/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/lib/fprime-scales/scales/scalesSvc")
```

Your `CMakeLists.txt` in the root project directory should have line 17 containing `register_fprime_target("${CMAKE_SOURCE_DIR}/lib/fprime-python/cmake/target/pybind.cmake")` **uncommented**.

Your `Components/CMakeLists.txt` should look like this:

```
# Include project-wide components here

#add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/PythonComponent/")
#add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/StandardBlankComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MLComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/PythonComponent/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MLComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera/")
```

After all of this, you should be able to `fprime-util generate && fprime-util build` for the JetsonDeployment.

## ImxDeployment

To correctly generate and build for the IMX, you need to have the build environment on your machine. Refer to [this guide](https://scales-docs.readthedocs.io/en/latest/imx_yocto_bsp/#building-the-bsp) we made on our docs for how to set up the IMX SDK.

### For Successful Build

Your `settings.ini` should look like this:

```
[fprime]
project_root: .
framework_path:     ./lib/fprime
; uncomment this line for JetsonDeployment
; library_locations:  ./lib/fprime-python:./lib/fprime-scales
; uncomment this line for ImxDeployment
library_locations:  ./lib/fprime-scales:

default_cmake_options:  FPRIME_ENABLE_FRAMEWORK_UTS=OFF
                        FPRIME_ENABLE_AUTOCODER_UTS=OFF
```

Your `project.cmake` should look like this:

```
# This CMake file is intended to register project-wide objects.
# This allows for reuse between deployments, or other projects.

# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Components")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/ImxDeployment/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/JetsonDeployment/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/lib/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/lib/fprime-scales/scales/scalesSvc")
```

Your `CMakeLists.txt` in the root project directory should have line 17 containing `register_fprime_target("${CMAKE_SOURCE_DIR}/lib/fprime-python/cmake/target/pybind.cmake")` **commented**.

Your `Components/CMakeLists.txt` should look like this:

```
# Include project-wide components here

# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/PythonComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/StandardBlankComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MLComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/PythonComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MLComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera/")
```

After all of this, you should be able to `fprime-util generate imx8x && fprime-util build imx8x` for the ImxDeployment.

### To Re-Create the Error

Your `settings.ini` should look like this:

```
[fprime]
project_root: .
framework_path:     ./lib/fprime
; uncomment this line for JetsonDeployment
library_locations:  ./lib/fprime-python:./lib/fprime-scales
; uncomment this line for ImxDeployment
; library_locations:  ./lib/fprime-scales:

default_cmake_options:  FPRIME_ENABLE_FRAMEWORK_UTS=OFF
                        FPRIME_ENABLE_AUTOCODER_UTS=OFF
```

Your `project.cmake` should look like this:

```
# This CMake file is intended to register project-wide objects.
# This allows for reuse between deployments, or other projects.

add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/Components")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/ImxDeployment/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/JetsonDeployment/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/lib/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/lib/fprime-scales/scales/scalesSvc")
```

Your `CMakeLists.txt` in the root project directory should have line 17 containing `register_fprime_target("${CMAKE_SOURCE_DIR}/lib/fprime-python/cmake/target/pybind.cmake")` **uncommented**.

Your `Components/CMakeLists.txt` should look like this:

```
# Include project-wide components here

# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/PythonComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/StandardBlankComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MLComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/PythonComponent/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MLComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera/")
```

After all of this, you should be able to `fprime-util generate imx8x && fprime-util build imx8x` to re-create the error for the ImxDeployment.

---

This project was auto-generated by the F' utility tool. 

F´ (F Prime) is a component-driven framework that enables rapid development and deployment of spaceflight and other embedded software applications.
**Please Visit the F´ Website:** https://fprime.jpl.nasa.gov.
