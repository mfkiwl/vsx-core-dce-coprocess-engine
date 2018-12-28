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

------------------------------------------------------------------------
-- Upstream packets reading from left side parallel interface module, --
-- unpacking, sending to the corresponding module and                 --
-- forwarding to the right side parallel interface module             --
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.mem_ctrl_def.all;
use work.cfg_registers_def.all;

entity command_packet_detector is
port(
  clk                   : in  std_logic;
  reset_n               : in  std_logic;

    -- 3 bit Own FPGA Addres for checking corresponding bit in Packet
  own_fpga_address_i    : in    std_logic_vector( 2 downto 0);

    -- Left Side Upstream FIFO interface signals
  ls_us_fifo_din_i      : in  std_logic_vector(35 downto 0);
  ls_us_fifo_rd_en_o    : out std_logic;
  ls_us_fifo_empty_i    : in  std_logic;

    -- Right Side Upstream FIFO interface signals
  rs_us_fifo_dout_o     : out std_logic_vector(35 downto 0);
  rs_us_fifo_wr_en_o    : out std_logic;
  rs_us_fifo_full_i     : in  std_logic;

    -- DDR3 Memory Init done
  mem_init_done_i       : in  std_logic;

    -- DDR3 Memory Write cmd user interface
  mem_wr_addr_o         : out std_logic_vector((MEM_ADDRESS_SIZE - 1) downto 0);
  mem_wr_addr_wr_en_o   : out std_logic;

    -- DDR3 Memory Write data user interface
  mem_wr_data_o         : out std_logic_vector(31 downto 0);
  mem_wr_en_o           : out std_logic;
  mem_wr_full_i         : in  std_logic;

    -- Query Vectors Writing interface
  qv_wr_en_o            : out std_logic;
  qv_wr_data_o          : out std_logic_vector(31 downto 0);
  qv_first_comp_o       : out std_logic;
  qv_last_comp_o        : out std_logic;
  qv_full_i             : in  std_logic;
  qv_id_o               : out std_logic_vector(15 downto 0);
  qv_id_wr_en_o         : out std_logic;

    -- Config Registres Writing interface
  cfg_reg_wr_en_o       : out std_logic;
  cfg_reg_wr_data_o     : out std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
  cfg_reg_wr_address_o  : out std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0);

    -- Config  Registres Read interface
  cfg_reg_rd_data_i     : in  std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
  cfg_reg_rd_address_o  : out std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0);

    -- Calculation Control Signals
  calc_reset_o          : out std_logic;
  calc_enable_o         : out std_logic;

    -- Own Results interface
  own_resp_data_o       : out std_logic_vector(95 downto 0);
  own_resp_valid_o      : out std_logic;
  own_resp_rdy_i        : in  std_logic
);
end command_packet_detector;

architecture rtl of command_packet_detector is

constant STATE_IDLE                 : std_logic_vector(3 downto 0) := X"0";
constant STATE_WRITE_REG            : std_logic_vector(3 downto 0) := X"1";
constant STATE_READ_REG             : std_logic_vector(3 downto 0) := X"2";
constant STATE_MEM_WR_ADDR          : std_logic_vector(3 downto 0) := X"3";
constant STATE_MEM_WR_DATA          : std_logic_vector(3 downto 0) := X"4";
constant STATE_CALC_START           : std_logic_vector(3 downto 0) := X"5";
constant STATE_CALC_STOP            : std_logic_vector(3 downto 0) := X"6";
constant STATE_CALC_RESET           : std_logic_vector(3 downto 0) := X"7";
constant STATE_SEND_QV              : std_logic_vector(3 downto 0) := X"8";
constant STATE_GET_TR_ID_CRC        : std_logic_vector(3 downto 0) := X"9";
constant STATE_SEND_RESPONSE        : std_logic_vector(3 downto 0) := X"A";

constant MEM_READ_STATE_IDLE        : std_logic_vector(3 downto 0) := X"0";
constant MEM_READ_STATE_ADDRESS     : std_logic_vector(3 downto 0) := X"2";
constant MEM_READ_STATE_DATA        : std_logic_vector(3 downto 0) := X"4";
constant MEM_READ_STATE_PID_CRC     : std_logic_vector(3 downto 0) := X"5";

constant CMD_WRITE_REG              : std_logic_vector(7 downto 0) := X"01";
constant CMD_READ_REG               : std_logic_vector(7 downto 0) := X"02";
constant CMD_WRITE_MEM              : std_logic_vector(7 downto 0) := X"03";
constant CMD_CALC_START             : std_logic_vector(7 downto 0) := X"05";
constant CMD_CALC_STOP              : std_logic_vector(7 downto 0) := X"06";
constant CMD_CALC_RESET             : std_logic_vector(7 downto 0) := X"07";
constant CMD_SEND_QV                : std_logic_vector(7 downto 0) := X"08";

signal state                        : std_logic_vector(3 downto 0);
signal ls_us_fifo_din               : std_logic_vector(31 downto 0);
signal own_fpga_address_reg         : std_logic_vector(2 downto 0);
signal own_fpga_select              : std_logic_vector(6 downto 0);
signal own_fpga_is_selected         : std_logic;
signal start_packet                 : std_logic;
signal command_id                   : std_logic_vector(7 downto 0);
signal command_id_reg               : std_logic_vector(7 downto 0);
signal packet_length_reg            : std_logic_vector(15 downto 0);
signal own_resp_valid_reg           : std_logic;
signal ready_to_read                : std_logic;
signal cfg_reg_address_reg          : std_logic_vector(15 downto 0);
signal transaction_id_reg           : std_logic_vector(15 downto 0);
signal packet_crc_reg               : std_logic_vector(15 downto 0);
signal qv_wr_count_reg              : std_logic_vector(15 downto 0);
signal calc_enable_reg              : std_logic;
signal calc_reset_reg               : std_logic;
signal calc_reset_counter_reg       : std_logic_vector( 3 downto 0);
signal cfg_reg_wr_response          : std_logic_vector(95 downto 0);
signal cfg_reg_rd_response          : std_logic_vector(95 downto 0);
signal mem_wr_response              : std_logic_vector(95 downto 0);
signal calc_start_response          : std_logic_vector(95 downto 0);
signal calc_stop_response           : std_logic_vector(95 downto 0);
signal calc_reset_response          : std_logic_vector(95 downto 0);
signal send_qv_response             : std_logic_vector(95 downto 0);
signal mem_wr_count_reg             : std_logic_vector(15 downto 0);

signal ls_us_fifo_fwft_din          : std_logic_vector(35 downto 0);
signal ls_us_fifo_fwft_rd_en        : std_logic;
signal ls_us_fifo_fwft_empty        : std_logic;

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

rs_us_fifo_dout_o           <= ls_us_fifo_fwft_din;
rs_us_fifo_wr_en_o          <= ls_us_fifo_fwft_rd_en;

ls_us_fifo_din              <= ls_us_fifo_fwft_din(34 downto 27) &
                               ls_us_fifo_fwft_din(25 downto 18) &
                               ls_us_fifo_fwft_din(16 downto  9) &
                               ls_us_fifo_fwft_din( 7 downto  0);

ready_to_read               <= '1' when ((ls_us_fifo_fwft_empty    = '0') and
                                         (rs_us_fifo_full_i        = '0') and
                                         (qv_full_i                = '0') and
                                         (calc_reset_reg           = '0'))
                                else '0';

start_packet                <= '1' when (ls_us_fifo_fwft_rd_en = '1') and
                                        (ls_us_fifo_fwft_din(35) = '1') else '0';

own_fpga_is_selected        <= '1' when ((own_fpga_select and ls_us_fifo_din(30 downto 24)) /= "0000000") else '0';

command_id                  <= ls_us_fifo_din(23 downto 16);

ls_us_fifo_fwft_rd_en       <= '1' when ((ready_to_read = '1') and (state /= STATE_SEND_RESPONSE)) else '0';

mem_wr_addr_o               <= ls_us_fifo_din(28 downto 0);
mem_wr_addr_wr_en_o         <= '1' when ((state = STATE_MEM_WR_ADDR) and (ready_to_read = '1')) else '0';

mem_wr_data_o( 7 downto  0) <= ls_us_fifo_din(31 downto 24);
mem_wr_data_o(15 downto  8) <= ls_us_fifo_din(23 downto 16);
mem_wr_data_o(23 downto 16) <= ls_us_fifo_din(15 downto  8);
mem_wr_data_o(31 downto 24) <= ls_us_fifo_din( 7 downto  0);
mem_wr_en_o                 <= '1' when ((state = STATE_MEM_WR_DATA) and (ready_to_read = '1')) else '0';

qv_wr_data_o( 7 downto  0)  <= ls_us_fifo_din(31 downto 24);
qv_wr_data_o(15 downto  8)  <= ls_us_fifo_din(23 downto 16);
qv_wr_data_o(23 downto 16)  <= ls_us_fifo_din(15 downto  8);
qv_wr_data_o(31 downto 24)  <= ls_us_fifo_din( 7 downto  0);
qv_wr_en_o                  <= '1' when ((state = STATE_SEND_QV) and (ready_to_read = '1')) else '0';
qv_first_comp_o             <= '1' when ((state = STATE_SEND_QV) and (ready_to_read = '1') and (qv_wr_count_reg = X"0002")) else '0';
qv_last_comp_o              <= '1' when ((state = STATE_SEND_QV) and (ready_to_read = '1') and (qv_wr_count_reg = packet_length_reg)) else '0';
qv_id_o                     <= ls_us_fifo_din(31 downto 16);
qv_id_wr_en_o               <= '1' when ((state = STATE_GET_TR_ID_CRC) and (ready_to_read = '1') and (command_id_reg = CMD_SEND_QV)) else '0';

cfg_reg_wr_data_o           <= ls_us_fifo_din(15 downto 0);
cfg_reg_wr_address_o        <= ls_us_fifo_din(31 downto 16);
cfg_reg_wr_en_o             <= '1' when ((state = STATE_WRITE_REG) and (ready_to_read = '1')) else '0';

cfg_reg_rd_address_o        <= cfg_reg_address_reg;

calc_enable_o               <= calc_enable_reg;
calc_reset_o                <= calc_reset_reg;

own_resp_data_o             <= cfg_reg_wr_response when (command_id_reg = CMD_WRITE_REG ) else
                               cfg_reg_rd_response when (command_id_reg = CMD_READ_REG  ) else
                               mem_wr_response     when (command_id_reg = CMD_WRITE_MEM ) else
                               calc_start_response when (command_id_reg = CMD_CALC_START) else
                               calc_stop_response  when (command_id_reg = CMD_CALC_STOP ) else
                               calc_reset_response when (command_id_reg = CMD_CALC_RESET) else
                               send_qv_response    when (command_id_reg = CMD_SEND_QV   ) else
                               (others => '0');

cfg_reg_wr_response         <= transaction_id_reg & packet_crc_reg &
                               cfg_reg_address_reg & cfg_reg_rd_data_i &
                               '0' & own_fpga_select & CMD_WRITE_REG & X"0002";

cfg_reg_rd_response         <= transaction_id_reg & packet_crc_reg &
                               cfg_reg_address_reg & cfg_reg_rd_data_i &
                               '0' & own_fpga_select & CMD_READ_REG & X"0002";

mem_wr_response             <= transaction_id_reg & packet_crc_reg &
                               packet_length_reg & X"0000" &
                               '0' & own_fpga_select & CMD_WRITE_MEM & X"0002";

calc_start_response         <= transaction_id_reg & packet_crc_reg &
                               X"00000000" &
                               '0' & own_fpga_select & CMD_CALC_START & X"0002";

calc_stop_response          <= transaction_id_reg & packet_crc_reg &
                               X"00000000" &
                               '0' & own_fpga_select & CMD_CALC_STOP & X"0002";

calc_reset_response         <= transaction_id_reg & packet_crc_reg &
                               X"00000000" &
                               '0' & own_fpga_select & CMD_CALC_RESET & X"0002";

send_qv_response            <= transaction_id_reg & packet_crc_reg &
                               packet_length_reg & X"0000" &
                               '0' & own_fpga_select & CMD_SEND_QV & X"0002";

own_resp_valid_o            <= own_resp_valid_reg;

fifo_9_36_fwft_0 : fifo_9_36_fwft
port map(
  clk     => clk,
  reset_n => reset_n,

  u_rden  => ls_us_fifo_fwft_rd_en,
  u_q     => ls_us_fifo_fwft_din,
  u_empty => ls_us_fifo_fwft_empty,

  f_rden  => ls_us_fifo_rd_en_o,
  f_q     => ls_us_fifo_din_i,
  f_empty => ls_us_fifo_empty_i
);

-- State machine of the module
process(clk, reset_n) begin
  if (reset_n = '0') then
    state <= STATE_IDLE;
    mem_wr_count_reg <= (others => '0');
    qv_wr_count_reg  <= (others => '0');
  elsif (clk = '1' and clk'event) then
    case state is
      when STATE_IDLE =>
        if((start_packet = '1') and (own_fpga_is_selected = '1')) then
          case command_id is
            when CMD_WRITE_REG =>
              state <= STATE_WRITE_REG;
            when CMD_READ_REG =>
              state <= STATE_READ_REG;
            when CMD_WRITE_MEM =>
              state <= STATE_MEM_WR_ADDR;
            when CMD_CALC_START =>
              state <= STATE_CALC_START;
            when CMD_CALC_STOP =>
              state <= STATE_CALC_STOP;
            when CMD_CALC_RESET =>
              state <= STATE_CALC_RESET;
            when CMD_SEND_QV =>
              qv_wr_count_reg <= X"0002";
              state <= STATE_SEND_QV;
            when others =>
          end case;
        end if;

      when STATE_WRITE_REG =>
        if(ready_to_read = '1') then
          state <= STATE_GET_TR_ID_CRC;
        end if;

      when STATE_READ_REG =>
        if(ready_to_read = '1') then
          state <= STATE_GET_TR_ID_CRC;
        end if;

      when STATE_MEM_WR_ADDR =>
        if(ready_to_read = '1') then
          state <= STATE_MEM_WR_DATA;
          mem_wr_count_reg <= X"0003";
        end if;

      when STATE_MEM_WR_DATA =>
        if(ready_to_read = '1') then
          if(packet_length_reg = mem_wr_count_reg) then
            state <= STATE_GET_TR_ID_CRC;
          else
            mem_wr_count_reg <= mem_wr_count_reg + 1;
          end if;
        end if;

      when STATE_CALC_START =>
        if(ready_to_read = '1') then
          state <= STATE_GET_TR_ID_CRC;
        end if;

      when STATE_CALC_STOP =>
        if(ready_to_read = '1') then
          state <= STATE_GET_TR_ID_CRC;
        end if;

      when STATE_CALC_RESET =>
        if(ready_to_read = '1') then
          state <= STATE_GET_TR_ID_CRC;
        end if;

      when STATE_SEND_QV =>
        if(ready_to_read = '1') then
          if(packet_length_reg = qv_wr_count_reg) then
            state <= STATE_GET_TR_ID_CRC;
          else
            qv_wr_count_reg <= qv_wr_count_reg + 1;
          end if;
        end if;

      when STATE_GET_TR_ID_CRC =>
        if(ready_to_read = '1') then
          state <= STATE_SEND_RESPONSE;
        end if;

      when STATE_SEND_RESPONSE =>
        if((own_resp_valid_reg = '1') and (own_resp_rdy_i = '1')) then
          state <= STATE_IDLE;
        end if;

      when others =>
        state <= STATE_IDLE;

    end case;
  end if;
end process;

-- Storing packet length and command.
-- These are used during packet unpacking.
process(clk, reset_n)
begin
  if (reset_n = '0') then
    packet_length_reg <= (others => '0');
    command_id_reg    <= (others => '0');
  elsif (clk = '1' and clk'event) then
    if(start_packet = '1') then
      packet_length_reg <= ls_us_fifo_din(15 downto  0);
      command_id_reg    <= command_id;
    end if;
  end if;
end process;

-- Forming flag which shows that command packet execution is finished
-- and response is valid.
process(clk, reset_n)
begin
  if (reset_n = '0') then
    own_resp_valid_reg <= '0';
  elsif (clk = '1' and clk'event) then
    if((state = STATE_GET_TR_ID_CRC) and (ready_to_read = '1')) then
      own_resp_valid_reg <= '1';
    elsif((own_resp_valid_reg = '1') and (own_resp_rdy_i = '1')) then
      own_resp_valid_reg <= '0';
    end if;
  end if;
end process;

-- Getting and storing register read/write address when corresponding command is received.
process(clk, reset_n)
begin
  if (reset_n = '0') then
    cfg_reg_address_reg <= (others => '0');
  elsif (clk = '1' and clk'event) then
    if(((state = STATE_WRITE_REG) or (state = STATE_READ_REG)) and (ready_to_read = '1')) then
      cfg_reg_address_reg <= ls_us_fifo_din(31 downto 16);
    end if;
  end if;
end process;

-- Storing transaction ID (Which will be the same in the response)
-- and packet CRC (CRC checking not implemented)
process(clk, reset_n)
begin
  if (reset_n = '0') then
    transaction_id_reg <= (others => '0');
    packet_crc_reg     <= (others => '0');
  elsif (clk = '1' and clk'event) then
    if((state = STATE_GET_TR_ID_CRC) and (ready_to_read = '1')) then
      transaction_id_reg <= ls_us_fifo_din(31 downto 16);
      packet_crc_reg     <= ls_us_fifo_din(15 downto  0);
    end if;
  end if;
end process;

-- Forming Calculation Enable and Calculation Reset outputs
-- when corresponding commands are received.
process(clk, reset_n)
begin
  if (reset_n = '0') then
    calc_enable_reg <= '0';
    calc_reset_reg  <= '0';
    calc_reset_counter_reg <= (others => '0');
  elsif (clk = '1' and clk'event) then

    if((state = STATE_CALC_START) and (ready_to_read = '1')) then
      calc_enable_reg <= '1';
    end if;

    if((state = STATE_CALC_STOP) and (ready_to_read = '1')) then
      calc_enable_reg <= '0';
    end if;

    if(calc_reset_reg = '1') then
      if(calc_reset_counter_reg = X"F") then
        calc_reset_reg <= '0';
        calc_reset_counter_reg <= (others => '0');
      else
        calc_reset_counter_reg <= calc_reset_counter_reg + '1';
      end if;
    elsif((state = STATE_CALC_RESET) and (ready_to_read = '1')) then
      calc_reset_reg <= '1';
      calc_enable_reg <= '0';
    end if;

  end if;
end process;

-- Current FPGA address field used in Response packet.
process(clk, reset_n)
begin
  if (reset_n = '0') then
    own_fpga_address_reg <= (others => '0');
    own_fpga_select      <= (others => '0');
  elsif (clk = '1' and clk'event) then
    own_fpga_address_reg <= own_fpga_address_i;
    case own_fpga_address_reg is
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
