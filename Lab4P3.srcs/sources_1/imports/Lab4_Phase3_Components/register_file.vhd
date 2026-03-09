--------------------------------------------------------------------------------
-- Entity: register_file
-- Description: 8-register file with 2 read ports and 1 write port
-- Features:
--   - R0 ($zero) is hardwired to 0
--   - Synchronous write on rising edge
--   - Asynchronous read
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.processor_pkg.all;

entity register_file is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        -- Read ports
        read_addr1   : in  reg_addr;              -- 3-bit address
        read_addr2   : in  reg_addr;              -- 3-bit address
        read_data1   : out word;                  -- 16-bit data output
        read_data2   : out word;                  -- 16-bit data output
        -- Write port
        write_addr   : in  reg_addr;              -- 3-bit address
        write_data   : in  word;                  -- 16-bit data input
        write_enable : in  std_logic              -- Write enable signal
    );
end register_file;

architecture behavioral of register_file is
    -- Array of 8 registers, each 16 bits wide
    type reg_array_type is array (0 to 7) of word;
    signal registers : reg_array_type;
    
begin

    -- Synchronous write process
    write_process: process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all registers to 0
            for i in 0 to 7 loop
                registers(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if write_enable = '1' then
                -- Write to register (but not R0)
                if write_addr /= "000" then
                    registers(to_integer(unsigned(write_addr))) <= write_data;
                end if;
                -- Note: Writing to R0 is ignored (it stays 0)
            end if;
        end if;
    end process;
    
    -- Asynchronous read process for port 1
    -- WITH WRITE-THROUGH FORWARDING: If reading the register being written, forward write data
    read_process1: process(read_addr1, registers, write_enable, write_addr, write_data)
    begin
        if write_enable = '1' and write_addr = read_addr1 and write_addr /= "000" then
            -- Forward the data being written (write-through)
            read_data1 <= write_data;
        else
            -- Normal read from register array
            read_data1 <= registers(to_integer(unsigned(read_addr1)));
        end if;
    end process;

    -- Asynchronous read process for port 2
    -- WITH WRITE-THROUGH FORWARDING: If reading the register being written, forward write data
    read_process2: process(read_addr2, registers, write_enable, write_addr, write_data)
    begin
        if write_enable = '1' and write_addr = read_addr2 and write_addr /= "000" then
            -- Forward the data being written (write-through)
            read_data2 <= write_data;
        else
            -- Normal read from register array
            read_data2 <= registers(to_integer(unsigned(read_addr2)));
        end if;
    end process;

end behavioral;
