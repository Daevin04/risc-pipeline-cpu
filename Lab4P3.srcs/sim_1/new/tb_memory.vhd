--------------------------------------------------------------------------------
-- Testbench: tb_memory
-- Description: Test memory read/write and addressing
-- Tests: Word addressing, initialization, read/write operations
-- Outputs detailed results to TCL console for analysis
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.processor_pkg.all;

entity tb_memory is
end tb_memory;

architecture behavioral of tb_memory is

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
        variable line_buf : line;

        procedure read_memory(
            test_name : string;
            addr      : word;
            expected  : word
        ) is
            variable line_buf : line;
        begin
            test_count <= test_count + 1;
            report "========================================";
            report "TEST " & integer'image(test_count) & ": " & test_name;

            address <= addr;
            mem_read <= '1';
            wait for clk_period;

            write(line_buf, string'("  Address:  0x"));
            hwrite(line_buf, addr);
            write(line_buf, string'(" (word addr: "));
            write(line_buf, to_integer(unsigned(addr(15 downto 1))));
            write(line_buf, string'(")"));
            report line_buf.all;

            write(line_buf, string'("  Result:   0x"));
            hwrite(line_buf, read_data);
            report line_buf.all;

            write(line_buf, string'("  Expected: 0x"));
            hwrite(line_buf, expected);
            report line_buf.all;

            if read_data = expected then
                report "  STATUS: PASS";
                pass_count <= pass_count + 1;
            else
                report "  STATUS: FAIL ***";
                fail_count <= fail_count + 1;
            end if;

            mem_read <= '0';
            wait for clk_period/2;
        end procedure;

        procedure write_memory(
            test_name : string;
            addr      : word;
            data      : word
        ) is
            variable line_buf : line;
        begin
            test_count <= test_count + 1;
            report "========================================";
            report "TEST " & integer'image(test_count) & ": " & test_name;

            write(line_buf, string'("  Address:  0x"));
            hwrite(line_buf, addr);
            write(line_buf, string'(" (word addr: "));
            write(line_buf, to_integer(unsigned(addr(15 downto 1))));
            write(line_buf, string'(")"));
            report line_buf.all;

            write(line_buf, string'("  Data:     0x"));
            hwrite(line_buf, data);
            report line_buf.all;

            address <= addr;
            write_data <= data;
            mem_write <= '1';
            wait for clk_period;
            mem_write <= '0';
            wait for clk_period/2;

            report "  Write completed";
        end procedure;

    begin
        report "================================================================================";
        report "MEMORY TESTBENCH";
        report "================================================================================";
        report "";

        -- Hold reset
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;

        report "--- TESTING INITIALIZED PROGRAM MEMORY ---";
        report "";

        -- Test reading initialized program from memory
        read_memory("Read mem[0] - First instruction", x"0000", x"4140");  -- ori $v0, $zero, 0x40
        read_memory("Read mem[1] - NOP", x"0002", x"0000");
        read_memory("Read mem[3] - Third instruction", x"0006", x"4210");  -- ori $v1, $zero, 0x10
        read_memory("Read mem[6] - ABS test", x"000C", x"B33F");  -- li $v2, 0x3F
        read_memory("Read mem[9] - ABS instruction", x"0012", x"C580");  -- abs $t0, $v2

        report "";
        report "--- TESTING DATA SECTION ---";
        report "";

        -- Test reading initialized data
        read_memory("Read data mem[60]", x"0078", x"0001");  -- Data at word 60
        read_memory("Read data mem[61]", x"007A", x"0002");
        read_memory("Read data mem[64]", x"0080", x"0005");

        report "";
        report "--- TESTING WRITE OPERATIONS ---";
        report "";

        -- Write to a new location
        write_memory("Write to mem[100]", x"00C8", x"ABCD");
        read_memory("Read back mem[100]", x"00C8", x"ABCD");

        -- Write to another location
        write_memory("Write to mem[101]", x"00CA", x"1234");
        read_memory("Read back mem[101]", x"00CA", x"1234");

        -- Verify first write is still there
        read_memory("Verify mem[100] unchanged", x"00C8", x"ABCD");

        report "";
        report "--- TESTING ADDRESSING ---";
        report "";

        -- Test that word addressing works (bit 0 ignored)
        write_memory("Write to 0x0050", x"0050", x"5555");
        read_memory("Read from 0x0050", x"0050", x"5555");
        read_memory("Read from 0x0051 (same word)", x"0051", x"5555");  -- Should be same word

        report "";
        report "--- TESTING EDGE CASES ---";
        report "";

        -- Test mem_read = 0 should give 0
        test_count <= test_count + 1;
        report "========================================";
        report "TEST " & integer'image(test_count) & ": Read with mem_read=0";
        address <= x"0000";
        mem_read <= '0';
        wait for clk_period;

        write(line_buf, string'("  Result: 0x"));
        hwrite(line_buf, read_data);
        report line_buf.all;

        report "  Expected: 0x0000";
        if read_data = x"0000" then
            report "  STATUS: PASS";
            pass_count <= pass_count + 1;
        else
            report "  STATUS: FAIL ***";
            fail_count <= fail_count + 1;
        end if;

        -- Test overwriting existing data
        write_memory("Overwrite mem[0]", x"0000", x"FFFF");
        read_memory("Read overwritten mem[0]", x"0000", x"FFFF");

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
