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

---------------------------------------------------------------------
-- Packet layer, contains command packet detector for upstream and --
-- response packet generator for downstream packets.               --
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.mem_ctrl_def.all;
use work.cfg_registers_def.all;

entity packet_controller is
port(
  clk                   : in  std_logic;
  reset_n               : in  std_logic;

    -- 3 bit Own FPGA Addres for checking corresponding bit in Packet
  own_fpga_address_i    : in    std_logic_vector( 2 downto 0);

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
  own_result_data_i    : in  std_logic_vector(127 downto 0);
  own_result_valid_i   : in  std_logic;
  own_result_rd_o      : out std_logic
);
end packet_controller;

architecture rtl of packet_controller is

component command_packet_detector
port(
  clk                   : in  std_logic;
  reset_n               : in  std_logic;

    -- 3 bit Own FPGA Addres for checking corresponding bit in Packet
  own_fpga_address_i    : in    std_logic_vector( 2 downto 0);

    -- Left Side Upstream FIFO interface signals
  ls_us_fifo_din_i      : in  std_logic_vector(35 downto 0);
  ls_us_fifo_rd_en_o    : out std_logic;
  ls_us_fifo_empty_i    : in  std_logic;

    -- Right Side Upstream FIFO interface signals
  rs_us_fifo_dout_o     : out std_logic_vector(35 downto 0);
  rs_us_fifo_wr_en_o    : out std_logic;
  rs_us_fifo_full_i     : in  std_logic;

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
  own_resp_data_o      : out std_logic_vector(95 downto 0);
  own_resp_valid_o     : out std_logic;
  own_resp_rdy_i       : in  std_logic
);
end component;

component resp_pack_gen
port(
  -- Common signals
  reset_n            : in  std_logic;
  clk                : in  std_logic;

  -- Downstream FIFO interface (To left side)
  ls_data_o          : out std_logic_vector(35 downto 0);
  ls_wr_en_o         : out std_logic;
  ls_full_i          : in  std_logic;

  -- Downstream FIFO interface (From right side)
  rs_data_i          : in  std_logic_vector(35 downto 0);
  rs_empty_i         : in  std_logic;
  rs_rd_en_o         : out std_logic;

  -- Own Responce interface
  own_resp_data_i    : in  std_logic_vector(95 downto 0);
  own_resp_valid_i   : in  std_logic;
  own_resp_rdy_o     : out std_logic;

  -- Own Results interface
  own_result_data_i  : in  std_logic_vector(127 downto 0);
  own_result_valid_i : in  std_logic;
  own_result_rd_o    : out std_logic
);
end component;

signal own_resp_data   : std_logic_vector(95 downto 0);
signal own_resp_valid  : std_logic;
signal own_resp_rdy    : std_logic;

begin

command_packet_detector_0 : command_packet_detector
port map(
  clk                   => clk,
  reset_n               => reset_n,

    -- 3 bit Own FPGA Addres for checking corresponding bit in Packet
  own_fpga_address_i    => own_fpga_address_i,

    -- Left Side Upstream FIFO interface signals
  ls_us_fifo_din_i      => ls_us_fifo_din_i,
  ls_us_fifo_rd_en_o    => ls_us_fifo_rd_en_o,
  ls_us_fifo_empty_i    => ls_us_fifo_empty_i,

    -- Right Side Upstream FIFO interface signals
  rs_us_fifo_dout_o     => rs_us_fifo_dout_o,
  rs_us_fifo_wr_en_o    => rs_us_fifo_wr_en_o,
  rs_us_fifo_full_i     => rs_us_fifo_full_i,

    -- DDR3 Memory Init done
  mem_init_done_i       => mem_init_done_i,

    -- DDR3 Memory Write cmd user interface
  mem_wr_addr_o         => mem_wr_addr_o,
  mem_wr_addr_wr_en_o   => mem_wr_addr_wr_en_o,

    -- DDR3 Memory Write data user interface
  mem_wr_data_o         => mem_wr_data_o,
  mem_wr_en_o           => mem_wr_en_o,
  mem_wr_full_i         => mem_wr_full_i,

    -- Query Vectors Writing interface
  qv_wr_en_o            => qv_wr_en_o,
  qv_wr_data_o          => qv_wr_data_o,
  qv_first_comp_o       => qv_first_comp_o,
  qv_last_comp_o        => qv_last_comp_o,
  qv_full_i             => qv_full_i,
  qv_id_o               => qv_id_o,
  qv_id_wr_en_o         => qv_id_wr_en_o,

    -- Config Registres Writing interface
  cfg_reg_wr_en_o       => cfg_reg_wr_en_o,
  cfg_reg_wr_data_o     => cfg_reg_wr_data_o,
  cfg_reg_wr_address_o  => cfg_reg_wr_address_o,

    -- Config  Registres Read interface
  cfg_reg_rd_data_i     => cfg_reg_rd_data_i,
  cfg_reg_rd_address_o  => cfg_reg_rd_address_o,

    -- Calculation Control Signals
  calc_reset_o          => calc_reset_o,
  calc_enable_o         => calc_enable_o,

    -- Own Results interface
  own_resp_data_o       => own_resp_data,
  own_resp_valid_o      => own_resp_valid,
  own_resp_rdy_i        => own_resp_rdy
);

resp_pack_gen_0 : resp_pack_gen
port map(
    -- Common signals
  reset_n            => reset_n,
  clk                => clk,

    -- Downstream FIFO interface (To left side)
  ls_data_o          => ls_ds_fifo_dout_o,
  ls_wr_en_o         => ls_ds_fifo_wr_en_o,
  ls_full_i          => ls_ds_fifo_full_i,

    -- Downstream FIFO interface (From right side)
  rs_data_i          => rs_ds_fifo_din_i,
  rs_empty_i         => rs_ds_fifo_empty_i,
  rs_rd_en_o         => rs_ds_fifo_rd_en_o,

    -- Own Responce interface
  own_resp_data_i    => own_resp_data,
  own_resp_valid_i   => own_resp_valid,
  own_resp_rdy_o     => own_resp_rdy,

    -- Own Results interface
  own_result_data_i  => own_result_data_i,
  own_result_valid_i => own_result_valid_i,
  own_result_rd_o    => own_result_rd_o
);

end rtl;
