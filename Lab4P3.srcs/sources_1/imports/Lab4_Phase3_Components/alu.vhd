--------------------------------------------------------------------------------
-- Entity: alu_ENHANCED
-- Description: Enhanced ALU with 12 operations including 3 custom non-MIPS ops
-- Operations: AND, OR, ADD, XOR, SUB, SLT, SRA, SLL, ABS, MIN, MAX, PASS_B
-- BONUS: ABS, MIN, MAX are custom non-MIPS instructions
-- Author: Lab 4 Team - ALL BONUS ATTEMPT
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.processor_pkg.all;

entity alu is
    Port (
        alu_control : in  alu_control_type;
        operand_a   : in  word;
        operand_b   : in  word;
        shamt       : in  std_logic;
        result      : out word;
        zero_flag   : out std_logic
    );
end alu;

architecture behavioral of alu is
    signal alu_result : signed(15 downto 0);
    signal a_signed : signed(15 downto 0);
    signal b_signed : signed(15 downto 0);
begin

    a_signed <= signed(operand_a);
    b_signed <= signed(operand_b);

    process(alu_control, operand_a, operand_b, a_signed, b_signed, shamt)
        variable shift_amount : integer;
    begin
        case alu_control is
            when ALU_AND =>
                -- Bitwise AND
                alu_result <= signed(operand_a and operand_b);
                
            when ALU_OR =>
                -- Bitwise OR
                alu_result <= signed(operand_a or operand_b);
                
            when ALU_ADD =>
                -- Addition
                alu_result <= a_signed + b_signed;
                
            when ALU_XOR =>
                -- Bitwise XOR
                alu_result <= signed(operand_a xor operand_b);
                
            when ALU_SUB =>
                -- Subtraction (also used for BEQ/BNE comparison)
                alu_result <= a_signed - b_signed;
                
            when ALU_SLT =>
                -- Set Less Than (signed comparison)
                if a_signed < b_signed then
                    alu_result <= to_signed(1, 16);
                else
                    alu_result <= to_signed(0, 16);
                end if;
                
            when ALU_SRA =>
                -- Shift Right Arithmetic (preserves sign bit)
                if shamt = '1' then
                    -- Shift right by 2 positions (divide by 4)
                    alu_result <= signed(a_signed(15) & a_signed(15) & a_signed(15 downto 2));
                else
                    -- Shift right by 1 position (divide by 2)
                    alu_result <= signed(a_signed(15) & a_signed(15 downto 1));
                end if;

            when ALU_SLL =>
                -- Shift Left Logical
                -- Uses operand_b (lower 4 bits) as shift amount (0-15 positions)
                -- Format: sll $rd, $rs, shift_amount
                shift_amount := to_integer(unsigned(operand_b(3 downto 0)));
                alu_result <= signed(shift_left(unsigned(a_signed), shift_amount));

            -- *** CUSTOM NON-MIPS OPERATIONS (BONUS +10%) ***
            
            when ALU_ABS =>
                -- CUSTOM: Absolute Value
                -- Returns |operand_a|
                -- Manual implementation: if negative, compute two's complement negation
                if a_signed(15) = '1' then
                    -- Negative number: compute -a_signed using two's complement
                    alu_result <= (not a_signed) + 1;
                else
                    -- Positive or zero: return as-is
                    alu_result <= a_signed;
                end if;
                
            when ALU_MIN =>
                -- CUSTOM: Minimum of two values
                -- Returns min(operand_a, operand_b)
                if a_signed < b_signed then
                    alu_result <= a_signed;
                else
                    alu_result <= b_signed;
                end if;
                
            when ALU_MAX =>
                -- CUSTOM: Maximum of two values  
                -- Returns max(operand_a, operand_b)
                if a_signed > b_signed then
                    alu_result <= a_signed;
                else
                    alu_result <= b_signed;
                end if;
                
            when ALU_PASS_B =>
                -- Pass through operand_b (for LI instruction)
                alu_result <= b_signed;
                
            when others =>
                -- Default case
                alu_result <= (others => '0');
        end case;
    end process;

    -- Output result
    result <= std_logic_vector(alu_result);
    
    -- Zero flag: set if result is zero (for branch instructions)
    zero_flag <= '1' when alu_result = 0 else '0';

end behavioral;