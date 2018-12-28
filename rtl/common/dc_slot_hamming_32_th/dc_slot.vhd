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
-- The system, device and methods implemented in this code are covered
-- by US patents #9,747,547 and #9,269,041. Unlimited license for use
-- of this code under the terms of the GPL license is hereby granted.
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

------------------------------------------------------------------------
-- Includes query vector buffer, dc row and                           --
-- row best result (results thresholding and packet creating) modules --
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.dc_slot_def.all;

entity dc_slot is
port(
    clk              : in  std_logic;
    reset_n          : in  std_logic;
    own_fpga_addr_i  : in  std_logic_vector( 2 downto 0);
    threshold_i      : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
    knn_num_i        : in  std_logic_vector( 6 downto 0);
    temperature_i    : in  std_logic_vector( 5 downto 0);
    fifo_z_rd_en     : in  std_logic;
    fifo_z_dout      : out std_logic_vector(127 downto 0);
    fifo_z_empty     : out std_logic;
    qv_wr_en         : in  std_logic;
    qv_wr_data       : in  std_logic_vector(31 downto 0);
    qv_first_data    : in  std_logic;
    qv_last_data     : in  std_logic;
    qv_status        : out std_logic;
    qv_id            : in  std_logic_vector(15 downto 0);
    qv_id_wr_en      : in  std_logic;
    calc_en          : in  std_logic;
    data_valid_vec_i : in  std_logic_vector(15 downto 0);
    first_comp       : in  std_logic;
    last_comp        : in  std_logic;
    pause            : out std_logic;
    reset_vec_cntr   : in  std_logic;
    fv_counter       : in  std_logic_vector(27 downto 0);
    ram_bus_00       : in  std_logic_vector( 7 downto 0);
    ram_bus_01       : in  std_logic_vector( 7 downto 0);
    ram_bus_02       : in  std_logic_vector( 7 downto 0);
    ram_bus_03       : in  std_logic_vector( 7 downto 0);
    ram_bus_04       : in  std_logic_vector( 7 downto 0);
    ram_bus_05       : in  std_logic_vector( 7 downto 0);
    ram_bus_06       : in  std_logic_vector( 7 downto 0);
    ram_bus_07       : in  std_logic_vector( 7 downto 0);
    ram_bus_08       : in  std_logic_vector( 7 downto 0);
    ram_bus_09       : in  std_logic_vector( 7 downto 0);
    ram_bus_10       : in  std_logic_vector( 7 downto 0);
    ram_bus_11       : in  std_logic_vector( 7 downto 0);
    ram_bus_12       : in  std_logic_vector( 7 downto 0);
    ram_bus_13       : in  std_logic_vector( 7 downto 0);
    ram_bus_14       : in  std_logic_vector( 7 downto 0);
    ram_bus_15       : in  std_logic_vector( 7 downto 0)
);
end dc_slot;

architecture rtl of dc_slot is

component dc_row is
port(
  clk              : in  std_logic;
  reset_n          : in  std_logic;
  dc_init          : in  std_logic;
  dc_enable        : in  std_logic;
  dc_last          : in  std_logic;
  tree_reset       : in  std_logic;
  m_rd             : in  std_logic;
  m_valid          : out std_logic;
  m_data           : out std_logic_vector((DISTANCE_SIZE - 1 + 4) downto 0);
  data_valid_vec_i : in  std_logic_vector(15 downto 0);
  ram_bus_00       : in  std_logic_vector( 7 downto 0);
  ram_bus_01       : in  std_logic_vector( 7 downto 0);
  ram_bus_02       : in  std_logic_vector( 7 downto 0);
  ram_bus_03       : in  std_logic_vector( 7 downto 0);
  ram_bus_04       : in  std_logic_vector( 7 downto 0);
  ram_bus_05       : in  std_logic_vector( 7 downto 0);
  ram_bus_06       : in  std_logic_vector( 7 downto 0);
  ram_bus_07       : in  std_logic_vector( 7 downto 0);
  ram_bus_08       : in  std_logic_vector( 7 downto 0);
  ram_bus_09       : in  std_logic_vector( 7 downto 0);
  ram_bus_10       : in  std_logic_vector( 7 downto 0);
  ram_bus_11       : in  std_logic_vector( 7 downto 0);
  ram_bus_12       : in  std_logic_vector( 7 downto 0);
  ram_bus_13       : in  std_logic_vector( 7 downto 0);
  ram_bus_14       : in  std_logic_vector( 7 downto 0);
  ram_bus_15       : in  std_logic_vector( 7 downto 0);
  data_bus         : in  std_logic_vector( 7 downto 0)

);
end component;

component qv_buffer is
port(
  clk            : in  std_logic;
  reset_n        : in  std_logic;

  qv_wr_en       : in  std_logic;
  qv_wr_data     : in  std_logic_vector(31 downto 0);
  qv_first_data  : in  std_logic;
  qv_last_data   : in  std_logic;
  qv_status      : out std_logic;
  qv_id          : in  std_logic_vector(15 downto 0);
  qv_id_wr_en    : in  std_logic;

  calc_en        : in  std_logic;
  first_comp     : in  std_logic;
  last_comp      : in  std_logic;

  dc_init        : out std_logic;
  dc_enable      : out std_logic;
  dc_last        : out std_logic;

  data_bus       : out std_logic_vector( 7 downto 0);

  reset_vec_cntr : in  std_logic;
  fv_counter     : in  std_logic_vector(27 downto 0);
  qv_id_out      : out std_logic_vector(15 downto 0);
  fv_index_out   : out std_logic_vector(27 downto 0);
  last_vector    : out std_logic
);
end component;

component row_best_result is
port(
  clk              : in  std_logic;
  reset_n          : in  std_logic;
  tree_reset       : out std_logic;
  own_fpga_addr_i  : in  std_logic_vector( 2 downto 0);
  last_vector      : in  std_logic;
  threshold_i      : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  knn_num_i        : in  std_logic_vector( 6 downto 0);
  temperature_i    : in  std_logic_vector( 5 downto 0);
  a_rd_o           : out std_logic;
  a_valid_i        : in  std_logic;
  a_data_i         : in  std_logic_vector((DISTANCE_SIZE - 1 + 4) downto 0);
  fv_index         : in  std_logic_vector(27 downto 0);
  qv_id            : in  std_logic_vector(15 downto 0);
  fifo_z_rd_en     : in  std_logic;
  fifo_z_dout      : out std_logic_vector(127 downto 0);
  fifo_z_empty     : out std_logic;
  pause            : out std_logic
);
end component;

signal tree_reset   : std_logic;
signal m_rd         : std_logic;
signal m_valid      : std_logic;
signal m_data       : std_logic_vector((DISTANCE_SIZE - 1 + 4) downto 0);
signal dc_init      : std_logic;
signal dc_enable    : std_logic;
signal dc_last      : std_logic;
signal data_bus     : std_logic_vector( 7 downto 0);

signal qv_id_out    : std_logic_vector(15 downto 0);
signal fv_index_out : std_logic_vector(27 downto 0);
signal last_vector  : std_logic;

begin

dc_row_0 : dc_row
port map(
  clk              => clk,
  reset_n          => reset_n,
  dc_init          => dc_init,
  dc_enable        => dc_enable,
  dc_last          => dc_last,
  tree_reset       => tree_reset,
  m_rd             => m_rd,
  m_valid          => m_valid,
  m_data           => m_data,
  data_valid_vec_i => data_valid_vec_i,
  ram_bus_00       => ram_bus_00,
  ram_bus_01       => ram_bus_01,
  ram_bus_02       => ram_bus_02,
  ram_bus_03       => ram_bus_03,
  ram_bus_04       => ram_bus_04,
  ram_bus_05       => ram_bus_05,
  ram_bus_06       => ram_bus_06,
  ram_bus_07       => ram_bus_07,
  ram_bus_08       => ram_bus_08,
  ram_bus_09       => ram_bus_09,
  ram_bus_10       => ram_bus_10,
  ram_bus_11       => ram_bus_11,
  ram_bus_12       => ram_bus_12,
  ram_bus_13       => ram_bus_13,
  ram_bus_14       => ram_bus_14,
  ram_bus_15       => ram_bus_15,
  data_bus         => data_bus
);

qv_buffer_0 : qv_buffer
port map(
  clk            => clk,
  reset_n        => reset_n,
  qv_wr_en       => qv_wr_en,
  qv_wr_data     => qv_wr_data,
  qv_first_data  => qv_first_data,
  qv_last_data   => qv_last_data,
  qv_status      => qv_status,
  qv_id          => qv_id,
  qv_id_wr_en    => qv_id_wr_en,
  calc_en        => calc_en,
  first_comp     => first_comp,
  last_comp      => last_comp,
  dc_init        => dc_init,
  dc_enable      => dc_enable,
  dc_last        => dc_last,
  data_bus       => data_bus,
  reset_vec_cntr => reset_vec_cntr,
  fv_counter     => fv_counter,
  qv_id_out      => qv_id_out,
  fv_index_out   => fv_index_out,
  last_vector    => last_vector
);

row_best_result_0 : row_best_result
port map(
  clk              => clk,
  reset_n          => reset_n,
  tree_reset       => tree_reset,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  last_vector      => last_vector,
  a_rd_o           => m_rd   ,
  a_valid_i        => m_valid,
  a_data_i         => m_data ,
  fv_index         => fv_index_out,
  qv_id            => qv_id_out,
  fifo_z_rd_en     => fifo_z_rd_en,
  fifo_z_dout      => fifo_z_dout,
  fifo_z_empty     => fifo_z_empty,
  pause            => pause
);

end rtl;
