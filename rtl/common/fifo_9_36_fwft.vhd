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

--------------------------------------------------------------------------------
-- Converts standard FIFO interface to First Word Fall Through FIFO interface --
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity fifo_9_36_fwft is
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
end fifo_9_36_fwft;

architecture rtl of fifo_9_36_fwft is


signal fifo_valid         : std_logic;
signal middle_valid       : std_logic;
signal dout_valid         : std_logic;
signal dout               : std_logic_vector(35 downto 0);
signal middle_dout        : std_logic_vector(35 downto 0);
signal fifo_dout          : std_logic_vector(35 downto 0);
signal fifo_empty         : std_logic;
signal fifo_rd_en         : std_logic;
signal will_update_middle : std_logic;
signal will_update_dout   : std_logic;

begin

fifo_dout          <= f_q;
fifo_empty         <= f_empty;
f_rden             <= fifo_rd_en;

will_update_middle <= fifo_valid when (middle_valid = will_update_dout) else '0';
will_update_dout   <= (middle_valid or fifo_valid) and (u_rden or (not dout_valid));
fifo_rd_en         <= (not fifo_empty) and (not(middle_valid and dout_valid and fifo_valid));
u_empty            <= not dout_valid;

u_q                <= dout;

-- First word fall through conversion logic
process(clk, reset_n)
begin
  if(reset_n = '0') then
    fifo_valid   <= '0';
    middle_valid <= '0';
    dout_valid   <= '0';
    dout         <= (others => '0');
    middle_dout  <= (others => '0');
  elsif(clk = '1' and clk'event) then
    if (will_update_middle = '1') then
      middle_dout <= fifo_dout;
    end if;

    if(will_update_dout = '1') then
      if(middle_valid = '1') then
        dout <= middle_dout;
      else
        dout <= fifo_dout;
      end if;
    end if;

    if(fifo_rd_en = '1') then
      fifo_valid <= '1';
    elsif ((will_update_middle or will_update_dout) = '1') then
      fifo_valid <= '0';
    end if;

    if(will_update_middle = '1') then
      middle_valid <= '1';
    elsif (will_update_dout = '1') then
      middle_valid <= '0';
    end if;

    if(will_update_dout = '1') then
      dout_valid <= '1';
    elsif (u_rden = '1') then
      dout_valid <= '0';
    end if;
  end if;
end process;

end rtl;
