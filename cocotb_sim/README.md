# Cocotb Simulation Environment

This directory contains the Python-based verification suite for the project.

## 🚀 Quick Start

To run all tests:
```bash
./run_tests.sh
```

## 📂 Testbench Structure

Each subdirectory corresponds to a Verilog module and contains:
- **`testbench.py`**: The Cocotb test logic.
- **`Makefile`**: Configures the simulator (Icarus Verilog) and modules.
- **`waves.vcd`**: Generated after running a test for waveform viewing.

| Directory | Purpose |
| :--- | :--- |
| `cameraCapture` | Verifies pixel reconstruction from camera timing signals. |
| `cameraConfig` | Checks that the SCCB state machine writes the correct ROM values. |
| `filter` | Tests individual image processing algorithms (inverse, grayscale, etc.). |
| `topModule` | Integration test verifying the data path from camera input to VGA output. |

## 🛠 Prerequisites
- **Icarus Verilog**: Hardware simulator.
- **Cocotb**: Python verification framework.
- **GTKWave**: For visualizing `.vcd` files.

## 📝 Configuration
Global simulation settings (like timescale and common stubs) are managed in `Makefile.common` and `sim_stubs.v`.
