-- Converted from rtl/verilog/mpsoc/riscv_mpsoc.sv
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
--              Many Processors System on Chip                                //
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

use work.riscv_mpsoc_pkg.all;

entity riscv_mpsoc is
  port (
    --Common signals
    HRESETn : in std_ulogic;
    HCLK    : in std_ulogic;

    --GLIP host connection
    glip_misd_in_data  : in  std_ulogic_vector(XLEN-1 downto 0);
    glip_misd_in_valid : in  std_ulogic;
    glip_misd_in_ready : out std_ulogic;

    glip_misd_out_data  : out std_ulogic_vector(XLEN-1 downto 0);
    glip_misd_out_valid : out std_ulogic;
    glip_misd_out_ready : in  std_ulogic;

    glip_simd_in_data  : in  std_ulogic_vector(XLEN-1 downto 0);
    glip_simd_in_valid : in  std_ulogic;
    glip_simd_in_ready : out std_ulogic;

    glip_simd_out_data  : out std_ulogic_vector(XLEN-1 downto 0);
    glip_simd_out_valid : out std_ulogic;
    glip_simd_out_ready : in  std_ulogic;

    --PMA configuration
    pma_cfg_i : in M_PMA_CNT_13;
    pma_adr_i : in M_PMA_CNT_PLEN;

    --AHB instruction - Single Port
    sins_simd_HSEL      : out M_XYZ;
    sins_simd_HADDR     : out M_XYZ_PLEN;
    sins_simd_HWDATA    : out M_XYZ_XLEN;
    sins_simd_HRDATA    : in  M_XYZ_XLEN;
    sins_simd_HWRITE    : out M_XYZ;
    sins_simd_HSIZE     : out M_XYZ_2;
    sins_simd_HBURST    : out M_XYZ_2;
    sins_simd_HPROT     : out M_XYZ_3;
    sins_simd_HTRANS    : out M_XYZ_1;
    sins_simd_HMASTLOCK : out M_XYZ;
    sins_simd_HREADY    : in  M_XYZ;
    sins_simd_HRESP     : in  M_XYZ;

    --AHB data - Single Port
    sdat_misd_HSEL      : out M_XYZ;
    sdat_misd_HADDR     : out M_XYZ_PLEN;
    sdat_misd_HWDATA    : out M_XYZ_XLEN;
    sdat_misd_HRDATA    : in  M_XYZ_XLEN;
    sdat_misd_HWRITE    : out M_XYZ;
    sdat_misd_HSIZE     : out M_XYZ_2;
    sdat_misd_HBURST    : out M_XYZ_2;
    sdat_misd_HPROT     : out M_XYZ_3;
    sdat_misd_HTRANS    : out M_XYZ_1;
    sdat_misd_HMASTLOCK : out M_XYZ;
    sdat_misd_HREADY    : in  M_XYZ;
    sdat_misd_HRESP     : in  M_XYZ;

    --AHB instruction - Multi Port
    mins_misd_HSEL      : out M_XYZ_CORES_PER_MISD;
    mins_misd_HADDR     : out M_XYZ_CORES_PER_MISD_PLEN;
    mins_misd_HWDATA    : out M_XYZ_CORES_PER_MISD_XLEN;
    mins_misd_HRDATA    : in  M_XYZ_CORES_PER_MISD_XLEN;
    mins_misd_HWRITE    : out M_XYZ_CORES_PER_MISD;
    mins_misd_HSIZE     : out M_XYZ_CORES_PER_MISD_2;
    mins_misd_HBURST    : out M_XYZ_CORES_PER_MISD_2;
    mins_misd_HPROT     : out M_XYZ_CORES_PER_MISD_3;
    mins_misd_HTRANS    : out M_XYZ_CORES_PER_MISD_1;
    mins_misd_HMASTLOCK : out M_XYZ_CORES_PER_MISD;
    mins_misd_HREADY    : in  M_XYZ_CORES_PER_MISD;
    mins_misd_HRESP     : in  M_XYZ_CORES_PER_MISD;

    --AHB data - Multi Port
    mdat_simd_HSEL      : out M_XYZ_CORES_PER_SIMD;
    mdat_simd_HADDR     : out M_XYZ_CORES_PER_SIMD_PLEN;
    mdat_simd_HWDATA    : out M_XYZ_CORES_PER_SIMD_XLEN;
    mdat_simd_HRDATA    : in  M_XYZ_CORES_PER_SIMD_XLEN;
    mdat_simd_HWRITE    : out M_XYZ_CORES_PER_SIMD;
    mdat_simd_HSIZE     : out M_XYZ_CORES_PER_SIMD_2;
    mdat_simd_HBURST    : out M_XYZ_CORES_PER_SIMD_2;
    mdat_simd_HPROT     : out M_XYZ_CORES_PER_SIMD_3;
    mdat_simd_HTRANS    : out M_XYZ_CORES_PER_SIMD_1;
    mdat_simd_HMASTLOCK : out M_XYZ_CORES_PER_SIMD;
    mdat_simd_HREADY    : in  M_XYZ_CORES_PER_SIMD;
    mdat_simd_HRESP     : in  M_XYZ_CORES_PER_SIMD;

    --Interrupts Interface
    ext_misd_nmi  : in M_XYZ_CORES_PER_MISD;
    ext_misd_tint : in M_XYZ_CORES_PER_MISD;
    ext_misd_sint : in M_XYZ_CORES_PER_MISD;
    ext_misd_int  : in M_XYZ_CORES_PER_MISD_3;

    ext_simd_nmi  : in M_XYZ_CORES_PER_SIMD;
    ext_simd_tint : in M_XYZ_CORES_PER_SIMD;
    ext_simd_sint : in M_XYZ_CORES_PER_SIMD;
    ext_simd_int  : in M_XYZ_CORES_PER_SIMD_3;

    --Debug Interface
    dbg_misd_stall : in  M_XYZ_CORES_PER_MISD;
    dbg_misd_strb  : in  M_XYZ_CORES_PER_MISD;
    dbg_misd_we    : in  M_XYZ_CORES_PER_MISD;
    dbg_misd_addr  : in  M_XYZ_CORES_PER_MISD_PLEN;
    dbg_misd_dati  : in  M_XYZ_CORES_PER_MISD_XLEN;
    dbg_misd_dato  : out M_XYZ_CORES_PER_MISD_XLEN;
    dbg_misd_ack   : out M_XYZ_CORES_PER_MISD;
    dbg_misd_bp    : out M_XYZ_CORES_PER_MISD;

    dbg_simd_stall : in  M_XYZ_CORES_PER_SIMD;
    dbg_simd_strb  : in  M_XYZ_CORES_PER_SIMD;
    dbg_simd_we    : in  M_XYZ_CORES_PER_SIMD;
    dbg_simd_addr  : in  M_XYZ_CORES_PER_SIMD_PLEN;
    dbg_simd_dati  : in  M_XYZ_CORES_PER_SIMD_XLEN;
    dbg_simd_dato  : out M_XYZ_CORES_PER_SIMD_XLEN;
    dbg_simd_ack   : out M_XYZ_CORES_PER_SIMD;
    dbg_simd_bp    : out M_XYZ_CORES_PER_SIMD;

    --GPIO Interface
    gpio_simd_i  : in  M_XYZ_PDATA_SIZE;
    gpio_simd_o  : out M_XYZ_PDATA_SIZE;
    gpio_simd_oe : out M_XYZ_PDATA_SIZE;

    gpio_misd_i  : in  M_XYZ_PDATA_SIZE;
    gpio_misd_o  : out M_XYZ_PDATA_SIZE;
    gpio_misd_oe : out M_XYZ_PDATA_SIZE
  );
end riscv_mpsoc;

architecture RTL of riscv_mpsoc is
  component riscv_noc_mesh
    port (
      clk : in std_ulogic;
      rst : in std_ulogic;

      in_flit  : in  M_NODES_CHANNELS_PLEN;
      in_last  : in  M_NODES_CHANNELS;
      in_valid : in  M_NODES_CHANNELS;
      in_ready : out M_NODES_CHANNELS;

      out_flit  : out M_NODES_CHANNELS_PLEN;
      out_last  : out M_NODES_CHANNELS;
      out_valid : out M_NODES_CHANNELS;
      out_ready : in  M_NODES_CHANNELS
    );
  end component;

  component riscv_debug_interface
    port (
      clk : in std_ulogic;
      rst : in std_ulogic;

      -- GLIP host connection
      glip_in_data  : in  std_ulogic_vector(XLEN-1 downto 0);
      glip_in_valid : in  std_ulogic;
      glip_in_ready : out std_ulogic;

      glip_out_data  : out std_ulogic_vector(XLEN-1 downto 0);
      glip_out_valid : out std_ulogic;
      glip_out_ready : in  std_ulogic;

      -- ring connection
      ring_out_data  : out M_CHANNELS_XLEN;
      ring_out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
      ring_out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
      ring_out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0);

      ring_in_data  : in  M_CHANNELS_XLEN;
      ring_in_last  : in  std_ulogic_vector(CHANNELS-1 downto 0);
      ring_in_valid : in  std_ulogic_vector(CHANNELS-1 downto 0);
      ring_in_ready : out std_ulogic_vector(CHANNELS-1 downto 0);

      -- system reset request
      sys_rst : out std_ulogic;

      -- CPU reset request
      cpu_rst : out std_ulogic
    );
  end component;

  component riscv_soc
    port (
    --Common signals
    HRESETn : in std_ulogic;
    HCLK    : in std_ulogic;

    --PMA configuration
    pma_cfg_i : in M_PMA_CNT_13;
    pma_adr_i : in M_PMA_CNT_PLEN;

    --Debug
    debug_misd_ring_in_data  : in  M_CHANNELS_XLEN;
    debug_misd_ring_in_last  : in  std_ulogic_vector(CHANNELS-1 downto 0);
    debug_misd_ring_in_valid : in  std_ulogic_vector(CHANNELS-1 downto 0);
    debug_misd_ring_in_ready : out std_ulogic_vector(CHANNELS-1 downto 0);

    debug_misd_ring_out_data  : out M_CHANNELS_XLEN;
    debug_misd_ring_out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
    debug_misd_ring_out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
    debug_misd_ring_out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0);

    debug_simd_ring_in_data  : in  M_CHANNELS_XLEN;
    debug_simd_ring_in_last  : in  std_ulogic_vector(CHANNELS-1 downto 0);
    debug_simd_ring_in_valid : in  std_ulogic_vector(CHANNELS-1 downto 0);
    debug_simd_ring_in_ready : out std_ulogic_vector(CHANNELS-1 downto 0);

    debug_simd_ring_out_data  : out M_CHANNELS_XLEN;
    debug_simd_ring_out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
    debug_simd_ring_out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
    debug_simd_ring_out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0);

    --AHB instruction - Single Port
    sins_simd_HSEL      : out std_ulogic;
    sins_simd_HADDR     : out std_ulogic_vector(PLEN-1 downto 0);
    sins_simd_HWDATA    : out std_ulogic_vector(XLEN-1 downto 0);
    sins_simd_HRDATA    : in  std_ulogic_vector(XLEN-1 downto 0);
    sins_simd_HWRITE    : out std_ulogic;
    sins_simd_HSIZE     : out std_ulogic_vector(2 downto 0);
    sins_simd_HBURST    : out std_ulogic_vector(2 downto 0);
    sins_simd_HPROT     : out std_ulogic_vector(3 downto 0);
    sins_simd_HTRANS    : out std_ulogic_vector(1 downto 0);
    sins_simd_HMASTLOCK : out std_ulogic;
    sins_simd_HREADY    : in  std_ulogic;
    sins_simd_HRESP     : in  std_ulogic;

    --AHB data - Single Port
    sdat_misd_HSEL      : out std_ulogic;
    sdat_misd_HADDR     : out std_ulogic_vector(PLEN-1 downto 0);
    sdat_misd_HWDATA    : out std_ulogic_vector(XLEN-1 downto 0);
    sdat_misd_HRDATA    : in  std_ulogic_vector(XLEN-1 downto 0);
    sdat_misd_HWRITE    : out std_ulogic;
    sdat_misd_HSIZE     : out std_ulogic_vector(2 downto 0);
    sdat_misd_HBURST    : out std_ulogic_vector(2 downto 0);
    sdat_misd_HPROT     : out std_ulogic_vector(3 downto 0);
    sdat_misd_HTRANS    : out std_ulogic_vector(1 downto 0);
    sdat_misd_HMASTLOCK : out std_ulogic;
    sdat_misd_HREADY    : in  std_ulogic;
    sdat_misd_HRESP     : in  std_ulogic;

    --AHB instruction - Multi Port
    mins_misd_HSEL      : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    mins_misd_HADDR     : out M_CORES_PER_MISD_PLEN;
    mins_misd_HWDATA    : out M_CORES_PER_MISD_XLEN;
    mins_misd_HRDATA    : in  M_CORES_PER_MISD_XLEN;
    mins_misd_HWRITE    : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    mins_misd_HSIZE     : out M_CORES_PER_MISD_2;
    mins_misd_HBURST    : out M_CORES_PER_MISD_2;
    mins_misd_HPROT     : out M_CORES_PER_MISD_3;
    mins_misd_HTRANS    : out M_CORES_PER_MISD_1;
    mins_misd_HMASTLOCK : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    mins_misd_HREADY    : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    mins_misd_HRESP     : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);

    --AHB data - Multi Port
    mdat_simd_HSEL      : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    mdat_simd_HADDR     : out M_CORES_PER_SIMD_PLEN;
    mdat_simd_HWDATA    : out M_CORES_PER_SIMD_XLEN;
    mdat_simd_HRDATA    : in  M_CORES_PER_SIMD_XLEN;
    mdat_simd_HWRITE    : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    mdat_simd_HSIZE     : out M_CORES_PER_SIMD_2;
    mdat_simd_HBURST    : out M_CORES_PER_SIMD_2;
    mdat_simd_HPROT     : out M_CORES_PER_SIMD_3;
    mdat_simd_HTRANS    : out M_CORES_PER_SIMD_1;
    mdat_simd_HMASTLOCK : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    mdat_simd_HREADY    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    mdat_simd_HRESP     : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

    --Interrupts Interface
    ext_misd_nmi  : in std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    ext_misd_tint : in std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    ext_misd_sint : in std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    ext_misd_int  : in M_CORES_PER_MISD_3;

    ext_simd_nmi  : in std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    ext_simd_tint : in std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    ext_simd_sint : in std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    ext_simd_int  : in M_CORES_PER_SIMD_3;

    --Debug Interface
    dbg_misd_stall : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    dbg_misd_strb  : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    dbg_misd_we    : in  std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    dbg_misd_addr  : in  M_CORES_PER_MISD_PLEN;
    dbg_misd_dati  : in  M_CORES_PER_MISD_XLEN;
    dbg_misd_dato  : out M_CORES_PER_MISD_XLEN;
    dbg_misd_ack   : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);
    dbg_misd_bp    : out std_ulogic_vector(CORES_PER_MISD-1 downto 0);

    dbg_simd_stall : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dbg_simd_strb  : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dbg_simd_we    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dbg_simd_addr  : in  M_CORES_PER_SIMD_PLEN;
    dbg_simd_dati  : in  M_CORES_PER_SIMD_XLEN;
    dbg_simd_dato  : out M_CORES_PER_SIMD_XLEN;
    dbg_simd_ack   : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dbg_simd_bp    : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

    --NoC Interface
    noc_misd_in_flit   : in  M_CHANNELS_PLEN;
    noc_misd_in_last   : in  std_ulogic_vector(CHANNELS-1 downto 0);
    noc_misd_in_valid  : in  std_ulogic_vector(CHANNELS-1 downto 0);
    noc_misd_in_ready  : out std_ulogic_vector(CHANNELS-1 downto 0);
    noc_misd_out_flit  : out M_CHANNELS_PLEN;
    noc_misd_out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
    noc_misd_out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
    noc_misd_out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0);

    noc_simd_in_flit   : in  M_CHANNELS_PLEN;
    noc_simd_in_last   : in  std_ulogic_vector(CHANNELS-1 downto 0);
    noc_simd_in_valid  : in  std_ulogic_vector(CHANNELS-1 downto 0);
    noc_simd_in_ready  : out std_ulogic_vector(CHANNELS-1 downto 0);
    noc_simd_out_flit  : out M_CHANNELS_PLEN;
    noc_simd_out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
    noc_simd_out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
    noc_simd_out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0);

    --GPIO Interface
    gpio_simd_i  : in  std_ulogic_vector(PDATA_SIZE-1 downto 0);
    gpio_simd_o  : out std_ulogic_vector(PDATA_SIZE-1 downto 0);
    gpio_simd_oe : out std_ulogic_vector(PDATA_SIZE-1 downto 0);

    gpio_misd_i  : in  std_ulogic_vector(PDATA_SIZE-1 downto 0);
    gpio_misd_o  : out std_ulogic_vector(PDATA_SIZE-1 downto 0);
    gpio_misd_oe : out std_ulogic_vector(PDATA_SIZE-1 downto 0)
    );
  end component;

  --//////////////////////////////////////////////////////////////
  --
  -- Constans
  --
  constant SYSTEM_VENDOR_ID         : integer := 2;
  constant SYSTEM_DEVICE_ID         : integer := 2;
  constant NUM_MODULES              : integer := 0;
  constant MAX_PKT_LEN              : integer := 2;
  constant SUBNET_BITS              : integer := 6;
  constant LOCAL_SUBNET             : integer := 0;
  constant DEBUG_ROUTER_BUFFER_SIZE : integer := 4;

  --//////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  -- Flits from NoC->tiles
  signal noc_misd_in_flit  : M_NODES_CHANNELS_PLEN;
  signal noc_misd_in_last  : M_NODES_CHANNELS;
  signal noc_misd_in_valid : M_NODES_CHANNELS;
  signal noc_misd_in_ready : M_NODES_CHANNELS;

  signal noc_simd_out_flit  : M_NODES_CHANNELS_PLEN;
  signal noc_simd_out_last  : M_NODES_CHANNELS;
  signal noc_simd_out_valid : M_NODES_CHANNELS;
  signal noc_simd_out_ready : M_NODES_CHANNELS;

  -- Flits from tiles->NoC
  signal noc_misd_out_flit  : M_NODES_CHANNELS_PLEN;
  signal noc_misd_out_last  : M_NODES_CHANNELS;
  signal noc_misd_out_valid : M_NODES_CHANNELS;
  signal noc_misd_out_ready : M_NODES_CHANNELS;

  signal noc_simd_in_flit  : M_NODES_CHANNELS_PLEN;
  signal noc_simd_in_last  : M_NODES_CHANNELS;
  signal noc_simd_in_valid : M_NODES_CHANNELS;
  signal noc_simd_in_ready : M_NODES_CHANNELS;

  signal rst_misd_sys : std_ulogic;
  signal rst_misd_cpu : std_ulogic;

  signal rst_simd_sys : std_ulogic;
  signal rst_simd_cpu : std_ulogic;

  signal debug_misd_ring_in_data  : M_XYZ_CHANNELS_XLEN;
  signal debug_misd_ring_in_last  : M_XYZ_CHANNELS;
  signal debug_misd_ring_in_valid : M_XYZ_CHANNELS;
  signal debug_misd_ring_in_ready : M_XYZ_CHANNELS;

  signal debug_misd_ring_out_data  : M_XYZ_CHANNELS_XLEN;
  signal debug_misd_ring_out_last  : M_XYZ_CHANNELS;
  signal debug_misd_ring_out_valid : M_XYZ_CHANNELS;
  signal debug_misd_ring_out_ready : M_XYZ_CHANNELS;

  signal debug_simd_ring_in_data  : M_XYZ_CHANNELS_XLEN;
  signal debug_simd_ring_in_last  : M_XYZ_CHANNELS;
  signal debug_simd_ring_in_valid : M_XYZ_CHANNELS;
  signal debug_simd_ring_in_ready : M_XYZ_CHANNELS;

  signal debug_simd_ring_out_data  : M_XYZ_CHANNELS_XLEN;
  signal debug_simd_ring_out_last  : M_XYZ_CHANNELS;
  signal debug_simd_ring_out_valid : M_XYZ_CHANNELS;
  signal debug_simd_ring_out_ready : M_XYZ_CHANNELS;

begin
  --//////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Instantiate RISC-V NoC MISD
  noc_mesh_misd : riscv_noc_mesh
    port map (
      rst => HRESETn,
      clk => HCLK,

      in_flit  => noc_misd_out_flit,
      in_last  => noc_misd_out_last,
      in_valid => noc_misd_out_valid,
      in_ready => noc_misd_out_ready,

      out_flit  => noc_misd_in_flit,
      out_last  => noc_misd_in_last,
      out_valid => noc_misd_in_valid,
      out_ready => noc_misd_in_ready
    );

  --Instantiate RISC-V NoC SIMD
  noc_mesh_simd : riscv_noc_mesh
    port map (
      rst => HRESETn,
      clk => HCLK,

      in_flit  => noc_simd_out_flit,
      in_last  => noc_simd_out_last,
      in_valid => noc_simd_out_valid,
      in_ready => noc_simd_out_ready,

      out_flit  => noc_simd_in_flit,
      out_last  => noc_simd_in_last,
      out_valid => noc_simd_in_valid,
      out_ready => noc_simd_in_ready
    );

  --Instantiate RISC-V Debug MISD
  debug_interface_misd : riscv_debug_interface
    port map (
      clk => HCLK,
      rst => HRESETn,

      sys_rst => rst_misd_sys,
      cpu_rst => rst_misd_cpu,

      glip_in_data  => glip_misd_in_data,
      glip_in_valid => glip_misd_in_valid,
      glip_in_ready => glip_misd_in_ready,

      glip_out_data  => glip_misd_out_data,
      glip_out_valid => glip_misd_out_valid,
      glip_out_ready => glip_misd_out_ready,

      ring_out_data  => debug_misd_ring_in_data(0,0,1),
      ring_out_last  => debug_misd_ring_in_last(0,0,1),
      ring_out_valid => debug_misd_ring_in_valid(0,0,1),
      ring_out_ready => debug_misd_ring_in_ready(0,0,1),

      ring_in_data  => debug_misd_ring_out_data(0,0,1),
      ring_in_last  => debug_misd_ring_out_last(0,0,1),
      ring_in_valid => debug_misd_ring_out_valid(0,0,1),
      ring_in_ready => debug_misd_ring_out_ready(0,0,1)
    );

  --Instantiate RISC-V Debug SIMD
  debug_interface_simd : riscv_debug_interface
    port map (
      clk => HCLK,
      rst => HRESETn,

      sys_rst => rst_simd_sys,
      cpu_rst => rst_simd_cpu,

      glip_in_data  => glip_simd_in_data,
      glip_in_valid => glip_simd_in_valid,
      glip_in_ready => glip_simd_in_ready,

      glip_out_data  => glip_simd_out_data,
      glip_out_valid => glip_simd_out_valid,
      glip_out_ready => glip_simd_out_ready,

      ring_out_data  => debug_simd_ring_in_data(0,0,0),
      ring_out_last  => debug_simd_ring_in_last(0,0,0),
      ring_out_valid => debug_simd_ring_in_valid(0,0,0),
      ring_out_ready => debug_simd_ring_in_ready(0,0,0),

      ring_in_data  => debug_simd_ring_out_data(0,0,1),
      ring_in_last  => debug_simd_ring_out_last(0,0,1),
      ring_in_valid => debug_simd_ring_out_valid(0,0,1),
      ring_in_ready => debug_simd_ring_out_ready(0,0,1)
    );

  --Instantiate RISC-V SoC
  generating_0 : for i in 0 to X - 1 generate
    generating_1 : for j in 0 to Y - 1 generate
      generating_2 : for k in 0 to Z - 1 generate
        soc : riscv_soc
          port map (
            --Common signals
            HRESETn => HRESETn,
            HCLK    => HCLK,

            --PMA configuration
            pma_cfg_i => pma_cfg_i,
            pma_adr_i => pma_adr_i,

            --Debug
            debug_misd_ring_in_data  => debug_misd_ring_in_data(i,j,k),
            debug_misd_ring_in_last  => debug_misd_ring_in_last(i,j,k),
            debug_misd_ring_in_valid => debug_misd_ring_in_valid(i,j,k),
            debug_misd_ring_in_ready => debug_misd_ring_in_ready(i,j,k),

            debug_misd_ring_out_data  => debug_misd_ring_out_data(i,j,k),
            debug_misd_ring_out_last  => debug_misd_ring_out_last(i,j,k),
            debug_misd_ring_out_valid => debug_misd_ring_out_valid(i,j,k),
            debug_misd_ring_out_ready => debug_misd_ring_out_ready(i,j,k),

            debug_simd_ring_in_data  => debug_simd_ring_in_data(i,j,k),
            debug_simd_ring_in_last  => debug_simd_ring_in_last(i,j,k),
            debug_simd_ring_in_valid => debug_simd_ring_in_valid(i,j,k),
            debug_simd_ring_in_ready => debug_simd_ring_in_ready(i,j,k),

            debug_simd_ring_out_data  => debug_simd_ring_out_data(i,j,k),
            debug_simd_ring_out_last  => debug_simd_ring_out_last(i,j,k),
            debug_simd_ring_out_valid => debug_simd_ring_out_valid(i,j,k),
            debug_simd_ring_out_ready => debug_simd_ring_out_ready(i,j,k),

            --AHB instruction - Single Port
            sins_simd_HSEL      => sins_simd_HSEL(i,j,k),
            sins_simd_HADDR     => sins_simd_HADDR(i,j,k),
            sins_simd_HWDATA    => sins_simd_HWDATA(i,j,k),
            sins_simd_HRDATA    => sins_simd_HRDATA(i,j,k),
            sins_simd_HWRITE    => sins_simd_HWRITE(i,j,k),
            sins_simd_HSIZE     => sins_simd_HSIZE(i,j,k),
            sins_simd_HBURST    => sins_simd_HBURST(i,j,k),
            sins_simd_HPROT     => sins_simd_HPROT(i,j,k),
            sins_simd_HTRANS    => sins_simd_HTRANS(i,j,k),
            sins_simd_HMASTLOCK => sins_simd_HMASTLOCK(i,j,k),
            sins_simd_HREADY    => sins_simd_HREADY(i,j,k),
            sins_simd_HRESP     => sins_simd_HRESP(i,j,k),

            --AHB data - Single Port
            sdat_misd_HSEL      => sdat_misd_HSEL(i,j,k),
            sdat_misd_HADDR     => sdat_misd_HADDR(i,j,k),
            sdat_misd_HWDATA    => sdat_misd_HWDATA(i,j,k),
            sdat_misd_HRDATA    => sdat_misd_HRDATA(i,j,k),
            sdat_misd_HWRITE    => sdat_misd_HWRITE(i,j,k),
            sdat_misd_HSIZE     => sdat_misd_HSIZE(i,j,k),
            sdat_misd_HBURST    => sdat_misd_HBURST(i,j,k),
            sdat_misd_HPROT     => sdat_misd_HPROT(i,j,k),
            sdat_misd_HTRANS    => sdat_misd_HTRANS(i,j,k),
            sdat_misd_HMASTLOCK => sdat_misd_HMASTLOCK(i,j,k),
            sdat_misd_HREADY    => sdat_misd_HREADY(i,j,k),
            sdat_misd_HRESP     => sdat_misd_HRESP(i,j,k),

            --AHB instruction - Multi Port
            mins_misd_HSEL      => mins_misd_HSEL(i,j,k),
            mins_misd_HADDR     => mins_misd_HADDR(i,j,k),
            mins_misd_HWDATA    => mins_misd_HWDATA(i,j,k),
            mins_misd_HRDATA    => mins_misd_HRDATA(i,j,k),
            mins_misd_HWRITE    => mins_misd_HWRITE(i,j,k),
            mins_misd_HSIZE     => mins_misd_HSIZE(i,j,k),
            mins_misd_HBURST    => mins_misd_HBURST(i,j,k),
            mins_misd_HPROT     => mins_misd_HPROT(i,j,k),
            mins_misd_HTRANS    => mins_misd_HTRANS(i,j,k),
            mins_misd_HMASTLOCK => mins_misd_HMASTLOCK(i,j,k),
            mins_misd_HREADY    => mins_misd_HREADY(i,j,k),
            mins_misd_HRESP     => mins_misd_HRESP(i,j,k),

            --AHB data - Multi Port
            mdat_simd_HSEL      => mdat_simd_HSEL(i,j,k),
            mdat_simd_HADDR     => mdat_simd_HADDR(i,j,k),
            mdat_simd_HWDATA    => mdat_simd_HWDATA(i,j,k),
            mdat_simd_HRDATA    => mdat_simd_HRDATA(i,j,k),
            mdat_simd_HWRITE    => mdat_simd_HWRITE(i,j,k),
            mdat_simd_HSIZE     => mdat_simd_HSIZE(i,j,k),
            mdat_simd_HBURST    => mdat_simd_HBURST(i,j,k),
            mdat_simd_HPROT     => mdat_simd_HPROT(i,j,k),
            mdat_simd_HTRANS    => mdat_simd_HTRANS(i,j,k),
            mdat_simd_HMASTLOCK => mdat_simd_HMASTLOCK(i,j,k),
            mdat_simd_HREADY    => mdat_simd_HREADY(i,j,k),
            mdat_simd_HRESP     => mdat_simd_HRESP(i,j,k),

            --Interrupts Interface
            ext_misd_nmi  => ext_misd_nmi(i,j,k),
            ext_misd_tint => ext_misd_tint(i,j,k),
            ext_misd_sint => ext_misd_sint(i,j,k),
            ext_misd_int  => ext_misd_int(i,j,k),

            ext_simd_nmi  => ext_simd_nmi(i,j,k),
            ext_simd_tint => ext_simd_tint(i,j,k),
            ext_simd_sint => ext_simd_sint(i,j,k),
            ext_simd_int  => ext_simd_int(i,j,k),

            --Debug Interface
            dbg_simd_stall => dbg_simd_stall(i,j,k),
            dbg_simd_strb  => dbg_simd_strb(i,j,k),
            dbg_simd_we    => dbg_simd_we(i,j,k),
            dbg_simd_addr  => dbg_simd_addr(i,j,k),
            dbg_simd_dati  => dbg_simd_dati(i,j,k),
            dbg_simd_dato  => dbg_simd_dato(i,j,k),
            dbg_simd_ack   => dbg_simd_ack(i,j,k),
            dbg_simd_bp    => dbg_simd_bp(i,j,k),

            dbg_misd_stall => dbg_misd_stall(i,j,k),
            dbg_misd_strb  => dbg_misd_strb(i,j,k),
            dbg_misd_we    => dbg_misd_we(i,j,k),
            dbg_misd_addr  => dbg_misd_addr(i,j,k),
            dbg_misd_dati  => dbg_misd_dati(i,j,k),
            dbg_misd_dato  => dbg_misd_dato(i,j,k),
            dbg_misd_ack   => dbg_misd_ack(i,j,k),
            dbg_misd_bp    => dbg_misd_bp(i,j,k),

            --GPIO Interface
            gpio_simd_i  => gpio_simd_i(i,j,k),
            gpio_simd_o  => gpio_simd_o(i,j,k),
            gpio_simd_oe => gpio_simd_oe(i,j,k),

            gpio_misd_i  => gpio_misd_i(i,j,k),
            gpio_misd_o  => gpio_misd_o(i,j,k),
            gpio_misd_oe => gpio_misd_oe(i,j,k),

            --NoC Interface
            noc_misd_in_flit   => noc_misd_in_flit((i+1)*(j+1)*(k+1)-1),
            noc_misd_in_last   => noc_misd_in_last((i+1)*(j+1)*(k+1)-1),
            noc_misd_in_valid  => noc_misd_in_valid((i+1)*(j+1)*(k+1)-1),
            noc_misd_in_ready  => noc_misd_in_ready((i+1)*(j+1)*(k+1)-1),
            noc_misd_out_flit  => noc_misd_out_flit((i+1)*(j+1)*(k+1)-1),
            noc_misd_out_last  => noc_misd_out_last((i+1)*(j+1)*(k+1)-1),
            noc_misd_out_valid => noc_misd_out_valid((i+1)*(j+1)*(k+1)-1),
            noc_misd_out_ready => noc_misd_out_ready((i+1)*(j+1)*(k+1)-1),

            noc_simd_in_flit   => noc_simd_in_flit((i+1)*(j+1)*(k+1)-1),
            noc_simd_in_last   => noc_simd_in_last((i+1)*(j+1)*(k+1)-1),
            noc_simd_in_valid  => noc_simd_in_valid((i+1)*(j+1)*(k+1)-1),
            noc_simd_in_ready  => noc_simd_in_ready((i+1)*(j+1)*(k+1)-1),
            noc_simd_out_flit  => noc_simd_out_flit((i+1)*(j+1)*(k+1)-1),
            noc_simd_out_last  => noc_simd_out_last((i+1)*(j+1)*(k+1)-1),
            noc_simd_out_valid => noc_simd_out_valid((i+1)*(j+1)*(k+1)-1),
            noc_simd_out_ready => noc_simd_out_ready((i+1)*(j+1)*(k+1)-1)
          );
      end generate generating_2;
    end generate generating_1;
  end generate generating_0;
end RTL;
