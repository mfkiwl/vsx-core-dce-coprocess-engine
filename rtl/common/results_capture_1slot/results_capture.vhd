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
-- Includes results tree and node to FIFO interface converting logic, --
-- to connect to dc slots results FIFO.                               --
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity results_capture is
port (
   clk                 : in  std_logic;
   reset_n             : in  std_logic;

   fifo_z_00_rd_en     : out std_logic;
   fifo_z_00_dout      : in  std_logic_vector(127 downto 0);
   fifo_z_00_empty     : in  std_logic;

   result_valid_o      : out std_logic;
   result_data_o       : out std_logic_vector(127 downto 0);
   result_rd_i         : in  std_logic

);
end results_capture;

architecture rtl of results_capture is

component rc_rd_tree
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
end component;

   signal results_rd_en          : std_logic;
   signal m_valid                : std_logic;

   signal valid_in_00            : std_logic;

   signal results_data_00        : std_logic_vector(127 downto 0);

   signal result_data_in         : std_logic_vector(127 downto 0);

begin

   result_valid_o  <= m_valid;
   result_data_o   <= result_data_in;
   results_rd_en   <= result_rd_i;

   valid_in_00     <= not fifo_z_00_empty;

   results_data_00 <= fifo_z_00_dout;

  rc_rd_tree_0 : rc_rd_tree
  port map(
     clk          => clk,
     reset_n      => reset_n,
     m_rd_i       => results_rd_en,
     m_valid_o    => m_valid,
     m_data_o     => result_data_in,
     rd_00_o      => fifo_z_00_rd_en,
     valid_00_i   => valid_in_00,
     data_00_i    => results_data_00
  );

end rtl;

