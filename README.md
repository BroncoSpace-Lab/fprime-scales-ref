# fprime-scales-ref F' Project

Welcome to the Space Compartmentalized Autonomous Learning and Edge computing System!

This README explains how to set up the SCALES development environment and run the SCALES demo.

Watch our video demo on [YouTube](https://youtu.be/-g3Wv_fr9r8?si=2xow8_22aNjE1XDO)!

Check out our [docs page](https://scales-docs.readthedocs.io/en/latest/)!

## Software Architecture

<div style="text-align: center;">
    <img src="docs/Images/scales-fsw-arch.png" alt="SCALES flight software architecture" width="1000" margin="center">
</div>

## Development Environment

We recommend using the following development environment:

- Ubuntu 22.04 host machine
- Python 3.12
- Git LFS:
  - [amd64 host machine installer](https://git-lfs.com/)
  - [arm64 Jetson installer](https://github.com/git-lfs/git-lfs/releases/download/v3.7.0/git-lfs-linux-arm64-v3.7.0.tar.gz)
- IMX8X BSP set up on your host machine. See the [IMX8X BSP setup guide](https://scales-docs.readthedocs.io/en/latest/imx_yocto_bsp/).

## Setup SCALES

It is recommended that you set up all custom hardware according to the guides below. Once all devices are working according to the recommended setup guides, you may continue setting up your development environment.

<a id="hardware-setup"></a>
<details>
<summary><strong>Hardware Setup</strong></summary>

### SCALES Compute Module

The SCALES Compute Module serves as the central processing unit of the system. This module contains an F' framework application that includes the software architecture and flight software components.

- [Setup Guide](https://scales-docs.readthedocs.io/en/latest/imx8x_merger/)

### Peripheral Board

The peripheral board provides connectivity to various peripherals, such as sensors, actuators, and communication interfaces.

- [Setup Guide](https://scales-docs.readthedocs.io/en/latest/peripheral_board/)

### Jetson Orin AGX

The Jetson is a powerful AI computer that runs the F' software on top of the Linux operating system.

- [Setup Guide](https://scales-docs.readthedocs.io/en/latest/nvidia_jetson_orin_agx/)

</details>

Use the commands below in a terminal to clone and set up the repository on both your Linux host machine, which should have the IMX8X SDK installed, and the Nvidia Jetson Orin AGX.

Before proceeding, make sure you have [Git LFS](https://git-lfs.com/) installed. Also, make sure to source `fprime-venv` before continuing development.

```bash
git clone https://github.com/BroncoSpace-Lab/fprime-scales-ref.git
cd fprime-scales-ref
make setup
source fprime-venv/bin/activate
```

## How to Build ImxDeployment

To generate and build for the IMX, you need to have the build environment set up on your machine. Refer to the [IMX SDK setup guide](https://scales-docs.readthedocs.io/en/latest/imx_yocto_bsp/#building-the-bsp) for instructions. Once that setup is complete, you may continue.

**On the Linux host machine**, generate ImxDeployment:

```bash
fprime-util generate imx8x -f
```

Build ImxDeployment:

```bash
fprime-util build imx8x
```

Once your deployment has built, copy the binary over the existing `ImxDeployment` on the IMX. You can use `scp` to copy the binary over the peripheral board network with a command similar to the one below.

**On the Linux host machine:**

```bash
scp fprime-scales-ref/build-artifacts/imx8x/ImxDeployment/bin/ImxDeployment root@<ip-of-imx>:/tmp/
```

**On the IMX:**

```bash
# From within /root
mv /tmp/ImxDeployment .
reboot now
```

On the next boot, the new ImxDeployment will be loaded as a system service and run on boot.

Since a deployment has been generated, ensure that its dictionary is copied to `fprime-scales-ref/GDSDictionary` so that once you have the Jetson dictionary, you can merge both dictionaries and run the GDS.

**On the Linux host machine**, copy the IMX dictionary to the `GDSDictionary` folder:

```bash
cp fprime-scales-ref/build-artifacts/imx8x/ImxDeployment/dict/ImxTopologyDictionary.json fprime-scales-ref/GDSDictionary
```

If the deployment has been copied to the IMX and you want to test the IMX alone with the GDS, navigate to the `GDSDictionary` folder and run:

```bash
./test-imx-only.sh
```

This will start the GDS with only the IMX dictionary. You should see a browser window open, and the GDS icon on the far right should turn from a red X to a green dot.

> **Note:** If you have added or changed sequences, you can recompile them using the dictionaries and copy them over to `/root` on the IMX. The sequences needed to run the demo come prepackaged in the SCALES Compute Module BSP.

## How to Build JetsonDeployment

**First-time setup only:** Set up the Arena SDK for the Ethernet camera. Run this command **on the Jetson**:

```bash
make arena-init
```

<details>
<summary><strong>Note: Running without the Ethernet camera</strong></summary>

If you are running this without the Ethernet camera, you can skip this step. Just make sure to comment out the following lines:

- [RunLucidCamera in Components/CMakeLists.txt](https://github.com/BroncoSpace-Lab/fprime-scales-ref/blob/4d7539bd00343ee9b80e19f95b4a6aae525610b0/Components/CMakeLists.txt#L4)
- [`add_fprime_subdirectory("${CMAKE_CURRENT_LIST_DIR}/ArenaSDK/")` in /lib/CMakeLists.txt](https://github.com/BroncoSpace-Lab/fprime-scales-ref/blob/4d7539bd00343ee9b80e19f95b4a6aae525610b0/lib/CMakeLists.txt#L1)

</details>

You must generate and build JetsonDeployment on the Jetson. Cross-compilation for `aarch64-linux` has not been set up yet.

**On the Jetson**, you should be able to generate and build JetsonDeployment. From within `fprime-scales-ref`, source your F' environment:

```bash
source fprime-venv/bin/activate
```

You should now be able to generate and build JetsonDeployment with the commands below:

```bash
fprime-util generate aarch64-linux -f
make build-jetson
```

The `make build-jetson` command will restart the system service with the new deployment and create a linked folder for the camera images.

# Run the SCALES Demo

<a id="imx-setup"></a>
<details>
<summary><strong>IMX Setup</strong></summary>

These steps are only required if changes have been made to ImxDeployment. Otherwise, the binary on the IMX should already be fine.

1. Follow the instructions above to build ImxDeployment on the host machine.

2. Make sure you are able to ping both the host machine and the Jetson from the IMX. Then, copy the ImxDeployment binary from the host machine to the IMX.

    **On the host machine:**

    ```bash
    scp fprime-scales-ref/build-artifacts/imx8x/ImxDeployment/bin/ImxDeployment root@<ip-of-imx>:/tmp/
    ```

    **On the IMX, from `/root`:**

    ```bash
    mv /tmp/ImxDeployment .
    reboot now
    ```

3. Copy the binary files for the sequences to the IMX:

    ```bash
    scp fprime-scales-ref/Sequences/save-png.bin root@<ip-of-imx>:/root
    scp fprime-scales-ref/Sequences/batch-send-img.bin root@<ip-of-imx>:/root
    scp fprime-scales-ref/Sequences/snap-n-save.bin root@<ip-of-imx>:/root
    scp fprime-scales-ref/Sequences/Zip-n-send-img.bin root@<ip-of-imx>:/root
    scp fprime-scales-ref/Sequences/test-resnet.bin root@<ip-of-imx>:/root
    scp fprime-scales-ref/Sequences/demo.bin root@<ip-of-imx>:/root
    scp fprime-scales-ref/Sequences/run-ml.bin root@<ip-of-imx>:/root
    ```

</details>

<a id="jetson-setup"></a>
<details>
<summary><strong>Jetson Setup</strong></summary>

1. On the Jetson, follow the directions above to generate and build JetsonDeployment.

2. Make sure the IP of the IMX is set in `JetsonDeployment/Top/JetsonDeploymentTopology.cpp` and matches the IP of the IMX:

    ```cpp
    // line 37
    const char* IMX_HUB_IP_ADDRESS = "10.3.2.10";
    ```

3. Rebuild JetsonDeployment:

    ```bash
    make build-jetson
    ```

4. **First-time setup only:** Make a folder with a symbolic link to where the camera images are saved. This ensures that the paths for commands in the fprime-gds are not too long.

    ```bash
    sudo ln -s ~/fprime-scales-ref/build-python-fprime-aarch64-linux/Images/ ./Images
    ```

    The `Images` folder will be created in your root directory.

</details>

<a id="host-setup"></a>
<details>
<summary><strong>Host Setup</strong></summary>

1. Open another terminal on the host machine, enter the repository directory, and source your environment:

    ```bash
    cd fprime-scales-ref
    source fprime-venv/bin/activate
    ```

2. Copy the ImxDeployment dictionary to the `GDS-Dictionary` folder on the host machine:

    ```bash
    cp fprime-scales-ref/build-artifacts/imx8x/ImxDeployment/dict/ImxDeploymentTopologyDictionary.json fprime-scales-ref/GDS-Dictionary/.
    ```

3. Copy the JetsonDeployment dictionary from the Jetson to the host machine:

    ```bash
    scp <jetson-name>@<jetson-ip>:fprime-scales-ref/build-artifacts/aarch64-linux/JetsonDeployment/dict/JetsonDeploymentTopologyDictionary.json fprime-scales-ref/GDS-Dictionary/.
    ```

4. Combine the GDS dictionaries with the `merge-automate.sh` script:

    ```bash
    cd GDS-Dictionary
    ./merge-automate.sh
    ```

    This will generate `GDSDictionary.json`, which contains both the IMX and Jetson dictionaries merged into one file.

</details>

You are now ready to run the demo.

## Running the Demo

1. After you finish setting up the demo in the previous section, navigate to the `GDS-Dictionary` folder **on the host machine** and run the fprime-gds:

    ```bash
    ./run-gds.sh
    ```

2. **On the IMX**, the ImxDeployment binary should be running as a system service. You should see a green dot on the fprime-gds and `Accepted client` in the IMX terminal.

    If the system service is stopped for any reason, you can run:

    ```bash
    ./ImxDeployment -a 0.0.0.0 -p 50000
    ```

3. **On the Jetson**, navigate to the project root directory and run:

    ```bash
    make build-jetson
    ```

    This will restart the system service and run the deployment. Alternatively, if you have stopped the service for any reason, you can run the deployment from within `fprime-scales-ref` by first sourcing `fprime-venv`, then running:

    ```bash
    ./jetson-python.sh
    ```

    This command runs JetsonDeployment through its Python implementation and connects to the IMX's fprime-gds using the hub pattern. To exit the Python environment, press `Ctrl + C`.

4. **On the host machine**, use the fprime-gds to run `jetson_cmdDisp.CMD_NO_OP` to test the connection with the Jetson. Do the same for the IMX with `imx_cmdDisp.CMD_NO_OP`. You should see that both events completed in the **Events** tab of the GDS.

5. Once the camera is connected and the camera light is flashing green, run the `jetson_lucidCamera.SETUP_CAMERA` command to verify the connection through fprime.

6. To take a picture with the camera, run the `imx_cmdSeq.CS_RUN` command in the fprime-gds with the argument `demo.bin`. This will take a picture with the camera, downlink it to the IMX, and then downlink it again to the host machine. You can download the image from the **Downlink** tab in the GDS.

    This sequence will also run a ResNet ML model to identify what is in the image. The output will be displayed in the **Events** tab of the GDS. Images are deleted from the Jetson after the `demo.bin` sequence concludes. Repeat this step if you want to take more images.

    <div style="text-align: center;">
        <img src="docs/Images/run_seq.png" alt="fprime-gds sequence command" width="600" margin="center">
    </div>

    This sequence will trigger the images from the Jetson to be downlinked to the IMX, and then downlinked again from the IMX to the host machine. Check the **Downlink** tab in the GDS to see the images.

    <div style="text-align: center;">
        <img src="docs/Images/image_downlink.png" alt="Downlink view" width="600" margin="center">
    </div>

    Click the **Download** button in the **Downlink** tab of the fprime-gds to download the zipped image folder to the host machine. You can then unzip the folder and view the images from the Jetson.

### Alternative Commands

1. To send a batch of images from the Jetson to the host machine, run a sequence on the IMX using the `imx_cmdSeq.CS_RUN` command in the fprime-gds with the `fileName` argument `send.bin`. The command string is as follows:

    ```text
    imx_cmdSeq.CS_RUN, "send.bin", BLOCK
    ```

    <div style="text-align: center;">
        <img src="docs/Images/run_seq.png" alt="fprime-gds sequence command" width="600" margin="center">
    </div>

    This sequence will trigger the images from the Jetson to be zipped into a smaller file, downlinked to the IMX, and then downlinked again from the IMX to the host machine.

    <div style="text-align: center;">
        <img src="docs/Images/image_downlink.png" alt="Downlink view" width="600" margin="center">
    </div>

    Click the **Download** button in the **Downlink** tab of the fprime-gds to download the zipped image folder to the host machine. You can then unzip the folder and view the images from the Jetson.

2. To run ML on the images, run the `mlManager.SET_ML_PATH` command with the argument `resnet_inference`. Then, set the inference path to where the images are stored with the `mlManager.SET_INFERENCE_PATH` command using the argument `../Images`. Finally, run the ML model with the `mlManager.MULTI_INFERENCE` command. You should see the ML results in both the Jetson terminal and the Jetson fprime-gds **Events** log.

That's how to run the SCALES demo.

Watch our video demo on [YouTube](https://youtu.be/-g3Wv_fr9r8?si=2xow8_22aNjE1XDO)! Some minor changes have been implemented since the video was created, but the core process remains the same.

# To Run Scales-ML

[Scales-ML](https://github.com/BroncoSpace-Lab/Scales-ML/tree/e3aa59f606e9325cd198b787543cea0341d9a19a)

1. Follow the setup described in the previous sections for the IMX, Jetson, and host machine.

2. In the fprime-gds, run the `imx_cmdSeq.CS_RUN` command with the argument `test-resnet.bin`. This sequence will:

    - Set the ML path to a ResNet model.
    - Set the inference path to a folder called `test-imagery` with example images.
    - Execute the `MULTI_INFERENCE` command to run inference on all images in that folder.

# Running After Making Changes

If you make changes to ImxDeployment or JetsonDeployment, rebuild the respective deployment and repeat the steps to merge the dictionaries.

## Updates to JetsonDeployment

1. Rebuild JetsonDeployment. Run this on the Jetson:

    ```bash
    make build-jetson
    ```

2. Open another terminal on the host machine, enter the repository directory, and source your environment:

    ```bash
    cd fprime-scales-ref
    source fprime-venv/bin/activate
    ```

3. Copy the ImxDeployment dictionary to the `GDS-Dictionary` folder on the host machine:

    ```bash
    cp fprime-scales-ref/build-artifacts/imx8x/ImxDeployment/dict/ImxDeploymentTopologyDictionary.json fprime-scales-ref/GDS-Dictionary/.
    ```

4. Copy the JetsonDeployment dictionary from the Jetson to the host machine:

    ```bash
    scp <jetson-name>@<jetson-ip>:fprime-scales-ref/build-artifacts/aarch64-linux/JetsonDeployment/dict/JetsonDeploymentTopologyDictionary.json fprime-scales-ref/GDS-Dictionary/.
    ```

5. Combine the GDS dictionaries with the `merge-automate.sh` script:

    ```bash
    cd GDS-Dictionary
    ./merge-automate.sh
    ```

    This will generate `GDSDictionary.json`, which contains both the IMX and Jetson dictionaries merged into one file.

## Updates to ImxDeployment

1. Rebuild ImxDeployment:

    ```bash
    fprime-util build imx8x
    ```

2. Use the following command to SSH into the IMX:

    ```bash
    ssh root@<ip-of-imx>
    ```

3. Copy the ImxDeployment binary from the host machine to the IMX. Run this command on the host machine:

    ```bash
    scp fprime-scales-ref/build-artifacts/imx8x/ImxDeployment/bin/ImxDeployment root@<ip-of-imx>:/tmp/
    ```

    **On the IMX, from within `/root`:**

    ```bash
    mv /tmp/ImxDeployment .
    reboot now
    ```

4. Combine the GDS dictionaries with the `merge-automate.sh` script. Run this command on the host machine. If you also updated JetsonDeployment, make sure to follow the directions above before attempting this step:

    ```bash
    cd GDS-Dictionary
    ./merge-automate.sh
    ```

5. Connect to the fprime-gds.

    **On the host machine**, navigate to the `GDS-Dictionary` folder and run the fprime-gds:

    ```bash
    ./run-gds.sh
    ```

    **On the IMX**, run the ImxDeployment binary if the service is not already running. You should see a green dot on the fprime-gds and `Accepted client` in the IMX terminal.

    If the service is stopped or disabled, you can run ImxDeployment with:

    ```bash
    ./ImxDeployment -a 0.0.0.0 -p 50000
    ```

    **On the Jetson**, navigate to the `build-python-fprime-aarch64-linux` directory to run the fprime-gds using Python.

    If you have made changes to JetsonDeployment but have not stopped or disabled the system service, run:

    ```bash
    make build-jetson
    ```

    If you have disabled or stopped the system service, you will have to either re-enable it or run JetsonDeployment from `fprime-scales-ref` using:

    ```bash
    ./jetson-python.sh
    ```

# Troubleshooting

When trying to run the SCALES demo, you may encounter a few issues.

## Hanging/Crashing During Downlink

This can happen if there is an existing file on the IMX named `image.png` from a previous incomplete run of the demo. Delete the `image.png` file from the IMX with `rm image.png`, then try running the demo again.

This may also be due to an issue with the `Images/` folder on the Jetson. Return to step 4 in [Jetson Setup](#jetson-setup) to make sure the `Images/` folder is set up correctly.

## fprime-gds Crashes on Jetson When Trying to Connect

Instead of using the shortened command to connect to the GDS from the Jetson, try entering the Python environment first. Then, run `import python_extension` and `python_extension.main()` one at a time.

## Inferencing Error

When trying to run the `MULTI_INFERENCE` command on the Jetson, you may experience an error similar to:

```text
'(MaxRetryError("HTTPSConnectionPool(host='huggingface.co', port=443): Max retries exceeded with url: /microsoft/resnet-18/resolve/main/preprocessor_config.json (Caused by NewConnectionError('<urllib3.connection.HTTPSConnection object at 0xffff3bf23450>: Failed to establish a new connection: [Errno -3] Temporary failure in name resolution'))"), '(Request ID: 6d6a5cec-e762-484c-a97a-1e1d9748bcba)')' thrown while requesting HEAD https://huggingface.co/microsoft/resnet-18/resolve/main/preprocessor_config.json
```

Make sure the Jetson is connected to Wi-Fi and try again. This is a new issue we have encountered that we are still trying to find the root cause of, but a Wi-Fi connection fixes the issue.

---

This project was auto-generated by the F' utility tool.

F' is a component-driven framework that enables rapid development and deployment of spaceflight and other embedded software applications.

**Please visit the F' website:** https://fprime.jpl.nasa.gov.