--------------------------------------------------------------------------------
-- Entity: MEM_WB_reg
-- Description: MEM/WB Pipeline Register
-- Stores: Control signals, memory data, ALU result from Memory to Write Back
-- Author: Lab 4 Team
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.processor_pkg.all;

entity MEM_WB_reg is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        
        -- Control signals IN
        MemtoReg_in    : in  std_logic;
        RegWrite_in    : in  std_logic;
        
        -- Data IN
        mem_data_in    : in  word;
        alu_result_in  : in  word;
        write_reg_in   : in  reg_addr;
        
        -- Control signals OUT
        MemtoReg_out   : out std_logic;
        RegWrite_out   : out std_logic;
        
        -- Data OUT
        mem_data_out   : out word;
        alu_result_out : out word;
        write_reg_out  : out reg_addr
    );
end MEM_WB_reg;

architecture behavioral of MEM_WB_reg is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            -- Clear control signals
            MemtoReg_out <= '0';
            RegWrite_out <= '0';
            
            -- Clear data
            mem_data_out <= (others => '0');
            alu_result_out <= (others => '0');
            write_reg_out <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Pass through
            MemtoReg_out <= MemtoReg_in;
            RegWrite_out <= RegWrite_in;
            
            mem_data_out <= mem_data_in;
            alu_result_out <= alu_result_in;
            write_reg_out <= write_reg_in;
        end if;
    end process;
end behavioral;