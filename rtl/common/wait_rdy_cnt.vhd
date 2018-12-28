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

-----------------------------------------------------------
-- Pause reading from memory controller and              --
-- distance calculation when vector length is too short. --
-- It is done to give extra time for results sorting.    --
-----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.cfg_registers_def.all;

entity wait_rdy_cnt is
port(
  clk          : in  std_logic;
  reset_n      : in  std_logic;
  fv_length    : in  std_logic_vector((DSV_LENGTH_SIZE     - 1) downto 0);
  last_comp    : in  std_logic;
  rd_en        : out std_logic
);
end wait_rdy_cnt;

architecture rtl of wait_rdy_cnt is

signal wait_cycle_cnt      : std_logic_vector(11 downto 0);
signal counter             : std_logic_vector(11 downto 0);
signal rd_en_reg           : std_logic;

begin

rd_en <= rd_en_reg;

-- Checks vector length and decides number of clock cycles to pause.
  process(clk, reset_n) begin
    if(reset_n = '0') then
      wait_cycle_cnt <= (others => '0');
    elsif(clk = '1' and clk'event) then
      if(fv_length((DSV_LENGTH_SIZE - 1) downto 7) = "00000") then
        wait_cycle_cnt <= "000001111111";
      else
        wait_cycle_cnt <= (others => '0');
      end if;
    end if;
  end process;

-- Countdown counter
  process(clk, reset_n) begin
    if(reset_n = '0') then
      counter <= (others => '0');
    elsif(clk = '1' and clk'event) then
      if(rd_en_reg = '1') then
        counter <= wait_cycle_cnt;
      else
        counter <= counter - '1';
      end if;
    end if;
  end process;

-- Definition of read enable signal which is output and is used for reading (and pausing) dataset vectors.
  process(clk, reset_n) begin
    if(reset_n = '0') then
      rd_en_reg <= '1';
    elsif(clk = '1' and clk'event) then
      if(wait_cycle_cnt /= "000000000000") then
        if(last_comp = '1') then
          rd_en_reg <= '0';
        elsif (counter = "000000000000") then
          rd_en_reg <= '1';
        end if;
      else
        rd_en_reg <= '1';
      end if;
    end if;
  end process;

end rtl;

