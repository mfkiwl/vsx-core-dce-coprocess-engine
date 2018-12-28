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

----------------------------------------------------
-- Includes standard FIFO, Extended smal FIFO and --
-- changes standard FIFO interface to             --
-- First Word Fall Through FIFO interface         --
----------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity qv_fifo_fwft is
port(
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
end qv_fifo_fwft;

architecture rtl of qv_fifo_fwft is

component qv_fifo
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

component qv_extender_fifo_fwft
  generic (
    constant DATA_WIDTH  : positive := 32;
    constant FIFO_DEPTH  : positive := 4
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    writeen : in  std_logic;
    datain  : in  std_logic_vector (DATA_WIDTH - 1 downto 0);
    readen  : in  std_logic;
    dataout : out std_logic_vector (DATA_WIDTH - 1 downto 0);
    empty   : out std_logic;
    full    : out std_logic
  );
end component;

signal fifo_valid         : std_logic;
signal middle_valid       : std_logic;
signal dout_valid         : std_logic;
signal dout               : std_logic_vector(7 downto 0);
signal middle_dout        : std_logic_vector(7 downto 0);
signal fifo_dout          : std_logic_vector(7 downto 0);
signal fifo_empty         : std_logic;
signal fifo_rd_en         : std_logic;
signal will_update_middle : std_logic;
signal will_update_dout   : std_logic;

signal extender_dout      : std_logic_vector(31 downto 0);
signal extender_empty     : std_logic;
signal extender_rden      : std_logic;

signal fifo_din           : std_logic_vector(31 downto 0);
signal fifo_full          : std_logic;
signal fifo_wren          : std_logic;

begin

will_update_middle <= fifo_valid when (middle_valid = will_update_dout) else '0';
will_update_dout   <= (middle_valid or fifo_valid) and (rden or (not dout_valid));
fifo_rd_en         <= (not fifo_empty) and (not(middle_valid and dout_valid and fifo_valid));
empty              <= not dout_valid;

q                  <= dout;

extender_rden      <= (not extender_empty) and (not fifo_full);

fifo_wren          <= extender_rden;
fifo_din           <= extender_dout;

-- First word fall through conversion logic
process(rdclock, reset)
begin
  if(reset = '1') then
    fifo_valid   <= '0';
    middle_valid <= '0';
    dout_valid   <= '0';
    dout         <= (others => '0');
    middle_dout  <= (others => '0');
  elsif(rdclock = '1' and rdclock'event) then
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
    elsif (rden = '1') then
      dout_valid <= '0';
    end if;
  end if;
end process;


qv_fifo_0 : qv_fifo
port map(
  wrclock => wrclock,
  rdclock => rdclock,
  reset   => reset,
  rpreset => rpreset,
  wren    => fifo_wren,
  data    => fifo_din,
  full    => fifo_full,
  rden    => fifo_rd_en,
  q       => fifo_dout,
  empty   => fifo_empty
);

qv_extender_fifo_fwft_0 : qv_extender_fifo_fwft
port map(
  clk     => wrclock,
  rst     => reset,
  writeen => wren,
  datain  => data,
  readen  => extender_rden,
  dataout => extender_dout,
  empty   => extender_empty,
  full    => full
);

end rtl;
