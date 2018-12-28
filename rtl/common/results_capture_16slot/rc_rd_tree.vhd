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

-------------------------------------------------------------------------
-- Reads results from 16 dc slots and forwards to result_response_node --
-------------------------------------------------------------------------

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
   data_00_i    : in  std_logic_vector(127 downto 0);
   data_01_i    : in  std_logic_vector(127 downto 0);
   data_02_i    : in  std_logic_vector(127 downto 0);
   data_03_i    : in  std_logic_vector(127 downto 0);
   data_04_i    : in  std_logic_vector(127 downto 0);
   data_05_i    : in  std_logic_vector(127 downto 0);
   data_06_i    : in  std_logic_vector(127 downto 0);
   data_07_i    : in  std_logic_vector(127 downto 0);
   data_08_i    : in  std_logic_vector(127 downto 0);
   data_09_i    : in  std_logic_vector(127 downto 0);
   data_10_i    : in  std_logic_vector(127 downto 0);
   data_11_i    : in  std_logic_vector(127 downto 0);
   data_12_i    : in  std_logic_vector(127 downto 0);
   data_13_i    : in  std_logic_vector(127 downto 0);
   data_14_i    : in  std_logic_vector(127 downto 0);
   data_15_i    : in  std_logic_vector(127 downto 0)
);
end rc_rd_tree;

architecture rtl of rc_rd_tree is

  component rc_rd_node
  port (
     clk          : in  std_logic;
     reset_n      : in  std_logic;
     m_rd_i       : in  std_logic;
     m_valid_o    : out std_logic;
     m_data_o     : out std_logic_vector(127 downto 0);
     a_rd_o       : out std_logic;
     a_valid_i    : in  std_logic;
     a_data_i     : in  std_logic_vector(127 downto 0);
     b_rd_o       : out std_logic;
     b_valid_i    : in  std_logic;
     b_data_i     : in  std_logic_vector(127 downto 0)
  );
  end component;


  signal a_rd_0_00    : std_logic;
  signal a_rd_0_01    : std_logic;
  signal a_rd_0_02    : std_logic;
  signal a_rd_0_03    : std_logic;
  signal a_rd_0_04    : std_logic;
  signal a_rd_0_05    : std_logic;
  signal a_rd_0_06    : std_logic;
  signal a_rd_0_07    : std_logic;

  signal b_rd_0_00    : std_logic;
  signal b_rd_0_01    : std_logic;
  signal b_rd_0_02    : std_logic;
  signal b_rd_0_03    : std_logic;
  signal b_rd_0_04    : std_logic;
  signal b_rd_0_05    : std_logic;
  signal b_rd_0_06    : std_logic;
  signal b_rd_0_07    : std_logic;

  signal a_valid_0_00 : std_logic;
  signal a_valid_0_01 : std_logic;
  signal a_valid_0_02 : std_logic;
  signal a_valid_0_03 : std_logic;
  signal a_valid_0_04 : std_logic;
  signal a_valid_0_05 : std_logic;
  signal a_valid_0_06 : std_logic;
  signal a_valid_0_07 : std_logic;

  signal b_valid_0_00 : std_logic;
  signal b_valid_0_01 : std_logic;
  signal b_valid_0_02 : std_logic;
  signal b_valid_0_03 : std_logic;
  signal b_valid_0_04 : std_logic;
  signal b_valid_0_05 : std_logic;
  signal b_valid_0_06 : std_logic;
  signal b_valid_0_07 : std_logic;

  signal a_data_0_00  : std_logic_vector(127 downto 0);
  signal a_data_0_01  : std_logic_vector(127 downto 0);
  signal a_data_0_02  : std_logic_vector(127 downto 0);
  signal a_data_0_03  : std_logic_vector(127 downto 0);
  signal a_data_0_04  : std_logic_vector(127 downto 0);
  signal a_data_0_05  : std_logic_vector(127 downto 0);
  signal a_data_0_06  : std_logic_vector(127 downto 0);
  signal a_data_0_07  : std_logic_vector(127 downto 0);

  signal b_data_0_00  : std_logic_vector(127 downto 0);
  signal b_data_0_01  : std_logic_vector(127 downto 0);
  signal b_data_0_02  : std_logic_vector(127 downto 0);
  signal b_data_0_03  : std_logic_vector(127 downto 0);
  signal b_data_0_04  : std_logic_vector(127 downto 0);
  signal b_data_0_05  : std_logic_vector(127 downto 0);
  signal b_data_0_06  : std_logic_vector(127 downto 0);
  signal b_data_0_07  : std_logic_vector(127 downto 0);

  signal a_rd_1_00    : std_logic;
  signal a_rd_1_01    : std_logic;
  signal a_rd_1_02    : std_logic;
  signal a_rd_1_03    : std_logic;

  signal b_rd_1_00    : std_logic;
  signal b_rd_1_01    : std_logic;
  signal b_rd_1_02    : std_logic;
  signal b_rd_1_03    : std_logic;

  signal a_valid_1_00 : std_logic;
  signal a_valid_1_01 : std_logic;
  signal a_valid_1_02 : std_logic;
  signal a_valid_1_03 : std_logic;

  signal b_valid_1_00 : std_logic;
  signal b_valid_1_01 : std_logic;
  signal b_valid_1_02 : std_logic;
  signal b_valid_1_03 : std_logic;

  signal a_data_1_00  : std_logic_vector(127 downto 0);
  signal a_data_1_01  : std_logic_vector(127 downto 0);
  signal a_data_1_02  : std_logic_vector(127 downto 0);
  signal a_data_1_03  : std_logic_vector(127 downto 0);

  signal b_data_1_00  : std_logic_vector(127 downto 0);
  signal b_data_1_01  : std_logic_vector(127 downto 0);
  signal b_data_1_02  : std_logic_vector(127 downto 0);
  signal b_data_1_03  : std_logic_vector(127 downto 0);

  signal a_rd_2_00    : std_logic;
  signal a_rd_2_01    : std_logic;

  signal b_rd_2_00    : std_logic;
  signal b_rd_2_01    : std_logic;

  signal a_valid_2_00 : std_logic;
  signal a_valid_2_01 : std_logic;

  signal b_valid_2_00 : std_logic;
  signal b_valid_2_01 : std_logic;

  signal a_data_2_00  : std_logic_vector(127 downto 0);
  signal a_data_2_01  : std_logic_vector(127 downto 0);

  signal b_data_2_00  : std_logic_vector(127 downto 0);
  signal b_data_2_01  : std_logic_vector(127 downto 0);

  signal a_rd_3_00    : std_logic;

  signal b_rd_3_00    : std_logic;

  signal a_valid_3_00 : std_logic;

  signal b_valid_3_00 : std_logic;

  signal a_data_3_00  : std_logic_vector(127 downto 0);

  signal b_data_3_00  : std_logic_vector(127 downto 0);

  signal a_rd_4_00    : std_logic;

  signal a_valid_4_00 : std_logic;

  signal a_data_4_00  : std_logic_vector(127 downto 0);

begin

   rd_00_o      <= a_rd_0_00;
   rd_01_o      <= b_rd_0_00;
   rd_02_o      <= a_rd_0_01;
   rd_03_o      <= b_rd_0_01;
   rd_04_o      <= a_rd_0_02;
   rd_05_o      <= b_rd_0_02;
   rd_06_o      <= a_rd_0_03;
   rd_07_o      <= b_rd_0_03;
   rd_08_o      <= a_rd_0_04;
   rd_09_o      <= b_rd_0_04;
   rd_10_o      <= a_rd_0_05;
   rd_11_o      <= b_rd_0_05;
   rd_12_o      <= a_rd_0_06;
   rd_13_o      <= b_rd_0_06;
   rd_14_o      <= a_rd_0_07;
   rd_15_o      <= b_rd_0_07;

   a_valid_0_00 <= valid_00_i;
   b_valid_0_00 <= valid_01_i;
   a_valid_0_01 <= valid_02_i;
   b_valid_0_01 <= valid_03_i;
   a_valid_0_02 <= valid_04_i;
   b_valid_0_02 <= valid_05_i;
   a_valid_0_03 <= valid_06_i;
   b_valid_0_03 <= valid_07_i;
   a_valid_0_04 <= valid_08_i;
   b_valid_0_04 <= valid_09_i;
   a_valid_0_05 <= valid_10_i;
   b_valid_0_05 <= valid_11_i;
   a_valid_0_06 <= valid_12_i;
   b_valid_0_06 <= valid_13_i;
   a_valid_0_07 <= valid_14_i;
   b_valid_0_07 <= valid_15_i;

   a_data_0_00  <= data_00_i;
   b_data_0_00  <= data_01_i;
   a_data_0_01  <= data_02_i;
   b_data_0_01  <= data_03_i;
   a_data_0_02  <= data_04_i;
   b_data_0_02  <= data_05_i;
   a_data_0_03  <= data_06_i;
   b_data_0_03  <= data_07_i;
   a_data_0_04  <= data_08_i;
   b_data_0_04  <= data_09_i;
   a_data_0_05  <= data_10_i;
   b_data_0_05  <= data_11_i;
   a_data_0_06  <= data_12_i;
   b_data_0_06  <= data_13_i;
   a_data_0_07  <= data_14_i;
   b_data_0_07  <= data_15_i;

   a_rd_4_00    <= m_rd_i;
   m_valid_o    <= a_valid_4_00;
   m_data_o     <= a_data_4_00;


   -- layer 0
   rc_rd_node_l0_00 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => a_rd_1_00,
      m_valid_o    => a_valid_1_00,
      m_data_o     => a_data_1_00,
      a_rd_o       => a_rd_0_00,
      a_valid_i    => a_valid_0_00,
      a_data_i     => a_data_0_00,
      b_rd_o       => b_rd_0_00,
      b_valid_i    => b_valid_0_00,
      b_data_i     => b_data_0_00

   );

   rc_rd_node_l0_01 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => b_rd_1_00,
      m_valid_o    => b_valid_1_00,
      m_data_o     => b_data_1_00,
      a_rd_o       => a_rd_0_01,
      a_valid_i    => a_valid_0_01,
      a_data_i     => a_data_0_01,
      b_rd_o       => b_rd_0_01,
      b_valid_i    => b_valid_0_01,
      b_data_i     => b_data_0_01

   );

   rc_rd_node_l0_02 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => a_rd_1_01,
      m_valid_o    => a_valid_1_01,
      m_data_o     => a_data_1_01,
      a_rd_o       => a_rd_0_02,
      a_valid_i    => a_valid_0_02,
      a_data_i     => a_data_0_02,
      b_rd_o       => b_rd_0_02,
      b_valid_i    => b_valid_0_02,
      b_data_i     => b_data_0_02

   );

   rc_rd_node_l0_03 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => b_rd_1_01,
      m_valid_o    => b_valid_1_01,
      m_data_o     => b_data_1_01,
      a_rd_o       => a_rd_0_03,
      a_valid_i    => a_valid_0_03,
      a_data_i     => a_data_0_03,
      b_rd_o       => b_rd_0_03,
      b_valid_i    => b_valid_0_03,
      b_data_i     => b_data_0_03

   );

   rc_rd_node_l0_04 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => a_rd_1_02,
      m_valid_o    => a_valid_1_02,
      m_data_o     => a_data_1_02,
      a_rd_o       => a_rd_0_04,
      a_valid_i    => a_valid_0_04,
      a_data_i     => a_data_0_04,
      b_rd_o       => b_rd_0_04,
      b_valid_i    => b_valid_0_04,
      b_data_i     => b_data_0_04

   );

   rc_rd_node_l0_05 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => b_rd_1_02,
      m_valid_o    => b_valid_1_02,
      m_data_o     => b_data_1_02,
      a_rd_o       => a_rd_0_05,
      a_valid_i    => a_valid_0_05,
      a_data_i     => a_data_0_05,
      b_rd_o       => b_rd_0_05,
      b_valid_i    => b_valid_0_05,
      b_data_i     => b_data_0_05

   );

   rc_rd_node_l0_06 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => a_rd_1_03,
      m_valid_o    => a_valid_1_03,
      m_data_o     => a_data_1_03,
      a_rd_o       => a_rd_0_06,
      a_valid_i    => a_valid_0_06,
      a_data_i     => a_data_0_06,
      b_rd_o       => b_rd_0_06,
      b_valid_i    => b_valid_0_06,
      b_data_i     => b_data_0_06

   );

   rc_rd_node_l0_07 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => b_rd_1_03,
      m_valid_o    => b_valid_1_03,
      m_data_o     => b_data_1_03,
      a_rd_o       => a_rd_0_07,
      a_valid_i    => a_valid_0_07,
      a_data_i     => a_data_0_07,
      b_rd_o       => b_rd_0_07,
      b_valid_i    => b_valid_0_07,
      b_data_i     => b_data_0_07

   );


   -- layer 1
   rc_rd_node_l1_00 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => a_rd_2_00,
      m_valid_o    => a_valid_2_00,
      m_data_o     => a_data_2_00,
      a_rd_o       => a_rd_1_00,
      a_valid_i    => a_valid_1_00,
      a_data_i     => a_data_1_00,
      b_rd_o       => b_rd_1_00,
      b_valid_i    => b_valid_1_00,
      b_data_i     => b_data_1_00

   );

   rc_rd_node_l1_01 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => b_rd_2_00,
      m_valid_o    => b_valid_2_00,
      m_data_o     => b_data_2_00,
      a_rd_o       => a_rd_1_01,
      a_valid_i    => a_valid_1_01,
      a_data_i     => a_data_1_01,
      b_rd_o       => b_rd_1_01,
      b_valid_i    => b_valid_1_01,
      b_data_i     => b_data_1_01

   );

   rc_rd_node_l1_02 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => a_rd_2_01,
      m_valid_o    => a_valid_2_01,
      m_data_o     => a_data_2_01,
      a_rd_o       => a_rd_1_02,
      a_valid_i    => a_valid_1_02,
      a_data_i     => a_data_1_02,
      b_rd_o       => b_rd_1_02,
      b_valid_i    => b_valid_1_02,
      b_data_i     => b_data_1_02

   );

   rc_rd_node_l1_03 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => b_rd_2_01,
      m_valid_o    => b_valid_2_01,
      m_data_o     => b_data_2_01,
      a_rd_o       => a_rd_1_03,
      a_valid_i    => a_valid_1_03,
      a_data_i     => a_data_1_03,
      b_rd_o       => b_rd_1_03,
      b_valid_i    => b_valid_1_03,
      b_data_i     => b_data_1_03

   );

   -- layer 2
   rc_rd_node_l2_00 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => a_rd_3_00,
      m_valid_o    => a_valid_3_00,
      m_data_o     => a_data_3_00,
      a_rd_o       => a_rd_2_00,
      a_valid_i    => a_valid_2_00,
      a_data_i     => a_data_2_00,
      b_rd_o       => b_rd_2_00,
      b_valid_i    => b_valid_2_00,
      b_data_i     => b_data_2_00

   );

   rc_rd_node_l2_01 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => b_rd_3_00,
      m_valid_o    => b_valid_3_00,
      m_data_o     => b_data_3_00,
      a_rd_o       => a_rd_2_01,
      a_valid_i    => a_valid_2_01,
      a_data_i     => a_data_2_01,
      b_rd_o       => b_rd_2_01,
      b_valid_i    => b_valid_2_01,
      b_data_i     => b_data_2_01

   );

   -- layer 3
   rc_rd_node_l3_00 : rc_rd_node
   port map (
      clk          => clk,
      reset_n      => reset_n,
      m_rd_i       => a_rd_4_00,
      m_valid_o    => a_valid_4_00,
      m_data_o     => a_data_4_00,
      a_rd_o       => a_rd_3_00,
      a_valid_i    => a_valid_3_00,
      a_data_i     => a_data_3_00,
      b_rd_o       => b_rd_3_00,
      b_valid_i    => b_valid_3_00,
      b_data_i     => b_data_3_00

   );


end rtl;
