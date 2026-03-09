--------------------------------------------------------------------------------
-- Entity: ID_EX_reg
-- Description: ID/EX Pipeline Register
-- Stores: Control signals, register data, immediates from Decode to Execute
-- Author: Lab 4 Team
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.processor_pkg.all;

entity ID_EX_reg is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        stall       : in  std_logic;
        flush       : in  std_logic;
        
        -- Control signals IN
        RegDst_in      : in  std_logic;
        ALUSrc_in      : in  std_logic;
        ALUOp_in       : in  std_logic_vector(1 downto 0);
        MemRead_in     : in  std_logic;
        MemWrite_in    : in  std_logic;
        MemtoReg_in    : in  std_logic;
        RegWrite_in    : in  std_logic;
        Branch_in      : in  std_logic;
        Jump_in        : in  std_logic;
        BranchNotEq_in : in  std_logic;
        
        -- Data IN
        PC_in          : in  word;
        read_data1_in  : in  word;
        read_data2_in  : in  word;
        imm_extended_in: in  word;
        rs_in          : in  reg_addr;
        rt_in          : in  reg_addr;
        rd_in          : in  reg_addr;
        shamt_in       : in  std_logic;
        funct_in       : in  funct_type;
        opcode_in      : in  opcode_type;
        
        -- Control signals OUT
        RegDst_out      : out std_logic;
        ALUSrc_out      : out std_logic;
        ALUOp_out       : out std_logic_vector(1 downto 0);
        MemRead_out     : out std_logic;
        MemWrite_out    : out std_logic;
        MemtoReg_out    : out std_logic;
        RegWrite_out    : out std_logic;
        Branch_out      : out std_logic;
        Jump_out        : out std_logic;
        BranchNotEq_out : out std_logic;
        
        -- Data OUT
        PC_out          : out word;
        read_data1_out  : out word;
        read_data2_out  : out word;
        imm_extended_out: out word;
        rs_out          : out reg_addr;
        rt_out          : out reg_addr;
        rd_out          : out reg_addr;
        shamt_out       : out std_logic;
        funct_out       : out funct_type;
        opcode_out      : out opcode_type
    );
end ID_EX_reg;

architecture behavioral of ID_EX_reg is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            -- Clear all control signals
            RegDst_out <= '0';
            ALUSrc_out <= '0';
            ALUOp_out <= "00";
            MemRead_out <= '0';
            MemWrite_out <= '0';
            MemtoReg_out <= '0';
            RegWrite_out <= '0';
            Branch_out <= '0';
            Jump_out <= '0';
            BranchNotEq_out <= '0';
            
            -- Clear data
            PC_out <= (others => '0');
            read_data1_out <= (others => '0');
            read_data2_out <= (others => '0');
            imm_extended_out <= (others => '0');
            rs_out <= (others => '0');
            rt_out <= (others => '0');
            rd_out <= (others => '0');
            shamt_out <= '0';
            funct_out <= (others => '0');
            opcode_out <= (others => '0');
            
        elsif rising_edge(clk) then
            if flush = '1' then
                -- Insert bubble (clear control signals)
                RegDst_out <= '0';
                ALUSrc_out <= '0';
                ALUOp_out <= "00";
                MemRead_out <= '0';
                MemWrite_out <= '0';
                MemtoReg_out <= '0';
                RegWrite_out <= '0';
                Branch_out <= '0';
                Jump_out <= '0';
                BranchNotEq_out <= '0';
                
            elsif stall = '0' then
                -- Normal operation - pass everything through
                RegDst_out <= RegDst_in;
                ALUSrc_out <= ALUSrc_in;
                ALUOp_out <= ALUOp_in;
                MemRead_out <= MemRead_in;
                MemWrite_out <= MemWrite_in;
                MemtoReg_out <= MemtoReg_in;
                RegWrite_out <= RegWrite_in;
                Branch_out <= Branch_in;
                Jump_out <= Jump_in;
                BranchNotEq_out <= BranchNotEq_in;
                
                PC_out <= PC_in;
                read_data1_out <= read_data1_in;
                read_data2_out <= read_data2_in;
                imm_extended_out <= imm_extended_in;
                rs_out <= rs_in;
                rt_out <= rt_in;
                rd_out <= rd_in;
                shamt_out <= shamt_in;
                funct_out <= funct_in;
                opcode_out <= opcode_in;
            end if;
        end if;
    end process;
end behavioral;