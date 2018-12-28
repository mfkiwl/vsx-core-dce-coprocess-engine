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
-- Merge sorting, results packet forming and storing in Results FIFO --
-----------------------------------------------------------------------

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

  component node_knn
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    tree_reset_i : in  std_logic;
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
  end component;

  component fifo_a_fwft
  port(
    clock        : in  std_logic;
    reset        : in  std_logic;
    data         : in  std_logic_vector(127 downto 0);
    wren         : in  std_logic;
    full         : out std_logic;
    almostfull   : out std_logic;
    q            : out std_logic_vector(127 downto 0);
    rden         : in  std_logic;
    empty        : out std_logic
  );
  end component;

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

  signal start               : std_logic;

  signal fifo_a_rst          : std_logic;
  signal fifo_a_din          : std_logic_vector(127 downto 0);
  signal fifo_a_wr_en        : std_logic;
  signal fifo_a_rd_en        : std_logic;
  signal fifo_a_dout         : std_logic_vector(127 downto 0);
  signal fifo_a_full         : std_logic;
  signal fifo_a_afull        : std_logic;
  signal fifo_a_empty        : std_logic;

  signal fifo_b_rst          : std_logic;
  signal fifo_b_din          : std_logic_vector(127 downto 0);
  signal fifo_b_wr_en        : std_logic;
  signal fifo_b_rd_en        : std_logic;
  signal fifo_b_dout         : std_logic_vector(127 downto 0);
  signal fifo_b_full         : std_logic;
  signal fifo_b_afull        : std_logic;
  signal fifo_b_empty        : std_logic;

  signal fifo_z_rst          : std_logic;
  signal fifo_z_din          : std_logic_vector(127 downto 0);
  signal fifo_z_wr_en        : std_logic;
  signal fifo_z_full         : std_logic;
  signal fifo_z_pfull        : std_logic;

  signal knn_tree_reset      : std_logic;
  signal knn_m_rd            : std_logic;
  signal knn_m_valid         : std_logic;
  signal knn_m_valid_d       : std_logic;
  signal knn_m_data          : std_logic_vector(127 downto 0);
  signal knn_a_rd            : std_logic;
  signal knn_a_valid         : std_logic;
  signal knn_a_valid_d       : std_logic;
  signal knn_a_data          : std_logic_vector(127 downto 0);
  signal knn_b_rd            : std_logic;
  signal knn_b_valid         : std_logic;
  signal knn_b_valid_a       : std_logic;
  signal knn_b_valid_b       : std_logic;
  signal knn_b_data          : std_logic_vector(127 downto 0);

  signal fifo_tgl            : std_logic;
  signal knn_num_eq_wc       : std_logic;
  signal write_count         : std_logic_vector( 6 downto 0);

  signal finish_resp_en      : std_logic;
  signal finish_resp_data    : std_logic_vector(127 downto 0);
  signal pending_finish_resp : std_logic;

  signal own_fpga_addr_reg   : std_logic_vector(2 downto 0);
  signal own_fpga_select     : std_logic_vector(6 downto 0);

  signal temperature_reg     : std_logic_vector(5 downto 0);
  signal knn_num_reg         : std_logic_vector(6 downto 0);

begin

  tree_reset       <= knn_tree_reset;
  a_rd_o           <= knn_a_rd;
  pause            <= fifo_z_pfull;

  knn_a_data       <= qv_id & CRC &
                      "000000000000" & a_data_i((DISTANCE_SIZE - 1) downto 0) &
                      fv_index & a_data_i((DISTANCE_SIZE - 1 + 4) downto DISTANCE_SIZE) &
                      '0' & own_fpga_select & RESULT_ID & RESULT_PACK_LENGTH;

  knn_a_valid      <= a_valid_i;
  knn_b_valid_a    <= (not fifo_a_empty) and (start or knn_a_valid);
  knn_b_valid_b    <= (not fifo_b_empty) and (start or knn_a_valid);
  knn_b_valid      <= knn_b_valid_a when (fifo_tgl = '1') else knn_b_valid_b;
  knn_b_data       <= fifo_a_dout when (fifo_tgl = '1') else fifo_b_dout;
  knn_m_rd         <= (fifo_a_wr_en or fifo_b_wr_en) when (last_vector = '0') else (fifo_z_wr_en and (not pending_finish_resp));


  knn_num_eq_wc    <= '1' when (write_count = knn_num_reg) else '0';
  fifo_a_wr_en     <= (not fifo_tgl) and (not last_vector) and knn_m_valid and (not knn_num_eq_wc) and (not fifo_a_afull);
  fifo_b_wr_en     <= fifo_tgl       and (not last_vector) and knn_m_valid and (not knn_num_eq_wc) and (not fifo_b_afull);
  fifo_a_rd_en     <= knn_b_rd when (fifo_tgl = '1') else '0';
  fifo_b_rd_en     <= knn_b_rd when (fifo_tgl = '0') else '0';
  fifo_a_din       <= knn_m_data;
  fifo_b_din       <= knn_m_data;

  fifo_z_wr_en     <= '1' when ((pending_finish_resp = '1') and (fifo_z_full = '0')) else
                      (last_vector and knn_m_valid and (not knn_num_eq_wc) and (not fifo_z_full));
  fifo_z_din       <= finish_resp_data when ((pending_finish_resp = '1') and (fifo_z_full = '0')) else knn_m_data;

  finish_resp_en   <= (last_vector and knn_tree_reset);
  finish_resp_data <= qv_id & CRC & X"00000000" & X"FFFFFF" & "00" & temperature_reg & '0' & own_fpga_select & LAST_RESULT_ID & RESULT_PACK_LENGTH;

  node_knn_0 : node_knn
  port map (
    clk          => clk,
    reset_n      => reset_n,
    tree_reset_i => knn_tree_reset,
    m_rd_i       => knn_m_rd,
    m_valid_o    => knn_m_valid,
    m_data_o     => knn_m_data,
    a_rd_o       => knn_a_rd,
    a_valid_i    => knn_a_valid,
    a_data_i     => knn_a_data,
    b_rd_o       => knn_b_rd,
    b_valid_i    => knn_b_valid,
    b_data_i     => knn_b_data
  );

  fifo_a_fwft_0 : fifo_a_fwft
  port map (
    clock            => clk,
    reset            => fifo_a_rst,
    data             => fifo_a_din,
    wren             => fifo_a_wr_en,
    full             => fifo_a_full,
    almostfull       => fifo_a_afull,
    q                => fifo_a_dout,
    rden             => fifo_a_rd_en,
    empty            => fifo_a_empty
  );

  fifo_b_fwft_0 : fifo_a_fwft
  port map (
    clock            => clk,
    reset            => fifo_b_rst,
    data             => fifo_b_din,
    wren             => fifo_b_wr_en,
    full             => fifo_b_full,
    almostfull       => fifo_b_afull,
    q                => fifo_b_dout,
    rden             => fifo_b_rd_en,
    empty            => fifo_b_empty
  );

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

-- Forming FIFO A to FIFO B toggling signals,
-- These FIFOs are used for merge sorting during 1 query.
-- FIFO toggle each time after 16 results (1 data batch) coming.
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      fifo_tgl <= '0';
    elsif (clk = '1' and clk'event) then
      if (knn_tree_reset = '1') then
        fifo_tgl <= not fifo_tgl;
      end if;
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
      if ((last_vector and knn_tree_reset) = '1') then
        pending_finish_resp <= '1';
      elsif (fifo_z_wr_en = '1')then
        pending_finish_resp <= '0';
      end if;
    end if;
  end process;

-- Forming delays of knn_a_valid and knn_m_valid signals to check their edges
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      knn_a_valid_d <= '0';
      knn_m_valid_d <= '0';
    elsif (clk = '1' and clk'event) then
      knn_a_valid_d <= knn_a_valid;
      knn_m_valid_d <= knn_m_valid;
    end if;
  end process;

-- Forming "start" signal which is used for merge sorting during each 16 results (1 data batch) coming
-- Forming FIFO A, FIFO B reset signals, and slot tree reset signal.
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      start <= '0';
      knn_tree_reset <= '0';
      fifo_a_rst <= '1';
      fifo_b_rst <= '1';
    elsif (clk = '1' and clk'event) then
      fifo_a_rst <= '0';
      fifo_b_rst <= '0';
      if (knn_a_valid = '1' and knn_a_valid_d = '0') then
        start <= '1';
      elsif((start = '1') and ((knn_m_valid = '0' and knn_m_valid_d = '1') or (knn_num_eq_wc = '1'))) then
        start <= '0';
        knn_tree_reset <= '1';
        fifo_a_rst <= fifo_tgl;
        fifo_b_rst <= not fifo_tgl;
      elsif(knn_tree_reset = '1') then
        knn_tree_reset <= '0';
      end if;
    end if;
  end process;

-- Forming counter for counting number of best results ( K ).
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      write_count <= (others => '0');
    elsif (clk = '1' and clk'event) then
      if ((fifo_a_wr_en = '1') or (fifo_b_wr_en = '1') or ((fifo_z_wr_en = '1') and (pending_finish_resp = '0'))) then
        write_count <= write_count + '1';
      elsif(knn_m_valid = '0' and knn_m_valid_d = '1') then
        write_count <= (others => '0');
      end if;
    end if;
  end process;

-- Delay of temperature value (for timing improvement)
-- Delay of number of best results input port (for timing improvement)
  process(clk, reset_n)
  begin
    if (reset_n = '0') then
      temperature_reg <= (others => '0');
      knn_num_reg     <= (others => '0');
    elsif (clk = '1' and clk'event) then
      temperature_reg <= temperature_i;
      knn_num_reg     <= knn_num_i;
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
