# fprime-scales-ref F' project

Watch our video demo on [YouTube](https://youtu.be/-g3Wv_fr9r8?si=2xow8_22aNjE1XDO)!

Check out our [docs page](https://scales-docs.readthedocs.io/en/latest/)!

### Development Environment

May or may not be required, but this is what we found best to use for development:

- Ubuntu 22.04 host machine
- python3.11
- git lfs (install [here for amd64](https://git-lfs.com/) and [here for arm64](https://github.com/git-lfs/git-lfs/releases/download/v3.7.0/git-lfs-linux-arm64-v3.7.0.tar.gz))

## How to Clone

Use the commands below in terminal to clone and set up the repository. Make sure to source the fprime-venv before you continue developing! **Make sure you have [git lfs](https://git-lfs.com/) installed before proceeding.**

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

## How to Build JetsonDeployment

You must generate build JetsonDeployment on the Jetson, we have not set up cross-compilation for aarch64-linux yet.

**On the Jetson**, should be able to generate and build the JetsonDeployment with the commands below:

```
fprime-util generate aarch64-linux -f
make build-jetson
```

The `make build-jetson` command runs `fprime-util build aarch64-linux` and `scripts/jetson-python.sh`, which copies ML code into `build-python-fprime-aarch64-linux/` for F´ Python.

## ImxDeployment

To correctly generate and build for the IMX, you need to have the build environment on your machine. Refer to [this guide](https://scales-docs.readthedocs.io/en/latest/imx_yocto_bsp/#building-the-bsp) we made on our docs for how to set up the IMX SDK.

Generate and build the ImxDeployment on your host machine with the commands below:

```
fprime-util generate imx8x -f && fprime-util build imx8x -j20
```

# To Run the SCALES Demo

## IMX Setup

These steps are only required if there are changes made to ImxDeployment. Otherwise, the binary on the IMX should be fine.

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
    // const char* REMOTE_HUIP_ADDRESS = "10.3.2.5"; // ip of CPP IMX
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
4. Combine the GDS dictionaries with the `merger.py` script. Run this command on the host machine.
  ```
    cd GDS-Dictionary
    python merger.py JetsonDeploymentTopologyAppDictionary.xml ImxDeploymentTopologyAppDictionary.xml GDSDictionary.xml
  ```

You are now ready to run the demo!

## Running the Demo

1. After you finished setting up the demo in the previous section, **on the host machine**, navigate to the `GDS-Dictionary` folder and run the fprime-gds.
  ```
    fprime-gds -n --dictionary GDSDictionary.xml --ip-client --ip-address <ip of imx>
  ```
2. **On the IMX**, run the ImxDeployment binary. You should see a green dot on the fprime-gds and "Accepted client" in the IMX terminal.
  ```
    ./ImxDeployment -a 0.0.0.0 -p 50000
  ```
3. **On the Jetson**, start F´ Python:
  ```
    cd build-python-fprime-aarch64-linux
    python -c "import python_extension; python_extension.main()"
  ```
    To exit, use `exit()`.
4. **On the host machine**, use the fprime-gds to run the `jetson_cmdDisp.CMD_NO_OP` to test the connection with the Jetson. Do the same for the IMX with the `imx_cmdDisp.CMD_NO_OP`. You should be able to see that both events completed in the "Events" tab of the gds.
5. Once the camera is connected, run the `jetson_lucidCamera.SETUP_CAMERA` command to verify the connection via fprime.
6. To take a picture with the Ethernet Camera, run a sequence on the IMX using the `imx_cmdSeq.CS_RUN` command on the fprime-gds with fileName argument `snap-n-save.bin`. The Command String is as follows:
  ```
    imx_cmdSeq.CS_RUN, "snap-n-save.bin", BLOCK
  ```
    This sequence will trigger the Images from the Jetson to be downlinked to the IMX, and then again downlinked from the IMX to the Host Machine. Check the `Downlink` tab in the GDS to see the images.
    Click the `Download` button in the `Downlink` tab of the fprime-gds to download the zipped Image folder to the host machine. You can then unzip the folder and view the images from the Jetson!
7. If you would like to send a batch of images from the Jetson to the Host Machine, run a sequence on the IMX using the `imx_cmdSeq.CS_RUN` command on the fprime-gds with fileName argument `send.bin`. The Command String is as follows:
  ```
    imx_cmdSeq.CS_RUN, "send.bin", BLOCK
  ```
    This sequence will trigger the Images from the Jetson to be zipped into a smaller file to be downlinked to the IMX, and then again downlinked from the IMX to the Host Machine.
    Click the `Download` button in the `Downlink` tab of the fprime-gds to download the zipped Image folder to the host machine. You can then unzip the folder and view the images from the Jetson!
8. To run ML on saved images, see [Machine learning (Scales-ML)](#machine-learning-scales-ml) below.

That's how to run the SCALES demo!

Watch our video demo on [YouTube](https://youtu.be/-g3Wv_fr9r8?si=2xow8_22aNjE1XDO)! Some minor changes have been implemented since the creation of this video, but the core process remains the same.

## Machine learning (Scales-ML)

F´ runs inference with three commands (GDS or command sequence):

1. `jetson_mlManager.SET_ML_PATH` — Python module for the model (see table below)
2. `jetson_mlManager.SET_INFERENCE_PATH` — folder of `.jpg` / `.png` / `.jpeg` images (any path you choose; relative paths are resolved from `build-python-fprime-aarch64-linux`)
3. `jetson_mlManager.MULTI_INFERENCE` — run on all images in that folder

Results show up as `InferenceOutput` events in GDS and as an FPS line on the Jetson terminal (for accelerated paths).

### Models you can run from F´


| `SET_ML_PATH`               | Engine                          | One-time setup                   | FPS (10 images, test-imagery)   |
| --------------------------- | ------------------------------- | -------------------------------- | ------------------------------- |
| `resnet.inference.pytorch`  | Hugging Face ResNet (F´ Python) | None                             | ~1–3 FPS                        |
| `resnet.inference.tensorrt` | TensorRT                        | `MODEL=resnet make ml-trt-setup` | ~20 FPS                         |
| `yolo.inference.pytorch`    | Ultralytics (JetPack Python)    | None                             | ~2.3 FPS                        |
| `yolo.inference.tensorrt`   | TensorRT                        | `MODEL=yolo make ml-trt-setup`   | device-dependent (often ≥4 FPS) |


FPS numbers are from Jetson runs on this repo’s sample folder; yours may differ.

TensorRT paths use **subprocess** inference in JetPack Python so F´ does not need TensorRT in the embedded venv.

### TensorRT setup (`make ml-trt-setup`)

Run **on the Jetson**, from the repo root, **once per model** (or after changing weights / ONNX). This exports ONNX, builds a TensorRT engine.

**ResNet:**

```bash
MODEL=resnet make ml-trt-setup
```

**YOLO** (first run may download `yolov8n.pt`; engine build often takes **10–30+ minutes**):

```bash
MODEL=yolo make ml-trt-setup
```

### Run inference from GDS

With the demo running and Jetson F´ Python connected:

```text
jetson_mlManager.SET_ML_PATH "yolo.inference.tensorrt"
jetson_mlManager.SET_INFERENCE_PATH "../test-imagery"
jetson_mlManager.MULTI_INFERENCE
```

To add a new model, see the [Scales-ML](https://github.com/BroncoSpace-Lab/Scales-ML) README.

---

This project was auto-generated by the F' utility tool. 

F´ (F Prime) is a component-driven framework that enables rapid development and deployment of spaceflight and other embedded software applications.
**Please Visit the F´ Website:** [https://fprime.jpl.nasa.gov](https://fprime.jpl.nasa.gov).