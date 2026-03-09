# 5-Stage Pipelined RISC CPU — VHDL, Artix-7 FPGA

A complete 5-stage pipelined processor implemented in VHDL, synthesized and implemented on the Nexys 4 DDR development board (Xilinx Artix-7). Designed as a computer organization course project with emphasis on microarchitecture correctness, hazard resolution, and FPGA board integration.

---

## Overview

This project implements a custom 16-bit RISC processor with a 5-stage pipeline (IF → ID → EX → MEM → WB). The processor executes a custom ISA with 20 instructions, handles all three classes of pipeline hazards, and runs visibly on an FPGA at a human-observable clock rate with 7-segment PC display and single-step debugging.

The design is written entirely in VHDL and targets the Xilinx `xc7a100tcsg324-1` (Artix-7) on the Nexys 4 DDR board. Synthesis, place-and-route, and bitstream generation were completed in Vivado 2023.2.

---

## Key Features

- **5-stage pipeline:** Instruction Fetch, Instruction Decode, Execute, Memory, Write Back
- **20-instruction custom ISA:** R-type, I-type, and J-type encodings on a 16-bit word
- **Data forwarding unit:** EX-to-EX bypass from the MEM and WB stages, eliminating NOPs for back-to-back dependent ALU instructions
- **Load-use hazard detection:** Automatic 1-cycle stall insertion when a load result is consumed by the immediately following instruction — no explicit NOPs required
- **ID-stage jump resolution:** Unconditional jumps resolved in the Decode stage (1-cycle penalty vs. the 3-cycle penalty of MEM-stage resolution), saving 2 NOPs per jump
- **3 custom ALU extensions:** ABS (absolute value), MIN, MAX
- **FPGA board integration:** 100 MHz → 2 Hz clock divider, 7-segment PC display, single-step (BTNU), run/pause toggle (BTND), active-low reset (CPU_RESETN)
- **Embedded test program:** 60+ instruction program exercising all hazard types, with only 5 explicit NOPs (3 branch delay slots + 2 jump delay slots) in the entire program

---

## Architecture Summary

### Pipeline Stages

| Stage | Module | Function |
|-------|--------|----------|
| IF | `datapath_pipelined` | Fetch instruction at PC, increment PC |
| ID | `control_unit`, `register_file` | Decode opcode, read registers, sign-extend immediates, resolve jumps |
| EX | `alu`, `alu_control`, `forwarding_unit` | Compute ALU result, select forwarded operands |
| MEM | `memory` | Load/store to data memory, resolve branch condition |
| WB | `datapath_pipelined` | Write result back to register file |

### Instruction Set Architecture

- **Data width:** 16 bits
- **Registers:** 8 × 16-bit (R0 hardwired to 0, R1–R7 general purpose)
- **Instruction memory:** 512 × 16-bit words
- **Instruction format:**

```
[15:12] opcode  [11:9] rs  [8:6] rt  [5:3] rd  [2:1] shamt/funct  [0] funct
I-type: [15:12] opcode  [11:9] rs  [8:6] rt  [5:0] immediate
J-type: [15:12] opcode  [11:0] jump_address
```

**Supported instructions:** ADD, SUB, AND, OR, XOR, SRA, SLL, SLT, ADDI, SUBI, ORI, SLTI, LW, SW, BEQ, BNE, JUMP, LI, ABS, MIN, MAX

### Hazard Resolution

```
Hazard Type          Resolution Strategy           Penalty
─────────────────────────────────────────────────────────
Data (ALU→ALU)       EX-to-EX forwarding           0 cycles
Load-use             Hardware stall (HDU)           1 cycle (automatic)
Branch               MEM-stage resolution           3-cycle delay slots
Jump                 ID-stage resolution            1-cycle delay slot
```

The forwarding unit checks if the source register of an instruction in EX matches the destination register of an instruction in MEM or WB and selects the appropriate bypass path. The hazard detection unit freezes the PC and IF/ID register while inserting a bubble into the ID/EX pipeline register.

### Module Hierarchy

```
processor_fpga (FPGA top-level, board I/O)
└── processor_top (processor wrapper)
    ├── datapath_pipelined (full pipeline datapath)
    │   ├── IF_ID_reg
    │   ├── ID_EX_reg
    │   ├── EX_MEM_reg
    │   ├── MEM_WB_reg
    │   ├── forwarding_unit
    │   ├── hazard_detection_unit
    │   ├── control_unit
    │   ├── alu_control
    │   ├── alu
    │   ├── register_file
    │   └── clock_divider
    ├── memory (instruction memory)
    └── memory (data memory)
```

---

## Verification

Simulation was performed in Vivado XSIM with multiple testbenches:

| Testbench | Scope |
|-----------|-------|
| `testbench.vhd` | Full processor integration — 600-cycle simulation with register/memory checkpoints |
| `tb_alu.vhd` | ALU unit test — all 12 operations including custom extensions |
| `tb_register_file.vhd` | Register file read/write and write-through forwarding |
| `tb_memory.vhd` | Memory read/write timing and initialization |
| `tb_datapath_pc_logic.vhd` | PC branch/jump calculation |

The integration testbench asserts expected register values at specific cycle counts and verifies memory contents after the program reaches the halt loop. A Vivado waveform configuration file (`testbench_behav.wcfg`) is included for quick signal inspection.

---

## Repository Structure

```
.
├── README.md
├── LICENSE
├── .gitignore
├── program.asm                         Assembly source for the embedded test program
├── testbench_behav.wcfg               Vivado waveform layout (preloaded signals)
├── Lab4P3.xpr                         Vivado project file
├── Lab4P3.srcs/
│   ├── sources_1/
│   │   ├── new/                       Pipeline registers, datapath, top-level, FPGA wrapper
│   │   │   ├── IF_ID_reg.vhd
│   │   │   ├── ID_EX_reg.vhd
│   │   │   ├── EX_MEM_reg.vhd
│   │   │   ├── MEM_WB_reg.vhd
│   │   │   ├── datapath_pipelined.vhd
│   │   │   ├── processor_top_pipelined.vhd
│   │   │   ├── processor_fpga.vhd
│   │   │   ├── forwarding_unit.vhd
│   │   │   ├── hazard_detection_unit.vhd
│   │   │   └── clock_divider.vhd
│   │   └── imports/Lab4_Phase3_Components/
│   │       ├── processor_pkg.vhd      Type definitions and ISA constants
│   │       ├── control_unit.vhd
│   │       ├── alu_control.vhd
│   │       ├── alu.vhd
│   │       ├── register_file.vhd
│   │       └── memory.vhd
│   ├── sim_1/new/                     Testbenches
│   └── constrs_1/imports/lab7/
│       └── Nexys4DDR_Master.xdc       Pin constraints for Nexys 4 DDR
├── scripts/
│   ├── run_sim.tcl                    Run behavioral simulation from Tcl console
│   └── setup_waveform.tcl             Load waveform signals in XSIM
└── docs/
    ├── architecture.md                Detailed microarchitecture reference
    ├── verification.md                Simulation methodology and results
    └── lessons_learned.md             Design decisions, bugs encountered, and insights
```

---

## How to Open in Vivado

The Vivado project is self-contained. The `.xpr` file uses `$PSRCDIR` macros that resolve source paths relative to the `.xpr` location, so the project opens correctly from any directory as long as the `Lab4P3.xpr` and `Lab4P3.srcs/` directory remain siblings (as they are in this repo).

```
1. Clone the repository
2. Open Vivado 2023.2 (or compatible version)
3. File → Open Project → select Lab4P3.xpr
4. Vivado may prompt to update the IP catalog — click OK
5. Sources, constraints, and simulation sets will appear in the Sources panel
```

Vivado will regenerate the `.cache/`, `.runs/`, `.sim/`, and `.hw/` directories automatically when you run synthesis, simulation, or implementation. These are excluded from the repo via `.gitignore`.

---

## How to Run / Reproduce

### Behavioral Simulation (no hardware required)

1. Open the project in Vivado
2. In the Flow Navigator, click **Run Simulation → Run Behavioral Simulation**
3. The `testbench` simulation set will launch XSIM
4. Optional: load the prebuilt waveform layout

```tcl
# In the Tcl console after simulation starts:
source scripts/setup_waveform.tcl
```

Or run simulation directly from the Tcl console:

```tcl
source scripts/run_sim.tcl
```

### Synthesis and Implementation (optional, generates new bitstream)

1. In the Flow Navigator, click **Run Synthesis**, then **Run Implementation**
2. After implementation: **Generate Bitstream**
3. Use **Open Hardware Manager → Program Device** to load onto Nexys 4 DDR

### On the FPGA Board

| Control | Function |
|---------|----------|
| `CPU_RESETN` (active-low) | Reset processor to initial state |
| `BTNU` | Single-step one clock cycle |
| `BTND` | Toggle run / pause |
| 7-segment display | Shows current PC value in hex |
| LEDs | Mirror lower bits of PC |

The processor runs at 2 Hz by default (100 MHz divided by 50,000,000), making each pipeline stage visible on the display.

---

## What I Learned

- **Pipeline hazard taxonomy is precise:** Data hazards, control hazards, and structural hazards each require distinct solutions. Forwarding eliminates most data hazards without stalling; load-use is the one case that requires a stall because the value is not available until after the MEM stage.
- **Moving computation earlier reduces penalty:** Resolving jumps in the ID stage instead of MEM saves two cycles per jump. The same principle (move resolution earlier) applies broadly to pipelined design.
- **VHDL process sensitivity lists matter:** Several bugs were caused by signals missing from combinational process sensitivity lists, producing correct simulation but potentially incorrect synthesis behavior.
- **Hazard detection interacts with flushing in subtle ways:** Getting the stall/flush priority correct (stall takes priority over flush on the same cycle) required careful reasoning about what happens when a load is immediately followed by a branch.

See `docs/lessons_learned.md` for a complete account of design decisions and bugs encountered.

---

## Limitations

- **Custom ISA, not standard:** The instruction set is course-defined, not MIPS or RISC-V. The processor cannot run real toolchain output.
- **No cache, no TLB:** Memory is synchronous BRAM with no hierarchy.
- **Hardcoded test program:** The test program is embedded in the memory initialization. There is no way to load a new program at runtime.
- **Branch resolved in MEM:** Branch decisions happen in the MEM stage (3-cycle delay). A more aggressive design would move branch resolution to ID or EX.
- **16-bit data path:** Register width, memory word width, and ALU width are all 16 bits. This limits the addressable space and arithmetic range.
- **No interrupts or exceptions:** The processor does not handle any form of exception or interrupt.

---

## Resume-Ready Project Description

**Project title:** 5-Stage Pipelined RISC Processor — VHDL / Artix-7 FPGA

**GitHub description:** 5-stage pipelined 16-bit RISC CPU in VHDL with data forwarding, load-use hazard detection, and Nexys 4 DDR FPGA implementation.

**Resume bullet points:**

- Designed a 5-stage pipelined 16-bit RISC processor in VHDL implementing a custom 20-instruction ISA, including 3 custom ALU extensions (ABS, MIN, MAX), synthesized and implemented on a Xilinx Artix-7 FPGA (Nexys 4 DDR)
- Implemented a forwarding unit and hazard detection unit to resolve data and load-use hazards, reducing explicit NOP instructions by 93% compared to a software-only hazard avoidance approach
- Integrated board-level I/O including a 2 Hz clock divider, 7-segment PC display, and single-step debug button, enabling real-time observation of pipeline execution on hardware

---

## License

MIT License. See [LICENSE](LICENSE).
