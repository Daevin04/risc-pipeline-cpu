--------------------------------------------------------------------------------
-- Entity: EX_MEM_reg
-- Description: EX/MEM Pipeline Register
-- Stores: Control signals, ALU result, memory data from Execute to Memory
-- Author: Lab 4 Team
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.processor_pkg.all;

entity EX_MEM_reg is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        
        -- Control signals IN
        MemRead_in     : in  std_logic;
        MemWrite_in    : in  std_logic;
        MemtoReg_in    : in  std_logic;
        RegWrite_in    : in  std_logic;
        Branch_in      : in  std_logic;
        Jump_in        : in  std_logic;
        BranchNotEq_in : in  std_logic;
        
        -- Data IN
        branch_target_in : in  word;
        zero_flag_in     : in  std_logic;
        alu_result_in    : in  word;
        read_data2_in    : in  word;
        write_reg_in     : in  reg_addr;
        
        -- Control signals OUT
        MemRead_out     : out std_logic;
        MemWrite_out    : out std_logic;
        MemtoReg_out    : out std_logic;
        RegWrite_out    : out std_logic;
        Branch_out      : out std_logic;
        Jump_out        : out std_logic;
        BranchNotEq_out : out std_logic;
        
        -- Data OUT
        branch_target_out : out word;
        zero_flag_out     : out std_logic;
        alu_result_out    : out word;
        read_data2_out    : out word;
        write_reg_out     : out reg_addr
    );
end EX_MEM_reg;

architecture behavioral of EX_MEM_reg is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            -- Clear control signals
            MemRead_out <= '0';
            MemWrite_out <= '0';
            MemtoReg_out <= '0';
            RegWrite_out <= '0';
            Branch_out <= '0';
            Jump_out <= '0';
            BranchNotEq_out <= '0';
            
            -- Clear data
            branch_target_out <= (others => '0');
            zero_flag_out <= '0';
            alu_result_out <= (others => '0');
            read_data2_out <= (others => '0');
            write_reg_out <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Pass through
            MemRead_out <= MemRead_in;
            MemWrite_out <= MemWrite_in;
            MemtoReg_out <= MemtoReg_in;
            RegWrite_out <= RegWrite_in;
            Branch_out <= Branch_in;
            Jump_out <= Jump_in;
            BranchNotEq_out <= BranchNotEq_in;
            
            branch_target_out <= branch_target_in;
            zero_flag_out <= zero_flag_in;
            alu_result_out <= alu_result_in;
            read_data2_out <= read_data2_in;
            write_reg_out <= write_reg_in;
        end if;
    end process;
end behavioral;