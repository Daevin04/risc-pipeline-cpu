--------------------------------------------------------------------------------
-- Entity: hazard_detection_unit
-- Description: Detects load-use hazards and generates stall signals
-- Stalls the pipeline when a load instruction is followed by a dependent instruction
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.processor_pkg.all;

entity hazard_detection_unit is
    Port (
        -- IF/ID stage (current instruction in ID)
        IFID_rs        : in  reg_addr;
        IFID_rt        : in  reg_addr;

        -- ID/EX stage (instruction in EX)
        IDEX_rt        : in  reg_addr;
        IDEX_MemRead   : in  std_logic;

        -- Stall and flush signals
        PC_Write       : out std_logic;  -- Enable PC update (0=stall)
        IFID_Write     : out std_logic;  -- Enable IF/ID register update (0=stall)
        Control_Flush  : out std_logic   -- Insert bubble in EX stage (1=flush)
    );
end hazard_detection_unit;

architecture behavioral of hazard_detection_unit is
begin

    hazard_detect: process(IFID_rs, IFID_rt, IDEX_rt, IDEX_MemRead)
    begin
        -- Default: no stall
        PC_Write <= '1';
        IFID_Write <= '1';
        Control_Flush <= '0';

        -- Load-use hazard detection
        -- If instruction in EX is a load and current instruction in ID uses the loaded register
        if (IDEX_MemRead = '1' and
            ((IDEX_rt = IFID_rs) or (IDEX_rt = IFID_rt))) then
            -- Stall the pipeline
            PC_Write <= '0';       -- Don't update PC
            IFID_Write <= '0';     -- Don't update IF/ID
            Control_Flush <= '1';  -- Insert bubble (NOP) in EX
        end if;
    end process;

end behavioral;
