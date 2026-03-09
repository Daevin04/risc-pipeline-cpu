# Lessons Learned

## Design Decisions

### Why resolve jumps in ID instead of MEM?

The naive implementation resolves branches and jumps in the MEM stage, where the full branch condition and target address are available. This incurs a 3-cycle penalty: the three instructions after the jump enter the pipeline before the jump is detected, and they must all be flushed.

For unconditional jumps, the target address is available as soon as the instruction is decoded — no ALU computation is needed. By moving jump resolution to the ID stage, the penalty drops from 3 cycles to 1 cycle (only the instruction in IF needs to be flushed). Across the test program with multiple jump instructions, this saved 2 NOPs per jump.

Branches remain resolved in MEM because the branch condition depends on the ALU zero flag, which is not available until after EX.

### Why write-through forwarding in the register file?

The register file was designed with synchronous write and asynchronous read. Without additional logic, there is a one-cycle window where a register being written cannot be read at the same time (the read sees the old value). Adding write-through forwarding inside the register file (if the read address matches the write address and write is enabled, forward the new value) eliminates this hazard at the register file boundary. This simplifies the main forwarding unit, which only needs to handle EX-stage hazards (instructions in flight past the register file stage).

### Why is the ID/EX register the most complex?

The ID/EX register carries more signals than any other pipeline register because the ID stage generates the most information: all control signals, two register values, the immediate, the sign-extended immediate, register addresses for forwarding checks, and the function code for ALU control. The width of this register is effectively a measure of the cost of the ID stage.

---

## Bugs Encountered

### Stall and flush occurring simultaneously

**Symptom:** When a load-use hazard was detected on the same cycle as a branch taken, the hazard detection unit and the flush logic would interact incorrectly. The pipeline register was being both frozen and flushed, producing wrong results.

**Root cause:** Stall (from the hazard detection unit) was not given explicit priority over flush (from MEM branch taken). Both signals were active simultaneously and the register received conflicting updates.

**Fix:** Added priority logic: if `PC_Write_Enable = 0` (stall active), the flush signals from MEM are suppressed for that cycle. Stall takes priority because the branch instruction itself has not yet exited the pipeline correctly.

### Missing signals in combinational process sensitivity lists

**Symptom:** Simulation was correct but Vivado synthesis reported latches on combinational signals in the control unit and forwarding unit.

**Root cause:** Several `process` blocks in VHDL had incomplete sensitivity lists. When a signal was used inside a `process` but not listed in the sensitivity list, VHDL simulation does not re-evaluate the process when that signal changes, effectively inferring a latch.

**Fix:** Added all driving signals to sensitivity lists. Alternatively, using `process (all)` in VHDL-2008 would avoid this class of bug entirely.

### Jump to wrong target after pipelining

**Symptom:** After moving jump resolution from MEM to ID, the processor jumped to incorrect addresses.

**Root cause:** The jump target calculation was left in the MEM-stage datapath, but the PC was being updated from the ID stage. The two computations were using different pipeline-stage values of the jump address field.

**Fix:** Moved the jump target multiplexer and the jump address extraction entirely into the ID-stage logic of `datapath_pipelined.vhd`. The jump address is now computed from the IF/ID register output (the raw instruction word), not from a pipeline-delayed value.

### Load-use stall not firing for SW after LW

**Symptom:** A `LW` followed immediately by `SW` using the loaded value produced incorrect memory writes.

**Root cause:** The hazard detection unit was checking `IDEX_rt == IFID_rs` and `IDEX_rt == IFID_rt`, but the `SW` instruction uses its `rt` field as the data source and `rs` as the base address. The check correctly caught `IFID_rt` but the specific encoding of `SW` placed the dependent register in `rt`, which was being matched. The bug was actually a case where the check was working but the forwarding path for the SW data input was not selecting the stall output correctly.

**Fix:** Verified that the forwarding unit's `ForwardB` signal also applies to the data input of SW (not just the ALU B input). The data being stored also needs to come from the forwarded value, not the stale register file output.

---

## What I Would Do Differently

1. **Resolve branches earlier.** Moving branch resolution to the EX stage (compare register values in EX instead of checking the ALU zero flag from EX in MEM) would reduce the branch penalty from 3 to 2 cycles. Resolving in ID (with early comparison hardware) would bring it to 1.

2. **Use VHDL-2008 `process (all)`.** Every combinational process should use `process (all)` instead of manually maintained sensitivity lists. The manual lists are a recurring source of simulation-synthesis mismatch bugs.

3. **Separate instruction and data memories from the start.** Early phases of the project used a unified memory, which complicated the address space and required careful partitioning. Starting with separate instruction ROM and data RAM would have simplified the datapath.

4. **Write a self-checking testbench.** The current testbench requires manual inspection of the Tcl console output. A proper self-checking testbench that prints PASS/FAIL and returns a non-zero exit code on failure would make regression testing faster and more reliable.
