# Verilog Source Files

This directory contains the core Verilog modules for the Basys 3 OV7670 video pipeline.

## 📄 Module Overview

| File | Description | State Machine |
| :--- | :--- | :--- |
| **`topModule.v`** | System top-level integration. | Power-on Reset Counter |
| **`cameraConfig.v`** | Camera register sequencer. | 4-state ROM sequencer |
| **`cameraCapture.v`** | Pixel reconstruction logic. | Sync-based byte toggle |
| **`vgaController.v`** | VGA timing & BRAM interface. | Synchronous counters |
| **`filter.v`** | Real-time image processing. | Combinational |
| **`sccbMaster.v`** | Bit-banged SCCB protocol. | 10-state I2C master |
| **`pulseSync.v`** | Clock Domain Crossing (CDC). | 3-state handshake |

---

## 🕹️ State Machines

### 1. Camera Configuration (`cameraConfig.v`)
This FSM iterates through the ROM and triggers SCCB transactions for each register.
```mermaid
stateDiagram-v2
    [*] --> RESET_WAIT : Power-on / Reset
    RESET_WAIT --> START : Wait Counter Expired
    START --> WAIT_DONE : sccbStart = 1
    START --> DONE : End of ROM (0xFFFF)
    WAIT_DONE --> RESET_WAIT : sccbDone = 1
    DONE --> DONE : Sequence Complete
```

### 2. SCCB Master (`sccbMaster.v`)
A detailed 10-state FSM that handles the bit-level timing of the SCCB protocol.
```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> START : start == 1
    START --> ID : Transmit Device ID
    ID --> DC_ID : 8 bits sent
    DC_ID --> REG : Transmit Address
    REG --> DC_REG : 8 bits sent
    DC_REG --> DATA : Transmit Data
    DATA --> DC_DATA : 8 bits sent
    DC_DATA --> STOP : Phase 3
    STOP --> DONE : Transaction Finished
    DONE --> IDLE
```

### 3. Camera Capture Logic (`cameraCapture.v`)
While primarily driven by control signals, it uses a toggle state to handle the two-byte pixel format.
```mermaid
stateDiagram-v2
    [*] --> VSYNC_RESET : cameraVs == 1
    VSYNC_RESET --> WAIT_HREF : cameraVs == 0
    WAIT_HREF --> CAPTURE_FIRST : cameraHs == 1
    CAPTURE_FIRST --> CAPTURE_SECOND : byteCount == 0 -> 1
    CAPTURE_SECOND --> WAIT_HREF : Write to BRAM (byteCount == 1 -> 0)
    WAIT_HREF --> VSYNC_RESET : cameraVs == 1
```

---

## 🏗 System Integration
The design uses a dual-port **Block RAM (BRAM)** as a frame buffer to decouple the camera's write clock (`pClk`) from the VGA's read clock (`vgaClk`).
