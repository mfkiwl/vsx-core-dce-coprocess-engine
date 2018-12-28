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

------------------------------------------------------------------------
-- Contains query vector mux, 10 dc slots and results capture modules --
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.dc_slot_def.all;

entity dc_slots_array is
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
end dc_slots_array;

architecture rtl of dc_slots_array is

component results_capture is
port(
   clk                 : in  std_logic;
   reset_n             : in  std_logic;
   fifo_z_00_rd_en     : out std_logic;
   fifo_z_00_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_00_empty     : in  std_logic;
   fifo_z_01_rd_en     : out std_logic;
   fifo_z_01_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_01_empty     : in  std_logic;
   fifo_z_02_rd_en     : out std_logic;
   fifo_z_02_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_02_empty     : in  std_logic;
   fifo_z_03_rd_en     : out std_logic;
   fifo_z_03_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_03_empty     : in  std_logic;
   fifo_z_04_rd_en     : out std_logic;
   fifo_z_04_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_04_empty     : in  std_logic;
   fifo_z_05_rd_en     : out std_logic;
   fifo_z_05_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_05_empty     : in  std_logic;
   fifo_z_06_rd_en     : out std_logic;
   fifo_z_06_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_06_empty     : in  std_logic;
   fifo_z_07_rd_en     : out std_logic;
   fifo_z_07_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_07_empty     : in  std_logic;
   fifo_z_08_rd_en     : out std_logic;
   fifo_z_08_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_08_empty     : in  std_logic;
   fifo_z_09_rd_en     : out std_logic;
   fifo_z_09_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_09_empty     : in  std_logic;
   result_valid_o      : out std_logic;
   result_data_o       : out std_logic_vector(127 downto 0);
   result_rd_i         : in  std_logic
);
end component;

component dc_slot is
port(
  clk                 : in  std_logic;
  reset_n             : in  std_logic;
  own_fpga_addr_i     : in  std_logic_vector( 2 downto 0);
  threshold_i         : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  knn_num_i           : in  std_logic_vector( 6 downto 0);
  temperature_i       : in  std_logic_vector( 5 downto 0);
  fifo_z_rd_en        : in  std_logic;
  fifo_z_dout         : out std_logic_vector(127 downto 0);
  fifo_z_empty        : out std_logic;
  qv_wr_en            : in  std_logic;
  qv_wr_data          : in  std_logic_vector(31 downto 0);
  qv_first_data       : in  std_logic;
  qv_last_data        : in  std_logic;
  qv_status           : out std_logic;
  qv_id               : in  std_logic_vector(15 downto 0);
  qv_id_wr_en         : in  std_logic;
  calc_en             : in  std_logic;
  data_valid_vec_i    : in  std_logic_vector(15 downto 0);
  first_comp          : in  std_logic;
  last_comp           : in  std_logic;
  pause               : out std_logic;
  reset_vec_cntr      : in  std_logic;
  fv_counter          : in  std_logic_vector(27 downto 0);
  ram_bus_00          : in  std_logic_vector(7 downto 0);
  ram_bus_01          : in  std_logic_vector(7 downto 0);
  ram_bus_02          : in  std_logic_vector(7 downto 0);
  ram_bus_03          : in  std_logic_vector(7 downto 0);
  ram_bus_04          : in  std_logic_vector(7 downto 0);
  ram_bus_05          : in  std_logic_vector(7 downto 0);
  ram_bus_06          : in  std_logic_vector(7 downto 0);
  ram_bus_07          : in  std_logic_vector(7 downto 0);
  ram_bus_08          : in  std_logic_vector(7 downto 0);
  ram_bus_09          : in  std_logic_vector(7 downto 0);
  ram_bus_10          : in  std_logic_vector(7 downto 0);
  ram_bus_11          : in  std_logic_vector(7 downto 0);
  ram_bus_12          : in  std_logic_vector(7 downto 0);
  ram_bus_13          : in  std_logic_vector(7 downto 0);
  ram_bus_14          : in  std_logic_vector(7 downto 0);
  ram_bus_15          : in  std_logic_vector(7 downto 0)
);
end component;

component qv_mux
port(
  clk                 : in  std_logic;
  reset_n             : in  std_logic;

  wr_en_i             : in  std_logic;
  id_wr_en_i          : in  std_logic;
  first_data_i        : in  std_logic;
  last_data_i         : in  std_logic;
  full_o              : out std_logic;
  qv_valid_o          : out std_logic;

  wr_en_00_o          : out std_logic;
  wr_en_01_o          : out std_logic;
  wr_en_02_o          : out std_logic;
  wr_en_03_o          : out std_logic;
  wr_en_04_o          : out std_logic;
  wr_en_05_o          : out std_logic;
  wr_en_06_o          : out std_logic;
  wr_en_07_o          : out std_logic;
  wr_en_08_o          : out std_logic;
  wr_en_09_o          : out std_logic;

  id_wr_en_00_o       : out std_logic;
  id_wr_en_01_o       : out std_logic;
  id_wr_en_02_o       : out std_logic;
  id_wr_en_03_o       : out std_logic;
  id_wr_en_04_o       : out std_logic;
  id_wr_en_05_o       : out std_logic;
  id_wr_en_06_o       : out std_logic;
  id_wr_en_07_o       : out std_logic;
  id_wr_en_08_o       : out std_logic;
  id_wr_en_09_o       : out std_logic;

  status_00_i         : in  std_logic;
  status_01_i         : in  std_logic;
  status_02_i         : in  std_logic;
  status_03_i         : in  std_logic;
  status_04_i         : in  std_logic;
  status_05_i         : in  std_logic;
  status_06_i         : in  std_logic;
  status_07_i         : in  std_logic;
  status_08_i         : in  std_logic;
  status_09_i         : in  std_logic
);
end component;

signal fifo_z_00_rd_en     : std_logic;
signal fifo_z_01_rd_en     : std_logic;
signal fifo_z_02_rd_en     : std_logic;
signal fifo_z_03_rd_en     : std_logic;
signal fifo_z_04_rd_en     : std_logic;
signal fifo_z_05_rd_en     : std_logic;
signal fifo_z_06_rd_en     : std_logic;
signal fifo_z_07_rd_en     : std_logic;
signal fifo_z_08_rd_en     : std_logic;
signal fifo_z_09_rd_en     : std_logic;

signal fifo_z_00_dout      : std_logic_vector(127 downto 0);
signal fifo_z_01_dout      : std_logic_vector(127 downto 0);
signal fifo_z_02_dout      : std_logic_vector(127 downto 0);
signal fifo_z_03_dout      : std_logic_vector(127 downto 0);
signal fifo_z_04_dout      : std_logic_vector(127 downto 0);
signal fifo_z_05_dout      : std_logic_vector(127 downto 0);
signal fifo_z_06_dout      : std_logic_vector(127 downto 0);
signal fifo_z_07_dout      : std_logic_vector(127 downto 0);
signal fifo_z_08_dout      : std_logic_vector(127 downto 0);
signal fifo_z_09_dout      : std_logic_vector(127 downto 0);

signal fifo_z_00_empty     : std_logic;
signal fifo_z_01_empty     : std_logic;
signal fifo_z_02_empty     : std_logic;
signal fifo_z_03_empty     : std_logic;
signal fifo_z_04_empty     : std_logic;
signal fifo_z_05_empty     : std_logic;
signal fifo_z_06_empty     : std_logic;
signal fifo_z_07_empty     : std_logic;
signal fifo_z_08_empty     : std_logic;
signal fifo_z_09_empty     : std_logic;

signal pause_00            : std_logic;
signal pause_01            : std_logic;
signal pause_02            : std_logic;
signal pause_03            : std_logic;
signal pause_04            : std_logic;
signal pause_05            : std_logic;
signal pause_06            : std_logic;
signal pause_07            : std_logic;
signal pause_08            : std_logic;
signal pause_09            : std_logic;
signal pause_reg           : std_logic;

signal data_valid_vec      : std_logic_vector(15 downto 0);

signal qv_wr_en_00         : std_logic;
signal qv_wr_en_01         : std_logic;
signal qv_wr_en_02         : std_logic;
signal qv_wr_en_03         : std_logic;
signal qv_wr_en_04         : std_logic;
signal qv_wr_en_05         : std_logic;
signal qv_wr_en_06         : std_logic;
signal qv_wr_en_07         : std_logic;
signal qv_wr_en_08         : std_logic;
signal qv_wr_en_09         : std_logic;

signal qv_id_wr_en_00      : std_logic;
signal qv_id_wr_en_01      : std_logic;
signal qv_id_wr_en_02      : std_logic;
signal qv_id_wr_en_03      : std_logic;
signal qv_id_wr_en_04      : std_logic;
signal qv_id_wr_en_05      : std_logic;
signal qv_id_wr_en_06      : std_logic;
signal qv_id_wr_en_07      : std_logic;
signal qv_id_wr_en_08      : std_logic;
signal qv_id_wr_en_09      : std_logic;

signal qv_status_00        : std_logic;
signal qv_status_01        : std_logic;
signal qv_status_02        : std_logic;
signal qv_status_03        : std_logic;
signal qv_status_04        : std_logic;
signal qv_status_05        : std_logic;
signal qv_status_06        : std_logic;
signal qv_status_07        : std_logic;
signal qv_status_08        : std_logic;
signal qv_status_09        : std_logic;

begin

pause          <= pause_reg;
data_valid_vec <= data_valid_vec_i;

-- Forming pause output
process(clk, reset_n)
begin
    if(reset_n = '0') then
        pause_reg <= '0';
    elsif(clk = '1' and clk'event) then
        pause_reg <= pause_00 or pause_01 or pause_02 or pause_03 or pause_04 or pause_05 or pause_06 or pause_07 or
                     pause_08 or pause_09;
    end if;
end process;

qv_mux_0 : qv_mux
port map(
  clk              => clk,
  reset_n          => reset_n,
  wr_en_i          => qv_wr_en_i,
  id_wr_en_i       => qv_id_wr_en,
  first_data_i     => qv_first_data,
  last_data_i      => qv_last_data,
  full_o           => qv_status_o,
  qv_valid_o       => qv_valid_o,
  wr_en_00_o       => qv_wr_en_00,
  wr_en_01_o       => qv_wr_en_01,
  wr_en_02_o       => qv_wr_en_02,
  wr_en_03_o       => qv_wr_en_03,
  wr_en_04_o       => qv_wr_en_04,
  wr_en_05_o       => qv_wr_en_05,
  wr_en_06_o       => qv_wr_en_06,
  wr_en_07_o       => qv_wr_en_07,
  wr_en_08_o       => qv_wr_en_08,
  wr_en_09_o       => qv_wr_en_09,
  id_wr_en_00_o    => qv_id_wr_en_00,
  id_wr_en_01_o    => qv_id_wr_en_01,
  id_wr_en_02_o    => qv_id_wr_en_02,
  id_wr_en_03_o    => qv_id_wr_en_03,
  id_wr_en_04_o    => qv_id_wr_en_04,
  id_wr_en_05_o    => qv_id_wr_en_05,
  id_wr_en_06_o    => qv_id_wr_en_06,
  id_wr_en_07_o    => qv_id_wr_en_07,
  id_wr_en_08_o    => qv_id_wr_en_08,
  id_wr_en_09_o    => qv_id_wr_en_09,
  status_00_i      => qv_status_00,
  status_01_i      => qv_status_01,
  status_02_i      => qv_status_02,
  status_03_i      => qv_status_03,
  status_04_i      => qv_status_04,
  status_05_i      => qv_status_05,
  status_06_i      => qv_status_06,
  status_07_i      => qv_status_07,
  status_08_i      => qv_status_08,
  status_09_i      => qv_status_09
);

dc_slot_00 : dc_slot
port map(
  clk              => clk,
  reset_n          => reset_n,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  fifo_z_rd_en     => fifo_z_00_rd_en,
  fifo_z_dout      => fifo_z_00_dout,
  fifo_z_empty     => fifo_z_00_empty,
  qv_wr_en         => qv_wr_en_00,
  qv_wr_data       => qv_wr_data,
  qv_first_data    => qv_first_data,
  qv_last_data     => qv_last_data,
  qv_status        => qv_status_00,
  qv_id            => qv_id,
  qv_id_wr_en      => qv_id_wr_en_00,
  calc_en          => calc_en,
  data_valid_vec_i => data_valid_vec,
  first_comp       => first_comp,
  last_comp        => last_comp,
  pause            => pause_00,
  reset_vec_cntr   => reset_vec_cntr,
  fv_counter       => fv_counter,
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
  ram_bus_15       => ram_bus_15
);

dc_slot_01 : dc_slot
port map(
  clk              => clk,
  reset_n          => reset_n,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  fifo_z_rd_en     => fifo_z_01_rd_en,
  fifo_z_dout      => fifo_z_01_dout,
  fifo_z_empty     => fifo_z_01_empty,
  qv_wr_en         => qv_wr_en_01,
  qv_wr_data       => qv_wr_data,
  qv_first_data    => qv_first_data,
  qv_last_data     => qv_last_data,
  qv_status        => qv_status_01,
  qv_id            => qv_id,
  qv_id_wr_en      => qv_id_wr_en_01,
  calc_en          => calc_en,
  data_valid_vec_i => data_valid_vec,
  first_comp       => first_comp,
  last_comp        => last_comp,
  pause            => pause_01,
  reset_vec_cntr   => reset_vec_cntr,
  fv_counter       => fv_counter,
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
  ram_bus_15       => ram_bus_15
);

dc_slot_02 : dc_slot
port map(
  clk              => clk,
  reset_n          => reset_n,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  fifo_z_rd_en     => fifo_z_02_rd_en,
  fifo_z_dout      => fifo_z_02_dout,
  fifo_z_empty     => fifo_z_02_empty,
  qv_wr_en         => qv_wr_en_02,
  qv_wr_data       => qv_wr_data,
  qv_first_data    => qv_first_data,
  qv_last_data     => qv_last_data,
  qv_status        => qv_status_02,
  qv_id            => qv_id,
  qv_id_wr_en      => qv_id_wr_en_02,
  calc_en          => calc_en,
  data_valid_vec_i => data_valid_vec,
  first_comp       => first_comp,
  last_comp        => last_comp,
  pause            => pause_02,
  reset_vec_cntr   => reset_vec_cntr,
  fv_counter       => fv_counter,
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
  ram_bus_15       => ram_bus_15
);

dc_slot_03 : dc_slot
port map(
  clk              => clk,
  reset_n          => reset_n,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  fifo_z_rd_en     => fifo_z_03_rd_en,
  fifo_z_dout      => fifo_z_03_dout,
  fifo_z_empty     => fifo_z_03_empty,
  qv_wr_en         => qv_wr_en_03,
  qv_wr_data       => qv_wr_data,
  qv_first_data    => qv_first_data,
  qv_last_data     => qv_last_data,
  qv_status        => qv_status_03,
  qv_id            => qv_id,
  qv_id_wr_en      => qv_id_wr_en_03,
  calc_en          => calc_en,
  data_valid_vec_i => data_valid_vec,
  first_comp       => first_comp,
  last_comp        => last_comp,
  pause            => pause_03,
  reset_vec_cntr   => reset_vec_cntr,
  fv_counter       => fv_counter,
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
  ram_bus_15       => ram_bus_15
);

dc_slot_04 : dc_slot
port map(
  clk              => clk,
  reset_n          => reset_n,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  fifo_z_rd_en     => fifo_z_04_rd_en,
  fifo_z_dout      => fifo_z_04_dout,
  fifo_z_empty     => fifo_z_04_empty,
  qv_wr_en         => qv_wr_en_04,
  qv_wr_data       => qv_wr_data,
  qv_first_data    => qv_first_data,
  qv_last_data     => qv_last_data,
  qv_status        => qv_status_04,
  qv_id            => qv_id,
  qv_id_wr_en      => qv_id_wr_en_04,
  calc_en          => calc_en,
  data_valid_vec_i => data_valid_vec,
  first_comp       => first_comp,
  last_comp        => last_comp,
  pause            => pause_04,
  reset_vec_cntr   => reset_vec_cntr,
  fv_counter       => fv_counter,
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
  ram_bus_15       => ram_bus_15
);

dc_slot_05 : dc_slot
port map(
  clk              => clk,
  reset_n          => reset_n,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  fifo_z_rd_en     => fifo_z_05_rd_en,
  fifo_z_dout      => fifo_z_05_dout,
  fifo_z_empty     => fifo_z_05_empty,
  qv_wr_en         => qv_wr_en_05,
  qv_wr_data       => qv_wr_data,
  qv_first_data    => qv_first_data,
  qv_last_data     => qv_last_data,
  qv_status        => qv_status_05,
  qv_id            => qv_id,
  qv_id_wr_en      => qv_id_wr_en_05,
  calc_en          => calc_en,
  data_valid_vec_i => data_valid_vec,
  first_comp       => first_comp,
  last_comp        => last_comp,
  pause            => pause_05,
  reset_vec_cntr   => reset_vec_cntr,
  fv_counter       => fv_counter,
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
  ram_bus_15       => ram_bus_15
);

dc_slot_06 : dc_slot
port map(
  clk              => clk,
  reset_n          => reset_n,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  fifo_z_rd_en     => fifo_z_06_rd_en,
  fifo_z_dout      => fifo_z_06_dout,
  fifo_z_empty     => fifo_z_06_empty,
  qv_wr_en         => qv_wr_en_06,
  qv_wr_data       => qv_wr_data,
  qv_first_data    => qv_first_data,
  qv_last_data     => qv_last_data,
  qv_status        => qv_status_06,
  qv_id            => qv_id,
  qv_id_wr_en      => qv_id_wr_en_06,
  calc_en          => calc_en,
  data_valid_vec_i => data_valid_vec,
  first_comp       => first_comp,
  last_comp        => last_comp,
  pause            => pause_06,
  reset_vec_cntr   => reset_vec_cntr,
  fv_counter       => fv_counter,
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
  ram_bus_15       => ram_bus_15
);

dc_slot_07 : dc_slot
port map(
  clk              => clk,
  reset_n          => reset_n,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  fifo_z_rd_en     => fifo_z_07_rd_en,
  fifo_z_dout      => fifo_z_07_dout,
  fifo_z_empty     => fifo_z_07_empty,
  qv_wr_en         => qv_wr_en_07,
  qv_wr_data       => qv_wr_data,
  qv_first_data    => qv_first_data,
  qv_last_data     => qv_last_data,
  qv_status        => qv_status_07,
  qv_id            => qv_id,
  qv_id_wr_en      => qv_id_wr_en_07,
  calc_en          => calc_en,
  data_valid_vec_i => data_valid_vec,
  first_comp       => first_comp,
  last_comp        => last_comp,
  pause            => pause_07,
  reset_vec_cntr   => reset_vec_cntr,
  fv_counter       => fv_counter,
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
  ram_bus_15       => ram_bus_15
);

dc_slot_08 : dc_slot
port map(
  clk              => clk,
  reset_n          => reset_n,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  fifo_z_rd_en     => fifo_z_08_rd_en,
  fifo_z_dout      => fifo_z_08_dout,
  fifo_z_empty     => fifo_z_08_empty,
  qv_wr_en         => qv_wr_en_08,
  qv_wr_data       => qv_wr_data,
  qv_first_data    => qv_first_data,
  qv_last_data     => qv_last_data,
  qv_status        => qv_status_08,
  qv_id            => qv_id,
  qv_id_wr_en      => qv_id_wr_en_08,
  calc_en          => calc_en,
  data_valid_vec_i => data_valid_vec,
  first_comp       => first_comp,
  last_comp        => last_comp,
  pause            => pause_08,
  reset_vec_cntr   => reset_vec_cntr,
  fv_counter       => fv_counter,
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
  ram_bus_15       => ram_bus_15
);

dc_slot_09 : dc_slot
port map(
  clk              => clk,
  reset_n          => reset_n,
  own_fpga_addr_i  => own_fpga_addr_i,
  threshold_i      => threshold_i,
  knn_num_i        => knn_num_i,
  temperature_i    => temperature_i,
  fifo_z_rd_en     => fifo_z_09_rd_en,
  fifo_z_dout      => fifo_z_09_dout,
  fifo_z_empty     => fifo_z_09_empty,
  qv_wr_en         => qv_wr_en_09,
  qv_wr_data       => qv_wr_data,
  qv_first_data    => qv_first_data,
  qv_last_data     => qv_last_data,
  qv_status        => qv_status_09,
  qv_id            => qv_id,
  qv_id_wr_en      => qv_id_wr_en_09,
  calc_en          => calc_en,
  data_valid_vec_i => data_valid_vec,
  first_comp       => first_comp,
  last_comp        => last_comp,
  pause            => pause_09,
  reset_vec_cntr   => reset_vec_cntr,
  fv_counter       => fv_counter,
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
  ram_bus_15       => ram_bus_15
);

results_capture_0 : results_capture
port map (
   clk                 => clk,
   reset_n             => reset_n,

   fifo_z_00_rd_en     => fifo_z_00_rd_en,
   fifo_z_00_dout      => fifo_z_00_dout,
   fifo_z_00_empty     => fifo_z_00_empty,

   fifo_z_01_rd_en     => fifo_z_01_rd_en,
   fifo_z_01_dout      => fifo_z_01_dout,
   fifo_z_01_empty     => fifo_z_01_empty,

   fifo_z_02_rd_en     => fifo_z_02_rd_en,
   fifo_z_02_dout      => fifo_z_02_dout,
   fifo_z_02_empty     => fifo_z_02_empty,

   fifo_z_03_rd_en     => fifo_z_03_rd_en,
   fifo_z_03_dout      => fifo_z_03_dout,
   fifo_z_03_empty     => fifo_z_03_empty,

   fifo_z_04_rd_en     => fifo_z_04_rd_en,
   fifo_z_04_dout      => fifo_z_04_dout,
   fifo_z_04_empty     => fifo_z_04_empty,

   fifo_z_05_rd_en     => fifo_z_05_rd_en,
   fifo_z_05_dout      => fifo_z_05_dout,
   fifo_z_05_empty     => fifo_z_05_empty,

   fifo_z_06_rd_en     => fifo_z_06_rd_en,
   fifo_z_06_dout      => fifo_z_06_dout,
   fifo_z_06_empty     => fifo_z_06_empty,

   fifo_z_07_rd_en     => fifo_z_07_rd_en,
   fifo_z_07_dout      => fifo_z_07_dout,
   fifo_z_07_empty     => fifo_z_07_empty,

   fifo_z_08_rd_en     => fifo_z_08_rd_en,
   fifo_z_08_dout      => fifo_z_08_dout,
   fifo_z_08_empty     => fifo_z_08_empty,

   fifo_z_09_rd_en     => fifo_z_09_rd_en,
   fifo_z_09_dout      => fifo_z_09_dout,
   fifo_z_09_empty     => fifo_z_09_empty,

   result_valid_o      => result_valid_o,
   result_data_o       => result_data_o,
   result_rd_i         => result_rd_i
);

end rtl;
