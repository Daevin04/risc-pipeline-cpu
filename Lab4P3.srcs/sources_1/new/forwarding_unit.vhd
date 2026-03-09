--------------------------------------------------------------------------------
-- Entity: forwarding_unit
-- Description: Detects and resolves data hazards through forwarding
-- Implements EX-to-EX forwarding from MEM and WB stages
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.processor_pkg.all;

entity forwarding_unit is
    Port (
        -- ID/EX stage (current instruction in EX)
        IDEX_rs        : in  reg_addr;
        IDEX_rt        : in  reg_addr;

        -- EX/MEM stage (previous instruction in MEM)
        EXMEM_RegWrite : in  std_logic;
        EXMEM_rd       : in  reg_addr;

        -- MEM/WB stage (instruction in WB)
        MEMWB_RegWrite : in  std_logic;
        MEMWB_rd       : in  reg_addr;

        -- Forwarding control outputs
        ForwardA       : out std_logic_vector(1 downto 0);  -- For ALU operand A
        ForwardB       : out std_logic_vector(1 downto 0)   -- For ALU operand B
    );
end forwarding_unit;

architecture behavioral of forwarding_unit is
begin

    -- Forward ALU operand A
    forward_a_logic: process(IDEX_rs, EXMEM_RegWrite, EXMEM_rd, MEMWB_RegWrite, MEMWB_rd)
    begin
        -- Default: no forwarding
        ForwardA <= "00";

        -- EX hazard (forward from MEM stage)
        if (EXMEM_RegWrite = '1' and EXMEM_rd /= "000" and EXMEM_rd = IDEX_rs) then
            ForwardA <= "10";  -- Forward from EX/MEM
        -- MEM hazard (forward from WB stage)
        elsif (MEMWB_RegWrite = '1' and MEMWB_rd /= "000" and MEMWB_rd = IDEX_rs) then
            ForwardA <= "01";  -- Forward from MEM/WB
        end if;
    end process;

    -- Forward ALU operand B
    forward_b_logic: process(IDEX_rt, EXMEM_RegWrite, EXMEM_rd, MEMWB_RegWrite, MEMWB_rd)
    begin
        -- Default: no forwarding
        ForwardB <= "00";

        -- EX hazard (forward from MEM stage)
        if (EXMEM_RegWrite = '1' and EXMEM_rd /= "000" and EXMEM_rd = IDEX_rt) then
            ForwardB <= "10";  -- Forward from EX/MEM
        -- MEM hazard (forward from WB stage)
        elsif (MEMWB_RegWrite = '1' and MEMWB_rd /= "000" and MEMWB_rd = IDEX_rt) then
            ForwardB <= "01";  -- Forward from MEM/WB
        end if;
    end process;

end behavioral;
