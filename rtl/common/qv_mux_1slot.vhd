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

---------------------------------------------
-- Finds first free DC slot                --
-- Contains in dc_slots_array_1slot module --
---------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity qv_mux is
port(
  clk           : in  std_logic;
  reset_n       : in  std_logic;

  wr_en_i       : in  std_logic;
  id_wr_en_i    : in  std_logic;
  first_data_i  : in  std_logic;
  last_data_i   : in  std_logic;
  full_o        : out std_logic;
  qv_valid_o    : out std_logic;

  wr_en_00_o    : out std_logic;

  id_wr_en_00_o : out std_logic;

  status_00_i  : in  std_logic
);
end qv_mux;

architecture rtl of qv_mux is

signal one_qv_valid    : std_logic;
signal status_or       : std_logic;
signal status_and      : std_logic;
signal all_qv_valid    : std_logic;
signal id_wr_en_reg    : std_logic;

begin

full_o     <= all_qv_valid;
qv_valid_o <= one_qv_valid;

wr_en_00_o <= wr_en_i;

id_wr_en_00_o <= id_wr_en_i;

status_or <= status_00_i;

status_and <= status_00_i;

process(clk, reset_n)
begin
  if(reset_n = '0') then
    id_wr_en_reg    <= '0';
  elsif(clk = '1' and clk'event) then
    id_wr_en_reg    <= id_wr_en_i;
  end if;
end process;

-- Forming flag showing that at least one DC Slot is full.
-- If one_qv_valid = '0' then dataset vectors reading stops.
process(clk, reset_n)
begin
  if(reset_n = '0') then
    one_qv_valid   <= '0';
  elsif(clk = '1' and clk'event) then
    one_qv_valid   <= status_or;
  end if;
end process;

-- Forming flag showing that all DC Slot are full.
-- If all_qv_valid = '1' then packet reading from left hand side stops.
process(clk, reset_n)
begin
  if(reset_n = '0') then
    all_qv_valid <= '0';
  elsif(clk = '1' and clk'event) then
    if((id_wr_en_reg = '1') and (status_and = '1'))then
      all_qv_valid <= '1';
    elsif((all_qv_valid = '1') and (status_and = '0'))then
      all_qv_valid <= '0';
    end if;
  end if;
end process;

end rtl;
