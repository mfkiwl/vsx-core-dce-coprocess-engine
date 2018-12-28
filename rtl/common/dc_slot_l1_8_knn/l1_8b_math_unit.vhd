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

---------------------------------------------------------------------------
-- Calculating and accumulating L1 distance with 1 Byte component length --
---------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.dc_slot_def.all;

entity l1_8b_math_unit is
port (
  clk      : in  std_logic;

  init_i   : in  std_logic;
  enable_i : in  std_logic;
  data_i   : in  std_logic_vector( 7 downto 0);
  ram_i    : in  std_logic_vector( 7 downto 0);
  result_o : out std_logic_vector((DISTANCE_SIZE - 1) downto 0)
);
end l1_8b_math_unit;

architecture rtl of l1_8b_math_unit is

component abs_adder
port (
  dataa   : in  std_logic_vector(7 downto 0);
  datab   : in  std_logic_vector(7 downto 0);
  clock   : in  std_logic;
  reset   : in  std_logic;
  clocken : in  std_logic;
  cin     : in  std_logic;
  result  : out std_logic_vector(7 downto 0)
);
end component;

component acc_adder
port (
  dataa   : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  datab   : in  std_logic_vector((DISTANCE_SIZE - 1) downto 0);
  clock   : in  std_logic;
  reset   : in  std_logic;
  clocken : in  std_logic;
  result  : out std_logic_vector((DISTANCE_SIZE - 1) downto 0)
);
end component;

component comparator_8
port(
  DataA : in  std_logic_vector(7 downto 0);
  DataB : in  std_logic_vector(7 downto 0);
  AGEB  : out std_logic
);
end component;

signal init       : std_logic;
signal enable     : std_logic;
signal enable_reg : std_logic;
signal data       : std_logic_vector( 7 downto 0);
signal ram        : std_logic_vector( 7 downto 0);
signal ram_n      : std_logic_vector( 7 downto 0);
signal cin        : std_logic;
signal cin_reg    : std_logic;
signal abs_result : std_logic_vector( 7 downto 0);
signal acc_in     : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal result     : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal data_b     : std_logic_vector((DISTANCE_SIZE - 1) downto 0);
signal init_reg   : std_logic;

begin

init     <= init_i;
enable   <= enable_i;
data     <= data_i;
ram      <= ram_i;
ram_n    <= not ram;
result_o <= result;
data_b   <= (others => '0') when init_reg = '1' else result;
acc_in   <= ("000000000000" & abs_result) when (cin_reg = '1') else ("000000000000" & (not abs_result));

comparator_8_0 : comparator_8
port map(
  DataA => data,
  DataB => ram,
  AGEB  => cin
);

abs_adder_0 : abs_adder
port map(
  clock   => clk,
  reset   => '0',
  clocken => enable,
  dataa   => data,
  datab   => ram_n,
  cin     => cin,
  result  => abs_result
);

acc_adder_0 : acc_adder
port map(
  clock   => clk,
  reset   => '0',
  clocken => enable_reg,
  dataa   => acc_in,
  datab   => data_b,
  result  => result
);

-- Delays of input ports (for timing improvement)
process(clk)
begin
  if(clk = '1' and clk'event) then
    enable_reg <= enable;
    init_reg   <= init;
    cin_reg    <= cin;
  end if;
end process;

end rtl;
