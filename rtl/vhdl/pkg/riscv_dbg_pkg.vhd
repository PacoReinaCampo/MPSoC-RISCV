-- Converted from rtl/verilog/arbiter/riscv_arb_rr.sv
-- by verilog2vhdl - QueenField

--//////////////////////////////////////////////////////////////////////////////
--                                            __ _      _     _               //
--                                           / _(_)    | |   | |              //
--                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
--               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
--              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
--               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
--                  | |                                                       //
--                  |_|                                                       //
--                                                                            //
--                                                                            //
--              MPSoC-RISCV CPU                                               //
--              Package                                                       //
--              AMBA3 AHB-Lite Bus Interface                                  //
--                                                                            //
--//////////////////////////////////////////////////////////////////////////////

-- Copyright (c) 2019-2020 by the author(s)
-- *
-- * Permission is hereby granted, free of charge, to any person obtaining a copy
-- * of this software and associated documentation files (the "Software"), to deal
-- * in the Software without restriction, including without limitation the rights
-- * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- * copies of the Software, and to permit persons to whom the Software is
-- * furnished to do so, subject to the following conditions:
-- *
-- * The above copyright notice and this permission notice shall be included in
-- * all copies or substantial portions of the Software.
-- *
-- * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- * THE SOFTWARE.
-- *
-- * =============================================================================
-- * Author(s):
-- *   Francisco Javier Reina Campo <frareicam@gmail.com>
-- */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package riscv_dbg_pkg is

  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant WIDTH : integer := 64;

  constant DEPTH : integer := 8;

  constant SYSTEM_VENDOR_ID         : integer := 2;
  constant SYSTEM_DEVICE_ID         : integer := 2;
  constant NUM_MODULES              : integer := 0;

  constant SUBNET_BITS              : integer := 6;
  constant LOCAL_SUBNET             : integer := 0;
  constant DEBUG_ROUTER_BUFFER_SIZE : integer := 4;

  constant BUFFER_SIZE : integer := 4;

  constant FULLPACKET : std_ulogic := '0';

  --Width of memory addresses
  constant ADDR_WIDTH : integer :=  64;

  --System word length
  constant DATA_WIDTH : integer :=  64;

  constant LOG2_BUFFER_SIZE : integer := integer(log2(real(BUFFER_SIZE)));

  --Regaccess
  constant  MOD_VENDOR             : integer := 4;  -- module vendor
  constant  MOD_TYPE               : integer := 4;  -- module type
  constant  MOD_VERSION            : integer := 4;  -- module version
  constant  MOD_EVENT_DEST_DEFAULT : integer := 4;  -- default event destination
  constant  MAX_REG_SIZE           : integer := 64;

  constant  CAN_STALL : std_ulogic := '0';

  -- The maximum number of payload words the packet could consist of.
  -- The actual number of payload words is given by data_num_words.
  constant MAX_DATA_NUM_WORDS : integer := DATA_WIDTH;
end riscv_dbg_pkg;
