# Hub Deployment Architecture

This document explains how the current i.MX + Jetson hub deployment is designed, how files move from the Jetson to the i.MX, how the i.MX saves those files locally, and how the i.MX later downlinks them to the GDS.

## Overview

The system has three major communication paths:

```text
1. Jetson -> i.MX over the hub
2. i.MX -> Jetson over the hub
3. i.MX -> GDS over the direct GDS communication stack
```

The important design choice is that the Jetson and i.MX do not exchange large files through the normal GDS-facing communication stack. Instead, Jetson file packets are sent through the `GenericHub` path and received by i.MX `FileUplink`, which reconstructs and saves the file locally on the i.MX filesystem.

After the file exists locally on the i.MX, the i.MX can downlink that saved file to the GDS using its own local `FileDownlink` service.

## High-Level Data Flow

The intended large-image path is:

```text
Image on Jetson
  -> Jetson FileDownlink
  -> Jetson GenericHub channel 0
  -> Jetson HubComAdapter
  -> Jetson FprimeFramer
  -> Jetson TCP hub driver
  -> i.MX TCP hub driver
  -> i.MX FrameAccumulator
  -> i.MX FprimeDeframer
  -> i.MX HubComAdapter
  -> i.MX GenericHub channel 0
  -> i.MX FileUplink
  -> file saved locally on i.MX
```

Then, separately:

```text
Saved file on i.MX
  -> i.MX FileDownlink
  -> i.MX ComFprime
  -> i.MX TCP GDS driver
  -> GDS
```

This two-step design prevents the i.MX-to-GDS path from being overwhelmed while the Jetson is still sending the file.

## Why the Hub Exists

The Jetson and i.MX are separate F Prime deployments. A normal F Prime port connection only exists inside one deployment, so direct component-to-component connections cannot cross the physical boundary between the Jetson process and the i.MX process.

`Svc.GenericHub` solves this by allowing logical F Prime port traffic to cross a physical transport.

In this deployment, the hub lets the Jetson send:

- file packets,
- command responses,
- power state data,
- power mode data,
- events,
- telemetry,

to the i.MX as if they were connected through normal F Prime ports.

## Why the Hub Uses F Prime Framing

The hub runs over TCP.

TCP is reliable and ordered, but it is a byte stream. That means one TCP read does not necessarily equal one hub message. TCP can split one hub record across multiple reads, or combine multiple hub records into one read.

Because of that, the hub transport uses F Prime framing:

```text
GenericHub
  -> HubComAdapter
  -> FprimeFramer
  -> ComStub
  -> TCP driver
```

On receive, the inverse happens:

```text
TCP driver
  -> ComStub
  -> FrameAccumulator
  -> FprimeDeframer
  -> HubComAdapter
  -> GenericHub
```

The `FprimeFramer` adds a frame boundary around each hub record. The `FrameAccumulator` rebuilds complete frames from the TCP byte stream. The `FprimeDeframer` removes the frame wrapper and recovers the original hub record.

## Major Hub Components

### `Svc.GenericHub`

`GenericHub` is the logical bridge between local F Prime ports and the physical hub transport.

It has typed logical ports such as:

```text
serialIn / serialOut
bufferIn / bufferOut
cmdDispIn / cmdDispOut
cmdRespIn / cmdRespOut
```

These allow different kinds of F Prime traffic to cross between deployments.

In this system, the important file channels are:

```text
buffer channel 0: Jetson file packets -> i.MX FileUplink
buffer channel 1: i.MX/GDS file uplink packets -> Jetson FileUplink
```

### `HubComAdapter`

`HubComAdapter` converts between `GenericHub` buffer-driver records and the `Svc.Com` style data interface used by `FprimeFramer`, `FprimeDeframer`, and `ComStub`.

It is the adapter that lets hub records travel through the standard framed communication pipeline.

### `Svc.FprimeFramer`

`FprimeFramer` wraps each outgoing hub record in a F Prime frame.

This is required because the hub uses TCP, and TCP does not preserve message boundaries.

### `Svc.FrameAccumulator`

`FrameAccumulator` collects bytes received from TCP until it has a complete F Prime frame.

Without this, the receiver could try to interpret partial TCP reads as complete hub messages.

### `Svc.FprimeDeframer`

`FprimeDeframer` removes the F Prime frame wrapper and emits the original payload.

In this architecture, that payload is a serialized hub record.

### `Svc.ComStub`

`ComStub` adapts the F Prime `Svc.Com` data interface to the byte-stream driver interface.

It sits between the framer/deframer path and the TCP driver.

### TCP Drivers

The hub transport uses TCP.

The i.MX side is the hub TCP server:

```text
imx_hubComDriver: Drv.TcpServer
```

The Jetson side is the hub TCP client:

```text
jetson_hubComDriver: Drv.TcpClient
```

This means the i.MX must be listening before the Jetson starts sending hub traffic.

## Jetson to i.MX File Transfer

A Jetson image starts as a local file on the Jetson, for example:

```text
Images/hubble.jpg
```

When `FileHandling.fileDownlink.SendFile` is run on the Jetson, `FileDownlink` packetizes the file into F Prime file packets.

The Jetson topology connects those packets to the hub:

```fpp
FileHandling.fileDownlink.bufferSendOut -> jetson_hub.bufferIn[0]
jetson_hub.bufferInReturn[0] -> FileHandling.fileDownlink.bufferReturn
```

This means Jetson file packets do not go through the Jetson `ComCcsds` stack for the hub transfer. They go directly into hub buffer channel 0.

On the i.MX side, hub channel 0 is connected to `FileUplink`:

```fpp
imx_hub.bufferOut[0] -> FileHandling.fileUplink.bufferSendIn
FileHandling.fileUplink.bufferSendOut -> imx_hub.bufferOutReturn[0]
```

`FileUplink` receives the file packets, reconstructs the file, validates it, and writes it to the i.MX filesystem.

## Why i.MX `fileUplink` Queue Size Is Large

`FileUplink.bufferSendIn` is an async input port. Incoming file packets are queued before the `FileUplink` component processes them.

Large images can produce tens of thousands of packets. For example, a roughly 19 MB image can produce around 38,000 file packets.

If the i.MX `FileUplink` queue is too small, it fills and causes an assert like:

```text
Assert in FileUplinkComponentAc.cpp, line 690: 8
```

The `8` corresponds to the queue status `FULL`.

For that reason, the i.MX `FileHandlingConfig` uses a large `fileUplink` queue:

```fpp
module QueueSizes {
    constant fileUplink = 50000
    constant fileDownlink = 10
    constant fileManager = 10
    constant prmDb = 10
}
```

This queue is specifically for the Jetson -> hub -> i.MX `FileUplink` path. It is not a CCSDS tuning value.

## i.MX Local File Save

The Jetson file is saved by i.MX `FileUplink`.

Once the transfer completes successfully, the file exists locally on the i.MX using the destination filename supplied by the Jetson `SendFile` command.

For example, if the Jetson command is:

```text
SendFile source: Images/hubble.jpg
SendFile destination: hubble.jpg
```

then the i.MX `FileUplink` reconstructs and saves:

```text
hubble.jpg
```

on the i.MX filesystem, relative to the i.MX deployment's working directory unless an absolute destination path is used.

## i.MX to GDS File Downlink

After the file exists locally on the i.MX, the i.MX can downlink it to the GDS.

This is a separate operation from the Jetson -> i.MX transfer.

The topology connects i.MX `FileDownlink` to `ComFprime`:

```fpp
FileHandling.fileDownlink.bufferSendOut -> ComFprime.comQueue.bufferQueueIn[ComFprime.Ports_ComBufferQueue.FILE]
ComFprime.comQueue.bufferReturnOut[ComFprime.Ports_ComBufferQueue.FILE] -> FileHandling.fileDownlink.bufferReturn
```

Then `ComFprime` sends the file packets through the direct i.MX GDS TCP driver:

```fpp
ComFprime.comStub.drvSendOut -> imx_comDriver.$send
imx_comDriver.$recv -> ComFprime.comStub.drvReceiveIn
```

The GDS-facing path is:

```text
i.MX FileDownlink
  -> ComFprime ComQueue
  -> FprimeFramer
  -> ComStub
  -> i.MX TCP GDS driver
  -> GDS
```

## Why i.MX Uses `ComFprime` Instead of `ComCcsds`

The older working deployment used plain F Prime framing for i.MX -> GDS file downlink.

The current i.MX GDS path uses `ComFprime` to match that behavior.

This avoids the CCSDS aggregation/TM-frame path, which was causing partial downlinks or confusing GDS completion behavior for large files.

The i.MX imports:

```fpp
import ComFprime.Subtopology
```

The GDS script should use F Prime framing:

```bash
fprime-gds -n \
  --dictionary "${DICTIONARY}" \
  --communication-selection ip \
  --framing-selection fprime \
  --ip-client \
  --ip-address "${IP_ADDRESS}" \
  --ip-port "${IP_PORT}" \
  --keepalive-interval 0
```

If the installed GDS does not recognize `--framing-selection fprime`, remove that option or check:

```bash
fprime-gds --help
```

for the exact F Prime framing option name.

## Why the Jetson Can Still Use `ComCcsds`

The Jetson can still import and use `ComCcsds` because the Jetson's GDS-facing communication stack is separate from the Jetson -> i.MX hub path.

The Jetson -> i.MX file path does not use Jetson `ComCcsds`.

It uses:

```text
Jetson FileDownlink -> Jetson GenericHub -> Hub transport -> i.MX GenericHub -> i.MX FileUplink
```

So the Jetson can keep `ComCcsds` for direct Jetson GDS testing or other local communication behavior, while the hub file transfer uses the hub's own F Prime framed TCP transport.

## Event and Telemetry Forwarding

Jetson events and telemetry are forwarded over the hub to the i.MX.

On the Jetson side:

```fpp
CdhCore.events.PktSend -> jetson_hub.serialIn[2]
CdhCore.tlmSend.PktSend -> jetson_hub.serialIn[3]
```

On the i.MX side:

```fpp
imx_hub.serialOut[2] -> ComFprime.comQueue.comPacketQueueIn[ComFprime.Ports_ComPacketQueue.EVENTS]
imx_hub.serialOut[3] -> ComFprime.comQueue.comPacketQueueIn[ComFprime.Ports_ComPacketQueue.TELEMETRY]
```

This allows Jetson events and telemetry to appear in the host GDS through the i.MX connection.

## Command Forwarding

The i.MX receives commands from the GDS through `ComFprime`.

Commands are routed through a command splitter:

```text
ComFprime.fprimeRouter.commandOut
  -> imx_cmdSplitter
```

Local i.MX commands are dispatched on the i.MX.

Remote Jetson commands are sent through the hub:

```fpp
imx_cmdSplitter.RemoteCmd[0] -> imx_hub.cmdDispIn[0]
imx_hub.cmdRespOut[0] -> imx_cmdSplitter.seqCmdStatus[0]
```

On the Jetson side, the hub emits those commands:

```fpp
jetson_hub.cmdDispOut[0] -> jetson_proxyGroundInterface.seqCmdBuf
jetson_proxyGroundInterface.comCmdOut -> CdhCore.cmdDisp.seqCmdBuff[2]
CdhCore.cmdDisp.seqCmdStatus[2] -> jetson_proxyGroundInterface.cmdResponseIn
jetson_proxyGroundInterface.seqCmdStatus -> jetson_hub.cmdRespIn[0]
```

This allows the GDS to command both deployments through the i.MX connection.

## File Uplink From GDS to Jetson

The reverse file direction is also supported.

GDS file uplink packets arrive at i.MX through `ComFprime.fprimeRouter.fileOut`.

The i.MX forwards those packets through hub buffer channel 1:

```fpp
ComFprime.fprimeRouter.fileOut -> imx_hub.bufferIn[1]
imx_hub.bufferInReturn[1] -> ComFprime.fprimeRouter.fileBufferReturnIn
```

On the Jetson side, hub channel 1 connects to Jetson `FileUplink`:

```fpp
jetson_hub.bufferOut[1] -> FileHandling.fileUplink.bufferSendIn
FileHandling.fileUplink.bufferSendOut -> jetson_hub.bufferOutReturn[1]
```

So channel 1 is the i.MX/GDS -> Jetson file uplink path.

## Hub Buffer Managers

Each side has two hub-related buffer managers.

### Hub retained-record buffer manager

This buffer manager stores complete deframed hub records that may be retained by downstream components.

On i.MX:

```text
imx_hubBufferManager
```

On Jetson:

```text
jetson_hubBufferManager
```

These are connected to `GenericHub` allocation/deallocation and to `FrameAccumulator` output buffers.

### Hub I/O buffer manager

This buffer manager stores buffers used on the framed TCP transport side.

On i.MX:

```text
imx_hubIoBufferManager
```

On Jetson:

```text
jetson_hubIoBufferManager
```

These are used by the TCP driver and by `FprimeFramer` output buffers.

## GDS Dictionary Merging

The system uses a merged dictionary so the GDS can understand commands, events, telemetry, and file services from both deployments.

Because both deployments use shared subtopologies, dictionary names are prefixed during merge.

The merger prefixes shared subtopology names such as:

```text
CdhCore.
ComCcsds.
ComFprime.
DataProducts.
FileHandling.
```

This prevents the GDS display from confusing similarly named shared components.

For example:

```text
jetson_ComCcsds...
imx_ComFprime...
jetson_FileHandling...
imx_FileHandling...
```

The runtime IDs are separated by deployment-specific base ID ranges, so the merged dictionary should not conflict as long as each deployment keeps its assigned ID ranges.

## Important Configuration Values

### i.MX FileUplink queue

This must be large enough for large Jetson -> i.MX file transfers:

```fpp
module QueueSizes {
    constant fileUplink = 50000
}
```

This prevents `FileUplink` queue-full asserts during large image transfer.

### i.MX ComFprime

The i.MX GDS-facing stack uses normal F Prime framing:

```fpp
module ComFprimeConfig {
    constant BASE_ID = 0x02000000
}
```

The normal default-sized ComFprime buffers are used. The large CCSDS packet-buffer tuning is not needed.

### Jetson FileHandling

Jetson `FileDownlink` can remain at default queue sizes unless Jetson-side queue asserts occur.

The Jetson file transfer to i.MX is throttled by the hub and return path, but the i.MX receiving side needs the larger `fileUplink` queue because it is the burst sink.

## Common Failure Modes

### i.MX `FileUplinkComponentAc.cpp` assert with `: 8`

Example:

```text
Assert in FileUplinkComponentAc.cpp, line 690: 8
```

Meaning:

```text
FileUplink async queue full
```

Fix:

```fpp
constant fileUplink = 50000
```

in the i.MX `FileHandlingConfig`.

### `NoBuffsAvail` from hub buffer managers

This means one of the hub buffer pools is exhausted.

Check whether the event comes from:

```text
imx_hubBufferManager
imx_hubIoBufferManager
jetson_hubBufferManager
jetson_hubIoBufferManager
```

The source tells you which side and which pool is starved.

### Partial i.MX -> GDS file downlink

If a file saves correctly on the i.MX but only partially downlinks to GDS, check that the i.MX GDS path is using `ComFprime`, not `ComCcsds`, and that the GDS launch script is not forcing CCSDS framing.

Bad for this design:

```bash
--framing-selection space-packet-space-data-link
--scid ...
--vcid ...
--frame-size ...
```

Expected:

```bash
--framing-selection fprime
```

or the GDS default F Prime framing mode.

## Final Architecture Summary

The final architecture is:

```text
Jetson image creation
  -> Jetson FileDownlink
  -> Hub buffer channel 0
  -> F Prime framed TCP hub transport
  -> i.MX hub buffer channel 0
  -> i.MX FileUplink
  -> local i.MX file save
  -> i.MX FileDownlink command
  -> i.MX ComFprime
  -> GDS
```

The hub is responsible for deployment-to-deployment movement.

`FileUplink` on the i.MX is responsible for reconstructing and saving the Jetson file locally.

`ComFprime` on the i.MX is responsible for the final GDS downlink.

The Jetson may still use `ComCcsds` for its own direct comm stack, but that stack is not part of the Jetson -> i.MX large-file transfer path.
