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

----------------------------------------------------------
-- Parallel interface (transport layer) for left side   --
-- logic with FIFO interface to/from internal logic and --
-- parallel bus to/from right neighbour FPGA.           --
----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library ecp5u;
use ecp5u.components.all;

entity ls_parallel_if_sdr is
port(
  clk_fifo_if           : in    std_logic;
  clk_par_if            : in    std_logic;
  clk_par_if_ph_shift   : in    std_logic;
  reset_n               : in    std_logic;

  -- Parallel interface signals  (Connect directly to pads)
  ls_sdr_clk_lr_i       : in    std_logic;
  ls_sdr_clk_rl_o       : out   std_logic;
  ls_sdr_data_io        : inout std_logic_vector(7 downto 0);
  ls_sdr_data_type_io   : inout std_logic_vector(1 downto 0);
  ls_sdr_dir_i          : in    std_logic;
  ls_has_data_o         : out   std_logic;
  ls_ready_io           : inout std_logic;

  -- FIFO  interface signals
  ds_fifo_din_i         : in    std_logic_vector(35 downto 0);
  ds_fifo_wr_en_i       : in    std_logic;
  ds_fifo_full_o        : out   std_logic;

  us_fifo_dout_o        : out   std_logic_vector(35 downto 0);
  us_fifo_rd_en_i       : in    std_logic;
  us_fifo_empty_o       : out   std_logic
);
end ls_parallel_if_sdr;

architecture rtl of ls_parallel_if_sdr is

component fifo_parif_9_36
port (
  reset            : in  std_logic;
  rpreset          : in  std_logic;
  wrclock          : in  std_logic;
  wren             : in  std_logic;
  data             : in  std_logic_vector(8 downto 0);
  full             : out std_logic;
  almostfull       : out std_logic;
  rdclock          : in  std_logic;
  rden             : in  std_logic;
  q                : out std_logic_vector(35 downto 0);
  empty            : out std_logic
);
end component;

component fifo_parif_36_9
port (
  reset            : in  std_logic;
  rpreset          : in  std_logic;
  wrclock          : in  std_logic;
  wren             : in  std_logic;
  data             : in  std_logic_vector(35 downto 0);
  full             : out std_logic;
  almostfull       : out std_logic;
  rdclock          : in  std_logic;
  rden             : in  std_logic;
  q                : out std_logic_vector(8 downto 0);
  empty            : out std_logic
);
end component;

component fifo_synch_extend
generic (
  g_WIDTH    : natural := 9;
  g_DEPTH    : integer := 128;
  g_AF_LEVEL : integer := 80;
  g_AE_LEVEL : integer := 20
);
port (
  i_rst_sync : in std_logic;
  i_clk      : in std_logic;

  -- FIFO Write Interface
  i_wr_en   : in  std_logic;
  i_wr_data : in  std_logic_vector(g_WIDTH-1 downto 0);
  o_af      : out std_logic;
  o_full    : out std_logic;

  -- FIFO Read Interface
  i_rd_en   : in  std_logic;
  o_rd_data : out std_logic_vector(g_WIDTH-1 downto 0);
  o_ae      : out std_logic;
  o_empty   : out std_logic
);
end component;

constant STATE_STAND_UP         : std_logic_vector(7 downto 0) := X"00";
constant STATE_RECEIVE          : std_logic_vector(7 downto 0) := X"01";
constant STATE_NOP_0_0          : std_logic_vector(7 downto 0) := X"02";
constant STATE_NOP_0_1          : std_logic_vector(7 downto 0) := X"03";
constant STATE_NOP_0_2          : std_logic_vector(7 downto 0) := X"04";
constant STATE_NOP_0_3          : std_logic_vector(7 downto 0) := X"05";
constant STATE_NOP_0_4          : std_logic_vector(7 downto 0) := X"06";
constant STATE_TRANSMIT         : std_logic_vector(7 downto 0) := X"07";
constant STATE_WAIT_NOP_0_0     : std_logic_vector(7 downto 0) := X"08";
constant STATE_WAIT_NOP_0_1     : std_logic_vector(7 downto 0) := X"09";
constant STATE_SEND_TYPE_11_0   : std_logic_vector(7 downto 0) := X"0A";
constant STATE_SEND_TYPE_11_1   : std_logic_vector(7 downto 0) := X"0B";
constant STATE_WAIT_NOP_1_0     : std_logic_vector(7 downto 0) := X"0C";
constant STATE_WAIT_NOP_1_1     : std_logic_vector(7 downto 0) := X"0D";
constant STATE_WAIT_NOP_1_2     : std_logic_vector(7 downto 0) := X"0E";

constant STAND_UP_CYCLES_COUNT  : std_logic_vector(31 downto 0) := X"02FAF080"; -- 50M, 1s
--constant STAND_UP_CYCLES_COUNT  : std_logic_vector(31 downto 0) := X"00000010"; -- For simulation

constant OUTPUT_DELAY_VALUE     : integer := 24;
constant INPUT_DELAY_VALUE      : integer := 16;

signal state                    : std_logic_vector(7 downto 0);
signal state_d1                 : std_logic_vector(7 downto 0);
signal state_d2                 : std_logic_vector(7 downto 0);
signal stand_up_counter         : std_logic_vector(31 downto 0);
signal upstream_en_reg_1        : std_logic;
signal upstream_en_reg_2        : std_logic;
signal set_upstream_en_reg_ext_1: std_logic;
signal set_upstream_en_reg_ext_2: std_logic;
signal set_upstream_en_reg_int  : std_logic;

signal end_receive_reg_ext      : std_logic;
signal end_receive_reg_int_1    : std_logic;
signal end_receive_reg_int_2    : std_logic;

signal data_tri_state           : std_logic_vector(7 downto 0);
signal data_type_tri_state      : std_logic;
signal ready_tri_state          : std_logic;

signal sdr_clk_out              : std_logic;
signal sdr_clk_out_ph_shift     : std_logic;
signal sdr_data_out             : std_logic_vector(7 downto 0);
signal sdr_data_out_d           : std_logic_vector(7 downto 0);
signal sdr_data_type_out        : std_logic_vector(1 downto 0);
signal sdr_data_type_out_d      : std_logic_vector(1 downto 0);
signal sdr_valid_out            : std_logic;
signal sdr_start_packet_out     : std_logic;
signal ready_down_in            : std_logic;
signal ready_down_reg_1         : std_logic;
signal ready_down_reg_2         : std_logic;

signal sdr_data_out_d_delayed   : std_logic_vector(7 downto 0);
signal sdr_data_type_out_d_delayed : std_logic_vector(1 downto 0);

signal sdr_clk_in               : std_logic;
signal sdr_data_in              : std_logic_vector(7 downto 0);
signal sdr_data_in_d            : std_logic_vector(7 downto 0);
signal sdr_data_type_in         : std_logic_vector(1 downto 0);
signal sdr_data_type_in_d       : std_logic_vector(1 downto 0);
signal sdr_dir_in               : std_logic;
signal sdr_dir_in_d_1           : std_logic;
signal sdr_dir_in_d_2           : std_logic;
signal sdr_valid_in_d           : std_logic;
signal sdr_start_packet_in_d    : std_logic;
signal has_data_out             : std_logic;
signal has_data_out_d           : std_logic;
signal ready_up_out             : std_logic;
signal ready_up_out_d           : std_logic;

signal sdr_data_in_delayed      : std_logic_vector(7 downto 0);
signal sdr_data_type_in_delayed : std_logic_vector(1 downto 0);

signal ds_fifo_reset            : std_logic;
signal ds_fifo_rd_clk           : std_logic;
signal ds_fifo_dout             : std_logic_vector(8 downto 0);
signal ds_fifo_rd_en            : std_logic;
signal ds_fifo_rd_en_d1         : std_logic;
signal ds_fifo_rd_en_d2         : std_logic;
signal ds_fifo_empty            : std_logic;
signal ds_fifo_wr_clk           : std_logic;
signal ds_fifo_din              : std_logic_vector(35 downto 0);
signal ds_fifo_wr_en            : std_logic;
signal ds_fifo_full             : std_logic;
signal ds_fifo_afull            : std_logic;

signal us_fifo_reset            : std_logic;
signal us_fifo_rd_clk           : std_logic;
signal us_fifo_dout             : std_logic_vector(35 downto 0);
signal us_fifo_rd_en            : std_logic;
signal us_fifo_empty            : std_logic;
signal us_fifo_wr_clk           : std_logic;
signal us_fifo_din              : std_logic_vector(8 downto 0);
signal us_fifo_wr_en            : std_logic;
signal us_fifo_full             : std_logic;
signal us_fifo_afull            : std_logic;

signal synch_fifo_reset         : std_logic;
signal synch_fifo_clk           : std_logic;
signal synch_fifo_dout          : std_logic_vector(8 downto 0);
signal synch_fifo_rd_en         : std_logic;
signal synch_fifo_empty         : std_logic;
signal synch_fifo_aempty        : std_logic;
signal synch_fifo_din           : std_logic_vector(8 downto 0);
signal synch_fifo_wr_en         : std_logic;
signal synch_fifo_full          : std_logic;
signal synch_fifo_afull         : std_logic;
signal synch_counter            : std_logic_vector(1 downto 0);
signal synch_aligned            : std_logic;

signal state_is_stand_up_int    : std_logic;
signal state_is_stand_up_int_d  : std_logic;
signal state_is_stand_up_ext    : std_logic;
signal state_is_stand_up_ext_d  : std_logic;

begin

sdr_clk_out             <= clk_par_if;
sdr_clk_out_ph_shift    <= clk_par_if_ph_shift;

ready_tri_state         <= not upstream_en_reg_1;

sdr_data_out            <= ds_fifo_dout(7 downto 0);
sdr_data_type_out       <= "00" when (state = STATE_STAND_UP      ) else
                           "11" when (state = STATE_SEND_TYPE_11_0) else
                           "11" when (state = STATE_SEND_TYPE_11_1) else
                           "01" when (sdr_start_packet_out = '1'  ) else
                           "10" when (sdr_valid_out = '1'         ) else
                           "00";
sdr_valid_out           <= ds_fifo_rd_en_d2;
sdr_start_packet_out    <= sdr_valid_out and ds_fifo_dout(8);

sdr_valid_in_d          <= '1' when (((sdr_data_type_in_d = "10") or (sdr_data_type_in_d = "01")) and (upstream_en_reg_1 = '1') and (state_is_stand_up_ext_d = '0')) else '0';
sdr_start_packet_in_d   <= '1' when ((sdr_data_type_in_d = "01") and (upstream_en_reg_1 = '1') and (state_is_stand_up_ext_d = '0')) else '0';

has_data_out            <= (not ds_fifo_empty) and (not state_is_stand_up_int_d);
ready_up_out            <= (not synch_fifo_afull) and (not state_is_stand_up_ext_d);

ds_fifo_reset           <= (not reset_n) or state_is_stand_up_ext_d;
ds_fifo_rd_clk          <= sdr_clk_out;
ds_fifo_rd_en           <= '1' when ((ds_fifo_empty = '0') and (ready_down_reg_2 = '1') and (state = STATE_TRANSMIT)) else '0';
ds_fifo_wr_clk          <= clk_fifo_if;
ds_fifo_din             <= ds_fifo_din_i;
ds_fifo_wr_en           <= ds_fifo_wr_en_i;
ds_fifo_full_o          <= ds_fifo_afull;

us_fifo_reset           <= (not reset_n) or state_is_stand_up_ext_d;
us_fifo_rd_clk          <= clk_fifo_if;
us_fifo_dout_o          <= us_fifo_dout;
us_fifo_rd_en           <= us_fifo_rd_en_i;
us_fifo_empty_o         <= us_fifo_empty;
us_fifo_wr_clk          <= sdr_clk_in;
us_fifo_din             <= synch_fifo_dout when (synch_aligned = '1') else (others => '0');
us_fifo_wr_en           <= ((not us_fifo_full) and (not synch_fifo_empty)) when (synch_aligned = '1') else (not us_fifo_full);

synch_aligned           <= '0' when ((synch_counter /= "00") and (synch_fifo_dout(8) = '1')) else '1';
synch_fifo_reset        <= (not reset_n) or state_is_stand_up_ext_d;
synch_fifo_clk          <= sdr_clk_in;
synch_fifo_din          <= sdr_start_packet_in_d & sdr_data_in_d;
synch_fifo_wr_en        <= '1' when ((sdr_valid_in_d = '1') and (synch_fifo_full = '0')) else '0';
synch_fifo_rd_en        <= ((not us_fifo_full) and (not synch_fifo_empty)) when (synch_aligned = '1') else '0';

-- State-machine for left side logic
process(sdr_clk_out, reset_n)
begin
  if(reset_n = '0') then
    state    <= STATE_STAND_UP;
    state_d1 <= STATE_STAND_UP;
    state_d2 <= STATE_STAND_UP;
  elsif(sdr_clk_out = '1' and sdr_clk_out'event) then
    case state is

      when STATE_STAND_UP =>
        if(stand_up_counter = STAND_UP_CYCLES_COUNT) then
          state <= STATE_RECEIVE;
        end if;

      when STATE_RECEIVE =>
        if((end_receive_reg_int_2 = '1') and (has_data_out = '1'))then
          state <= STATE_NOP_0_0;
        end if;

      when STATE_NOP_0_0 =>
        state <= STATE_NOP_0_1;

      when STATE_NOP_0_1 =>
        state <= STATE_NOP_0_2;

      when STATE_NOP_0_2 =>
        state <= STATE_NOP_0_3;

      when STATE_NOP_0_3 =>
        state <= STATE_NOP_0_4;

      when STATE_NOP_0_4 =>
        state <= STATE_TRANSMIT;

      when STATE_TRANSMIT =>
        if(sdr_dir_in_d_2 = '1') then
          state <= STATE_WAIT_NOP_0_0;
        end if;

      when STATE_WAIT_NOP_0_0 =>
        state <= STATE_WAIT_NOP_0_1;

      when STATE_WAIT_NOP_0_1 =>
        state <= STATE_SEND_TYPE_11_0;

      when STATE_SEND_TYPE_11_0 =>
        state <= STATE_SEND_TYPE_11_1;

      when STATE_SEND_TYPE_11_1 =>
        state <= STATE_WAIT_NOP_1_0;

      when STATE_WAIT_NOP_1_0 =>
        state <= STATE_WAIT_NOP_1_1;

      when STATE_WAIT_NOP_1_1 =>
        state <= STATE_WAIT_NOP_1_2;

      when STATE_WAIT_NOP_1_2 =>
        state <= STATE_RECEIVE;

      when others =>
        state <= STATE_STAND_UP;
    end case;

    state_d1 <= state;
    state_d2 <= state_d1;

  end if;
end process;

-- Formation of control data_tri_state signal for bidirectional buffers of data bus
process(sdr_clk_out, reset_n)
begin
  if (reset_n = '0') then
    data_tri_state <= (others => '1');
  elsif (sdr_clk_out = '1' and sdr_clk_out'event) then
    if(state = STATE_RECEIVE)then
      if((end_receive_reg_int_2 = '1') and (has_data_out = '1'))then
        data_tri_state <= (others => '0');
      end if;
    elsif(state = STATE_WAIT_NOP_1_0)then
      data_tri_state <= (others => '1');
    end if;
  end if;
end process;

-- Formation of control data_type_tri_state signal for bidirectional buffers of data_type bus
process(sdr_clk_out, reset_n)
begin
  if (reset_n = '0') then
    data_type_tri_state <= '1';
  elsif (sdr_clk_out = '1' and sdr_clk_out'event) then
    if(data_type_tri_state = '0') then
      if(state = STATE_RECEIVE)then
        data_type_tri_state <= '1';
      end if;
    else
      if(state = STATE_RECEIVE)then
        if((end_receive_reg_int_2 = '1') and (has_data_out = '1'))then
          data_type_tri_state <= '0';
        end if;
      end if;
    end if;
  end if;
end process;

-- 1 clock delay of internal signals for connecting to inputs of Output/Bidirectional buffers
process(sdr_clk_out, reset_n)
begin
  if (reset_n = '0') then
    sdr_data_out_d      <= (others => '0');
    sdr_data_type_out_d <= (others => '0');
    has_data_out_d      <= '0';
  elsif (sdr_clk_out = '1' and sdr_clk_out'event) then
    sdr_data_out_d      <= sdr_data_out;
    sdr_data_type_out_d <= sdr_data_type_out;
    has_data_out_d      <= has_data_out;
  end if;
end process;

process(sdr_clk_in, reset_n)
begin
  if (reset_n = '0') then
    ready_up_out_d     <= '0';
  elsif (sdr_clk_in = '1' and sdr_clk_in'event) then
    ready_up_out_d     <= ready_up_out;
  end if;
end process;

-- 1 clock delay of outputs of Bidirectional buffers for use in internal logic
process(sdr_clk_in, reset_n)
begin
  if (reset_n = '0') then
    sdr_data_in_d      <= (others => '0');
    sdr_data_type_in_d <= (others => '0');
  elsif (sdr_clk_in = '1' and sdr_clk_in'event) then
    sdr_data_in_d      <= sdr_data_in;
    sdr_data_type_in_d <= sdr_data_type_in;
  end if;
end process;

-- 2 clock delays of outputs of input/bidirectional buffers with internal clock
-- to prevent metastability
process(sdr_clk_out, reset_n)
begin
  if (reset_n = '0') then
    ready_down_reg_1 <= '0';
    ready_down_reg_2 <= '0';
    sdr_dir_in_d_1   <= '1';
    sdr_dir_in_d_2   <= '1';
  elsif (sdr_clk_out = '1' and sdr_clk_out'event) then
    ready_down_reg_1 <= ready_down_in;
    ready_down_reg_2 <= ready_down_reg_1;
    sdr_dir_in_d_1   <= sdr_dir_in;
    sdr_dir_in_d_2   <= sdr_dir_in_d_1;
  end if;
end process;

-- 2 clock delay for downstream FIFO read-enable signal to align with its output data
process(sdr_clk_out, reset_n)
begin
  if (reset_n = '0') then
    ds_fifo_rd_en_d1    <= '0';
    ds_fifo_rd_en_d2    <= '0';
  elsif (sdr_clk_out = '1' and sdr_clk_out'event) then
    ds_fifo_rd_en_d1    <= ds_fifo_rd_en;
    ds_fifo_rd_en_d2    <= ds_fifo_rd_en_d1;
  end if;
end process;

-- Forming 2 clock cycle pulse to create same pulse on sdr_clk_in clock domain
-- This pulse is used to set "upstream enable" signal
process(sdr_clk_out, reset_n)
begin
  if (reset_n = '0') then
    set_upstream_en_reg_int <= '0';
  elsif (sdr_clk_out = '1' and sdr_clk_out'event) then
    if(state = STATE_WAIT_NOP_1_1) then
      set_upstream_en_reg_int <= '1';
    elsif(state = STATE_WAIT_NOP_1_2) then
      set_upstream_en_reg_int <= '1';
    else
      set_upstream_en_reg_int <= '0';
    end if;
  end if;
end process;

-- 2 clock cycle delay for set_upstream_en_reg_int signal to prevent metastability
process(sdr_clk_in, reset_n)
begin
  if (reset_n = '0') then
    set_upstream_en_reg_ext_1 <= '0';
    set_upstream_en_reg_ext_2 <= '0';
  elsif (sdr_clk_in = '1' and sdr_clk_in'event) then
    set_upstream_en_reg_ext_1 <= set_upstream_en_reg_int;
    set_upstream_en_reg_ext_2 <= set_upstream_en_reg_ext_1;
  end if;
end process;

-- Formation for upstream enable signal (main signal for upstream logic)
process(sdr_clk_in, reset_n)
begin
  if (reset_n = '0') then
    upstream_en_reg_1 <= '1';
    upstream_en_reg_2 <= '1';
  elsif (sdr_clk_in = '1' and sdr_clk_in'event) then
    if(upstream_en_reg_1 = '0') then
      if(set_upstream_en_reg_ext_2 = '1') then
        upstream_en_reg_1 <= '1';
      end if;
    else
      if(sdr_data_type_in_d = "11") then
        upstream_en_reg_1 <= '0';
      end if;
    end if;
    upstream_en_reg_2 <= upstream_en_reg_1;
  end if;
end process;

-- Forming 2 clock cycle pulse to indicate of finishing upstream
process(sdr_clk_in, reset_n)
begin
  if (reset_n = '0') then
    end_receive_reg_ext <= '0';
  elsif (sdr_clk_in = '1' and sdr_clk_in'event) then
    if((sdr_data_type_in_d = "11") and ((upstream_en_reg_1 = '1') or (upstream_en_reg_2 = '1'))) then
      end_receive_reg_ext <= '1';
    else
      end_receive_reg_ext <= '0';
    end if;
  end if;
end process;

-- 2 clock cycle delay for end_receive_reg_ext signal to prevent metastability
-- The pulse of this signal is used in state machine to leave RECEIVE state
process(sdr_clk_out, reset_n)
begin
  if (reset_n = '0') then
    end_receive_reg_int_1 <= '0';
    end_receive_reg_int_2 <= '0';
  elsif (sdr_clk_out = '1' and sdr_clk_out'event) then
    end_receive_reg_int_1 <= end_receive_reg_ext;
    end_receive_reg_int_2 <= end_receive_reg_int_1;
  end if;
end process;

-- Counter and flag to hold the logic in STAND-UP state
-- In this state all the signals in logic are in their default state
-- Data transmit is prevented in this state
process(sdr_clk_out, reset_n)
begin
  if (reset_n = '0') then
    stand_up_counter <= (others => '0');
    state_is_stand_up_int <= '1';
    state_is_stand_up_int_d  <= '1';
  elsif (sdr_clk_out = '1' and sdr_clk_out'event) then
    if(state = STATE_STAND_UP) then
      stand_up_counter <= stand_up_counter + '1';
      state_is_stand_up_int <= '1';
    else
      stand_up_counter <= (others => '0');
      state_is_stand_up_int <= '0';
    end if;
    state_is_stand_up_int_d <= state_is_stand_up_int;
  end if;
end process;

-- 2 clock cycle delay for state_is_stand_up_int_d signal to prevent metastability
process(sdr_clk_in, reset_n)
begin
  if (reset_n = '0') then
    state_is_stand_up_ext   <= '1';
    state_is_stand_up_ext_d <= '1';
  elsif (sdr_clk_in = '1' and sdr_clk_in'event) then
    state_is_stand_up_ext   <= state_is_stand_up_int_d;
    state_is_stand_up_ext_d <= state_is_stand_up_ext;
  end if;
end process;

-- Counter for using to synchronize upstream packets if their start packet bits are shifted
process(sdr_clk_in, reset_n)
begin
  if (reset_n = '0') then
    synch_counter <= (others => '0');
  elsif (sdr_clk_in = '1' and sdr_clk_in'event) then
    if(us_fifo_wr_en = '1') then
      synch_counter <= synch_counter + '1';
    end if;
  end if;
end process;

us_fifo_9_36_0 : fifo_parif_9_36
port map(
  reset      => us_fifo_reset,
  rpreset    => us_fifo_reset,
  wrclock    => us_fifo_wr_clk,
  wren       => us_fifo_wr_en,
  data       => us_fifo_din,
  full       => us_fifo_full,
  almostfull => us_fifo_afull,
  rdclock    => us_fifo_rd_clk,
  rden       => us_fifo_rd_en,
  q          => us_fifo_dout,
  empty      => us_fifo_empty
);

ds_fifo_36_9_0 : fifo_parif_36_9
port map(
  reset      => ds_fifo_reset,
  rpreset    => ds_fifo_reset,
  wrclock    => ds_fifo_wr_clk,
  wren       => ds_fifo_wr_en,
  data       => ds_fifo_din,
  full       => ds_fifo_full,
  almostfull => ds_fifo_afull,
  rdclock    => ds_fifo_rd_clk,
  rden       => ds_fifo_rd_en,
  q          => ds_fifo_dout,
  empty      => ds_fifo_empty
);

fifo_synch_extend_0 : fifo_synch_extend
generic map(
  g_WIDTH    => 9,
  g_DEPTH    => 128,
  g_AF_LEVEL => 80,
  g_AE_LEVEL => 20
)
port map(
  i_rst_sync => synch_fifo_reset,
  i_clk      => synch_fifo_clk,
  i_wr_en    => synch_fifo_wr_en,
  i_wr_data  => synch_fifo_din,
  o_af       => synch_fifo_afull,
  o_full     => synch_fifo_full,
  i_rd_en    => synch_fifo_rd_en,
  o_rd_data  => synch_fifo_dout,
  o_ae       => synch_fifo_aempty,
  o_empty    => synch_fifo_empty
);


delay_data_out_0 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => OUTPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_out_d(0),
    Z         => sdr_data_out_d_delayed(0)
  );

delay_data_out_1 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => OUTPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_out_d(1),
    Z         => sdr_data_out_d_delayed(1)
  );

delay_data_out_2 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => OUTPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_out_d(2),
    Z         => sdr_data_out_d_delayed(2)
  );

delay_data_out_3 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => OUTPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_out_d(3),
    Z         => sdr_data_out_d_delayed(3)
  );

delay_data_out_4 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => OUTPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_out_d(4),
    Z         => sdr_data_out_d_delayed(4)
  );

delay_data_out_5 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => OUTPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_out_d(5),
    Z         => sdr_data_out_d_delayed(5)
  );

delay_data_out_6 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => OUTPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_out_d(6),
    Z         => sdr_data_out_d_delayed(6)
  );

delay_data_out_7 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => OUTPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_out_d(7),
    Z         => sdr_data_out_d_delayed(7)
  );

delay_data_type_out_0 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => OUTPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_type_out_d(0),
    Z         => sdr_data_type_out_d_delayed(0)
  );

delay_data_type_out_1 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => OUTPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_type_out_d(1),
    Z         => sdr_data_type_out_d_delayed(1)
  );

delay_data_in_0 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => INPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_in(0),
    Z         => sdr_data_in_delayed(0)
  );

delay_data_in_1 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => INPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_in(1),
    Z         => sdr_data_in_delayed(1)
  );

delay_data_in_2 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => INPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_in(2),
    Z         => sdr_data_in_delayed(2)
  );

delay_data_in_3 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => INPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_in(3),
    Z         => sdr_data_in_delayed(3)
  );

delay_data_in_4 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => INPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_in(4),
    Z         => sdr_data_in_delayed(4)
  );

delay_data_in_5 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => INPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_in(5),
    Z         => sdr_data_in_delayed(5)
  );

delay_data_in_6 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => INPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_in(6),
    Z         => sdr_data_in_delayed(6)
  );

delay_data_in_7 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => INPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_in(7),
    Z         => sdr_data_in_delayed(7)
  );

delay_data_type_in_0 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => INPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_type_in(0),
    Z         => sdr_data_type_in_delayed(0)
  );

delay_data_type_in_1 : DELAYG
  generic map (
    DEL_MODE => "USER_DEFINED",
    DEL_VALUE => INPUT_DELAY_VALUE
  )
  port map (
    A         => sdr_data_type_in(1),
    Z         => sdr_data_type_in_delayed(1)
  );

sdr_clk_lr_ib : IB
port map (
  I => ls_sdr_clk_lr_i,
  O => sdr_clk_in
);

sdr_clk_rl_ob : OB
port map (
  O => ls_sdr_clk_rl_o,
  I => sdr_clk_out_ph_shift
);

sdr_data_0_iob : BB
port map (
  B => ls_sdr_data_io(0),
  O => sdr_data_in(0),
  I => sdr_data_out_d_delayed(0),
  T => data_tri_state(0)
);

sdr_data_1_iob : BB
port map (
  B => ls_sdr_data_io(1),
  O => sdr_data_in(1),
  I => sdr_data_out_d_delayed(1),
  T => data_tri_state(1)
);

sdr_data_2_iob : BB
port map (
  B => ls_sdr_data_io(2),
  O => sdr_data_in(2),
  I => sdr_data_out_d_delayed(2),
  T => data_tri_state(2)
);

sdr_data_3_iob : BB
port map (
  B => ls_sdr_data_io(3),
  O => sdr_data_in(3),
  I => sdr_data_out_d_delayed(3),
  T => data_tri_state(3)
);

sdr_data_4_iob : BB
port map (
  B => ls_sdr_data_io(4),
  O => sdr_data_in(4),
  I => sdr_data_out_d_delayed(4),
  T => data_tri_state(4)
);

sdr_data_5_iob : BB
port map (
  B => ls_sdr_data_io(5),
  O => sdr_data_in(5),
  I => sdr_data_out_d_delayed(5),
  T => data_tri_state(5)
);

sdr_data_6_iob : BB
port map (
  B => ls_sdr_data_io(6),
  O => sdr_data_in(6),
  I => sdr_data_out_d_delayed(6),
  T => data_tri_state(6)
);

sdr_data_7_iob : BB
port map (
  B => ls_sdr_data_io(7),
  O => sdr_data_in(7),
  I => sdr_data_out_d_delayed(7),
  T => data_tri_state(7)
);

sdr_data_type_0_iob : BB
port map (
  B => ls_sdr_data_type_io(0),
  O => sdr_data_type_in(0),
  I => sdr_data_type_out_d_delayed(0),
  T => data_type_tri_state
);

sdr_data_type_1_iob : BB
port map (
  B => ls_sdr_data_type_io(1),
  O => sdr_data_type_in(1),
  I => sdr_data_type_out_d_delayed(1),
  T => data_type_tri_state
);

sdr_dir_ib : IB
port map (
  I => ls_sdr_dir_i,
  O => sdr_dir_in
);

has_data_ob : OB
port map (
  O => ls_has_data_o,
  I => has_data_out_d
);

ready_bb : BB
port map (
  B => ls_ready_io,
  O => ready_down_in,
  I => ready_up_out_d,
  T => ready_tri_state
);

end rtl;
