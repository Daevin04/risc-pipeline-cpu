# Architecture Reference

## Instruction Set Architecture

### Word and Register Width

All data paths are 16 bits wide. The processor has 8 registers (R0–R7). R0 is hardwired to zero; reads always return 0 and writes are ignored.

### Instruction Encoding

**R-type (register-to-register operations):**
```
[15:12] opcode  [11:9] rs  [8:6] rt  [5:3] rd  [2:1] shamt  [1:0] funct
```

**I-type (immediate / memory / branch):**
```
[15:12] opcode  [11:9] rs  [8:6] rt  [5:0] immediate (sign-extended to 16 bits)
```

**J-type (unconditional jump):**
```
[15:12] opcode  [11:0] jump_address
```

### Opcode Table

| Opcode (4-bit) | Mnemonic | Type | Operation |
|----------------|----------|------|-----------|
| 0000 | ADD/SUB/AND/OR | R | ALU op selected by funct |
| 0001 | SLT/XOR/SRA | R | ALU op selected by funct |
| 0010 | ADDI | I | rt ← rs + sign_ext(imm) |
| 0011 | SUBI | I | rt ← rs − sign_ext(imm) |
| 0100 | ORI | I | rt ← rs \| zero_ext(imm) |
| 0101 | LW | I | rt ← mem[rs + sign_ext(imm)] |
| 0110 | SW | I | mem[rs + sign_ext(imm)] ← rt |
| 0111 | SLTI | I | rt ← (rs < sign_ext(imm)) ? 1 : 0 |
| 1000 | BEQ | I | if (rs == rt) PC ← PC + sign_ext(imm)×2 |
| 1001 | BNE | I | if (rs ≠ rt) PC ← PC + sign_ext(imm)×2 |
| 1010 | JUMP | J | PC ← jump_address |
| 1011 | LI | I | rt ← zero_ext(imm) |
| 1111 | SLL | I | rt ← rs << shamt |
| 1100 | ABS | R | rd ← \|rs\| (custom extension) |
| 1101 | MIN | R | rd ← min(rs, rt) (custom extension) |
| 1110 | MAX | R | rd ← max(rs, rt) (custom extension) |

---

## Pipeline Datapath

### Stage Boundaries

Each pair of adjacent stages is separated by a pipeline register. All four registers (`IF_ID_reg`, `ID_EX_reg`, `EX_MEM_reg`, `MEM_WB_reg`) are clocked on the rising edge of the processor clock (the divided 2 Hz clock on the FPGA, or the 100 MHz simulation clock).

```
┌──────┐  IF/ID  ┌──────┐  ID/EX  ┌──────┐  EX/MEM ┌──────┐  MEM/WB ┌──────┐
│  IF  │────────▶│  ID  │────────▶│  EX  │────────▶│ MEM  │────────▶│  WB  │
└──────┘         └──────┘         └──────┘         └──────┘         └──────┘
   ▲                                                    │
   └──────────────── branch taken / jump ───────────────┘
```

### IF Stage

- PC register increments by 2 each cycle (16-bit word addressed, byte addressed memory → +2 per instruction).
- On stall: `PC_Write_Enable = 0` holds the PC.
- On branch taken (from MEM) or jump (from ID): PC is overwritten with the computed target.

### ID Stage

- Instruction fields are decoded and distributed to the control unit, register file, and immediate extension logic.
- The control unit generates all pipeline control signals based on the 4-bit opcode.
- Jumps are resolved here: the 12-bit jump address is zero-extended and loaded into the PC mux. A 1-cycle penalty follows (the instruction in IF is flushed).
- Register file provides write-through forwarding: if a register is being written and read on the same cycle, the new value is forwarded directly to the ID output without waiting for the write to commit.

### EX Stage

- The ALU receives two operands selected by the forwarding muxes (ForwardA, ForwardB).
- `ForwardA/B = 2'b00` → register file output (no hazard)
- `ForwardA/B = 2'b10` → forward from EX/MEM ALU result
- `ForwardA/B = 2'b01` → forward from MEM/WB result (ALU or memory load)
- The ALU control unit maps `ALUOp` (from control unit) plus `funct`/`opcode` to a 4-bit ALU operation select.

### MEM Stage

- Load and store operations access the data memory.
- The branch condition is evaluated here: if `Branch=1` and `Zero=1` (for BEQ), or `BranchNotEq=1` and `Zero=0` (for BNE), `MEM_branch_taken=1` and the PC is updated and the EX/MEM and ID/EX registers are flushed.

### WB Stage

- The write-back mux selects between the ALU result and the memory load data based on `MemtoReg`.
- The result is written to the register file at the address specified by `RegDst` (rd for R-type, rt for I-type).

---

## Hazard Units

### Forwarding Unit (`forwarding_unit.vhd`)

Combinational logic. Compares the source registers of the instruction in EX against the destination registers of the instructions in MEM and WB. Produces `ForwardA` and `ForwardB` control signals.

```
Priority: MEM-stage forward > WB-stage forward
Exception: Never forward from R0 (destination == 0 means no write)
```

### Hazard Detection Unit (`hazard_detection_unit.vhd`)

Detects load-use hazards — specifically when a LW is followed immediately by an instruction that reads the loaded register. On detection:

1. `PC_Write_Enable ← 0` — freeze the program counter
2. `IFID_Write_Enable ← 0` — freeze the IF/ID pipeline register
3. `Control_Flush ← 1` — zero out all control signals in the ID/EX register (insert a bubble / NOP)

This inserts exactly one stall cycle, after which the load result is available from the forwarding unit.

---

## Memory Model

A single `memory.vhd` component is instantiated twice in `processor_top_pipelined.vhd`: once as instruction memory (read-only in practice) and once as data memory. Both are 512 × 16-bit BRAM arrays.

The instruction memory is initialized at synthesis time with the test program binary encoded in the memory initialization section of `memory.vhd`. There is no way to load a new program at runtime; a new test program requires re-synthesizing the design.

---

## FPGA Top-Level

`processor_fpga.vhd` wraps the processor with Nexys 4 DDR board logic:

- **Clock divider:** Divides 100 MHz by 50,000,000 to produce a 2 Hz tick, allowing each pipeline step to be observed on the 7-segment display.
- **Single-step:** `BTNU` generates a one-cycle pulse, advancing the processor by one clock tick when paused.
- **Run/pause toggle:** `BTND` toggles continuous execution.
- **7-segment display:** The current PC value is displayed in hex across the 4 rightmost digits.
- **LEDs:** Lower bits of the PC are reflected on the 16 LEDs.
- **Reset:** `CPU_RESETN` is active-low (Nexys 4 board convention) and is inverted before driving the active-high processor reset.
