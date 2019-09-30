-- Converted from rtl/verilog/soc/riscv_simd.sv
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
--              Multiple Instruction Single Data                              //
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

use work.riscv_mpsoc_pkg.all;
use work.riscv_dbg_pkg.all;
use work.riscv_msi_pkg.all;

entity riscv_simd is
  port (
    --Common signals
    HRESETn : in std_ulogic;
    HCLK    : in std_ulogic;

    --Debug
    debug_ring_in_data  : in  M_CHANNELS_XLEN;
    debug_ring_in_last  : in  std_ulogic_vector(CHANNELS-1 downto 0);
    debug_ring_in_valid : in  std_ulogic_vector(CHANNELS-1 downto 0);
    debug_ring_in_ready : out std_ulogic_vector(CHANNELS-1 downto 0);

    debug_ring_out_data  : out M_CHANNELS_XLEN;
    debug_ring_out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
    debug_ring_out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
    debug_ring_out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0);

    --PMA configuration
    pma_cfg_i : M_PMA_CNT_13;
    pma_adr_i : M_PMA_CNT_PLEN;

    --AHB instruction
    ins_HSEL      : out std_ulogic;
    ins_HADDR     : out std_ulogic_vector(PLEN-1 downto 0);
    ins_HWDATA    : out std_ulogic_vector(XLEN-1 downto 0);
    ins_HRDATA    : in  std_ulogic_vector(XLEN-1 downto 0);
    ins_HWRITE    : out std_ulogic;
    ins_HSIZE     : out std_ulogic_vector(2 downto 0);
    ins_HBURST    : out std_ulogic_vector(2 downto 0);
    ins_HPROT     : out std_ulogic_vector(3 downto 0);
    ins_HTRANS    : out std_ulogic_vector(1 downto 0);
    ins_HMASTLOCK : out std_ulogic;
    ins_HREADY    : in  std_ulogic;
    ins_HRESP     : in  std_ulogic;

    --AHB data
    dat_HSEL      : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dat_HADDR     : out M_CORES_PER_SIMD_PLEN;
    dat_HWDATA    : out M_CORES_PER_SIMD_XLEN;
    dat_HRDATA    : in  M_CORES_PER_SIMD_XLEN;
    dat_HWRITE    : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dat_HSIZE     : out M_CORES_PER_SIMD_2;
    dat_HBURST    : out M_CORES_PER_SIMD_2;
    dat_HPROT     : out M_CORES_PER_SIMD_3;
    dat_HTRANS    : out M_CORES_PER_SIMD_1;
    dat_HMASTLOCK : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dat_HREADY    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dat_HRESP     : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

    --Interrupts Interface
    ext_nmi  : in std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    ext_tint : in std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    ext_sint : in std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    ext_int  : in M_CORES_PER_SIMD_3;

    --Debug Interface
    dbg_stall : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dbg_strb  : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dbg_we    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dbg_addr  : in  M_CORES_PER_SIMD_PLEN;
    dbg_dati  : in  M_CORES_PER_SIMD_XLEN;
    dbg_dato  : out M_CORES_PER_SIMD_XLEN;
    dbg_ack   : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    dbg_bp    : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

    --GPIO Interface
    gpio_i  : in  std_ulogic_vector(PDATA_SIZE-1 downto 0);
    gpio_o  : out std_ulogic_vector(PDATA_SIZE-1 downto 0);
    gpio_oe : out std_ulogic_vector(PDATA_SIZE-1 downto 0);

    --NoC Interface
    noc_in_flit   : in  M_CHANNELS_PLEN;
    noc_in_last   : in  std_ulogic_vector(CHANNELS-1 downto 0);
    noc_in_valid  : in  std_ulogic_vector(CHANNELS-1 downto 0);
    noc_in_ready  : out std_ulogic_vector(CHANNELS-1 downto 0);
    noc_out_flit  : out M_CHANNELS_PLEN;
    noc_out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
    noc_out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
    noc_out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0)
  );
end riscv_simd;

architecture RTL of riscv_simd is
  component riscv_pu
    port (
      --AHB interfaces
      HRESETn : in std_ulogic;
      HCLK    : in std_ulogic;

      pma_cfg_i : M_PMA_CNT_13;
      pma_adr_i : M_PMA_CNT_PLEN;

      dat_HSEL      : out std_ulogic;
      dat_HADDR     : out std_ulogic_vector(PLEN-1 downto 0);
      dat_HWDATA    : out std_ulogic_vector(XLEN-1 downto 0);
      dat_HRDATA    : in  std_ulogic_vector(XLEN-1 downto 0);
      dat_HWRITE    : out std_ulogic;
      dat_HSIZE     : out std_ulogic_vector(2 downto 0);
      dat_HBURST    : out std_ulogic_vector(2 downto 0);
      dat_HPROT     : out std_ulogic_vector(3 downto 0);
      dat_HTRANS    : out std_ulogic_vector(1 downto 0);
      dat_HMASTLOCK : out std_ulogic;
      dat_HREADY    : in  std_ulogic;
      dat_HRESP     : in  std_ulogic;

      ins_HSEL      : out std_ulogic;
      ins_HADDR     : out std_ulogic_vector(PLEN-1 downto 0);
      ins_HWDATA    : out std_ulogic_vector(XLEN-1 downto 0);
      ins_HRDATA    : in  std_ulogic_vector(XLEN-1 downto 0);
      ins_HWRITE    : out std_ulogic;
      ins_HSIZE     : out std_ulogic_vector(2 downto 0);
      ins_HBURST    : out std_ulogic_vector(2 downto 0);
      ins_HPROT     : out std_ulogic_vector(3 downto 0);
      ins_HTRANS    : out std_ulogic_vector(1 downto 0);
      ins_HMASTLOCK : out std_ulogic;
      ins_HREADY    : in  std_ulogic;
      ins_HRESP     : in  std_ulogic;

      --Interrupts
      ext_nmi  : in std_ulogic;
      ext_tint : in std_ulogic;
      ext_sint : in std_ulogic;
      ext_int  : in std_ulogic_vector(3 downto 0);

      --Debug Interface
      dbg_stall : in  std_ulogic;
      dbg_strb  : in  std_ulogic;
      dbg_we    : in  std_ulogic;
      dbg_addr  : in  std_ulogic_vector(PLEN-1 downto 0);
      dbg_dati  : in  std_ulogic_vector(XLEN-1 downto 0);
      dbg_dato  : out std_ulogic_vector(XLEN-1 downto 0);
      dbg_ack   : out std_ulogic;
      dbg_bp    : out std_ulogic
    );
  end component;

  component riscv_simd_memory_interconnect
    port (    --Common signals
    HRESETn : in std_ulogic;
    HCLK    : in std_ulogic;

    --Master Ports; AHB masters connect to these
    -- thus these are actually AHB Slave Interfaces
    mst_priority : in M_CORES_PER_SIMD_2;

    mst_HSEL      : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    mst_HADDR     : in  M_CORES_PER_SIMD_PLEN;
    mst_HWDATA    : in  M_CORES_PER_SIMD_XLEN;
    mst_HRDATA    : out M_CORES_PER_SIMD_XLEN;
    mst_HWRITE    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    mst_HSIZE     : in  M_CORES_PER_SIMD_2;
    mst_HBURST    : in  M_CORES_PER_SIMD_2;
    mst_HPROT     : in  M_CORES_PER_SIMD_3;
    mst_HTRANS    : in  M_CORES_PER_SIMD_1;
    mst_HMASTLOCK : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    mst_HREADYOUT : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    mst_HREADY    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    mst_HRESP     : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

    --Slave Ports; AHB Slaves connect to these
    --  thus these are actually AHB Master Interfaces
    slv_addr_mask : in M_CORES_PER_SIMD_PLEN;
    slv_addr_base : in M_CORES_PER_SIMD_PLEN;

    slv_HSEL      : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    slv_HADDR     : out M_CORES_PER_SIMD_PLEN;
    slv_HWDATA    : out M_CORES_PER_SIMD_XLEN;
    slv_HRDATA    : in  M_CORES_PER_SIMD_XLEN;
    slv_HWRITE    : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    slv_HSIZE     : out M_CORES_PER_SIMD_2;
    slv_HBURST    : out M_CORES_PER_SIMD_2;
    slv_HPROT     : out M_CORES_PER_SIMD_3;
    slv_HTRANS    : out M_CORES_PER_SIMD_1;
    slv_HMASTLOCK : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    slv_HREADYOUT : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);  --HREADYOUT to slave-decoder; generates HREADY to all connected slaves
    slv_HREADY    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);  --combinatorial HREADY from all connected slaves
    slv_HRESP     : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0)
    );
  end component;

  component riscv_simd_peripheral_interconnect
    port (    --Common signals
    --Common signals
    HRESETn : in std_ulogic;
    HCLK    : in std_ulogic;

    --Master Ports; AHB masters connect to these
    -- thus these are actually AHB Slave Interfaces
    mst_priority : in M_2_2;

    mst_HSEL      : in  std_ulogic_vector(2 downto 0);
    mst_HADDR     : in  M_2_PLEN;
    mst_HWDATA    : in  M_2_XLEN;
    mst_HRDATA    : out M_2_XLEN;
    mst_HWRITE    : in  std_ulogic_vector(2 downto 0);
    mst_HSIZE     : in  M_2_2;
    mst_HBURST    : in  M_2_2;
    mst_HPROT     : in  M_2_3;
    mst_HTRANS    : in  M_2_1;
    mst_HMASTLOCK : in  std_ulogic_vector(2 downto 0);
    mst_HREADYOUT : out std_ulogic_vector(2 downto 0);
    mst_HREADY    : in  std_ulogic_vector(2 downto 0);
    mst_HRESP     : out std_ulogic_vector(2 downto 0);

    --Slave Ports; AHB Slaves connect to these
    --  thus these are actually AHB Master Interfaces
    slv_addr_mask : in M_CORES_PER_SIMD1_PLEN;
    slv_addr_base : in M_CORES_PER_SIMD1_PLEN;

    slv_HSEL      : out std_ulogic_vector(CORES_PER_SIMD downto 0);
    slv_HADDR     : out M_CORES_PER_SIMD1_PLEN;
    slv_HWDATA    : out M_CORES_PER_SIMD1_XLEN;
    slv_HRDATA    : in  M_CORES_PER_SIMD1_XLEN;
    slv_HWRITE    : out std_ulogic_vector(CORES_PER_SIMD downto 0);
    slv_HSIZE     : out M_CORES_PER_SIMD1_2;
    slv_HBURST    : out M_CORES_PER_SIMD1_2;
    slv_HPROT     : out M_CORES_PER_SIMD1_3;
    slv_HTRANS    : out M_CORES_PER_SIMD1_1;
    slv_HMASTLOCK : out std_ulogic_vector(CORES_PER_SIMD downto 0);
    slv_HREADYOUT : out std_ulogic_vector(CORES_PER_SIMD downto 0);  --HREADYOUT to slave-decoder; generates HREADY to all connected slaves
    slv_HREADY    : in  std_ulogic_vector(CORES_PER_SIMD downto 0);  --combinatorial HREADY from all connected slaves
    slv_HRESP     : in  std_ulogic_vector(CORES_PER_SIMD downto 0)
    );
  end component;

  component riscv_noc_adapter
    generic (
      PLEN         : integer := 32;
      XLEN         : integer := 32;
      BUFFER_DEPTH : integer := 4;
      CHANNELS     : integer := 2
    );
    port (
      --Common signals
      HCLK    : in std_ulogic;
      HRESETn : in std_ulogic;

      --NoC Interface
      noc_out_flit  : out M_CHANNELS_PLEN;
      noc_out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
      noc_out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
      noc_out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0);

      noc_in_flit  : in M_CHANNELS_PLEN;
      noc_in_last  : in  std_ulogic_vector(CHANNELS-1 downto 0);
      noc_in_valid : in  std_ulogic_vector(CHANNELS-1 downto 0);
      noc_in_ready : out std_ulogic_vector(CHANNELS-1 downto 0);

      --AHB instruction interface
      mst_HSEL      : in  std_ulogic;
      mst_HADDR     : in  std_ulogic_vector(PLEN-1 downto 0);
      mst_HWDATA    : in  std_ulogic_vector(XLEN-1 downto 0);
      mst_HRDATA    : out std_ulogic_vector(XLEN-1 downto 0);
      mst_HWRITE    : in  std_ulogic;
      mst_HSIZE     : in  std_ulogic_vector(2 downto 0);
      mst_HBURST    : in  std_ulogic_vector(2 downto 0);
      mst_HPROT     : in  std_ulogic_vector(3 downto 0);
      mst_HTRANS    : in  std_ulogic_vector(1 downto 0);
      mst_HMASTLOCK : in  std_ulogic;
      mst_HREADYOUT : out std_ulogic;
      mst_HRESP     : out std_ulogic;

      --AHB data interface
      slv_HSEL      : out std_ulogic;
      slv_HADDR     : out std_ulogic_vector(PLEN-1 downto 0);
      slv_HWDATA    : out std_ulogic_vector(XLEN-1 downto 0);
      slv_HRDATA    : in  std_ulogic_vector(XLEN-1 downto 0);
      slv_HWRITE    : out std_ulogic;
      slv_HSIZE     : out std_ulogic_vector(2 downto 0);
      slv_HBURST    : out std_ulogic_vector(2 downto 0);
      slv_HPROT     : out std_ulogic_vector(3 downto 0);
      slv_HTRANS    : out std_ulogic_vector(1 downto 0);
      slv_HMASTLOCK : out std_ulogic;
      slv_HREADY    : in  std_ulogic;
      slv_HRESP     : in  std_ulogic
    );
  end component;

  component riscv_bridge
    generic (
      HADDR_SIZE : integer := 32;
      HDATA_SIZE : integer := 32;
      PADDR_SIZE : integer := 10;
      PDATA_SIZE : integer := 8;
      SYNC_DEPTH : integer := 3
    );
    port (
      --AHB Slave Interface
      HRESETn   : in  std_ulogic;
      HCLK      : in  std_ulogic;
      HSEL      : in  std_ulogic;
      HADDR     : in  std_ulogic_vector(HADDR_SIZE-1 downto 0);
      HWDATA    : in  std_ulogic_vector(HDATA_SIZE-1 downto 0);
      HRDATA    : out std_ulogic_vector(HDATA_SIZE-1 downto 0);
      HWRITE    : in  std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
      HSIZE     : in  std_ulogic_vector(2 downto 0);
      HBURST    : in  std_ulogic_vector(2 downto 0);
      HPROT     : in  std_ulogic_vector(3 downto 0);
      HTRANS    : in  std_ulogic_vector(1 downto 0);
      HMASTLOCK : in  std_ulogic;
      HREADYOUT : out std_ulogic;
      HREADY    : in  std_ulogic;
      HRESP     : out std_ulogic;

      --APB Master Interface
      PRESETn : in  std_ulogic;
      PCLK    : in  std_ulogic;
      PSEL    : out std_ulogic;
      PENABLE : out std_ulogic;
      PPROT   : out std_ulogic_vector(2 downto 0);
      PWRITE  : out std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
      PSTRB   : out std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
      PADDR   : out std_ulogic_vector(PADDR_SIZE-1 downto 0);
      PWDATA  : out std_ulogic_vector(PDATA_SIZE-1 downto 0);
      PRDATA  : in  std_ulogic_vector(PDATA_SIZE-1 downto 0);
      PREADY  : in  std_ulogic;
      PSLVERR : in  std_ulogic
    );
  end component;

  component riscv_gpio
    port (
      PRESETn : in std_ulogic;
      PCLK    : in std_ulogic;

      PSEL    : in  std_ulogic;
      PENABLE : in  std_ulogic;
      PWRITE  : in  std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
      PSTRB   : in  std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
      PADDR   : in  std_ulogic_vector(PADDR_SIZE-1 downto 0);
      PWDATA  : in  std_ulogic_vector(PDATA_SIZE-1 downto 0);
      PRDATA  : out std_ulogic_vector(PDATA_SIZE-1 downto 0);
      PREADY  : out std_ulogic;
      PSLVERR : out std_ulogic;

      gpio_i  : in  std_ulogic_vector(PDATA_SIZE-1 downto 0);
      gpio_o  : out std_ulogic_vector(PDATA_SIZE-1 downto 0);
      gpio_oe : out std_ulogic_vector(PDATA_SIZE-1 downto 0)
    );
  end component;

  component riscv_simd_mpram
    generic (
      MEM_SIZE          : integer := 0;    --Memory in Bytes
      MEM_DEPTH         : integer := 256;  --Memory depth
      PLEN              : integer := 64;
      XLEN              : integer := 32;
      TECHNOLOGY        : string  := "GENERIC";
      REGISTERED_OUTPUT : string  := "NO"
    );
    port (
      HRESETn : in std_ulogic;
      HCLK    : in std_ulogic;

      --AHB Slave Interfaces (receive data from AHB Masters)
      --AHB Masters connect to these ports
      HSEL      : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
      HADDR     : in  M_CORES_PER_SIMD_PLEN;
      HWDATA    : in  M_CORES_PER_SIMD_XLEN;
      HRDATA    : out M_CORES_PER_SIMD_XLEN;
      HWRITE    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
      HSIZE     : in  M_CORES_PER_SIMD_2;
      HBURST    : in  M_CORES_PER_SIMD_2;
      HPROT     : in  M_CORES_PER_SIMD_3;
      HTRANS    : in  M_CORES_PER_SIMD_1;
      HMASTLOCK : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
      HREADYOUT : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
      HREADY    : in  std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
      HRESP     : out std_ulogic_vector(CORES_PER_SIMD-1 downto 0)
    );
  end component;

  component riscv_spram
    generic (
      MEM_SIZE          : integer := 0;    --Memory in Bytes
      MEM_DEPTH         : integer := 256;  --Memory depth
      PLEN              : integer := 64;
      XLEN              : integer := 32;
      TECHNOLOGY        : string  := "GENERIC";
      REGISTERED_OUTPUT : string  := "NO"
    );
    port (
      HRESETn : in std_ulogic;
      HCLK    : in std_ulogic;

      --AHB Slave Interfaces (receive data from AHB Masters)
      --AHB Masters connect to these ports
      HSEL      : in  std_ulogic;
      HADDR     : in  std_ulogic_vector(PLEN-1 downto 0);
      HWDATA    : in  std_ulogic_vector(XLEN-1 downto 0);
      HRDATA    : out std_ulogic_vector(XLEN-1 downto 0);
      HWRITE    : in  std_ulogic;
      HSIZE     : in  std_ulogic_vector(2 downto 0);
      HBURST    : in  std_ulogic_vector(2 downto 0);
      HPROT     : in  std_ulogic_vector(3 downto 0);
      HTRANS    : in  std_ulogic_vector(1 downto 0);
      HMASTLOCK : in  std_ulogic;
      HREADYOUT : out std_ulogic;
      HREADY    : in  std_ulogic;
      HRESP     : out std_ulogic
    );
  end component;

  component riscv_debug_ring_expand
    port (
      clk : in std_ulogic;
      rst : in std_ulogic;

      id_map : in M_NODES_15;

      dii_in_data  : in  M_NODES_XLEN;
      dii_in_last  : in  std_ulogic_vector(NODES-1 downto 0);
      dii_in_valid : in  std_ulogic_vector(NODES-1 downto 0);
      dii_in_ready : out std_ulogic_vector(NODES-1 downto 0);

      dii_out_data  : out M_NODES_XLEN;
      dii_out_last  : out std_ulogic_vector(NODES-1 downto 0);
      dii_out_valid : out std_ulogic_vector(NODES-1 downto 0);
      dii_out_ready : in  std_ulogic_vector(NODES-1 downto 0);

      ext_in_data  : in  M_CHANNELS_XLEN;
      ext_in_last  : in  std_ulogic_vector(CHANNELS-1 downto 0);
      ext_in_valid : in  std_ulogic_vector(CHANNELS-1 downto 0);
      ext_in_ready : out std_ulogic_vector(CHANNELS-1 downto 0);  -- extension input ports

      ext_out_data  : out M_CHANNELS_XLEN;
      ext_out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
      ext_out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
      ext_out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0)  -- extension output ports
    );
  end component;

  component riscv_osd_ctm_template
    port (
      clk : in std_ulogic;
      rst : in std_ulogic;

      id : in std_ulogic_vector(15 downto 0);

      debug_in_data  : in  std_ulogic_vector(DATA_WIDTH-1 downto 0);
      debug_in_last  : in  std_ulogic;
      debug_in_valid : in  std_ulogic;
      debug_in_ready : out std_ulogic;

      debug_out_data  : out std_ulogic_vector(DATA_WIDTH-1 downto 0);
      debug_out_last  : out std_ulogic;
      debug_out_valid : out std_ulogic;
      debug_out_ready : in  std_ulogic;

      trace_port_insn     : in std_ulogic_vector(XLEN-1 downto 0);
      trace_port_pc       : in std_ulogic_vector(XLEN-1 downto 0);
      trace_port_jb       : in std_ulogic;
      trace_port_jal      : in std_ulogic;
      trace_port_jr       : in std_ulogic;
      trace_port_jbtarget : in std_ulogic_vector(XLEN-1 downto 0);
      trace_port_valid    : in std_ulogic;
      trace_port_data     : in std_ulogic_vector(VALWIDTH-1 downto 0);
      trace_port_addr     : in std_ulogic_vector(4 downto 0);
      trace_port_we       : in std_ulogic
    );
  end component;

  component riscv_osd_stm_template
    port (
      clk : in std_ulogic;
      rst : in std_ulogic;

      id : in std_ulogic_vector(15 downto 0);

      debug_in_data  : in  std_ulogic_vector(XLEN-1 downto 0);
      debug_in_last  : in  std_ulogic;
      debug_in_valid : in  std_ulogic;
      debug_in_ready : out std_ulogic;

      debug_out_data  : out std_ulogic_vector(XLEN-1 downto 0);
      debug_out_last  : out std_ulogic;
      debug_out_valid : out std_ulogic;
      debug_out_ready : in  std_ulogic;

      trace_port_insn     : in std_ulogic_vector(XLEN-1 downto 0);
      trace_port_pc       : in std_ulogic_vector(XLEN-1 downto 0);
      trace_port_jb       : in std_ulogic;
      trace_port_jal      : in std_ulogic;
      trace_port_jr       : in std_ulogic;
      trace_port_jbtarget : in std_ulogic_vector(XLEN-1 downto 0);
      trace_port_valid    : in std_ulogic;
      trace_port_data     : in std_ulogic_vector(VALWIDTH-1 downto 0);
      trace_port_addr     : in std_ulogic_vector(4 downto 0);
      trace_port_we       : in std_ulogic
    );
  end component;

  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --
  constant SIMD_BITS : integer := integer(log2(real(CORES_PER_SIMD)));

  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --
  function to_stdlogic (
    input : boolean
  ) return std_ulogic is
  begin
    if input then
      return('1');
    else
      return('0');
    end if;
  end function to_stdlogic;

  function reduce_or (
    reduce_or_in : std_ulogic_vector
  ) return std_ulogic is
    variable reduce_or_out : std_ulogic := '0';
  begin
    for i in reduce_or_in'range loop
      reduce_or_out := reduce_or_out or reduce_or_in(i);
    end loop;
    return reduce_or_out;
  end reduce_or;

  function onehot2int (
    onehot : std_ulogic_vector(CORES_PER_SIMD-1 downto 0)
  ) return integer is
    variable onehot2int_return : integer := -1;

    variable onehot_return : std_ulogic_vector(CORES_PER_SIMD-1 downto 0) := onehot;
  begin
    while (reduce_or(onehot) = '1') loop
      onehot2int_return := onehot2int_return + 1;
      onehot_return     := std_ulogic_vector(unsigned(onehot_return) srl 1);
    end loop;
    return onehot2int_return;
  end onehot2int;  --onehot2int

  function highest_requested_priority (
    hsel : std_ulogic_vector(CORES_PER_SIMD-1 downto 0)
  ) return std_ulogic_vector is
    variable priorities : M_CORES_PER_SIMD_2;
    variable highest_requested_priority_return : std_ulogic_vector (2 downto 0);
  begin
    highest_requested_priority_return := (others => '0');
    for n in 0 to CORES_PER_SIMD - 1 loop
      if (hsel(n) = '1' and unsigned(priorities(n)) > unsigned(highest_requested_priority_return)) then
        highest_requested_priority_return := priorities(n);
      end if;
    end loop;
    return highest_requested_priority_return;
  end highest_requested_priority;  --highest_requested_priority

  function requesters (
    hsel            : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
    priority_select : std_ulogic_vector(2 downto 0)

  ) return std_ulogic_vector is
    variable priorities : M_CORES_PER_SIMD_2;
    variable requesters_return : std_ulogic_vector (CORES_PER_SIMD-1 downto 0);
  begin
    for n in 0 to CORES_PER_SIMD - 1 loop
      requesters_return(n) := to_stdlogic(priorities(n) = priority_select) and hsel(n);
    end loop;
    return requesters_return;
  end requesters;  --requesters

  function nxt_simd_master (
    pending_simd_masters : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);  --pending masters for the requesed priority level
    last_simd_master     : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);  --last granted master for the priority level
    current_simd_master  : std_ulogic_vector(CORES_PER_SIMD-1 downto 0)  --current granted master (indpendent of priority level)
  ) return std_ulogic_vector is
    variable offset                 : integer;
    variable sr                     : std_ulogic_vector(CORES_PER_SIMD*2-1 downto 0);
    variable nxt_simd_master_return : std_ulogic_vector (CORES_PER_SIMD-1 downto 0);
  begin
    --default value, don't switch if not needed
    nxt_simd_master_return := current_simd_master;

    --implement round-robin
    offset := onehot2int(last_simd_master)+1;

    sr := (pending_simd_masters & pending_simd_masters);
    for n in 0 to CORES_PER_SIMD - 1 loop
      if (sr(n+offset) = '1') then
        return std_ulogic_vector(to_unsigned(2**((n+offset) mod CORES_PER_SIMD), CORES_PER_SIMD));
      end if;
    end loop;
    return nxt_simd_master_return;
  end nxt_simd_master;

  --//////////////////////////////////////////////////////////////
  --
  -- Types
  --
  type M_2_CORES_PER_SIMD is array (2 downto 0) of std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  type M_CORES_PER_SIMD_4 is array (CORES_PER_SIMD-1 downto 0) of std_ulogic_vector(4 downto 0);
  --//////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  --AHB Bus Master Interfaces
  signal mst_noc_HSEL      : std_ulogic;
  signal mst_noc_HADDR     : std_ulogic_vector(PLEN-1 downto 0);
  signal mst_noc_HWDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal mst_noc_HRDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal mst_noc_HWRITE    : std_ulogic;
  signal mst_noc_HSIZE     : std_ulogic_vector(2 downto 0);
  signal mst_noc_HBURST    : std_ulogic_vector(2 downto 0);
  signal mst_noc_HPROT     : std_ulogic_vector(3 downto 0);
  signal mst_noc_HTRANS    : std_ulogic_vector(1 downto 0);
  signal mst_noc_HMASTLOCK : std_ulogic;
  signal mst_noc_HREADYOUT : std_ulogic;
  signal mst_noc_HRESP     : std_ulogic;

  signal mst_gpio_HSEL      : std_ulogic;
  signal mst_gpio_HADDR     : std_ulogic_vector(PLEN-1 downto 0);
  signal mst_gpio_HWDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal mst_gpio_HRDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal mst_gpio_HWRITE    : std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
  signal mst_gpio_HSIZE     : std_ulogic_vector(2 downto 0);
  signal mst_gpio_HBURST    : std_ulogic_vector(2 downto 0);
  signal mst_gpio_HPROT     : std_ulogic_vector(3 downto 0);
  signal mst_gpio_HTRANS    : std_ulogic_vector(1 downto 0);
  signal mst_gpio_HMASTLOCK : std_ulogic;
  signal mst_gpio_HREADY    : std_ulogic;
  signal mst_gpio_HREADYOUT : std_ulogic;
  signal mst_gpio_HRESP     : std_ulogic;

  signal gpio_PSEL    : std_ulogic;
  signal gpio_PENABLE : std_ulogic;
  signal gpio_PWRITE  : std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
  signal gpio_PSTRB   : std_ulogic_vector(PDATA_SIZE/8-1 downto 0);
  signal gpio_PADDR   : std_ulogic_vector(PADDR_SIZE-1 downto 0);
  signal gpio_PWDATA  : std_ulogic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_PRDATA  : std_ulogic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_PREADY  : std_ulogic;
  signal gpio_PSLVERR : std_ulogic;

  signal mst_sram_HSEL      : std_ulogic;
  signal mst_sram_HADDR     : std_ulogic_vector(PLEN-1 downto 0);
  signal mst_sram_HWDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal mst_sram_HRDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal mst_sram_HWRITE    : std_ulogic;
  signal mst_sram_HSIZE     : std_ulogic_vector(2 downto 0);
  signal mst_sram_HBURST    : std_ulogic_vector(2 downto 0);
  signal mst_sram_HPROT     : std_ulogic_vector(3 downto 0);
  signal mst_sram_HTRANS    : std_ulogic_vector(1 downto 0);
  signal mst_sram_HMASTLOCK : std_ulogic;
  signal mst_sram_HREADY    : std_ulogic;
  signal mst_sram_HREADYOUT : std_ulogic;
  signal mst_sram_HRESP     : std_ulogic;

  signal mst_mram_HSEL      : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_mram_HADDR     : M_CORES_PER_SIMD_PLEN;
  signal mst_mram_HWDATA    : M_CORES_PER_SIMD_XLEN;
  signal mst_mram_HRDATA    : M_CORES_PER_SIMD_XLEN;
  signal mst_mram_HWRITE    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_mram_HSIZE     : M_CORES_PER_SIMD_2;
  signal mst_mram_HBURST    : M_CORES_PER_SIMD_2;
  signal mst_mram_HPROT     : M_CORES_PER_SIMD_3;
  signal mst_mram_HTRANS    : M_CORES_PER_SIMD_1;
  signal mst_mram_HMASTLOCK : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_mram_HREADY    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_mram_HREADYOUT : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_mram_HRESP     : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

  signal mst_msi_mram_HRDATA    : M_CORES_PER_SIMD_XLEN;
  signal mst_msi_mram_HREADYOUT : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal mst_msi_mram_HRESP     : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

  signal mst_HSEL      : std_ulogic_vector(2 downto 0);
  signal mst_HADDR     : M_2_PLEN;
  signal mst_HWDATA    : M_2_XLEN;
  signal mst_HRDATA    : M_2_XLEN;
  signal mst_HWRITE    : std_ulogic_vector(2 downto 0);
  signal mst_HSIZE     : M_2_2;
  signal mst_HBURST    : M_2_2;
  signal mst_HPROT     : M_2_3;
  signal mst_HTRANS    : M_2_1;
  signal mst_HMASTLOCK : std_ulogic_vector(2 downto 0);
  signal mst_HREADY    : std_ulogic_vector(2 downto 0);
  signal mst_HREADYOUT : std_ulogic_vector(2 downto 0);
  signal mst_HRESP     : std_ulogic_vector(2 downto 0);

  --AHB Bus Slaves Interfaces
  signal out_dat_HSEL      : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal out_dat_HADDR     : M_CORES_PER_SIMD_PLEN;
  signal out_dat_HWDATA    : M_CORES_PER_SIMD_XLEN;
  signal out_dat_HRDATA    : M_CORES_PER_SIMD_XLEN;
  signal out_dat_HWRITE    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal out_dat_HSIZE     : M_CORES_PER_SIMD_2;
  signal out_dat_HBURST    : M_CORES_PER_SIMD_2;
  signal out_dat_HPROT     : M_CORES_PER_SIMD_3;
  signal out_dat_HTRANS    : M_CORES_PER_SIMD_1;
  signal out_dat_HMASTLOCK : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal out_dat_HREADY    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal out_dat_HREADYOUT : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal out_dat_HRESP     : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

  signal out_ins_HSEL      : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal out_ins_HADDR     : M_CORES_PER_SIMD_PLEN;
  signal out_ins_HWDATA    : M_CORES_PER_SIMD_XLEN;
  signal out_ins_HRDATA    : M_CORES_PER_SIMD_XLEN;
  signal out_ins_HWRITE    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal out_ins_HSIZE     : M_CORES_PER_SIMD_2;
  signal out_ins_HBURST    : M_CORES_PER_SIMD_2;
  signal out_ins_HPROT     : M_CORES_PER_SIMD_3;
  signal out_ins_HTRANS    : M_CORES_PER_SIMD_1;
  signal out_ins_HMASTLOCK : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal out_ins_HREADY    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal out_ins_HRESP     : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

  signal bus_ins_HSEL      : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal bus_ins_HADDR     : M_CORES_PER_SIMD_PLEN;
  signal bus_ins_HWDATA    : M_CORES_PER_SIMD_XLEN;
  signal bus_ins_HRDATA    : M_CORES_PER_SIMD_XLEN;
  signal bus_ins_HWRITE    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal bus_ins_HSIZE     : M_CORES_PER_SIMD_2;
  signal bus_ins_HBURST    : M_CORES_PER_SIMD_2;
  signal bus_ins_HPROT     : M_CORES_PER_SIMD_3;
  signal bus_ins_HTRANS    : M_CORES_PER_SIMD_1;
  signal bus_ins_HMASTLOCK : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal bus_ins_HREADY    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal bus_ins_HRESP     : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

  signal slv_noc_HSEL      : std_ulogic;
  signal slv_noc_HADDR     : std_ulogic_vector(PLEN-1 downto 0);
  signal slv_noc_HWDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal slv_noc_HRDATA    : std_ulogic_vector(XLEN-1 downto 0);
  signal slv_noc_HWRITE    : std_ulogic;
  signal slv_noc_HSIZE     : std_ulogic_vector(2 downto 0);
  signal slv_noc_HBURST    : std_ulogic_vector(2 downto 0);
  signal slv_noc_HPROT     : std_ulogic_vector(3 downto 0);
  signal slv_noc_HTRANS    : std_ulogic_vector(1 downto 0);
  signal slv_noc_HMASTLOCK : std_ulogic;
  signal slv_noc_HREADY    : std_ulogic;
  signal slv_noc_HRESP     : std_ulogic;

  signal slv_HSEL      : std_ulogic_vector(CORES_PER_SIMD downto 0);
  signal slv_HADDR     : M_CORES_PER_SIMD1_PLEN;
  signal slv_HWDATA    : M_CORES_PER_SIMD1_XLEN;
  signal slv_HRDATA    : M_CORES_PER_SIMD1_XLEN;
  signal slv_HWRITE    : std_ulogic_vector(CORES_PER_SIMD downto 0);
  signal slv_HSIZE     : M_CORES_PER_SIMD1_2;
  signal slv_HBURST    : M_CORES_PER_SIMD1_2;
  signal slv_HPROT     : M_CORES_PER_SIMD1_3;
  signal slv_HTRANS    : M_CORES_PER_SIMD1_1;
  signal slv_HMASTLOCK : std_ulogic_vector(CORES_PER_SIMD downto 0);
  signal slv_HREADY    : std_ulogic_vector(CORES_PER_SIMD downto 0);
  signal slv_HRESP     : std_ulogic_vector(CORES_PER_SIMD downto 0);

  signal requested_priority_lvl : std_ulogic_vector(2 downto 0);  --requested priority level
  signal priority_simd_masters  : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);  --all masters at this priority level

  signal pending_simd_master      : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);  --next master waiting to be served
  signal last_granted_simd_master : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);  --for requested priority level

  signal last_granted_simd_masters : M_2_CORES_PER_SIMD;  --per priority level, for round-robin


  signal granted_simd_master_idx     : std_ulogic_vector(SIMD_BITS-1 downto 0);  --granted master as index
  signal granted_simd_master_idx_dly : std_ulogic_vector(SIMD_BITS-1 downto 0);  --deleayed granted master index (for HWDATA)

  signal granted_simd_master : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

  signal dii_in_data  : M_2CORES_PER_SIMD_XLEN;
  signal dii_in_last  : std_ulogic_vector(2*CORES_PER_SIMD-1 downto 0);
  signal dii_in_valid : std_ulogic_vector(2*CORES_PER_SIMD-1 downto 0);
  signal dii_in_ready : std_ulogic_vector(2*CORES_PER_SIMD-1 downto 0);

  signal dii_out_data  : M_2CORES_PER_SIMD_XLEN;
  signal dii_out_last  : std_ulogic_vector(2*CORES_PER_SIMD-1 downto 0);
  signal dii_out_valid : std_ulogic_vector(2*CORES_PER_SIMD-1 downto 0);
  signal dii_out_ready : std_ulogic_vector(2*CORES_PER_SIMD-1 downto 0);

  signal trace_port_insn     : M_CORES_PER_SIMD_XLEN;
  signal trace_port_pc       : M_CORES_PER_SIMD_XLEN;
  signal trace_port_jb       : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal trace_port_jal      : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal trace_port_jr       : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal trace_port_jbtarget : M_CORES_PER_SIMD_XLEN;
  signal trace_port_valid    : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);
  signal trace_port_data     : M_CORES_PER_SIMD_VALWIDTH;
  signal trace_port_addr     : M_CORES_PER_SIMD_4;
  signal trace_port_we       : std_ulogic_vector(CORES_PER_SIMD-1 downto 0);

  signal ins_HSEL_sgn : std_ulogic;

begin
  --//////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --Instantiate RISC-V PU
  generating_0 : for t in 0 to CORES_PER_SIMD - 1 generate
    pu : riscv_pu
      port map (
        --Common signals
        HRESETn => HRESETn,
        HCLK    => HCLK,

        --PMA configuration
        pma_cfg_i => pma_cfg_i,
        pma_adr_i => pma_adr_i,

        --AHB instruction
        dat_HSEL      => dat_HSEL(t),
        dat_HADDR     => dat_HADDR(t),
        dat_HWDATA    => dat_HWDATA(t),
        dat_HRDATA    => dat_HRDATA(t),
        dat_HWRITE    => dat_HWRITE(t),
        dat_HSIZE     => dat_HSIZE(t),
        dat_HBURST    => dat_HBURST(t),
        dat_HPROT     => dat_HPROT(t),
        dat_HTRANS    => dat_HTRANS(t),
        dat_HMASTLOCK => dat_HMASTLOCK(t),
        dat_HREADY    => dat_HREADY(t),
        dat_HRESP     => dat_HRESP(t),

        --AHB data
        ins_HSEL      => bus_ins_HSEL(t),
        ins_HADDR     => bus_ins_HADDR(t),
        ins_HWDATA    => bus_ins_HWDATA(t),
        ins_HRDATA    => bus_ins_HRDATA(t),
        ins_HWRITE    => bus_ins_HWRITE(t),
        ins_HSIZE     => bus_ins_HSIZE(t),
        ins_HBURST    => bus_ins_HBURST(t),
        ins_HPROT     => bus_ins_HPROT(t),
        ins_HTRANS    => bus_ins_HTRANS(t),
        ins_HMASTLOCK => bus_ins_HMASTLOCK(t),
        ins_HREADY    => bus_ins_HREADY(t),
        ins_HRESP     => bus_ins_HRESP(t),

        --Interrupts Interface
        ext_nmi  => ext_nmi(t),
        ext_tint => ext_tint(t),
        ext_sint => ext_sint(t),
        ext_int  => ext_int(t),

        --Debug Interface
        dbg_stall => dbg_stall(t),
        dbg_strb  => dbg_strb(t),
        dbg_we    => dbg_we(t),
        dbg_addr  => dbg_addr(t),
        dbg_dati  => dbg_dati(t),
        dbg_dato  => dbg_dato(t),
        dbg_ack   => dbg_ack(t),
        dbg_bp    => dbg_bp(t)
      );
  end generate;

  --get highest priority from selected masters
  requested_priority_lvl <= highest_requested_priority(bus_ins_HSEL);

  --get pending masters for the highest priority requested
  priority_simd_masters <= requesters(bus_ins_HSEL, requested_priority_lvl);

  --get last granted master for the priority requested
  last_granted_simd_master <= last_granted_simd_masters(to_integer(unsigned(requested_priority_lvl)));

  --get next master to serve
  pending_simd_master <= nxt_simd_master(priority_simd_masters, last_granted_simd_master, granted_simd_master);

  --select new master
  processing_0 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      granted_simd_master <= (0 => '1', others => '0');
    elsif (rising_edge(HCLK)) then
      if (ins_HSEL_sgn = '0') then

        granted_simd_master <= pending_simd_master;
      end if;
    end if;
  end process;

  --store current master (for this priority level)
  processing_1 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      last_granted_simd_masters(to_integer(unsigned(requested_priority_lvl))) <= (0 => '1', others => '0');
    elsif (rising_edge(HCLK)) then
      if (ins_HSEL_sgn = '0') then
        last_granted_simd_masters(to_integer(unsigned(requested_priority_lvl))) <= pending_simd_master;
      end if;
    end if;
  end process;

  --get signals from current requester
  processing_2 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      granted_simd_master_idx <= (others => '0');
    elsif (rising_edge(HCLK)) then
      if (ins_HSEL_sgn = '0') then
        granted_simd_master_idx <= std_ulogic_vector(to_unsigned(onehot2int(pending_simd_master), SIMD_BITS));
      end if;
    end if;
  end process;

  processing_3 : process (HCLK)
  begin
    if (rising_edge(HCLK)) then
      if (ins_HSEL_sgn = '1') then
        granted_simd_master_idx_dly <= granted_simd_master_idx;
      end if;
    end if;
  end process;

  ins_HSEL_sgn  <= bus_ins_HSEL(to_integer(unsigned(granted_simd_master_idx)));
  ins_HADDR     <= bus_ins_HADDR(to_integer(unsigned(granted_simd_master_idx)));
  ins_HWDATA    <= bus_ins_HWDATA(to_integer(unsigned(granted_simd_master_idx_dly)));
  ins_HWRITE    <= bus_ins_HWRITE(to_integer(unsigned(granted_simd_master_idx)));
  ins_HSIZE     <= bus_ins_HSIZE(to_integer(unsigned(granted_simd_master_idx)));
  ins_HBURST    <= bus_ins_HBURST(to_integer(unsigned(granted_simd_master_idx)));
  ins_HPROT     <= bus_ins_HPROT(to_integer(unsigned(granted_simd_master_idx)));
  ins_HTRANS    <= bus_ins_HTRANS(to_integer(unsigned(granted_simd_master_idx)));
  ins_HMASTLOCK <= bus_ins_HMASTLOCK(to_integer(unsigned(granted_simd_master_idx)));

  ins_HSEL <= ins_HSEL_sgn;

  generating_1 : for t in 0 to CORES_PER_SIMD - 1 generate
    bus_ins_HRDATA(t) <= ins_HRDATA;
    bus_ins_HREADY(t) <= ins_HREADY;
    bus_ins_HRESP(t)  <= ins_HRESP;
  end generate;

  --AHB Master-Slave Relations
  out_ins_HSEL      <= bus_ins_HSEL;
  out_ins_HADDR     <= bus_ins_HADDR;
  out_ins_HWDATA    <= bus_ins_HWDATA;
  out_ins_HWRITE    <= bus_ins_HWRITE;
  out_ins_HSIZE     <= bus_ins_HSIZE;
  out_ins_HBURST    <= bus_ins_HBURST;
  out_ins_HPROT     <= bus_ins_HPROT;
  out_ins_HTRANS    <= bus_ins_HTRANS;
  out_ins_HMASTLOCK <= bus_ins_HMASTLOCK;

  bus_ins_HRDATA <= out_ins_HRDATA;
  bus_ins_HREADY <= out_ins_HREADY;
  bus_ins_HRESP  <= out_ins_HRESP;

  dat_HSEL      <= out_dat_HSEL;
  dat_HADDR     <= out_dat_HADDR;
  dat_HWDATA    <= out_dat_HWDATA;
  dat_HWRITE    <= out_dat_HWRITE;
  dat_HSIZE     <= out_dat_HSIZE;
  dat_HBURST    <= out_dat_HBURST;
  dat_HPROT     <= out_dat_HPROT;
  dat_HTRANS    <= out_dat_HTRANS;
  dat_HMASTLOCK <= out_dat_HMASTLOCK;
  --assign dat_HREADYOUT = out_dat_HREADYOUT;

  out_dat_HRDATA <= dat_HRDATA;
  out_dat_HREADY <= dat_HREADY;
  out_dat_HRESP  <= dat_HRESP;

  --AHB Master Interconnect
  mst_HSEL(0)      <= mst_noc_HSEL;
  mst_HADDR(0)     <= mst_noc_HADDR;
  mst_HWDATA(0)    <= mst_noc_HWDATA;
  mst_HWRITE(0)    <= mst_noc_HWRITE;
  mst_HSIZE(0)     <= mst_noc_HSIZE;
  mst_HBURST(0)    <= mst_noc_HBURST;
  mst_HPROT(0)     <= mst_noc_HPROT;
  mst_HTRANS(0)    <= mst_noc_HTRANS;
  mst_HMASTLOCK(0) <= mst_noc_HMASTLOCK;

  mst_HRDATA(0)    <= mst_noc_HRDATA;
  mst_HREADYOUT(0) <= mst_noc_HREADYOUT;
  mst_HRESP(0)     <= mst_noc_HRESP;

  mst_HSEL(1)      <= mst_gpio_HSEL;
  mst_HADDR(1)     <= mst_gpio_HADDR;
  mst_HWDATA(1)    <= mst_gpio_HWDATA;
  mst_HWRITE(1)    <= mst_gpio_HWRITE(0);
  mst_HSIZE(1)     <= mst_gpio_HSIZE;
  mst_HBURST(1)    <= mst_gpio_HBURST;
  mst_HPROT(1)     <= mst_gpio_HPROT;
  mst_HTRANS(1)    <= mst_gpio_HTRANS;
  mst_HMASTLOCK(1) <= mst_gpio_HMASTLOCK;
  mst_HREADY(1)    <= mst_gpio_HREADY;

  mst_HRDATA(1)    <= mst_gpio_HRDATA;
  mst_HREADYOUT(1) <= mst_gpio_HREADYOUT;
  mst_HRESP(1)     <= mst_gpio_HRESP;

  mst_HSEL(2)      <= mst_sram_HSEL;
  mst_HADDR(2)     <= mst_sram_HADDR;
  mst_HWDATA(2)    <= mst_sram_HWDATA;
  mst_HWRITE(2)    <= mst_sram_HWRITE;
  mst_HSIZE(2)     <= mst_sram_HSIZE;
  mst_HBURST(2)    <= mst_sram_HBURST;
  mst_HPROT(2)     <= mst_sram_HPROT;
  mst_HTRANS(2)    <= mst_sram_HTRANS;
  mst_HMASTLOCK(2) <= mst_sram_HMASTLOCK;
  mst_HREADY(2)    <= mst_sram_HREADY;

  mst_HRDATA(2)    <= mst_sram_HRDATA;
  mst_HREADYOUT(2) <= mst_sram_HREADYOUT;
  mst_HRESP(2)     <= mst_sram_HRESP;

  --AHB Slave Interconnect
  generating_2 : for t in 0 to CORES_PER_SIMD - 1 generate
    out_ins_HSEL(t)      <= slv_HSEL(t);
    out_ins_HADDR(t)     <= slv_HADDR(t);
    out_ins_HWDATA(t)    <= slv_HWDATA(t);
    out_ins_HWRITE(t)    <= slv_HWRITE(t);
    out_ins_HSIZE(t)     <= slv_HSIZE(t);
    out_ins_HBURST(t)    <= slv_HBURST(t);
    out_ins_HPROT(t)     <= slv_HPROT(t);
    out_ins_HTRANS(t)    <= slv_HTRANS(t);
    out_ins_HMASTLOCK(t) <= slv_HMASTLOCK(t);
  end generate;

  generating_3 : for t in 0 to CORES_PER_SIMD - 1 generate
    slv_HRDATA(t) <= out_ins_HRDATA(t);
    slv_HREADY(t) <= out_ins_HREADY(t);
    slv_HRESP(t)  <= out_ins_HRESP(t);
  end generate;

  slv_HSEL(CORES_PER_SIMD)      <= slv_noc_HSEL;
  slv_HADDR(CORES_PER_SIMD)     <= slv_noc_HADDR;
  slv_HWDATA(CORES_PER_SIMD)    <= slv_noc_HWDATA;
  slv_HWRITE(CORES_PER_SIMD)    <= slv_noc_HWRITE;
  slv_HSIZE(CORES_PER_SIMD)     <= slv_noc_HSIZE;
  slv_HBURST(CORES_PER_SIMD)    <= slv_noc_HBURST;
  slv_HPROT(CORES_PER_SIMD)     <= slv_noc_HPROT;
  slv_HTRANS(CORES_PER_SIMD)    <= slv_noc_HTRANS;
  slv_HMASTLOCK(CORES_PER_SIMD) <= slv_noc_HMASTLOCK;

  slv_HRDATA(CORES_PER_SIMD) <= slv_noc_HRDATA;
  slv_HREADY(CORES_PER_SIMD) <= slv_noc_HREADY;
  slv_HRESP(CORES_PER_SIMD)  <= slv_noc_HRESP;

  --Instantiate RISC-V Interconnect
  simd_peripheral_interconnect : riscv_simd_peripheral_interconnect
    port map (
      --Common signals
      HRESETn => HRESETn,
      HCLK    => HCLK,

      --Master Ports; AHB masters connect to these
      --thus these are actually AHB Slave Interfaces
      mst_priority => (others => (others => '0')),

      mst_HSEL      => mst_HSEL,
      mst_HADDR     => mst_HADDR,
      mst_HWDATA    => mst_HWDATA,
      mst_HRDATA    => mst_HRDATA,
      mst_HWRITE    => mst_HWRITE,
      mst_HSIZE     => mst_HSIZE,
      mst_HBURST    => mst_HBURST,
      mst_HPROT     => mst_HPROT,
      mst_HTRANS    => mst_HTRANS,
      mst_HMASTLOCK => mst_HMASTLOCK,
      mst_HREADYOUT => mst_HREADYOUT,
      mst_HREADY    => mst_HREADY,
      mst_HRESP     => mst_HRESP,

      --Slave Ports; AHB Slaves connect to these
      --thus these are actually AHB Master Interfaces
      slv_addr_mask => (others => (others => '0')),
      slv_addr_base => (others => (others => '0')),


      slv_HSEL      => slv_HSEL,
      slv_HADDR     => slv_HADDR,
      slv_HWDATA    => slv_HWDATA,
      slv_HRDATA    => slv_HRDATA,
      slv_HWRITE    => slv_HWRITE,
      slv_HSIZE     => slv_HSIZE,
      slv_HBURST    => slv_HBURST,
      slv_HPROT     => slv_HPROT,
      slv_HTRANS    => slv_HTRANS,
      slv_HMASTLOCK => slv_HMASTLOCK,
      slv_HREADYOUT => open,
      slv_HREADY    => slv_HREADY,
      slv_HRESP     => slv_HRESP
    );

  simd_memory_interconnect : riscv_simd_memory_interconnect
    port map (
      --Common signals
      HRESETn => HRESETn,
      HCLK    => HCLK,

      --Master Ports; AHB masters connect to these
      --thus these are actually AHB Slave Interfaces
      mst_priority => (others => (others => '0')),

      mst_HSEL      => mst_mram_HSEL,
      mst_HADDR     => mst_mram_HADDR,
      mst_HWDATA    => mst_mram_HWDATA,
      mst_HRDATA    => mst_msi_mram_HRDATA,
      mst_HWRITE    => mst_mram_HWRITE,
      mst_HSIZE     => mst_mram_HSIZE,
      mst_HBURST    => mst_mram_HBURST,
      mst_HPROT     => mst_mram_HPROT,
      mst_HTRANS    => mst_mram_HTRANS,
      mst_HMASTLOCK => mst_mram_HMASTLOCK,
      mst_HREADYOUT => mst_msi_mram_HREADYOUT,
      mst_HREADY    => mst_mram_HREADY,
      mst_HRESP     => mst_msi_mram_HRESP,

      --Slave Ports; AHB Slaves connect to these
      --thus these are actually AHB Master Interfaces
      slv_addr_mask => (others => (others => '0')),
      slv_addr_base => (others => (others => '0')),

      slv_HSEL      => out_dat_HSEL,
      slv_HADDR     => out_dat_HADDR,
      slv_HWDATA    => out_dat_HWDATA,
      slv_HRDATA    => out_dat_HRDATA,
      slv_HWRITE    => out_dat_HWRITE,
      slv_HSIZE     => out_dat_HSIZE,
      slv_HBURST    => out_dat_HBURST,
      slv_HPROT     => out_dat_HPROT,
      slv_HTRANS    => out_dat_HTRANS,
      slv_HMASTLOCK => out_dat_HMASTLOCK,
      slv_HREADYOUT => out_dat_HREADYOUT,
      slv_HREADY    => out_dat_HREADY,
      slv_HRESP     => out_dat_HRESP
    );

  --Instantiate RISC-V NoC Adapter
  noc_adapter : riscv_noc_adapter
    generic map (
      PLEN         => PLEN,
      XLEN         => XLEN,
      BUFFER_DEPTH => BUFFER_DEPTH,
      CHANNELS     => CHANNELS
    )
    port map (
      --Common signals
      HCLK    => HCLK,
      HRESETn => HRESETn,

      --NoC Interface
      noc_in_flit   => noc_in_flit,
      noc_in_last   => noc_in_last,
      noc_in_valid  => noc_in_valid,
      noc_in_ready  => noc_in_ready,
      noc_out_flit  => noc_out_flit,
      noc_out_last  => noc_out_last,
      noc_out_valid => noc_out_valid,
      noc_out_ready => noc_out_ready,

      --AHB master interface
      mst_HSEL      => mst_noc_HSEL,
      mst_HADDR     => mst_noc_HADDR,
      mst_HWDATA    => mst_noc_HWDATA,
      mst_HRDATA    => mst_noc_HRDATA,
      mst_HWRITE    => mst_noc_HWRITE,
      mst_HSIZE     => mst_noc_HSIZE,
      mst_HBURST    => mst_noc_HBURST,
      mst_HPROT     => mst_noc_HPROT,
      mst_HTRANS    => mst_noc_HTRANS,
      mst_HMASTLOCK => mst_noc_HMASTLOCK,
      mst_HREADYOUT => mst_noc_HREADYOUT,
      mst_HRESP     => mst_noc_HRESP,

      --AHB slave interface
      slv_HSEL      => slv_noc_HSEL,
      slv_HADDR     => slv_noc_HADDR,
      slv_HWDATA    => slv_noc_HWDATA,
      slv_HRDATA    => slv_noc_HRDATA,
      slv_HWRITE    => slv_noc_HWRITE,
      slv_HSIZE     => slv_noc_HSIZE,
      slv_HBURST    => slv_noc_HBURST,
      slv_HPROT     => slv_noc_HPROT,
      slv_HTRANS    => slv_noc_HTRANS,
      slv_HMASTLOCK => slv_noc_HMASTLOCK,
      slv_HREADY    => slv_noc_HREADY,
      slv_HRESP     => slv_noc_HRESP
    );

  --Instantiate RISC-V GPIO
  gpio_bridge : riscv_bridge
    generic map (
      HADDR_SIZE => PLEN,
      HDATA_SIZE => XLEN,
      PADDR_SIZE => PADDR_SIZE,
      PDATA_SIZE => PDATA_SIZE,
      SYNC_DEPTH => SYNC_DEPTH
    )
    port map (
      --AHB Slave Interface
      HRESETn => HRESETn,
      HCLK    => HCLK,

      HSEL      => mst_gpio_HSEL,
      HADDR     => mst_gpio_HADDR,
      HWDATA    => mst_gpio_HWDATA,
      HRDATA    => mst_gpio_HRDATA,
      HWRITE    => mst_gpio_HWRITE,
      HSIZE     => mst_gpio_HSIZE,
      HBURST    => mst_gpio_HBURST,
      HPROT     => mst_gpio_HPROT,
      HTRANS    => mst_gpio_HTRANS,
      HMASTLOCK => mst_gpio_HMASTLOCK,
      HREADYOUT => mst_gpio_HREADYOUT,
      HREADY    => mst_gpio_HREADY,
      HRESP     => mst_gpio_HRESP,

      --APB Master Interface
      PRESETn => HRESETn,
      PCLK    => HCLK,

      PSEL    => gpio_PSEL,
      PENABLE => gpio_PENABLE,
      PPROT   => open,
      PWRITE  => gpio_PWRITE,
      PSTRB   => gpio_PSTRB,
      PADDR   => gpio_PADDR,
      PWDATA  => gpio_PWDATA,
      PRDATA  => gpio_PRDATA,
      PREADY  => gpio_PREADY,
      PSLVERR => gpio_PSLVERR
    );

  gpio : riscv_gpio
    port map (
      PRESETn => HRESETn,
      PCLK    => HCLK,

      PSEL    => gpio_PSEL,
      PENABLE => gpio_PENABLE,
      PWRITE  => gpio_PWRITE,
      PSTRB   => gpio_PSTRB,
      PADDR   => gpio_PADDR,
      PWDATA  => gpio_PWDATA,
      PRDATA  => gpio_PRDATA,
      PREADY  => gpio_PREADY,
      PSLVERR => gpio_PSLVERR,

      gpio_i  => gpio_i,
      gpio_o  => gpio_o,
      gpio_oe => gpio_oe
    );

  --Instantiate RISC-V RAM
  simd_mpram : riscv_simd_mpram
    generic map (
      MEM_SIZE          => 0,
      MEM_DEPTH         => 256,
      PLEN              => PLEN,
      XLEN              => XLEN,
      TECHNOLOGY        => TECHNOLOGY,
      REGISTERED_OUTPUT => "NO"
    )
    port map (
      --AHB Slave Interface
      HRESETn => HRESETn,
      HCLK    => HCLK,

      HSEL      => mst_mram_HSEL,
      HADDR     => mst_mram_HADDR,
      HWDATA    => mst_mram_HWDATA,
      HRDATA    => mst_mram_HRDATA,
      HWRITE    => mst_mram_HWRITE,
      HSIZE     => mst_mram_HSIZE,
      HBURST    => mst_mram_HBURST,
      HPROT     => mst_mram_HPROT,
      HTRANS    => mst_mram_HTRANS,
      HMASTLOCK => mst_mram_HMASTLOCK,
      HREADYOUT => mst_mram_HREADYOUT,
      HREADY    => mst_mram_HREADY,
      HRESP     => mst_mram_HRESP
    );

  spram : riscv_spram
    generic map (
      MEM_SIZE          => 0,
      MEM_DEPTH         => 256,
      PLEN              => PLEN,
      XLEN              => XLEN,
      TECHNOLOGY        => TECHNOLOGY,
      REGISTERED_OUTPUT => "NO"
    )
    port map (
      --AHB Slave Interface
      HRESETn => HRESETn,
      HCLK    => HCLK,

      HSEL      => mst_sram_HSEL,
      HADDR     => mst_sram_HADDR,
      HWDATA    => mst_sram_HWDATA,
      HRDATA    => mst_sram_HRDATA,
      HWRITE    => mst_sram_HWRITE,
      HSIZE     => mst_sram_HSIZE,
      HBURST    => mst_sram_HBURST,
      HPROT     => mst_sram_HPROT,
      HTRANS    => mst_sram_HTRANS,
      HMASTLOCK => mst_sram_HMASTLOCK,
      HREADYOUT => mst_sram_HREADYOUT,
      HREADY    => mst_sram_HREADY,
      HRESP     => mst_sram_HRESP
    );

  --Instantiate RISC-V Debug
  generating_4 : for t in 0 to CORES_PER_SIMD - 1 generate
    osd_ctm_template : riscv_osd_ctm_template
      port map (
        clk => HCLK,
        rst => HRESETn,

        id => (others => '0'),

        debug_in_data   => dii_out_data(2*t),
        debug_in_last   => dii_out_last(2*t),
        debug_in_valid  => dii_out_valid(2*t),
        debug_in_ready  => dii_out_ready(2*t),
        debug_out_data  => dii_in_data(2*t),
        debug_out_last  => dii_in_last(2*t),
        debug_out_valid => dii_in_valid(2*t),
        debug_out_ready => dii_in_ready(2*t),

        trace_port_insn     => trace_port_insn(t),
        trace_port_pc       => trace_port_pc(t),
        trace_port_jb       => trace_port_jb(t),
        trace_port_jal      => trace_port_jal(t),
        trace_port_jr       => trace_port_jr(t),
        trace_port_jbtarget => trace_port_jbtarget(t),
        trace_port_valid    => trace_port_valid(t),
        trace_port_data     => trace_port_data(t),
        trace_port_addr     => trace_port_addr(t),
        trace_port_we       => trace_port_we(t)
      );

    osd_stm_template : riscv_osd_stm_template
      port map (
        clk => HCLK,
        rst => HRESETn,

        id => (others => '0'),

        debug_in_data   => dii_out_data(2*t+1),
        debug_in_last   => dii_out_last(2*t+1),
        debug_in_valid  => dii_out_valid(2*t+1),
        debug_in_ready  => dii_out_ready(2*t+1),
        debug_out_data  => dii_in_data(2*t+1),
        debug_out_last  => dii_in_last(2*t+1),
        debug_out_valid => dii_in_valid(2*t+1),
        debug_out_ready => dii_in_ready(2*t+1),

        trace_port_insn     => trace_port_insn(t),
        trace_port_pc       => trace_port_pc(t),
        trace_port_jb       => trace_port_jb(t),
        trace_port_jal      => trace_port_jal(t),
        trace_port_jr       => trace_port_jr(t),
        trace_port_jbtarget => trace_port_jbtarget(t),
        trace_port_valid    => trace_port_valid(t),
        trace_port_data     => trace_port_data(t),
        trace_port_addr     => trace_port_addr(t),
        trace_port_we       => trace_port_we(t)
      );
  end generate;
end RTL;
