--------------------------------------------------------------------------------
-- Testbench: tb_datapath_pc_logic
-- Description: CRITICAL TEST - Tests PC advancement, branch, and jump logic
-- This test will reveal if branches/jumps are working
-- Tests: PC increment, branch taken/not taken, jump, PC source mux
-- Outputs detailed results to TCL console for analysis
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use work.processor_pkg.all;

entity tb_datapath_pc_logic is
end tb_datapath_pc_logic;

architecture behavioral of tb_datapath_pc_logic is

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
    signal cycle_count : integer := 0;

    type pc_trace_type is record
        cycle : integer;
        pc_val : word;
    end record;

    type pc_history_type is array (0 to 99) of pc_trace_type;
    signal pc_history : pc_history_type;
    signal history_idx : integer := 0;

begin

    uut: processor_top
        port map (
            clk   => clk,
            reset => reset,
            PC    => PC
        );

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Track PC history
    pc_tracker: process(clk)
    begin
        if rising_edge(clk) and reset = '0' then
            if history_idx < 100 then
                pc_history(history_idx).cycle <= cycle_count;
                pc_history(history_idx).pc_val <= PC;
                history_idx <= history_idx + 1;
            end if;
            cycle_count <= cycle_count + 1;
        end if;
    end process;

    test_proc: process
        variable prev_pc : word := x"0000";
        variable pc_increment : integer;
    begin
        report "================================================================================";
        report "DATAPATH PC LOGIC TESTBENCH - CRITICAL TEST";
        report "================================================================================";
        report "This test will show if PC increments correctly and if branches/jumps work.";
        report "";

        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';

        report "--- ANALYZING PC BEHAVIOR ---";
        report "";

        -- Run for several cycles
        for i in 1 to 60 loop
            wait for clk_period;

            if i <= 30 or (i > 46 and i < 56) or i = 60 then
                pc_increment := to_integer(unsigned(PC)) - to_integer(unsigned(prev_pc));

                report "Cycle " & integer'image(cycle_count) & ": PC = " & integer'image(to_integer(unsigned(PC))) & " (increment: " & integer'image(pc_increment) & ")";

                -- Check if this looks like a branch or jump
                if pc_increment /= 2 and pc_increment /= 0 then
                    if pc_increment > 2 then
                        report "  *** FORWARD JUMP/BRANCH DETECTED (+" & integer'image(pc_increment) & ") ***";
                    elsif pc_increment < 0 then
                        report "  *** BACKWARD JUMP/BRANCH DETECTED (" & integer'image(pc_increment) & ") ***";
                    end if;
                elsif pc_increment = 0 then
                    if i > 1 then
                        report "  *** PC DID NOT ADVANCE (stuck or halt loop) ***";
                    end if;
                else
                    report "  Normal increment (+2)";
                end if;

                report "";
            end if;

            prev_pc := PC;
        end loop;

        wait for clk_period * 2;

        report "================================================================================";
        report "PC TRACE ANALYSIS";
        report "================================================================================";
        report "";
        report "Expected behavior for test program:";
        report "  - PC should increment by 2 most of the time";
        report "  - Around cycle ~35-40: Should see a BACKWARD JUMP (loop)";
        report "  - Around cycle ~50-55: Should exit loop and FORWARD BRANCH";
        report "  - Eventually: PC stuck at 0x6C (infinite halt loop)";
        report "";
        report "If PC ONLY increments by 2 and NEVER jumps/branches:";
        report "  *** CRITICAL BUG: PC source logic is missing! ***";
        report "  *** Branches and jumps are NOT working! ***";
        report "";

        -- Analyze the collected history
        report "Full PC history (first 60 cycles):";
        for i in 0 to history_idx-1 loop
            if i < 60 then
                report "  [" & integer'image(pc_history(i).cycle) & "] PC = " & integer'image(to_integer(unsigned(pc_history(i).pc_val)));
            end if;
        end loop;

        report "";
        report "================================================================================";
        report "ANALYSIS COMPLETE";
        report "================================================================================";
        report "";
        report "Questions to answer:";
        report "  1. Does PC always increment by exactly 2?";
        report "  2. Do you see any backward jumps (negative increments)?";
        report "  3. Does PC get stuck in a loop (same value repeated)?";
        report "  4. Does the program reach PC=0x6C (108 decimal)?";
        report "";
        report "If answer to Q1 is YES and all others are NO:";
        report "  --> Branch/Jump logic is BROKEN or MISSING";
        report "";
        report "================================================================================";

        wait;
    end process;

end behavioral;
