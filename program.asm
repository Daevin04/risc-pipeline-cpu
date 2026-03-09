# =============================================================================
# LAB 4 PHASE 3 - COMPLETE MIPS ASSEMBLY PROGRAM
# 5-Stage Pipelined RISC Processor Test Program
# =============================================================================
#
# This program tests:
#   - 3 custom BONUS instructions (ABS, MIN, MAX)
#   - All standard RISC instructions
#   - Loop with branch and jump
#   - Memory load/store operations
#   - Pipeline hazard handling with software NOPs
#
# Register Usage:
#   R0 ($zero) - Always 0
#   R1 ($v0)   - Test result / loop variable
#   R2 ($v1)   - Test result / loop variable
#   R3 ($v2)   - Test value for custom instructions
#   R4 ($v3)   - Test value for custom instructions
#   R5 ($t0)   - Temporary / loop data
#   R6 ($a0)   - Memory base address pointer
#   R7 ($a1)   - Loop counter
#
# =============================================================================

.text
.globl main

# =============================================================================
# SECTION 1: CUSTOM INSTRUCTION TESTS (BONUS +10%)
# =============================================================================

main:
    # ---------------------------------------------------------------------
    # Test 1: ABS (Absolute Value)
    # ---------------------------------------------------------------------
    # Address: 0x0000 (mem[0])
    ori     $v2, $zero, -2          # $v2 = -2 (0xFFFE in 16-bit)
    nop                             # Hazard handling NOPs (7 total)
    nop
    nop
    nop
    nop
    nop
    nop

    # Address: 0x0010 (mem[8])
    abs     $v1, $v2                # $v1 = |$v2| = |-2| = 2 (CUSTOM INSTRUCTION)
    nop                             # Hazard handling NOPs (7 total)
    nop
    nop
    nop
    nop
    nop
    nop

    # Expected: $v1 (R2) = 0x0002

    # ---------------------------------------------------------------------
    # Test 2: MIN (Minimum)
    # ---------------------------------------------------------------------
    # Address: 0x0020 (mem[16])
    ori     $v2, $zero, 5           # $v2 = 5
    nop                             # Hazard handling NOPs (7 total)
    nop
    nop
    nop
    nop
    nop
    nop

    # Address: 0x0030 (mem[24])
    ori     $v3, $zero, 10          # $v3 = 10
    nop                             # Hazard handling NOPs (7 total)
    nop
    nop
    nop
    nop
    nop
    nop

    # Address: 0x0040 (mem[32])
    min     $a1, $v2, $v3           # $a1 = min(5, 10) = 5 (CUSTOM INSTRUCTION)
    nop                             # Hazard handling NOPs (7 total)
    nop
    nop
    nop
    nop
    nop
    nop

    # Expected: $a1 (R7) = 0x0005

    # ---------------------------------------------------------------------
    # Test 3: MAX (Maximum)
    # ---------------------------------------------------------------------
    # Address: 0x0050 (mem[40])
    max     $a0, $v2, $v3           # $a0 = max(5, 10) = 10 (CUSTOM INSTRUCTION)
    nop                             # Hazard handling NOPs (7 total)
    nop
    nop
    nop
    nop
    nop
    nop

    # Expected: $a0 (R6) = 0x000A

    # ---------------------------------------------------------------------
    # Jump to Loop Test Section
    # ---------------------------------------------------------------------
    # Address: 0x0060 (mem[48])
    j       loop_init               # Jump to loop initialization
    nop                             # Jump delay slots (3 total)
    nop
    nop


# =============================================================================
# SECTION 2: LOOP INITIALIZATION
# =============================================================================

loop_init:
    # ---------------------------------------------------------------------
    # Initialize $v0 = 0x0040
    # ---------------------------------------------------------------------
    # Address: 0x0078 (mem[60])
    li      $v0, 4                  # $v0 = 4
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # Address: 0x0082 (mem[65])
    sll     $v0, $v0, 4             # $v0 = 4 << 4 = 0x40
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # ---------------------------------------------------------------------
    # Initialize $v1 = 0x1010
    # ---------------------------------------------------------------------
    # Address: 0x008C (mem[70])
    li      $v1, 1                  # $v1 = 1
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # Address: 0x0096 (mem[75])
    sll     $v1, $v1, 12            # $v1 = 1 << 12 = 0x1000
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # Address: 0x00A0 (mem[80])
    addi    $v1, $v1, 16            # $v1 = 0x1000 + 16 = 0x1010
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # ---------------------------------------------------------------------
    # Initialize $v2 = 0x000F
    # ---------------------------------------------------------------------
    # Address: 0x00AA (mem[85])
    li      $v2, 15                 # $v2 = 15 = 0x000F
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # ---------------------------------------------------------------------
    # Initialize $v3 = 0x00F0
    # ---------------------------------------------------------------------
    # Address: 0x00B4 (mem[90])
    li      $v3, 15                 # $v3 = 15
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # Address: 0x00BE (mem[95])
    sll     $v3, $v3, 4             # $v3 = 15 << 4 = 0xF0
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # ---------------------------------------------------------------------
    # Initialize $a0 = 0x0200 (memory base address)
    # ---------------------------------------------------------------------
    # Address: 0x00C8 (mem[100])
    li      $a0, 2                  # $a0 = 2
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # Address: 0x00D2 (mem[105])
    sll     $a0, $a0, 8             # $a0 = 2 << 8 = 0x200
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # ---------------------------------------------------------------------
    # Initialize $a1 = 5 (loop counter)
    # ---------------------------------------------------------------------
    # Address: 0x00DC (mem[110])
    li      $a1, 5                  # $a1 = 5 (loop will run 5 times)
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop


# =============================================================================
# SECTION 3: MAIN LOOP - Load and Store Test
# =============================================================================
# This loop:
#   - Iterates 5 times (counter in $a1)
#   - Loads a word from memory at address $a0
#   - Stores it back to the same address
#   - Increments the address pointer by 2 (word size)
#   - Tests: LW, SW, BEQ, SUBI, ADDI, JUMP, and branch logic
# =============================================================================

loop_start:
    # Address: 0x00E6 (mem[115])
    # ---------------------------------------------------------------------
    # Clear temporary register $t0
    # ---------------------------------------------------------------------
    sub     $t0, $t0, $t0           # $t0 = 0 (clear register)
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # Address: 0x00F0 (mem[120])
    # ---------------------------------------------------------------------
    # Check if loop counter reached zero
    # ---------------------------------------------------------------------
    beq     $a1, $t0, done          # if ($a1 == 0) goto done
    nop                             # Branch delay slots (3 total)
    nop                             # Branch decision in MEM stage
    nop

    # Address: 0x00F8 (mem[124])
    # ---------------------------------------------------------------------
    # Decrement loop counter
    # ---------------------------------------------------------------------
    subi    $a1, $a1, 1             # $a1 = $a1 - 1
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # Address: 0x0102 (mem[129])
    # ---------------------------------------------------------------------
    # Load word from memory
    # ---------------------------------------------------------------------
    lw      $t0, 0($a0)             # $t0 = memory[$a0 + 0]
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # Address: 0x010C (mem[134])
    # ---------------------------------------------------------------------
    # Store word back to memory
    # ---------------------------------------------------------------------
    sw      $t0, 0($a0)             # memory[$a0 + 0] = $t0
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # Address: 0x0116 (mem[139])
    # ---------------------------------------------------------------------
    # Increment memory pointer (move to next word)
    # ---------------------------------------------------------------------
    addi    $a0, $a0, 2             # $a0 = $a0 + 2 (word size is 2 bytes)
    nop                             # Hazard handling NOPs (4 total)
    nop
    nop
    nop

    # Address: 0x0120 (mem[144])
    # ---------------------------------------------------------------------
    # Jump back to loop start
    # ---------------------------------------------------------------------
    j       loop_start              # Jump to beginning of loop
    nop                             # Jump delay slots (3 total)
    nop
    nop


# =============================================================================
# SECTION 4: PROGRAM TERMINATION
# =============================================================================

done:
    # Address: 0x012A (mem[149])
    # ---------------------------------------------------------------------
    # Halt: Infinite loop
    # ---------------------------------------------------------------------
    j       done                    # Infinite loop (halt)
    nop                             # Jump delay slots
    nop
    nop


# =============================================================================
# SECTION 5: DATA SECTION
# =============================================================================
# Located at address 0x0200 (mem[256])
# =============================================================================

.data
.org 0x0200

test_data:
    .word   0x0101                  # mem[256] @ 0x0200 - Test value 1
    .word   0x0110                  # mem[257] @ 0x0202 - Test value 2
    .word   0x0011                  # mem[258] @ 0x0204 - Test value 3
    .word   0x00F0                  # mem[259] @ 0x0206 - Test value 4
    .word   0x00FF                  # mem[260] @ 0x0208 - Test value 5


# =============================================================================
# PROGRAM SUMMARY
# =============================================================================
#
# FINAL EXPECTED REGISTER STATE:
#   R0 ($zero) = 0x0000  (always zero)
#   R1 ($v0)   = 0x0040  (from loop initialization)
#   R2 ($v1)   = 0x1010  (from loop initialization)
#   R3 ($v2)   = 0x000F  (from loop initialization)
#   R4 ($v3)   = 0x00F0  (from loop initialization)
#   R5 ($t0)   = 0x0000  (cleared at loop exit)
#   R6 ($a0)   = 0x020A  (0x0200 + 5×2 = 0x020A, points past last element)
#   R7 ($a1)   = 0x0000  (loop counter decremented to zero)
#
# FINAL MEMORY STATE:
#   mem[0x0200] = 0x0101  (unchanged by load/store)
#   mem[0x0202] = 0x0110  (unchanged by load/store)
#   mem[0x0204] = 0x0011  (unchanged by load/store)
#   mem[0x0206] = 0x00F0  (unchanged by load/store)
#   mem[0x0208] = 0x00FF  (unchanged by load/store)
#
# INSTRUCTIONS TESTED:
#   Standard: ORI, LI, SLL, ADDI, SUBI, SUB, LW, SW, BEQ, JUMP
#   Custom BONUS (+10%): ABS, MIN, MAX
#   Total: 20+ unique instructions
#
# PIPELINE FEATURES DEMONSTRATED:
#   - 5-stage pipeline operation (IF, ID, EX, MEM, WB)
#   - Data hazard handling via software NOPs (4 NOPs after writes)
#   - Control hazard handling via delay slots (3 NOPs after branch/jump)
#   - Branch decision in MEM stage (requires 3 delay slots)
#   - Memory operations in MEM stage
#   - Register write-back in WB stage
#
# LOOP BEHAVIOR:
#   - 5 iterations total
#   - Each iteration: loads from memory, stores back, increments pointer
#   - Counter decrements: 5 → 4 → 3 → 2 → 1 → 0
#   - Pointer increments: 0x0200 → 0x0202 → 0x0204 → 0x0206 → 0x0208 → 0x020A
#   - Branch taken on iteration 5 when counter reaches 0
#
# =============================================================================