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

-------------------------------------------------
-- Input buffers for "Own FPGA Address" inputs --
-------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library ecp5u;
use ecp5u.components.all;

entity own_fpga_addr_buf is
port(
  own_fpga_address_in_i  : in  std_logic_vector( 2 downto 0);
  own_fpga_address_out_o : out std_logic_vector( 2 downto 0)
);
end own_fpga_addr_buf;

architecture rtl of own_fpga_addr_buf is

begin

own_fpga_addr_buf_0 : IB
port map (
  I => own_fpga_address_in_i(0),
  O => own_fpga_address_out_o(0)
);

own_fpga_addr_buf_1 : IB
port map (
  I => own_fpga_address_in_i(1),
  O => own_fpga_address_out_o(1)
);

own_fpga_addr_buf_2 : IB
port map (
  I => own_fpga_address_in_i(2),
  O => own_fpga_address_out_o(2)
);

end rtl;
