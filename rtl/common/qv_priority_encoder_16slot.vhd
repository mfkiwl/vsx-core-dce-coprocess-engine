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

-----------------------------------------
-- Finds lowest status with '0' value. --
-- Contains in QV_mux16slot module.    --
-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity qv_priority_encoder is
port(
  status_00_i : in  std_logic;
  status_01_i : in  std_logic;
  status_02_i : in  std_logic;
  status_03_i : in  std_logic;
  status_04_i : in  std_logic;
  status_05_i : in  std_logic;
  status_06_i : in  std_logic;
  status_07_i : in  std_logic;
  status_08_i : in  std_logic;
  status_09_i : in  std_logic;
  status_10_i : in  std_logic;
  status_11_i : in  std_logic;
  status_12_i : in  std_logic;
  status_13_i : in  std_logic;
  status_14_i : in  std_logic;
  status_15_i : in  std_logic;

  index_o     : out std_logic_vector(3 downto 0);
  status_o    : out std_logic

);
end qv_priority_encoder;

architecture rtl of qv_priority_encoder is

signal Y0_03_00 :std_logic_vector(1 downto 0);
signal Y0_07_04 :std_logic_vector(1 downto 0);
signal Y0_11_08 :std_logic_vector(1 downto 0);
signal Y0_15_12 :std_logic_vector(1 downto 0);
signal V0_03_00 :std_logic;
signal V0_07_04 :std_logic;
signal V0_11_08 :std_logic;
signal V0_15_12 :std_logic;

signal Y1_07_00 :std_logic_vector(2 downto 0);
signal Y1_15_08 :std_logic_vector(2 downto 0);
signal V1_07_00 :std_logic;
signal V1_15_08 :std_logic;

signal Y2_15_00 :std_logic_vector(3 downto 0);
signal V2_15_00 :std_logic;

begin

  Y0_03_00(0) <= ((not status_03_i) and status_02_i and status_00_i) or ((not status_01_i) and status_00_i);
  Y0_07_04(0) <= ((not status_07_i) and status_06_i and status_04_i) or ((not status_05_i) and status_04_i);
  Y0_03_00(1) <= status_01_i and status_00_i;
  Y0_07_04(1) <= status_05_i and status_04_i;

  V0_03_00 <= status_03_i and status_02_i and status_01_i and status_00_i;
  V0_07_04 <= status_07_i and status_06_i and status_05_i and status_04_i;

  Y0_11_08(0) <= ((not status_11_i) and status_10_i and status_08_i) or ((not status_09_i) and status_08_i);
  Y0_15_12(0) <= ((not status_15_i) and status_14_i and status_12_i) or ((not status_13_i) and status_12_i);
  Y0_11_08(1) <= status_09_i and status_08_i;
  Y0_15_12(1) <= status_13_i and status_12_i;

  V0_11_08 <= status_11_i and status_10_i and status_09_i and status_08_i;
  V0_15_12 <= status_15_i and status_14_i and status_13_i and status_12_i;

  Y1_07_00 <= ('0' & Y0_03_00) when (V0_03_00 = '0') else ('1' & Y0_07_04);
  V1_07_00 <= V0_07_04 and V0_03_00;

  Y1_15_08 <= ('0' & Y0_11_08) when (V0_11_08 = '0') else ('1' & Y0_15_12);
  V1_15_08 <= V0_15_12 and V0_11_08;

  Y2_15_00 <= ('0' & Y1_07_00) when (V1_07_00 = '0') else ('1' & Y1_15_08);
  V2_15_00 <= V1_07_00 and V1_15_08;

  index_o  <= Y2_15_00;
  status_o <= V2_15_00;

end rtl;
