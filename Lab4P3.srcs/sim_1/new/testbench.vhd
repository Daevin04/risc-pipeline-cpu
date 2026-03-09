--------------------------------------------------------------------------------
-- Entity: testbench
-- Description: Clean testbench - outputs TCL examine commands at checkpoints
-- Author: Lab 4 Team
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.processor_pkg.all;

entity testbench is
end testbench;

architecture behavioral of testbench is

    component processor_top is
        Port (
            clk   : in  std_logic;
            reset : in  std_logic;
            PC    : out word
        );
    end component;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal PC    : word;
    constant clk_period : time := 10 ns;
    signal sim_done : boolean := false;
    signal cycle_count : integer := 0;

begin

    uut: processor_top
        port map (
            clk   => clk,
            reset => reset,
            PC    => PC
        );

    clk_process: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    cycle_counter: process(clk)
    begin
        if rising_edge(clk) and reset = '0' then
            cycle_count <= cycle_count + 1;
        end if;
    end process;

    stim_proc: process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';

        report "========================================";
        report "SIMULATION STARTED";
        report "========================================";
        report "";

        wait for clk_period * 600;

        report "";
        report "========================================";
        report "TIMEOUT AT 600 CYCLES";
        report "========================================";

        sim_done <= true;
        wait;
    end process;

    checkpoint_proc: process(clk)
        variable loop_count : integer := 0;
        variable halt_done : boolean := false;
        variable line_buf : line;
    begin
        if rising_edge(clk) and reset = '0' then

            -- Count loop iterations
            if to_integer(unsigned(PC)) = 230 then
                loop_count := loop_count + 1;
            end if;

            -- CHECKPOINT 1
            if cycle_count = 50 then
                report "";
                report "======== CHECKPOINT 1 (Cycle 50) ========";
                write(line_buf, string'("PC = 0x"));
                hwrite(line_buf, PC);
                report line_buf.all;
                deallocate(line_buf);
                report "";
                report "COPY-PASTE THESE TCL COMMANDS:";
                report "examine /testbench/uut/dp/reg_file/registers(2)";
                report "examine /testbench/uut/dp/reg_file/registers(6)";
                report "examine /testbench/uut/dp/reg_file/registers(7)";
                report "==========================================";
                report "";
            end if;

            -- CHECKPOINT 2
            if cycle_count = 120 then
                report "";
                report "======== CHECKPOINT 2 (Cycle 120) ========";
                write(line_buf, string'("PC = 0x"));
                hwrite(line_buf, PC);
                report line_buf.all;
                deallocate(line_buf);
                report "";
                report "COPY-PASTE THESE TCL COMMANDS:";
                report "examine /testbench/uut/dp/reg_file/registers(1)";
                report "examine /testbench/uut/dp/reg_file/registers(2)";
                report "examine /testbench/uut/dp/reg_file/registers(4)";
                report "examine /testbench/uut/dp/reg_file/registers(7)";
                report "===========================================";
                report "";
            end if;

            -- FINAL CHECKPOINT
            if to_integer(unsigned(PC)) = 298 and not halt_done then
                report "";
                report "======== FINAL - HALTED AT 0x012A ========";
                report "Cycle: " & integer'image(cycle_count);
                report "Loops: " & integer'image(loop_count) & " (expect 5)";
                report "";
                report "FINAL VERIFICATION - COPY ALL COMMANDS:";
                report "examine /testbench/uut/dp/reg_file/registers(1)";
                report "examine /testbench/uut/dp/reg_file/registers(2)";
                report "examine /testbench/uut/dp/reg_file/registers(3)";
                report "examine /testbench/uut/dp/reg_file/registers(4)";
                report "examine /testbench/uut/dp/reg_file/registers(5)";
                report "examine /testbench/uut/dp/reg_file/registers(6)";
                report "examine /testbench/uut/dp/reg_file/registers(7)";
                report "examine /testbench/uut/data_mem/mem(256)";
                report "examine /testbench/uut/data_mem/mem(257)";
                report "examine /testbench/uut/data_mem/mem(258)";
                report "examine /testbench/uut/data_mem/mem(259)";
                report "examine /testbench/uut/data_mem/mem(260)";
                report "===========================================";
                report "";
                halt_done := true;
            end if;

        end if;
    end process;

end behavioral;
