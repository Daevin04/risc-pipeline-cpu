--------------------------------------------------------------------------------
-- Entity: control_unit_ENHANCED
-- Description: Enhanced control unit supporting 20 instructions (3 custom)
-- Custom instructions: ABS, MIN, MAX
-- Author: Lab 4 Team - ALL BONUS ATTEMPT
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.processor_pkg.all;

entity control_unit is
    Port (
        opcode      : in  opcode_type;
        RegDst      : out std_logic;
        Jump        : out std_logic;
        Branch      : out std_logic;
        MemRead     : out std_logic;
        MemtoReg    : out std_logic;
        ALUOp       : out std_logic_vector(1 downto 0);
        MemWrite    : out std_logic;
        ALUSrc      : out std_logic;
        RegWrite    : out std_logic;
        BranchNotEq : out std_logic
    );
end control_unit;

architecture behavioral of control_unit is
begin

    process(opcode)
    begin
        -- Default values
        RegDst      <= '0';
        ALUSrc      <= '0';
        MemtoReg    <= '0';
        RegWrite    <= '0';
        MemRead     <= '0';
        MemWrite    <= '0';
        Branch      <= '0';
        ALUOp       <= "00";
        Jump        <= '0';
        BranchNotEq <= '0';
        
        case opcode is
            -- R-type instructions (opcode 0000)
            when OP_RTYPE_0 =>
                RegDst      <= '1';  -- Write to rd
                ALUSrc      <= '0';  -- Use register for ALU operand B
                MemtoReg    <= '0';  -- Write ALU result to register
                RegWrite    <= '1';  -- Enable register write
                ALUOp       <= ALUOP_RTYPE;
                
            -- R-type instructions (opcode 0001)
            when OP_RTYPE_1 =>
                RegDst      <= '1';
                ALUSrc      <= '0';
                MemtoReg    <= '0';
                RegWrite    <= '1';
                ALUOp       <= ALUOP_RTYPE;
                
            -- addi
            when OP_ADDI =>
                RegDst      <= '0';  -- Write to rt
                ALUSrc      <= '1';  -- Use immediate
                MemtoReg    <= '0';
                RegWrite    <= '1';
                ALUOp       <= ALUOP_ADD;
                
            -- subi
            when OP_SUBI =>
                RegDst      <= '0';
                ALUSrc      <= '1';
                MemtoReg    <= '0';
                RegWrite    <= '1';
                ALUOp       <= ALUOP_SUB;
                
            -- ori
            when OP_ORI =>
                RegDst      <= '0';
                ALUSrc      <= '1';
                MemtoReg    <= '0';
                RegWrite    <= '1';
                ALUOp       <= ALUOP_OR;
                
            -- lw
            when OP_LW =>
                RegDst      <= '0';
                ALUSrc      <= '1';
                MemtoReg    <= '1';  -- Write memory data to register
                RegWrite    <= '1';
                MemRead     <= '1';  -- Enable memory read
                ALUOp       <= ALUOP_ADD;
                
            -- sw
            when OP_SW =>
                ALUSrc      <= '1';
                MemWrite    <= '1';  -- Enable memory write
                ALUOp       <= ALUOP_ADD;
                
            -- slti
            when OP_SLTI =>
                RegDst      <= '0';
                ALUSrc      <= '1';
                MemtoReg    <= '0';
                RegWrite    <= '1';
                ALUOp       <= ALUOP_RTYPE;
                
            -- beq
            when OP_BEQ =>
                ALUSrc      <= '0';
                Branch      <= '1';
                ALUOp       <= ALUOP_SUB;
                BranchNotEq <= '0';
                
            -- bne
            when OP_BNE =>
                ALUSrc      <= '0';
                Branch      <= '1';
                ALUOp       <= ALUOP_SUB;
                BranchNotEq <= '1';
                
            -- j (jump)
            when OP_JUMP =>
                Jump        <= '1';
                
            -- li (load immediate)
            when OP_LI =>
                RegDst      <= '0';
                ALUSrc      <= '1';
                MemtoReg    <= '0';
                RegWrite    <= '1';
                ALUOp       <= ALUOP_RTYPE;
                
            -- *** CUSTOM NON-MIPS INSTRUCTIONS (BONUS +10%) ***
            
            -- ABS (Absolute Value)
            -- Format: abs $rd, $rs
            -- Operation: $rd = |$rs|
            when OP_ABS =>
                RegDst      <= '1';  -- Write to rd
                ALUSrc      <= '0';  -- Use register (operand_b ignored)
                MemtoReg    <= '0';  -- Write ALU result
                RegWrite    <= '1';  -- Enable write
                ALUOp       <= ALUOP_RTYPE;
                
            -- MIN (Minimum of two values)
            -- Format: min $rd, $rs, $rt
            -- Operation: $rd = min($rs, $rt)
            when OP_MIN =>
                RegDst      <= '1';  -- Write to rd
                ALUSrc      <= '0';  -- Use registers
                MemtoReg    <= '0';  -- Write ALU result
                RegWrite    <= '1';  -- Enable write
                ALUOp       <= ALUOP_RTYPE;
                
            -- MAX (Maximum of two values)
            -- Format: max $rd, $rs, $rt
            -- Operation: $rd = max($rs, $rt)
            when OP_MAX =>
                RegDst      <= '1';  -- Write to rd
                ALUSrc      <= '0';  -- Use registers
                MemtoReg    <= '0';  -- Write ALU result
                RegWrite    <= '1';  -- Enable write
                ALUOp       <= ALUOP_RTYPE;

            -- SLL (Shift Left Logical) - I-type with immediate
            -- Format: sll $rt, $rs, shift_amount
            -- Operation: $rt = $rs << shift_amount
            when OP_SLL =>
                RegDst      <= '0';  -- Write to rt
                ALUSrc      <= '1';  -- Use immediate for shift amount
                MemtoReg    <= '0';  -- Write ALU result
                RegWrite    <= '1';  -- Enable write
                ALUOp       <= ALUOP_RTYPE;

            when others =>
                -- All signals remain at default (0)
                null;
        end case;
    end process;

end behavioral;