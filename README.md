# 🚀 ATmega328P Custom Core (Verilog HDL)
## 📌 Overview
This project is a custom-designed, modular subset of the **ATmega328P Microcontroller** written entirely in Verilog HDL. Designed from the ground up to operate on a standard **Harvard Architecture**, this core separates program memory (ROM) from data memory/peripherals, allowing simultaneous instruction fetching and data access.
Currently, the core implements a foundational subset of the AVR Instruction Set Architecture (ISA), capable of memory-mapped I/O, bitwise shifting, conditional branching, and handling external hardware interrupts.
## 🏗️ Architectural Block Diagram
```text
                     +----------------------------------+

| ATmega328P TOP |
| :--- | <br> [CLK] >-----------+--> [ AVR CPU CORE ]              | <br> [RST] >-----------+--> | - ALU        |              |
|  | - 32x8 Regs | <-> [PROG_ROM] (Instruction Memory)
|  | - PC Logic |  |
| +-------+------+ |
|  | Internal Bus |
| +-------v------+ |
|  | MEMORY DECODER |  |
| +-------+------+ |
| :--- | :--- | :--- | :--- |
| [GPIO] [UART] [TIMER] | <br> +------|-----|---------------------+
| :--- |

                         [PORTB] [TX]
```
## 🔌 Pin-to-Pin Specification
The top-level wrapper (atmega328p_top.v) exposes the following physical pins for integration into higher-level SOCs or FPGA mapping:

| Pin Name | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| clk | Input | 1-bit | System Clock (Designed for 50MHz synchronous operation). |
| reset | Input | 1-bit | Active-High Asynchronous Reset. Initializes PC and registers. |
| portb_pins | Output | 8-bit | Memory-mapped GPIO outputs simulating PORTB (Pins 8-13 on Arduino Uno). |
| uart_tx_pin | Output | 1-bit | Serial transmission line for UART communications. | <br> ## 🧠 Core Specifications & ISA <br> ### The Execution Engine <br> * **Registers:** 32 x 8-bit General Purpose Working Registers (R0 - R31). <br> * **Program Counter:** 16-bit PC, supporting up to 64KB of Program Memory. <br> * **Status Register:** Custom implementation featuring a Zero Flag (Z) for conditional branching. <br> ### Supported Instruction Set <br> The CPU decodes the top 4 bits (nibble) of the 16-bit instruction word to determine the operation.
| Opcode | Mnemonic | Operation | Description |
| :--- | :--- | :--- | :--- |
| 0x1 | **LDI** | Rd <- K | Load Immediate: Loads an 8-bit constant into a register. |
| 0x2 | **OUT** | I/O <- Rr | Out to I/O: Writes register data to a memory-mapped peripheral. |
| 0x4 | **LSL** | Rd <- Rd << 1 | Logical Shift Left: Shifts all bits left, padding with zero. |
| 0x9 | **CPI** | Rd == K | Compare Immediate: Compares register with constant, updates Zero Flag. |
| 0xA | **BRNE** | if(Z==0) PC=PC+k | Branch if Not Equal: Relative jump using two's complement sign extension. |
| 0xB | **RETI** | PC <- Stack | Return from Interrupt: Exits ISR and returns to main execution thread. |
| 0xC | **RJMP** | PC <- PC + k | Relative Jump: Unconditional jump to a relative memory address. | <br> ## 🗺️ Memory Map (Peripherals) <br> Rather than separate I/O spaces, peripherals are mapped directly to the Data SRAM addressing space, mimicking the standard AVR memory layout.
| Address | Peripheral | Access | Description |
| :--- | :--- | :--- | :--- |
| 0x25 | **GPIO / PORTB** | Write-Only | Controls the 8-bit output state of portb_pins. |
| 0x26 | **UART TX Data** | Write-Only | Writing an ASCII character here stages it for serial transmission. |

## 🔬 Testbench & Simulation
The test environment uses a custom visualizer acting as an internal logic analyzer. It is configured to run an **LED Chaser Program** simulating a Knight Rider scanner effect across PORTB.
### Simulation Sequence:
 1. **System Reset:** Asserts reset high, then low to initialize the CPU state.
 2. **Setup (LDI):** Loads binary 00000001 into R16.
 3. **Execution Loop:**
   * OUT writes R16 to Port B.
   * LSL shifts the bit left (e.g., 00000010).
   * CPI checks if the bit shifted completely out (equals 0x00).
   * BRNE jumps backward mathematically using Sign Extension ({{8{instruction[7]}}, instruction[7:0]}) to loop.
   * If zero, the program resets R16 and restarts.
### Running the Simulation
This project uses **Icarus Verilog (iverilog)**. To run locally:
```bash
# 1. Compile all Verilog files into a simulation executable
iverilog -o simulation.vvp *.v
# 2. Run the simulation
vvp simulation.vvp
```
**Expected Console Output:**
```text
⏱️ Time: 50000 ns | 🖥️ PC: 04 | 💡 LEDs: [. . . . . . . O]
⏱️ Time: 60000 ns | 🖥️ PC: 04 | 💡 LEDs: [. . . . . . O .]
⏱️ Time: 70000 ns | 🖥️ PC: 04 | 💡 LEDs: [. . . . . O . .]
```
## ⚙️ Continuous Integration (CI/CD)
The repository is hooked into GitHub Actions. On every push and pull_request to the main branch, the CI pipeline automatically:
 1. Provisions an Ubuntu environment.
 2. Installs iverilog.
 3. Links all modular files (avr_cpu_core.v, atmega328p_top.v, peripherals, testbench).
 4. Executes the simulation and validates successful execution.
## 🔮 Future Roadmap
 * [ ] Implement SRAM interface for LD and ST instructions.
 * [ ] Expand ALU to support full addition (ADD), subtraction (SUB), and logic (AND, OR).
 * [ ] Implement a proper hardware Stack Pointer (SP) for nested subroutines and interrupts.
 * [ ] Add bidirectional GPIO support (DDRB and PINB registers).
*Engineered from scratch for educational hardware exploration and Verilog HDL mastery.*
