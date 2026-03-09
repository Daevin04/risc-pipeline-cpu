--------------------------------------------------------------------------------
-- Testbench: tb_memory_simple
-- Simplified memory testbench using integer reporting
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.processor_pkg.all;

entity tb_memory_simple is
end tb_memory_simple;

architecture behavioral of tb_memory_simple is

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

    signal clk        : std_logic := '0';
    signal reset      : std_logic := '1';
    signal address    : word := (others => '0');
    signal write_data : word := (others => '0');
    signal read_data  : word;
    signal mem_read   : std_logic := '0';
    signal mem_write  : std_logic := '0';

    constant clk_period : time := 10 ns;
    signal test_count : integer := 0;
    signal pass_count : integer := 0;
    signal fail_count : integer := 0;

begin

    uut: memory
        port map (
            clk        => clk,
            reset      => reset,
            address    => address,
            write_data => write_data,
            read_data  => read_data,
            mem_read   => mem_read,
            mem_write  => mem_write
        );

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    test_proc: process
    begin
        report "================================================================================";
        report "MEMORY TESTBENCH";
        report "================================================================================";

        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;

        report "Testing initialized program memory...";

        -- Test 1: Read mem[0] - First instruction
        test_count <= test_count + 1;
        address <= x"0000";
        mem_read <= '1';
        wait for clk_period;
        report "TEST " & integer'image(test_count) & ": Read mem[0]";
        report "  Address: " & integer'image(to_integer(unsigned(address)));
        report "  Result (dec): " & integer'image(to_integer(unsigned(read_data)));
        report "  Expected (dec): 16704 (hex 4140 = ori $v0, $zero, 0x40)";
        if read_data = x"4140" then
            report "  STATUS: PASS";
            pass_count <= pass_count + 1;
        else
            report "  STATUS: FAIL ***";
            fail_count <= fail_count + 1;
        end if;
        mem_read <= '0';

        -- Test 2: Read mem[1] - NOP
        test_count <= test_count + 1;
        address <= x"0002";
        mem_read <= '1';
        wait for clk_period;
        report "TEST " & integer'image(test_count) & ": Read mem[1] - NOP";
        report "  Address: " & integer'image(to_integer(unsigned(address)));
        report "  Result (dec): " & integer'image(to_integer(unsigned(read_data)));
        report "  Expected (dec): 0 (NOP)";
        if read_data = x"0000" then
            report "  STATUS: PASS";
            pass_count <= pass_count + 1;
        else
            report "  STATUS: FAIL ***";
            fail_count <= fail_count + 1;
        end if;
        mem_read <= '0';

        -- Test 3: Read initialized data
        test_count <= test_count + 1;
        address <= x"0078";  -- word 60
        mem_read <= '1';
        wait for clk_period;
        report "TEST " & integer'image(test_count) & ": Read data mem[60]";
        report "  Address: " & integer'image(to_integer(unsigned(address)));
        report "  Result (dec): " & integer'image(to_integer(unsigned(read_data)));
        report "  Expected (dec): 1";
        if read_data = x"0001" then
            report "  STATUS: PASS";
            pass_count <= pass_count + 1;
        else
            report "  STATUS: FAIL ***";
            fail_count <= fail_count + 1;
        end if;
        mem_read <= '0';

        report "";
        report "Testing write operations...";

        -- Test 4: Write and read back
        test_count <= test_count + 1;
        address <= x"00C8";  -- word 100
        write_data <= x"ABCD";
        mem_write <= '1';
        wait for clk_period;
        mem_write <= '0';
        wait for clk_period/2;

        address <= x"00C8";
        mem_read <= '1';
        wait for clk_period;
        report "TEST " & integer'image(test_count) & ": Write then read mem[100]";
        report "  Wrote (dec): " & integer'image(to_integer(unsigned(x"ABCD"))) & " = 43981";
        report "  Read (dec):  " & integer'image(to_integer(unsigned(read_data)));
        if read_data = x"ABCD" then
            report "  STATUS: PASS";
            pass_count <= pass_count + 1;
        else
            report "  STATUS: FAIL ***";
            fail_count <= fail_count + 1;
        end if;
        mem_read <= '0';

        wait for clk_period * 2;

        report "";
        report "================================================================================";
        report "MEMORY TESTBENCH COMPLETE";
        report "================================================================================";
        report "Total Tests: " & integer'image(test_count);
        report "Passed:      " & integer'image(pass_count);
        report "Failed:      " & integer'image(fail_count);

        if fail_count = 0 then
            report "*** ALL TESTS PASSED ***";
        else
            report "*** SOME TESTS FAILED - REVIEW ABOVE ***";
        end if;
        report "================================================================================";

        wait;
    end process;

end behavioral;
