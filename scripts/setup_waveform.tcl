# =============================================================================
# WAVEFORM CONFIGURATION FOR LAB 4 PHASE 3 DEMO
# Sets up all important signals for visual demonstration
# =============================================================================
#
# Usage: Source this file after launching simulation
#   launch_simulation
#   source setup_waveform.tcl
#
# =============================================================================

puts "========================================================================="
puts "SETTING UP WAVEFORM SIGNALS FOR DEMONSTRATION"
puts "========================================================================="
puts ""

# Note: Vivado XSim doesn't support -divider, so signals are grouped by comments
puts "Adding signals to waveform..."

# ============ GROUP 1: Clock and Control ============
puts "  [1/8] Clock and Control signals..."
add_wave /testbench/clk
add_wave /testbench/reset
add_wave /testbench/cycle_count

# ============ GROUP 2: Program Counter ============
puts "  [2/8] Program Counter and Branch Logic..."
add_wave -radix hex /testbench/PC
add_wave -radix hex /testbench/uut/dp/IF_PC_plus_2
add_wave /testbench/uut/dp/MEM_branch_taken
add_wave /testbench/uut/dp/EXMEM_Jump
add_wave -radix hex /testbench/uut/dp/EXMEM_branch_target
add_wave -radix hex /testbench/uut/dp/MEM_jump_target

# ============ GROUP 3: Pipeline Stage Instructions ============
puts "  [3/8] Pipeline Stage Instructions..."
add_wave -radix hex /testbench/uut/dp/IFID_instruction
add_wave -radix hex /testbench/uut/dp/IDEX_opcode
add_wave -radix hex /testbench/uut/dp/ID_opcode

# ============ GROUP 4: Register File (All 8 Registers) ============
puts "  [4/8] Register File (R0-R7)..."
add_wave -radix hex /testbench/uut/dp/reg_file/registers(0)
add_wave -radix hex /testbench/uut/dp/reg_file/registers(1)
add_wave -radix hex /testbench/uut/dp/reg_file/registers(2)
add_wave -radix hex /testbench/uut/dp/reg_file/registers(3)
add_wave -radix hex /testbench/uut/dp/reg_file/registers(4)
add_wave -radix hex /testbench/uut/dp/reg_file/registers(5)
add_wave -radix hex /testbench/uut/dp/reg_file/registers(6)
add_wave -radix hex /testbench/uut/dp/reg_file/registers(7)

# ============ GROUP 5: ALU Signals ============
puts "  [5/8] ALU signals..."
add_wave -radix hex /testbench/uut/dp/alu_unit/operand_a
add_wave -radix hex /testbench/uut/dp/alu_unit/operand_b
add_wave -radix hex /testbench/uut/dp/alu_unit/result
add_wave /testbench/uut/dp/alu_unit/zero_flag
add_wave -radix hex /testbench/uut/dp/alu_unit/alu_control

# ============ GROUP 6: Control Signals ============
puts "  [6/8] Control signals..."
add_wave /testbench/uut/dp/ID_Branch
add_wave /testbench/uut/dp/ID_Jump
add_wave /testbench/uut/dp/ID_MemRead
add_wave /testbench/uut/dp/ID_MemWrite
add_wave /testbench/uut/dp/ID_RegWrite
add_wave /testbench/uut/dp/ID_ALUSrc
add_wave /testbench/uut/dp/EXMEM_zero_flag
add_wave /testbench/uut/dp/EXMEM_Branch
add_wave /testbench/uut/dp/IDEX_Branch

# ============ GROUP 7: Memory Access ============
puts "  [7/8] Memory signals..."
add_wave -radix hex /testbench/uut/data_mem/address
add_wave -radix hex /testbench/uut/data_mem/write_data
add_wave -radix hex /testbench/uut/data_mem/read_data
add_wave /testbench/uut/data_mem/mem_write
add_wave /testbench/uut/data_mem/mem_read

# ============ GROUP 8: Loop Critical Signals (Highlighted) ============
puts "  [8/8] Loop critical signals (R5, R6, R7)..."
add_wave -radix hex /testbench/uut/dp/reg_file/registers(5)
add_wave -radix hex /testbench/uut/dp/reg_file/registers(6)
add_wave -radix hex /testbench/uut/dp/reg_file/registers(7)

puts ""
puts "========================================================================="
puts "WAVEFORM SETUP COMPLETE"
puts "========================================================================="
puts ""
puts "Signal groups added (in order):"
puts "  1. Clock and Control (clk, reset, cycle_count)"
puts "  2. Program Counter & Branch Logic (PC, branch_taken, jump)"
puts "  3. Pipeline Stage Instructions (IFID, IDEX opcodes)"
puts "  4. Register File R0-R7 (all in hex)"
puts "  5. ALU Operations (operands, result, zero_flag, control)"
puts "  6. Control Signals (Branch, Jump, MemRead, MemWrite, RegWrite)"
puts "  7. Memory Access (address, write_data, read_data, control)"
puts "  8. Loop Critical Signals (R5, R6, R7 duplicated for easy viewing)"
puts ""
puts "DEMO TIPS:"
puts "  - Watch R7 decrement from 5 to 0 (loop counter)"
puts "  - Watch R6 increment by 2 each iteration (memory pointer)"
puts "  - Watch R5 get cleared then loaded each iteration (temp value)"
puts "  - Watch MEM_branch_taken go high when loop exits"
puts "  - Watch zero_flag when BEQ compares R7 with R5"
puts ""
puts "Recommended cursor positions for demo:"
puts "  -  525 ns : After custom instruction tests (Checkpoint 1)"
puts "  - 1225 ns : After loop initialization (Checkpoint 2)"
puts "  - 1505 ns : After first loop iteration (Checkpoint 3)"
puts "  - 2065 ns : After 2nd iteration (Checkpoint 4 start)"
puts "  - 2865 ns : Final halt state (Checkpoint 5)"
puts ""
puts "Use Vivado's zoom and cursor features to navigate between checkpoints!"
puts "========================================================================="
puts ""
