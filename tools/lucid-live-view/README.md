# lucid-live-view

Live view of the LUCID GigE camera (testbench: PHX032S-C at 10.3.2.4) for
focusing the lens and framing objects for the ML demo.

The overlay shows:

- **SHARPNESS**, with the best value so far: turn the focus ring to maximize it.
- **A yellow box**: the central square ResNet-18 classifies (shorter side × 0.875).
- Frames per second and incomplete frames (lost GigE packets), plus brightness,
  exposure, gain and gamma.

Keys: `q`/`Esc` quit, `s` save a snapshot to `~/lucid-snapshots/`, `h` toggle
the overlay, `c` toggle the crop box.

## Setup (once per machine)

From the repo root, on the machine whose screen you'll watch (normally the
x86-64 ground PC on the 10.3.2.x network):

```bash
make camera-viewer-setup
```

This installs OpenCV (`libopencv-dev`) and build tools, installs the Arena SDK
if it's missing, and builds the viewer.

- **x86-64:** needs the Arena SDK for Linux x64. If
  `~/ArenaSDK-x64/ArenaSDK_Linux_x64` doesn't exist, it is extracted from
  `~/Downloads/ArenaSDK_*_Linux_x64.tar.gz` (download it from LUCID's Downloads
  Hub; it requires a LUCID login) and registered with the SDK's own
  `Arena_SDK_Linux_x64.conf`.
- **Jetson (aarch64):** uses the repo's ARM64 SDK (`lib/ArenaSDK`, from
  `make arena-init`).

## Run

```bash
make camera-view                 # read-only: changes no camera settings
make camera-view flight=1        # first apply F' SETUP_CAMERA image settings
make camera-view args=--help     # options
```

`flight=1` sets auto exposure and white balance, gamma 0.5 and target
brightness 50, so the view matches what the flight software captures for the
model. Without it you see the camera's current settings (gamma 1.0 after a
power cycle, which looks darker). Neither mode touches the camera's IP
configuration.

When launched over SSH with no display set, `make camera-view` targets the
desktop session on `:0`.

## Camera IP address (set it back to 10.3.2.4)

The flight software on the Jetson (10.3.2.13/24) expects the camera at
**10.3.2.4/24**. The testbench camera is a PHX032S-C, serial 222401887, MAC
`1c:0f:af:03:61:7e`.

Check the current address (read-only):

```bash
make camera-ip-show
# camera: PHX032S-C  serial 222401887  MAC 1c:0f:af:03:61:7e  IP 10.3.2.4/255.255.255.0  gw 0.0.0.0
```

If it shows anything else, typically a `169.254.x.x/255.255.0.0` address, set
it back, from the repo root on any machine on the 10.3.2.x network (the Jetson
or the ground PC):

```bash
make camera-set-ip                        # defaults: ip=10.3.2.4 mask=255.255.255.0 gateway=0.0.0.0
make camera-set-ip ip=10.3.2.4 serial=222401887   # explicit; serial needed if several cameras
```

This runs `tools/lucid-live-view/lucid_set_ip`, which follows LUCID's
`Cpp_ForceIp` and `Cpp_IpConfig_Manual` examples:

1. **Force IP** (temporary): puts the camera on 10.3.2.4/24 right away, even
   from a 169.254.x.x address on another subnet.
2. **Persistent IP**: writes `GevPersistentIPAddress=10.3.2.4`,
   `GevPersistentSubnetMask=255.255.255.0`, `GevPersistentDefaultGateway=0.0.0.0`,
   enables `GevCurrentIPConfigurationPersistentIP` and disables
   `GevCurrentIPConfigurationDHCP`, so the camera comes back on 10.3.2.4 after
   every restart.
3. Re-discovers the camera and prints the verified address.

It doesn't change ARP conflict detection or any image settings. Close the
viewer (and don't have F´ holding the camera) while running it. Afterwards
`make camera-view` and `jetson_lucidCamera.SETUP_CAMERA` both work again.

Why it happens: a GigE Vision camera without a persistent IP comes up on DHCP,
or, with no DHCP server (as on the 10.3.2.x bench network), on a self-assigned
169.254.x.x address after any restart: power or PoE glitch, cable re-plug or
link reset. Merely viewing or streaming (this viewer, ArenaView play) never
changes the IP; only Force IP and the IP configuration settings do. Once the
persistent IP is set (done on 2026-11-13), this shouldn't recur.

## Lots of INCOMPLETE frames?

At gigabit full duplex the camera streams about 33 fps with 0% incomplete
frames. If the overlay shows most frames incomplete at about 3 fps, the link has
dropped to 100 Mb/s half duplex. Check with
`cat /sys/class/net/<iface>/speed /sys/class/net/<iface>/duplex`.

On the testbench the cause was the bench switch (Microchip KSZ9896C): its
`LED2_1` strap DIP switch was ON, selecting "Fast Link-up" (no
auto-negotiation, forced 100BASE-TX). **All strap switches must be OFF**, then
reset the switch. Details are in the root README's troubleshooting section.

## Sharing the camera with the flight software

Only one program can control the camera at a time.

- Close the viewer before sending `jetson_lucidCamera.SETUP_CAMERA` or running
  `demo.bin`.
- If the flight software already holds the camera, the viewer says so. Release
  it with `sudo systemctl restart jetson-deployment` on the Jetson, and don't
  send `SETUP_CAMERA` until you're done viewing.
