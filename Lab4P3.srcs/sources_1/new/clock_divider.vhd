--------------------------------------------------------------------------------
-- Entity: clock_divider
-- Description: Divides 100 MHz system clock to visible speed (~1-2 Hz)
-- For Nexys 4 DDR FPGA Board
-- Author: Lab 4 Team - FPGA Implementation
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_divider is
    Port (
        clk_in      : in  std_logic;  -- 100 MHz input
        reset       : in  std_logic;
        clk_out     : out std_logic   -- ~1 Hz output (adjustable)
    );
end clock_divider;

architecture behavioral of clock_divider is
    -- For 100 MHz to 1 Hz: divide by 100,000,000
    -- For 100 MHz to 2 Hz: divide by 50,000,000
    -- Using 50,000,000 for 2 Hz execution speed
    constant DIVISOR : integer := 50000000;
    signal counter : integer range 0 to DIVISOR-1 := 0;
    signal clk_div : std_logic := '0';
begin

    process(clk_in, reset)
    begin
        if reset = '1' then
            counter <= 0;
            clk_div <= '0';
        elsif rising_edge(clk_in) then
            if counter = DIVISOR-1 then
                counter <= 0;
                clk_div <= not clk_div;  -- Toggle clock
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    
    clk_out <= clk_div;

end behavioral;