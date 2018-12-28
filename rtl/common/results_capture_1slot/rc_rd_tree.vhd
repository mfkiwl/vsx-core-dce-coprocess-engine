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

-----------------------------------------------------------------------
-- Reads results from 1 dc slot and forwards to result_response_node --
-- In 1 slot version directly connect lower port to upper port       --
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rc_rd_tree is
port (
   clk          : in  std_logic;
   reset_n      : in  std_logic;
   m_rd_i       : in  std_logic;
   m_valid_o    : out std_logic;
   m_data_o     : out std_logic_vector(127 downto 0);
   rd_00_o      : out std_logic;
   valid_00_i   : in  std_logic;
   data_00_i    : in  std_logic_vector(127 downto 0)
);
end rc_rd_tree;

architecture rtl of rc_rd_tree is

begin

rd_00_o   <= m_rd_i;
m_valid_o <= valid_00_i;
m_data_o  <= data_00_i;

end rtl;
