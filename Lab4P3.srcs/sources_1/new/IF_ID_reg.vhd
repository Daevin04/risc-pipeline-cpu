--------------------------------------------------------------------------------
-- Entity: IF_ID_reg
-- Description: IF/ID Pipeline Register
-- Stores: PC+2 and Instruction from Fetch stage to Decode stage
-- Author: Lab 4 Team
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.processor_pkg.all;

entity IF_ID_reg is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        stall       : in  std_logic;
        flush       : in  std_logic;
        -- Inputs from IF stage
        PC_in       : in  word;
        instr_in    : in  word;
        -- Outputs to ID stage
        PC_out      : out word;
        instr_out   : out word
    );
end IF_ID_reg;

architecture behavioral of IF_ID_reg is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            PC_out <= (others => '0');
            instr_out <= (others => '0');
        elsif rising_edge(clk) then
            if flush = '1' then
                -- Insert bubble (NOP)
                PC_out <= (others => '0');
                instr_out <= (others => '0');
            elsif stall = '0' then
                -- Normal operation
                PC_out <= PC_in;
                instr_out <= instr_in;
            end if;
            -- If stall = '1', hold current values
        end if;
    end process;
end behavioral;