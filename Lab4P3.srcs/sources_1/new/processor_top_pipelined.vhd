--------------------------------------------------------------------------------
-- Entity: processor_top_pipelined
-- Description: Top-level 5-stage pipelined RISC processor
-- Integrates pipelined datapath and memory
-- BONUS #5: Software-inserted NOPs for hazard handling
-- Author: Lab 4 Team
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.processor_pkg.all;

entity processor_top is
    Port (
        clk   : in  std_logic;
        reset : in  std_logic;
        PC    : out word  -- Expose PC for testbench monitoring
    );
end processor_top;

architecture behavioral of processor_top is

    -- Component declarations
    component datapath_pipelined is
        Port (
            clk             : in  std_logic;
            reset           : in  std_logic;
            instruction     : in  word;
            mem_read_data   : in  word;
            mem_address     : out word;
            mem_write_data  : out word;
            MemRead         : out std_logic;
            MemWrite        : out std_logic;
            PC_out          : out word
        );
    end component;

    component memory is
        Port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            address    : in  word;
            write_data : in  word;
            read_data  : out word;
            mem_read   : in  std_logic;
            mem_write  : in  std_logic
        );
    end component;

    -- Internal signals
    signal PC_internal : word;
    signal instruction : word;
    signal mem_address : word;
    signal mem_write_data : word;
    signal mem_read_data : word;
    signal MemRead, MemWrite : std_logic;

begin

    -- Pipelined Datapath instantiation
    dp: datapath_pipelined
        port map (
            clk             => clk,
            reset           => reset,
            instruction     => instruction,
            mem_read_data   => mem_read_data,
            mem_address     => mem_address,
            mem_write_data  => mem_write_data,
            MemRead         => MemRead,
            MemWrite        => MemWrite,
            PC_out          => PC_internal
        );

    -- Instruction memory (fetch using PC)
    instr_mem: memory
        port map (
            clk        => clk,
            reset      => reset,
            address    => PC_internal,
            write_data => (others => '0'),  -- Never write to instruction mem via PC
            read_data  => instruction,
            mem_read   => '1',              -- Always reading instructions
            mem_write  => '0'               -- Never write via instruction fetch
        );

    -- Data memory (access using mem_address from ALU)
    data_mem: memory
        port map (
            clk        => clk,
            reset      => reset,
            address    => mem_address,
            write_data => mem_write_data,
            read_data  => mem_read_data,
            mem_read   => MemRead,
            mem_write  => MemWrite
        );

    -- Connect internal PC to output port
    PC <= PC_internal;

end behavioral;
