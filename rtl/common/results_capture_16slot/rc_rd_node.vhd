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

------------------------------------------------------------------------------------
-- Reads from two input ports, toggling port if both are valid                    --
-- Ports A and B connected to dc slots (lowest layer) or one layer down node,     --
-- port M connected to one layer up node, or result_response_node (topmost layer) --
------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rc_rd_node is
port (

  clk          : in  std_logic;
  reset_n      : in  std_logic;
  -- Port M signals
  m_rd_i       : in  std_logic;
  m_valid_o    : out std_logic;
  m_data_o     : out std_logic_vector(127 downto 0);
  -- Port A signals
  a_rd_o       : out std_logic;
  a_valid_i    : in  std_logic;
  a_data_i     : in  std_logic_vector(127 downto 0);
  -- Port B signals
  b_rd_o       : out std_logic;
  b_valid_i    : in  std_logic;
  b_data_i     : in  std_logic_vector(127 downto 0)
);
end rc_rd_node;

architecture rtl of rc_rd_node is

  signal win_toogle   : std_logic;
  signal mem_data_0   : std_logic_vector(127 downto 0);
  signal mem_data_1   : std_logic_vector(127 downto 0);
  signal flag         : std_logic_vector(1 downto 0);
  signal rd_toggle    : std_logic;
  signal wr_toggle    : std_logic;
  signal mem_data_in  : std_logic_vector(127 downto 0);
  signal both_full    : std_logic;
  signal both_empty_n : std_logic;
  signal wr_en        : std_logic;
  signal rd_en        : std_logic;
  signal a_rd         : std_logic;
  signal b_rd         : std_logic;

begin

  a_rd_o        <= a_rd;
  b_rd_o        <= b_rd;
  m_valid_o     <= both_empty_n;
  m_data_o      <= mem_data_0 when (rd_toggle = '0') else mem_data_1;
  a_rd          <= ((not win_toogle) or (not b_valid_i)) and a_valid_i and (not both_full);
  b_rd          <= (win_toogle or (not a_valid_i)) and b_valid_i and (not both_full);

  both_full     <= flag(0) and flag(1);
  both_empty_n  <= flag(0) or  flag(1);
  mem_data_in   <= b_data_i when (b_rd = '1') else a_data_i;
  wr_en         <= (a_valid_i or b_valid_i) and (not both_full);
  rd_en         <= m_rd_i;

-- Toggling flag to define port which will be read (response/result)
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      win_toogle <= '0';
    elsif (clk = '1' and clk'event) then
      win_toogle <= not win_toogle;
    end if;
  end process;

-- Includes 2 storage write/read regions (mem_data_*). Each has own flag which shows status (full or empty).
-- Each time writing from bottom port wr_toggle is inverted.
-- Each time reading from top port rd_toggle is inverted.
-- Works as FIFO with depth equal to two in which wr_toggle acts as write address and rd_toggle - as read address,
-- both_full - as full, both_empty_n - as empty_n
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      mem_data_0  <= (others => '0');
      mem_data_1  <= (others => '0');
      flag(0)     <= '0';
      flag(1)     <= '0';
      rd_toggle   <= '0';
      wr_toggle   <= '0';
    elsif (clk = '1' and clk'event) then
      if(wr_en = '1') then
        if(wr_toggle = '0') then
          mem_data_0 <= mem_data_in;
          flag(0)    <= '1';
        else
          mem_data_1 <= mem_data_in;
          flag(1)    <= '1';
        end if;
        wr_toggle <= not wr_toggle;
      end if;
      if(rd_en = '1') then
        if(rd_toggle = '0') then
          flag(0)    <= '0';
        else
          flag(1)    <= '0';
        end if;
        rd_toggle <= not rd_toggle;
      end if;
    end if;
  end process;

end rtl;
