////////////////////////////////////////////////////////////////////////////////
//                                            __ _      _     _               //
//                                           / _(_)    | |   | |              //
//                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
//               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
//              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
//               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
//                  | |                                                       //
//                  |_|                                                       //
//                                                                            //
//                                                                            //
//              MPSoC-RISCV CPU                                               //
//              Multiple Instruction Single Data                              //
//              AMBA3 AHB-Lite Bus Interface                                  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/* Copyright (c) 2019-2020 by the author(s)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * =============================================================================
 * Author(s):
 *   Francisco Javier Reina Campo <frareicam@gmail.com>
 */

`include "riscv_mpsoc_pkg.sv"

module riscv_misd #(
  parameter            XLEN               = 32,
  parameter            PLEN               = XLEN,
  parameter [XLEN-1:0] PC_INIT            = 'h200,
  parameter            HAS_USER           = 0,
  parameter            HAS_SUPER          = 0,
  parameter            HAS_HYPER          = 0,
  parameter            HAS_BPU            = 1,
  parameter            HAS_FPU            = 0,
  parameter            HAS_MMU            = 0,
  parameter            HAS_RVM            = 0,
  parameter            HAS_RVA            = 0,
  parameter            HAS_RVC            = 0,
  parameter            IS_RV32E           = 0,

  parameter            MULT_LATENCY       = 0,

  parameter            BREAKPOINTS        = 8,  //Number of hardware breakpoints

  parameter            PMA_CNT            = 16,
  parameter            PMP_CNT            = 16, //Number of Physical Memory Protection entries

  parameter            BP_GLOBAL_BITS     = 2,
  parameter            BP_LOCAL_BITS      = 10,

  parameter            ICACHE_SIZE        = 0,  //in KBytes
  parameter            ICACHE_BLOCK_SIZE  = 32, //in Bytes
  parameter            ICACHE_WAYS        = 2,  //'n'-way set associative
  parameter            ICACHE_REPLACE_ALG = 0,
  parameter            ITCM_SIZE          = 0,

  parameter            DCACHE_SIZE        = 0,  //in KBytes
  parameter            DCACHE_BLOCK_SIZE  = 32, //in Bytes
  parameter            DCACHE_WAYS        = 2,  //'n'-way set associative
  parameter            DCACHE_REPLACE_ALG = 0,
  parameter            DTCM_SIZE          = 0,
  parameter            WRITEBUFFER_SIZE   = 8,

  parameter            TECHNOLOGY         = "GENERIC",

  parameter            MNMIVEC_DEFAULT    = PC_INIT - 'h004,
  parameter            MTVEC_DEFAULT      = PC_INIT - 'h040,
  parameter            HTVEC_DEFAULT      = PC_INIT - 'h080,
  parameter            STVEC_DEFAULT      = PC_INIT - 'h0C0,
  parameter            UTVEC_DEFAULT      = PC_INIT - 'h100,

  parameter            JEDEC_BANK            = 10,
  parameter            JEDEC_MANUFACTURER_ID = 'h6e,

  parameter            HARTID             = 0,

  parameter            PARCEL_SIZE        = 32,

  parameter            HADDR_SIZE         = XLEN,
  parameter            HDATA_SIZE         = PLEN,
  parameter            PADDR_SIZE         = PLEN,
  parameter            PDATA_SIZE         = XLEN,

  parameter            SYNC_DEPTH         = 3,

  parameter            BUFFER_DEPTH       = 4,

  parameter            CORES_PER_MISD     = 8,

  parameter            CHANNELS           = 2,

  parameter            ROUTER_BUFFER_SIZE = 2,
  parameter            REG_ADDR_WIDTH     = 2,
  parameter            VALWIDTH           = 2,
  parameter            MAX_PKT_LEN        = 2
)
  (
    //Common signals
    input                                          HRESETn,
    input                                          HCLK,

    //Debug
    input       [CHANNELS -1:0][HDATA_SIZE   -1:0] debug_ring_in_data,
    input       [CHANNELS -1:0]                    debug_ring_in_last,
    input       [CHANNELS -1:0]                    debug_ring_in_valid,
    output      [CHANNELS -1:0]                    debug_ring_in_ready,

    output      [CHANNELS -1:0][HDATA_SIZE   -1:0] debug_ring_out_data,
    output      [CHANNELS -1:0]                    debug_ring_out_last,
    output      [CHANNELS -1:0]                    debug_ring_out_valid,
    input       [CHANNELS -1:0]                    debug_ring_out_ready,

    //PMA configuration
    input logic [PMA_CNT  -1:0][             13:0] pma_cfg_i,
    input logic [PMA_CNT  -1:0][XLEN         -1:0] pma_adr_i,

    //AHB instruction
    output      [CORES_PER_MISD-1:0]               ins_HSEL,
    output      [CORES_PER_MISD-1:0][PLEN    -1:0] ins_HADDR,
    output      [CORES_PER_MISD-1:0][XLEN    -1:0] ins_HWDATA,
    input       [CORES_PER_MISD-1:0][XLEN    -1:0] ins_HRDATA,
    output      [CORES_PER_MISD-1:0]               ins_HWRITE,
    output      [CORES_PER_MISD-1:0][         2:0] ins_HSIZE,
    output      [CORES_PER_MISD-1:0][         2:0] ins_HBURST,
    output      [CORES_PER_MISD-1:0][         3:0] ins_HPROT,
    output      [CORES_PER_MISD-1:0][         1:0] ins_HTRANS,
    output      [CORES_PER_MISD-1:0]               ins_HMASTLOCK,
    input       [CORES_PER_MISD-1:0]               ins_HREADY,
    input       [CORES_PER_MISD-1:0]               ins_HRESP,

    //AHB data
    output                                         dat_HSEL,
    output      [PLEN                        -1:0] dat_HADDR,
    output      [XLEN                        -1:0] dat_HWDATA,
    input       [XLEN                        -1:0] dat_HRDATA,
    output                                         dat_HWRITE,
    output      [                             2:0] dat_HSIZE,
    output      [                             2:0] dat_HBURST,
    output      [                             3:0] dat_HPROT,
    output      [                             1:0] dat_HTRANS,
    output                                         dat_HMASTLOCK,
    input                                          dat_HREADY,
    input                                          dat_HRESP,

    //Interrupts Interface
    input       [CORES_PER_MISD-1:0]               ext_nmi,
    input       [CORES_PER_MISD-1:0]               ext_tint,
    input       [CORES_PER_MISD-1:0]               ext_sint,
    input       [CORES_PER_MISD-1:0][         3:0] ext_int,

    //Debug Interface
    input       [CORES_PER_MISD-1:0]               dbg_stall,
    input       [CORES_PER_MISD-1:0]               dbg_strb,
    input       [CORES_PER_MISD-1:0]               dbg_we,
    input       [CORES_PER_MISD-1:0][PLEN    -1:0] dbg_addr,
    input       [CORES_PER_MISD-1:0][XLEN    -1:0] dbg_dati,
    output      [CORES_PER_MISD-1:0][XLEN    -1:0] dbg_dato,
    output      [CORES_PER_MISD-1:0]               dbg_ack,
    output      [CORES_PER_MISD-1:0]               dbg_bp,

    //GPIO Interface
    input       [PDATA_SIZE                  -1:0] gpio_i,
    output reg  [PDATA_SIZE                  -1:0] gpio_o,
    output reg  [PDATA_SIZE                  -1:0] gpio_oe,

    //NoC Interface
    input       [CHANNELS -1:0][HADDR_SIZE   -1:0] noc_in_flit,
    input       [CHANNELS -1:0]                    noc_in_last,
    input       [CHANNELS -1:0]                    noc_in_valid,
    output      [CHANNELS -1:0]                    noc_in_ready,
    output      [CHANNELS -1:0][HADDR_SIZE   -1:0] noc_out_flit,
    output      [CHANNELS -1:0]                    noc_out_last,
    output      [CHANNELS -1:0]                    noc_out_valid,
    input       [CHANNELS -1:0]                    noc_out_ready
  );

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //

  localparam MISD_BITS = $clog2(CORES_PER_MISD);

  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //
  function integer onehot2int;
    input [CORES_PER_MISD-1:0] onehot;

    for (onehot2int = - 1; |onehot; onehot2int=onehot2int+1) onehot = onehot >> 1;
  endfunction //onehot2int

  function [2:0] highest_requested_priority (
    input [CORES_PER_MISD-1:0] hsel       
  );
    logic [CORES_PER_MISD-1:0][2:0] priorities;
    integer n;
    highest_requested_priority = 0;
    for (n=0; n<CORES_PER_MISD; n++) begin
      priorities[n] = n;
      if (hsel[n] && priorities[n] > highest_requested_priority) highest_requested_priority = priorities[n];
    end
  endfunction //highest_requested_priority

  function [CORES_PER_MISD-1:0] requesters;
    input [CORES_PER_MISD-1:0] hsel;
    input [2:0] priority_select;
    logic [CORES_PER_MISD-1:0][2:0] priorities;
    integer n;

    for (n=0; n<CORES_PER_MISD; n++) begin
      priorities[n] = n;
      requesters[n] = (priorities[n] == priority_select) & hsel[n];
    end
  endfunction //requesters

  function [CORES_PER_MISD-1:0] nxt_misd_master;
    input [CORES_PER_MISD-1:0] pending_misd_masters;  //pending masters for the requesed priority level
    input [CORES_PER_MISD-1:0] last_misd_master;      //last granted master for the priority level
    input [CORES_PER_MISD-1:0] current_misd_master;   //current granted master (indpendent of priority level)

    integer n, offset;
    logic [CORES_PER_MISD*2-1:0] sr;

    //default value, don't switch if not needed
    nxt_misd_master = current_misd_master;

    //implement round-robin
    offset = onehot2int(last_misd_master) + 1;

    sr = {pending_misd_masters, pending_misd_masters};
    for (n = 0; n < CORES_PER_MISD; n++)
      if ( sr[n + offset] ) return (1 << ((n+offset) % CORES_PER_MISD));
  endfunction

  ////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  genvar t;

  //AHB Bus Master Interfaces
  wire                        mst_noc_HSEL;
  wire  [PLEN           -1:0] mst_noc_HADDR;
  wire  [XLEN           -1:0] mst_noc_HWDATA;
  wire  [XLEN           -1:0] mst_noc_HRDATA;
  wire                        mst_noc_HWRITE;
  wire  [                2:0] mst_noc_HSIZE;
  wire  [                2:0] mst_noc_HBURST;
  wire  [                3:0] mst_noc_HPROT;
  wire  [                1:0] mst_noc_HTRANS;
  wire                        mst_noc_HMASTLOCK;
  wire                        mst_noc_HREADYOUT;
  wire                        mst_noc_HRESP;

  wire                        mst_gpio_HSEL;
  wire  [PLEN           -1:0] mst_gpio_HADDR;
  wire  [XLEN           -1:0] mst_gpio_HWDATA;
  wire  [XLEN           -1:0] mst_gpio_HRDATA;
  wire  [PDATA_SIZE/8   -1:0] mst_gpio_HWRITE;
  wire  [                2:0] mst_gpio_HSIZE;
  wire  [                2:0] mst_gpio_HBURST;
  wire  [                3:0] mst_gpio_HPROT;
  wire  [                1:0] mst_gpio_HTRANS;
  wire                        mst_gpio_HMASTLOCK;
  wire                        mst_gpio_HREADY;
  wire                        mst_gpio_HREADYOUT;
  wire                        mst_gpio_HRESP;

  wire                        gpio_PSEL;
  wire                        gpio_PENABLE;
  wire  [PDATA_SIZE/8   -1:0] gpio_PWRITE;
  wire  [PDATA_SIZE/8   -1:0] gpio_PSTRB;
  wire  [PADDR_SIZE     -1:0] gpio_PADDR;
  wire  [PDATA_SIZE     -1:0] gpio_PWDATA;
  wire  [PDATA_SIZE     -1:0] gpio_PRDATA;
  wire                        gpio_PREADY;
  wire                        gpio_PSLVERR;

  wire                        mst_sram_HSEL;
  wire  [PLEN           -1:0] mst_sram_HADDR;
  wire  [XLEN           -1:0] mst_sram_HWDATA;
  wire  [XLEN           -1:0] mst_sram_HRDATA;
  wire                        mst_sram_HWRITE;
  wire  [                2:0] mst_sram_HSIZE;
  wire  [                2:0] mst_sram_HBURST;
  wire  [                3:0] mst_sram_HPROT;
  wire  [                1:0] mst_sram_HTRANS;
  wire                        mst_sram_HMASTLOCK;
  wire                        mst_sram_HREADY;
  wire                        mst_sram_HREADYOUT;
  wire                        mst_sram_HRESP;

  wire  [CORES_PER_MISD-1:0]                      mst_mram_HSEL;
  wire  [CORES_PER_MISD-1:0][PLEN           -1:0] mst_mram_HADDR;
  wire  [CORES_PER_MISD-1:0][XLEN           -1:0] mst_mram_HWDATA;
  wire  [CORES_PER_MISD-1:0][XLEN           -1:0] mst_mram_HRDATA;
  wire  [CORES_PER_MISD-1:0]                      mst_mram_HWRITE;
  wire  [CORES_PER_MISD-1:0][                2:0] mst_mram_HSIZE;
  wire  [CORES_PER_MISD-1:0][                2:0] mst_mram_HBURST;
  wire  [CORES_PER_MISD-1:0][                3:0] mst_mram_HPROT;
  wire  [CORES_PER_MISD-1:0][                1:0] mst_mram_HTRANS;
  wire  [CORES_PER_MISD-1:0]                      mst_mram_HMASTLOCK;
  wire  [CORES_PER_MISD-1:0]                      mst_mram_HREADY;
  wire  [CORES_PER_MISD-1:0]                      mst_mram_HREADYOUT;
  wire  [CORES_PER_MISD-1:0]                      mst_mram_HRESP;

  wire  [2:0]                      mst_HSEL;
  wire  [2:0][PLEN           -1:0] mst_HADDR;
  wire  [2:0][XLEN           -1:0] mst_HWDATA;
  wire  [2:0][XLEN           -1:0] mst_HRDATA;
  wire  [2:0]                      mst_HWRITE;
  wire  [2:0][                2:0] mst_HSIZE;
  wire  [2:0][                2:0] mst_HBURST;
  wire  [2:0][                3:0] mst_HPROT;
  wire  [2:0][                1:0] mst_HTRANS;
  wire  [2:0]                      mst_HMASTLOCK;
  wire  [2:0]                      mst_HREADY;
  wire  [2:0]                      mst_HREADYOUT;
  wire  [2:0]                      mst_HRESP;

  //AHB Bus Slaves Interfaces
  wire  [CORES_PER_MISD-1:0]                      out_ins_HSEL;
  wire  [CORES_PER_MISD-1:0][PLEN           -1:0] out_ins_HADDR;
  wire  [CORES_PER_MISD-1:0][XLEN           -1:0] out_ins_HWDATA;
  wire  [CORES_PER_MISD-1:0][XLEN           -1:0] out_ins_HRDATA;
  wire  [CORES_PER_MISD-1:0]                      out_ins_HWRITE;
  wire  [CORES_PER_MISD-1:0][                2:0] out_ins_HSIZE;
  wire  [CORES_PER_MISD-1:0][                2:0] out_ins_HBURST;
  wire  [CORES_PER_MISD-1:0][                3:0] out_ins_HPROT;
  wire  [CORES_PER_MISD-1:0][                1:0] out_ins_HTRANS;
  wire  [CORES_PER_MISD-1:0]                      out_ins_HMASTLOCK;
  wire  [CORES_PER_MISD-1:0]                      out_ins_HREADY;
  wire  [CORES_PER_MISD-1:0]                      out_ins_HREADYOUT;
  wire  [CORES_PER_MISD-1:0]                      out_ins_HRESP;

  wire  [CORES_PER_MISD-1:0]                      out_dat_HSEL;
  wire  [CORES_PER_MISD-1:0][PLEN           -1:0] out_dat_HADDR;
  wire  [CORES_PER_MISD-1:0][XLEN           -1:0] out_dat_HWDATA;
  wire  [CORES_PER_MISD-1:0][XLEN           -1:0] out_dat_HRDATA;
  wire  [CORES_PER_MISD-1:0]                      out_dat_HWRITE;
  wire  [CORES_PER_MISD-1:0][                2:0] out_dat_HSIZE;
  wire  [CORES_PER_MISD-1:0][                2:0] out_dat_HBURST;
  wire  [CORES_PER_MISD-1:0][                3:0] out_dat_HPROT;
  wire  [CORES_PER_MISD-1:0][                1:0] out_dat_HTRANS;
  wire  [CORES_PER_MISD-1:0]                      out_dat_HMASTLOCK;
  wire  [CORES_PER_MISD-1:0]                      out_dat_HREADY;
  wire  [CORES_PER_MISD-1:0]                      out_dat_HRESP;

  wire  [CORES_PER_MISD-1:0]                      bus_dat_HSEL;
  wire  [CORES_PER_MISD-1:0][PLEN           -1:0] bus_dat_HADDR;
  wire  [CORES_PER_MISD-1:0][XLEN           -1:0] bus_dat_HWDATA;
  wire  [CORES_PER_MISD-1:0][XLEN           -1:0] bus_dat_HRDATA;
  wire  [CORES_PER_MISD-1:0]                      bus_dat_HWRITE;
  wire  [CORES_PER_MISD-1:0][                2:0] bus_dat_HSIZE;
  wire  [CORES_PER_MISD-1:0][                2:0] bus_dat_HBURST;
  wire  [CORES_PER_MISD-1:0][                3:0] bus_dat_HPROT;
  wire  [CORES_PER_MISD-1:0][                1:0] bus_dat_HTRANS;
  wire  [CORES_PER_MISD-1:0]                      bus_dat_HMASTLOCK;
  wire  [CORES_PER_MISD-1:0]                      bus_dat_HREADY;
  wire  [CORES_PER_MISD-1:0]                      bus_dat_HRESP;

  wire                        slv_noc_HSEL;
  wire  [PLEN           -1:0] slv_noc_HADDR;
  wire  [XLEN           -1:0] slv_noc_HWDATA;
  wire  [XLEN           -1:0] slv_noc_HRDATA;
  wire                        slv_noc_HWRITE;
  wire  [                2:0] slv_noc_HSIZE;
  wire  [                2:0] slv_noc_HBURST;
  wire  [                3:0] slv_noc_HPROT;
  wire  [                1:0] slv_noc_HTRANS;
  wire                        slv_noc_HMASTLOCK;
  wire                        slv_noc_HREADY;
  wire                        slv_noc_HRESP;

  wire  [CORES_PER_MISD:0]                      slv_HSEL;
  wire  [CORES_PER_MISD:0][PLEN           -1:0] slv_HADDR;
  wire  [CORES_PER_MISD:0][XLEN           -1:0] slv_HWDATA;
  wire  [CORES_PER_MISD:0][XLEN           -1:0] slv_HRDATA;
  wire  [CORES_PER_MISD:0]                      slv_HWRITE;
  wire  [CORES_PER_MISD:0][                2:0] slv_HSIZE;
  wire  [CORES_PER_MISD:0][                2:0] slv_HBURST;
  wire  [CORES_PER_MISD:0][                3:0] slv_HPROT;
  wire  [CORES_PER_MISD:0][                1:0] slv_HTRANS;
  wire  [CORES_PER_MISD:0]                      slv_HMASTLOCK;
  wire  [CORES_PER_MISD:0]                      slv_HREADY;
  wire  [CORES_PER_MISD:0]                      slv_HRESP;

  logic [                2:0] requested_priority_lvl;        //requested priority level
  logic [CORES_PER_MISD -1:0] priority_misd_masters;         //all masters at this priority level

  logic [CORES_PER_MISD -1:0] pending_misd_master,           //next master waiting to be served
                              last_granted_misd_master;      //for requested priority level
  logic [CORES_PER_MISD -1:0] last_granted_misd_masters [3]; //per priority level, for round-robin


  logic [MISD_BITS      -1:0] granted_misd_master_idx,       //granted master as index
                              granted_misd_master_idx_dly;   //deleayed granted master index (for HWDATA)

  logic [CORES_PER_MISD -1:0] granted_misd_master;

  logic [2*CORES_PER_MISD-1:0][XLEN -1:0] dii_in_data;
  logic [2*CORES_PER_MISD-1:0]            dii_in_last;
  logic [2*CORES_PER_MISD-1:0]            dii_in_valid;
  logic [2*CORES_PER_MISD-1:0]            dii_in_ready;

  logic [2*CORES_PER_MISD-1:0][XLEN -1:0] dii_out_data;
  logic [2*CORES_PER_MISD-1:0]            dii_out_last;
  logic [2*CORES_PER_MISD-1:0]            dii_out_valid;
  logic [2*CORES_PER_MISD-1:0]            dii_out_ready;

  logic [CORES_PER_MISD-1:0][XLEN    -1:0] trace_port_insn;
  logic [CORES_PER_MISD-1:0][XLEN    -1:0] trace_port_pc;
  logic [CORES_PER_MISD-1:0]               trace_port_jb;
  logic [CORES_PER_MISD-1:0]               trace_port_jal;
  logic [CORES_PER_MISD-1:0]               trace_port_jr;
  logic [CORES_PER_MISD-1:0][XLEN    -1:0] trace_port_jbtarget;
  logic [CORES_PER_MISD-1:0]               trace_port_valid;
  logic [CORES_PER_MISD-1:0][VALWIDTH-1:0] trace_port_data;
  logic [CORES_PER_MISD-1:0][         4:0] trace_port_addr;
  logic [CORES_PER_MISD-1:0]               trace_port_we;

  ////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //Instantiate RISC-V PU
  generate
    for (t=0; t < CORES_PER_MISD; t=t+1) begin
      riscv_pu #(
        .XLEN                  ( XLEN ),
        .PLEN                  ( PLEN ),
        .PC_INIT               ( PC_INIT ),
        .HAS_USER              ( HAS_USER ),
        .HAS_SUPER             ( HAS_SUPER ),
        .HAS_HYPER             ( HAS_HYPER ),
        .HAS_BPU               ( HAS_BPU ),
        .HAS_FPU               ( HAS_FPU ),
        .HAS_MMU               ( HAS_MMU ),
        .HAS_RVM               ( HAS_RVM ),
        .HAS_RVA               ( HAS_RVA ),
        .HAS_RVC               ( HAS_RVC ),
        .IS_RV32E              ( IS_RV32E ),

        .MULT_LATENCY          ( MULT_LATENCY ),

        .BREAKPOINTS           ( BREAKPOINTS ),

        .PMA_CNT               ( PMA_CNT ),
        .PMP_CNT               ( PMP_CNT ),

        .BP_GLOBAL_BITS        ( BP_GLOBAL_BITS ),
        .BP_LOCAL_BITS         ( BP_LOCAL_BITS ),

        .ICACHE_SIZE           ( ICACHE_SIZE ),
        .ICACHE_BLOCK_SIZE     ( ICACHE_BLOCK_SIZE ),
        .ICACHE_WAYS           ( ICACHE_WAYS ),
        .ICACHE_REPLACE_ALG    ( ICACHE_REPLACE_ALG ),
        .ITCM_SIZE             ( ITCM_SIZE ),

        .DCACHE_SIZE           ( DCACHE_SIZE ),
        .DCACHE_BLOCK_SIZE     ( DCACHE_BLOCK_SIZE ),
        .DCACHE_WAYS           ( DCACHE_WAYS ),
        .DCACHE_REPLACE_ALG    ( DCACHE_REPLACE_ALG ),
        .DTCM_SIZE             ( DTCM_SIZE ),
        .WRITEBUFFER_SIZE      ( WRITEBUFFER_SIZE ),

        .TECHNOLOGY            ( TECHNOLOGY ),

        .MNMIVEC_DEFAULT       ( MNMIVEC_DEFAULT ),
        .MTVEC_DEFAULT         ( MTVEC_DEFAULT ),
        .HTVEC_DEFAULT         ( HTVEC_DEFAULT ),
        .STVEC_DEFAULT         ( STVEC_DEFAULT ),
        .UTVEC_DEFAULT         ( UTVEC_DEFAULT ),

        .JEDEC_BANK            ( JEDEC_BANK ),
        .JEDEC_MANUFACTURER_ID ( JEDEC_MANUFACTURER_ID ),

        .HARTID                ( HARTID ),

        .PARCEL_SIZE           ( PARCEL_SIZE )
      )
      pu (
        //Common signals
        .HRESETn       ( HRESETn ),
        .HCLK          ( HCLK ),

        //PMA configuration
        .pma_cfg_i     ( pma_cfg_i ),
        .pma_adr_i     ( pma_adr_i ),

        //AHB instruction
        .ins_HSEL      ( ins_HSEL          [t] ),
        .ins_HADDR     ( ins_HADDR         [t] ),
        .ins_HWDATA    ( ins_HWDATA        [t] ),
        .ins_HRDATA    ( ins_HRDATA        [t] ),
        .ins_HWRITE    ( ins_HWRITE        [t] ),
        .ins_HSIZE     ( ins_HSIZE         [t] ),
        .ins_HBURST    ( ins_HBURST        [t] ),
        .ins_HPROT     ( ins_HPROT         [t] ),
        .ins_HTRANS    ( ins_HTRANS        [t] ),
        .ins_HMASTLOCK ( ins_HMASTLOCK     [t] ),
        .ins_HREADY    ( ins_HREADY        [t] ),
        .ins_HRESP     ( ins_HRESP         [t] ),

        //AHB data
        .dat_HSEL      ( bus_dat_HSEL      [t] ),
        .dat_HADDR     ( bus_dat_HADDR     [t] ),
        .dat_HWDATA    ( bus_dat_HWDATA    [t] ),
        .dat_HRDATA    ( bus_dat_HRDATA    [t] ),
        .dat_HWRITE    ( bus_dat_HWRITE    [t] ),
        .dat_HSIZE     ( bus_dat_HSIZE     [t] ),
        .dat_HBURST    ( bus_dat_HBURST    [t] ),
        .dat_HPROT     ( bus_dat_HPROT     [t] ),
        .dat_HTRANS    ( bus_dat_HTRANS    [t] ),
        .dat_HMASTLOCK ( bus_dat_HMASTLOCK [t] ),
        .dat_HREADY    ( bus_dat_HREADY    [t] ),
        .dat_HRESP     ( bus_dat_HRESP     [t] ),

        //Interrupts Interface
        .ext_nmi       ( ext_nmi           [t] ),
        .ext_tint      ( ext_tint          [t] ),
        .ext_sint      ( ext_sint          [t] ),
        .ext_int       ( ext_int           [t] ),

        //Debug Interface
        .dbg_stall     ( dbg_stall         [t] ),
        .dbg_strb      ( dbg_strb          [t] ),
        .dbg_we        ( dbg_we            [t] ),
        .dbg_addr      ( dbg_addr          [t] ),
        .dbg_dati      ( dbg_dati          [t] ),
        .dbg_dato      ( dbg_dato          [t] ),
        .dbg_ack       ( dbg_ack           [t] ),
        .dbg_bp        ( dbg_bp            [t] )
      );
    end
  endgenerate

  //get highest priority from selected masters
  assign requested_priority_lvl = highest_requested_priority(bus_dat_HSEL);

  //get pending masters for the highest priority requested
  assign priority_misd_masters = requesters(bus_dat_HSEL, requested_priority_lvl);

  //get last granted master for the priority requested
  assign last_granted_misd_master = last_granted_misd_masters[requested_priority_lvl];

  //get next master to serve
  assign pending_misd_master = nxt_misd_master(priority_misd_masters, last_granted_misd_master, granted_misd_master);

  //select new master
  always @(posedge HCLK, negedge HRESETn)
    if      ( !HRESETn  ) granted_misd_master <= 'h1;
    else if ( !dat_HSEL ) granted_misd_master <= pending_misd_master;

  //store current master (for this priority level)
  always @(posedge HCLK, negedge HRESETn)
    if      ( !HRESETn  ) last_granted_misd_masters[requested_priority_lvl] <= 'h1;
    else if ( !dat_HSEL ) last_granted_misd_masters[requested_priority_lvl] <= pending_misd_master;

  //get signals from current requester
  always @(posedge HCLK, negedge HRESETn)
    if      ( !HRESETn  ) granted_misd_master_idx <= 'h0;
    else if ( !dat_HSEL ) granted_misd_master_idx <= onehot2int(pending_misd_master);

  always @(posedge HCLK)
    if (dat_HSEL) granted_misd_master_idx_dly <= granted_misd_master_idx;

  assign dat_HSEL      = bus_dat_HSEL      [granted_misd_master_idx];
  assign dat_HADDR     = bus_dat_HADDR     [granted_misd_master_idx];
  assign dat_HWDATA    = bus_dat_HWDATA    [granted_misd_master_idx_dly];
  assign dat_HWRITE    = bus_dat_HWRITE    [granted_misd_master_idx];
  assign dat_HSIZE     = bus_dat_HSIZE     [granted_misd_master_idx];
  assign dat_HBURST    = bus_dat_HBURST    [granted_misd_master_idx];
  assign dat_HPROT     = bus_dat_HPROT     [granted_misd_master_idx];
  assign dat_HTRANS    = bus_dat_HTRANS    [granted_misd_master_idx];
  assign dat_HMASTLOCK = bus_dat_HMASTLOCK [granted_misd_master_idx];

  generate
    for(t=0; t < CORES_PER_MISD; t=t+1) begin
      assign bus_dat_HRDATA [t] = dat_HRDATA;
      assign bus_dat_HREADY [t] = dat_HREADY;
      assign bus_dat_HRESP  [t] = dat_HRESP;
    end
  endgenerate

  //AHB Master-Slave Relations
  assign out_dat_HSEL      = bus_dat_HSEL;
  assign out_dat_HADDR     = bus_dat_HADDR;
  assign out_dat_HWDATA    = bus_dat_HWDATA;
  assign out_dat_HWRITE    = bus_dat_HWRITE;
  assign out_dat_HSIZE     = bus_dat_HSIZE;
  assign out_dat_HBURST    = bus_dat_HBURST;
  assign out_dat_HPROT     = bus_dat_HPROT;
  assign out_dat_HTRANS    = bus_dat_HTRANS;
  assign out_dat_HMASTLOCK = bus_dat_HMASTLOCK;

  assign bus_dat_HRDATA    = out_dat_HRDATA;
  assign bus_dat_HREADY    = out_dat_HREADY;
  assign bus_dat_HRESP     = out_dat_HRESP;

  assign out_ins_HSEL      = ins_HSEL;
  assign out_ins_HADDR     = ins_HADDR;
  assign out_ins_HWDATA    = ins_HWDATA;
  assign out_ins_HWRITE    = ins_HWRITE;
  assign out_ins_HSIZE     = ins_HSIZE;
  assign out_ins_HBURST    = ins_HBURST;
  assign out_ins_HPROT     = ins_HPROT;
  assign out_ins_HTRANS    = ins_HTRANS;
  assign out_ins_HMASTLOCK = ins_HMASTLOCK;
//assign out_ins_HREADYOUT = ins_HREADYOUT;

  assign out_ins_HRDATA    = ins_HRDATA;
  assign out_ins_HREADY    = ins_HREADY;
  assign out_ins_HRESP     = ins_HRESP;

  //AHB Master Interconnect
  assign mst_HSEL      [0] = mst_noc_HSEL;
  assign mst_HADDR     [0] = mst_noc_HADDR;
  assign mst_HWDATA    [0] = mst_noc_HWDATA;
  assign mst_HWRITE    [0] = mst_noc_HWRITE;
  assign mst_HSIZE     [0] = mst_noc_HSIZE;
  assign mst_HBURST    [0] = mst_noc_HBURST;
  assign mst_HPROT     [0] = mst_noc_HPROT;
  assign mst_HTRANS    [0] = mst_noc_HTRANS;
  assign mst_HMASTLOCK [0] = mst_noc_HMASTLOCK;

  //assign mst_noc_HRDATA    = mst_HRDATA    [0];
  //assign mst_noc_HREADYOUT = mst_HREADYOUT [0];
  //assign mst_noc_HRESP     = mst_HRESP     [0];

  assign mst_HSEL      [1] = mst_gpio_HSEL;
  assign mst_HADDR     [1] = mst_gpio_HADDR;
  assign mst_HWDATA    [1] = mst_gpio_HWDATA;
  assign mst_HWRITE    [1] = mst_gpio_HWRITE [0];
  assign mst_HSIZE     [1] = mst_gpio_HSIZE;
  assign mst_HBURST    [1] = mst_gpio_HBURST;
  assign mst_HPROT     [1] = mst_gpio_HPROT;
  assign mst_HTRANS    [1] = mst_gpio_HTRANS;
  assign mst_HMASTLOCK [1] = mst_gpio_HMASTLOCK;
  assign mst_HREADY    [1] = mst_gpio_HREADY;

  //assign mst_gpio_HRDATA    = mst_HRDATA    [1];
  //assign mst_gpio_HREADYOUT = mst_HREADYOUT [1];
  //assign mst_gpio_HRESP     = mst_HRESP     [1];

  assign mst_HSEL      [2] = mst_sram_HSEL;
  assign mst_HADDR     [2] = mst_sram_HADDR;
  assign mst_HWDATA    [2] = mst_sram_HWDATA;
  assign mst_HWRITE    [2] = mst_sram_HWRITE;
  assign mst_HSIZE     [2] = mst_sram_HSIZE;
  assign mst_HBURST    [2] = mst_sram_HBURST;
  assign mst_HPROT     [2] = mst_sram_HPROT;
  assign mst_HTRANS    [2] = mst_sram_HTRANS;
  assign mst_HMASTLOCK [2] = mst_sram_HMASTLOCK;
  assign mst_HREADY    [2] = mst_sram_HREADY;

  //assign mst_sram_HRDATA    = mst_HRDATA    [2];
  //assign mst_sram_HREADYOUT = mst_HREADYOUT [2];
  //assign mst_sram_HRESP     = mst_HRESP     [2];

  //AHB Slave Interconnect
  generate
    for(t=0; t < CORES_PER_MISD; t=t+1) begin
      assign out_dat_HSEL      [t] = slv_HSEL      [t];
      assign out_dat_HADDR     [t] = slv_HADDR     [t];
      assign out_dat_HWDATA    [t] = slv_HWDATA    [t];
      assign out_dat_HWRITE    [t] = slv_HWRITE    [t];
      assign out_dat_HSIZE     [t] = slv_HSIZE     [t];
      assign out_dat_HBURST    [t] = slv_HBURST    [t];
      assign out_dat_HPROT     [t] = slv_HPROT     [t];
      assign out_dat_HTRANS    [t] = slv_HTRANS    [t];
      assign out_dat_HMASTLOCK [t] = slv_HMASTLOCK [t];
    end
  endgenerate

  generate
    for(t=0; t < CORES_PER_MISD; t=t+1) begin
      assign slv_HRDATA [t] = out_dat_HRDATA [t];
      assign slv_HREADY [t] = out_dat_HREADY [t];
      assign slv_HRESP  [t] = out_dat_HRESP  [t];
    end
  endgenerate

  //assign slv_noc_HSEL      = slv_HSEL      [CORES_PER_MISD];
  //assign slv_noc_HADDR     = slv_HADDR     [CORES_PER_MISD];
  //assign slv_noc_HWDATA    = slv_HWDATA    [CORES_PER_MISD];
  //assign slv_noc_HWRITE    = slv_HWRITE    [CORES_PER_MISD];
  //assign slv_noc_HSIZE     = slv_HSIZE     [CORES_PER_MISD];
  //assign slv_noc_HBURST    = slv_HBURST    [CORES_PER_MISD];
  //assign slv_noc_HPROT     = slv_HPROT     [CORES_PER_MISD];
  //assign slv_noc_HTRANS    = slv_HTRANS    [CORES_PER_MISD];
  //assign slv_noc_HMASTLOCK = slv_HMASTLOCK [CORES_PER_MISD];

  assign slv_HRDATA [CORES_PER_MISD] = slv_noc_HRDATA;
  assign slv_HREADY [CORES_PER_MISD] = slv_noc_HREADY;
  assign slv_HRESP  [CORES_PER_MISD] = slv_noc_HRESP;

  //Instantiate RISC-V Interconnect
  riscv_interconnect #(
    .PLEN    ( PLEN               ),
    .XLEN    ( XLEN               ),
    .MASTERS ( 3                  ),
    .SLAVES  ( CORES_PER_MISD + 1 )
  )
  peripheral_interconnect (
    //Common signals
    .HRESETn       ( HRESETn ),
    .HCLK          ( HCLK    ),

    //Master Ports; AHB masters connect to these
    //thus these are actually AHB Slave Interfaces
    .mst_priority  (               ),

    .mst_HSEL      ( mst_HSEL      ),
    .mst_HADDR     ( mst_HADDR     ),
    .mst_HWDATA    ( mst_HWDATA    ),
    .mst_HRDATA    ( mst_HRDATA    ),
    .mst_HWRITE    ( mst_HWRITE    ),
    .mst_HSIZE     ( mst_HSIZE     ),
    .mst_HBURST    ( mst_HBURST    ),
    .mst_HPROT     ( mst_HPROT     ),
    .mst_HTRANS    ( mst_HTRANS    ),
    .mst_HMASTLOCK ( mst_HMASTLOCK ),
    .mst_HREADYOUT ( mst_HREADYOUT ),
    .mst_HREADY    ( mst_HREADY    ),
    .mst_HRESP     ( mst_HRESP     ),

    //Slave Ports; AHB Slaves connect to these
    //thus these are actually AHB Master Interfaces
    .slv_addr_mask (               ),
    .slv_addr_base (               ),

    .slv_HSEL      ( slv_HSEL      ),
    .slv_HADDR     ( slv_HADDR     ),
    .slv_HWDATA    ( slv_HWDATA    ),
    .slv_HRDATA    ( slv_HRDATA    ),
    .slv_HWRITE    ( slv_HWRITE    ),
    .slv_HSIZE     ( slv_HSIZE     ),
    .slv_HBURST    ( slv_HBURST    ),
    .slv_HPROT     ( slv_HPROT     ),
    .slv_HTRANS    ( slv_HTRANS    ),
    .slv_HMASTLOCK ( slv_HMASTLOCK ),
    .slv_HREADYOUT (               ),
    .slv_HREADY    ( slv_HREADY    ),
    .slv_HRESP     ( slv_HRESP     )
  );

  riscv_interconnect #(
    .PLEN    ( PLEN           ),
    .XLEN    ( XLEN           ),
    .MASTERS ( CORES_PER_MISD ),
    .SLAVES  ( CORES_PER_MISD )
  )
  memory_interconnect (
    //Common signals
    .HRESETn       ( HRESETn ),
    .HCLK          ( HCLK    ),

    //Master Ports; AHB masters connect to these
    //thus these are actually AHB Slave Interfaces
    .mst_priority  (                    ),

    .mst_HSEL      ( mst_mram_HSEL      ),
    .mst_HADDR     ( mst_mram_HADDR     ),
    .mst_HWDATA    ( mst_mram_HWDATA    ),
    .mst_HRDATA    ( mst_mram_HRDATA    ),
    .mst_HWRITE    ( mst_mram_HWRITE    ),
    .mst_HSIZE     ( mst_mram_HSIZE     ),
    .mst_HBURST    ( mst_mram_HBURST    ),
    .mst_HPROT     ( mst_mram_HPROT     ),
    .mst_HTRANS    ( mst_mram_HTRANS    ),
    .mst_HMASTLOCK ( mst_mram_HMASTLOCK ),
    .mst_HREADYOUT ( mst_mram_HREADYOUT ),
    .mst_HREADY    ( mst_mram_HREADY    ),
    .mst_HRESP     ( mst_mram_HRESP     ),

    //Slave Ports; AHB Slaves connect to these
    //thus these are actually AHB Master Interfaces
    .slv_addr_mask (                    ),
    .slv_addr_base (                    ),

    .slv_HSEL      ( out_ins_HSEL       ),
    .slv_HADDR     ( out_ins_HADDR      ),
    .slv_HWDATA    ( out_ins_HWDATA     ),
    .slv_HRDATA    ( out_ins_HRDATA     ),
    .slv_HWRITE    ( out_ins_HWRITE     ),
    .slv_HSIZE     ( out_ins_HSIZE      ),
    .slv_HBURST    ( out_ins_HBURST     ),
    .slv_HPROT     ( out_ins_HPROT      ),
    .slv_HTRANS    ( out_ins_HTRANS     ),
    .slv_HMASTLOCK ( out_ins_HMASTLOCK  ),
    .slv_HREADYOUT ( out_ins_HREADYOUT  ),
    .slv_HREADY    ( out_ins_HREADY     ),
    .slv_HRESP     ( out_ins_HRESP      )
  );

  //Instantiate RISC-V NoC Adapter
  riscv_noc_adapter #(
    .HADDR_SIZE   ( HADDR_SIZE   ),
    .HDATA_SIZE   ( HDATA_SIZE   ),
    .BUFFER_DEPTH ( BUFFER_DEPTH ),
    .CHANNELS     ( CHANNELS     )
  )
  noc_adapter (
    //Common signals
    .HCLK          ( HCLK               ),
    .HRESETn       ( HRESETn            ),

    //NoC Interface
    .noc_in_flit   ( noc_in_flit        ),
    .noc_in_last   ( noc_in_last        ),
    .noc_in_valid  ( noc_in_valid       ),
    .noc_in_ready  ( noc_in_ready       ),
    .noc_out_flit  ( noc_out_flit       ),
    .noc_out_last  ( noc_out_last       ),
    .noc_out_valid ( noc_out_valid      ),
    .noc_out_ready ( noc_out_ready      ),

    //AHB master interface
    .mst_HSEL      ( mst_noc_HSEL      ),
    .mst_HADDR     ( mst_noc_HADDR     ),
    .mst_HWDATA    ( mst_noc_HWDATA    ),
    .mst_HRDATA    ( mst_noc_HRDATA    ),
    .mst_HWRITE    ( mst_noc_HWRITE    ),
    .mst_HSIZE     ( mst_noc_HSIZE     ),
    .mst_HBURST    ( mst_noc_HBURST    ),
    .mst_HPROT     ( mst_noc_HPROT     ),
    .mst_HTRANS    ( mst_noc_HTRANS    ),
    .mst_HMASTLOCK ( mst_noc_HMASTLOCK ),
    .mst_HREADYOUT ( mst_noc_HREADYOUT ),
    .mst_HRESP     ( mst_noc_HRESP     ),

    //AHB slave interface
    .slv_HSEL      ( slv_noc_HSEL      ),
    .slv_HADDR     ( slv_noc_HADDR     ),
    .slv_HWDATA    ( slv_noc_HWDATA    ),
    .slv_HRDATA    ( slv_noc_HRDATA    ),
    .slv_HWRITE    ( slv_noc_HWRITE    ),
    .slv_HSIZE     ( slv_noc_HSIZE     ),
    .slv_HBURST    ( slv_noc_HBURST    ),
    .slv_HPROT     ( slv_noc_HPROT     ),
    .slv_HTRANS    ( slv_noc_HTRANS    ),
    .slv_HMASTLOCK ( slv_noc_HMASTLOCK ),
    .slv_HREADY    ( slv_noc_HREADY    ),
    .slv_HRESP     ( slv_noc_HRESP     )
  );

  //Instantiate RISC-V GPIO
  riscv_bridge #(
    .HADDR_SIZE ( HADDR_SIZE ),
    .HDATA_SIZE ( HDATA_SIZE ),
    .PADDR_SIZE ( PADDR_SIZE ),
    .PDATA_SIZE ( PDATA_SIZE ),
    .SYNC_DEPTH ( SYNC_DEPTH )
  )
  gpio_bridge (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( mst_gpio_HSEL      ),
    .HADDR     ( mst_gpio_HADDR     ),
    .HWDATA    ( mst_gpio_HWDATA    ),
    .HRDATA    ( mst_gpio_HRDATA    ),
    .HWRITE    ( mst_gpio_HWRITE    ),
    .HSIZE     ( mst_gpio_HSIZE     ),
    .HBURST    ( mst_gpio_HBURST    ),
    .HPROT     ( mst_gpio_HPROT     ),
    .HTRANS    ( mst_gpio_HTRANS    ),
    .HMASTLOCK ( mst_gpio_HMASTLOCK ),
    .HREADYOUT ( mst_gpio_HREADYOUT ),
    .HREADY    ( mst_gpio_HREADY    ),
    .HRESP     ( mst_gpio_HRESP     ),

    //APB Master Interface
    .PRESETn ( HRESETn ),
    .PCLK    ( HCLK    ),

    .PSEL    ( gpio_PSEL    ),
    .PENABLE ( gpio_PENABLE ),
    .PPROT   (              ),
    .PWRITE  ( gpio_PWRITE  ),
    .PSTRB   ( gpio_PSTRB   ),
    .PADDR   ( gpio_PADDR   ),
    .PWDATA  ( gpio_PWDATA  ),
    .PRDATA  ( gpio_PRDATA  ),
    .PREADY  ( gpio_PREADY  ),
    .PSLVERR ( gpio_PSLVERR )
  );

  riscv_gpio #(
    .PADDR_SIZE (HADDR_SIZE),
    .PDATA_SIZE (HDATA_SIZE)
  )
  gpio (
    .PRESETn ( HRESETn ),
    .PCLK    ( HCLK    ),

    .PSEL    ( gpio_PSEL    ),
    .PENABLE ( gpio_PENABLE ),
    .PWRITE  ( gpio_PWRITE  ),
    .PSTRB   ( gpio_PSTRB   ),
    .PADDR   ( gpio_PADDR   ),
    .PWDATA  ( gpio_PWDATA  ),
    .PRDATA  ( gpio_PRDATA  ),
    .PREADY  ( gpio_PREADY  ),
    .PSLVERR ( gpio_PSLVERR ),

    .gpio_i  ( gpio_i       ),
    .gpio_o  ( gpio_o       ),
    .gpio_oe ( gpio_oe      )
  );

  //Instantiate RISC-V RAM
  riscv_mpram #(
    .MEM_SIZE          ( 0 ),
    .MEM_DEPTH         ( 256 ),
    .HADDR_SIZE        ( HADDR_SIZE ),
    .HDATA_SIZE        ( HDATA_SIZE ),
    .CORES_PER_TILE    ( CORES_PER_MISD ),
    .TECHNOLOGY        ( TECHNOLOGY ),
    .REGISTERED_OUTPUT ( "NO" )
  )
  mpram (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( mst_mram_HSEL      ),
    .HADDR     ( mst_mram_HADDR     ),
    .HWDATA    ( mst_mram_HWDATA    ),
    .HRDATA    ( mst_mram_HRDATA    ),
    .HWRITE    ( mst_mram_HWRITE    ),
    .HSIZE     ( mst_mram_HSIZE     ),
    .HBURST    ( mst_mram_HBURST    ),
    .HPROT     ( mst_mram_HPROT     ),
    .HTRANS    ( mst_mram_HTRANS    ),
    .HMASTLOCK ( mst_mram_HMASTLOCK ),
    .HREADYOUT ( mst_mram_HREADYOUT ),
    .HREADY    ( mst_mram_HREADY    ),
    .HRESP     ( mst_mram_HRESP     )
  );

  riscv_spram #(
    .MEM_SIZE          ( 0 ),
    .MEM_DEPTH         ( 256 ),
    .HADDR_SIZE        ( HADDR_SIZE ),
    .HDATA_SIZE        ( HDATA_SIZE ),
    .TECHNOLOGY        ( TECHNOLOGY ),
    .REGISTERED_OUTPUT ( "NO" )
  )
  spram (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( mst_sram_HSEL      ),
    .HADDR     ( mst_sram_HADDR     ),
    .HWDATA    ( mst_sram_HWDATA    ),
    .HRDATA    ( mst_sram_HRDATA    ),
    .HWRITE    ( mst_sram_HWRITE    ),
    .HSIZE     ( mst_sram_HSIZE     ),
    .HBURST    ( mst_sram_HBURST    ),
    .HPROT     ( mst_sram_HPROT     ),
    .HTRANS    ( mst_sram_HTRANS    ),
    .HMASTLOCK ( mst_sram_HMASTLOCK ),
    .HREADYOUT ( mst_sram_HREADYOUT ),
    .HREADY    ( mst_sram_HREADY    ),
    .HRESP     ( mst_sram_HRESP     )
  );

  //Instantiate RISC-V Debug
  riscv_debug_misd_expand #(
    .XLEN (XLEN),
    .CHANNELS (CHANNELS),
    .CORES_PER_MISD (CORES_PER_MISD)
  )
  debug_ring_expand (
    .clk           ( HCLK    ),
    .rst           ( HRESETn ),

    .id_map        (),
    .dii_in_data   ( dii_in_data          ),
    .dii_in_last   ( dii_in_last          ),
    .dii_in_valid  ( dii_in_valid         ),
    .dii_in_ready  ( dii_in_ready         ),
    .dii_out_data  ( dii_out_data         ),
    .dii_out_last  ( dii_out_last         ),
    .dii_out_valid ( dii_out_valid        ),
    .dii_out_ready ( dii_out_ready        ),
    .ext_in_data   ( debug_ring_in_data   ),
    .ext_in_last   ( debug_ring_in_last   ),
    .ext_in_valid  ( debug_ring_in_valid  ),
    .ext_in_ready  ( debug_ring_in_ready  ),
    .ext_out_data  ( debug_ring_out_data  ),
    .ext_out_last  ( debug_ring_out_last  ),
    .ext_out_valid ( debug_ring_out_valid ),
    .ext_out_ready ( debug_ring_out_ready )
  );

  generate
    for(t=0; t < CORES_PER_MISD; t=t+1) begin
      riscv_osd_ctm_template #(
        .XLEN (XLEN),
        .PLEN (PLEN),

        .MAX_REG_SIZE (64),

        .ADDR_WIDTH (PLEN),
        .DATA_WIDTH (XLEN),

        .VALWIDTH (VALWIDTH)
      )
      osd_ctm_template (
        .clk             ( HCLK    ),
        .rst             ( HRESETn ),

        .id              (),

        .debug_in_data   ( dii_out_data  [2*t] ),
        .debug_in_last   ( dii_out_last  [2*t] ),
        .debug_in_valid  ( dii_out_valid [2*t] ),
        .debug_in_ready  ( dii_out_ready [2*t] ),
        .debug_out_data  ( dii_in_data   [2*t] ),
        .debug_out_last  ( dii_in_last   [2*t] ),
        .debug_out_valid ( dii_in_valid  [2*t] ),
        .debug_out_ready ( dii_in_ready  [2*t] ),

        .trace_port_insn     ( trace_port_insn     [t] ),
        .trace_port_pc       ( trace_port_pc       [t] ),
        .trace_port_jb       ( trace_port_jb       [t] ),
        .trace_port_jal      ( trace_port_jal      [t] ),
        .trace_port_jr       ( trace_port_jr       [t] ),
        .trace_port_jbtarget ( trace_port_jbtarget [t] ),
        .trace_port_valid    ( trace_port_valid    [t] ),
        .trace_port_data     ( trace_port_data     [t] ),
        .trace_port_addr     ( trace_port_addr     [t] ),
        .trace_port_we       ( trace_port_we       [t] )
      );

      riscv_osd_stm_template #(
        .XLEN     (XLEN),
        .VALWIDTH (VALWIDTH)
      )
      osd_stm_template (
        .clk             ( HCLK    ),
        .rst             ( HRESETn ),

        .id              (),

        .debug_in_data   ( dii_out_data  [2*t+1] ),
        .debug_in_last   ( dii_out_last  [2*t+1] ),
        .debug_in_valid  ( dii_out_valid [2*t+1] ),
        .debug_in_ready  ( dii_out_ready [2*t+1] ),
        .debug_out_data  ( dii_in_data   [2*t+1] ),
        .debug_out_last  ( dii_in_last   [2*t+1] ),
        .debug_out_valid ( dii_in_valid  [2*t+1] ),
        .debug_out_ready ( dii_in_ready  [2*t+1] ),

        .trace_port_insn     ( trace_port_insn     [t] ),
        .trace_port_pc       ( trace_port_pc       [t] ),
        .trace_port_jb       ( trace_port_jb       [t] ),
        .trace_port_jal      ( trace_port_jal      [t] ),
        .trace_port_jr       ( trace_port_jr       [t] ),
        .trace_port_jbtarget ( trace_port_jbtarget [t] ),
        .trace_port_valid    ( trace_port_valid    [t] ),
        .trace_port_data     ( trace_port_data     [t] ),
        .trace_port_addr     ( trace_port_addr     [t] ),
        .trace_port_we       ( trace_port_we       [t] )
      );
    end
  endgenerate
endmodule
