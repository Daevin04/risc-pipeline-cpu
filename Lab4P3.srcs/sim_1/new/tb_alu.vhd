--------------------------------------------------------------------------------
-- Testbench: tb_alu
-- Description: Comprehensive test of ALU with all 11 operations
-- Tests: AND, OR, ADD, XOR, SUB, SLT, SRA, ABS, MIN, MAX, PASS_B
-- Outputs detailed results to TCL console for analysis
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.processor_pkg.all;

entity tb_alu is
end tb_alu;

architecture behavioral of tb_alu is

    component alu is
        Port (
            alu_control : in  alu_control_type;
            operand_a   : in  word;
            operand_b   : in  word;
            shamt       : in  std_logic;
            result      : out word;
            zero_flag   : out std_logic
        );
    end component;

    signal alu_control : alu_control_type := (others => '0');
    signal operand_a   : word := (others => '0');
    signal operand_b   : word := (others => '0');
    signal shamt       : std_logic := '0';
    signal result      : word;
    signal zero_flag   : std_logic;

    signal test_count : integer := 0;
    signal pass_count : integer := 0;
    signal fail_count : integer := 0;

begin

    uut: alu
        port map (
            alu_control => alu_control,
            operand_a   => operand_a,
            operand_b   => operand_b,
            shamt       => shamt,
            result      => result,
            zero_flag   => zero_flag
        );

    test_proc: process
        variable expected : std_logic_vector(15 downto 0);
        variable expected_zero : std_logic;

        procedure test_alu_op(
            op_name : string;
            alu_op  : alu_control_type;
            a       : word;
            b       : word;
            sh      : std_logic;
            exp_res : word;
            exp_z   : std_logic
        ) is
            variable line_buf : line;
        begin
            test_count <= test_count + 1;
            operand_a <= a;
            operand_b <= b;
            alu_control <= alu_op;
            shamt <= sh;
            wait for 10 ns;

            report "========================================";
            report "TEST " & integer'image(test_count) & ": " & op_name;

            write(line_buf, string'("  Operand A:     "));
            hwrite(line_buf, a);
            write(line_buf, string'(" ("));
            write(line_buf, to_integer(signed(a)));
            write(line_buf, string'(")"));
            report line_buf.all;

            write(line_buf, string'("  Operand B:     "));
            hwrite(line_buf, b);
            write(line_buf, string'(" ("));
            write(line_buf, to_integer(signed(b)));
            write(line_buf, string'(")"));
            report line_buf.all;

            report "  Shamt:         " & std_logic'image(sh);

            write(line_buf, string'("  ALU Control:   "));
            hwrite(line_buf, alu_op);
            report line_buf.all;

            write(line_buf, string'("  Result:        "));
            hwrite(line_buf, result);
            write(line_buf, string'(" ("));
            write(line_buf, to_integer(signed(result)));
            write(line_buf, string'(")"));
            report line_buf.all;

            report "  Zero Flag:     " & std_logic'image(zero_flag);

            write(line_buf, string'("  Expected Res:  "));
            hwrite(line_buf, exp_res);
            write(line_buf, string'(" ("));
            write(line_buf, to_integer(signed(exp_res)));
            write(line_buf, string'(")"));
            report line_buf.all;

            report "  Expected Zero: " & std_logic'image(exp_z);

            if result = exp_res and zero_flag = exp_z then
                report "  STATUS: PASS";
                pass_count <= pass_count + 1;
            else
                report "  STATUS: FAIL ***";
                fail_count <= fail_count + 1;
            end if;

        end procedure;

    begin
        wait for 20 ns;

        report "================================================================================";
        report "ALU TESTBENCH - Testing All 11 Operations";
        report "================================================================================";
        report "";

        -- Test 1: AND operation
        test_alu_op("AND", ALU_AND, x"FF0F", x"F0F0", '0', x"F000", '0');

        -- Test 2: OR operation
        test_alu_op("OR", ALU_OR, x"FF0F", x"F0F0", '0', x"FFFF", '0');

        -- Test 3: ADD operation (positive)
        test_alu_op("ADD (positive)", ALU_ADD, x"0005", x"0003", '0', x"0008", '0');

        -- Test 4: ADD operation (result = 0)
        test_alu_op("ADD (zero result)", ALU_ADD, x"0005", x"FFFB", '0', x"0000", '1');

        -- Test 5: XOR operation
        test_alu_op("XOR", ALU_XOR, x"FFFF", x"FF00", '0', x"00FF", '0');

        -- Test 6: SUB operation
        test_alu_op("SUB", ALU_SUB, x"000A", x"0003", '0', x"0007", '0');

        -- Test 7: SUB (result = 0)
        test_alu_op("SUB (zero result)", ALU_SUB, x"0005", x"0005", '0', x"0000", '1');

        -- Test 8: SLT (less than)
        test_alu_op("SLT (true)", ALU_SLT, x"0003", x"0005", '0', x"0001", '0');

        -- Test 9: SLT (not less than)
        test_alu_op("SLT (false)", ALU_SLT, x"0005", x"0003", '0', x"0000", '1');

        -- Test 10: SRA (shift right arithmetic, shamt=0)
        test_alu_op("SRA (shamt=0)", ALU_SRA, x"8004", x"0000", '0', x"C002", '0');

        -- Test 11: SRA (shift right arithmetic, shamt=1)
        test_alu_op("SRA (shamt=1)", ALU_SRA, x"8004", x"0000", '1', x"E001", '0');

        -- Test 12: ABS (positive number - CUSTOM INSTRUCTION)
        test_alu_op("ABS (positive)", ALU_ABS, x"0042", x"0000", '0', x"0042", '0');

        -- Test 13: ABS (negative number - CUSTOM INSTRUCTION)
        test_alu_op("ABS (negative)", ALU_ABS, x"FFC1", x"0000", '0', x"003F", '0');

        -- Test 14: ABS (zero - CUSTOM INSTRUCTION)
        test_alu_op("ABS (zero)", ALU_ABS, x"0000", x"0000", '0', x"0000", '1');

        -- Test 15: MIN (a < b - CUSTOM INSTRUCTION)
        test_alu_op("MIN (a < b)", ALU_MIN, x"0005", x"000A", '0', x"0005", '0');

        -- Test 16: MIN (a > b - CUSTOM INSTRUCTION)
        test_alu_op("MIN (a > b)", ALU_MIN, x"000A", x"0005", '0', x"0005", '0');

        -- Test 17: MIN (a = b - CUSTOM INSTRUCTION)
        test_alu_op("MIN (a = b)", ALU_MIN, x"0007", x"0007", '0', x"0007", '0');

        -- Test 18: MAX (a < b - CUSTOM INSTRUCTION)
        test_alu_op("MAX (a < b)", ALU_MAX, x"0005", x"000A", '0', x"000A", '0');

        -- Test 19: MAX (a > b - CUSTOM INSTRUCTION)
        test_alu_op("MAX (a > b)", ALU_MAX, x"000A", x"0005", '0', x"000A", '0');

        -- Test 20: MAX (a = b - CUSTOM INSTRUCTION)
        test_alu_op("MAX (a = b)", ALU_MAX, x"0007", x"0007", '0', x"0007", '0');

        -- Test 21: PASS_B (for LI instruction)
        test_alu_op("PASS_B", ALU_PASS_B, x"1234", x"5678", '0', x"5678", '0');

        wait for 20 ns;

        report "";
        report "================================================================================";
        report "ALU TESTBENCH COMPLETE";
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
