# JetsonFileHandling Subtopology — Software Design Document (SDD)

The **JetsonFileHandling subtopology** packages the core file-transfer services commonly needed in F´ deployments: **file uplink** (ground → flight), **file downlink** (flight → ground), **on-board file management**, and parameter management via filesystem. By providing these as a pre-wired subgraph, integration engineers avoid repetitive wiring and get a consistent, reusable baseline for file operations.

## 1. Requirements

| ID                   | Description                                                                                                     | Validation |
| -------------------- | --------------------------------------------------------------------------------------------------------------- | ---------- |
| SVC-JETSONFILEHANDLING-001 | The subtopology shall provide **file uplink functionality** to receive and reconstruct files from ground.       | Inspection |
| SVC-JETSONFILEHANDLING-002 | The subtopology shall provide **file downlink functionality** to segment and transmit files to ground.          | Inspection |
| SVC-JETSONFILEHANDLING-003 | The subtopology shall provide **on-board file management functionality** (e.g., list, remove, hash, mkdir).     | Inspection |
| SVC-JETSONFILEHANDLING-004 | The subtopology shall provide **parameter management** via the filesystem.                                      | Inspection |
| SVC-JETSONFILEHANDLING-005 | The subtopology shall support **configurable instance properties** (IDs, queue sizes, stack sizes, priorities). | Inspection |
| SVC-JETSONFILEHANDLING-006 | The subtopology shall expose **rate-group connection points** for any rate-drive components it contains.        | Inspection |


## 2. Design & Core Functions

### 2.1 Instance Summary

| Instance name  | Type (Svc)     | Kind   | Purpose (core function)                                 |
| -------------- | -------------- | ------ | ------------------------------------------------------- |
| `fileUplink`   | `FileUplink`   | Active | Ingest deframed file packets; reconstruct files.        |
| `fileDownlink` | `FileDownlink` | Active | Read files; segment into packets for downlink.          |
| `fileManager`  | `FileManager`  | Active | Local file operations.                                  |
| `prmDb`        | `PrmDb`        | Active | Filesystem based parameter management.                  |

### 2.2 Configuration Hooks inside the Subtopology

* Uses **instance properties** (IDs, queue sizes, stack sizes, priorities) defined in `JetsonFileHandlingConfig` for these static instances (see §4).

### 2.3 Required Inputs for Operation

* **Rate Groups**: Connect scheduler outputs to the **Run** (scheduling) ports of `fileDownlink`.
* **Communication/Framing Stack**: Wire file-packet ports between JetsonFileHandling and your COM/framing subtopology (e.g., `ComCcsds`, `ComFprime`, `FramingFprime`, `FramingCcsds`) to complete uplink/downlink paths.

### 2.4 Limitations

Focused on **file transfer and on-board file ops** only. It does **not** provide general uplink/downlink routing for non-file traffic, framing/deframing for non-file data, or broader CDH services.

## 3. Usage

### 3.1 Example Usage

```fpp
topology Flight {
  instance JetsonFileHandling.Subtopology

  param connections instance JetsonFileHandling.prmDb

  # Schedule the active/queued file components (example)
  connections RateGroups {
    rg.RateGroupMemberOut[0] -> JetsonFileHandling.Subtopology.fileDownlinkRun
  }

  connections ComCcsds_JetsonFileHandling {
    # File Downlink <-> ComQueue
    JetsonFileHandling.Subtopology.fileDownlinkBufferSendOut -> ComCcsds.Subtopology.bufferQueueIn[ComCcsds.Ports_ComBufferQueue.FILE]
    ComCcsds.Subtopology.bufferReturnOut[ComCcsds.Ports_ComBufferQueue.FILE] -> JetsonFileHandling.Subtopology.fileDownlinkBufferReturn
    
    # Router <-> FileUplink
    ComCcsds.Subtopology.fileUplinkOut                    -> JetsonFileHandling.Subtopology.fileUplinkBufferSendIn
    JetsonFileHandling.Subtopology.fileUplinkBufferSendOut     -> ComCcsds.Subtopology.fileUplinkReturnIn
  }
```

## 4. Configuration

> Configure **only the instance properties** for the static instances owned by the subtopology. All knobs live under:
> `Svc/Subtopologies/JetsonFileHandling/JetsonFileHandlingConfig/JetsonFileHandlingConfig.fpp`. The generated constants header for this module (e.g., `FppConstantsAc.hpp`) reflects these settings. ([FPrime][2])

### 4.1 Component properties (`JetsonFileHandlingConfig.fpp`)

* **Base ID** — Base identifier for the subtopology; component IDs are offset from this base.
* **Queue sizes** — Queue depths for `fileUplink`, `fileDownlink`, `fileManager`.
* **Stack sizes** — Task stacks for active components (`fileUplink`, `fileDownlink`).
* **Priorities** — RTOS priorities for the active/queued components as applicable.

> These knobs tailor runtime footprint and scheduling without modifying the subtopology wiring.

---

## 5. Traceability Matrix

| Requirement ID       | Satisfied by                               |
| -------------------- | ------------------------------------------ |
| SVC-JETSONFILEHANDLING-001 | `fileUplink` — `Svc.FileUplink`            |
| SVC-JETSONFILEHANDLING-002 | `fileDownlink` — `Svc.FileDownlink`        |
| SVC-JETSONFILEHANDLING-003 | `fileManager` — `Svc.FileManager`          |
| SVC-JETSONFILEHANDLING-004 | `prmDb` — `Svc.PrmDb`                      |
| SVC-JETSONFILEHANDLING-005 | `JetsonFileHandlingConfig` (instance properties) |
| SVC-JETSONFILEHANDLING-006 | Run/scheduling connection specifiers       |
