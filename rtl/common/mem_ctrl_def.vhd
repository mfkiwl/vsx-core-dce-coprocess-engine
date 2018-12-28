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

----------------------------------------------
-- Definitions for memory controller module --
----------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package mem_ctrl_def is

  constant MEM_CMD_READ          : std_logic_vector ( 3 downto 0) := "0001";
  constant MEM_CMD_WRITE         : std_logic_vector ( 3 downto 0) := "0010";
  constant MEM_CMD_READA         : std_logic_vector ( 3 downto 0) := "0011";
  constant MEM_CMD_WRITEA        : std_logic_vector ( 3 downto 0) := "0100";
  constant MEM_CMD_PDOWN_ENT     : std_logic_vector ( 3 downto 0) := "0101";
  constant MEM_CMD_LOAD_MR       : std_logic_vector ( 3 downto 0) := "0110";
  constant MEM_CMD_SEL_REF_ENT   : std_logic_vector ( 3 downto 0) := "1000";
  constant MEM_CMD_SEL_REF_EXIT  : std_logic_vector ( 3 downto 0) := "1001";
  constant MEM_CMD_PDOWN_EXIT    : std_logic_vector ( 3 downto 0) := "1011";
  constant MEM_CMD_ZQ_LNG        : std_logic_vector ( 3 downto 0) := "1100";
  constant MEM_CMD_ZQ_SHRT       : std_logic_vector ( 3 downto 0) := "1101";

  constant MEM_ADDRESS_SIZE      : integer := 29;
  constant MEM_RD_COUNT_SIZE     : integer :=  5;

  constant DS_COMPONENT_LENGTH   : integer := 8;

end package mem_ctrl_def;
