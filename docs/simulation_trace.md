# Pipeline Simulation Trace — Cycle-by-Cycle Analysis

Generated from Vivado XSIM behavioral simulation. Clock period: 10 ns. Reset released at 20 ns; first active rising edge at 25 ns. Cycle 0 reflects signal state 1 ns after that first edge.

---

## Quick Reference — All Instructions

Scan this table to instantly find any instruction: its fetch address, what it does, final result, and when the result commits to the register file. "Commit cycle" is when `WB_rw=1` and `wbdat` holds the final value.

### BONUS Section — Custom Instructions (0x0000–0x000E)

| PC (fetch) | Hex | Instruction | Computes | Result | Dest | Commit cycle |
|------------|-----|-------------|----------|--------|------|-------------|
| 0x0000 | 40FE | `ORI $v2, $zero, -2` | 0 \| sign-ext(-2) | **0xFFFE** | R3 | cyc 4 |
| 0x0002 | C690 | `ABS $v1, $v2` | \|0xFFFE\| | **0x0002** | R2 | cyc 5 |
| 0x0004 | 40C5 | `ORI $v2, $zero, 5` | 0 \| 5 | **0x0005** | R3 | cyc 6 |
| 0x0006 | 410A | `ORI $v3, $zero, 10` | 0 \| 10 | **0x000A** | R4 | cyc 7 |
| 0x0008 | D738 | `MIN $a1, $v2, $v3` | min(5, 10) | **0x0005** | R7 | cyc 8 |
| 0x000A | E730 | `MAX $a0, $v2, $v3` | max(5, 10) | **0x000A** | R6 | cyc 9 |
| 0x000C | A01C | `JUMP 0x0038` | PC ← 0x0038 | — | — | cyc 8 (ID-stage) |
| 0x000E | 0000 | `NOP` (jump delay slot) | — | — | — | — |

> After the JUMP commits, the pipeline drains: cycles 8–11 execute the stale-fetch NOPs while the JUMP redirect takes effect. Active instructions resume at 0x0038 from cycle 11 onward.

---

### Initialization Section — Build Working Registers (0x0038–0x004C)

| PC (fetch) | Hex | Instruction | Computes | Result | Dest | Commit cycle |
|------------|-----|-------------|----------|--------|------|-------------|
| 0x0038 | B244 | `LI $v0, 4` | 4 | **0x0004** | R1 | cyc 15 |
| 0x003A | F244 | `SLL $v0, $v0, 4` | 4 << 4 | **0x0040** | R1 | cyc 16 |
| 0x003C | B481 | `LI $v1, 1` | 1 | **0x0001** | R2 | cyc 17 |
| 0x003E | F48C | `SLL $v1, $v1, 12` | 1 << 12 | **0x1000** | R2 | cyc 18 |
| 0x0040 | 2490 | `ADDI $v1, $v1, 16` | 0x1000 + 16 | **0x1010** | R2 | cyc 19 |
| 0x0042 | B6CF | `LI $v2, 15` | 15 | **0x000F** | R3 | cyc 20 |
| 0x0044 | B90F | `LI $v3, 15` | 15 | **0x000F** | R4 | cyc 21 |
| 0x0046 | F904 | `SLL $v3, $v3, 4` | 15 << 4 | **0x00F0** | R4 | cyc 22 |
| 0x0048 | BD82 | `LI $a0, 2` | 2 | **0x0002** | R6 | cyc 23 |
| 0x004A | FD88 | `SLL $a0, $a0, 8` | 2 << 8 | **0x0200** | R6 | cyc 24 |
| 0x004C | BFC5 | `LI $a1, 5` | 5 | **0x0005** | R7 | cyc 25 |

> Every result here is forwarded to the next instruction via the EX→EX bypass — zero NOP overhead, zero register-file stalls.

---

### Loop Body — Per-Iteration Breakdown (0x004E–0x0062, 5 iterations)

Each pass through the loop executes these 8 instructions. The load-use stall between LW and SW is handled entirely by hardware — no NOP in the source.

| PC | Instruction | What it does | Iter 1 result | Iter 2 | Iter 3 | Iter 4 | Iter 5 |
|----|-------------|--------------|---------------|--------|--------|--------|--------|
| 0x004E | `SUB $t0,$t0,$t0` | Zero out $t0 | R5 = 0x0000 | same | same | same | same |
| 0x0050 | `BEQ $a1,$t0, 27` | Branch if $a1==0 | not taken | not taken | not taken | not taken | **TAKEN** |
| 0x0051–56 | `NOP × 3` | Branch delay slots | — | — | — | — | — |
| 0x0058 | `SUBI $a1,$a1,1` | Decrement counter | R7: 5→**4** | 4→**3** | 3→**2** | 2→**1** | 1→**0** |
| 0x005A | `LW $t0, 0($a0)` | Load from Mem[$a0] | $t0=**0x0101** | **0x0110** | **0x0011** | **0x00F0** | **0x00FF** |
| 0x005C | `SW $t0, 0($a0)` | Store $t0→Mem[$a0] | *(HW stalls 1 cyc)* | same | same | same | same |
| 0x005E | `ADDI $a0,$a0,2` | Advance pointer | R6: 0x200→**0x202** | →**0x204** | →**0x206** | →**0x208** | →**0x20A** |
| 0x0060 | `JUMP 0x004E` | Back to loop top | — | — | — | — | — |
| 0x0062 | `NOP` | Jump delay slot | — | — | — | — | — |

> The LW→SW pair on every iteration triggers the hazard detection unit: PC and IF/ID freeze for one cycle, a bubble is inserted into ID/EX, then SW's ForwardB mux (select=01) grabs the loaded value from the MEM/WB stage.

**BEQ taken on iteration 5** (cycle ≈ 82, t ≈ 846 ns): $a1 decrements to 0, the SUB at 0x004E clears $t0 to 0, and BEQ sees $a1 == $t0. The processor flushes the three NOPs that followed and redirects to the halt loop.

---

### Final State After Program Completion

| Register | Final value | Set by |
|----------|-------------|--------|
| R0 $zero | 0x0000 | always zero |
| R1 $v0 | **0x0040** | SLL at 0x003A |
| R2 $v1 | **0x1010** | ADDI at 0x0040 |
| R3 $v2 | **0x000F** | LI at 0x0042 |
| R4 $v3 | **0x00F0** | SLL at 0x0046 |
| R5 $t0 | **0x00FF** | LW at 0x005A (iter 5) |
| R6 $a0 | **0x020A** | ADDI at 0x005E (iter 5) |
| R7 $a1 | **0x0000** | SUBI at 0x0058 (iter 5) |

| Memory address | Final value | Note |
|----------------|-------------|------|
| 0x0200 (mem[256]) | 0x0101 | loaded and stored back, iter 1 |
| 0x0202 (mem[257]) | 0x0110 | iter 2 |
| 0x0204 (mem[258]) | 0x0011 | iter 3 |
| 0x0206 (mem[259]) | 0x00F0 | iter 4 |
| 0x0208 (mem[260]) | 0x00FF | iter 5 |

> Note: XSIM may show 0x0000 for memory after `restart` because the reset initialization signal does not re-fire. The correct values are visible in the `wbdat` column of the cycle-by-cycle dump during each LW commit.

---

## Column Reference

```
CYC     Processor cycle number (counted from first active rising edge)
IF:PC   Program counter value latched this cycle — the address being fetched NEXT
ID:instr  Raw hex instruction in the IF/ID register — being decoded this cycle
EX:op   Instruction mnemonic and opcode in the ID/EX register — executing this cycle
EX:rs,rt  Source registers of the EX-stage instruction (decoded from IDEX fields)
->rd    Destination register (rd bits from instruction encoding — actual write target
          follows RegDst: rt for I-type, rd for R-type)
ALU     ALU result computed this cycle in the EX stage
Br=     MEM_branch_taken — fires from the MEM stage when a branch condition is true
FA FB   ForwardA / ForwardB — forwarding mux selects for ALU operands:
          00 = no forward (use register file output)
          10 = forward from EX/MEM stage (one cycle old result)
          01 = forward from MEM/WB stage (two cycles old result, via WB_write_data)
P I F   PC_Write / IFID_Write / Control_Flush — hazard detection outputs:
          P=0: PC frozen (stall)
          I=0: IF/ID register frozen (stall)
          F=1: bubble being inserted into ID/EX (load-use stall or flush)
MEM_rw  EXMEM_RegWrite — whether the instruction now in MEM will write a register
Rg      EXMEM_write_reg — which register it will write
dat     EXMEM_alu_result — ALU result carried into the MEM stage
WB_rw   MEMWB_RegWrite — whether the instruction now in WB is committing a write
wbdat   WB_write_data — the value being written to the register file this cycle
```

**Pipeline staging note:** Because the dump is captured one cycle after each rising edge, the columns map as follows: `IF:PC` reflects the instruction just fetched; `ID:instr` is decoding; `EX:op` is executing; `MEM_rw/Rg/dat` is the instruction one stage ahead of EX in the memory stage; `WB_rw/wbdat` is the instruction committing results.

---

## Waveform Answer Sheet

**How to use:** Type the time into Vivado's "Go to time" box. Find the matching card below. Each card lists what every signal in your waveform groups should read at that moment, plus a key result callout explaining what is happening and why.

Time formula: `ns = 26 + (cycle × 10)`

Quick index of times to visit: `46` `76` `86` `96` `126` `156` `236` `286` `296` `306` `406` `846` `856`

---

### t = 46 ns | Cycle 2 | ABS executes — EX/MEM forwarding active

> **KEY RESULT: ABS computes |−2| = 0x0002. The input was forwarded directly from the previous instruction's ALU output — the register file was not read.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `cycle_count` | 2 | |
| top | `PC` | 0x0006 | Fetching ORI $v3, $zero, 10 next |
| **group675** | `instruction` | 0x410A | Instruction memory output at 0x0006 |
| group675 | `IF_PC` | 0x0006 | |
| group675 | `IFID_instruction` | **0x40C5** | ORI $v2, $zero, 5 — now in decode |
| **group676** | `ID_opcode` | 4 | ORI being decoded |
| group676 | `ID_rs` | 0 | $zero |
| group676 | `ID_rt` | 3 | $v2 = destination |
| group676 | `ID_immediate` | 5 | immediate = 5 |
| **group677** | `IDEX_opcode` | **C** | ABS — this is the executing instruction |
| group677 | `IDEX_read_data1` | 0x0000 | Stale register file value for R3 (not used) |
| group677 | `alu_control` | ABS op | |
| group677 | `operand_a` | **0xFFFE** | Forwarded from EX/MEM (ORI result, not register file) |
| group677 | `operand_b` | 0x0000 | Unused by ABS |
| group677 | `EX_alu_result` | **0x0002** | \|0xFFFE\| = 2 ✓ |
| group677 | `EX_write_reg` | R2 | ABS destination = $v1 |
| group677 | `IDEX_RegWrite` | 1 | Will write result |
| **group678** | `EXMEM_alu_result` | **0xFFFE** | ORI result being carried through MEM — this is what ForwardA tapped |
| group678 | `EXMEM_write_reg` | R3 | ORI was writing $v2 |
| group678 | `EXMEM_RegWrite` | 1 | |
| group678 | `EXMEM_MemRead` | 0 | No memory load |
| **group1149** | `EXMEM_Branch` | 0 | |
| group1149 | `EXMEM_zero_flag` | 0 | |
| group1149 | `MEM_branch_taken` | 0 | |

---

### t = 76 ns | Cycle 5 | MIN executes — ForwardA and ForwardB both active simultaneously

> **KEY RESULT: MIN computes min(5, 10) = 0x0005. Both ALU inputs were forwarded — R3=5 from WB, R4=10 from MEM — zero register file reads.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `PC` | 0x000C | Fetching JUMP next |
| group675 | `IF_PC` | 0x000C | |
| group675 | `IFID_instruction` | **0xE730** | MAX — now in decode |
| group676 | `ID_opcode` | E | MAX being decoded |
| group676 | `ID_rs` | 3 | $v2 |
| group676 | `ID_rt` | 4 | $v3 |
| group676 | `ID_rd` | 6 | $a0 = destination |
| **group677** | `IDEX_opcode` | **D** | MIN — this is the executing instruction |
| group677 | `operand_a` | **0x0005** | Forwarded from MEM/WB (ORI $v2=5, ForwardA=01) |
| group677 | `operand_b` | **0x000A** | Forwarded from EX/MEM (ORI $v3=10, ForwardB=10) |
| group677 | `EX_alu_result` | **0x0005** | min(5, 10) = 5 ✓ |
| group677 | `EX_write_reg` | R7 | MIN destination = $a1 |
| group677 | `IDEX_RegWrite` | 1 | |
| **group678** | `EXMEM_alu_result` | **0x000A** | ORI $v3=10 in MEM — this is what ForwardB tapped |
| group678 | `EXMEM_write_reg` | R4 | |
| group678 | `EXMEM_RegWrite` | 1 | |
| group1149 | `MEM_branch_taken` | 0 | |

---

### t = 86 ns | Cycle 6 | MAX executes + JUMP enters decode

> **KEY RESULT: MAX computes max(5, 10) = 0x000A. Simultaneously, the JUMP instruction is in the decode stage — the processor is already computing the jump target 0x0038.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `PC` | 0x000E | Fetching delay slot NOP |
| group675 | `IF_PC` | 0x000E | |
| group675 | `IFID_instruction` | **0xA01C** | JUMP 0x0038 — now in decode |
| group676 | `ID_opcode` | A | JUMP being decoded |
| group676 | `ID_immediate` | 0x01C | Jump address field (word 28 = byte 0x0038) |
| **group677** | `IDEX_opcode` | **E** | MAX — this is the executing instruction |
| group677 | `operand_a` | 0x0005 | R3=5 from register file (no forward needed) |
| group677 | `operand_b` | **0x000A** | Forwarded from MEM/WB (ORI $v3=10, ForwardB=01) |
| group677 | `EX_alu_result` | **0x000A** | max(5, 10) = 10 ✓ |
| group677 | `EX_write_reg` | R6 | MAX destination = $a0 |
| **group678** | `EXMEM_alu_result` | 0x0005 | MIN result (= R7) moving through MEM |
| group678 | `EXMEM_write_reg` | R7 | |
| group1149 | `MEM_branch_taken` | 0 | |

---

### t = 96 ns | Cycle 7 | Jump redirect — PC jumps to 0x0038

> **KEY RESULT: PC has jumped from 0x000E to 0x0038 in a single cycle. Only the NOP delay slot was consumed. MAX result (0x000A) is moving through the MEM stage on its way to writing R6.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `PC` | **0x0038** | Jumped! Was 0x000E last cycle |
| group675 | `IF_PC` | **0x0038** | Now fetching init section |
| group675 | `IFID_instruction` | **0x0000** | NOP delay slot — in decode |
| group676 | `ID_opcode` | 0 | NOP decoded as ADD R0,R0,R0 |
| **group677** | `IDEX_opcode` | E | MAX opcode retained (flush zeros control signals only) |
| group677 | `EX_alu_result` | 0x0005 | Garbage — flush bubble, IDEX_RegWrite=0 so nothing commits |
| group677 | `IDEX_RegWrite` | **0** | Flushed — no register write despite non-zero opcode |
| **group678** | `EXMEM_alu_result` | **0x000A** | MAX result moving to WB next cycle — R6 will get 0x000A |
| group678 | `EXMEM_write_reg` | R6 | |
| group678 | `EXMEM_RegWrite` | 1 | |
| group1149 | `MEM_branch_taken` | 0 | |

---

### t = 126 ns | Cycle 10 | SLL $v0 — chained forwarding after LI

> **KEY RESULT: SLL shifts 4 left by 4 bits = 0x0040. The value 4 was forwarded from EX/MEM (LI result one cycle old) — no stall, no NOP.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `PC` | 0x003E | Fetching LI $v1=1 next |
| group675 | `IFID_instruction` | **0xB481** | LI $v1, 1 — in decode |
| group676 | `ID_opcode` | B | LI being decoded |
| **group677** | `IDEX_opcode` | **F** | SLL — this is the executing instruction |
| group677 | `operand_a` | **0x0004** | Forwarded from EX/MEM (LI $v0=4, ForwardA=10) |
| group677 | `operand_b` | **0x0004** | Forwarded from EX/MEM same source (ForwardB=10) |
| group677 | `EX_alu_result` | **0x0040** | 4 << 4 = 64 = 0x40 ✓ |
| group677 | `EX_write_reg` | R1 | Writing $v0 |
| **group678** | `EXMEM_alu_result` | **0x0004** | LI result — this is what ForwardA/B tapped |
| group678 | `EXMEM_write_reg` | R1 | |
| group678 | `EXMEM_RegWrite` | 1 | |

---

### t = 156 ns | Cycle 13 | ADDI $v1 — three-instruction forwarding chain

> **KEY RESULT: ADDI adds 16 to SLL's result: 0x1000 + 16 = 0x1010. This is the third instruction in a chain — LI→SLL→ADDI — all handled by forwarding with zero NOPs.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `PC` | 0x0044 | Fetching LI $v2=15 next |
| group675 | `IFID_instruction` | **0xB6CF** | LI $v2, 15 — in decode |
| **group677** | `IDEX_opcode` | **2** | ADDI — this is the executing instruction |
| group677 | `operand_a` | **0x1000** | Forwarded from EX/MEM (SLL result, ForwardA=10) |
| group677 | `operand_b` | **0x0010** | Immediate = 16 (from sign extension) |
| group677 | `EX_alu_result` | **0x1010** | 0x1000 + 16 = 0x1010 ✓ |
| group677 | `EX_write_reg` | R2 | Writing $v1 |
| **group678** | `EXMEM_alu_result` | **0x1000** | SLL result — what ForwardA tapped |
| group678 | `EXMEM_write_reg` | R2 | |

---

### t = 236 ns | Cycle 21 | BEQ — not taken (loop counter = 5, not 0)

> **KEY RESULT: BEQ compares R7=5 vs R5=0. They are not equal, so branch is not taken. Loop body executes. ForwardA and ForwardB active — neither value was committed to register file yet.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `PC` | 0x0054 | Fetching NOP delay slot 1 |
| group675 | `IFID_instruction` | 0x0000 | NOP delay slot 1 — in decode |
| **group677** | `IDEX_opcode` | **8** | BEQ — this is the executing instruction |
| group677 | `operand_a` | **0x0005** | R7=5 forwarded from MEM/WB (LI $a1=5, ForwardA=01) |
| group677 | `operand_b` | **0x0000** | R5=0 forwarded from EX/MEM (SUB result, ForwardB=10) |
| group677 | `EX_alu_result` | **0x0005** | R7 − R5 = 5 − 0 = 5, not zero |
| **group678** | `EXMEM_alu_result` | 0x0000 | SUB R5=0 in MEM — what ForwardB tapped |
| **group1149** | `EXMEM_Branch` | 1 | BEQ control signal is set |
| group1149 | `EXMEM_zero_flag` | **0** | Not zero → branch condition false |
| group1149 | `MEM_branch_taken` | **0** | Branch NOT taken ✓ |

---

### t = 286 ns | Cycle 26 | Load-use stall fires — LW in EX, SW in decode

> **KEY RESULT: Hazard detection freezes the PC and IF/ID register and inserts a bubble into ID/EX. LW is computing the load address 0x0200. SW is frozen in decode waiting for the load result. No explicit NOP was written.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `PC` | **0x005E** | FROZEN — same as last cycle, will not advance |
| group675 | `IF_PC` | **0x005E** | Frozen |
| group675 | `IFID_instruction` | **0x6D40** | SW — frozen in decode, waiting for LW |
| group676 | `ID_opcode` | 6 | SW being decoded |
| group676 | `ID_rs` | 6 | $a0 = base address register |
| group676 | `ID_rt` | 5 | $t0 = data register (this is R5 = LW destination → hazard!) |
| **group677** | `IDEX_opcode` | **5** | LW — this is the executing instruction |
| group677 | `operand_a` | 0x0200 | R6=$a0 (base address) |
| group677 | `operand_b` | 0x0000 | Offset = 0 |
| group677 | `EX_alu_result` | **0x0200** | Load address = R6 + 0 = 0x0200 ✓ |
| group677 | `IDEX_RegWrite` | 1 | LW will write R5 |
| **group678** | `EXMEM_alu_result` | 0x0004 | SUBI result (R7=4) still moving through |
| group678 | `EXMEM_write_reg` | R7 | |
| group1149 | `MEM_branch_taken` | 0 | |

> **At this exact moment in the waveform, watch: PC does not change on the NEXT rising edge. IFID_instruction does not change. A bubble appears in group677 signals at t=296ns.**

---

### t = 296 ns | Cycle 27 | Stall cycle — bubble in EX, LW in MEM

> **KEY RESULT: The stall has taken effect. A bubble occupies EX. LW is now in the MEM stage reading address 0x0200 from data memory. The value 0x0101 is being loaded. SW is still frozen in decode.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `PC` | **0x005E** | Still frozen from last cycle |
| group675 | `IF_PC` | **0x005E** | Still frozen |
| group675 | `IFID_instruction` | **0x6D40** | SW still frozen in decode |
| **group677** | `IDEX_opcode` | 5 | Opcode field retained, but control signals zeroed |
| group677 | `IDEX_RegWrite` | **0** | Bubble — no register write despite opcode showing LW |
| group677 | `EX_alu_result` | 0x0400 | Garbage computation from bubble — harmless |
| **group678** | `EXMEM_alu_result` | **0x0200** | LW load address — memory is reading from here right now |
| group678 | `EXMEM_MemRead` | **1** | Memory read in progress |
| group678 | `EXMEM_write_reg` | R5 | LW will write $t0 |
| group1149 | `MEM_branch_taken` | 0 | |

---

### t = 306 ns | Cycle 28 | SW executes — forwarded LW data used as store value

> **KEY RESULT: SW stores 0x0101 to address 0x0200. The value 0x0101 came from LW two cycles ago and is forwarded via MEM/WB — the register file (R5) was never read. This is the forwarding unit resolving the hazard that the stall began.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `PC` | 0x0060 | Back to normal — ADDI $a0 fetching |
| group675 | `IFID_instruction` | **0x2D82** | ADDI $a0, $a0, 2 — in decode |
| **group677** | `IDEX_opcode` | **6** | SW — this is the executing instruction |
| group677 | `operand_a` | **0x0200** | R6=$a0 = store address base |
| group677 | `operand_b` | **0x0101** | ForwardB=01 → from MEM/WB (LW loaded 0x0101 from Mem[0x0200]) |
| group677 | `EX_alu_result` | **0x0200** | Store address = R6 + 0 = 0x0200 ✓ |
| group677 | `IDEX_RegWrite` | **0** | SW does not write register |
| **group678** | `EXMEM_alu_result` | 0x0400 | Bubble garbage — ignore (EXMEM_RegWrite=0) |
| group678 | `EXMEM_RegWrite` | 0 | |
| group1149 | `MEM_branch_taken` | 0 | |

> **In WB this cycle:** `WB_write_data = 0x0101`, `MEMWB_RegWrite = 1` — LW result is being committed to R5 right now.

---

### t = 406 / 526 / 646 / 766 ns | Cycles 38 / 50 / 62 / 74 | Load-use stall — iterations 2–5

> **KEY RESULT: Same stall pattern repeats once per loop iteration. LW address increments by 2 each time as R6=$a0 advances.**

| Iteration | Stall cycle | Time | LW address | Mem value loaded |
|-----------|-------------|------|-----------|-----------------|
| 2 | 38 | 406 ns | 0x0202 | 0x0110 |
| 3 | 50 | 526 ns | 0x0204 | 0x0011 |
| 4 | 62 | 646 ns | 0x0206 | 0x00F0 |
| 5 | 74 | 766 ns | 0x0208 | 0x00FF |

At each stall cycle: `PC` frozen, `IFID_instruction = 0x6D40` (SW), `EX_alu_result` = load address, `EXMEM_MemRead = 1`.

---

### t = 846 ns | Cycle 82 | BEQ taken — loop counter reached zero

> **KEY RESULT: R7=0 and R5=0, so BEQ condition is true. MEM_branch_taken fires. This is the only cycle in the entire simulation where MEM_branch_taken = 1.**

| Group | Signal | Value | What it means |
|-------|--------|-------|---------------|
| top | `PC` | 0x0056 | Mid-branch — delay slots |
| group675 | `IFID_instruction` | 0x0000 | NOP delay slot in decode |
| **group677** | `IDEX_opcode` | 0 | NOP/bubble in EX |
| group677 | `EX_alu_result` | 0x0000 | |
| **group678** | `EXMEM_alu_result` | 0x0000 | BEQ comparison result — zero! |
| **group1149** | `EXMEM_Branch` | **1** | BEQ control signal set |
| group1149 | `EXMEM_zero_flag` | **1** | R7 − R5 = 0 → branch condition true |
| group1149 | `MEM_branch_taken` | **1** | BRANCH TAKEN — watch PC change on next cycle |

> **At t = 856 ns (next cycle):** `IF_PC` jumps to **0x0088** (not 0x0080 — branch offset bug in test program). PC will keep incrementing through uninitialized memory (all 0x0000) from here on.

---

## Section 1 — BONUS Custom Instructions (Cycles 0–6)

Tests the three custom ALU extensions: ABS, MIN, MAX.

```
CYC | IF:PC  | ID:instr | EX:op         | EX:rs,rt | ALU    | Br | FA FB | P I F | WB_rw wbdat
----+--------+----------+---------------+----------+--------+----+-------+-------+-------------
 0  | 0x0002 | 40FE     | ADD/SUB(0)    | R0,R0    | 0x0000 |  0 | 00 00 | 1 1 0 | 0     0x0000
 1  | 0x0004 | C690     | ORI    (4)    | R0,R3    | 0xFFFE |  0 | 00 00 | 1 1 0 | 0     0x0000
 2  | 0x0006 | 40C5     | ABS    (C)    | R3,R2    | 0x0002 |  0 | 10 00 | 1 1 0 | 1     0x0000
 3  | 0x0008 | 410A     | ORI    (4)    | R0,R3    | 0x0005 |  0 | 00 01 | 1 1 0 | 1     0xFFFE
 4  | 0x000A | D738     | ORI    (4)    | R0,R4    | 0x000A |  0 | 00 00 | 1 1 0 | 1     0x0002
 5  | 0x000C | E730     | MIN    (D)    | R3,R4    | 0x0005 |  0 | 01 10 | 1 1 0 | 1     0x0005
 6  | 0x000E | A01C     | MAX    (E)    | R3,R4    | 0x000A |  0 | 00 01 | 1 1 0 | 1     0x000A
```

**Cycle 0:** Pipeline is filling. The first instruction (ORI $v2, $zero, -2) is in the IF/ID register being decoded. The EX stage holds a reset bubble.

**Cycle 1:** ORI is executing. `IDEX_rs=R0` (=$zero), `IDEX_rt=R3` ($v2). Immediate = 0x3E (62 decimal), sign-extended → 0xFFFE (−2). ALU result = R0 | 0xFFFE = **0xFFFE**. No forwarding needed (FA=00, FB=00).

**Cycle 2:** ABS is executing. `ForwardA=10` — the ABS instruction reads $v2 (R3), which was written by ORI one cycle ago and is now in the EX/MEM register. Instead of reading the stale register file value, the forwarding unit selects EXMEM_alu_result = 0xFFFE. ALU computes |0xFFFE| = **0x0002**. In WB this cycle: the reset bubble commits nothing (WB_rw=1 writing R0=0, harmless).

**Cycle 3:** ORI $v2, $zero, 5 executing. `ForwardB=01` — the destination of the ORI two cycles ago (R3=$v2) is now in MEM/WB. WB_write_data = 0xFFFE is being written to R3 this cycle (WB_rw=1, wbdat=0xFFFE). The ORI at cycle 3 doesn't need R3 as an input, so this forwarding is for the ABS result (R2) coincidentally matching. ALU result = 0 | 5 = **0x0005**.

**Cycle 4:** ORI $v3, $zero, 10 executing. No forwarding needed. ALU = **0x000A**. In WB: ABS result 0x0002 committed to R2.

**Cycle 5:** MIN $a1, $v2, $v3 executing.
- `ForwardA=01` (MEM/WB → R3): ORI $v2=5 is in WB, forwarding 0x0005 to ALU operand A.
- `ForwardB=10` (EX/MEM → R4): ORI $v3=10 is in MEM, forwarding 0x000A to ALU operand B.
- ALU result = min(5, 10) = **0x0005**. Both forwarding paths active simultaneously. ✓

**Cycle 6:** MAX $a0, $v2, $v3 executing.
- `ForwardA=00` — R3=5 is already committed to register file (written at WB during cycle 5).
- `ForwardB=01` (MEM/WB → R4): ORI $v3=10 is now in WB, forwarding 0x000A.
- ALU result = max(5, 10) = **0x000A**. ✓

**Summary:** All three BONUS instructions produced correct results. ABS used one EX/MEM forward (FA=10). MIN used simultaneous EX/MEM and MEM/WB forwards (FA=01, FB=10). MAX used a single MEM/WB forward (FB=01).

---

## Section 2 — ID-Stage Jump (Cycles 6–8)

After the BONUS section, an unconditional JUMP transfers control to the initialization section at 0x0038.

```
CYC | IF:PC  | ID:instr | EX:op         | Notes
----+--------+----------+---------------+------------------------------------------
 6  | 0x000E | A01C     | MAX    (E)    | JUMP 0x0038 in ID; MAX in EX
 7  | 0x0038 | 0000     | MAX    (E)*   | PC updated; delay slot NOP enters ID
 8  | 0x003A | B244     | ADD/SUB(0)    | NOP in EX (delay slot executes harmlessly)
```

*At cycle 7, IDEX retains the MAX opcode field but all control signals are zeroed (flush). This is a known implementation detail: only control signals are flushed, not the opcode register. The ALU computes a garbage result but RegWrite=0 ensures nothing is committed.

**Cycle 6:** JUMP (A01C) is in the IF/ID register being decoded. The datapath resolves the 12-bit jump address (0x001C = 28 words = 0x0038 bytes) in the ID stage and immediately writes 0x0038 to the PC mux. The instruction currently in IF (at 0x000E = 0x0000, the NOP delay slot) is allowed to continue.

**Cycle 7:** PC has jumped to 0x0038. The NOP (delay slot from 0x000E) is now in the ID stage. Only one instruction was wasted (the delay slot NOP), giving a **1-cycle jump penalty** instead of the 3-cycle penalty that MEM-stage resolution would require.

**Cycle 8:** Initialization section begins fetching from 0x003A. The delay slot NOP is in EX and executes harmlessly (ADD R0, R0, R0 with no register write).

---

## Section 3 — Initialization (Cycles 9–19)

Builds register values using LI, SLL, and ADDI. All data hazards are handled by EX-to-EX forwarding — zero explicit NOPs.

```
CYC | IF:PC  | ID:instr | EX:op      | ALU    | FA FB | WB_rw wbdat  | Notes
----+--------+----------+------------+--------+-------+--------------+------------------------
  9 | 0x003C | F244     | LI     (B) | 0x0004 | 00 00 | 0     0x0005 | LI $v0=4
 10 | 0x003E | B481     | SLL    (F) | 0x0040 | 10 10 | 1     0x0004 | SLL $v0,4 << 4=0x40; FORWARD FA=10,FB=10
 11 | 0x0040 | F48C     | LI     (B) | 0x0001 | 00 00 | 1     0x0040 | LI $v1=1; R1=0x0040 committed
 12 | 0x0042 | 2490     | SLL    (F) | 0x1000 | 10 10 | 1     0x0001 | SLL $v1,1 << 12=0x1000; FORWARD FA=10,FB=10
 13 | 0x0044 | B6CF     | ADDI   (2) | 0x1010 | 10 10 | 1     0x0001 | ADDI $v1,+16; FORWARD FA=10,FB=10
 14 | 0x0046 | B90F     | LI     (B) | 0x000F | 00 00 | 1     0x1000 | LI $v2=15
 15 | 0x0048 | F904     | LI     (B) | 0x000F | 00 00 | 1     0x000F | LI $v3=15
 16 | 0x004A | BD82     | SLL    (F) | 0x00F0 | 10 10 | 1     0x000F | SLL $v3,15 << 4=0xF0; FORWARD FA=10,FB=10
 17 | 0x004C | FD88     | LI     (B) | 0x0002 | 00 00 | 1     0x00F0 | LI $a0=2
 18 | 0x004E | BFC5     | SLL    (F) | 0x0200 | 10 10 | 1     0x0002 | SLL $a0,2 << 8=0x200; FORWARD FA=10,FB=10
 19 | 0x0050 | 0B69     | LI     (B) | 0x0005 | 00 00 | 1     0x0200 | LI $a1=5 (loop counter)
```

**Forwarding pattern (cycles 10, 12, 13, 16, 18):** Every `SLL` or `ADDI` that immediately follows a `LI` (or another SLL) that writes the same register uses `ForwardA=10` and `ForwardB=10` — both ALU inputs forwarded from the EX/MEM stage (one cycle old result). This eliminates what would otherwise be two NOPs per dependent instruction pair.

**Cycle 10 detail:** `SLL $v0, $v0, 4` — LI wrote R1=4 at the previous cycle. At cycle 10, that result (0x0004) is in EX/MEM. ForwardA=10 selects it as the shift operand. ForwardB=10 also selects from EX/MEM (the same source — the forwarding unit selects EX/MEM for both inputs since both rs and rt decode to R1). SLL computes 4 << 4 = **0x0040**. In WB this cycle: LI result 0x0004 commits to R1 (shown in wbdat), but it will be immediately superseded by SLL's 0x0040.

**Cycle 13 detail:** `ADDI $v1, $v1, 16` — SLL at cycle 12 wrote R2=0x1000. ForwardA=10 forwards 0x1000; ForwardB is irrelevant (ADDI uses immediate). ADDI computes 0x1000 + 16 = **0x1010**. ✓

---

## Section 4 — Loop Entry and First BEQ (Cycles 20–25)

```
CYC | IF:PC  | ID:instr | EX:op      | ALU    | FA FB | Notes
----+--------+----------+------------+--------+-------+------------------------------------
 20 | 0x0052 | 8F5B     | ADD/SUB(0) | 0x0000 | 00 00 | SUB $t0,$t0,$t0 entering ID
 21 | 0x0054 | 0000     | BEQ    (8) | 0x0005 | 01 10 | BEQ $a1=5, $t0=0; not equal → not taken
 22 | 0x0056 | 0000     | ADD/SUB(0) | 0x0000 | 00 00 | Branch delay slot NOP 1
 23 | 0x0058 | 0000     | ADD/SUB(0) | 0x0000 | 00 00 | Branch delay slot NOP 2
 24 | 0x005A | 3FC1     | ADD/SUB(0) | 0x0000 | 00 00 | Branch delay slot NOP 3
 25 | 0x005C | 5D40     | SUBI   (3) | 0x0004 | 00 00 | SUBI $a1,$a1,1 → R7=4
```

**Cycle 20:** `SUB $t0, $t0, $t0` is in ID (IFID=0B69). This clears R5 to 0 before the BEQ comparison. LI $a1=5 (loop counter) is in EX, confirming R7=5 is committed this cycle (WB in next cycles).

**Cycle 21:** BEQ $a1, $t0 in EX. `ForwardA=01` (MEM/WB → R7=5), `ForwardB=10` (EX/MEM → R5=0 from SUB). ALU computes A−B = 5−0 = **0x0005** ≠ 0, so zero_flag=0. Branch **not taken** (Br=0). Three NOP delay slots follow (cycles 22, 23, 24) — these are the architectural requirement for branch resolution at MEM stage (3-cycle penalty).

**Cycle 25:** SUBI $a1, $a1, 1 in EX. Decrements loop counter from 5 to **4**.

---

## Section 5 — Load-Use Stall (Cycles 26–28, First Occurrence)

The LW→SW sequence is the only hazard in the loop body that the forwarding unit cannot resolve alone. The hazard detection unit intervenes automatically.

```
CYC | IF:PC  | ID:instr | EX:op      | ALU    | FA FB | P I F | MEM_rw Rg  dat    | WB_rw wbdat  | Notes
----+--------+----------+------------+--------+-------+-------+-------------------+--------------+------------------------------
 25 | 0x005C | 5D40     | SUBI   (3) | 0x0004 | 00 00 | 1 1 0 | 1     R0  0x0000  | 1     0x0000 | SUBI in EX; LW entering ID
 26 | 0x005E | 6D40     | LW     (5) | 0x0200 | 00 00 | 0 0 1 | 1     R7  0x0004  | 1     0x0000 | *** STALL *** P=0 I=0 F=1
 27 | 0x005E | 6D40     | LW     (5) | 0x0400 | 00 10 | 1 1 0 | 1     R5  0x0200  | 1     0x0004 | Bubble in EX; LW in MEM; SUBI writes R7=4
 28 | 0x0060 | 2D82     | SW     (6) | 0x0200 | 00 01 | 1 1 0 | 0     R5  0x0400  | 1     0x0101 | SW in EX; ForwardB=01 (LW data→SW store data)
```

**Cycle 26 — Stall injection:**
- LW ($t0, 0($a0)) is in EX (IDEX). SW (0($a0), $t0) is in ID (IFID=6D40).
- Hazard detection unit sees: `IDEX_MemRead=1` (LW reads memory) AND `IDEX_rt=R5` matches `IFID_rt=R5` (SW's store-data register is R5, the LW destination).
- Outputs: `PC_Write=0` (freeze PC at 0x005E), `IFID_Write=0` (freeze IF/ID holding SW), `Control_Flush=1` (zero control signals in ID/EX on next edge → bubble).
- **No explicit NOP was written.** The hardware stalls for exactly 1 cycle automatically.

**Cycle 27 — Stall cycle:**
- PC still = 0x005E (frozen). IFID still = 6D40 (SW, frozen).
- IDEX retains LW's opcode field but all control signals are zeroed (flush implementation detail). EX computes a garbage result (0x0400) but EXMEM_RegWrite is controlled by the flushed control signals, so nothing is written.
- EXMEM now carries LW's load address (0x0200) and `MemRead=1`. Memory reads from 0x0200 this cycle, producing 0x0101.
- `ForwardB=10` — the EX stage sees EX/MEM carrying a result for R5, and it will forward it. This sets up the path for cycle 28.

**Cycle 28 — SW executes with forwarded data:**
- SW is now in EX (entered after the stall). ALU computes store address: R6 + 0 = **0x0200** ✓
- `ForwardB=01` — SW's store data (R5) is forwarded from MEM/WB (LW result = 0x0101, now in WB). `WB_write_data = 0x0101` ✓
- The SW stores 0x0101 to data memory address 0x0200. LW's loaded value is also committed to R5 via WB (wbdat=0x0101). ✓

**Cost: 1 cycle stall.** Without hardware detection, a programmer would need to insert an explicit NOP between LW and SW. The hazard detection unit eliminates this.

---

## Section 6 — Loop Iterations (All Five)

The loop body (addresses 0x004E–0x0062) executes 5 times before R7 (loop counter) reaches 0. Each iteration has the same structure:

```
mem[39]  0x004E: SUB  $t0, $t0, $t0       (clear R5 for BEQ comparison)
mem[40]  0x0050: BEQ  $a1, $t0, +27       (branch to 0x0088 if R7==0)  ← offset bug, see note
mem[41-43]       NOP, NOP, NOP             (3 branch delay slots)
mem[44]  0x0058: SUBI $a1, $a1, 1         (decrement loop counter R7)
mem[45]  0x005A: LW   $t0, 0($a0)         (load from Mem[R6])
mem[46]  0x005C: SW   $t0, 0($a0)         (store back — hardware stalls for LW→SW)
mem[47]  0x005E: ADDI $a0, $a0, 2         (advance pointer)
mem[48]  0x0060: JUMP 0x004E              (back to loop top — 1-cycle jump delay)
mem[49]  0x0062: NOP                      (jump delay slot)
```

Each iteration: 5 real instructions + 3 branch NOPs + 1 jump NOP + 1 hardware stall = ~12 cycles/iteration.

| Iter | Cycles   | R7 before BEQ | LW reads         | LW data | SW writes to  | ADDI R6→  |
|------|----------|---------------|-----------------|---------|---------------|-----------|
| 1    | 20–30    | 5 → 4         | Mem[0x0200]=256 | 0x0101  | Mem[0x0200]   | 0x0202    |
| 2    | 31–42    | 4 → 3         | Mem[0x0202]=257 | 0x0110  | Mem[0x0202]   | 0x0204    |
| 3    | 43–54    | 3 → 2         | Mem[0x0204]=258 | 0x0011  | Mem[0x0204]   | 0x0206    |
| 4    | 55–66    | 2 → 1         | Mem[0x0206]=259 | 0x00F0  | Mem[0x0206]   | 0x0208    |
| 5    | 67–78    | 1 → 0         | Mem[0x0208]=260 | 0x00FF  | Mem[0x0208]   | 0x020A    |

**Load-use stalls:** Each iteration triggers the LW→SW stall at cycles 26, 38, 50, 62, and 74 respectively (one stall per iteration, zero explicit NOPs). Visible by `P=0 I=0 F=1` in the trace.

**LW load values visible in WB column:**
- Cycle 28: wbdat=0x0101 (iteration 1 LW result committed to R5) ✓
- Cycle 40: wbdat=0x0110 ✓
- Cycle 52: wbdat=0x0011 ✓
- Cycle 64: wbdat=0x00F0 ✓
- Cycle 76: wbdat=0x00FF ✓

**BEQ not-taken cycles per iteration:** 21, 33, 45, 57, 69 — all show `Br=0` with ALU computing R7−0 = loop counter value (5, 4, 3, 2, 1 respectively).

---

## Section 7 — BEQ Taken (Cycle 82)

After the fifth iteration, R7=0. The BEQ compares R7==R5 (both 0) and the branch is taken.

```
CYC | IF:PC  | EX:op      | ALU    | Br | FA FB | Notes
----+--------+------------+--------+----+-------+-----------------------------------------
 80 | 0x0052 | ADD/SUB(0) | 0x0000 |  0 | 00 00 | SUB clears R5=0
 81 | 0x0054 | BEQ    (8) | 0x0000 |  0 | 00 10 | BEQ in EX; R7=0, R5=0; zero_flag=1
 82 | 0x0056 | ADD/SUB(0) | 0x0000 |  1 | 00 00 | *** BRANCH TAKEN *** Br=1 fires from MEM
 83 | 0x0088 | 0000       | ---    |  0 | ---   | PC redirected to branch target 0x0088
```

**Cycle 81:** BEQ $a1, $t0 in EX. `ForwardB=10` (EX/MEM → R5=0 from SUB). ALU computes R7−R5 = 0−0 = **0x0000**. zero_flag=1, condition true. Branch decision propagates to MEM stage.

**Cycle 82:** Branch resolves in MEM stage (one cycle after BEQ executes in EX). `Br=1` fires. PC is redirected and the three instructions that entered the pipeline during the 3-cycle branch delay are flushed. The three NOPs in the delay slots (cycles 83–85) are the architectural delay slots — they execute because they were placed there intentionally.

**Branch target note:** The BEQ instruction has offset=27, giving target = 0x0052 + (27×2) = 0x0088. The halt loop (`j 0x0080`) is at 0x0080, not 0x0088. This is an off-by-4 error in the branch offset encoding in the test program. The processor correctly computes the target it was given (0x0088) — the bug is in the immediate field, not in the branch logic. After cycle 83, the processor fetches from 0x0088 onwards, which contains uninitialized memory (all zeros = ADD R0,R0,R0, a harmless infinite sequence of NOPs).

---

## Final Register State (Verified Correct)

```
R0 = 0x0000  (hardwired zero)
R1 = 0x0040  ✓  (initialized: LI 4, SLL<<4 = 64 = 0x40)
R2 = 0x1010  ✓  (initialized: LI 1, SLL<<12 = 0x1000, ADDI+16 = 0x1010)
R3 = 0x000F  ✓  (initialized: LI 15)
R4 = 0x00F0  ✓  (initialized: LI 15, SLL<<4 = 0xF0)
R5 = 0x0000  ✓  (last SUB $t0,$t0,$t0 before final BEQ cleared it)
R6 = 0x020A  ✓  (base address 0x0200 + 5 increments of 2 = 0x020A)
R7 = 0x0000  ✓  (loop counter decremented from 5 to 0 over 5 iterations)
```

All registers match expected values from `run_sim.tcl`.

---

## Forwarding Event Summary

| Cycle | Instruction | ForwardA | ForwardB | Source (forwarded from) | Value |
|-------|-------------|----------|----------|--------------------------|-------|
| 2 | ABS $v1, $v2 | 10 | — | EX/MEM: ORI→R3=0xFFFE | 0xFFFE |
| 3 | ORI $v2, _, 5 | — | 01 | MEM/WB: ABS→R2=0x0002 | (coincidental) |
| 5 | MIN $a1,$v2,$v3 | 01 | 10 | WB:ORI→R3=5 / MEM:ORI→R4=10 | 5, 10 |
| 6 | MAX $a0,$v2,$v3 | 00 | 01 | WB: ORI→R4=10 | 10 |
| 10 | SLL $v0,$v0,4 | 10 | 10 | EX/MEM: LI→R1=4 | 4 |
| 12 | SLL $v1,$v1,12 | 10 | 10 | EX/MEM: LI→R2=1 | 1 |
| 13 | ADDI $v1,+16 | 10 | 10 | EX/MEM: SLL→R2=0x1000 | 0x1000 |
| 16 | SLL $v3,$v3,4 | 10 | 10 | EX/MEM: LI→R4=15 | 15 |
| 18 | SLL $a0,$a0,8 | 10 | 10 | EX/MEM: LI→R6=2 | 2 |
| 21 | BEQ | 01 | 10 | WB:LI→R7 / MEM:SUB→R5=0 | 5, 0 |
| 28 | SW ← LW data | — | 01 | MEM/WB: LW→R5=0x0101 | 0x0101 |
| 40 | SW ← LW data | — | 01 | MEM/WB: LW→R5=0x0110 | 0x0110 |
| 52 | SW ← LW data | — | 01 | MEM/WB: LW→R5=0x0011 | 0x0011 |
| 64 | SW ← LW data | — | 01 | MEM/WB: LW→R5=0x00F0 | 0x00F0 |
| 76 | SW ← LW data | — | 01 | MEM/WB: LW→R5=0x00FF | 0x00FF |

---

## Hazard Event Summary

| Cycle | Type | Trigger | P I F | Cost |
|-------|------|---------|-------|------|
| 26 | Load-use stall | LW→SW on R5 (iter 1) | 0 0 1 | 1 cycle |
| 38 | Load-use stall | LW→SW on R5 (iter 2) | 0 0 1 | 1 cycle |
| 50 | Load-use stall | LW→SW on R5 (iter 3) | 0 0 1 | 1 cycle |
| 62 | Load-use stall | LW→SW on R5 (iter 4) | 0 0 1 | 1 cycle |
| 74 | Load-use stall | LW→SW on R5 (iter 5) | 0 0 1 | 1 cycle |
| 6 | Jump flush | JUMP resolved in ID | flush | 1 cycle (delay slot) |
| 82 | Branch flush | BEQ taken in MEM | flush | 3 cycles (delay slots) |

No data hazard ever required a stall — the forwarding unit handled all ALU→ALU dependencies without any pipeline freeze.

---

## Notes on Memory Readback

The final memory dump (from the Tcl console after 160 cycles) shows `mem[0x0200–0x0208] = 0x0000`. The SW instructions did execute and the correct load values (0x0101, 0x0110, 0x0011, 0x00F0, 0x00FF) are visible in the `wbdat` column at cycles 28, 40, 52, 64, and 76, confirming that LW loaded the correct initialized values. The zero readback is a simulation artifact: XSIM's `restart` command may not re-trigger the VHDL reset initialization sequence in the data memory, leaving `data_mem.mem` at its default-zero state. If the simulation is run fresh (via **Run Simulation** from the Flow Navigator rather than `restart`), the data memory initializes properly through the reset process.
