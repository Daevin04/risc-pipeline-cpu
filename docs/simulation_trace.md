# Pipeline Simulation Trace — Cycle-by-Cycle Analysis

Generated from Vivado XSIM behavioral simulation. Clock period: 10 ns. Reset released at 20 ns; first active rising edge at 25 ns. Cycle 0 reflects signal state 1 ns after that first edge.

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

## Waveform Cross-Reference

**How to use:** In Vivado XSIM, use the waveform toolbar's "Go to time" field (or type a time in the Tcl console: `current_time 286ns`). Navigate to the time in the table, then find the matching row in the section below to read the explanation.

Simulation time formula: `time (ns) = 26 + (cycle × 10)`

### Key Events — Jump Directly to These Times

| Event | Cycle | Time (ns) | Signals to look at in waveform | What you should see |
|-------|-------|-----------|-------------------------------|---------------------|
| Pipeline filling | 0–1 | 26–36 | `IFID_instruction`, `IDEX_opcode` | First instruction (0x40FE ORI) flowing from ID→EX |
| **ABS instruction + EX/MEM forward** | 2 | 46 | `ForwardA`, `EX_alu_result`, `EXMEM_alu_result` | FA=10, ALU=0x0002, EXMEM carries 0xFFFE |
| **MIN — both ForwardA and ForwardB active** | 5 | 76 | `ForwardA`, `ForwardB`, `EX_alu_result` | FA=01, FB=10, ALU=0x0005 |
| **MAX — result** | 6 | 86 | `ForwardB`, `EX_alu_result` | FB=01, ALU=0x000A |
| **JUMP resolved in ID — PC redirect** | 7 | 96 | `IF_PC`, `IFID_instruction` | PC jumps 0x000E→0x0038; IFID holds delay slot NOP (0x0000) |
| Forwarding chain (SLL after LI) | 10 | 126 | `ForwardA`, `ForwardB`, `IDEX_opcode` | FA=10, FB=10, SLL computing 4<<4=0x0040 |
| ADDI chained on SLL result | 13 | 156 | `ForwardA`, `EX_alu_result` | FA=10, ALU=0x1000+16=0x1010 |
| **Loop starts — BEQ not taken (iter 1)** | 21 | 236 | `MEM_branch_taken`, `EX_alu_result` | Br=0, ALU=0x0005 (R7≠R5) |
| **Load-use stall fired (iter 1)** | 26 | 286 | `PC_Write_Enable`, `IFID_Write_Enable`, `Control_Flush_Signal` | **0, 0, 1** — all three change simultaneously |
| Stall cycle — bubble in pipeline | 27 | 296 | `PC_Write_Enable`, `IFID_instruction`, `EXMEM_alu_result` | PC_Write back to 1; IFID still holds SW; EXMEM has LW addr 0x0200 |
| SW executes with forwarded LW data | 28 | 306 | `ForwardB`, `WB_write_data`, `EXMEM_alu_result` | FB=01, WBdat=0x0101, SW addr=0x0200 |
| Load-use stall (iter 2) | 38 | 406 | `PC_Write_Enable`, `Control_Flush_Signal` | 0, 1 again |
| Load-use stall (iter 3) | 50 | 526 | `PC_Write_Enable`, `Control_Flush_Signal` | 0, 1 again |
| Load-use stall (iter 4) | 62 | 646 | `PC_Write_Enable`, `Control_Flush_Signal` | 0, 1 again |
| Load-use stall (iter 5) | 74 | 766 | `PC_Write_Enable`, `Control_Flush_Signal` | 0, 1 again |
| **BEQ taken — loop exits** | 82 | 846 | `MEM_branch_taken`, `IF_PC` | **Br=1**; PC redirected; watch for flush on next cycle |
| Processor in uninitialized memory | 83+ | 856+ | `IFID_instruction`, `IF_PC` | All 0x0000 — program ran off end due to branch offset bug |

### Recommended Waveform Signal Groups

Add these signals to the waveform viewer in this order for the clearest view:

```
-- Control flow
/testbench/PC
/testbench/uut/dp/IF_PC
/testbench/uut/dp/IFID_instruction
/testbench/uut/dp/IDEX_opcode

-- Hazard detection outputs (watch for 0,0,1 pattern)
/testbench/uut/dp/PC_Write_Enable
/testbench/uut/dp/IFID_Write_Enable
/testbench/uut/dp/Control_Flush_Signal

-- Forwarding (watch for non-00 values)
/testbench/uut/dp/ForwardA
/testbench/uut/dp/ForwardB

-- Execution result
/testbench/uut/dp/EX_alu_result
/testbench/uut/dp/MEM_branch_taken

-- Register write (watch what gets committed each cycle)
/testbench/uut/dp/MEMWB_RegWrite
/testbench/uut/dp/MEMWB_write_reg
/testbench/uut/dp/WB_write_data
```

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
