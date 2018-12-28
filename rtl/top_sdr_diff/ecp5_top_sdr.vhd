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

---------------------------------
-- Top module for ecp5 project --
---------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.mem_ctrl_def.all;
use work.cfg_registers_def.all;
use work.dc_slot_def.all;

entity ecp5_top_sdr is
port(
  -- Main clock inputs
  cm_clk_p              : in    std_logic;

  reset_n_i             : in    std_logic;
  -- 3 bit Own FPGA Addres for checking corresponding bit in Packet
  own_fpga_address_i    : in    std_logic_vector( 2 downto 0);

  -- DDR3 Memory side signals
  ddr3_mem_reset_n      : out   std_logic;
  ddr3_mem_clk          : out   std_logic_vector( 1 downto 0);
  ddr3_mem_cke          : out   std_logic_vector( 0 downto 0);
  ddr3_mem_cs_n         : out   std_logic_vector( 0 downto 0);
  ddr3_mem_addr         : out   std_logic_vector(15 downto 0);
  ddr3_mem_ba           : out   std_logic_vector( 2 downto 0);
  ddr3_mem_ras_n        : out   std_logic;
  ddr3_mem_cas_n        : out   std_logic;
  ddr3_mem_dqs          : inout std_logic_vector( 3 downto 0);
  ddr3_mem_dm           : out   std_logic_vector( 3 downto 0);
  ddr3_mem_odt          : out   std_logic_vector( 0 downto 0);
  ddr3_mem_data         : inout std_logic_vector(31 downto 0);
  ddr3_mem_we_n         : out   std_logic;

  -- Parallel interface signals for left side  (Connect directly to pads)
  ls_sdr_clk_lr_i       : in    std_logic;
  ls_sdr_clk_rl_o       : out   std_logic;
  ls_sdr_data_io        : inout std_logic_vector(7 downto 0);
  ls_sdr_data_type_io   : inout std_logic_vector(1 downto 0);
  ls_sdr_dir_i          : in    std_logic;
  ls_has_data_o         : out   std_logic;
  ls_ready_io           : inout std_logic;

  -- Parallel interface signals for right side  (Connect directly to pads)
  rs_sdr_clk_lr_o       : out   std_logic;
  rs_sdr_clk_rl_i       : in    std_logic;
  rs_sdr_data_io        : inout std_logic_vector(7 downto 0);
  rs_sdr_data_type_io   : inout std_logic_vector(1 downto 0);
  rs_sdr_dir_o          : out   std_logic;
  rs_has_data_i         : in    std_logic;
  rs_ready_io           : inout std_logic
);
end ecp5_top_sdr;

architecture rtl of ecp5_top_sdr is

component own_fpga_addr_buf
port(
  own_fpga_address_in_i  : in  std_logic_vector( 2 downto 0);
  own_fpga_address_out_o : out std_logic_vector( 2 downto 0)
);
end component;

component main_pll
port(
  rst    : in  std_logic;
  clki   : in  std_logic;
  clkop  : out std_logic;
  clkos  : out std_logic;
  clkos2 : out std_logic;
  lock   : out std_logic
);
end component;

component ls_parallel_if_sdr
port(
  clk_fifo_if           : in    std_logic;
  clk_par_if            : in    std_logic;
  clk_par_if_ph_shift   : in    std_logic;
  reset_n               : in    std_logic;

  -- Parallel interface signals  (Connect directly to pads)
  ls_sdr_clk_lr_i       : in    std_logic;
  ls_sdr_clk_rl_o       : out   std_logic;
  ls_sdr_data_io        : inout std_logic_vector(7 downto 0);
  ls_sdr_data_type_io   : inout std_logic_vector(1 downto 0);
  ls_sdr_dir_i          : in    std_logic;
  ls_has_data_o         : out   std_logic;
  ls_ready_io           : inout std_logic;

  -- FIFO  interface signals
  ds_fifo_din_i         : in    std_logic_vector(35 downto 0);
  ds_fifo_wr_en_i       : in    std_logic;
  ds_fifo_full_o        : out   std_logic;

  us_fifo_dout_o        : out   std_logic_vector(35 downto 0);
  us_fifo_rd_en_i       : in    std_logic;
  us_fifo_empty_o       : out   std_logic
);
end component;

component rs_parallel_if_sdr
port(
  clk_fifo_if           : in    std_logic;
  clk_par_if            : in    std_logic;
  clk_par_if_ph_shift   : in    std_logic;
  reset_n               : in    std_logic;

  -- 3 bit Own FPGA Addres for checking corresponding bit in Packet
  own_fpga_address_i    : in    std_logic_vector( 2 downto 0);

  -- Parallel interface signals  (Connect directly to pads)
  rs_sdr_clk_lr_o       : out   std_logic;
  rs_sdr_clk_rl_i       : in    std_logic;
  rs_sdr_data_io        : inout std_logic_vector(7 downto 0);
  rs_sdr_data_type_io   : inout std_logic_vector(1 downto 0);
  rs_sdr_dir_o          : out   std_logic;
  rs_has_data_i         : in    std_logic;
  rs_ready_io           : inout std_logic;

  -- FIFO  interface signals
  ds_fifo_dout_o        : out   std_logic_vector(35 downto 0);
  ds_fifo_rd_en_i       : in    std_logic;
  ds_fifo_empty_o       : out   std_logic;

  us_fifo_din_i         : in    std_logic_vector(35 downto 0);
  us_fifo_wr_en_i       : in    std_logic;
  us_fifo_full_o        : out   std_logic
);
end component;

component packet_controller
port(
  clk                   : in  std_logic;
  reset_n               : in  std_logic;

  -- 3 bit Own FPGA Addres for checking corresponding bit in Packet
  own_fpga_address_i    : in  std_logic_vector( 2 downto 0);

  -- Left Side Upstream FIFO interface signals
  ls_us_fifo_din_i      : in  std_logic_vector(35 downto 0);
  ls_us_fifo_rd_en_o    : out std_logic;
  ls_us_fifo_empty_i    : in  std_logic;

  -- Left Side Downstream FIFO interface signals
  ls_ds_fifo_dout_o     : out std_logic_vector(35 downto 0);
  ls_ds_fifo_wr_en_o    : out std_logic;
  ls_ds_fifo_full_i     : in  std_logic;

  -- Right Side Upstream FIFO interface signals
  rs_us_fifo_dout_o     : out std_logic_vector(35 downto 0);
  rs_us_fifo_wr_en_o    : out std_logic;
  rs_us_fifo_full_i     : in  std_logic;

  -- Right Side Downstream FIFO interface signals
  rs_ds_fifo_din_i      : in  std_logic_vector(35 downto 0);
  rs_ds_fifo_rd_en_o    : out std_logic;
  rs_ds_fifo_empty_i    : in  std_logic;

  -- DDR3 Memory Init done
  mem_init_done_i       : in  std_logic;

  -- DDR3 Memory Write cmd user interface
  mem_wr_addr_o         : out std_logic_vector((MEM_ADDRESS_SIZE - 1) downto 0);
  mem_wr_addr_wr_en_o   : out std_logic;

  -- DDR3 Memory Write data user interface
  mem_wr_data_o         : out std_logic_vector(31 downto 0);
  mem_wr_en_o           : out std_logic;
  mem_wr_full_i         : in  std_logic;

  -- Query Vectors Writing interface
  qv_wr_en_o            : out std_logic;
  qv_wr_data_o          : out std_logic_vector(31 downto 0);
  qv_first_comp_o       : out std_logic;
  qv_last_comp_o        : out std_logic;
  qv_full_i             : in  std_logic;
  qv_id_o               : out std_logic_vector(15 downto 0);
  qv_id_wr_en_o         : out std_logic;

  -- Config Registres Writing interface
  cfg_reg_wr_en_o       : out std_logic;
  cfg_reg_wr_data_o     : out std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
  cfg_reg_wr_address_o  : out std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0);

  -- Config  Registres Read interface
  cfg_reg_rd_data_i     : in  std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
  cfg_reg_rd_address_o  : out std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0);

  -- Calculation Control Signals
  calc_reset_o          : out std_logic;
  calc_enable_o         : out std_logic;

  -- Own Results interface
  own_result_data_i     : in  std_logic_vector(127 downto 0);
  own_result_valid_i    : in  std_logic;
  own_result_rd_o       : out std_logic
);
end component;

component cfg_registers
port(
  clk                    : in  std_logic;
  reset_n                : in  std_logic;

  status_i               : in  std_logic_vector(15 downto 0);

  -- Registers Writing interface
  wr_en_i                : in  std_logic;
  wr_data_i              : in  std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
  wr_address_i           : in  std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0);

  -- Registers Read interface
  rd_data_o              : out std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
  rd_address_i           : in  std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0);

  -- Configuration outputs
  threshold_o            : out std_logic_vector((DISTANCE_SIZE - 1)       downto 0);
  knn_num_o              : out std_logic_vector((KNN_NUM_SIZE        - 1) downto 0);
  dsv_count_o            : out std_logic_vector((DSV_COUNT_HI_SIZE + DSV_COUNT_LO_SIZE - 1) downto 0);
  dsv_length_o           : out std_logic_vector((DSV_LENGTH_SIZE     - 1) downto 0);

  temperature_o          : out std_logic_vector(5 downto 0)
);
end component;

component memory_controller
port(
  -- Common signals
  reset_n               : in  std_logic;
  main_pll_lock_i       : in  std_logic;
  mem_pll_lock_o        : out std_logic;
  clk                   : in  std_logic;
  clk_out               : out std_logic;
  calc_reset_i          : in  std_logic;

  -- DDR3 Memory Write cmd user interface
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
end component;

component dc_slots_array
port(
  clk                : in  std_logic;
  reset_n            : in  std_logic;
  own_fpga_addr_i    : in  std_logic_vector( 2 downto 0);
  threshold_i        : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  knn_num_i          : in  std_logic_vector( 6 downto 0);
  temperature_i      : in  std_logic_vector( 5 downto 0);
  pause              : out std_logic;
  calc_en            : in  std_logic;
  first_comp         : in  std_logic;
  last_comp          : in  std_logic;
  reset_vec_cntr     : in  std_logic;
  fv_counter         : in  std_logic_vector(27 downto 0);
  ram_bus_00         : in  std_logic_vector(7  downto 0);
  ram_bus_01         : in  std_logic_vector(7  downto 0);
  ram_bus_02         : in  std_logic_vector(7  downto 0);
  ram_bus_03         : in  std_logic_vector(7  downto 0);
  ram_bus_04         : in  std_logic_vector(7  downto 0);
  ram_bus_05         : in  std_logic_vector(7  downto 0);
  ram_bus_06         : in  std_logic_vector(7  downto 0);
  ram_bus_07         : in  std_logic_vector(7  downto 0);
  ram_bus_08         : in  std_logic_vector(7  downto 0);
  ram_bus_09         : in  std_logic_vector(7  downto 0);
  ram_bus_10         : in  std_logic_vector(7  downto 0);
  ram_bus_11         : in  std_logic_vector(7  downto 0);
  ram_bus_12         : in  std_logic_vector(7  downto 0);
  ram_bus_13         : in  std_logic_vector(7  downto 0);
  ram_bus_14         : in  std_logic_vector(7  downto 0);
  ram_bus_15         : in  std_logic_vector(7  downto 0);
  data_valid_vec_i   : in  std_logic_vector(15 downto 0);
  qv_wr_data         : in  std_logic_vector(31 downto 0);
  qv_wr_en_i         : in  std_logic;
  qv_first_data      : in  std_logic;
  qv_last_data       : in  std_logic;
  qv_status_o        : out std_logic;
  qv_valid_o         : out std_logic;
  qv_id              : in  std_logic_vector(15 downto 0);
  qv_id_wr_en        : in  std_logic;

  result_valid_o     : out std_logic;
  result_data_o      : out std_logic_vector(127 downto 0);
  result_rd_i        : in  std_logic
);
end component;

component wait_rdy_cnt
port(
  clk          : in  std_logic;
  reset_n      : in  std_logic;
  fv_length    : in  std_logic_vector((DSV_LENGTH_SIZE     - 1) downto 0);
  last_comp    : in  std_logic;
  rd_en        : out std_logic
);
end component;

signal clk_out_mem          : std_logic;
signal clk_main             : std_logic;
signal clk_parallel         : std_logic;
signal clk_parallel_ph_shift: std_logic;
signal reset_n_main_reg     : std_logic;
signal reset_n_main         : std_logic;
signal dc_slots_reset_n     : std_logic;

signal own_fpga_address     : std_logic_vector(2 downto 0);

signal status               : std_logic_vector(15 downto 0);

signal ls_ds_fifo_din       : std_logic_vector(35 downto 0);
signal ls_ds_fifo_wr_en     : std_logic;
signal ls_ds_fifo_full      : std_logic;
signal ls_us_fifo_dout      : std_logic_vector(35 downto 0);
signal ls_us_fifo_rd_en     : std_logic;
signal ls_us_fifo_empty     : std_logic;

signal rs_ds_fifo_dout      : std_logic_vector(35 downto 0);
signal rs_ds_fifo_rd_en     : std_logic;
signal rs_ds_fifo_empty     : std_logic;
signal rs_us_fifo_din       : std_logic_vector(35 downto 0);
signal rs_us_fifo_wr_en     : std_logic;
signal rs_us_fifo_full      : std_logic;

signal mem_init_done        : std_logic;
signal mem_wr_addr          : std_logic_vector((MEM_ADDRESS_SIZE - 1) downto 0);
signal mem_wr_addr_wr_en    : std_logic;
signal mem_wr_data          : std_logic_vector(31 downto 0);
signal mem_wr_en            : std_logic;
signal mem_wr_full          : std_logic;
signal mem_wr_fifo_empty    : std_logic;
signal mem_wl_err           : std_logic;
signal mem_rt_err           : std_logic;
signal mem_cmd_valid        : std_logic;
signal mem_rd_fifo_empty    : std_logic;
signal mem_rd_fifo_afull    : std_logic;

signal qv_wr_en             : std_logic;
signal qv_wr_data           : std_logic_vector(31 downto 0);
signal qv_first_comp        : std_logic;
signal qv_last_comp         : std_logic;
signal qv_full              : std_logic;
signal qv_id                : std_logic_vector(15 downto 0);
signal qv_id_wr_en          : std_logic;

signal cfg_reg_wr_en        : std_logic;
signal cfg_reg_wr_data      : std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
signal cfg_reg_wr_address   : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0);
signal cfg_reg_rd_data      : std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
signal cfg_reg_rd_address   : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0);

signal calc_reset           : std_logic;
signal calc_enable          : std_logic;

signal own_result_data      : std_logic_vector(127 downto 0);
signal own_result_valid     : std_logic;
signal own_result_rd        : std_logic;

signal threshold            : std_logic_vector((DISTANCE_SIZE - 1)       downto 0);
signal knn_num              : std_logic_vector((KNN_NUM_SIZE        - 1) downto 0);
signal dsv_count            : std_logic_vector((DSV_COUNT_HI_SIZE + DSV_COUNT_LO_SIZE - 1) downto 0);
signal dsv_length           : std_logic_vector((DSV_LENGTH_SIZE     - 1) downto 0);
signal temperature          : std_logic_vector(5 downto 0);

signal ds_out_dc_00         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_01         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_02         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_03         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_04         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_05         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_06         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_07         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_08         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_09         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_10         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_11         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_12         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_13         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_14         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);
signal ds_out_dc_15         : std_logic_vector(DS_COMPONENT_LENGTH-1 downto 0);

signal ds_data_valid        : std_logic;
signal ds_rd_en             : std_logic;
signal ds_vec_counter       : std_logic_vector(27 downto 0);
signal ds_data_valid_vec    : std_logic_vector(15 downto 0);
signal ds_first_comp        : std_logic;
signal ds_last_comp         : std_logic;
signal ds_reset_vec_cntr    : std_logic;

signal pause                : std_logic;
signal qv_valid             : std_logic;

signal reset_main_pll_reg   : std_logic;
signal reset_main_pll       : std_logic;
signal mem_pll_lock         : std_logic;
signal mem_pll_lock_counter : std_logic_vector(7 downto 0);
signal main_pll_lock        : std_logic;
signal main_pll_lock_counter: std_logic_vector(7 downto 0);

signal wait_rd_en           : std_logic;

begin

reset_main_pll   <= reset_main_pll_reg;

reset_n_main     <= reset_n_main_reg;

dc_slots_reset_n <= reset_n_main;

status           <= X"00" & "00" & mem_cmd_valid & mem_rd_fifo_empty & mem_rd_fifo_afull & mem_rt_err & mem_wl_err & mem_init_done;

ds_rd_en         <= qv_valid and (not pause) and wait_rd_en;

-- reset_main_pll_reg active high reset must become '0' when mem_pll_lock is '1' for X"F0" clock cycles
process(clk_out_mem)
begin
  if (clk_out_mem = '1' and clk_out_mem'event) then
    if(mem_pll_lock = '0') then
      mem_pll_lock_counter <= (others => '0');
      reset_main_pll_reg <= '1';
    else
      if(reset_main_pll_reg = '1') then
        if(mem_pll_lock_counter = X"F0") then
          reset_main_pll_reg <= '0';
        else
          mem_pll_lock_counter <= mem_pll_lock_counter + '1';
        end if;
      end if;
    end if;
  end if;
end process;

-- reset_n_main_reg active low reset (main reset signal for system)
-- must become '1' when main_pll_lock is '1' for X"F0" clock cycles
process(clk_main)
begin
  if (clk_main = '1' and clk_main'event) then
    if(main_pll_lock = '0') then
      main_pll_lock_counter <= (others => '0');
      reset_n_main_reg <= '0';
    else
      if(reset_n_main_reg = '0') then
        if(main_pll_lock_counter = X"F0") then
          reset_n_main_reg <= '1';
        else
          main_pll_lock_counter <= main_pll_lock_counter + '1';
        end if;
      end if;
    end if;
  end if;
end process;

own_fpga_addr_buf_0 : own_fpga_addr_buf
port map(
  own_fpga_address_in_i  => own_fpga_address_i,
  own_fpga_address_out_o => own_fpga_address
);

main_pll_0 : main_pll
port map(
  rst    => reset_main_pll,
  clki   => clk_out_mem,
  clkop  => clk_main,
  clkos  => clk_parallel,
  clkos2 => clk_parallel_ph_shift,
  lock   => main_pll_lock
);

ls_parallel_if_sdr_0 : ls_parallel_if_sdr
port map(
  clk_fifo_if           => clk_main,
  clk_par_if            => clk_parallel,
  clk_par_if_ph_shift   => clk_parallel_ph_shift,
  reset_n               => reset_n_main,
  ls_sdr_clk_lr_i       => ls_sdr_clk_lr_i,
  ls_sdr_clk_rl_o       => ls_sdr_clk_rl_o,
  ls_sdr_data_io        => ls_sdr_data_io,
  ls_sdr_data_type_io   => ls_sdr_data_type_io,
  ls_sdr_dir_i          => ls_sdr_dir_i,
  ls_has_data_o         => ls_has_data_o,
  ls_ready_io           => ls_ready_io,
  ds_fifo_din_i         => ls_ds_fifo_din,
  ds_fifo_wr_en_i       => ls_ds_fifo_wr_en,
  ds_fifo_full_o        => ls_ds_fifo_full,
  us_fifo_dout_o        => ls_us_fifo_dout,
  us_fifo_rd_en_i       => ls_us_fifo_rd_en,
  us_fifo_empty_o       => ls_us_fifo_empty
);

rs_parallel_if_sdr_0 : rs_parallel_if_sdr
port map(
  clk_fifo_if           => clk_main,
  clk_par_if            => clk_parallel,
  clk_par_if_ph_shift   => clk_parallel_ph_shift,
  reset_n               => reset_n_main,
  own_fpga_address_i    => own_fpga_address,
  rs_sdr_clk_lr_o       => rs_sdr_clk_lr_o,
  rs_sdr_clk_rl_i       => rs_sdr_clk_rl_i,
  rs_sdr_data_io        => rs_sdr_data_io,
  rs_sdr_data_type_io   => rs_sdr_data_type_io,
  rs_sdr_dir_o          => rs_sdr_dir_o,
  rs_has_data_i         => rs_has_data_i,
  rs_ready_io           => rs_ready_io,
  ds_fifo_dout_o        => rs_ds_fifo_dout,
  ds_fifo_rd_en_i       => rs_ds_fifo_rd_en,
  ds_fifo_empty_o       => rs_ds_fifo_empty,
  us_fifo_din_i         => rs_us_fifo_din,
  us_fifo_wr_en_i       => rs_us_fifo_wr_en,
  us_fifo_full_o        => rs_us_fifo_full
);

packet_controller_0 : packet_controller
port map(
  clk                   => clk_main,
  reset_n               => reset_n_main,

  -- 3 bit Own FPGA Addres for checking corresponding bit in Packet
  own_fpga_address_i    => own_fpga_address,

  -- Left Side Upstream FIFO interface signals
  ls_us_fifo_din_i      => ls_us_fifo_dout,
  ls_us_fifo_rd_en_o    => ls_us_fifo_rd_en,
  ls_us_fifo_empty_i    => ls_us_fifo_empty,

  -- Left Side Downstream FIFO interface signals
  ls_ds_fifo_dout_o     => ls_ds_fifo_din,
  ls_ds_fifo_wr_en_o    => ls_ds_fifo_wr_en,
  ls_ds_fifo_full_i     => ls_ds_fifo_full,

  -- Right Side Upstream FIFO interface signals
  rs_us_fifo_dout_o     => rs_us_fifo_din,
  rs_us_fifo_wr_en_o    => rs_us_fifo_wr_en,
  rs_us_fifo_full_i     => rs_us_fifo_full,

  -- Right Side Downstream FIFO interface signals
  rs_ds_fifo_din_i      => rs_ds_fifo_dout,
  rs_ds_fifo_rd_en_o    => rs_ds_fifo_rd_en,
  rs_ds_fifo_empty_i    => rs_ds_fifo_empty,

  mem_init_done_i       => mem_init_done,

  -- DDR3 Memory Write cmd user interface
  mem_wr_addr_o         => mem_wr_addr,
  mem_wr_addr_wr_en_o   => mem_wr_addr_wr_en,

  -- DDR3 Memory Write data user interface
  mem_wr_data_o         => mem_wr_data,
  mem_wr_en_o           => mem_wr_en,
  mem_wr_full_i         => mem_wr_full,

  -- Query Vectors Writing interface
  qv_wr_en_o            => qv_wr_en,
  qv_wr_data_o          => qv_wr_data,
  qv_first_comp_o       => qv_first_comp,
  qv_last_comp_o        => qv_last_comp,
  qv_full_i             => qv_full,
  qv_id_o               => qv_id,
  qv_id_wr_en_o         => qv_id_wr_en,

  -- Config Registres Writing interface
  cfg_reg_wr_en_o       => cfg_reg_wr_en,
  cfg_reg_wr_data_o     => cfg_reg_wr_data,
  cfg_reg_wr_address_o  => cfg_reg_wr_address,

  -- Config  Registres Read interface
  cfg_reg_rd_data_i     => cfg_reg_rd_data,
  cfg_reg_rd_address_o  => cfg_reg_rd_address,

  -- Calculation Control Signals
  calc_reset_o          => calc_reset,
  calc_enable_o         => calc_enable,

  -- Own Results interface
  own_result_data_i     => own_result_data,
  own_result_valid_i    => own_result_valid,
  own_result_rd_o       => own_result_rd
);

cfg_registers_0 : cfg_registers
port map(
  clk              => clk_main,
  reset_n          => reset_n_main,
  status_i         => status,
  wr_en_i          => cfg_reg_wr_en,
  wr_data_i        => cfg_reg_wr_data,
  wr_address_i     => cfg_reg_wr_address,
  rd_data_o        => cfg_reg_rd_data,
  rd_address_i     => cfg_reg_rd_address,
  threshold_o      => threshold,
  knn_num_o        => knn_num,
  dsv_count_o      => dsv_count,
  dsv_length_o     => dsv_length,
  temperature_o    => temperature
);

memory_controller_0 : memory_controller
port map(
  -- Common signals
  reset_n               => reset_n_i,
  main_pll_lock_i       => reset_n_main,
  mem_pll_lock_o        => mem_pll_lock,
  clk                   => clk_main,
  clk_out               => clk_out_mem,
  calc_reset_i          => calc_reset,

  -- DDR3 Memory Write address user interface
  mem_wr_addr_i         => mem_wr_addr,
  mem_wr_addr_wr_en_i   => mem_wr_addr_wr_en,

  -- DDR3 Memory Write data user interface
  mem_wr_data_i         => mem_wr_data,
  mem_wr_en_i           => mem_wr_en,
  mem_wr_full_o         => mem_wr_full,
  mem_wr_fifo_empty_o   => mem_wr_fifo_empty,

  -- DDR3 Memory Read Data Set interface
  ds_out_dc_00_o        => ds_out_dc_00,
  ds_out_dc_01_o        => ds_out_dc_01,
  ds_out_dc_02_o        => ds_out_dc_02,
  ds_out_dc_03_o        => ds_out_dc_03,
  ds_out_dc_04_o        => ds_out_dc_04,
  ds_out_dc_05_o        => ds_out_dc_05,
  ds_out_dc_06_o        => ds_out_dc_06,
  ds_out_dc_07_o        => ds_out_dc_07,
  ds_out_dc_08_o        => ds_out_dc_08,
  ds_out_dc_09_o        => ds_out_dc_09,
  ds_out_dc_10_o        => ds_out_dc_10,
  ds_out_dc_11_o        => ds_out_dc_11,
  ds_out_dc_12_o        => ds_out_dc_12,
  ds_out_dc_13_o        => ds_out_dc_13,
  ds_out_dc_14_o        => ds_out_dc_14,
  ds_out_dc_15_o        => ds_out_dc_15,

  ds_data_valid_o       => ds_data_valid,
  ds_rd_en_i            => ds_rd_en,
  ds_vec_counter_o      => ds_vec_counter,
  ds_data_valid_vec_o   => ds_data_valid_vec,
  ds_first_comp_o       => ds_first_comp,
  ds_last_comp_o        => ds_last_comp,
  ds_reset_vec_cntr_o   => ds_reset_vec_cntr,

  -- Configuration signals
  ds_vec_length_i       => dsv_length,
  ds_vec_count_i        => dsv_count,
  run_i                 => calc_enable,

  -- DDR3 Memory side signals
  cm_clk_p              => cm_clk_p,
  em_ddr_data           => ddr3_mem_data,
  em_ddr_reset_n        => ddr3_mem_reset_n,
  em_ddr_dqs            => ddr3_mem_dqs,
  em_ddr_clk            => ddr3_mem_clk,
  em_ddr_cke            => ddr3_mem_cke,
  em_ddr_ras_n          => ddr3_mem_ras_n,
  em_ddr_cas_n          => ddr3_mem_cas_n,
  em_ddr_we_n           => ddr3_mem_we_n,
  em_ddr_cs_n           => ddr3_mem_cs_n,
  em_ddr_odt            => ddr3_mem_odt,
  em_ddr_dm             => ddr3_mem_dm,
  em_ddr_ba             => ddr3_mem_ba,
  em_ddr_addr           => ddr3_mem_addr,

  -- Statuses
  init_done_o           => mem_init_done,
  wl_err_o              => mem_wl_err,
  rt_err_o              => mem_rt_err,
  cmd_valid_o           => mem_cmd_valid,
  rd_fifo_empty_o       => mem_rd_fifo_empty,
  rd_fifo_almost_full_o => mem_rd_fifo_afull
);

dc_slots_array_0 : dc_slots_array
port map(
  clk                 => clk_main,
  reset_n             => dc_slots_reset_n,
  own_fpga_addr_i     => own_fpga_address,
  threshold_i         => threshold,
  knn_num_i           => knn_num,
  temperature_i       => temperature,
  pause               => pause,
  calc_en             => ds_data_valid,
  first_comp          => ds_first_comp,
  last_comp           => ds_last_comp,
  reset_vec_cntr      => ds_reset_vec_cntr,
  fv_counter          => ds_vec_counter,
  ram_bus_00          => ds_out_dc_00,
  ram_bus_01          => ds_out_dc_01,
  ram_bus_02          => ds_out_dc_02,
  ram_bus_03          => ds_out_dc_03,
  ram_bus_04          => ds_out_dc_04,
  ram_bus_05          => ds_out_dc_05,
  ram_bus_06          => ds_out_dc_06,
  ram_bus_07          => ds_out_dc_07,
  ram_bus_08          => ds_out_dc_08,
  ram_bus_09          => ds_out_dc_09,
  ram_bus_10          => ds_out_dc_10,
  ram_bus_11          => ds_out_dc_11,
  ram_bus_12          => ds_out_dc_12,
  ram_bus_13          => ds_out_dc_13,
  ram_bus_14          => ds_out_dc_14,
  ram_bus_15          => ds_out_dc_15,
  data_valid_vec_i    => ds_data_valid_vec,
  qv_wr_data          => qv_wr_data,
  qv_wr_en_i          => qv_wr_en,
  qv_first_data       => qv_first_comp,
  qv_last_data        => qv_last_comp,
  qv_status_o         => qv_full,
  qv_valid_o          => qv_valid,
  qv_id               => qv_id,
  qv_id_wr_en         => qv_id_wr_en,

  result_valid_o      => own_result_valid,
  result_data_o       => own_result_data,
  result_rd_i         => own_result_rd
);

wait_rdy_cnt_0 : wait_rdy_cnt
  port map(
    clk          => clk_main,
    reset_n      => reset_n_main,
    fv_length    => dsv_length,
    last_comp    => ds_last_comp,
    rd_en        => wait_rd_en
  );

end rtl;
