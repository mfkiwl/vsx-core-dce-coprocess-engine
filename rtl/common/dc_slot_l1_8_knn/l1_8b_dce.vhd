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

----------------------------------------------------------------------
-- Includes L1 8 bit math unit and result storing and reading logic --
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.dc_slot_def.all;

entity l1_8b_dce is
port (
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
end l1_8b_dce;

architecture rtl of l1_8b_dce is

component l1_8b_math_unit
port (
  clk      : in  std_logic;

  init_i   : in  std_logic;
  enable_i : in  std_logic;
  data_i   : in  std_logic_vector( 7 downto 0);
  ram_i    : in  std_logic_vector( 7 downto 0);
  result_o : out std_logic_vector((DISTANCE_SIZE - 1) downto 0)
);
end component;

signal init_reg     : std_logic;
signal enable_reg   : std_logic;
signal data_reg     : std_logic_vector( 7 downto 0);
signal ram_reg      : std_logic_vector( 7 downto 0);


signal result       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal distance_reg : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal valid_reg    : std_logic;
signal last_reg_1   : std_logic;
signal last_reg_2   : std_logic;
signal last_reg_3   : std_logic;

begin

m_valid_o <= valid_reg;
m_data_o  <= distance_reg;

  l1_8b_math_unit_0 : l1_8b_math_unit
  port map (
    clk      => clk,
    init_i   => init_reg,
    enable_i => enable_reg,
    data_i   => data_reg,
    ram_i    => ram_reg,
    result_o => result
  );

-- Delays of input ports (for timing improvement)
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      init_reg   <= '0';
      enable_reg <= '0';
      data_reg   <= (others => '0');
      ram_reg    <= (others => '0');
    elsif (clk = '1' and clk'event) then
      init_reg   <= init_i;
      enable_reg <= enable_i;
      data_reg   <= data_i;
      ram_reg    <= ram_i;
    end if;
  end process;

-- Storring accumulated distance to output (Port M).
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      distance_reg <= (others => '0');
    elsif (clk = '1' and clk'event) then
      if(last_reg_3 = '1') then
        distance_reg <= result;
      end if;
    end if;
  end process;

-- Forming of output valid signal (Port M).
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      valid_reg <= '0';
    elsif (clk = '1' and clk'event) then
      if(last_reg_3 = '1') then
        valid_reg <= '1';
      elsif(m_rd_i = '1') then
        valid_reg <= '0';
      end if;
    end if;
  end process;

-- Delay of input port.
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      last_reg_1 <= '0';
      last_reg_2 <= '0';
      last_reg_3 <= '0';
    elsif (clk = '1' and clk'event) then
      last_reg_1 <= last_i;
      last_reg_2 <= last_reg_1;
      last_reg_3 <= last_reg_2;
    end if;
  end process;

end rtl;
