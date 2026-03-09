--------------------------------------------------------------------------------
-- Entity: SevenSegmentDisplay
-- Description: Seven-segment display driver for Nexys 4 DDR
-- From Lab 8 - Adapted for use with processor
-- Displays 16-bit value on 4 rightmost seven-segment displays
-- Author: Student (from Lab 8)
-- Date: Original Lab 8, adapted November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SevenSegmentDisplay is
    Port (
        CLK100MHZ : in STD_LOGIC; -- 100 MHz system clock
        BTNC : in STD_LOGIC; -- Center button for reset
        CPU_RESETN: in STD_LOGIC; -- CPU reset signal (active-low)
        SW : in STD_LOGIC_VECTOR(15 downto 0); -- 16 switches for BCD input
        CA, CB, CC, CD, CE, CF, CG : out STD_LOGIC; -- Segment outputs
        DP : out STD_LOGIC; -- Decimal point control
        AN : out STD_LOGIC_VECTOR(7 downto 0); -- Anode control (8 digits, lower 4 used)
        LED : out STD_LOGIC_VECTOR(15 downto 0) -- LEDs mirror the switches
    );
end SevenSegmentDisplay;

architecture Behavioral of SevenSegmentDisplay is
    signal sclk : STD_LOGIC; -- Slow clock for multiplexing
    signal BCD_digit : STD_LOGIC_VECTOR(3 downto 0); -- Current BCD digit to display
    signal digit_select : STD_LOGIC_VECTOR(1 downto 0); -- Selects the active digit (0-3)
    signal count : INTEGER range 0 to 2047 := 0; -- Counter for clock division
    constant DIVISOR : INTEGER := 1000; -- Divisor for the multiplexing rate (adjust as needed)
begin

    -- Mirror switches to LEDs for visual feedback
    LED <= SW;

    -- Clock Divider for Slow Clock (sclk) from CLK100MHZ
    process(CLK100MHZ, BTNC)
    begin
        if BTNC = '1' or CPU_RESETN = '0' then
            count <= 0;
            sclk <= '0';
        elsif rising_edge(CLK100MHZ) then
            if count = DIVISOR then
                sclk <= NOT sclk;
                count <= 0;
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    -- Multiplexing Process to Cycle Through Digits and Assign BCD_digit
    process(sclk, BTNC)
    begin
        if BTNC = '1' then
            digit_select <= "00";
            AN <= "11111111"; -- Turn off all digits (only using AN0 to AN3)
            BCD_digit <= "0000"; -- Initialize BCD_digit
        elsif rising_edge(sclk) then
            case digit_select is
                when "00" =>
                    AN <= "11111110"; -- Activate digit 0 (rightmost)
                    BCD_digit <= SW(3 downto 0); -- Assign rightmost 4 bits to BCD_digit
                    digit_select <= "01";
                when "01" =>
                    AN <= "11111101"; -- Activate digit 1
                    BCD_digit <= SW(7 downto 4); -- Assign next 4 bits
                    digit_select <= "10";
                when "10" =>
                    AN <= "11111011"; -- Activate digit 2
                    BCD_digit <= SW(11 downto 8); -- Assign next 4 bits
                    digit_select <= "11";
                when "11" =>
                    AN <= "11110111"; -- Activate digit 3 (leftmost of 4)
                    BCD_digit <= SW(15 downto 12); -- Assign leftmost 4 bits
                    digit_select <= "00";
                when others =>
                    digit_select <= "00";
            end case;
        end if;
    end process;

    -- 7-Segment Display Decoder Process (Converts BCD to Segment Encoding)
    process(BCD_digit)
    begin
        -- Default: Turn off all segments (for invalid BCD values 10-15)
        CA <= '1'; CB <= '1'; CC <= '1'; CD <= '1';
        CE <= '1'; CF <= '1'; CG <= '1';
        
        case BCD_digit is
            when "0000" => -- 0
                CA <= '0'; CB <= '0'; CC <= '0'; CD <= '0';
                CE <= '0'; CF <= '0'; CG <= '1';
            when "0001" => -- 1
                CA <= '1'; CB <= '0'; CC <= '0'; CD <= '1';
                CE <= '1'; CF <= '1'; CG <= '1';
            when "0010" => -- 2
                CA <= '0'; CB <= '0'; CC <= '1'; CD <= '0';
                CE <= '0'; CF <= '1'; CG <= '0';
            when "0011" => -- 3
                CA <= '0'; CB <= '0'; CC <= '0'; CD <= '0';
                CE <= '1'; CF <= '1'; CG <= '0';
            when "0100" => -- 4
                CA <= '1'; CB <= '0'; CC <= '0'; CD <= '1';
                CE <= '1'; CF <= '0'; CG <= '0';
            when "0101" => -- 5
                CA <= '0'; CB <= '1'; CC <= '0'; CD <= '0';
                CE <= '1'; CF <= '0'; CG <= '0';
            when "0110" => -- 6
                CA <= '0'; CB <= '1'; CC <= '0'; CD <= '0';
                CE <= '0'; CF <= '0'; CG <= '0';
            when "0111" => -- 7
                CA <= '0'; CB <= '0'; CC <= '0'; CD <= '1';
                CE <= '1'; CF <= '1'; CG <= '1';
            when "1000" => -- 8
                CA <= '0'; CB <= '0'; CC <= '0'; CD <= '0';
                CE <= '0'; CF <= '0'; CG <= '0';
            when "1001" => -- 9
                CA <= '0'; CB <= '0'; CC <= '0'; CD <= '0';
                CE <= '1'; CF <= '0'; CG <= '0';
            when others => -- Invalid BCD values (10-15)
                CA <= '1'; CB <= '1'; CC <= '1'; CD <= '1';
                CE <= '1'; CF <= '1'; CG <= '1';
        end case;
    end process;

    -- Decimal Point Control Process
    process(digit_select)
    begin
        if digit_select = "11" then
            DP <= '0'; -- Decimal point on for digit 3 (leftmost) only
        else
            DP <= '1'; -- Decimal point off
        end if;
    end process;

end Behavioral;