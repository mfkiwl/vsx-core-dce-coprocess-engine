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

---------------------------------------------------------------------------------------
-- Reads from two input ports with comparing results and adding 1 bit to show winner --
-- Layer 2 - Ports A and B connected to Layer 1, port M connected to Layer 3 node    --
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dc_slot_def.all;

entity row_node_l2 is
port (

  clk          : in  std_logic;
  reset_n      : in  std_logic;
  tree_reset_i : in  std_logic;
  -- Port M signals
  m_rd_i       : in  std_logic;
  m_valid_o    : out std_logic;
  m_data_o     : out std_logic_vector((DISTANCE_SIZE - 1 + 3) downto 0);
  -- Port A signals
  a_rd_o       : out std_logic;
  a_valid_i    : in  std_logic;
  a_data_i     : in  std_logic_vector((DISTANCE_SIZE - 1 + 2) downto 0);
  -- Port B signals
  b_rd_o       : out std_logic;
  b_valid_i    : in  std_logic;
  b_data_i     : in  std_logic_vector((DISTANCE_SIZE - 1 + 2) downto 0)
);
end row_node_l2;

architecture rtl of row_node_l2 is

  signal data_win      : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  signal b_winner      : std_logic;
  signal win_valid     : std_logic;
  signal mem_data_0    : std_logic_vector((DISTANCE_SIZE - 1 + 3) downto 0);
  signal mem_data_1    : std_logic_vector((DISTANCE_SIZE - 1 + 3) downto 0);
  signal flag          : std_logic_vector(1 downto 0);
  signal rd_toggle     : std_logic;
  signal wr_toggle     : std_logic;
  signal mem_data_in   : std_logic_vector((DISTANCE_SIZE - 1 + 3) downto 0);
  signal both_full     : std_logic;
  signal both_empty_n  : std_logic;
  signal wr_en         : std_logic;
  signal rd_en         : std_logic;

  component tree_comparator_10
  port (
     data1     : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
     valid1    : in  std_logic;
     data2     : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
     valid2    : in  std_logic;
     data_win  : out std_logic_vector((DISTANCE_SIZE - 1) downto 0);
     b_winner  : out std_logic;
     win_valid : out std_logic
  );
  end component;

begin

  m_valid_o                                                           <= both_empty_n;
  m_data_o                                                            <= mem_data_0 when (rd_toggle = '0') else mem_data_1;
  a_rd_o                                                              <= (not b_winner) and wr_en;
  b_rd_o                                                              <= b_winner and wr_en;
  both_full                                                           <= flag(0) and flag(1);
  both_empty_n                                                        <= flag(0) or  flag(1);
  mem_data_in((DISTANCE_SIZE - 1) downto 0 )                          <= data_win;
  mem_data_in((DISTANCE_SIZE - 1 + 2) downto (DISTANCE_SIZE - 1 + 1)) <= b_data_i((DISTANCE_SIZE - 1 + 2) downto (DISTANCE_SIZE - 1 + 1)) when b_winner = '1' else
                                                                         a_data_i((DISTANCE_SIZE - 1 + 2) downto (DISTANCE_SIZE - 1 + 1));
  mem_data_in((DISTANCE_SIZE - 1 + 3))                                <= b_winner;
  wr_en                                                               <= win_valid and (not both_full);
  rd_en                                                               <= m_rd_i;

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
      if(tree_reset_i = '1') then
        mem_data_0 <= (others => '0');
        mem_data_1 <= (others => '0');
        flag(0)    <= '0';
        flag(1)    <= '0';
        wr_toggle  <= '0';
        rd_toggle  <= '0';
      else
        if(wr_en = '1') then
          if(wr_toggle = '0') then
            mem_data_0 <= mem_data_in;
            flag(0) <= '1';
          else
            mem_data_1 <= mem_data_in;
            flag(1) <= '1';
          end if;
          wr_toggle <= not wr_toggle;
        end if;
        if(rd_en = '1') then
          if(rd_toggle = '0') then
            flag(0) <= '0';
          else
            flag(1) <= '0';
          end if;
          rd_toggle <= not rd_toggle;
        end if;
      end if;
    end if;
  end process;

  tree_comparator_10_inst : tree_comparator_10
  port map (
    data1     => a_data_i((DISTANCE_SIZE - 1) downto 0),
    valid1    => a_valid_i,
    data2     => b_data_i((DISTANCE_SIZE - 1) downto 0),
    valid2    => b_valid_i,
    data_win  => data_win,
    b_winner  => b_winner,
    win_valid => win_valid
  );

end rtl;

