# Libraries

To update the submodules, run the following command in the `fprime-scales-ref/lib` folder. This process is also included in the root README.

```
git submodule init && git submodule update
```

## ArenaSDK

Libraries from the Arena SDK provided by LUCID Vision Labs to use the ethernet camera in the initial SCALES demo. There is also a tarball to extract the correct version of the ArenaSDK.

### How to Set Up ArenaSDK

In `lib/ArenaSDK` there is a file called `ArenaSDK_v0.1.77_Linux_ARM64.tar.xz`. Use the following commands to extract the tarball and move the required folders to the correct directory.

```
cd lib/ArenaSDK
tar -xvf ArenaSDK_v0.1.77_Linux_ARM64.tar.xz
```

This will create a folder called `ArenaSDK_v0.1.77_Linux_ARM64`. In that folder, there is another folder called `ArenaSDK_Linux_ARM64`. In this folder, there are many folders and files that must be copied to `lib/ArenaSDK` to have the correct file paths for the CMakeLists. 

```
cd ArenaSDK_v0.1.77_Linux_ARM64/ArenaSDK_Linux_ARM64
cp -r * ~/fprime-scales-ref/lib/ArenaSDK/
```

These commands will copy over all files and folders from `ArenaSDK_v0.1.77_Linux_ARM64/ArenaSDK_Linux_ARM64` to `/lib/ArenaSDk`. Now we have the option of deleting the extracted file folder.

```
cd ../..
rm -rf ArenaSDK_v0.1.77_Linux_ARM64
```

## fprime

Git submodule of NASA JPL's fprime repository. Currently in v3.6.3 but will be updated to 4.0 soon.

## fprime-python

Git submodule of NASA JPL's fprime-python repository. The branch and commit used here have been updated by members of the SCALES team. This library is required to run JetsonDeployment.

Make sure `fprime-python` is on the `main` branch.

## fprime-scales

Git submodule of Bronco Space's fprime-scales repository. This repo is meant to contain the core fprime components required to make SCALES functional, mainly hardware managers and cmake toolchains. This library is required to run ImxDeployment.
