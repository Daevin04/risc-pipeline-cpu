--------------------------------------------------------------------------------
-- Entity: datapath_pipelined
-- Description: 5-stage pipelined datapath for 16-bit RISC processor
-- Stages: IF → ID → EX → MEM → WB
-- Features: Hardware forwarding (EX-to-EX) and hazard detection
-- Author: Lab 4 Team
-- Date: November 2025
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.processor_pkg.all;

entity datapath_pipelined is
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        -- Instruction input
        instruction     : in  word;
        -- Memory interface
        mem_read_data   : in  word;
        mem_address     : out word;
        mem_write_data  : out word;
        -- Control signals
        MemRead         : out std_logic;
        MemWrite        : out std_logic;
        -- PC output
        PC_out          : out word
    );
end datapath_pipelined;

architecture behavioral of datapath_pipelined is
    
    -- Component declarations
    component IF_ID_reg is
        Port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            stall       : in  std_logic;
            flush       : in  std_logic;
            PC_in       : in  word;
            instr_in    : in  word;
            PC_out      : out word;
            instr_out   : out word
        );
    end component;
    
    component ID_EX_reg is
        Port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            stall       : in  std_logic;
            flush       : in  std_logic;
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
    end component;
    
    component EX_MEM_reg is
        Port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            MemRead_in     : in  std_logic;
            MemWrite_in    : in  std_logic;
            MemtoReg_in    : in  std_logic;
            RegWrite_in    : in  std_logic;
            Branch_in      : in  std_logic;
            Jump_in        : in  std_logic;
            BranchNotEq_in : in  std_logic;
            branch_target_in : in  word;
            zero_flag_in     : in  std_logic;
            alu_result_in    : in  word;
            read_data2_in    : in  word;
            write_reg_in     : in  reg_addr;
            MemRead_out     : out std_logic;
            MemWrite_out    : out std_logic;
            MemtoReg_out    : out std_logic;
            RegWrite_out    : out std_logic;
            Branch_out      : out std_logic;
            Jump_out        : out std_logic;
            BranchNotEq_out : out std_logic;
            branch_target_out : out word;
            zero_flag_out     : out std_logic;
            alu_result_out    : out word;
            read_data2_out    : out word;
            write_reg_out     : out reg_addr
        );
    end component;
    
    component MEM_WB_reg is
        Port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            MemtoReg_in    : in  std_logic;
            RegWrite_in    : in  std_logic;
            mem_data_in    : in  word;
            alu_result_in  : in  word;
            write_reg_in   : in  reg_addr;
            MemtoReg_out   : out std_logic;
            RegWrite_out   : out std_logic;
            mem_data_out   : out word;
            alu_result_out : out word;
            write_reg_out  : out reg_addr
        );
    end component;
    
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
    
    component alu_control is
        Port (
            ALUOp       : in  std_logic_vector(1 downto 0);
            funct       : in  funct_type;
            opcode      : in  opcode_type;
            alu_control : out alu_control_type
        );
    end component;
    
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
    
    component control_unit is
        Port (
            opcode      : in  opcode_type;
            RegDst      : out std_logic;
            Jump        : out std_logic;
            Branch      : out std_logic;
            MemRead     : out std_logic;
            MemtoReg    : out std_logic;
            ALUOp       : out std_logic_vector(1 downto 0);
            MemWrite    : out std_logic;
            ALUSrc      : out std_logic;
            RegWrite    : out std_logic;
            BranchNotEq : out std_logic
        );
    end component;

    component forwarding_unit is
        Port (
            IDEX_rs        : in  reg_addr;
            IDEX_rt        : in  reg_addr;
            EXMEM_RegWrite : in  std_logic;
            EXMEM_rd       : in  reg_addr;
            MEMWB_RegWrite : in  std_logic;
            MEMWB_rd       : in  reg_addr;
            ForwardA       : out std_logic_vector(1 downto 0);
            ForwardB       : out std_logic_vector(1 downto 0)
        );
    end component;

    component hazard_detection_unit is
        Port (
            IFID_rs        : in  reg_addr;
            IFID_rt        : in  reg_addr;
            IDEX_rt        : in  reg_addr;
            IDEX_MemRead   : in  std_logic;
            PC_Write       : out std_logic;
            IFID_Write     : out std_logic;
            Control_Flush  : out std_logic
        );
    end component;

    --------------------------------------------------------------------------------
    -- STAGE 1: IF (Instruction Fetch) signals
    --------------------------------------------------------------------------------
    signal IF_PC, IF_PC_next, IF_PC_plus_2 : word;
    
    --------------------------------------------------------------------------------
    -- IF/ID Pipeline Register signals
    --------------------------------------------------------------------------------
    signal IFID_PC : word;
    signal IFID_instruction : word;
    signal IFID_stall, IFID_flush : std_logic;
    
    --------------------------------------------------------------------------------
    -- STAGE 2: ID (Instruction Decode) signals
    --------------------------------------------------------------------------------
    signal ID_opcode     : opcode_type;
    signal ID_rs, ID_rt, ID_rd : reg_addr;
    signal ID_shamt      : std_logic;
    signal ID_funct      : funct_type;
    signal ID_immediate  : immediate_type;
    signal ID_jump_addr  : jump_addr_type;
    
    -- Control signals from control unit
    signal ID_RegDst, ID_Jump, ID_Branch, ID_MemtoReg : std_logic;
    signal ID_ALUOp : std_logic_vector(1 downto 0);
    signal ID_ALUSrc, ID_RegWrite, ID_BranchNotEq : std_logic;
    signal ID_MemRead, ID_MemWrite : std_logic;
    
    -- Register file
    signal ID_reg_read_data1, ID_reg_read_data2 : word;
    
    -- Sign extension
    signal ID_sign_extended, ID_zero_extended : word;
    signal ID_immediate_extended : word;

    -- Jump target (calculated in ID stage for 1-cycle delay)
    signal ID_jump_target : word;

    --------------------------------------------------------------------------------
    -- ID/EX Pipeline Register signals
    --------------------------------------------------------------------------------
    signal IDEX_RegDst, IDEX_ALUSrc, IDEX_MemRead, IDEX_MemWrite : std_logic;
    signal IDEX_MemtoReg, IDEX_RegWrite, IDEX_Branch, IDEX_Jump, IDEX_BranchNotEq : std_logic;
    signal IDEX_ALUOp : std_logic_vector(1 downto 0);
    signal IDEX_PC : word;
    signal IDEX_read_data1, IDEX_read_data2 : word;
    signal IDEX_imm_extended : word;
    signal IDEX_rs, IDEX_rt, IDEX_rd : reg_addr;
    signal IDEX_shamt : std_logic;
    signal IDEX_funct : funct_type;
    signal IDEX_opcode : opcode_type;
    signal IDEX_stall, IDEX_flush : std_logic;
    
    --------------------------------------------------------------------------------
    -- STAGE 3: EX (Execute) signals
    --------------------------------------------------------------------------------
    signal EX_alu_control_sig : alu_control_type;
    signal EX_alu_operand_b : word;
    signal EX_alu_result : word;
    signal EX_zero_flag : std_logic;
    signal EX_write_reg : reg_addr;
    signal EX_branch_target : word;

    -- Forwarding signals
    signal ForwardA : std_logic_vector(1 downto 0);
    signal ForwardB : std_logic_vector(1 downto 0);
    signal EX_alu_operand_a_forwarded : word;
    signal EX_alu_operand_b_forwarded : word;

    -- Hazard detection signals
    signal PC_Write_Enable : std_logic;
    signal IFID_Write_Enable : std_logic;
    signal Control_Flush_Signal : std_logic;

    --------------------------------------------------------------------------------
    -- EX/MEM Pipeline Register signals
    --------------------------------------------------------------------------------
    signal EXMEM_MemRead, EXMEM_MemWrite, EXMEM_MemtoReg, EXMEM_RegWrite : std_logic;
    signal EXMEM_Branch, EXMEM_Jump, EXMEM_BranchNotEq : std_logic;
    signal EXMEM_branch_target : word;
    signal EXMEM_zero_flag : std_logic;
    signal EXMEM_alu_result : word;
    signal EXMEM_read_data2 : word;
    signal EXMEM_write_reg : reg_addr;
    
    --------------------------------------------------------------------------------
    -- STAGE 4: MEM (Memory Access) signals
    --------------------------------------------------------------------------------
    signal MEM_branch_taken : std_logic;
    signal MEM_jump_target : word;
    
    --------------------------------------------------------------------------------
    -- MEM/WB Pipeline Register signals
    --------------------------------------------------------------------------------
    signal MEMWB_MemtoReg, MEMWB_RegWrite : std_logic;
    signal MEMWB_mem_data : word;
    signal MEMWB_alu_result : word;
    signal MEMWB_write_reg : reg_addr;
    
    --------------------------------------------------------------------------------
    -- STAGE 5: WB (Write Back) signals
    --------------------------------------------------------------------------------
    signal WB_write_data : word;
    
begin
    
    --------------------------------------------------------------------------------
    -- STAGE 1: IF (Instruction Fetch)
    --------------------------------------------------------------------------------
    
    -- PC register (with hazard detection stall support)
    process(clk, reset)
    begin
        if reset = '1' then
            IF_PC <= (others => '0');
        elsif rising_edge(clk) then
            if PC_Write_Enable = '1' then
                IF_PC <= IF_PC_next;
            end if;
        end if;
    end process;
    
    -- PC + 2 calculation
    IF_PC_plus_2 <= std_logic_vector(unsigned(IF_PC) + 2);

    -- PC source multiplexer (selects between PC+2, branch target, and jump target)
    -- MODIFIED: Jump now resolved in ID stage (1-cycle delay) instead of MEM stage (3-cycle delay)
    IF_PC_next <= ID_jump_target when ID_Jump = '1' else
                  EXMEM_branch_target when MEM_branch_taken = '1' else
                  IF_PC_plus_2;

    -- Stall/flush signals from hazard detection unit
    IFID_stall <= not IFID_Write_Enable;  -- Convert write enable to stall signal
    -- MODIFIED: Flush on ID-stage jump (immediate) or MEM-stage branch taken
    IFID_flush <= MEM_branch_taken or ID_Jump;
    
    -- IF/ID Pipeline Register
    IFID: IF_ID_reg
        port map (
            clk       => clk,
            reset     => reset,
            stall     => IFID_stall,
            flush     => IFID_flush,
            PC_in     => IF_PC_plus_2,
            instr_in  => instruction,
            PC_out    => IFID_PC,
            instr_out => IFID_instruction
        );
    
    --------------------------------------------------------------------------------
    -- STAGE 2: ID (Instruction Decode)
    --------------------------------------------------------------------------------
    
    -- Extract instruction fields
    ID_opcode    <= get_opcode(IFID_instruction);
    ID_rs        <= get_rs(IFID_instruction);
    ID_rt        <= get_rt(IFID_instruction);
    ID_rd        <= get_rd(IFID_instruction);
    ID_shamt     <= get_shamt(IFID_instruction);
    ID_funct     <= get_funct(IFID_instruction);
    ID_immediate <= get_immediate(IFID_instruction);
    ID_jump_addr <= get_jump_addr(IFID_instruction);
    
    -- Sign and zero extension
    ID_sign_extended <= sign_extend_6to16(ID_immediate);
    ID_zero_extended <= zero_extend_6to16(ID_immediate);

    -- Select appropriate extension
    -- For jumps, we need to pass the jump address (12 bits) through the immediate field
    -- ORI uses SIGN extension (not zero) to support negative immediates
    ID_immediate_extended <= std_logic_vector(resize(unsigned(ID_jump_addr), 16)) when ID_opcode = OP_JUMP else
                            ID_sign_extended;

    -- Jump target calculation (moved to ID stage for 1-cycle delay instead of 3-cycle)
    -- Jump uses absolute addressing: jump_addr << 1 (multiply by 2 for word addressing)
    ID_jump_target <= std_logic_vector(shift_left(unsigned(ID_immediate_extended), 1));

    -- Control Unit
    ctrl: control_unit
        port map (
            opcode      => ID_opcode,
            RegDst      => ID_RegDst,
            Jump        => ID_Jump,
            Branch      => ID_Branch,
            MemRead     => ID_MemRead,
            MemtoReg    => ID_MemtoReg,
            ALUOp       => ID_ALUOp,
            MemWrite    => ID_MemWrite,
            ALUSrc      => ID_ALUSrc,
            RegWrite    => ID_RegWrite,
            BranchNotEq => ID_BranchNotEq
        );
    
    -- Register File (reads in ID, writes in WB)
    reg_file: register_file
        port map (
            clk          => clk,
            reset        => reset,
            read_addr1   => ID_rs,
            read_addr2   => ID_rt,
            read_data1   => ID_reg_read_data1,
            read_data2   => ID_reg_read_data2,
            write_addr   => MEMWB_write_reg,
            write_data   => WB_write_data,
            write_enable => MEMWB_RegWrite
        );

    -- Hazard Detection Unit
    hazard_unit: hazard_detection_unit
        port map (
            IFID_rs        => ID_rs,
            IFID_rt        => ID_rt,
            IDEX_rt        => IDEX_rt,
            IDEX_MemRead   => IDEX_MemRead,
            PC_Write       => PC_Write_Enable,
            IFID_Write     => IFID_Write_Enable,
            Control_Flush  => Control_Flush_Signal
        );

    -- Stall/flush signals
    IDEX_stall <= '0';  -- No stall needed for ID/EX (hazard unit handles it via IF/ID stall)
    -- MODIFIED: Flush on load-use hazard, branch taken, or ID-stage jump
    IDEX_flush <= Control_Flush_Signal or MEM_branch_taken or ID_Jump;
    
    -- ID/EX Pipeline Register
    IDEX: ID_EX_reg
        port map (
            clk         => clk,
            reset       => reset,
            stall       => IDEX_stall,
            flush       => IDEX_flush,
            RegDst_in      => ID_RegDst,
            ALUSrc_in      => ID_ALUSrc,
            ALUOp_in       => ID_ALUOp,
            MemRead_in     => ID_MemRead,
            MemWrite_in    => ID_MemWrite,
            MemtoReg_in    => ID_MemtoReg,
            RegWrite_in    => ID_RegWrite,
            Branch_in      => ID_Branch,
            Jump_in        => ID_Jump,
            BranchNotEq_in => ID_BranchNotEq,
            PC_in          => IFID_PC,
            read_data1_in  => ID_reg_read_data1,
            read_data2_in  => ID_reg_read_data2,
            imm_extended_in=> ID_immediate_extended,
            rs_in          => ID_rs,
            rt_in          => ID_rt,
            rd_in          => ID_rd,
            shamt_in       => ID_shamt,
            funct_in       => ID_funct,
            opcode_in      => ID_opcode,
            RegDst_out      => IDEX_RegDst,
            ALUSrc_out      => IDEX_ALUSrc,
            ALUOp_out       => IDEX_ALUOp,
            MemRead_out     => IDEX_MemRead,
            MemWrite_out    => IDEX_MemWrite,
            MemtoReg_out    => IDEX_MemtoReg,
            RegWrite_out    => IDEX_RegWrite,
            Branch_out      => IDEX_Branch,
            Jump_out        => IDEX_Jump,
            BranchNotEq_out => IDEX_BranchNotEq,
            PC_out          => IDEX_PC,
            read_data1_out  => IDEX_read_data1,
            read_data2_out  => IDEX_read_data2,
            imm_extended_out=> IDEX_imm_extended,
            rs_out          => IDEX_rs,
            rt_out          => IDEX_rt,
            rd_out          => IDEX_rd,
            shamt_out       => IDEX_shamt,
            funct_out       => IDEX_funct,
            opcode_out      => IDEX_opcode
        );
    
    --------------------------------------------------------------------------------
    -- STAGE 3: EX (Execute)
    --------------------------------------------------------------------------------

    -- Forwarding Unit
    fwd_unit: forwarding_unit
        port map (
            IDEX_rs        => IDEX_rs,
            IDEX_rt        => IDEX_rt,
            EXMEM_RegWrite => EXMEM_RegWrite,
            EXMEM_rd       => EXMEM_write_reg,
            MEMWB_RegWrite => MEMWB_RegWrite,
            MEMWB_rd       => MEMWB_write_reg,
            ForwardA       => ForwardA,
            ForwardB       => ForwardB
        );

    -- Forwarding mux for ALU operand A
    forward_a_mux: process(ForwardA, IDEX_read_data1, EXMEM_alu_result, WB_write_data)
    begin
        case ForwardA is
            when "10" =>  -- Forward from EX/MEM (MEM stage)
                EX_alu_operand_a_forwarded <= EXMEM_alu_result;
            when "01" =>  -- Forward from MEM/WB (WB stage)
                EX_alu_operand_a_forwarded <= WB_write_data;
            when others => -- No forwarding
                EX_alu_operand_a_forwarded <= IDEX_read_data1;
        end case;
    end process;

    -- Forwarding mux for ALU operand B (before ALUSrc mux)
    forward_b_mux: process(ForwardB, IDEX_read_data2, EXMEM_alu_result, WB_write_data)
    begin
        case ForwardB is
            when "10" =>  -- Forward from EX/MEM (MEM stage)
                EX_alu_operand_b_forwarded <= EXMEM_alu_result;
            when "01" =>  -- Forward from MEM/WB (WB stage)
                EX_alu_operand_b_forwarded <= WB_write_data;
            when others => -- No forwarding
                EX_alu_operand_b_forwarded <= IDEX_read_data2;
        end case;
    end process;

    -- ALU Control
    alu_ctrl: alu_control
        port map (
            ALUOp       => IDEX_ALUOp,
            funct       => IDEX_funct,
            opcode      => IDEX_opcode,
            alu_control => EX_alu_control_sig
        );

    -- ALU source B multiplexer (uses forwarded operand B)
    EX_alu_operand_b <= IDEX_imm_extended when IDEX_ALUSrc = '1' else EX_alu_operand_b_forwarded;

    -- ALU (uses forwarded operand A)
    alu_unit: alu
        port map (
            alu_control => EX_alu_control_sig,
            operand_a   => EX_alu_operand_a_forwarded,
            operand_b   => EX_alu_operand_b,
            shamt       => IDEX_shamt,
            result      => EX_alu_result,
            zero_flag   => EX_zero_flag
        );
    
    -- Write register multiplexer
    EX_write_reg <= IDEX_rd when IDEX_RegDst = '1' else IDEX_rt;

    -- Branch/Jump target calculation
    -- For branches: PC + (sign_extended_offset << 1)
    -- For jumps: jump_addr << 1 (absolute address)
    EX_branch_target <= std_logic_vector(shift_left(unsigned(IDEX_imm_extended), 1)) when IDEX_Jump = '1' else
                        std_logic_vector(unsigned(IDEX_PC) + shift_left(unsigned(IDEX_imm_extended), 1));
    
    -- EX/MEM Pipeline Register
    EXMEM: EX_MEM_reg
        port map (
            clk         => clk,
            reset       => reset,
            MemRead_in     => IDEX_MemRead,
            MemWrite_in    => IDEX_MemWrite,
            MemtoReg_in    => IDEX_MemtoReg,
            RegWrite_in    => IDEX_RegWrite,
            Branch_in      => IDEX_Branch,
            Jump_in        => IDEX_Jump,
            BranchNotEq_in => IDEX_BranchNotEq,
            branch_target_in => EX_branch_target,
            zero_flag_in     => EX_zero_flag,
            alu_result_in    => EX_alu_result,
            read_data2_in    => IDEX_read_data2,
            write_reg_in     => EX_write_reg,
            MemRead_out     => EXMEM_MemRead,
            MemWrite_out    => EXMEM_MemWrite,
            MemtoReg_out    => EXMEM_MemtoReg,
            RegWrite_out    => EXMEM_RegWrite,
            Branch_out      => EXMEM_Branch,
            Jump_out        => EXMEM_Jump,
            BranchNotEq_out => EXMEM_BranchNotEq,
            branch_target_out => EXMEM_branch_target,
            zero_flag_out     => EXMEM_zero_flag,
            alu_result_out    => EXMEM_alu_result,
            read_data2_out    => EXMEM_read_data2,
            write_reg_out     => EXMEM_write_reg
        );
    
    --------------------------------------------------------------------------------
    -- STAGE 4: MEM (Memory Access)
    --------------------------------------------------------------------------------

    -- Branch decision logic
    -- BEQ: Branch if zero_flag = '1' (operands are equal)
    -- BNE: Branch if zero_flag = '0' (operands are not equal)
    MEM_branch_taken <= '1' when (EXMEM_Branch = '1' and EXMEM_BranchNotEq = '0' and EXMEM_zero_flag = '1') or
                                 (EXMEM_Branch = '1' and EXMEM_BranchNotEq = '1' and EXMEM_zero_flag = '0') else
                        '0';

    -- Jump target is calculated in EX stage and passed through EXMEM_branch_target
    -- (branch_target serves dual purpose: branch offset for branches, absolute address for jumps)
    MEM_jump_target <= EXMEM_branch_target;

    -- Memory outputs (directly connect to external memory)
    mem_address    <= EXMEM_alu_result;
    mem_write_data <= EXMEM_read_data2;
    MemRead        <= EXMEM_MemRead;
    MemWrite       <= EXMEM_MemWrite;
    
    -- MEM/WB Pipeline Register
    MEMWB: MEM_WB_reg
        port map (
            clk         => clk,
            reset       => reset,
            MemtoReg_in    => EXMEM_MemtoReg,
            RegWrite_in    => EXMEM_RegWrite,
            mem_data_in    => mem_read_data,
            alu_result_in  => EXMEM_alu_result,
            write_reg_in   => EXMEM_write_reg,
            MemtoReg_out   => MEMWB_MemtoReg,
            RegWrite_out   => MEMWB_RegWrite,
            mem_data_out   => MEMWB_mem_data,
            alu_result_out => MEMWB_alu_result,
            write_reg_out  => MEMWB_write_reg
        );
    
    --------------------------------------------------------------------------------
    -- STAGE 5: WB (Write Back)
    --------------------------------------------------------------------------------
    
    -- Write data multiplexer
    WB_write_data <= MEMWB_mem_data when MEMWB_MemtoReg = '1' else MEMWB_alu_result;

    -- PC output (for monitoring)
    PC_out <= IF_PC;

    --------------------------------------------------------------------------------
    -- DEBUG MONITORING PROCESS (DISABLED TO REDUCE OUTPUT)
    -- Tracks critical signals for SUBI and BEQ instructions
    --------------------------------------------------------------------------------
    -- debug_monitor: process(clk)
    --     variable line_buf : line;
    --     variable cycle_count : integer := 0;
    -- begin
    --     if rising_edge(clk) and reset = '0' then
    --         cycle_count := cycle_count + 1;
    --
    --         -- Monitor SUBI instruction in EX stage (opcode = 0011, writes to R7=$a1)
    --             if IDEX_opcode = OP_SUBI and IDEX_rt = "111" then
    --                 report "================================================================================";
    --                 write(line_buf, string'("CYCLE "));
    --                 write(line_buf, cycle_count);
    --                 write(line_buf, string'(": SUBI $a1, $a1, 1 in EX stage"));
    --                 report line_buf.all;
    --                 report "================================================================================";
    --                 write(line_buf, string'("  ID stage (IDEX registers):"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    RegDst     = "));
    --                 write(line_buf, IDEX_RegDst);
    --                 write(line_buf, string'(" (0=write to rt)"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    RegWrite   = "));
    --                 write(line_buf, IDEX_RegWrite);
    --                 report line_buf.all;
    --                 write(line_buf, string'("    rs         = R"));
    --                 write(line_buf, to_integer(unsigned(IDEX_rs)));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    rt         = R"));
    --                 write(line_buf, to_integer(unsigned(IDEX_rt)));
    --                 write(line_buf, string'(" ($a1)"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    read_data1 = "));
    --                 write(line_buf, to_integer(signed(IDEX_read_data1)));
    --                 write(line_buf, string'(" (current $a1 value)"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    immediate  = "));
    --                 write(line_buf, to_integer(signed(IDEX_imm_extended)));
    --                 report line_buf.all;
    --                 write(line_buf, string'("  EX stage:"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    write_reg  = R"));
    --                 write(line_buf, to_integer(unsigned(EX_write_reg)));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    alu_result = "));
    --                 write(line_buf, to_integer(signed(EX_alu_result)));
    --                 write(line_buf, string'(" (new $a1 value) [0x"));
    --                 hwrite(line_buf, EX_alu_result);
    --                 write(line_buf, string'("]"));
    --                 report line_buf.all;
    --                 report "";
    --             end if;
    -- 
    --             -- Monitor when SUBI reaches MEM stage (RegWrite=1, writing to R7)
    --             if EXMEM_RegWrite = '1' and EXMEM_write_reg = "111" and EXMEM_MemtoReg = '0' and EXMEM_MemWrite = '0' then
    --                 write(line_buf, string'("CYCLE "));
    --                 write(line_buf, cycle_count);
    --                 write(line_buf, string'(": SUBI $a1 in MEM stage"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("  RegWrite   = "));
    --                 write(line_buf, EXMEM_RegWrite);
    --                 report line_buf.all;
    --                 write(line_buf, string'("  write_reg  = R"));
    --                 write(line_buf, to_integer(unsigned(EXMEM_write_reg)));
    --                 write(line_buf, string'(" ($a1)"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("  alu_result = "));
    --                 write(line_buf, to_integer(signed(EXMEM_alu_result)));
    --                 write(line_buf, string'(" [0x"));
    --                 hwrite(line_buf, EXMEM_alu_result);
    --                 write(line_buf, string'("]"));
    --                 report line_buf.all;
    --                 report "";
    --             end if;
    -- 
    --             -- Monitor when SUBI reaches WB stage (RegWrite=1, writing to R7)
    --             if MEMWB_RegWrite = '1' and MEMWB_write_reg = "111" and MEMWB_MemtoReg = '0' then
    --                 report "********************************************************************************";
    --                 write(line_buf, string'("CYCLE "));
    --                 write(line_buf, cycle_count);
    --                 write(line_buf, string'(": SUBI $a1 in WB stage - WRITING TO REGISTER FILE NOW!"));
    --                 report line_buf.all;
    --                 report "********************************************************************************";
    --                 write(line_buf, string'("  RegWrite    = "));
    --                 write(line_buf, MEMWB_RegWrite);
    --                 report line_buf.all;
    --                 write(line_buf, string'("  write_reg   = R"));
    --                 write(line_buf, to_integer(unsigned(MEMWB_write_reg)));
    --                 write(line_buf, string'(" ($a1)"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("  write_data  = "));
    --                 write(line_buf, to_integer(signed(WB_write_data)));
    --                 write(line_buf, string'(" <-- NEW $a1 VALUE [0x"));
    --                 hwrite(line_buf, WB_write_data);
    --                 write(line_buf, string'("]"));
    --                 report line_buf.all;
    --                 report "  NOTE: Register file will be updated on NEXT rising edge";
    --                 report "";
    --             end if;
    -- 
    --             -- Monitor BEQ instruction in EX stage (Branch=1, rs=R7, rt=R0)
    --             if IDEX_opcode = OP_BEQ and IDEX_rs = "111" and IDEX_rt = "000" then
    --                 report "================================================================================";
    --                 write(line_buf, string'("CYCLE "));
    --                 write(line_buf, cycle_count);
    --                 write(line_buf, string'(": BEQ $a1, $zero, offset in EX stage"));
    --                 report line_buf.all;
    --                 report "================================================================================";
    --                 write(line_buf, string'("  ID stage (IDEX registers):"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    rs            = R"));
    --                 write(line_buf, to_integer(unsigned(IDEX_rs)));
    --                 write(line_buf, string'(" ($a1)"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    rt            = R"));
    --                 write(line_buf, to_integer(unsigned(IDEX_rt)));
    --                 write(line_buf, string'(" ($zero)"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    read_data1    = "));
    --                 write(line_buf, to_integer(signed(IDEX_read_data1)));
    --                 write(line_buf, string'(" <-- CURRENT $a1 VALUE READ FROM REGISTER FILE"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    read_data2    = "));
    --                 write(line_buf, to_integer(signed(IDEX_read_data2)));
    --                 write(line_buf, string'(" (from $zero)"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("  EX stage:"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    alu_result    = "));
    --                 write(line_buf, to_integer(signed(EX_alu_result)));
    --                 write(line_buf, string'(" (read_data1 - read_data2)"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("    zero_flag     = "));
    --                 write(line_buf, EX_zero_flag);
    --                 if EX_zero_flag = '1' then
    --                     write(line_buf, string'(" <-- EQUAL! Should branch"));
    --                 else
    --                     write(line_buf, string'(" <-- NOT EQUAL! Should NOT branch"));
    --                 end if;
    --                 report line_buf.all;
    --                 report "";
    --             end if;
    -- 
    --             -- Monitor when BEQ reaches MEM stage (Branch decision)
    --             if EXMEM_Branch = '1' and EXMEM_BranchNotEq = '0' then
    --                 report "********************************************************************************";
    --                 write(line_buf, string'("CYCLE "));
    --                 write(line_buf, cycle_count);
    --                 write(line_buf, string'(": BEQ in MEM stage - BRANCH DECISION MADE NOW!"));
    --                 report line_buf.all;
    --                 report "********************************************************************************";
    --                 write(line_buf, string'("  Branch         = "));
    --                 write(line_buf, EXMEM_Branch);
    --                 report line_buf.all;
    --                 write(line_buf, string'("  BranchNotEq    = "));
    --                 write(line_buf, EXMEM_BranchNotEq);
    --                 report line_buf.all;
    --                 write(line_buf, string'("  zero_flag      = "));
    --                 write(line_buf, EXMEM_zero_flag);
    --                 report line_buf.all;
    --                 write(line_buf, string'("  branch_taken   = "));
    --                 write(line_buf, MEM_branch_taken);
    --                 write(line_buf, string'(" <-- FINAL DECISION"));
    --                 report line_buf.all;
    --                 write(line_buf, string'("  branch_target  = 0x"));
    --                 hwrite(line_buf, EXMEM_branch_target);
    --                 write(line_buf, string'(" ("));
    --                 write(line_buf, to_integer(unsigned(EXMEM_branch_target)));
    --                 write(line_buf, string'(")"));
    --                 report line_buf.all;
    --                 if MEM_branch_taken = '1' then
    --                     report "  >>> BRANCH WILL BE TAKEN - PC will jump to target <<<";
    --                 else
    --                     report "  >>> BRANCH NOT TAKEN - PC will increment normally <<<";
    --                 end if;
    --                 report "";
    --             end if;
    -- 
    --         end if;
    -- end process;

end behavioral;