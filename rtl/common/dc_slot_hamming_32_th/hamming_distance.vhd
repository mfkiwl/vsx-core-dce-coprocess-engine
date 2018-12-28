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

---------------------------------------------------------------------------------
-- Calculating and accumulating Hamming distance with 4 Bytes component length --
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.dc_slot_def.all;

entity hamming_distance is
port(
  clk          : in  std_logic;
  reset_n      : in  std_logic;
  init_i       : in  std_logic;
  enable_i     : in  std_logic;
  last_i       : in  std_logic;
  data_i       : in  std_logic_vector(7 downto 0);
  ram_i        : in  std_logic_vector(7 downto 0);
  m_rd_i       : in  std_logic;
  m_valid_o    : out std_logic;
  m_data_o     : out std_logic_vector((DISTANCE_SIZE -1) downto 0)
);
end hamming_distance;

architecture rtl of hamming_distance is

  signal xor_data      : std_logic_vector(7 downto 0);
  signal xor_dist      : std_logic;
  signal xor_dist_reg  : std_logic;
  signal align_counter : std_logic_vector(1 downto 0);
  signal data_dist_0   : std_logic;
  signal data_dist_1   : std_logic;
  signal data_dist_2   : std_logic;
  signal or_data_dist  : std_logic;
  signal distance      : std_logic_vector((DISTANCE_SIZE -1) downto 0);
  signal m_valid       : std_logic;
  signal m_data        : std_logic_vector((DISTANCE_SIZE -1) downto 0);
  signal init_reg_1    : std_logic;
  signal init_reg_2    : std_logic;
  signal init_reg_3    : std_logic;
  signal enable_reg_1  : std_logic;
  signal enable_reg_2  : std_logic;
  signal last_reg_1    : std_logic;
  signal last_reg_2    : std_logic;
  signal last_reg_3    : std_logic;
  signal data_reg      : std_logic_vector(7 downto 0);
  signal ram_reg       : std_logic_vector(7 downto 0);

begin

  m_valid_o    <= m_valid;
  m_data_o     <= m_data;

  xor_data     <= data_reg xor ram_reg;
  xor_dist     <= xor_data(0) or xor_data(1) or xor_data(2) or xor_data(3) or
                  xor_data(4) or xor_data(5) or xor_data(6) or xor_data(7);

  or_data_dist <= data_dist_0 or data_dist_1 or data_dist_2 or xor_dist_reg;

-- Delay of 1 Byte distance
  process(clk, reset_n)
  begin
    if(reset_n = '0') then
      xor_dist_reg <= '0';
    elsif(clk = '1' and clk'event) then
      xor_dist_reg <= xor_dist;
    end if;
  end process;

-- Counter for 4 Bytes Hamming Distance alignment
  process(clk, reset_n)
  begin
    if(reset_n = '0') then
      align_counter <= (others => '0');
    elsif(clk = '1' and clk'event) then
      if(enable_reg_2 = '1') then
        align_counter <= align_counter + '1';
      end if;
    end if;
  end process;

-- Defining 4 Bytes Hamming Distance using align_counter
  process(clk, reset_n)
  begin
    if(reset_n = '0') then
      data_dist_0 <= '0';
      data_dist_1 <= '0';
      data_dist_2 <= '0';
    elsif(clk = '1' and clk'event) then
      if(enable_reg_2 = '1') then
        if(align_counter = "00") then
          data_dist_0 <= xor_dist_reg;
        elsif(align_counter = "01") then
          data_dist_1 <= xor_dist_reg;
        elsif(align_counter = "10") then
          data_dist_2 <= xor_dist_reg;
        end if;
      end if;
    end if;
  end process;

-- 4 Bytes Hamming Distance accumulation
  process(clk, reset_n)
  begin
    if(reset_n = '0') then
      distance <= (others => '0');
    elsif(clk = '1' and clk'event) then
      if(init_reg_3 = '1') then
        distance <= (others => '0');
      elsif(align_counter = "11" and enable_reg_2 = '1') then
        distance <= distance + or_data_dist;
      end if;
    end if;
  end process;

-- Output of accumulated distance and valid signal.
  process(clk, reset_n)
  begin
    if(reset_n = '0') then
      m_valid <= '0';
      m_data  <= (others => '0');
    elsif(clk = '1' and clk'event) then
      if(last_reg_3 = '1') then
        m_valid <= '1';
        m_data  <= distance;
      elsif(m_rd_i = '1') then
        m_valid <= '0';
      end if;
    end if;
  end process;

-- Delays of input ports. Needed for timing improvement.
  process(clk, reset_n)
  begin
    if(reset_n = '0') then
      init_reg_1   <= '0';
      init_reg_2   <= '0';
      init_reg_3   <= '0';
      enable_reg_1 <= '0';
      enable_reg_2 <= '0';
      last_reg_1   <= '0';
      last_reg_2   <= '0';
      last_reg_3   <= '0';
      data_reg     <= (others => '0');
      ram_reg      <= (others => '0');
    elsif(clk = '1' and clk'event) then
      init_reg_1   <= init_i;
      init_reg_2   <= init_reg_1;
      init_reg_3   <= init_reg_2;
      enable_reg_1 <= enable_i;
      enable_reg_2 <= enable_reg_1;
      last_reg_1   <= last_i;
      last_reg_2   <= last_reg_1;
      last_reg_3   <= last_reg_2;
      data_reg     <= data_i;
      ram_reg      <= ram_i;
    end if;
  end process;

end rtl;
