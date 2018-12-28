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
-- Module for thresholding, results packet forming and storing in Results FIFO --
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.dc_slot_def.all;

entity row_best_result is
port (

  clk              : in  std_logic;
  reset_n          : in  std_logic;
  tree_reset       : out std_logic;

  own_fpga_addr_i  : in  std_logic_vector( 2 downto 0);

  threshold_i      : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  knn_num_i        : in  std_logic_vector( 6 downto 0);
  temperature_i    : in  std_logic_vector( 5 downto 0);
  last_vector      : in  std_logic;

  a_rd_o           : out std_logic;
  a_valid_i        : in  std_logic;
  a_data_i         : in  std_logic_vector((DISTANCE_SIZE - 1 + 4) downto 0);

  fv_index         : in  std_logic_vector(27 downto 0);
  qv_id            : in  std_logic_vector(15 downto 0);

  fifo_z_rd_en     : in  std_logic;
  fifo_z_dout      : out std_logic_vector(127 downto 0);
  fifo_z_empty     : out std_logic;

  pause            : out std_logic
);
end row_best_result;

architecture rtl of row_best_result is

  constant RESULT_ID          : std_logic_vector( 7 downto 0) := X"AA";
  constant LAST_RESULT_ID     : std_logic_vector( 7 downto 0) := X"AB";
  constant CRC                : std_logic_vector(15 downto 0) := X"5555";
  constant RESULT_PACK_LENGTH : std_logic_vector(15 downto 0) := X"0003";

  component fifo_z_fwft
  port (
    clock      : in  std_logic;
    reset      : in  std_logic;
    data       : in  std_logic_vector(127 downto 0);
    wren       : in  std_logic;
    full       : out std_logic;
    almostfull : out std_logic;
    q          : out std_logic_vector(127 downto 0);
    rden       : in  std_logic;
    empty      : out std_logic
  );
  end component;

  signal reset_n_reg         : std_logic;

  signal fifo_z_rst          : std_logic;
  signal fifo_z_din          : std_logic_vector(127 downto 0);
  signal fifo_z_wr_en        : std_logic;
  signal fifo_z_full         : std_logic;
  signal fifo_z_pfull        : std_logic;

  signal a_rd                : std_logic;
  signal a_valid_reg         : std_logic;
  signal th_gt_dist          : std_logic;
  signal threshold_reg       : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  signal own_fpga_addr_reg   : std_logic_vector(2 downto 0);
  signal own_fpga_select     : std_logic_vector(6 downto 0);

  signal finish_resp_en      : std_logic;
  signal finish_resp_data    : std_logic_vector(127 downto 0);
  signal pending_finish_resp : std_logic;

  signal threshold_data      : std_logic_vector(127 downto 0);

  signal temperature_reg     : std_logic_vector(5 downto 0);
  signal th_tree_reset       : std_logic;

begin

  tree_reset     <= th_tree_reset;
  a_rd_o         <= a_rd;
  pause          <= fifo_z_pfull;

  a_rd           <= a_valid_i;

  threshold_data   <= qv_id & CRC &
                      "000000000000" & a_data_i((DISTANCE_SIZE - 1) downto 0) &
                      fv_index & a_data_i((DISTANCE_SIZE - 1 + 4) downto DISTANCE_SIZE) &
                      '0' & own_fpga_select & RESULT_ID & RESULT_PACK_LENGTH;

  fifo_z_wr_en     <= '1' when ((pending_finish_resp = '1') and (fifo_z_full = '0')) else
                      (a_valid_i and (not fifo_z_full) and th_gt_dist);
  fifo_z_din       <= finish_resp_data when ((pending_finish_resp = '1') and (fifo_z_full = '0')) else threshold_data;

  finish_resp_en   <= (last_vector and th_tree_reset);
  finish_resp_data <= qv_id & CRC & X"00000000" & X"FFFFFF" & "00" & temperature_reg & '0' & own_fpga_select & LAST_RESULT_ID & RESULT_PACK_LENGTH;

  th_gt_dist       <= '1' when (threshold_reg > a_data_i((DISTANCE_SIZE - 1) downto 0)) else '0';

  fifo_z_fwft_0 : fifo_z_fwft
  port map (
    clock      => clk,
    reset      => fifo_z_rst,
    data       => fifo_z_din,
    wren       => fifo_z_wr_en,
    full       => fifo_z_full,
    almostfull => fifo_z_pfull,
    q          => fifo_z_dout,
    rden       => fifo_z_rd_en,
    empty      => fifo_z_empty
  );

-- Forming of FIFO Z reset
  process(clk)
  begin
    if (clk = '1' and clk'event) then
      reset_n_reg <= reset_n;
      fifo_z_rst  <= not reset_n_reg;
    end if;
  end process;

-- Forming enable for finishing query response.
-- Is set to '1' when all results for current query are written to FIFO Z (results FIFO),
-- Is set to '0' when this response is written to FIFO Z.
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      pending_finish_resp <= '0';
    elsif (clk = '1' and clk'event) then
      if ((last_vector and th_tree_reset) = '1') then
        pending_finish_resp <= '1';
      elsif (fifo_z_wr_en = '1')then
        pending_finish_resp <= '0';
      end if;
    end if;
  end process;

-- Delay of temperature value (for timing improvement)
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      temperature_reg <= (others => '0');
    elsif (clk = '1' and clk'event) then
      temperature_reg <= temperature_i;
    end if;
  end process;

-- Delay of threshold value (for timing improvement)
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      threshold_reg  <= (others => '0');
    elsif (clk = '1' and clk'event) then
      threshold_reg <= threshold_i;
    end if;
  end process;

-- Delay of Port A valid for detecting of its falling edge.
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      a_valid_reg <= '0';
    elsif (clk = '1' and clk'event) then
      a_valid_reg <= a_valid_i;
    end if;
  end process;

-- Forming tree reset signal on falling edge of A valid
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      th_tree_reset <= '0';
    elsif (clk = '1' and clk'event) then
      if(a_valid_i = '0' and a_valid_reg = '1') then
        th_tree_reset <= '1';
      elsif(th_tree_reset = '1') then
        th_tree_reset <= '0';
      end if;
    end if;
  end process;

-- Current FPGA address field used in Results packet.
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      own_fpga_addr_reg <= (others => '0');
      own_fpga_select   <= (others => '0');
    elsif (clk = '1' and clk'event) then
      own_fpga_addr_reg <= own_fpga_addr_i;
      case own_fpga_addr_reg is
        when "000" =>
          own_fpga_select <= "0000001";
        when "001" =>
          own_fpga_select <= "0000010";
        when "010" =>
          own_fpga_select <= "0000100";
        when "011" =>
          own_fpga_select <= "0001000";
        when "100" =>
          own_fpga_select <= "0010000";
        when "101" =>
          own_fpga_select <= "0100000";
        when "110" =>
          own_fpga_select <= "1000000";
        when others =>
          own_fpga_select <= (others => '0');
      end case;
    end if;
  end process;

end rtl;

