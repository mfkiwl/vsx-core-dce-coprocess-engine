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

--------------------------------------------------------------------------
-- Configuration, status and information registers read/write interface --
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library ecp5u;
use ecp5u.components.all;
use work.cfg_registers_def.all;
use work.dc_slot_def.all;

entity cfg_registers is
port(
  clk                    : in  std_logic;
  reset_n                : in  std_logic;

  status_i               : in  std_logic_vector(15 downto 0);

  -- Registers Writing interface
  wr_en_i                : in  std_logic;
  wr_data_i              : in  std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
  wr_address_i           : in  std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0);

  -- Registers Read interface
  rd_data_o              : out std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
  rd_address_i           : in  std_logic_vector((REG_IF_ADDRESS_SIZE - 1) downto 0);

  -- Configuration outputs
  threshold_o            : out std_logic_vector((DISTANCE_SIZE - 1)       downto 0);
  knn_num_o              : out std_logic_vector((KNN_NUM_SIZE        - 1) downto 0);
  dsv_count_o            : out std_logic_vector((DSV_COUNT_HI_SIZE + DSV_COUNT_LO_SIZE - 1) downto 0);
  dsv_length_o           : out std_logic_vector((DSV_LENGTH_SIZE     - 1) downto 0);

  temperature_o          : out std_logic_vector(5 downto 0)
);
end cfg_registers;


architecture rtl of cfg_registers is

constant DTR_PULSE_CYCLE_COUNT : std_logic_vector(31 downto 0) := X"01312D00"; -- 20M Cycles = 200 ms

signal rtl_version_reg        : std_logic_vector((RTL_VERSION_SIZE       - 1) downto 0);
signal threshold_lo_reg       : std_logic_vector((THRESHOLD_LO_SIZE      - 1) downto 0);
signal threshold_hi_reg       : std_logic_vector((THRESHOLD_HI_SIZE      - 1) downto 0);
signal dsv_count_lo_reg       : std_logic_vector((DSV_COUNT_LO_SIZE      - 1) downto 0);
signal dsv_count_hi_reg       : std_logic_vector((DSV_COUNT_HI_SIZE      - 1) downto 0);
signal dsv_length_reg         : std_logic_vector((DSV_LENGTH_SIZE        - 1) downto 0);
signal knn_num_reg            : std_logic_vector((KNN_NUM_SIZE           - 1) downto 0);
signal status_reg             : std_logic_vector((STATUS_SIZE            - 1) downto 0);
signal design_def_1_reg       : std_logic_vector((DESIGN_DEF_1_SIZE      - 1) downto 0);
signal design_def_2_reg       : std_logic_vector((DESIGN_DEF_2_SIZE      - 1) downto 0);

signal all_zeros              : std_logic_vector((REG_IF_DATA_SIZE       - 1) downto 0);
signal threshold_reg          : std_logic_vector((THRESHOLD_HI_SIZE + THRESHOLD_LO_SIZE - 1) downto 0);

signal dtr_start_pulse        : std_logic;
signal dtr_counter            : std_logic_vector(31 downto 0);
signal dtr_data_out           : std_logic_vector(7 downto 0);
signal dtr_value_reg          : std_logic_vector(5 downto 0);

signal rd_data                : std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);
signal rd_data_reg            : std_logic_vector((REG_IF_DATA_SIZE    - 1) downto 0);

begin

rtl_version_reg  <= RTL_VERSION_DEF;

threshold_reg    <= threshold_hi_reg & threshold_lo_reg;
threshold_o      <= threshold_reg((DISTANCE_SIZE - 1) downto 0);
dsv_count_o      <= dsv_count_hi_reg & dsv_count_lo_reg;
dsv_length_o     <= dsv_length_reg;
knn_num_o        <= knn_num_reg;

all_zeros        <= (others => '0');

rd_data_o        <= rd_data_reg;

temperature_o    <= dtr_value_reg;

design_def_1_reg <= DESIGN_DEF_1_DEF;
design_def_2_reg <= DESIGN_DEF_2_DEF;

rd_data          <= rtl_version_reg       when (rd_address_i = RTL_VERSION_ADDR  ) else
                    threshold_lo_reg      when (rd_address_i = THRESHOLD_LO_ADDR ) else
                    threshold_hi_reg      when (rd_address_i = THRESHOLD_HI_ADDR ) else
                    dsv_count_lo_reg      when (rd_address_i = DSV_COUNT_LO_ADDR ) else
                    dsv_count_hi_reg      when (rd_address_i = DSV_COUNT_HI_ADDR ) else
                    all_zeros((REG_IF_DATA_SIZE - 1) downto DSV_LENGTH_SIZE      ) & dsv_length_reg   when (rd_address_i = DSV_LENGTH_ADDR  ) else
                    all_zeros((REG_IF_DATA_SIZE - 1) downto KNN_NUM_SIZE         ) & knn_num_reg      when (rd_address_i = KNN_NUM_ADDR     ) else
                    status_reg            when (rd_address_i = STATUS_ADDR       ) else
                    design_def_1_reg      when (rd_address_i = DESIGN_DEF_1_ADDR ) else
                    design_def_2_reg      when (rd_address_i = DESIGN_DEF_2_ADDR ) else
                    (others => '1');

  -- Configuration Register write logic
  process(clk, reset_n)
  begin
    if(reset_n = '0') then
      threshold_lo_reg <= THRESHOLD_LO_DEF;
      threshold_hi_reg <= THRESHOLD_HI_DEF;
      dsv_count_lo_reg <= DSV_COUNT_LO_DEF;
      dsv_count_hi_reg <= DSV_COUNT_HI_DEF;
      dsv_length_reg   <= DSV_LENGTH_DEF;
      knn_num_reg      <= KNN_NUM_DEF;
    elsif(clk = '1' and clk'event) then
      if(wr_en_i = '1') then
        case wr_address_i is
          when THRESHOLD_LO_ADDR => if (THRESHOLD_LO_WP = '0') then threshold_lo_reg <= wr_data_i((THRESHOLD_LO_SIZE - 1) downto 0); end if;
          when THRESHOLD_HI_ADDR => if (THRESHOLD_HI_WP = '0') then threshold_hi_reg <= wr_data_i((THRESHOLD_HI_SIZE - 1) downto 0); end if;
          when DSV_COUNT_LO_ADDR => if (DSV_COUNT_LO_WP = '0') then dsv_count_lo_reg <= wr_data_i((DSV_COUNT_LO_SIZE - 1) downto 0); end if;
          when DSV_COUNT_HI_ADDR => if (DSV_COUNT_HI_WP = '0') then dsv_count_hi_reg <= wr_data_i((DSV_COUNT_HI_SIZE - 1) downto 0); end if;
          when DSV_LENGTH_ADDR   => if (DSV_LENGTH_WP   = '0') then dsv_length_reg   <= wr_data_i((DSV_LENGTH_SIZE   - 1) downto 0); end if;
          when KNN_NUM_ADDR      => if (KNN_NUM_WP      = '0') then knn_num_reg      <= wr_data_i((KNN_NUM_SIZE      - 1) downto 0); end if;
          when others =>
        end case;
      end if;
    end if;
  end process;

-- Forming pulse with 4 clock cycle duration, and 200 ms period.
-- This pulse is used by DTR.
process (reset_n, clk) begin
  if(reset_n = '0') then
    dtr_start_pulse <= '0';
  elsif(clk = '1' and clk'event) then
    if((dtr_counter = X"00000000") or (dtr_counter = X"00000001") or
       (dtr_counter = X"00000002") or (dtr_counter = X"00000003")) then
      dtr_start_pulse <= '1';
    else
      dtr_start_pulse <= '0';
    end if;
  end if;
end process;

process (reset_n, clk) begin
  if(reset_n = '0') then
    dtr_counter <= (others => '0');
  elsif(clk = '1' and clk'event) then
    if(dtr_counter = DTR_PULSE_CYCLE_COUNT) then
      dtr_counter <= (others => '0');
    else
      dtr_counter <= dtr_counter + '1';
    end if;
  end if;
end process;

-- Delay for read data which is the output of the module.
process (reset_n, clk) begin
  if(reset_n = '0') then
    rd_data_reg <= (others => '0');
  elsif(clk = '1' and clk'event) then
    rd_data_reg <= rd_data;
  end if;
end process;

-- Formation of status register value
process (reset_n, clk) begin
  if(reset_n = '0') then
    status_reg <= (others => '0');
  elsif(clk = '1' and clk'event) then
    status_reg <= status_i(7 downto 0) & "00" & dtr_value_reg;
  end if;
end process;

-- Delay of DTR output. Needs for timing improvement.
process (reset_n, clk) begin
  if(reset_n = '0') then
    dtr_value_reg <= (others => '0');
  elsif(clk = '1' and clk'event) then
    if(dtr_data_out(7) = '1') then
      dtr_value_reg <= dtr_data_out(5 downto 0);
    end if;
  end if;
end process;

dtr_0 : DTR
port map (
  STARTPULSE => dtr_start_pulse,
  DTROUT7    => dtr_data_out(7),
  DTROUT6    => dtr_data_out(6),
  DTROUT5    => dtr_data_out(5),
  DTROUT4    => dtr_data_out(4),
  DTROUT3    => dtr_data_out(3),
  DTROUT2    => dtr_data_out(2),
  DTROUT1    => dtr_data_out(1),
  DTROUT0    => dtr_data_out(0)
);

end rtl;
