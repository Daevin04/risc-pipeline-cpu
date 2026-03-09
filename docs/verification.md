# Verification

## Simulation Environment

All simulation was performed using Vivado XSIM (behavioral simulation). No gate-level or post-implementation simulation was run. The testbenches are written in VHDL and instantiate the design under test directly.

---

## Testbench Overview

### `testbench.vhd` — Integration Test

Top-level testbench instantiating `processor_top`. Generates a 100 MHz clock (10 ns period) and drives an active-high reset for the first 20 ns.

**Test program sections exercised:**

| Section | Instructions | Hazards present |
|---------|-------------|-----------------|
| BONUS | ABS, MIN, MAX | Data hazards (resolved by forwarding) |
| Initialization | ORI, SLL, ADDI, ADD | Data hazards (forwarding); no load-use |
| Loop (5 iterations) | LW, SW, BNE, ADDI, JUMP | Load-use stall; branch delay slots; forwarding |

**Checkpoint assertions:**

| Cycle | Checked signals | Expected values |
|-------|----------------|-----------------|
| 50 | R2, R6, R7 | BONUS instruction results |
| 120 | R1, R2, R4, R7 | Initialization complete |
| PC = 0x012A | All registers + memory[0x0200:0x0208] | Program completed — halt loop entered |

The testbench uses `assert` statements with severity `error` to flag mismatches during simulation. It does not use automatic pass/fail exit codes; results must be inspected in the Tcl console or waveform viewer.

### Unit Testbenches

| File | DUT | What is tested |
|------|-----|----------------|
| `tb_alu.vhd` | `alu` | All 12 operations: ADD, SUB, AND, OR, XOR, SRA, SLL, SLT, ABS, MIN, MAX, PASS_B; zero flag |
| `tb_register_file.vhd` | `register_file` | Read, write, write-through forwarding (read of register being written), R0 hardwiring |
| `tb_memory.vhd` | `memory` | Read/write timing, address decoding |
| `tb_memory_simple.vhd` | `memory` | Minimal read/write smoke test |
| `tb_datapath_pc_logic.vhd` | `datapath_pipelined` | PC increment, branch target, jump target computation |

---

## Running Simulation

### From the Vivado GUI

1. Open `Lab4P3.xpr` in Vivado
2. In the Sources panel, confirm that `testbench` is the active simulation set
3. Flow Navigator → **Run Simulation → Run Behavioral Simulation**
4. XSIM will open with the waveform viewer

To load the pre-configured signal list:
```tcl
source scripts/setup_waveform.tcl
```

### From the Tcl Console

```tcl
source scripts/run_sim.tcl
```

This compiles and runs the behavioral simulation for 600 clock cycles.

---

## Known Simulation Limitations

- **No automatic pass/fail:** The testbench asserts expected values but does not produce a machine-readable result. Failures appear as `assertion error` messages in the Tcl console.
- **Simulation time vs. cycle count:** The testbench uses a 10 ns clock period. 600 cycles = 6000 ns. The default run time in `run_sim.tcl` is set accordingly.
- **FPGA-level simulation not included:** The `processor_fpga.vhd` wrapper (with clock divider, button debouncing, 7-segment controller) is not covered by a testbench. Board behavior was verified on hardware.

---

## Waveform Configuration

`testbench_behav.wcfg` contains a pre-saved XSIM waveform layout with the following signal groups:

- PC and control flow signals (branch taken, jump)
- Pipeline register contents (IF/ID, ID/EX, EX/MEM, MEM/WB)
- Forwarding signals (ForwardA, ForwardB)
- Hazard detection signals (PC_Write, IFID_Write, Control_Flush)
- Register file write port
- ALU inputs and result
- Memory address and data

To load in XSIM: **File → Open Waveform Configuration → testbench_behav.wcfg**
