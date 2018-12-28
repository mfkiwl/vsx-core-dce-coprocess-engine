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

------------------------------------------------------------------------
-- Stores query vector and sends to dc row module during calculation. --
-- Controls dc engines.                                               --
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity qv_buffer is
port(
  clk            : in  std_logic;
  reset_n        : in  std_logic;

  qv_wr_en       : in  std_logic;
  qv_wr_data     : in  std_logic_vector(31 downto 0);
  qv_first_data  : in  std_logic;
  qv_last_data   : in  std_logic;
  qv_status      : out std_logic;
  qv_id          : in  std_logic_vector(15 downto 0);
  qv_id_wr_en    : in  std_logic;

  calc_en        : in  std_logic;
  first_comp     : in  std_logic;
  last_comp      : in  std_logic;

  dc_init        : out std_logic;
  dc_enable      : out std_logic;
  dc_last        : out std_logic;

  data_bus       : out std_logic_vector(7 downto 0);

  reset_vec_cntr : in  std_logic;
  fv_counter     : in  std_logic_vector(27 downto 0);
  qv_id_out      : out std_logic_vector(15 downto 0);
  fv_index_out   : out std_logic_vector(27 downto 0);
  last_vector    : out std_logic
);
end qv_buffer;

architecture rtl of qv_buffer is

component qv_fifo_fwft
port (
  wrclock : in  std_logic;
  rdclock : in  std_logic;

  reset   : in  std_logic;
  rpreset : in  std_logic;

  wren    : in  std_logic;
  data    : in  std_logic_vector(31 downto 0);
  full    : out  std_logic;

  rden    : in  std_logic;
  q       : out  std_logic_vector(7 downto 0);
  empty   : out  std_logic
);
end component;

signal reset                 : std_logic;

signal qv_vector_rdy         : std_logic;
signal fv_finish_index       : std_logic_vector(27 downto 0);
signal start_calc            : std_logic;
signal start_calc_reg        : std_logic;
signal qv_id_reg             : std_logic_vector(15 downto 0);
signal qv_id_out_reg         : std_logic_vector(15 downto 0);
signal qv_id_out_flag        : std_logic;
signal fv_index_out_reg      : std_logic_vector(27 downto 0);
signal last_vector_reg       : std_logic;

signal fifo_wr_en            : std_logic;
signal fifo_wr_en_int        : std_logic;
signal fifo_din              : std_logic_vector(31 downto 0);
signal fifo_din_int          : std_logic_vector(31 downto 0);
signal din_index             : std_logic_vector( 1 downto 0);
signal fifo_full             : std_logic;
signal fifo_rd_en            : std_logic;
signal fifo_dout             : std_logic_vector( 7 downto 0);
signal fifo_empty            : std_logic;

signal fv_counter_reg        : std_logic_vector(27 downto 0);
signal fv_counter_eq_finish  : std_logic;

signal qv_wr_en_reg          : std_logic;
signal qv_wr_data_reg        : std_logic_vector(31 downto 0);

begin

reset <= not reset_n;

qv_fifo_fwft_0 : qv_fifo_fwft
port map(
  wrclock       => clk,
  rdclock       => clk,
  reset         => reset,
  rpreset       => reset,
  wren          => fifo_wr_en,
  data          => fifo_din,
  full          => fifo_full,
  rden          => fifo_rd_en,
  q             => fifo_dout,
  empty         => fifo_empty
);


fifo_wr_en    <= (qv_wr_en_reg and (not fifo_full)) when (qv_vector_rdy = '0') else (fifo_wr_en_int and (not fifo_full));
fifo_din      <= qv_wr_data_reg when (qv_vector_rdy = '0') else fifo_din_int;
qv_status     <= qv_vector_rdy;
fifo_rd_en    <= not fifo_empty and calc_en and start_calc;

data_bus      <= fifo_dout;

dc_init       <= first_comp and start_calc;
dc_enable     <= fifo_rd_en;
dc_last       <= last_comp and start_calc;

qv_id_out     <= qv_id_out_reg;
fv_index_out  <= fv_index_out_reg;
last_vector   <= last_vector_reg;

fv_counter_eq_finish <= '1' when (fv_counter = fv_finish_index) else '0';

-- Definition of main flag for distance calculation.
process(clk, reset_n)
begin
  if(reset_n = '0') then
    start_calc <= '0';
  elsif(clk = '1' and clk'event) then
    if((start_calc = '0') and (last_comp = '1') and ((qv_vector_rdy = '1') or (qv_id_wr_en = '1'))) then
      start_calc <= '1';
    elsif((start_calc = '1') and (last_comp = '1') and (fv_counter_eq_finish = '1')) then
      start_calc <= '0';
    end if;
  end if;
end process;

-- Shows dataset vectors IDs whose results are already calculated
process(clk, reset_n)
begin
  if(reset_n = '0') then
    fv_index_out_reg   <= (others => '0');
  elsif(clk = '1' and clk'event) then
    if(fv_counter_reg /= fv_counter) then
      fv_index_out_reg <= fv_counter_reg;
    end if;
  end if;
end process;

-- Defines last data batch calculation. Used in row best results module.
process(clk, reset_n)
begin
  if(reset_n = '0') then
    last_vector_reg <= '0';
  elsif(clk = '1' and clk'event) then
    if((last_vector_reg = '0') and (start_calc = '0') and (start_calc_reg = '1')) then
      last_vector_reg <= '1';
    end if;
    if((last_vector_reg = '1') and (fv_counter_reg /= fv_counter)) then
      last_vector_reg <= '0';
    end if;
  end if;
end process;

-- Storing Query vector ID
process(clk, reset_n)
begin
  if(reset_n = '0') then
    qv_id_reg     <= (others => '0');
  elsif(clk = '1' and clk'event) then
    if(qv_id_wr_en = '1') then
      qv_id_reg     <= qv_id;
    end if;
  end if;
end process;

-- Keeping previous Query Vector ID during current Query Vector first data batch calculation
-- Used in row best results module for sending last data batch results with correct Query Vector ID.
process(clk, reset_n)
begin
  if(reset_n = '0') then
    qv_id_out_flag <= '0';
    qv_id_out_reg  <= (others => '0');
  elsif(clk = '1' and clk'event) then
    if((start_calc = '1') and (last_comp = '1') and (qv_id_out_flag = '0')) then
      qv_id_out_flag <= '1';
      qv_id_out_reg  <= qv_id_reg;
    elsif((start_calc = '0') and (start_calc_reg = '1')) then
      qv_id_out_flag <= '0';
    end if;
  end if;
end process;

-- Defines query vector status, and uses as DC slot status in top level modules.
process(clk, reset_n)
begin
  if(reset_n = '0') then
    qv_vector_rdy <= '0';
  elsif(clk = '1' and clk'event) then
    if(qv_id_wr_en = '1') then
      qv_vector_rdy <= '1';
    elsif((start_calc = '1') and (last_comp = '1') and (fv_counter_eq_finish = '1')) then
      qv_vector_rdy <= '0';
    end if;
  end if;
end process;

-- Storing dataset ID which must be calculated last.
process(clk, reset_n)
begin
  if(reset_n = '0') then
    fv_finish_index <= (others => '1');
  elsif(clk = '1' and clk'event) then
    if(qv_id_wr_en = '1') then
      fv_finish_index <= fv_counter;
    end if;
  end if;
end process;

-- Delay of fv_counter to detect its changing (fv_counter_reg /= fv_counter)
process(clk, reset_n)
begin
  if(reset_n = '0') then
    fv_counter_reg <= (others => '0');
  elsif(clk = '1' and clk'event) then
    fv_counter_reg <= fv_counter;
  end if;
end process;

-- Delay of start_calc to detect its edges.
process(clk, reset_n)
begin
  if(reset_n = '0') then
    start_calc_reg <= '0';
  elsif(clk = '1' and clk'event) then
    start_calc_reg <= start_calc;
  end if;
end process;

-- Preparing and writing read data from FIFO.
-- This is needed for cycling reading same query vector during the whole calculation.
process(clk, reset_n)
begin
  if(reset_n = '0') then
    din_index      <= "00";
    fifo_din_int   <= (others => '0');
    fifo_wr_en_int <= '0';
  elsif(clk = '1' and clk'event) then
    fifo_wr_en_int <= '0';
    if((fifo_rd_en = '1') and (start_calc = '1') and (fv_counter_eq_finish = '0')) then
      case din_index is
      when "00" =>
        fifo_din_int( 7 downto  0) <= fifo_dout;
        din_index <= "01";
      when "01" =>
        fifo_din_int(15 downto  8) <= fifo_dout;
        din_index <= "10";
      when "10" =>
        fifo_din_int(23 downto 16) <= fifo_dout;
        din_index <= "11";
      when "11" =>
        fifo_din_int(31 downto 24) <= fifo_dout;
        din_index <= "00";
        fifo_wr_en_int <= '1';
      when others =>
      end case;
    end if;
  end if;
end process;

-- Delay of input signals. Needed for timing improvement.
process(clk, reset_n)
begin
  if(reset_n = '0') then
    qv_wr_en_reg      <= '0';
    qv_wr_data_reg    <= (others => '0');
  elsif(clk = '1' and clk'event) then
    qv_wr_en_reg      <= qv_wr_en;
    qv_wr_data_reg    <= qv_wr_data;
  end if;
end process;

end rtl;
