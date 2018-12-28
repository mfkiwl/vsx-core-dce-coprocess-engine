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

---------------------------------------------------------------------------
-- Sending own responses and results and packets read from right side    --
-- parallel interface module to the left side parallel interface module. --
---------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity resp_pack_gen is
port(
    -- Common signals
  reset_n            : in  std_logic;
  clk                : in  std_logic;

    -- Downstream FIFO interface (To left side)
  ls_data_o          : out std_logic_vector(35 downto 0);
  ls_wr_en_o         : out std_logic;
  ls_full_i          : in  std_logic;

    -- Downstream FIFO interface (From right side)
  rs_data_i          : in  std_logic_vector(35 downto 0);
  rs_empty_i         : in  std_logic;
  rs_rd_en_o         : out std_logic;

    -- Own Response interface
  own_resp_data_i    : in  std_logic_vector(95 downto 0);
  own_resp_valid_i   : in  std_logic;
  own_resp_rdy_o     : out std_logic;

    -- Own Results interface
  own_result_data_i  : in  std_logic_vector(127 downto 0);
  own_result_valid_i : in  std_logic;
  own_result_rd_o    : out std_logic
);
end resp_pack_gen;

architecture rtl of resp_pack_gen is

constant STATE_IDLE          : std_logic_vector(3 downto 0) := X"0";
constant STATE_RESPONSE_0    : std_logic_vector(3 downto 0) := X"1";
constant STATE_RESPONSE_1    : std_logic_vector(3 downto 0) := X"2";
constant STATE_RESPONSE_2    : std_logic_vector(3 downto 0) := X"3";
constant STATE_RESULT_0      : std_logic_vector(3 downto 0) := X"4";
constant STATE_RESULT_1      : std_logic_vector(3 downto 0) := X"5";
constant STATE_RESULT_2      : std_logic_vector(3 downto 0) := X"6";
constant STATE_RESULT_3      : std_logic_vector(3 downto 0) := X"7";
constant STATE_FROM_RIGHT    : std_logic_vector(3 downto 0) := X"8";
constant STATE_FROM_RIGHT_L0 : std_logic_vector(3 downto 0) := X"9";
constant STATE_FROM_RIGHT_L1 : std_logic_vector(3 downto 0) := X"A";

component result_response_node
port (
  clk              : in  std_logic;
  reset_n          : in  std_logic;
  -- Port M signals
  m_rdy_i          : in  std_logic;
  m_valid_o        : out std_logic;
  m_data_o         : out std_logic_vector(127 downto 0);
  m_result_flag_o  : out std_logic;
  -- Port A signals
  result_rd_o      : out std_logic;
  result_valid_i   : in  std_logic;
  result_data_i    : in  std_logic_vector(127 downto 0);
  -- Port B signals
  response_rd_o    : out std_logic;
  response_valid_i : in  std_logic;
  response_data_i  : in  std_logic_vector(95 downto 0)
);
end component;

signal state                  : std_logic_vector( 3 downto 0);
signal sm_rdy                 : std_logic;
signal ls_own_response_data   : std_logic_vector(35 downto 0);
signal ls_own_response_we     : std_logic;
signal ls_own_result_data     : std_logic_vector(35 downto 0);
signal ls_own_result_we       : std_logic;
signal ls_from_rs_data        : std_logic_vector(35 downto 0);
signal ls_from_rs_we          : std_logic;
signal rs_read_counter        : std_logic_vector(15 downto 0);

signal ls_data                : std_logic_vector(35 downto 0);
signal ls_wr_en               : std_logic;

signal own_resp_data_reg      : std_logic_vector(95 downto 0);
signal own_result_data_reg    : std_logic_vector(127 downto 0);

signal rs_ds_fifo_fwft_din    : std_logic_vector(35 downto 0);
signal rs_ds_fifo_fwft_rd_en  : std_logic;
signal rs_ds_fifo_fwft_empty  : std_logic;

signal m_data                 : std_logic_vector(127 downto 0);
signal m_valid                : std_logic;
signal m_rdy                  : std_logic;
signal m_result_flag          : std_logic;

component fifo_9_36_fwft
port(
  clk     : in  std_logic;
  reset_n : in  std_logic;

  u_rden  : in  std_logic;
  u_q     : out std_logic_vector(35 downto 0);
  u_empty : out std_logic;

  f_rden  : out std_logic;
  f_q     : in  std_logic_vector(35 downto 0);
  f_empty : in  std_logic
);
end component;

begin

m_rdy                 <= sm_rdy;

sm_rdy                <= '1' when ((state = STATE_IDLE) and (ls_full_i = '0')) else '0';

ls_data               <= ls_own_response_data when (ls_own_response_we = '1') else
                         ls_from_rs_data      when (ls_from_rs_we      = '1') else
                         ls_own_result_data   when (ls_own_result_we   = '1') else
                         (others => '0');
ls_wr_en              <= ls_own_response_we or ls_from_rs_we or ls_own_result_we;

ls_data_o             <= ls_data;
ls_wr_en_o            <= ls_wr_en;

ls_own_response_we    <= '1' when (((state = STATE_RESPONSE_0) or (state = STATE_RESPONSE_1) or (state = STATE_RESPONSE_2)) and (ls_full_i = '0')) else '0';
ls_own_response_data  <= '1' & own_resp_data_reg(31 downto 24) &
                         '0' & own_resp_data_reg(23 downto 16) &
                         '0' & own_resp_data_reg(15 downto  8) &
                         '0' & own_resp_data_reg( 7 downto  0) when (state = STATE_RESPONSE_0) else
                         '0' & own_resp_data_reg(63 downto 56) &
                         '0' & own_resp_data_reg(55 downto 48) &
                         '0' & own_resp_data_reg(47 downto 40) &
                         '0' & own_resp_data_reg(39 downto 32) when (state = STATE_RESPONSE_1) else
                         '0' & own_resp_data_reg(95 downto 88) &
                         '0' & own_resp_data_reg(87 downto 80) &
                         '0' & own_resp_data_reg(79 downto 72) &
                         '0' & own_resp_data_reg(71 downto 64);-- when (state = STATE_RESPONSE_2) else

ls_own_result_we      <= '1' when (((state = STATE_RESULT_0) or (state = STATE_RESULT_1) or (state = STATE_RESULT_2) or (state = STATE_RESULT_3)) and (ls_full_i = '0')) else '0';
ls_own_result_data    <= '1' & own_result_data_reg( 31 downto  24) &
                        '0' & own_result_data_reg( 23 downto  16) &
                        '0' & own_result_data_reg( 15 downto   8) &
                        '0' & own_result_data_reg(  7 downto   0) when (state = STATE_RESULT_0) else
                        '0' & own_result_data_reg( 63 downto  56) &
                        '0' & own_result_data_reg( 55 downto  48) &
                        '0' & own_result_data_reg( 47 downto  40) &
                        '0' & own_result_data_reg( 39 downto  32) when (state = STATE_RESULT_1) else
                        '0' & own_result_data_reg( 95 downto  88) &
                        '0' & own_result_data_reg( 87 downto  80) &
                        '0' & own_result_data_reg( 79 downto  72) &
                        '0' & own_result_data_reg( 71 downto  64) when (state = STATE_RESULT_2) else
                        '0' & own_result_data_reg(127 downto 120) &
                        '0' & own_result_data_reg(119 downto 112) &
                        '0' & own_result_data_reg(111 downto 104) &
                        '0' & own_result_data_reg(103 downto  96);-- when (state = STATE_RESULT_3) else

ls_from_rs_data       <= rs_ds_fifo_fwft_din;
ls_from_rs_we         <= rs_ds_fifo_fwft_rd_en;
rs_ds_fifo_fwft_rd_en <= '1' when ((state = STATE_FROM_RIGHT) and (rs_ds_fifo_fwft_empty = '0') and (ls_full_i = '0') and (rs_read_counter /= X"0000")) else '0';

fifo_9_36_fwft_0 : fifo_9_36_fwft
port map(
  clk     => clk,
  reset_n => reset_n,

  u_rden  => rs_ds_fifo_fwft_rd_en,
  u_q     => rs_ds_fifo_fwft_din,
  u_empty => rs_ds_fifo_fwft_empty,

  f_rden  => rs_rd_en_o,
  f_q     => rs_data_i,
  f_empty => rs_empty_i
);

-- State-machine of the module
process(clk, reset_n) begin
  if (reset_n = '0') then
    state <= STATE_IDLE;
  elsif (clk = '1' and clk'event) then
    case state is
      when STATE_IDLE =>
        if(ls_full_i = '0') then
          if(m_valid = '1') then
            if(m_result_flag = '1') then
              state <= STATE_RESULT_0;
            else
              state <= STATE_RESPONSE_0;
            end if;
          elsif(rs_ds_fifo_fwft_empty = '0') then
            state <= STATE_FROM_RIGHT;
          end if;
        end if;

      when STATE_RESPONSE_0 =>
        if(ls_full_i = '0') then
          state <= STATE_RESPONSE_1;
        end if;

      when STATE_RESPONSE_1 =>
        if(ls_full_i = '0') then
          state <= STATE_RESPONSE_2;
        end if;

      when STATE_RESPONSE_2 =>
        if(ls_full_i = '0') then
          state <= STATE_IDLE;
        end if;

      when STATE_RESULT_0 =>
        if(ls_full_i = '0') then
          state <= STATE_RESULT_1;
        end if;

      when STATE_RESULT_1 =>
        if(ls_full_i = '0') then
          state <= STATE_RESULT_2;
        end if;

      when STATE_RESULT_2 =>
        if(ls_full_i = '0') then
          state <= STATE_RESULT_3;
        end if;

      when STATE_RESULT_3 =>
        if(ls_full_i = '0') then
          state <= STATE_IDLE;
        end if;

      when STATE_FROM_RIGHT =>
        if(rs_read_counter = X"0000") then
          state <= STATE_FROM_RIGHT_L0;
        end if;

      when STATE_FROM_RIGHT_L0 =>
        state <= STATE_FROM_RIGHT_L1;

      when STATE_FROM_RIGHT_L1 =>
        state <= STATE_IDLE;

      when others =>
        state <= STATE_IDLE;

    end case;
  end if;
end process;

-- Storing own response data if it is valid and state-machine is ready
process(clk, reset_n) begin
  if (reset_n = '0') then
    own_resp_data_reg <= (others => '0');
  elsif (clk = '1' and clk'event) then
    if((m_valid = '1') and (sm_rdy = '1')) then
      own_resp_data_reg <= m_data(95 downto 0);
    end if;
  end if;
end process;

-- Storing own result data if it is valid and state-machine is ready
process(clk, reset_n) begin
  if (reset_n = '0') then
    own_result_data_reg <= (others => '0');
  elsif (clk = '1' and clk'event) then
    if((m_valid = '1') and (sm_rdy = '1')) then
      own_result_data_reg <= m_data;
    end if;
  end if;
end process;

-- Counter for the right-to-left (downstream) side packet forwarding.
-- Is used in state-machine to finish forwarding.
process(clk, reset_n) begin
  if (reset_n = '0') then
    rs_read_counter <= (others => '1');
  elsif (clk = '1' and clk'event) then
    if(state = STATE_FROM_RIGHT_L1) then
      rs_read_counter <= (others => '1');
    elsif((rs_ds_fifo_fwft_rd_en = '1') and (rs_ds_fifo_fwft_din(35) = '1')) then
      rs_read_counter <= (rs_ds_fifo_fwft_din(16 downto 9) & rs_ds_fifo_fwft_din(7 downto 0));
    elsif (rs_ds_fifo_fwft_rd_en = '1') then
      rs_read_counter <= rs_read_counter - '1';
    end if;
  end if;
end process;

result_response_node_0 : result_response_node
port  map(
  clk               => clk,
  reset_n           => reset_n,
  -- Port M signals
  m_rdy_i           => m_rdy,
  m_valid_o         => m_valid,
  m_data_o          => m_data,
  m_result_flag_o   => m_result_flag,
  -- Port A signals
  result_rd_o       => own_result_rd_o,
  result_valid_i    => own_result_valid_i,
  result_data_i     => own_result_data_i,
  -- Port B signals
  response_rd_o     => own_resp_rdy_o,
  response_valid_i  => own_resp_valid_i,
  response_data_i   => own_resp_data_i
);

end rtl;
