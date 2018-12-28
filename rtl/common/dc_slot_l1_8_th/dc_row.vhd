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

------------------------------------------------------
-- Includes 16 parallel connected Hamming distance  --
-- calculation engines and 16 results sorting tree. --
------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.dc_slot_def.all;

entity dc_row is
port(
    clk              :  in  std_logic;
    reset_n          :  in  std_logic;
    dc_init          :  in  std_logic;
    dc_enable        :  in  std_logic;
    dc_last          :  in  std_logic;
    tree_reset       :  in  std_logic;
    m_rd             :  in  std_logic;
    m_valid          :  out std_logic;
    m_data           :  out std_logic_vector((DISTANCE_SIZE - 1 + 4) downto 0);
    data_valid_vec_i :  in  std_logic_vector(15 downto 0);
    ram_bus_00       :  in  std_logic_vector( 7 downto 0);
    ram_bus_01       :  in  std_logic_vector( 7 downto 0);
    ram_bus_02       :  in  std_logic_vector( 7 downto 0);
    ram_bus_03       :  in  std_logic_vector( 7 downto 0);
    ram_bus_04       :  in  std_logic_vector( 7 downto 0);
    ram_bus_05       :  in  std_logic_vector( 7 downto 0);
    ram_bus_06       :  in  std_logic_vector( 7 downto 0);
    ram_bus_07       :  in  std_logic_vector( 7 downto 0);
    ram_bus_08       :  in  std_logic_vector( 7 downto 0);
    ram_bus_09       :  in  std_logic_vector( 7 downto 0);
    ram_bus_10       :  in  std_logic_vector( 7 downto 0);
    ram_bus_11       :  in  std_logic_vector( 7 downto 0);
    ram_bus_12       :  in  std_logic_vector( 7 downto 0);
    ram_bus_13       :  in  std_logic_vector( 7 downto 0);
    ram_bus_14       :  in  std_logic_vector( 7 downto 0);
    ram_bus_15       :  in  std_logic_vector( 7 downto 0);
    data_bus         :  in  std_logic_vector( 7 downto 0)
);
end dc_row;

architecture rtl of dc_row is

component l1_8b_dce is
port(
  clk          : in  std_logic;
  reset_n      : in  std_logic;
  init_i       : in  std_logic;
  enable_i     : in  std_logic;
  last_i       : in  std_logic;
  data_i       : in  std_logic_vector( 7 downto 0);
  ram_i        : in  std_logic_vector( 7 downto 0);
  m_rd_i       : in  std_logic;
  m_valid_o    : out std_logic;
  m_data_o     : out std_logic_vector((DISTANCE_SIZE - 1) downto 0)
);
end component;

component row_tree_16 is
port(
  clk          : in  std_logic;
  reset_n      : in  std_logic;
  tree_reset_i : in  std_logic;
  m_rd_i       : in  std_logic;
  m_valid_o    : out std_logic;
  m_data_o     : out std_logic_vector((DISTANCE_SIZE - 1 + 4) downto 0);
  rd_00_o      : out std_logic;
  rd_01_o      : out std_logic;
  rd_02_o      : out std_logic;
  rd_03_o      : out std_logic;
  rd_04_o      : out std_logic;
  rd_05_o      : out std_logic;
  rd_06_o      : out std_logic;
  rd_07_o      : out std_logic;
  rd_08_o      : out std_logic;
  rd_09_o      : out std_logic;
  rd_10_o      : out std_logic;
  rd_11_o      : out std_logic;
  rd_12_o      : out std_logic;
  rd_13_o      : out std_logic;
  rd_14_o      : out std_logic;
  rd_15_o      : out std_logic;
  valid_00_i   : in  std_logic;
  valid_01_i   : in  std_logic;
  valid_02_i   : in  std_logic;
  valid_03_i   : in  std_logic;
  valid_04_i   : in  std_logic;
  valid_05_i   : in  std_logic;
  valid_06_i   : in  std_logic;
  valid_07_i   : in  std_logic;
  valid_08_i   : in  std_logic;
  valid_09_i   : in  std_logic;
  valid_10_i   : in  std_logic;
  valid_11_i   : in  std_logic;
  valid_12_i   : in  std_logic;
  valid_13_i   : in  std_logic;
  valid_14_i   : in  std_logic;
  valid_15_i   : in  std_logic;
  data_00_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_01_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_02_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_03_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_04_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_05_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_06_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_07_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_08_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_09_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_10_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_11_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_12_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_13_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_14_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  data_15_i    : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0)
);
end component;

signal dc_last_00      : std_logic;
signal dc_last_01      : std_logic;
signal dc_last_02      : std_logic;
signal dc_last_03      : std_logic;
signal dc_last_04      : std_logic;
signal dc_last_05      : std_logic;
signal dc_last_06      : std_logic;
signal dc_last_07      : std_logic;
signal dc_last_08      : std_logic;
signal dc_last_09      : std_logic;
signal dc_last_10      : std_logic;
signal dc_last_11      : std_logic;
signal dc_last_12      : std_logic;
signal dc_last_13      : std_logic;
signal dc_last_14      : std_logic;
signal dc_last_15      : std_logic;

signal rd_00           : std_logic;
signal rd_01           : std_logic;
signal rd_02           : std_logic;
signal rd_03           : std_logic;
signal rd_04           : std_logic;
signal rd_05           : std_logic;
signal rd_06           : std_logic;
signal rd_07           : std_logic;
signal rd_08           : std_logic;
signal rd_09           : std_logic;
signal rd_10           : std_logic;
signal rd_11           : std_logic;
signal rd_12           : std_logic;
signal rd_13           : std_logic;
signal rd_14           : std_logic;
signal rd_15           : std_logic;
signal valid_00        : std_logic;
signal valid_01        : std_logic;
signal valid_02        : std_logic;
signal valid_03        : std_logic;
signal valid_04        : std_logic;
signal valid_05        : std_logic;
signal valid_06        : std_logic;
signal valid_07        : std_logic;
signal valid_08        : std_logic;
signal valid_09        : std_logic;
signal valid_10        : std_logic;
signal valid_11        : std_logic;
signal valid_12        : std_logic;
signal valid_13        : std_logic;
signal valid_14        : std_logic;
signal valid_15        : std_logic;
signal result_00       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_01       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_02       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_03       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_04       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_05       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_06       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_07       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_08       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_09       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_10       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_11       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_12       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_13       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_14       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result_15       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);

begin

  dc_last_00 <= data_valid_vec_i( 0) and dc_last;
  dc_last_01 <= data_valid_vec_i( 1) and dc_last;
  dc_last_02 <= data_valid_vec_i( 2) and dc_last;
  dc_last_03 <= data_valid_vec_i( 3) and dc_last;
  dc_last_04 <= data_valid_vec_i( 4) and dc_last;
  dc_last_05 <= data_valid_vec_i( 5) and dc_last;
  dc_last_06 <= data_valid_vec_i( 6) and dc_last;
  dc_last_07 <= data_valid_vec_i( 7) and dc_last;
  dc_last_08 <= data_valid_vec_i( 8) and dc_last;
  dc_last_09 <= data_valid_vec_i( 9) and dc_last;
  dc_last_10 <= data_valid_vec_i(10) and dc_last;
  dc_last_11 <= data_valid_vec_i(11) and dc_last;
  dc_last_12 <= data_valid_vec_i(12) and dc_last;
  dc_last_13 <= data_valid_vec_i(13) and dc_last;
  dc_last_14 <= data_valid_vec_i(14) and dc_last;
  dc_last_15 <= data_valid_vec_i(15) and dc_last;

l1_8b_dce_00 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_00,
    data_i       => data_bus,
    ram_i        => ram_bus_00,
    m_rd_i       => rd_00,
    m_valid_o    => valid_00,
    m_data_o     => result_00
);

l1_8b_dce_01 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_01,
    data_i       => data_bus,
    ram_i        => ram_bus_01,
    m_rd_i       => rd_01,
    m_valid_o    => valid_01,
    m_data_o     => result_01
);

l1_8b_dce_02 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_02,
    data_i       => data_bus,
    ram_i        => ram_bus_02,
    m_rd_i       => rd_02,
    m_valid_o    => valid_02,
    m_data_o     => result_02
);

l1_8b_dce_03 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_03,
    data_i       => data_bus,
    ram_i        => ram_bus_03,
    m_rd_i       => rd_03,
    m_valid_o    => valid_03,
    m_data_o     => result_03
);

l1_8b_dce_04 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_04,
    data_i       => data_bus,
    ram_i        => ram_bus_04,
    m_rd_i       => rd_04,
    m_valid_o    => valid_04,
    m_data_o     => result_04
);

l1_8b_dce_05 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_05,
    data_i       => data_bus,
    ram_i        => ram_bus_05,
    m_rd_i       => rd_05,
    m_valid_o    => valid_05,
    m_data_o     => result_05
);

l1_8b_dce_06 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_06,
    data_i       => data_bus,
    ram_i        => ram_bus_06,
    m_rd_i       => rd_06,
    m_valid_o    => valid_06,
    m_data_o     => result_06
);

l1_8b_dce_07 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_07,
    data_i       => data_bus,
    ram_i        => ram_bus_07,
    m_rd_i       => rd_07,
    m_valid_o    => valid_07,
    m_data_o     => result_07
);

l1_8b_dce_08 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_08,
    data_i       => data_bus,
    ram_i        => ram_bus_08,
    m_rd_i       => rd_08,
    m_valid_o    => valid_08,
    m_data_o     => result_08
);

l1_8b_dce_09 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_09,
    data_i       => data_bus,
    ram_i        => ram_bus_09,
    m_rd_i       => rd_09,
    m_valid_o    => valid_09,
    m_data_o     => result_09
);

l1_8b_dce_10 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_10,
    data_i       => data_bus,
    ram_i        => ram_bus_10,
    m_rd_i       => rd_10,
    m_valid_o    => valid_10,
    m_data_o     => result_10
);

l1_8b_dce_11 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_11,
    data_i       => data_bus,
    ram_i        => ram_bus_11,
    m_rd_i       => rd_11,
    m_valid_o    => valid_11,
    m_data_o     => result_11
);

l1_8b_dce_12 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_12,
    data_i       => data_bus,
    ram_i        => ram_bus_12,
    m_rd_i       => rd_12,
    m_valid_o    => valid_12,
    m_data_o     => result_12
);

l1_8b_dce_13 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_13,
    data_i       => data_bus,
    ram_i        => ram_bus_13,
    m_rd_i       => rd_13,
    m_valid_o    => valid_13,
    m_data_o     => result_13
);

l1_8b_dce_14 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_14,
    data_i       => data_bus,
    ram_i        => ram_bus_14,
    m_rd_i       => rd_14,
    m_valid_o    => valid_14,
    m_data_o     => result_14
);

l1_8b_dce_15 : l1_8b_dce
  port map(
    clk          => clk,
    reset_n      => reset_n,
    init_i       => dc_init,
    enable_i     => dc_enable,
    last_i       => dc_last_15,
    data_i       => data_bus,
    ram_i        => ram_bus_15,
    m_rd_i       => rd_15,
    m_valid_o    => valid_15,
    m_data_o     => result_15
);

row_tree_16_0 : row_tree_16
  port map (
  clk          => clk,
  reset_n      => reset_n,
  tree_reset_i => tree_reset,
  m_rd_i       => m_rd,
  m_valid_o    => m_valid,
  m_data_o     => m_data,
  rd_00_o      => rd_00,
  rd_01_o      => rd_01,
  rd_02_o      => rd_02,
  rd_03_o      => rd_03,
  rd_04_o      => rd_04,
  rd_05_o      => rd_05,
  rd_06_o      => rd_06,
  rd_07_o      => rd_07,
  rd_08_o      => rd_08,
  rd_09_o      => rd_09,
  rd_10_o      => rd_10,
  rd_11_o      => rd_11,
  rd_12_o      => rd_12,
  rd_13_o      => rd_13,
  rd_14_o      => rd_14,
  rd_15_o      => rd_15,
  valid_00_i   => valid_00,
  valid_01_i   => valid_01,
  valid_02_i   => valid_02,
  valid_03_i   => valid_03,
  valid_04_i   => valid_04,
  valid_05_i   => valid_05,
  valid_06_i   => valid_06,
  valid_07_i   => valid_07,
  valid_08_i   => valid_08,
  valid_09_i   => valid_09,
  valid_10_i   => valid_10,
  valid_11_i   => valid_11,
  valid_12_i   => valid_12,
  valid_13_i   => valid_13,
  valid_14_i   => valid_14,
  valid_15_i   => valid_15,
  data_00_i    => result_00,
  data_01_i    => result_01,
  data_02_i    => result_02,
  data_03_i    => result_03,
  data_04_i    => result_04,
  data_05_i    => result_05,
  data_06_i    => result_06,
  data_07_i    => result_07,
  data_08_i    => result_08,
  data_09_i    => result_09,
  data_10_i    => result_10,
  data_11_i    => result_11,
  data_12_i    => result_12,
  data_13_i    => result_13,
  data_14_i    => result_14,
  data_15_i    => result_15
);

end rtl;
