--------------------------------------------------------------------------------
-- Package: processor_pkg_ENHANCED
-- Description: Enhanced processor with 20 instructions (3 custom non-MIPS)
-- BONUS: ABS, MIN, MAX instructions
-- Author: Lab 4 Team - ALL BONUS ATTEMPT
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package processor_pkg is
    
    -- Data types
    subtype word is std_logic_vector(15 downto 0);
    subtype byte is std_logic_vector(7 downto 0);
    subtype reg_addr is std_logic_vector(2 downto 0);
    subtype opcode_type is std_logic_vector(3 downto 0);
    subtype funct_type is std_logic_vector(1 downto 0);
    subtype alu_control_type is std_logic_vector(3 downto 0);
    subtype immediate_type is std_logic_vector(5 downto 0);
    subtype jump_addr_type is std_logic_vector(11 downto 0);
    
    -- Opcodes (4 bits) - NOW 20 INSTRUCTIONS!
    constant OP_RTYPE_0  : opcode_type := "0000";  -- R-type: add, sub, and, or
    constant OP_RTYPE_1  : opcode_type := "0001";  -- R-type: slt, xor, sra
    constant OP_ADDI     : opcode_type := "0010";  -- Add immediate
    constant OP_SUBI     : opcode_type := "0011";  -- Subtract immediate
    constant OP_ORI      : opcode_type := "0100";  -- OR immediate
    constant OP_LW       : opcode_type := "0101";  -- Load word
    constant OP_SW       : opcode_type := "0110";  -- Store word
    constant OP_SLTI     : opcode_type := "0111";  -- Set less than immediate
    constant OP_BEQ      : opcode_type := "1000";  -- Branch if equal
    constant OP_BNE      : opcode_type := "1001";  -- Branch if not equal
    constant OP_JUMP     : opcode_type := "1010";  -- Jump
    constant OP_LI       : opcode_type := "1011";  -- Load immediate
    -- *** CUSTOM NON-MIPS INSTRUCTIONS (BONUS +10%) ***
    constant OP_ABS      : opcode_type := "1100";  -- CUSTOM: Absolute value
    constant OP_MIN      : opcode_type := "1101";  -- CUSTOM: Minimum of two values
    constant OP_MAX      : opcode_type := "1110";  -- CUSTOM: Maximum of two values
    constant OP_SLL      : opcode_type := "1111";  -- Shift left logical (I-type with immediate)
    
    -- Function codes for R-type instructions (2 bits)
    constant FUNCT_ADD   : funct_type := "00";
    constant FUNCT_SUB   : funct_type := "01";
    constant FUNCT_AND   : funct_type := "10";
    constant FUNCT_OR    : funct_type := "11";
    constant FUNCT_SLT   : funct_type := "00";  -- opcode 0001
    constant FUNCT_XOR   : funct_type := "01";  -- opcode 0001
    constant FUNCT_SRA   : funct_type := "10";  -- opcode 0001
    -- FUNCT "11" reserved for opcode 0001
    
    -- ALU Control signals (4 bits) - ENHANCED WITH CUSTOM OPS
    constant ALU_AND     : alu_control_type := "0000";
    constant ALU_OR      : alu_control_type := "0001";
    constant ALU_ADD     : alu_control_type := "0010";
    constant ALU_XOR     : alu_control_type := "0011";
    constant ALU_SUB     : alu_control_type := "0110";
    constant ALU_SLT     : alu_control_type := "0111";
    constant ALU_SRA     : alu_control_type := "1000";
    constant ALU_SLL     : alu_control_type := "1100";  -- Shift Left Logical
    constant ALU_ABS     : alu_control_type := "1001";  -- CUSTOM: Absolute value
    constant ALU_MIN     : alu_control_type := "1010";  -- CUSTOM: Minimum
    constant ALU_MAX     : alu_control_type := "1011";  -- CUSTOM: Maximum
    constant ALU_PASS_B  : alu_control_type := "1111";  -- For LI instruction
    
    -- ALUOp encoding (2 bits for main control)
    constant ALUOP_ADD   : std_logic_vector(1 downto 0) := "00";
    constant ALUOP_SUB   : std_logic_vector(1 downto 0) := "01";
    constant ALUOP_RTYPE : std_logic_vector(1 downto 0) := "10";
    constant ALUOP_OR    : std_logic_vector(1 downto 0) := "11";
    
    -- Register names
    constant REG_ZERO    : reg_addr := "000";  -- R0 - Always 0
    constant REG_V0      : reg_addr := "001";  -- R1
    constant REG_V1      : reg_addr := "010";  -- R2
    constant REG_V2      : reg_addr := "011";  -- R3
    constant REG_V3      : reg_addr := "100";  -- R4
    constant REG_T0      : reg_addr := "101";  -- R5
    constant REG_A0      : reg_addr := "110";  -- R6
    constant REG_A1      : reg_addr := "111";  -- R7
    
    -- Memory constants
    constant MEM_SIZE    : integer := 512;  -- Increased from 256 to accommodate larger programs
    constant MEM_ADDR_BITS : integer := 16;
    
    -- Helper functions for instruction decoding
    function get_opcode(instruction : word) return opcode_type;
    function get_rs(instruction : word) return reg_addr;
    function get_rt(instruction : word) return reg_addr;
    function get_rd(instruction : word) return reg_addr;
    function get_shamt(instruction : word) return std_logic;
    function get_funct(instruction : word) return funct_type;
    function get_immediate(instruction : word) return immediate_type;
    function get_jump_addr(instruction : word) return jump_addr_type;
    
    -- Sign extension functions
    function sign_extend_6to16(imm : immediate_type) return word;
    function zero_extend_6to16(imm : immediate_type) return word;
    
end package processor_pkg;

package body processor_pkg is
    
    -- Extract opcode (bits 15-12)
    function get_opcode(instruction : word) return opcode_type is
    begin
        return instruction(15 downto 12);
    end function;
    
    -- Extract rs (bits 11-9)
    function get_rs(instruction : word) return reg_addr is
    begin
        return instruction(11 downto 9);
    end function;
    
    -- Extract rt (bits 8-6)
    function get_rt(instruction : word) return reg_addr is
    begin
        return instruction(8 downto 6);
    end function;
    
    -- Extract rd (bits 5-3)
    function get_rd(instruction : word) return reg_addr is
    begin
        return instruction(5 downto 3);
    end function;
    
    -- Extract shamt (bit 2)
    function get_shamt(instruction : word) return std_logic is
    begin
        return instruction(2);
    end function;
    
    -- Extract funct (bits 1-0)
    function get_funct(instruction : word) return funct_type is
    begin
        return instruction(1 downto 0);
    end function;
    
    -- Extract immediate (bits 5-0)
    function get_immediate(instruction : word) return immediate_type is
    begin
        return instruction(5 downto 0);
    end function;
    
    -- Extract jump address (bits 11-0)
    function get_jump_addr(instruction : word) return jump_addr_type is
    begin
        return instruction(11 downto 0);
    end function;
    
    -- Sign extend 6-bit immediate to 16 bits
    function sign_extend_6to16(imm : immediate_type) return word is
        variable result : word;
    begin
        if imm(5) = '1' then
            result := "1111111111" & imm;
        else
            result := "0000000000" & imm;
        end if;
        return result;
    end function;
    
    -- Zero extend 6-bit immediate to 16 bits
    function zero_extend_6to16(imm : immediate_type) return word is
    begin
        return "0000000000" & imm;
    end function;
    
end package body processor_pkg;