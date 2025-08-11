# fprime-scales-ref F' project

Watch our video demo on [YouTube](https://youtu.be/-g3Wv_fr9r8?si=2xow8_22aNjE1XDO)!

Check out our [docs page](https://scales-docs.readthedocs.io/en/latest/)!

## How to Clone

There are a few git submodules used here, so when cloning be sure to init and update them.

```
git clone https://github.com/BroncoSpace-Lab/fprime-scales-ref.git
cd fprime-scales-ref
make setup
make arena-init
source fprime-venv/bin/activate
```

### Necessary Changes

Some lines need to be commented in `lib/fprime/cmake/API.cmake` in order to use `fprime-python`. Comment out lines [545](https://github.com/nasa/fprime/blob/5a3b873854fe4d646d6874d134585535652fddb9/cmake/API.cmake#L545) and [562](https://github.com/nasa/fprime/blob/5a3b873854fe4d646d6874d134585535652fddb9/cmake/API.cmake#L562).

After this, you should be good to go!

---

## JetsonDeployment Build Configuration

You must generate build JetsonDeployment on the Jetson, we have not set up cross-compilation for aarch64-linux yet.

<details>

<summary> JetsonDeployment Build Configuration Details </summary>

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

# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/StandardBlankComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/PythonComponent/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MLComponent/")
add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera/")
```

</details>

After all of this, **on the Jetson** you should be able to generate and build the JetsonDeployment.

To generate: 

```
fprime-util generate aarch64-linux -f
```

To build and set up the build environment:

```
make build-jetson
```

## ImxDeployment

To correctly generate and build for the IMX, you need to have the build environment on your machine. Refer to [this guide](https://scales-docs.readthedocs.io/en/latest/imx_yocto_bsp/#building-the-bsp) we made on our docs for how to set up the IMX SDK.

<details>

<summary> ImxDeployment Build Configuration Details </summary>

### For Successful Build

Your `settings.ini` should look like this:

```
[fprime]
project_root: .
framework_path:     ./lib/fprime
; uncomment this line for JetsonDeployment
; library_locations:  ./lib/fprime-python:./lib/fprime-scales
; uncomment this line for ImxDeployment
library_locations:  ./lib/fprime-scales

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

# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/StandardBlankComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/PythonComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/MLComponent/")
# add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/RunLucidCamera/")
```

</details>


After all of this, you should be able to generate and build the ImxDeployment on your host machine.

To generate: 

```
fprime-util generate imx8x -f
```

To build:

```
fprime-util build imx8x
```

# To Run the SCALES Demo

## IMX Setup

1. Follow the instructions above to build ImxDeployment on the host machine. Use the following command to ssh into the IMX.

    ```
    ssh root@<ip of imx> -o HostKeyAlgorithms=+ssh-rsa -o PubKeyAcceptedAlgorithms=+ssh-rsa
    ```

2. Make sure you are able to ping both the host machine and the Jetson from the IMX. Copy the ImxDeployment binary from the host machine to the IMX. (Run this command on the host machine.)

    ```
    scp -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa ~/fprime-scales-ref/build-artifacts/imx8x/ImxDeployment/bin/ImxDeployment root@<ip of imx>:~/.
    ```

3. Copy the binary files for the sequences to the IMX.

    ```
    scp -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa ~/fprime-scales-ref/save-png.bin root@<ip of imx>:~/.
    scp -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa ~/fprime-scales-ref/batch-send-img.bin root@<ip of imx>:~/.
    ```

## Jetson Setup

1. On the Jetson, follow the above directions to generate and build JetsonDeployment.

2. Change the IP of the IMX in `Jetsondeployment/Top/JetsonDeploymentTopology.cpp` to match the IP of the IMX.

    ```
    // line 32
    const char* REMOTE_HUIP_ADDRESS = "10.3.2.2"; // ip of JPL IMX
    // const char* REMOTE_HUIP_ADDRESS = "192.168.0.66"; // ip of CPP IMX
    const U32 REMOTE_HUPORT = 50500;
    ```

3. Rebuild JetsonDeployment.

    ```
    make build-jetson
    ```

4. **For first time setup only:** Make a folder with a symbolic link to where the camera images are saved. This is done to assure the paths for commands in the fprime-gds are not too long.

    ```
    sudo ln -s ~/fprime-scales-ref/build-python-fprime-aarch64-linux/Images/ ./Images
    ```

    The `Images` folder will be created in your root directory.

## Host Setup

1. Open another terminal on the host machine and enter the directory for the repo and source your environment.

    ```
    cd fprime-scales-ref
    source fprime-venv/bin/activate
    ```

2. Copy the ImxDeployment dictionary to the GDS-Dictionary folder on the host machine. Run this command on the host machine.

    ```
    cp ~/fprime-scales-ref/build-artifacts/imx8x/ImxDeployment/dict/ImxDeploymentTopologyAppDictionary.xml ~/fprime-scales-ref/GDS-Dictionary/.
    ```

3. Copy the JetsonDeployment dictionary from the Jetson to the host machine. Run this command on the host machine.

    ```
    scp <jetson name>@<jetson IP>:~/fprime-scales-ref/build-artifacts/aarch64-linux/JetsonDeployment/dict/JetsonDeploymentTopologyAppDictionary.xml ~/fprime-scales-ref/GDS-Dictionary/.
    ```

6. Combine the GDS dictionaries with the `merger.py` script. Run this command on the host machine.

    ```
    python merger.py JetsonDeploymentTopologyAppDictionary.xml ImxDeploymentTopologyAppDictionary.xml GDSDictionary.xml
    ```

You are now ready to run the demo!

## Running the Demo

1. After you finished setting up the demo in the previous section, on the host machine, navigate to the `GDS-Dictionary` folder and run the fprime-gds.

    ```
    fprime-gds -n --dictionary GDSDictionary.xml --ip-client --ip-address <ip of imx>
    ```

2. On the IMX, run the ImxDeployment binary. You should see a green dot on the fprime-gds and "Accepted client" in the IMX terminal.

    ```
    ./ImxDeployment -a 0.0.0.0 -p 50000
    ```

3. On the Jetson, navigate to the `build-python-fprime-aarch64-linux` directory to run the fprime-gds using python.

    ```
    cd build-python-fprime-aarch64-linux
    python
    ```

    Once the python environment opens, run the following commands to connect to the IMX's fprime-gds using the hub pattern. If you want to exit the python environment, the command is `exit()`.

    ```
    import python_extension
    python_extension.main()
    ```

4. On the host machine, use the fprime-gds to run the `jetson_cmdDisp.CMD_NO_OP` to test the connection with the Jetson. Do the same for the IMX with the `imx_cmdDisp.CMD_NO_OP`. You can see both events and their status in the "Events" tab of the GDS.

5. Once the camera is connected, run the `jetson_lucidCamera.SETUP_CAMERA` command to verify the connection via fprime. 

6. To take a picture with the camera, run the `imx_RUN` command in the fprime-gds with argument `save-png.bin`. This will take a pictire with the camera, downlink it to the IMX, and then downlink it again to the Host Machine. You can download the image from the `Downlink` tab in the GDS.

7. If you would like to send a batch of saved images from the Jetson to the Host, run the `imx_RUN` command with argument `batch-send-img.bin`. This sequence will zip the saved images on the Jetson into a folder, downlink that zipped folder to the IMX and then again to the Host. You can download the zipped Images folder from the `Downlink` tab in the GDS.

8. To run ML on the images, run the `jetson_mlManager.SET_ML_PATH` command with argument `resent_inference`. Then, set the inference path to where the images are stored with the `jetson_mlManager.SET_INFERENCE_PATH` command with argement `../Images`. Finally, run the ML model with command `jetson_mlManager.MULTI_INFERENCE`. You should see the results of the ML model both in the Jetson's terminal and in the Jetson's fprime-gds Events log.

That's how to run the SCALES demo!

Watch our video demo on [YouTube](https://youtu.be/-g3Wv_fr9r8?si=2xow8_22aNjE1XDO)!

---

This project was auto-generated by the F' utility tool. 

F´ (F Prime) is a component-driven framework that enables rapid development and deployment of spaceflight and other embedded software applications.
**Please Visit the F´ Website:** https://fprime.jpl.nasa.gov.