-- Converted from verilog/riscv_noc_adapter/riscv_noc_adapter.sv
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
--              Network on Chip Interface                                     //
--              AMBA3 AHB-Lite Bus Interface                                  //
--              Mesh Topology                                                 //
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
use work.riscv_noc_pkg.all;

entity riscv_noc_adapter is
  generic (
    PLEN         : integer := 64;
    XLEN         : integer := 64;
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

    noc_in_flit  : in  M_CHANNELS_PLEN;
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
end riscv_noc_adapter;

architecture RTL of riscv_noc_adapter is
  component riscv_dma
    generic (
      XLEN : integer := 64;
      PLEN : integer := 64;

      NOC_PACKET_SIZE : integer := 16;

      TABLE_ENTRIES : integer := 4;
      DMA_REQMASK_WIDTH : integer := 5;
      DMA_REQUEST_WIDTH : integer := 199;
      DMA_REQFIELD_SIZE_WIDTH : integer := 64;
      TABLE_ENTRIES_PTRWIDTH : integer := integer(log2(real(4)))
    );
    port (
      clk : in std_ulogic;
      rst : in std_ulogic;

      noc_in_req_flit  : in  std_ulogic_vector(PLEN-1 downto 0);
      noc_in_req_last  : in  std_ulogic;
      noc_in_req_valid : in  std_ulogic;
      noc_in_req_ready : out std_ulogic;

      noc_in_res_flit  : in  std_ulogic_vector(PLEN-1 downto 0);
      noc_in_res_last  : in  std_ulogic;
      noc_in_res_valid : in  std_ulogic;
      noc_in_res_ready : out std_ulogic;

      noc_out_req_flit  : out std_ulogic_vector(PLEN-1 downto 0);
      noc_out_req_last  : out std_ulogic;
      noc_out_req_valid : out std_ulogic;
      noc_out_req_ready : in  std_ulogic;

      noc_out_res_flit  : out std_ulogic_vector(PLEN-1 downto 0);
      noc_out_res_last  : out std_ulogic;
      noc_out_res_valid : out std_ulogic;
      noc_out_res_ready : in  std_ulogic;

      irq : out std_ulogic_vector(TABLE_ENTRIES-1 downto 0);

      --AHB master interface
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

      --AHB slave interface
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

  component riscv_mpb
    generic (
      PLEN     : integer := 32;
      XLEN     : integer := 32;
      CHANNELS : integer := 2;
      SIZE     : integer := 16
    );
    port (
      --Common signals
      HRESETn : in std_ulogic;
      HCLK    : in std_ulogic;

      --NoC Interface
      noc_in_flit  : in  M_CHANNELS_PLEN;
      noc_in_last  : in  std_ulogic_vector(CHANNELS-1 downto 0);
      noc_in_valid : in  std_ulogic_vector(CHANNELS-1 downto 0);
      noc_in_ready : out std_ulogic_vector(CHANNELS-1 downto 0);

      noc_out_flit  : out M_CHANNELS_PLEN;
      noc_out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
      noc_out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
      noc_out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0);

      --AHB input interface
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
      mst_HRESP     : out std_ulogic
    );
  end component;

  component riscv_noc_channels_mux
    generic (
      PLEN     : integer := 64;
      CHANNELS : integer := 2
    );
    port (
      clk : in std_ulogic;
      rst : in std_ulogic;

      in_flit  : in  M_CHANNELS_PLEN;
      in_last  : in  std_ulogic_vector(CHANNELS-1 downto 0);
      in_valid : in  std_ulogic_vector(CHANNELS-1 downto 0);
      in_ready : out std_ulogic_vector(CHANNELS-1 downto 0);

      out_flit  : out std_ulogic_vector(PLEN-1 downto 0);
      out_last  : out std_ulogic;
      out_valid : out std_ulogic;
      out_ready : in  std_ulogic
    );
  end component;

  component riscv_noc_buffer
    generic (
      BUFFER_DEPTH : integer := 4
    );
    port (
      -- the width of the index
      clk : in std_ulogic;
      rst : in std_ulogic;

      --FIFO input side
      in_flit  : in  std_ulogic_vector(PLEN-1 downto 0);
      in_last  : in  std_ulogic;
      in_valid : in  std_ulogic;
      in_ready : out std_ulogic;

      --FIFO output side
      out_flit  : out std_ulogic_vector(PLEN-1 downto 0);
      out_last  : out std_ulogic;
      out_valid : out std_ulogic;
      out_ready : in  std_ulogic;

      packet_size : out std_ulogic_vector(integer(log2(real(BUFFER_DEPTH))) downto 0)
    );
  end component;

  component riscv_noc_demux
    generic (
      MAPPING : std_ulogic_vector(PLEN-1 downto 0) := (others => 'X')
    );
    port (
      clk : in std_ulogic;
      rst : in std_ulogic;

      in_flit  : in  std_ulogic_vector(PLEN-1 downto 0);
      in_last  : in  std_ulogic;
      in_valid : in  std_ulogic;
      in_ready : out std_ulogic;

      out_flit  : out M_CHANNELS_PLEN;
      out_last  : out std_ulogic_vector(CHANNELS-1 downto 0);
      out_valid : out std_ulogic_vector(CHANNELS-1 downto 0);
      out_ready : in  std_ulogic_vector(CHANNELS-1 downto 0)
    );
  end component;

  --//////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  --Those are the actual channels from the modules
  constant MODCHANNELS : integer := 4;

  constant C_MPB_REQ : integer := 0;
  constant C_MPB_RES : integer := 1;
  constant C_DMA_REQ : integer := 2;
  constant C_DMA_RES : integer := 3;

  constant ELEMENTS : integer := 2;

  constant ELEMENTS_BITS : integer := integer(log2(real(ELEMENTS)));

  --//////////////////////////////////////////////////////////////
  --
  -- Types
  --
  type M_ELEMENTS_PLEN is array (ELEMENTS-1 downto 0) of std_ulogic_vector(PLEN-1 downto 0);
  type M_ELEMENTS_XLEN is array (ELEMENTS-1 downto 0) of std_ulogic_vector(XLEN-1 downto 0);
  type M_ELEMENTS_3 is array (ELEMENTS-1 downto 0) of std_ulogic_vector(3 downto 0);
  type M_ELEMENTS_2 is array (ELEMENTS-1 downto 0) of std_ulogic_vector(2 downto 0);
  type M_ELEMENTS_1 is array(ELEMENTS-1 downto 0) of std_ulogic_vector(1 downto 0);

  type M_MODCHANNELS_PLEN is array (MODCHANNELS-1 downto 0) of std_ulogic_vector(PLEN-1 downto 0);

  type M_2_ELEMENTS is array (2 downto 0) of std_ulogic_vector(ELEMENTS-1 downto 0);

  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --
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

  function onehot2int (
    onehot : std_ulogic_vector(ELEMENTS-1 downto 0)
  ) return integer is
    variable onehot2int_return : integer := -1;

    variable onehot_return : std_ulogic_vector(ELEMENTS-1 downto 0) := onehot;
  begin
    while (reduce_or(onehot) = '1') loop
      onehot2int_return := onehot2int_return + 1;
      onehot_return     := std_ulogic_vector(unsigned(onehot_return) srl 1);
    end loop;
    return onehot2int_return;
  end onehot2int;  --onehot2int

  function highest_requested_priority (
    hsel : std_ulogic_vector(ELEMENTS-1 downto 0)
  ) return std_ulogic_vector is
    variable priorities                        : M_ELEMENTS_2;
    variable highest_requested_priority_return : std_ulogic_vector (2 downto 0);
  begin
    highest_requested_priority_return := (others => '0');
    for n in 0 to ELEMENTS - 1 loop
      priorities(n) := std_ulogic_vector(to_unsigned(n, 3));
      if (hsel(n) = '1' and unsigned(priorities(n)) > unsigned(highest_requested_priority_return)) then
        highest_requested_priority_return := priorities(n);
      end if;
    end loop;
    return highest_requested_priority_return;
  end highest_requested_priority;  --highest_requested_priority

  function requesters (
    hsel            : std_ulogic_vector(ELEMENTS-1 downto 0);
    priority_select : std_ulogic_vector(2 downto 0)
  ) return std_ulogic_vector is
    variable priorities        : M_ELEMENTS_2;
    variable requesters_return : std_ulogic_vector (ELEMENTS-1 downto 0);
  begin
    for n in 0 to ELEMENTS - 1 loop
      priorities(n)        := std_ulogic_vector(to_unsigned(n, 3));
      requesters_return(n) := to_stdlogic(priorities(n) = priority_select) and hsel(n);
    end loop;
    return requesters_return;
  end requesters;  --requesters

  function nxt_master (
    pending_masters : std_ulogic_vector(ELEMENTS-1 downto 0);  --pending masters for the requesed priority level
    last_master     : std_ulogic_vector(ELEMENTS-1 downto 0);  --last granted master for the priority level
    current_master  : std_ulogic_vector(ELEMENTS-1 downto 0)  --current granted master (indpendent of priority level)
  ) return std_ulogic_vector is
    variable offset            : integer;
    variable sr                : std_ulogic_vector(ELEMENTS*2-1 downto 0);
    variable nxt_master_return : std_ulogic_vector (ELEMENTS-1 downto 0);
  begin
    --default value, don't switch if not needed
    nxt_master_return := current_master;

    --implement round-robin
    offset := onehot2int(last_master)+1;

    sr := (pending_masters & pending_masters);
    for n in 0 to ELEMENTS - 1 loop
      if (sr(n+offset) = '1') then
        return std_ulogic_vector(to_unsigned(2**((n+offset) mod ELEMENTS), ELEMENTS));
      end if;
    end loop;
    return nxt_master_return;
  end nxt_master;

  --//////////////////////////////////////////////////////////////
  --
  --Variables
  --
  signal mod_out_flit  : M_MODCHANNELS_PLEN;
  signal mod_out_last  : std_ulogic_vector(MODCHANNELS-1 downto 0);
  signal mod_out_valid : std_ulogic_vector(MODCHANNELS-1 downto 0);
  signal mod_out_ready : std_ulogic_vector(MODCHANNELS-1 downto 0);

  signal mod_in_flit  : M_MODCHANNELS_PLEN;
  signal mod_in_last  : std_ulogic_vector(MODCHANNELS-1 downto 0);
  signal mod_in_valid : std_ulogic_vector(MODCHANNELS-1 downto 0);
  signal mod_in_ready : std_ulogic_vector(MODCHANNELS-1 downto 0);

  signal muxed_flit  : M_CHANNELS_PLEN;
  signal muxed_last  : std_ulogic_vector(CHANNELS-1 downto 0);
  signal muxed_valid : std_ulogic_vector(CHANNELS-1 downto 0);
  signal muxed_ready : std_ulogic_vector(CHANNELS-1 downto 0);

  signal inbuffer_flit  : M_CHANNELS_PLEN;
  signal inbuffer_last  : std_ulogic_vector(CHANNELS-1 downto 0);
  signal inbuffer_valid : std_ulogic_vector(CHANNELS-1 downto 0);
  signal inbuffer_ready : std_ulogic_vector(CHANNELS-1 downto 0);

  --AHB interface
  signal bus_HSEL      : std_ulogic_vector(ELEMENTS-1 downto 0);
  signal bus_HADDR     : M_ELEMENTS_PLEN;
  signal bus_HWDATA    : M_ELEMENTS_XLEN;
  signal bus_HRDATA    : M_ELEMENTS_XLEN;
  signal bus_HWRITE    : std_ulogic_vector(ELEMENTS-1 downto 0);
  signal bus_HSIZE     : M_ELEMENTS_2;
  signal bus_HBURST    : M_ELEMENTS_2;
  signal bus_HPROT     : M_ELEMENTS_3;
  signal bus_HTRANS    : M_ELEMENTS_1;
  signal bus_HMASTLOCK : std_ulogic_vector(ELEMENTS-1 downto 0);
  signal bus_HREADYOUT : std_ulogic_vector(ELEMENTS-1 downto 0);
  signal bus_HRESP     : std_ulogic_vector(ELEMENTS-1 downto 0);

  signal requested_priority_lvl : std_ulogic_vector(2 downto 0);  --requested priority level
  signal priority_masters       : std_ulogic_vector(ELEMENTS-1 downto 0);  --all masters at this priority level

  signal pending_master      : std_ulogic_vector(ELEMENTS-1 downto 0);  --next master waiting to be served
  signal last_granted_master : std_ulogic_vector(ELEMENTS-1 downto 0);  --for requested priority level

  signal last_granted_masters : M_2_ELEMENTS;  --per priority level, for round-robin

  signal granted_master_idx : std_ulogic_vector(ELEMENTS_BITS-1 downto 0);  --granted master as index

  signal granted_master : std_ulogic_vector(ELEMENTS-1 downto 0);

  signal mpb_in_flit  : M_CHANNELS_PLEN;
  signal mpb_in_last  : std_ulogic_vector(CHANNELS-1 downto 0);
  signal mpb_in_valid : std_ulogic_vector(CHANNELS-1 downto 0);
  signal mpb_in_ready : std_ulogic_vector(CHANNELS-1 downto 0);

  signal mpb_out_flit  : M_CHANNELS_PLEN;
  signal mpb_out_last  : std_ulogic_vector(CHANNELS-1 downto 0);
  signal mpb_out_valid : std_ulogic_vector(CHANNELS-1 downto 0);
  signal mpb_out_ready : std_ulogic_vector(CHANNELS-1 downto 0);

  signal mux_in_flit  : M_CHANNELS_PLEN;
  signal mux_in_last  : std_ulogic_vector(CHANNELS-1 downto 0);
  signal mux_in_valid : std_ulogic_vector(CHANNELS-1 downto 0);
  signal mux_in_ready : std_ulogic_vector(CHANNELS-1 downto 0);

  signal demux_out_flit  : M_CHANNELS_PLEN;
  signal demux_out_last  : std_ulogic_vector(CHANNELS-1 downto 0);
  signal demux_out_valid : std_ulogic_vector(CHANNELS-1 downto 0);
  signal demux_out_ready : std_ulogic_vector(CHANNELS-1 downto 0);

begin
  --//////////////////////////////////////////////////////////////
  --
  --Module Body
  --
  --get highest priority from selected masters
  requested_priority_lvl <= highest_requested_priority(bus_HSEL);

  --get pending masters for the highest priority requested
  priority_masters <= requesters(bus_HSEL, requested_priority_lvl);

  --get last granted master for the priority requested
  last_granted_master <= last_granted_masters(to_integer(unsigned(requested_priority_lvl)));

  --get next master to serve
  pending_master <= nxt_master(priority_masters, last_granted_master, granted_master);

  --select new master
  processing_0 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      granted_master <= std_ulogic_vector(to_unsigned(1, ELEMENTS));
    elsif (rising_edge(HCLK)) then
      if (mst_HSEL = '0') then
        granted_master <= pending_master;
      end if;
    end if;
  end process;

  --store current master (for this priority level)
  processing_1 : process (HCLK, HRESETn, requested_priority_lvl)
  begin
    if (HRESETn = '0') then
      last_granted_masters(to_integer(unsigned(requested_priority_lvl))) <= std_ulogic_vector(to_unsigned(1, ELEMENTS));
    elsif (rising_edge(HCLK)) then
      if (mst_HSEL = '0') then
        last_granted_masters(to_integer(unsigned(requested_priority_lvl))) <= pending_master;
      end if;
    end if;
  end process;

  --get signals from current requester
  processing_2 : process (HCLK, HRESETn)
  begin
    if (HRESETn = '0') then
      granted_master_idx <= (others => '0');
    elsif (rising_edge(HCLK)) then
      if (mst_HSEL = '0') then
        granted_master_idx <= std_ulogic_vector(to_unsigned(onehot2int(pending_master), ELEMENTS_BITS));
      end if;
    end if;
  end process;

  generating_0 : for e in 0 to ELEMENTS - 1 generate
    bus_HSEL(e)      <= mst_HSEL;
    bus_HADDR(e)     <= mst_HADDR;
    bus_HWDATA(e)    <= mst_HWDATA;
    bus_HWRITE(e)    <= mst_HWRITE;
    bus_HSIZE(e)     <= mst_HSIZE;
    bus_HBURST(e)    <= mst_HBURST;
    bus_HPROT(e)     <= mst_HPROT;
    bus_HTRANS(e)    <= mst_HTRANS;
    bus_HMASTLOCK(e) <= mst_HMASTLOCK;
  end generate;

  mst_HRDATA    <= bus_HRDATA(to_integer(unsigned(granted_master_idx)));
  mst_HREADYOUT <= bus_HREADYOUT(to_integer(unsigned(granted_master_idx)));
  mst_HRESP     <= bus_HRESP(to_integer(unsigned(granted_master_idx)));

  --Instantiate RISC-V DMA
  dma : riscv_dma
    generic map (
      XLEN => XLEN,
      PLEN => PLEN,

      NOC_PACKET_SIZE => 16,

      TABLE_ENTRIES => 4,
      DMA_REQMASK_WIDTH => 5,
      DMA_REQUEST_WIDTH => 199,
      DMA_REQFIELD_SIZE_WIDTH => 64,
      TABLE_ENTRIES_PTRWIDTH => integer(log2(real(4)))
    )
    port map (
      --Common signals
      clk => HCLK,
      rst => HRESETn,

      --NoC Interface
      noc_in_req_flit  => mod_in_flit(C_DMA_REQ),
      noc_in_req_last  => mod_in_last(C_DMA_REQ),
      noc_in_req_valid => mod_in_valid(C_DMA_REQ),
      noc_in_req_ready => mod_in_ready(C_DMA_REQ),

      noc_in_res_flit  => mod_in_flit(C_DMA_RES),
      noc_in_res_last  => mod_in_last(C_DMA_RES),
      noc_in_res_valid => mod_in_valid(C_DMA_RES),
      noc_in_res_ready => mod_in_ready(C_DMA_RES),

      noc_out_req_flit  => mod_out_flit(C_DMA_REQ),
      noc_out_req_last  => mod_out_last(C_DMA_REQ),
      noc_out_req_valid => mod_out_valid(C_DMA_REQ),
      noc_out_req_ready => mod_out_ready(C_DMA_REQ),

      noc_out_res_flit  => mod_out_flit(C_DMA_RES),
      noc_out_res_last  => mod_out_last(C_DMA_RES),
      noc_out_res_valid => mod_out_valid(C_DMA_RES),
      noc_out_res_ready => mod_out_ready(C_DMA_RES),

      --Interrupts
      irq => open,

      --AHB input interface
      mst_HSEL      => bus_HSEL(0),
      mst_HADDR     => bus_HADDR(0),
      mst_HWDATA    => bus_HWDATA(0),
      mst_HRDATA    => bus_HRDATA(0),
      mst_HWRITE    => bus_HWRITE(0),
      mst_HSIZE     => bus_HSIZE(0),
      mst_HBURST    => bus_HBURST(0),
      mst_HPROT     => bus_HPROT(0),
      mst_HTRANS    => bus_HTRANS(0),
      mst_HMASTLOCK => bus_HMASTLOCK(0),
      mst_HREADYOUT => bus_HREADYOUT(0),
      mst_HRESP     => bus_HRESP(0),

      --AHB output interface
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
      slv_HREADY    => slv_HREADY,
      slv_HRESP     => slv_HRESP
    );

  --Instantiate RISC-V Message Passing Buffer End-Point
  mpb : riscv_mpb
    generic map (
      PLEN     => PLEN,
      XLEN     => XLEN,
      CHANNELS => CHANNELS,
      SIZE     => 2
    )
    port map (
      --Common signals
      HRESETn => HRESETn,
      HCLK    => HCLK,

      --NoC Interface
      noc_in_flit  => mpb_in_flit,
      noc_in_last  => mpb_in_last,
      noc_in_valid => mpb_in_valid,
      noc_in_ready => mpb_in_ready,

      noc_out_flit  => mpb_out_flit,
      noc_out_last  => mpb_out_last,
      noc_out_valid => mpb_out_valid,
      noc_out_ready => mpb_out_ready,

      --AHB input interface
      mst_HSEL      => bus_HSEL(1),
      mst_HADDR     => bus_HADDR(1),
      mst_HWDATA    => bus_HWDATA(1),
      mst_HRDATA    => bus_HRDATA(1),
      mst_HWRITE    => bus_HWRITE(1),
      mst_HSIZE     => bus_HSIZE(1),
      mst_HBURST    => bus_HBURST(1),
      mst_HPROT     => bus_HPROT(1),
      mst_HTRANS    => bus_HTRANS(1),
      mst_HMASTLOCK => bus_HMASTLOCK(1),
      mst_HREADYOUT => bus_HREADYOUT(1),
      mst_HRESP     => bus_HRESP(1)
    );

  mpb_in_flit(0) <= mod_in_flit(C_MPB_RES);
  mpb_in_flit(1) <= mod_in_flit(C_MPB_REQ);

  mpb_in_last(0) <= mod_in_last(C_MPB_RES);
  mpb_in_last(1) <= mod_in_last(C_MPB_REQ);

  mpb_in_valid(0) <= mod_in_valid(C_MPB_RES);
  mpb_in_valid(1) <= mod_in_valid(C_MPB_REQ);

  mod_in_ready(C_MPB_RES) <= mpb_in_ready(0);
  mod_in_ready(C_MPB_REQ) <= mpb_in_ready(1);

  mod_out_flit(C_MPB_RES) <= mpb_out_flit(0);
  mod_out_flit(C_MPB_REQ) <= mpb_out_flit(1);

  mod_out_last(C_MPB_RES) <= mpb_out_last(0);
  mod_out_last(C_MPB_REQ) <= mpb_out_last(1);

  mod_out_valid(C_MPB_RES) <= mpb_out_valid(0);
  mod_out_valid(C_MPB_REQ) <= mpb_out_valid(1);

  mpb_out_ready(0) <= mod_out_ready(C_MPB_RES);
  mpb_out_ready(1) <= mod_out_ready(C_MPB_REQ);

  generating_1 : for c in 0 to CHANNELS - 1 generate
    --noc_channels_mux : riscv_noc_channels_mux
      --generic map (
        --PLEN     => PLEN,
        --CHANNELS => CHANNELS
      --)
      --port map (
        --clk => HCLK,
        --rst => HRESETn,

        --in_flit  => mux_in_flit,
        --in_last  => mux_in_last,
        --in_valid => mux_in_valid,
        --in_ready => open,

        --out_flit  => muxed_flit(c),
        --out_last  => muxed_last(c),
        --out_valid => muxed_valid(c),
        --out_ready => muxed_ready(c)
      --);

    mod_out_flit(C_MPB_REQ+c) <= mux_in_flit(0);
    mod_out_flit(C_DMA_REQ+c) <= mux_in_flit(1);

    mod_out_last(C_MPB_REQ+c) <= mux_in_last(0);
    mod_out_last(C_DMA_REQ+c) <= mux_in_last(1);

    mod_out_valid(C_MPB_REQ+c) <= mux_in_valid(0);
    mod_out_valid(C_DMA_REQ+c) <= mux_in_valid(1);


    mux_in_ready(0) <= mod_out_ready(C_MPB_REQ+c);
    mux_in_ready(0) <= mod_out_ready(C_DMA_REQ+c);

    --out_buffer : riscv_noc_buffer
      --generic map (
        --BUFFER_DEPTH => BUFFER_DEPTH
      --)
      --port map (
        --clk => HCLK,
        --rst => HRESETn,

        --in_flit  => muxed_flit(c),
        --in_last  => muxed_last(c),
        --in_valid => muxed_valid(c),
        --in_ready => muxed_ready(c),

        --out_flit  => noc_out_flit(c)(XLEN-1 downto 0),
        --out_last  => noc_out_last(c),
        --out_valid => noc_out_valid(c),
        --out_ready => noc_out_ready(c),

        --packet_size => open
      --);

    --in_buffer : riscv_noc_buffer
      --generic map (
        --BUFFER_DEPTH => BUFFER_DEPTH
      --)
      --port map (
        --clk => HCLK,
        --rst => HRESETn,

        --in_flit  => noc_in_flit(c),
        --in_last  => noc_in_last(c),
        --in_valid => noc_in_valid(c),
        --in_ready => noc_in_ready(c),

        --out_flit  => inbuffer_flit(c),
        --out_last  => inbuffer_last(c),
        --out_valid => inbuffer_valid(c),
        --out_ready => inbuffer_ready(c),

        --packet_size => open
      --);

    --noc_demux : riscv_noc_demux
      --generic map (
        --MAPPING => (others => 'X')
      --)
      --port map (
        --clk => HCLK,
        --rst => HRESETn,

        --in_flit  => inbuffer_flit(c),
        --in_last  => inbuffer_last(c),
        --in_valid => inbuffer_valid(c),
        --in_ready => inbuffer_ready(c),

        --out_flit  => open,
        --out_last  => open,
        --out_valid => open,
        --out_ready => demux_out_ready
      --);

    demux_out_flit(0) <= mod_in_flit(C_DMA_REQ+c);
    demux_out_flit(1) <= mod_in_flit(C_MPB_REQ+c);

    demux_out_last(0) <= mod_in_last(C_DMA_REQ+c);
    demux_out_last(1) <= mod_in_last(C_MPB_REQ+c);

    demux_out_valid(0) <= mod_in_valid(C_DMA_REQ+c);
    demux_out_valid(1) <= mod_in_valid(C_MPB_REQ+c);

    mod_in_ready(C_DMA_REQ+c) <= demux_out_ready(0);
    mod_in_ready(C_MPB_REQ+c) <= demux_out_ready(1);
  end generate;
end RTL;
