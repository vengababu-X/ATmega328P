
# ATmega328P Custom Core (Verilog HDL) & 28nm ASIC Tape-Out

## 📌 Overview
This project is an advanced, modular subset of the ATmega328P Microcontroller designed entirely in Verilog HDL. Engineered on a strict Harvard Architecture, this core separates program instruction memory (ROM) from data memory/peripherals to achieve single-cycle execution efficiency.

## 🏗️ Architectural Block Diagram
```text
                     +---------------------------------------------+
                     | ATmega328P TOP                              |
 [CLK] >-----------+--> [   AVR CPU CORE   ]                     |
 [RST] >-----------+--> | - ALU / Control  |                     |
                        | - 32x8 Registers | <-> [PROG_ROM]      |
 [IRQ_TIMER] >--------+--> | - PC & IRQ Logic |     (128x16-bit)  |
                        +-------+----------+                     |
                                | Internal Bus (Data/Addr/WE)    |
                        +-------v----------+                     |
                        | MEMORY DECODER   |                     |
                        +-------+----------+                     |
                        |       |          |                     |
 [GPIO] [UART] [TIMER]  |       |          |                     |
 +------|-------|-------+-------+----------+---------------------+
        |       |
     [PORTB]  [TX]

```
## 🔌 Pin-to-Pin Specification
| Pin Name | Direction | Width | Description |
|---|---|---|---|
| clk | Input | 1-bit | System Clock (50MHz). |
| reset | Input | 1-bit | Active-High Asynchronous Reset. |
| irq_timer | Input | 1-bit | Hardware Interrupt Request (Vector 0x0001). |
| portb_pins | Output | 8-bit | Memory-mapped GPIO outputs. |
| uart_tx_pin | Output | 1-bit | Serial TX transmission line. |
## 🧠 Execution Engine & ISA
 * **Registers:** 32 x 8-bit General Purpose Working Registers (R0 - R31).
 * **Program Counter:** 16-bit wide, natively addressing up to 64KB.
 * **ISA Summary:**
   * **LDI (0x1):** Load Immediate constant into register.
   * **OUT (0x2):** Write register to I/O peripheral.
   * **LSL (0x4):** Logical Shift Left (bit-wise).
   * **CPI (0x9):** Compare register with constant (sets Zero Flag Z).
   * **BRNE (0xA):** Branch if Not Equal (Sign-extended relative jump).
   * **RJMP (0xC):** Unconditional relative jump.
## 🔬 Simulation & Visual Testbench
The testbench acts as a logic analyzer rendering real-time, cycle-by-cycle pin changes.
```bash
# Compile and Simulate
iverilog -o simulation.vvp *.v
vvp simulation.vvp

```
*Expected Output:*
```text
⏱️ Time: 30000 ns | 🖥️ PC: 04 | 💡 LEDs: [. . . . . . . O]
⏱️ Time: 40000 ns | 🖥️ PC: 05 | 💡 LEDs: [. . . . . . O .]

```
## ⚙️ ASIC Tape-Out & CI/CD Pipeline
 * **Status:** GOLDEN TAPE-OUT APPROVED.
 * **Fabrication Process:** 28nm Virtual CMOS.
 * **Verification:** Full-scale simulation testbench passed via G-CORE X1 VLSI suite.
 * **Pipeline:** Integrated GitHub Actions for automated validation and OpenLane ASIC flow for physical design synthesis.
## 📂 Project Structure
```text
/
├── rtl/                # Verilog source files (Core, ALU, Register File)
├── sim/                # Simulation testbenches and G-CORE X1 scripts
├── doc/                # Architecture design and technical specs
├── synth/              # Synthesis scripts and 28nm reports
└── README.md           # Project documentation

```
## 📄 License
This project is licensed under the MIT License.
```

```
