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

---------------------------------------------------------------
-- Compares two inputs (distances) and indicates winner port --
---------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity tree_comparator_20 is
port (
   data1     : in  std_logic_vector(19 downto 0);
   valid1    : in  std_logic;
   data2     : in  std_logic_vector(19 downto 0);
   valid2    : in  std_logic;
   data_win  : out std_logic_vector(19 downto 0);
   b_winner  : out std_logic;
   win_valid : out std_logic
);
end tree_comparator_20;

architecture rtl of tree_comparator_20 is

  signal less21      : std_logic;
  signal b_winner_in : std_logic;

  component comparator_20
  port(
    DataA : in  std_logic_vector(19 downto 0);
    DataB : in  std_logic_vector(19 downto 0);
    AGTB  : out std_logic
  );
  end component;

begin

  b_winner     <= b_winner_in;
  b_winner_in  <= (less21 or (not valid1)) and valid2;
  data_win     <= data2 when (b_winner_in = '1') else data1;
  win_valid    <= valid1 or valid2;
  --less21       <= '1' when (data1 > data2) else '0';

  comparator_20_0 : comparator_20
  port map(
    DataA => data1,
    DataB => data2,
    AGTB  => less21
  );

end rtl;

