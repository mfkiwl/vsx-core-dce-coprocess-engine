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

-----------------------------
-- RTL version definitions --
-----------------------------

library ieee;
use ieee.std_logic_1164.all;

package version_def is

constant MAJOR_VERSION   : std_logic_vector(3 downto 0) :=  X"1";
constant MINOR_VERSION   : std_logic_vector(3 downto 0) :=  X"1";
constant REVISION        : std_logic_vector(7 downto 0) := X"12";

--constant NUM_OF_DC_SLOTS : std_logic_vector(5 downto 0) :=  "010000"; -- 16 Slot
--constant NUM_OF_DC_SLOTS : std_logic_vector(5 downto 0) :=  "001010"; -- 10 Slot
constant NUM_OF_DC_SLOTS : std_logic_vector(5 downto 0) :=  "000001"; --  1 Slot

constant DDR3_FREQ       : std_logic_vector(1 downto 0) :=  "00"; -- 300 MHz
                                                         -- "01"; -- 333 MHz
                                                         -- "10"; -- 400 MHz
                                                         -- "11"; -- Unused

--constant DC_SLOTS_FREQ   : std_logic_vector(3 downto 0) :=  "0101"; --  5 * 10MHz + 50MHz = 100 MHz
constant DC_SLOTS_FREQ   : std_logic_vector(3 downto 0) :=  "1010"; -- 10 * 10MHz + 50MHz = 150 MHz

constant PAR_BUS_FREQ    : std_logic_vector(3 downto 0) :=  "0000"; --  0 * 10MHz + 50MHz =  50 MHz

end package version_def;
