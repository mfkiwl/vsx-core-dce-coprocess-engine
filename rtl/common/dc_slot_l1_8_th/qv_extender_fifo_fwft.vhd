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

-------------------------------------------------
-- Small FIFO for extending query vectors FIFO --
-------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity qv_extender_fifo_fwft is
  generic (
    constant DATA_WIDTH  : positive := 32;
    constant FIFO_DEPTH  : positive := 8
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
end qv_extender_fifo_fwft;

architecture rtl of qv_extender_fifo_fwft is

begin

  fifo_proc : process (clk)
    type fifo_memory is array (0 to FIFO_DEPTH - 1) of STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
    variable memory : fifo_memory;

    variable head : natural range 0 to FIFO_DEPTH - 1;
    variable tail : natural range 0 to FIFO_DEPTH - 1;

    variable looped : boolean;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        head := 0;
        tail := 0;

        looped := false;

        full  <= '0';
        empty <= '1';
      else
        if (readen = '1') then
          if ((looped = true) or (head /= tail)) then
            if (tail = FIFO_DEPTH - 1) then
              tail := 0;
              looped := false;
            else
              tail := tail + 1;
            end if;
          end if;
        end if;

        if (writeen = '1') then
          if ((looped = false) or (head /= tail)) then
            memory(head) := datain;

            if (head = FIFO_DEPTH - 1) then
              head := 0;

              looped := true;
            else
              head := head + 1;
            end if;
          end if;
        end if;

        dataout <= memory(tail);

        if (head = tail) then
          if looped then
            full <= '1';
          else
            empty <= '1';
          end if;
        else
          empty  <= '0';
          full  <= '0';
        end if;
      end if;
    end if;
  end process;

end rtl;
