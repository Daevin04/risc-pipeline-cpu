# =================================================================
# Pipeline Cycle-by-Cycle Signal Dump
# Usage: source scripts/dump_pipeline.tcl
#   (run from Vivado Tcl console after opening behavioral simulation)
# Output: Paste full console output into analysis document
# =================================================================

restart

# Sample 1 ns past each rising edge so delta cycles have settled.
# Reset releases at 20 ns; first active rising edge is at 25 ns.
run 26 ns

# ---- helper: get signal as uppercase hex string (no 0x prefix) ----
proc hx {sig} {
    return [string toupper [get_value -radix hex $sig]]
}
proc bn {sig} {
    return [get_value -radix bin $sig]
}
proc ud {sig} {
    return [get_value -radix unsigned $sig]
}

# ---- opcode lookup table (matches processor_pkg.vhd constants) ----
proc op_name {op4} {
    switch $op4 {
        "0" { return "ADD/SUB" }
        "1" { return "SLT/XOR" }
        "2" { return "ADDI   " }
        "3" { return "SUBI   " }
        "4" { return "ORI    " }
        "5" { return "LW     " }
        "6" { return "SW     " }
        "7" { return "SLTI   " }
        "8" { return "BEQ    " }
        "9" { return "BNE    " }
        "A" { return "JUMP   " }
        "B" { return "LI     " }
        "C" { return "ABS    " }
        "D" { return "MIN    " }
        "E" { return "MAX    " }
        "F" { return "SLL    " }
        default { return "??     " }
    }
}

puts ""
puts "==========================================================================================================================="
puts "PIPELINE CYCLE-BY-CYCLE DUMP  |  Clock: 10 ns  |  All values hex unless noted"
puts "==========================================================================================================================="
puts [format "%-3s | %-6s | %-8s | %-8s | %-7s | %-14s | %-6s | %-2s %-2s | %-1s %-1s %-1s | %-5s R%-1s %-6s | %-5s %-6s" \
    "CYC" \
    "IF:PC " \
    "ID:instr" \
    "EX:op   " \
    "EX:rs rt" \
    "  ->rd  ALU   " \
    "Br/Jmp" \
    "FA" "FB" \
    "P" "I" "F" \
    "MEM_rw" "g" "dat   " \
    "WB_rw" "wbdat "]
puts [string repeat "-" 145]

set cycle 0
set halt_count 0

while {$cycle < 160} {

    set pc        [hx /testbench/PC]
    set ifid_raw  [hx /testbench/uut/dp/IFID_instruction]
    set ex_op_hex [hx /testbench/uut/dp/IDEX_opcode]
    set ex_name   [op_name $ex_op_hex]
    set rs        [ud /testbench/uut/dp/IDEX_rs]
    set rt        [ud /testbench/uut/dp/IDEX_rt]
    set rd        [ud /testbench/uut/dp/IDEX_rd]
    set alu_res   [hx /testbench/uut/dp/EX_alu_result]
    set fa        [bn /testbench/uut/dp/ForwardA]
    set fb        [bn /testbench/uut/dp/ForwardB]
    set pc_wr     [bn /testbench/uut/dp/PC_Write_Enable]
    set ifid_wr   [bn /testbench/uut/dp/IFID_Write_Enable]
    set ctrl_fl   [bn /testbench/uut/dp/Control_Flush_Signal]
    set br_taken  [bn /testbench/uut/dp/MEM_branch_taken]
    set exmem_rw  [bn /testbench/uut/dp/EXMEM_RegWrite]
    set exmem_rg  [ud /testbench/uut/dp/EXMEM_write_reg]
    set exmem_dat [hx /testbench/uut/dp/EXMEM_alu_result]
    set memwb_rw  [bn /testbench/uut/dp/MEMWB_RegWrite]
    set wb_dat    [hx /testbench/uut/dp/WB_write_data]

    puts [format "%-3d | 0x%-4s | %-8s | %s(%s) | R%s,R%s | ->R%s  0x%-4s | Br=%s  | %-2s %-2s | %s %s %s | %-5s R%s 0x%-4s | %-5s 0x%-4s" \
        $cycle \
        $pc \
        $ifid_raw \
        $ex_name $ex_op_hex \
        $rs $rt \
        $rd $alu_res \
        $br_taken \
        $fa $fb \
        $pc_wr $ifid_wr $ctrl_fl \
        $exmem_rw $exmem_rg $exmem_dat \
        $memwb_rw $wb_dat]

    if {$pc eq "0080"} {
        incr halt_count
        if {$halt_count >= 4} {
            puts [string repeat "-" 145]
            puts ">>> HALT LOOP REACHED at cycle $cycle - stopping dump"
            break
        }
    }

    run 10 ns
    incr cycle
}

puts ""
puts "==========================================================================================================================="
puts "FINAL REGISTER FILE STATE"
puts "==========================================================================================================================="
for {set i 0} {$i <= 7} {incr i} {
    puts "  R$i = 0x[hx /testbench/uut/dp/reg_file/registers($i)]"
}

puts ""
puts "==========================================================================================================================="
puts "FINAL DATA MEMORY STATE (loop results)"
puts "==========================================================================================================================="
puts "  mem\[0x0200\] = 0x[hx /testbench/uut/data_mem/mem(256)]  (expect 0x0101)"
puts "  mem\[0x0202\] = 0x[hx /testbench/uut/data_mem/mem(257)]  (expect 0x0110)"
puts "  mem\[0x0204\] = 0x[hx /testbench/uut/data_mem/mem(258)]  (expect 0x0011)"
puts "  mem\[0x0206\] = 0x[hx /testbench/uut/data_mem/mem(259)]  (expect 0x00F0)"
puts "  mem\[0x0208\] = 0x[hx /testbench/uut/data_mem/mem(260)]  (expect 0x00FF)"
puts "==========================================================================================================================="
