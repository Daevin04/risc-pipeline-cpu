--------------------------------------------------------------------------------
-- Entity: alu_control_ENHANCED
-- Description: Enhanced ALU control with support for custom instructions
-- Supports: Standard MIPS + ABS, MIN, MAX custom operations
-- Author: Lab 4 Team - ALL BONUS ATTEMPT
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.processor_pkg.all;

entity alu_control is
    Port (
        ALUOp       : in  std_logic_vector(1 downto 0);
        funct       : in  funct_type;
        opcode      : in  opcode_type;
        alu_control : out alu_control_type
    );
end alu_control;

architecture behavioral of alu_control is
begin

    process(ALUOp, funct, opcode)
    begin
        case ALUOp is
            when ALUOP_ADD =>
                -- Add (for lw, sw, addi)
                alu_control <= ALU_ADD;
                
            when ALUOP_SUB =>
                -- Subtract (for beq, bne, subi)
                alu_control <= ALU_SUB;
                
            when ALUOP_OR =>
                -- OR (for ori)
                alu_control <= ALU_OR;
                
            when ALUOP_RTYPE =>
                -- R-type or custom instructions - use funct field or opcode
                case opcode is
                    when OP_RTYPE_0 =>
                        -- Standard R-type group 1
                        case funct is
                            when FUNCT_ADD => alu_control <= ALU_ADD;
                            when FUNCT_SUB => alu_control <= ALU_SUB;
                            when FUNCT_AND => alu_control <= ALU_AND;
                            when FUNCT_OR  => alu_control <= ALU_OR;
                            when others    => alu_control <= ALU_ADD;
                        end case;
                        
                    when OP_RTYPE_1 =>
                        -- Standard R-type group 2
                        case funct is
                            when FUNCT_SLT => alu_control <= ALU_SLT;
                            when FUNCT_XOR => alu_control <= ALU_XOR;
                            when FUNCT_SRA => alu_control <= ALU_SRA;
                            when others    => alu_control <= ALU_ADD;
                        end case;
                        
                    when OP_SLTI =>
                        -- Set less than immediate
                        alu_control <= ALU_SLT;
                        
                    when OP_LI =>
                        -- Load immediate - pass through B
                        alu_control <= ALU_PASS_B;
                        
                    -- *** CUSTOM NON-MIPS INSTRUCTIONS (BONUS +10%) ***
                    
                    when OP_ABS =>
                        -- CUSTOM: Absolute value
                        alu_control <= ALU_ABS;
                        
                    when OP_MIN =>
                        -- CUSTOM: Minimum
                        alu_control <= ALU_MIN;
                        
                    when OP_MAX =>
                        -- CUSTOM: Maximum
                        alu_control <= ALU_MAX;

                    when OP_SLL =>
                        -- Shift left logical (I-type)
                        alu_control <= ALU_SLL;

                    when others =>
                        alu_control <= ALU_ADD;
                end case;
                
            when others =>
                alu_control <= ALU_ADD;
        end case;
    end process;

end behavioral;