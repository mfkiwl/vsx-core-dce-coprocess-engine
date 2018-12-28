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
-- Configuration registers definitions --
-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.dc_slot_def.all;
use work.version_def.all;

package cfg_registers_def is
  constant REG_IF_DATA_SIZE       : integer := 16;
  constant REG_IF_ADDRESS_SIZE    : integer := 16;

  constant RTL_VERSION_ADDR       : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0) := X"0000";
  constant THRESHOLD_LO_ADDR      : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0) := X"0001";
  constant THRESHOLD_HI_ADDR      : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0) := X"0002";
  constant DSV_COUNT_LO_ADDR      : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0) := X"0003";
  constant DSV_COUNT_HI_ADDR      : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0) := X"0004";
  constant DSV_LENGTH_ADDR        : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0) := X"0005";
  constant KNN_NUM_ADDR           : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0) := X"0006";
  constant STATUS_ADDR            : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0) := X"000C";
  constant DESIGN_DEF_1_ADDR      : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0) := X"000D";
  constant DESIGN_DEF_2_ADDR      : std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0) := X"000E";

  constant RTL_VERSION_SIZE       : integer := 16;
  constant THRESHOLD_LO_SIZE      : integer := 16;
  constant THRESHOLD_HI_SIZE      : integer := 16;
  constant DSV_COUNT_LO_SIZE      : integer := 16;
  constant DSV_COUNT_HI_SIZE      : integer := 16;
  constant DSV_LENGTH_SIZE        : integer := 12;
  constant KNN_NUM_SIZE           : integer :=  7;
  constant STATUS_SIZE            : integer := 16;
  constant DESIGN_DEF_1_SIZE      : integer := 16;
  constant DESIGN_DEF_2_SIZE      : integer := 16;

  constant RTL_VERSION_WP         : std_logic := '1';
  constant THRESHOLD_LO_WP        : std_logic := '0';
  constant THRESHOLD_HI_WP        : std_logic := '0';
  constant DSV_COUNT_LO_WP        : std_logic := '0';
  constant DSV_COUNT_HI_WP        : std_logic := '0';
  constant DSV_LENGTH_WP          : std_logic := '0';
  constant KNN_NUM_WP             : std_logic := '0';
  constant STATUS_WP              : std_logic := '1';
  constant DESIGN_DEF_1_WP        : std_logic := '1';
  constant DESIGN_DEF_2_WP        : std_logic := '1';

  constant RTL_VERSION_DEF        : std_logic_vector((RTL_VERSION_SIZE  - 1) downto 0) := MAJOR_VERSION & MINOR_VERSION & REVISION;
  constant THRESHOLD_LO_DEF       : std_logic_vector((THRESHOLD_LO_SIZE - 1) downto 0) := (others => '0');
  constant THRESHOLD_HI_DEF       : std_logic_vector((THRESHOLD_HI_SIZE - 1) downto 0) := (others => '0');
  constant DSV_COUNT_LO_DEF       : std_logic_vector((DSV_COUNT_LO_SIZE - 1) downto 0) := (others => '0');
  constant DSV_COUNT_HI_DEF       : std_logic_vector((DSV_COUNT_HI_SIZE - 1) downto 0) := (others => '0');
  constant DSV_LENGTH_DEF         : std_logic_vector((DSV_LENGTH_SIZE   - 1) downto 0) := (others => '0');
  constant KNN_NUM_DEF            : std_logic_vector((KNN_NUM_SIZE      - 1) downto 0) := (others => '0');
  constant STATUS_DEF             : std_logic_vector((STATUS_SIZE       - 1) downto 0) := (others => '0');
  constant DESIGN_DEF_1_DEF       : std_logic_vector((DESIGN_DEF_1_SIZE - 1) downto 0) := DISTANCE_MODE & QUERY_MODE & "00000" & COMPONENT_SIZE;
  constant DESIGN_DEF_2_DEF       : std_logic_vector((DESIGN_DEF_2_SIZE - 1) downto 0) := NUM_OF_DC_SLOTS & DDR3_FREQ & DC_SLOTS_FREQ & PAR_BUS_FREQ;

end package cfg_registers_def;
