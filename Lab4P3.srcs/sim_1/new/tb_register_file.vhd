--------------------------------------------------------------------------------
-- Testbench: tb_register_file
-- Description: Test register file read/write operations
-- Tests: Write enable, read ports, R0 hardwired to zero
-- Outputs detailed results to TCL console for analysis
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.processor_pkg.all;

entity tb_register_file is
end tb_register_file;

architecture behavioral of tb_register_file is

    component register_file is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            read_addr1   : in  reg_addr;
            read_addr2   : in  reg_addr;
            read_data1   : out word;
            read_data2   : out word;
            write_addr   : in  reg_addr;
            write_data   : in  word;
            write_enable : in  std_logic
        );
    end component;

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal read_addr1   : reg_addr := (others => '0');
    signal read_addr2   : reg_addr := (others => '0');
    signal read_data1   : word;
    signal read_data2   : word;
    signal write_addr   : reg_addr := (others => '0');
    signal write_data   : word := (others => '0');
    signal write_enable : std_logic := '0';

    constant clk_period : time := 10 ns;
    signal test_count : integer := 0;
    signal pass_count : integer := 0;
    signal fail_count : integer := 0;

begin

    uut: register_file
        port map (
            clk          => clk,
            reset        => reset,
            read_addr1   => read_addr1,
            read_addr2   => read_addr2,
            read_data1   => read_data1,
            read_data2   => read_data2,
            write_addr   => write_addr,
            write_data   => write_data,
            write_enable => write_enable
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

        procedure write_register(
            test_name : string;
            reg       : reg_addr;
            data      : word
        ) is
            variable line_buf : line;
        begin
            test_count <= test_count + 1;
            report "========================================";
            report "TEST " & integer'image(test_count) & ": " & test_name;

            write(line_buf, string'("  Writing: Reg["));
            write(line_buf, to_integer(unsigned(reg)));
            write(line_buf, string'("] = "));
            hwrite(line_buf, data);
            report line_buf.all;

            write_addr <= reg;
            write_data <= data;
            write_enable <= '1';
            wait for clk_period;
            write_enable <= '0';
            wait for clk_period/2;
        end procedure;

        procedure read_and_verify(
            test_name : string;
            reg       : reg_addr;
            expected  : word
        ) is
            variable line_buf : line;
        begin
            test_count <= test_count + 1;
            report "========================================";
            report "TEST " & integer'image(test_count) & ": " & test_name;

            read_addr1 <= reg;
            wait for 5 ns;

            write(line_buf, string'("  Reading: Reg["));
            write(line_buf, to_integer(unsigned(reg)));
            write(line_buf, string'("]"));
            report line_buf.all;

            write(line_buf, string'("  Result:   "));
            hwrite(line_buf, read_data1);
            report line_buf.all;

            write(line_buf, string'("  Expected: "));
            hwrite(line_buf, expected);
            report line_buf.all;

            if read_data1 = expected then
                report "  STATUS: PASS";
                pass_count <= pass_count + 1;
            else
                report "  STATUS: FAIL ***";
                fail_count <= fail_count + 1;
            end if;
        end procedure;

        procedure read_two_and_verify(
            test_name : string;
            reg1      : reg_addr;
            reg2      : reg_addr;
            expected1 : word;
            expected2 : word
        ) is
            variable line_buf : line;
        begin
            test_count <= test_count + 1;
            report "========================================";
            report "TEST " & integer'image(test_count) & ": " & test_name;

            read_addr1 <= reg1;
            read_addr2 <= reg2;
            wait for 5 ns;

            write(line_buf, string'("  Reading: Reg["));
            write(line_buf, to_integer(unsigned(reg1)));
            write(line_buf, string'("] and Reg["));
            write(line_buf, to_integer(unsigned(reg2)));
            write(line_buf, string'("]"));
            report line_buf.all;

            write(line_buf, string'("  Result 1:   "));
            hwrite(line_buf, read_data1);
            report line_buf.all;

            write(line_buf, string'("  Expected 1: "));
            hwrite(line_buf, expected1);
            report line_buf.all;

            write(line_buf, string'("  Result 2:   "));
            hwrite(line_buf, read_data2);
            report line_buf.all;

            write(line_buf, string'("  Expected 2: "));
            hwrite(line_buf, expected2);
            report line_buf.all;

            if read_data1 = expected1 and read_data2 = expected2 then
                report "  STATUS: PASS";
                pass_count <= pass_count + 1;
            else
                report "  STATUS: FAIL ***";
                fail_count <= fail_count + 1;
            end if;
        end procedure;

    begin
        report "================================================================================";
        report "REGISTER FILE TESTBENCH";
        report "================================================================================";
        report "";

        -- Hold reset
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;

        -- Test 1: Verify all registers are zero after reset
        read_and_verify("Reset - Verify R0 = 0", REG_ZERO, x"0000");
        read_and_verify("Reset - Verify R1 = 0", REG_V0, x"0000");
        read_and_verify("Reset - Verify R7 = 0", REG_A1, x"0000");

        -- Test 2: Write to R1 (V0)
        write_register("Write R1", REG_V0, x"1234");
        read_and_verify("Read R1 back", REG_V0, x"1234");

        -- Test 3: Write to R2 (V1)
        write_register("Write R2", REG_V1, x"5678");
        read_and_verify("Read R2 back", REG_V1, x"5678");

        -- Test 4: Verify R1 still has old value
        read_and_verify("Verify R1 unchanged", REG_V0, x"1234");

        -- Test 5: Write to all registers
        write_register("Write R3", REG_V2, x"AAAA");
        write_register("Write R4", REG_V3, x"BBBB");
        write_register("Write R5", REG_T0, x"CCCC");
        write_register("Write R6", REG_A0, x"DDDD");
        write_register("Write R7", REG_A1, x"EEEE");

        -- Test 6: Read two registers simultaneously
        read_two_and_verify("Dual read R1 and R2", REG_V0, REG_V1, x"1234", x"5678");
        read_two_and_verify("Dual read R5 and R7", REG_T0, REG_A1, x"CCCC", x"EEEE");

        -- Test 7: CRITICAL - Try to write to R0 (should remain 0)
        write_register("Attempt write to R0", REG_ZERO, x"FFFF");
        read_and_verify("Verify R0 still zero", REG_ZERO, x"0000");

        -- Test 8: Write when write_enable = 0 (should not write)
        read_addr1 <= REG_V0;
        wait for 5 ns;
        test_count <= test_count + 1;
        report "========================================";
        report "TEST " & integer'image(test_count) & ": Write with write_enable=0";

        write(line_buf, string'("  Current R1 value: "));
        hwrite(line_buf, read_data1);
        report line_buf.all;

        write_addr <= REG_V0;
        write_data <= x"9999";
        write_enable <= '0';  -- Write disabled
        wait for clk_period;

        read_addr1 <= REG_V0;
        wait for 5 ns;

        write(line_buf, string'("  After write attempt: "));
        hwrite(line_buf, read_data1);
        report line_buf.all;

        if read_data1 = x"1234" then
            report "  STATUS: PASS (correctly ignored write)";
            pass_count <= pass_count + 1;
        else
            report "  STATUS: FAIL (incorrectly wrote data)";
            fail_count <= fail_count + 1;
        end if;

        wait for clk_period * 2;

        report "";
        report "================================================================================";
        report "REGISTER FILE TESTBENCH COMPLETE";
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
