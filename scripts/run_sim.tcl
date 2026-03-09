# =================================================================
# Lab 4 Phase 3 - Automated Simulation Script for Vivado XSim
# Runs simulation and displays loop test results
# =================================================================

puts "========================================"
puts "LAB 4 PROCESSOR SIMULATION"
puts "========================================"
puts ""

# Check initial PC
puts "Initial PC: [get_value /testbench/PC]"
puts ""

# Run complete simulation (6000 ns)
puts "Running simulation to completion (6000 ns)..."
run 6000 ns

puts ""
puts "========================================="
puts "FINAL RESULTS - LOOP TEST"
puts "========================================="
puts ""

puts "=== ALL REGISTERS ==="
puts "R0 (zero): [get_value /testbench/uut/dp/reg_file/registers(0)]"
puts "R1 (v0) - expect 0x0040: [get_value /testbench/uut/dp/reg_file/registers(1)]"
puts "R2 (v1) - expect 0x1010: [get_value /testbench/uut/dp/reg_file/registers(2)]"
puts "R3 (v2) - expect 0x000F: [get_value /testbench/uut/dp/reg_file/registers(3)]"
puts "R4 (v3) - expect 0x00F0: [get_value /testbench/uut/dp/reg_file/registers(4)]"
puts "R5 (t0) - expect 0x00FF: [get_value /testbench/uut/dp/reg_file/registers(5)]"
puts "R6 (a0) - expect 0x010A: [get_value /testbench/uut/dp/reg_file/registers(6)]"
puts "R7 (a1) - expect 0x0000: [get_value /testbench/uut/dp/reg_file/registers(7)]"

puts ""
puts "=== MEMORY VALUES ==="
puts "mem 256 (0x0200) - expect 0x0101: [get_value /testbench/uut/data_mem/mem(256)]"
puts "mem 257 (0x0202) - expect 0x0110: [get_value /testbench/uut/data_mem/mem(257)]"
puts "mem 258 (0x0204) - expect 0x0011: [get_value /testbench/uut/data_mem/mem(258)]"
puts "mem 259 (0x0206) - expect 0x00F0: [get_value /testbench/uut/data_mem/mem(259)]"
puts "mem 260 (0x0208) - expect 0x00FF: [get_value /testbench/uut/data_mem/mem(260)]"

puts ""
puts "=== PROGRAM COUNTER ==="
puts "PC - expect 0x012A: [get_value /testbench/PC]"

puts ""
puts "========================================="
puts "EXPECTED VALUES:"
puts "  R1=0x0040 R2=0x1010 R3=0x000F R4=0x00F0"
puts "  R5=0x0000 R6=0x020A R7=0x0000"
puts "  Mem: 0x0101 0x0110 0x0011 0x00F0 0x00FF"
puts "  PC=0x012A (or nearby due to pipeline delay)"
puts "========================================="
puts ""
