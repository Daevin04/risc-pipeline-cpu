--------------------------------------------------------------------------------
-- Entity: processor_fpga
-- Description: FPGA top-level for Nexys 4 DDR board
-- Connects processor to board I/O (LEDs, 7-segment, buttons, switches)
-- Uses existing SevenSegmentDisplay from Lab 8
-- Author: Lab 4 Team - FPGA Implementation
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.processor_pkg.all;

entity processor_fpga is
    Port (
        -- Clock and reset
        CLK100MHZ   : in  std_logic;                      -- 100 MHz system clock
        CPU_RESETN  : in  std_logic;                      -- Active-low reset button
        
        -- Buttons
        BTNC        : in  std_logic;                      -- Center button (manual reset)
        BTNU        : in  std_logic;                      -- Up button (single step)
        BTNL        : in  std_logic;                      -- Left button (unused for now)
        BTNR        : in  std_logic;                      -- Right button (unused for now)
        BTND        : in  std_logic;                      -- Down button (run/pause)
        
        -- Switches
        SW          : in  std_logic_vector(15 downto 0);  -- 16 switches
        
        -- LEDs
        LED         : out std_logic_vector(15 downto 0);  -- 16 LEDs
        
        -- Seven-segment display
        CA, CB, CC, CD, CE, CF, CG : out std_logic;       -- Segments (active low)
        DP          : out std_logic;                      -- Decimal point
        AN          : out std_logic_vector(7 downto 0)    -- Anodes (active low)
    );
end processor_fpga;

architecture behavioral of processor_fpga is
    
    -- Component declarations
    component processor_top is
        Port (
            clk   : in  std_logic;
            reset : in  std_logic;
            PC    : out word
        );
    end component;
    
    component clock_divider is
        Port (
            clk_in  : in  std_logic;
            reset   : in  std_logic;
            clk_out : out std_logic
        );
    end component;
    
    -- Use the existing SevenSegmentDisplay from Lab 8
    component SevenSegmentDisplay is
        Port (
            CLK100MHZ : in STD_LOGIC;
            BTNC : in STD_LOGIC;
            CPU_RESETN: in STD_LOGIC;
            SW : in STD_LOGIC_VECTOR(15 downto 0);
            CA, CB, CC, CD, CE, CF, CG : out STD_LOGIC;
            DP : out STD_LOGIC;
            AN : out STD_LOGIC_VECTOR(7 downto 0);
            LED : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;
    
    -- Internal signals
    signal reset_sync : std_logic;
    signal clk_slow   : std_logic;  -- Divided clock for visible execution
    signal clk_proc   : std_logic;  -- Clock to processor (slow or fast)
    signal PC         : word;       -- Program counter from processor
    
    -- Mode control
    signal run_mode   : std_logic := '0';  -- 0=stopped, 1=running
    signal step_pulse : std_logic;
    signal prev_btnu  : std_logic := '0';
    
    -- Display control
    signal display_data : std_logic_vector(15 downto 0);  -- Data to display on 7-seg
    
begin

    -- Reset logic (active high, from active-low button or center button)
    reset_sync <= not CPU_RESETN or BTNC;
    
    -- Clock divider for slow execution (~2 Hz for visible operation)
    clk_div: clock_divider
        port map (
            clk_in  => CLK100MHZ,
            reset   => reset_sync,
            clk_out => clk_slow
        );
    
    -- Run/Pause control (toggle on BTND press)
    process(CLK100MHZ, reset_sync)
        variable prev_btnd : std_logic := '0';
    begin
        if reset_sync = '1' then
            run_mode <= '0';
        elsif rising_edge(CLK100MHZ) then
            if BTND = '1' and prev_btnd = '0' then  -- Button press detected
                run_mode <= not run_mode;
            end if;
            prev_btnd := BTND;
        end if;
    end process;
    
    -- Single-step pulse (on BTNU press)
    process(CLK100MHZ, reset_sync)
    begin
        if reset_sync = '1' then
            step_pulse <= '0';
            prev_btnu <= '0';
        elsif rising_edge(CLK100MHZ) then
            if BTNU = '1' and prev_btnu = '0' then
                step_pulse <= '1';
            else
                step_pulse <= '0';
            end if;
            prev_btnu <= BTNU;
        end if;
    end process;
    
    -- Clock selection: step pulse when stopped, slow clock when running
    clk_proc <= step_pulse when run_mode = '0' else
                clk_slow when run_mode = '1' else
                '0';
    
    -- Processor instantiation
    proc: processor_top
        port map (
            clk   => clk_proc,
            reset => reset_sync,
            PC    => PC
        );
    
    -- Display data selection
    -- Use SW[0] to select what to display:
    -- SW[0]=0: Display PC on 7-segment
    -- SW[0]=1: Display PC on 7-segment (same for now, could add instruction later)
    display_data <= PC;
    
    -- Instantiate your existing Seven-Segment Display from Lab 8
    -- This will display the PC value on the 4 rightmost digits
    seven_seg: SevenSegmentDisplay
        port map (
            CLK100MHZ  => CLK100MHZ,
            BTNC       => BTNC,
            CPU_RESETN => CPU_RESETN,
            SW         => display_data,  -- Connect PC to SW input
            CA         => CA,
            CB         => CB,
            CC         => CC,
            CD         => CD,
            CE         => CE,
            CF         => CF,
            CG         => CG,
            DP         => DP,
            AN         => AN,
            LED        => LED            -- LEDs will mirror the PC value
        );

end behavioral;