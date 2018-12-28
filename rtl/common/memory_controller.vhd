-- Copyright (c) 2015-2018 in2H2 inc.
-- System developed for in2H2 inc. by Intermotion Technology, Inc.
--
-- Full system RTL, C sources and board design files available at https://github.com/nearist
--
-- in2H2 inc. Team Members:
-- - Chris McCormick - Algorithm Research and Design
-- - Matt McCormick - Board Production, System Q/A
--
-- Intermotion Technology Inc. Team Members:
-- - Mick Fandrich - Project Lead
-- - Dr. Ludovico Minati - Board Architecture and Design, FPGA Technology Advisor
-- - Vardan Movsisyan - RTL Team Lead
-- - Khachatur Gyozalyan - RTL Design
-- - Tigran Papazyan - RTL Design
-- - Taron Harutyunyan - RTL Design
-- - Hayk Ghaltaghchyan - System Software
--
-- Tecno77 S.r.l. Team Members:
-- - Stefano Aldrigo, Board Layout Design
--
-- We dedicate this project to the memory of Bruce McCormick, an AI pioneer
-- and advocate, a good friend and father.
--
-- These materials are provided free of charge: you can redistribute them and/or modify
-- them under the terms of the GNU General Public License as published by
-- the Free Software Foundation, version 3.
--
-- These materials are distributed in the hope that they will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.

--------------------------------------------------------------------------------------------
-- 1) Writes dataset vectors to DDR3 Memory (with the use of ddr_sdram_controller IP),    --
-- 2) Reading dataset vectors from DDR3 Memory (with the use of ddr_sdram_controller IP), --
--    and sending to DC Slots (for distance calculation).
--------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.mem_ctrl_def.all;
use work.cfg_registers_def.all;

entity memory_controller is
port(
    -- Common signals
  reset_n               : in  std_logic;
  main_pll_lock_i       : in  std_logic;
  mem_pll_lock_o        : out std_logic;
  clk                   : in  std_logic;
  clk_out               : out std_logic;
  calc_reset_i          : in  std_logic;

    --DDR3 Memory Write address user interface
  mem_wr_addr_i         : in  std_logic_vector((MEM_ADDRESS_SIZE - 1) downto 0);
  mem_wr_addr_wr_en_i   : in  std_logic;

    -- DDR3 Memory Write data user interface
  mem_wr_data_i         : in  std_logic_vector(31 downto 0);
  mem_wr_en_i           : in  std_logic;
  mem_wr_full_o         : out std_logic;
  mem_wr_fifo_empty_o   : out std_logic;

    -- DDR3 Memory Read Data Set interface
  ds_out_dc_00_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_01_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_02_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_03_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_04_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_05_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_06_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_07_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_08_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_09_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_10_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_11_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_12_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_13_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_14_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
  ds_out_dc_15_o        : out std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);

  ds_data_valid_o       : out std_logic;
  ds_rd_en_i            : in  std_logic;
  ds_vec_counter_o      : out std_logic_vector(27 downto 0);
  ds_data_valid_vec_o   : out std_logic_vector(15 downto 0);
  ds_first_comp_o       : out std_logic;
  ds_last_comp_o        : out std_logic;
  ds_reset_vec_cntr_o   : out std_logic;

    -- Configuration signals
  ds_vec_length_i       : in  std_logic_vector((DSV_LENGTH_SIZE - 1) downto 0);
  ds_vec_count_i        : in  std_logic_vector(31 downto 0);
  run_i                 : in  std_logic;

    -- DDR3 Memory side signals
  cm_clk_p              : in    std_logic;
  em_ddr_data           : inout std_logic_vector(31 downto 0);
  em_ddr_reset_n        : out   std_logic;
  em_ddr_dqs            : inout std_logic_vector( 3 downto 0);
  em_ddr_clk            : out   std_logic_vector( 1 downto 0);
  em_ddr_cke            : out   std_logic_vector( 0 downto 0);
  em_ddr_ras_n          : out   std_logic;
  em_ddr_cas_n          : out   std_logic;
  em_ddr_we_n           : out   std_logic;
  em_ddr_cs_n           : out   std_logic_vector( 0 downto 0);
  em_ddr_odt            : out   std_logic_vector( 0 downto 0);
  em_ddr_dm             : out   std_logic_vector( 3 downto 0);
  em_ddr_ba             : out   std_logic_vector( 2 downto 0);
  em_ddr_addr           : out   std_logic_vector(15 downto 0);

    -- Statuses
  init_done_o           : out   std_logic;
  wl_err_o              : out   std_logic;
  rt_err_o              : out   std_logic;
  cmd_valid_o           : out   std_logic;
  rd_fifo_empty_o       : out   std_logic;
  rd_fifo_almost_full_o : out   std_logic
);
end memory_controller;

architecture rtl of memory_controller is

  signal logic_reset               : std_logic;
  signal main_pll_lock_n           : std_logic;

  signal mem_rst_n_reg             : std_logic;
  signal init_start_reg            : std_logic;
  signal cmd                       : std_logic_vector(3 downto 0);
  signal addr                      : std_logic_vector((MEM_ADDRESS_SIZE - 1) downto 0);
  signal cmd_burst_cnt             : std_logic_vector(4 downto 0);
  signal cmd_burst_cnt_rd          : std_logic_vector(4 downto 0);
  signal cmd_burst_cnt_wr          : std_logic_vector(4 downto 0);
  signal cmd_burst_cnt_wr_rem_reg  : std_logic_vector(5 downto 0);
  signal cmd_burst_cnt_rd_rem_reg  : std_logic_vector(4 downto 0);
  signal cmd_valid                 : std_logic;
  signal ofly_burst_len            : std_logic;
  signal write_data                : std_logic_vector(127 downto 0);
  signal datain_rdy                : std_logic;
  signal data_mask                 : std_logic_vector(15 downto 0);
  signal clk_u                     : std_logic;

     -- Output signals to the User I/F
  signal cmd_rdy                   : std_logic;
  signal init_done                 : std_logic;
  signal init_done_reg             : std_logic;
  signal init_counter              : std_logic_vector(15 downto 0);
  signal rt_err                    : std_logic;
  signal rt_err_reg                : std_logic;
  signal wl_err                    : std_logic;
  signal wl_err_reg                : std_logic;
  signal read_data                 : std_logic_vector(127 downto 0);
  signal read_data_valid           : std_logic;

     -- Output for test logic
  signal clocking_good             : std_logic;

  signal cmd_wr_signals_ext_clk    : std_logic_vector(0 downto 0);
  signal clk_ext_to_int_signals    : std_logic_vector(0 downto 0);
  signal clk_ext_to_int_empty      : std_logic;
  signal clk_ext_to_int_full       : std_logic;
  signal clk_ext_to_int_rd_en      : std_logic;
  signal clk_ext_to_int_wr_en      : std_logic;

  signal cmd_wr_signals_int_clk    : std_logic_vector(5 downto 0);
  signal clk_int_to_ext_signals    : std_logic_vector(5 downto 0);
  signal clk_int_to_ext_empty      : std_logic;
  signal clk_int_to_ext_full       : std_logic;
  signal clk_int_to_ext_rd_en      : std_logic;
  signal clk_int_to_ext_wr_en      : std_logic;

  signal wr_data_fifo_read_cnt     : std_logic_vector(6 downto 0);
  signal wr_data_fifo_read_cnt_reg : std_logic_vector(6 downto 0);
  signal wr_data_fifo_read_cnt_not_zero_reg : std_logic;
  signal wr_data_fifo_empty        : std_logic;

  signal ds_vec_counter_reg        : std_logic_vector(27 downto 0);
  signal ds_addr_cnt_reg           : std_logic_vector((DSV_LENGTH_SIZE  - 1) downto 0);
  signal ds_rd_addr_reg            : std_logic_vector((MEM_ADDRESS_SIZE - 2) downto 0);
  signal ds_data_valid             : std_logic;

  signal rd_fifo_wr_en             : std_logic;
  signal rd_fifo_rd_en             : std_logic;
  signal rd_fifo_almost_full       : std_logic;
  signal rd_fifo_full              : std_logic;
  signal rd_fifo_empty             : std_logic;

  signal rd_fifo_valid_reg         : std_logic;
  signal rd_fifo_first_rd_en_reg   : std_logic;

  signal run_reg                   : std_logic;

  signal last_ds_valid_vec_reg     : std_logic_vector(15 downto 0);
  signal last_ds_valid_vec         : std_logic_vector(15 downto 0);

  signal mem_wr_addr_reg           : std_logic_vector((MEM_ADDRESS_SIZE - 1) downto 0);
  signal mem_wr_addr               : std_logic_vector((MEM_ADDRESS_SIZE - 1) downto 0);
  signal mem_max_addr_reg          : std_logic_vector((MEM_ADDRESS_SIZE - 1) downto 0);
  signal mem_max_diff_addr         : std_logic_vector((MEM_ADDRESS_SIZE - 2) downto 0);
  signal mem_wr_cnt_reg            : std_logic_vector(6 downto 0);
  signal mem_wr_in_prog_0_reg      : std_logic;
  signal mem_wr_in_prog_1_reg      : std_logic;
  signal mem_wr_in_prog_2_reg      : std_logic;
  signal wr_addr_empty             : std_logic;
  signal wr_addr_rd_en             : std_logic;
  signal wr_addr_rd_en_reg_1       : std_logic;
  signal wr_addr_rd_en_reg_2       : std_logic;

  signal mem_rd_addr               : std_logic_vector((MEM_ADDRESS_SIZE - 1) downto 0);
  signal rd_fifo_data_out          : std_logic_vector(127 downto 0);

  component fifo_dc_wr_data
  port (
    Data    : in  std_logic_vector(31 downto 0);
    WrClock : in  std_logic;
    RdClock : in  std_logic;
    WrEn    : in  std_logic;
    RdEn    : in  std_logic;
    Reset   : in  std_logic;
    RPReset : in  std_logic;
    Q       : out std_logic_vector(127 downto 0);
    RCNT    : out std_logic_vector(  6 downto 0);
    Empty   : out std_logic;
    Full    : out std_logic
  );
  end component;

  component fifo_dc_wr_addr
  port (
    Data    : in  std_logic_vector(28 downto 0);
    WrClock : in  std_logic;
    RdClock : in  std_logic;
    WrEn    : in  std_logic;
    RdEn    : in  std_logic;
    Reset   : in  std_logic;
    RPReset : in  std_logic;
    Q       : out std_logic_vector(28 downto 0);
    Empty   : out std_logic;
    Full    : out std_logic
  );
  end component;


  component fifo_dc_clk_ext_to_int
  port (
    Data    : in   std_logic_vector(0 downto 0);
    WrClock : in   std_logic;
    RdClock : in   std_logic;
    WrEn    : in   std_logic;
    RdEn    : in   std_logic;
    Reset   : in   std_logic;
    RPReset : in   std_logic;
    Q       : out  std_logic_vector(0 downto 0);
    Empty   : out  std_logic;
    Full    : out  std_logic
  );
  end component;

  component fifo_dc_clk_int_to_ext
  port (
    Data    : in   std_logic_vector(5 downto 0);
    WrClock : in   std_logic;
    RdClock : in   std_logic;
    WrEn    : in   std_logic;
    RdEn    : in   std_logic;
    Reset   : in   std_logic;
    RPReset : in   std_logic;
    Q       : out  std_logic_vector(5 downto 0);
    Empty   : out  std_logic;
    Full    : out  std_logic
  );
  end component;


  component fifo_dc_rd_data
  port (
    Data       : in  std_logic_vector(127 downto 0);
    WrClock    : in  std_logic;
    RdClock    : in  std_logic;
    WrEn       : in  std_logic;
    RdEn       : in  std_logic;
    Reset      : in  std_logic;
    RPReset    : in  std_logic;
    Q          : out std_logic_vector(127 downto 0);
    Empty      : out std_logic;
    Full       : out std_logic;
    AlmostFull : out std_logic
  );
  end component;

  component ddr3_sdram_mem_top_ddr3_ip_core
  port(
    clk_in               : in    std_logic;
    rst_n                : in    std_logic;
    mem_rst_n            : in    std_logic;
    init_start           : in    std_logic;
    cmd                  : in    std_logic_vector(3 downto  0);
    addr                 : in    std_logic_vector(28 downto 0);
    cmd_burst_cnt        : in    std_logic_vector(4 downto  0);
    cmd_valid            : in    std_logic;
    ofly_burst_len       : in    std_logic;
    write_data           : in    std_logic_vector(127 downto 0);
    data_mask            : in    std_logic_vector(15 downto 0);

    -- Output signals to the User I/F
    cmd_rdy              : out   std_logic;
    init_done            : out   std_logic;
    rt_err               : out   std_logic;
    wl_err               : out   std_logic;
    datain_rdy           : out   std_logic;
    read_data            : out   std_logic_vector(127 downto 0);
    read_data_valid      : out   std_logic;

    -- Output for test logic
    sclk_out             : out   std_logic;
    clocking_good        : out   std_logic;

    -- Memory side signals
    em_ddr_data          : inout std_logic_vector(31 downto 0);
    em_ddr_reset_n       : out   std_logic;
    em_ddr_dqs           : inout std_logic_vector(3  downto 0);
    em_ddr_clk           : out   std_logic_vector(1  downto 0);
    em_ddr_cke           : out   std_logic_vector(0  downto 0);
    em_ddr_ras_n         : out   std_logic;
    em_ddr_cas_n         : out   std_logic;
    em_ddr_we_n          : out   std_logic;
    em_ddr_cs_n          : out   std_logic_vector(0  downto 0);
    em_ddr_odt           : out   std_logic_vector(0  downto 0);
    em_ddr_dm            : out   std_logic_vector(3  downto 0);
    em_ddr_ba            : out   std_logic_vector(2  downto 0);
    em_ddr_addr          : out   std_logic_vector(15 downto 0)
  );
  end component;

begin

  clk_out                   <= clk_u;

  main_pll_lock_n           <= not main_pll_lock_i;
  logic_reset               <= calc_reset_i or main_pll_lock_n;

  cmd_wr_signals_ext_clk(0) <= run_i;

  mem_pll_lock_o            <= clocking_good;

  cmd_valid                 <= '1' when ((cmd_rdy = '1') and
                                         (((wr_data_fifo_read_cnt_not_zero_reg = '1') and
                                           (wr_data_fifo_empty = '0')                 and
                                           (mem_wr_in_prog_0_reg = '0') and (mem_wr_in_prog_2_reg = '0')) or
                                           ((rd_fifo_almost_full = '0') and
                                            (run_reg = '1')))) else '0';

  cmd                       <= MEM_CMD_WRITE when ((wr_data_fifo_read_cnt_not_zero_reg = '1') and (wr_data_fifo_empty = '0') and (mem_wr_in_prog_0_reg = '0') and (mem_wr_in_prog_2_reg = '0')) else
                               MEM_CMD_READ;

  cmd_burst_cnt_wr          <= cmd_burst_cnt_wr_rem_reg(4 downto 0) when (wr_data_fifo_read_cnt_reg(6 downto 1) >= (cmd_burst_cnt_wr_rem_reg)) else
                               wr_data_fifo_read_cnt_reg(5 downto 1);

  cmd_burst_cnt_rd          <= cmd_burst_cnt_rd_rem_reg;

  cmd_burst_cnt             <= cmd_burst_cnt_wr when (cmd = MEM_CMD_WRITE) else
                               cmd_burst_cnt_rd;

  addr                      <= mem_wr_addr_reg(MEM_ADDRESS_SIZE-3 downto 0) & "00" when (cmd = MEM_CMD_WRITE) else
                               mem_rd_addr(MEM_ADDRESS_SIZE-3 downto 0) & "00"     when (cmd = MEM_CMD_READ)  else
                               (others => '0');

  data_mask                 <= X"0000";
  ofly_burst_len            <= '0';

  rd_fifo_wr_en             <= '1' when (read_data_valid = '1') and (rt_err = '0') and (init_done_reg = '1') else '0';
  rd_fifo_rd_en             <= '1' when ((rd_fifo_empty = '0') and ((rd_fifo_valid_reg = '0') or
                                         (rd_fifo_first_rd_en_reg = '0') or
                                         (((run_i = '1') and (ds_rd_en_i  = '1'))))) else '0';

  mem_rd_addr               <= (ds_rd_addr_reg & '0');
  rd_fifo_empty_o           <= rd_fifo_empty;
  rd_fifo_almost_full_o     <= clk_int_to_ext_signals(5);
  cmd_valid_o               <= clk_int_to_ext_signals(4);
  wl_err_o                  <= clk_int_to_ext_signals(3);
  rt_err_o                  <= clk_int_to_ext_signals(2);
  mem_wr_fifo_empty_o       <= clk_int_to_ext_signals(1);
  init_done_o               <= clk_int_to_ext_signals(0);

  cmd_wr_signals_int_clk    <= rd_fifo_almost_full & cmd_valid & wl_err_reg & rt_err_reg & wr_data_fifo_empty & init_done_reg;

  ds_out_dc_00_o            <= rd_fifo_data_out(  7 downto   0);
  ds_out_dc_01_o            <= rd_fifo_data_out( 15 downto   8);
  ds_out_dc_02_o            <= rd_fifo_data_out( 23 downto  16);
  ds_out_dc_03_o            <= rd_fifo_data_out( 31 downto  24);
  ds_out_dc_04_o            <= rd_fifo_data_out( 39 downto  32);
  ds_out_dc_05_o            <= rd_fifo_data_out( 47 downto  40);
  ds_out_dc_06_o            <= rd_fifo_data_out( 55 downto  48);
  ds_out_dc_07_o            <= rd_fifo_data_out( 63 downto  56);
  ds_out_dc_08_o            <= rd_fifo_data_out( 71 downto  64);
  ds_out_dc_09_o            <= rd_fifo_data_out( 79 downto  72);
  ds_out_dc_10_o            <= rd_fifo_data_out( 87 downto  80);
  ds_out_dc_11_o            <= rd_fifo_data_out( 95 downto  88);
  ds_out_dc_12_o            <= rd_fifo_data_out(103 downto  96);
  ds_out_dc_13_o            <= rd_fifo_data_out(111 downto 104);
  ds_out_dc_14_o            <= rd_fifo_data_out(119 downto 112);
  ds_out_dc_15_o            <= rd_fifo_data_out(127 downto 120);

  ds_data_valid             <= '1' when ((rd_fifo_valid_reg = '1') and (run_i = '1') and (ds_rd_en_i = '1')) else '0';
  ds_data_valid_o           <= ds_data_valid;
  ds_vec_counter_o          <= ds_vec_counter_reg;
  ds_first_comp_o           <= '1' when ((ds_data_valid = '1') and (ds_addr_cnt_reg = "000000000000")) else '0';
  ds_last_comp_o            <= '1' when ((ds_data_valid = '1') and (ds_addr_cnt_reg = ds_vec_length_i)) else '0';
  ds_reset_vec_cntr_o       <= mem_wr_addr_wr_en_i;

  last_ds_valid_vec         <= "0000000000000001" when (ds_vec_count_i(3 downto 0) = X"0") else
                               "0000000000000011" when (ds_vec_count_i(3 downto 0) = X"1") else
                               "0000000000000111" when (ds_vec_count_i(3 downto 0) = X"2") else
                               "0000000000001111" when (ds_vec_count_i(3 downto 0) = X"3") else
                               "0000000000011111" when (ds_vec_count_i(3 downto 0) = X"4") else
                               "0000000000111111" when (ds_vec_count_i(3 downto 0) = X"5") else
                               "0000000001111111" when (ds_vec_count_i(3 downto 0) = X"6") else
                               "0000000011111111" when (ds_vec_count_i(3 downto 0) = X"7") else
                               "0000000111111111" when (ds_vec_count_i(3 downto 0) = X"8") else
                               "0000001111111111" when (ds_vec_count_i(3 downto 0) = X"9") else
                               "0000011111111111" when (ds_vec_count_i(3 downto 0) = X"A") else
                               "0000111111111111" when (ds_vec_count_i(3 downto 0) = X"B") else
                               "0001111111111111" when (ds_vec_count_i(3 downto 0) = X"C") else
                               "0011111111111111" when (ds_vec_count_i(3 downto 0) = X"D") else
                               "0111111111111111" when (ds_vec_count_i(3 downto 0) = X"E") else
                               "1111111111111111" ;

  ds_data_valid_vec_o <= last_ds_valid_vec_reg when (ds_vec_counter_reg = ds_vec_count_i(31 downto 4)) else X"FFFF";

  wr_addr_rd_en       <= '1' when ((wr_addr_empty = '0') and (mem_wr_in_prog_0_reg = '0')) else '0';

  clk_ext_to_int_rd_en <= not clk_ext_to_int_empty;
  clk_ext_to_int_wr_en <= not clk_ext_to_int_full;

  clk_int_to_ext_rd_en <= not clk_int_to_ext_empty;
  clk_int_to_ext_wr_en <= not clk_int_to_ext_full;

  fifo_dc_wr_data_0 : fifo_dc_wr_data
  port map(
    Data     => mem_wr_data_i,
    WrClock  => clk,
    RdClock  => clk_u,
    WrEn     => mem_wr_en_i,
    RdEn     => datain_rdy,
    Reset    => main_pll_lock_n,
    RPReset  => '0',
    Q        => write_data,
    RCNT     => wr_data_fifo_read_cnt,
    Empty    => wr_data_fifo_empty,
    Full     => mem_wr_full_o
  );

  fifo_dc_wr_addr_0 : fifo_dc_wr_addr
  port map(
    Data     => mem_wr_addr_i,
    WrClock  => clk,
    RdClock  => clk_u,
    WrEn     => mem_wr_addr_wr_en_i,
    RdEn     => wr_addr_rd_en,
    Reset    => main_pll_lock_n,
    RPReset  => '0',
    Q        => mem_wr_addr,
    Empty    => wr_addr_empty,
    Full     => open
  );

  fifo_dc_clk_ext_to_int_0 : fifo_dc_clk_ext_to_int
  port map(
    Data     => cmd_wr_signals_ext_clk,
    WrClock  => clk,
    RdClock  => clk_u,
    WrEn     => clk_ext_to_int_wr_en,
    RdEn     => clk_ext_to_int_rd_en,
    Reset    => main_pll_lock_n,
    RPReset  => '0',
    Q        => clk_ext_to_int_signals,
    Empty    => clk_ext_to_int_empty,
    Full     => clk_ext_to_int_full
  );

  fifo_dc_clk_int_to_ext_0 : fifo_dc_clk_int_to_ext
  port map(
    Data     => cmd_wr_signals_int_clk,
    WrClock  => clk_u,
    RdClock  => clk,
    WrEn     => clk_int_to_ext_wr_en,
    RdEn     => clk_int_to_ext_rd_en,
    Reset    => main_pll_lock_n,
    RPReset  => '0',
    Q        => clk_int_to_ext_signals,
    Empty    => clk_int_to_ext_empty,
    Full     => clk_int_to_ext_full
  );

  fifo_dc_rd_data_0 : fifo_dc_rd_data
  port map(
    Data       => read_data,
    WrClock    => clk_u,
    RdClock    => clk,
    WrEn       => rd_fifo_wr_en,
    RdEn       => rd_fifo_rd_en,
    Reset      => logic_reset,
    RPReset    => '0',
    Q          => rd_fifo_data_out,
    Empty      => rd_fifo_empty,
    Full       => rd_fifo_full,
    AlmostFull => rd_fifo_almost_full
  );

  ddr3_sdram_mem_top_ddr3_ip_core_0 : ddr3_sdram_mem_top_ddr3_ip_core
  port map(
    clk_in          => cm_clk_p,
    rst_n           => reset_n,
    mem_rst_n       => mem_rst_n_reg,
    init_start      => init_start_reg,
    cmd             => cmd,
    addr            => addr,
    cmd_burst_cnt   => cmd_burst_cnt,
    cmd_valid       => cmd_valid,
    ofly_burst_len  => ofly_burst_len,
    write_data      => write_data,
    datain_rdy      => datain_rdy,
    data_mask       => data_mask,

    -- Output signals to the User I/F
    cmd_rdy         => cmd_rdy,
    init_done       => init_done,
    rt_err          => rt_err,
    wl_err          => wl_err,
    read_data       => read_data,
    read_data_valid => read_data_valid,

    -- Output for test logic
    sclk_out        => clk_u,
    clocking_good   => clocking_good,

    -- Memory side signals
    em_ddr_data     => em_ddr_data,
    em_ddr_reset_n  => em_ddr_reset_n,
    em_ddr_dqs      => em_ddr_dqs,
    em_ddr_clk      => em_ddr_clk,
    em_ddr_cke      => em_ddr_cke,
    em_ddr_ras_n    => em_ddr_ras_n,
    em_ddr_cas_n    => em_ddr_cas_n,
    em_ddr_we_n     => em_ddr_we_n,
    em_ddr_cs_n     => em_ddr_cs_n,
    em_ddr_odt      => em_ddr_odt,
    em_ddr_dm       => em_ddr_dm,
    em_ddr_ba       => em_ddr_ba,
    em_ddr_addr     => em_ddr_addr
  );

-- Fixing if read error or write error detected (can be read from status register)
  process(clk_u, logic_reset) begin
    if(logic_reset = '1') then
      rt_err_reg  <= '0';
      wl_err_reg  <= '0';
    elsif((clk_u = '1') and (clk_u'event)) then
      if(init_done_reg = '1') then
        if(rt_err = '1') then
          rt_err_reg <= '1';
        end if;
        if(wl_err = '1') then
          wl_err_reg <= '1';
        end if;
      end if;
    end if;
  end process;

-- Counting number of remaining write bursts "cmd_burst_cnt_wr_rem_reg" wich should be 32 aligned.
-- If write fifo has no enough data, burst count is set to
-- fifo read data count, and new alignment value will be subtracted
-- for burst count value "cmd_burst_cnt_wr_rem_reg - cmd_burst_cnt_wr".
  process(clk_u, logic_reset) begin
    if(logic_reset = '1') then
      cmd_burst_cnt_wr_rem_reg  <= "100000";
    elsif((clk_u = '1') and (clk_u'event)) then
      if((cmd = MEM_CMD_WRITE) and (cmd_valid = '1')) then
        if(wr_data_fifo_read_cnt_reg(6 downto 1) >= (cmd_burst_cnt_wr_rem_reg)) then
          cmd_burst_cnt_wr_rem_reg <= "100000";
        else
          cmd_burst_cnt_wr_rem_reg <= cmd_burst_cnt_wr_rem_reg - cmd_burst_cnt_wr;
        end if;
      end if;
    end if;
  end process;

--Forming flag which shows that write fifo contains at least two data
--which are the minimum for write operation.
--Delay on write fifo read data count for alignment.
  process(clk_u, main_pll_lock_n) begin
    if(main_pll_lock_n = '1') then
      wr_data_fifo_read_cnt_reg  <= (others => '0');
      wr_data_fifo_read_cnt_not_zero_reg <= '0';
    elsif((clk_u = '1') and (clk_u'event)) then
      if(wr_data_fifo_read_cnt_reg(6 downto 1) /= "000000") then
        wr_data_fifo_read_cnt_not_zero_reg <= '1';
      else
        wr_data_fifo_read_cnt_not_zero_reg <= '0';
      end if;
      wr_data_fifo_read_cnt_reg <= wr_data_fifo_read_cnt;
    end if;
  end process;

--Calculating read burst count. If remaining read data count is less than 32, it will be set to remaining,
--otherwise it will be set to "00000" which means 32 bursts (Maximum number of bursts for one command).
-- -2 in address size used because each address contains two data words.
  process(clk_u, logic_reset) begin
    if(logic_reset = '1') then
      cmd_burst_cnt_rd_rem_reg <= (others => '0');
    elsif((clk_u = '1') and (clk_u'event)) then
        if(mem_max_diff_addr((MEM_ADDRESS_SIZE - 2) downto 5) /= "00000000000000000000000") then
          cmd_burst_cnt_rd_rem_reg <= "00000";
        else
          cmd_burst_cnt_rd_rem_reg <= mem_max_diff_addr(4 downto 0);
        end if;
    end if;
  end process;


--Calculating current read address.
--Calculating difference between maximum read address and current read address.
  process(clk_u, logic_reset) begin
    if(logic_reset = '1') then
      ds_rd_addr_reg <= (others => '0');
      mem_max_diff_addr <= (others => '0');
    elsif((clk_u = '1') and (clk_u'event)) then
      if((cmd_valid = '1') and (cmd = MEM_CMD_READ) and (run_reg = '1')) then
        if(cmd_burst_cnt_rd = "00000") then
          if(ds_rd_addr_reg + "100000" >= mem_max_addr_reg((MEM_ADDRESS_SIZE - 1) downto 1)) then
            ds_rd_addr_reg <= (others => '0');
            mem_max_diff_addr <= mem_max_addr_reg((MEM_ADDRESS_SIZE - 1) downto 1);
          else
            ds_rd_addr_reg <= ds_rd_addr_reg + "100000";
            mem_max_diff_addr <= mem_max_addr_reg((MEM_ADDRESS_SIZE - 1) downto 1) - (ds_rd_addr_reg + "100000");
          end if;
        else
          if(ds_rd_addr_reg + cmd_burst_cnt_rd >= mem_max_addr_reg((MEM_ADDRESS_SIZE - 1) downto 1)) then
            ds_rd_addr_reg <= (others => '0');
            mem_max_diff_addr <= mem_max_addr_reg((MEM_ADDRESS_SIZE - 1) downto 1);
          else
            ds_rd_addr_reg <= ds_rd_addr_reg + cmd_burst_cnt_rd;
            mem_max_diff_addr <= mem_max_addr_reg((MEM_ADDRESS_SIZE - 1) downto 1) - (ds_rd_addr_reg + cmd_burst_cnt_rd);
          end if;
        end if;
      end if;
    end if;
  end process;

-- Countdown counter for writing burst count to create flag
-- which shows write command is in progress or finish.
-- This flag's delays are used to synchronize "ddr3 sdram" ip core commands.
  process(clk_u, main_pll_lock_n) begin
    if(main_pll_lock_n = '1') then
      mem_wr_cnt_reg         <= (others => '0');
      mem_wr_in_prog_0_reg <= '0';
      mem_wr_in_prog_1_reg <= '0';
      mem_wr_in_prog_2_reg <= '0';
    elsif((clk_u = '1') and (clk_u'event)) then
      mem_wr_in_prog_1_reg <= mem_wr_in_prog_0_reg;
      mem_wr_in_prog_2_reg <= mem_wr_in_prog_1_reg;

      if((cmd_valid = '1') and (cmd = MEM_CMD_WRITE)) then
        mem_wr_in_prog_0_reg <= '1';
        if(wr_data_fifo_read_cnt_reg(6) = '0') then
          mem_wr_cnt_reg <= '0' & cmd_burst_cnt & '0';
        else
          mem_wr_cnt_reg <= "1000000";
        end if;
      else
        if(datain_rdy = '1') then
          mem_wr_cnt_reg <= mem_wr_cnt_reg - 1;
        end if;
        if(mem_wr_cnt_reg = "0000000") then
          mem_wr_in_prog_0_reg <= '0';
        end if;
      end if;
    end if;
  end process;

-- "run_reg" signal is set by Calculation Enable command
-- and after passing through clock-crossing FIFO.
-- Main signal for reading dataset vectors and passing to DC slots.
  process(clk_u, main_pll_lock_n) begin
    if(main_pll_lock_n = '1') then
      run_reg <= '0';
    elsif((clk_u = '1') and (clk_u'event)) then
      if(clk_ext_to_int_empty = '0') then
        run_reg <= clk_ext_to_int_signals(0);
      end if;
    end if;
  end process;

-- Sets start write address when command is received from Packet Layer and
-- starts incrementing during write command execution - "mem_wr_addr_reg"
-- Calculating last written memory address for use in Read logic - "mem_max_addr_reg"
  process(clk_u, main_pll_lock_n) begin
    if(main_pll_lock_n = '1') then
      mem_wr_addr_reg <= (others => '0');
      wr_addr_rd_en_reg_1 <= '0';
      wr_addr_rd_en_reg_2 <= '0';
      mem_max_addr_reg  <= (others => '0');
    elsif((clk_u = '1') and (clk_u'event)) then
      wr_addr_rd_en_reg_1 <= wr_addr_rd_en;
      wr_addr_rd_en_reg_2 <= wr_addr_rd_en_reg_1;
      if(datain_rdy = '1') then
        mem_wr_addr_reg  <= mem_wr_addr_reg + '1';
        mem_max_addr_reg <= mem_wr_addr_reg + '1';
      end if;
      if(wr_addr_rd_en_reg_2 = '1') then
        mem_wr_addr_reg <= mem_wr_addr;
      end if;
    end if;
  end process;

-- Forming "ddr3 sdram" ip core reset
-- Forming "ddr3 sdram" ip core initialization controls and flag
  process(clk_u, main_pll_lock_i) begin
    if(main_pll_lock_i = '0') then
      init_counter   <= (others => '0');
      mem_rst_n_reg  <= '0';
      init_start_reg <= '0';
      init_done_reg  <= '0';
    elsif(clk_u = '1' and clk_u'event) then
      if(init_counter(4) = '1') then
        mem_rst_n_reg  <= '1';
        if((init_done_reg = '0') and (init_done = '0')) then
          init_start_reg <= '1';
        else
          init_start_reg <= '0';
        end if;

        if(init_start_reg = '1') then
          if(init_done = '1') then
            init_done_reg <= '1';
          end if;
        end if;
      else
        init_counter <= init_counter + '1';
      end if;
    end if;
  end process;

-- Counters for dataset vectors reading in DC Slots clock domain.
-- Are used for creating results with correct dataset IDs.
-- "last_ds_valid_vec_reg" signal is used to disable some DC engines in DC slots if
-- last data batch (16 vectors) does not contain the whole 16 vectors.
  process(clk, logic_reset) begin
    if(logic_reset = '1') then
      ds_addr_cnt_reg       <= (others => '0');
      ds_vec_counter_reg    <= (others => '0');
      last_ds_valid_vec_reg <= (others => '0');
    elsif(clk = '1' and (clk'event)) then
      last_ds_valid_vec_reg <= last_ds_valid_vec;

      if(mem_wr_addr_wr_en_i = '1') then
        ds_vec_counter_reg <= (others => '0');
        ds_addr_cnt_reg    <= (others => '0');
      elsif((ds_data_valid = '1') and (ds_rd_en_i = '1')) then
        if(ds_addr_cnt_reg = ds_vec_length_i) then
          ds_addr_cnt_reg <= (others => '0');
          if(ds_vec_counter_reg = ds_vec_count_i(31 downto 4)) then
            ds_vec_counter_reg <= (others => '0');
          else
            ds_vec_counter_reg <= ds_vec_counter_reg + '1';
          end if;
        else
          ds_addr_cnt_reg <= ds_addr_cnt_reg + '1';
        end if;
      end if;
    end if;
  end process;

-- Forming flag which shows that dataset outputs (to DC slots) are valid.
  process(clk, logic_reset) begin
    if(logic_reset = '1') then
      rd_fifo_valid_reg <= '0';
      rd_fifo_first_rd_en_reg <= '0';
    elsif((clk = '1') and (clk'event)) then
      if((run_i = '1') and (ds_rd_en_i  = '1')) then
        rd_fifo_valid_reg <= '0';
      end if;
      if((rd_fifo_rd_en = '1') and (rd_fifo_first_rd_en_reg = '1')) then
        rd_fifo_valid_reg <= '1';
      end if;

      if(rd_fifo_rd_en = '1') then
        rd_fifo_first_rd_en_reg <= '1';
      end if;
    end if;
  end process;

end rtl;
