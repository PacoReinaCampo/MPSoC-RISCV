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
//              Network on Chip Interface                                     //
//              AMBA3 AHB-Lite Bus Interface                                  //
//              Mesh Topology                                                 //
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

`include "riscv_noc_pkg.sv"

module riscv_noc_adapter #(
  parameter HADDR_SIZE   = 64,
  parameter HDATA_SIZE   = 64,
  parameter BUFFER_DEPTH = 4,
  parameter CHANNELS     = 2
)
  ( 
    //Common signals
    input                                   HCLK,
    input                                   HRESETn,

    //NoC Interface
    output [CHANNELS -1:0][HADDR_SIZE -1:0] noc_out_flit,
    output [CHANNELS -1:0]                  noc_out_last,
    output [CHANNELS -1:0]                  noc_out_valid,
    input  [CHANNELS -1:0]                  noc_out_ready,

    input  [CHANNELS -1:0][HADDR_SIZE -1:0] noc_in_flit,
    input  [CHANNELS -1:0]                  noc_in_last,
    input  [CHANNELS -1:0]                  noc_in_valid,
    output [CHANNELS -1:0]                  noc_in_ready,

    //AHB instruction interface
    input                                   mst_HSEL,
    input                 [HADDR_SIZE -1:0] mst_HADDR,
    input                 [HDATA_SIZE -1:0] mst_HWDATA,
    output logic          [HDATA_SIZE -1:0] mst_HRDATA,
    input                                   mst_HWRITE,
    input                 [            2:0] mst_HSIZE,
    input                 [            2:0] mst_HBURST,
    input                 [            3:0] mst_HPROT,
    input                 [            1:0] mst_HTRANS,
    input                                   mst_HMASTLOCK,
    output logic                            mst_HREADYOUT,
    output logic                            mst_HRESP,

    //AHB data interface
    output logic                            slv_HSEL,
    output logic          [HADDR_SIZE -1:0] slv_HADDR,
    output logic          [HDATA_SIZE -1:0] slv_HWDATA,
    input                 [HDATA_SIZE -1:0] slv_HRDATA,
    output logic                            slv_HWRITE,
    output logic          [            2:0] slv_HSIZE,
    output logic          [            2:0] slv_HBURST,
    output logic          [            3:0] slv_HPROT,
    output logic          [            1:0] slv_HTRANS,
    output logic                            slv_HMASTLOCK,
    input                                   slv_HREADY,
    input                                   slv_HRESP    
  );


  ////////////////////////////////////////////////////////////////
  //
  //Constants
  //

  //Those are the actual channels from the modules
  localparam MODCHANNELS = 4;

  localparam C_MPB_REQ   = 0;
  localparam C_MPB_RES   = 1;
  localparam C_DMA_REQ   = 2;
  localparam C_DMA_RES   = 3;

  localparam ELEMENTS = 2;

  localparam ELEMENTS_BITS = $clog2(ELEMENTS);

  ////////////////////////////////////////////////////////////////
  //
  // Functions
  //
  function integer onehot2int;
    input [ELEMENTS-1:0] onehot;

    for (onehot2int = - 1; |onehot; onehot2int++) onehot = onehot >> 1;
  endfunction //onehot2int


  function [2:0] highest_requested_priority (
    input [ELEMENTS-1:0] hsel       
  );
    logic [ELEMENTS-1:0][2:0] priorities;
    integer n;
    highest_requested_priority = 0;
    for (n=0; n<ELEMENTS; n++) begin
      priorities[n] = n;
      if (hsel[n] && priorities[n] > highest_requested_priority) highest_requested_priority = priorities[n];
    end
  endfunction //highest_requested_priority


  function [ELEMENTS-1:0] requesters;
    input [ELEMENTS-1:0] hsel;
    input [2:0] priority_select;
    logic [ELEMENTS-1:0][2:0] priorities;
    integer n;

    for (n=0; n<ELEMENTS; n++) begin
      priorities[n] = n;
      requesters[n] = (priorities[n] == priority_select) & hsel[n];
    end
  endfunction //requesters


  function [ELEMENTS-1:0] nxt_master;
    input [ELEMENTS-1:0] pending_masters;  //pending masters for the requesed priority level
    input [ELEMENTS-1:0] last_master;      //last granted master for the priority level
    input [ELEMENTS-1:0] current_master;   //current granted master (indpendent of priority level)

    integer n, offset;
    logic [ELEMENTS*2-1:0] sr;

    //default value, don't switch if not needed
    nxt_master = current_master;

    //implement round-robin
    offset = onehot2int(last_master) + 1;

    sr = {pending_masters, pending_masters};
    for (n = 0; n < ELEMENTS; n++)
      if ( sr[n + offset] ) return (1 << ((n+offset) % ELEMENTS));
  endfunction


  ////////////////////////////////////////////////////////////////
  //
  //Variables
  //
  genvar c, e;

  wire  [MODCHANNELS-1:0][HADDR_SIZE -1:0] mod_out_flit;
  wire  [MODCHANNELS-1:0]                  mod_out_last;
  wire  [MODCHANNELS-1:0]                  mod_out_valid;
  wire  [MODCHANNELS-1:0]                  mod_out_ready;

  wire  [MODCHANNELS-1:0][HADDR_SIZE -1:0] mod_in_flit;
  wire  [MODCHANNELS-1:0]                  mod_in_last;
  wire  [MODCHANNELS-1:0]                  mod_in_valid;
  wire  [MODCHANNELS-1:0]                  mod_in_ready;

  wire  [CHANNELS-1:0][HADDR_SIZE -1:0] muxed_flit;
  wire  [CHANNELS-1:0]                  muxed_last, 
                                        muxed_valid, 
                                        muxed_ready;

  wire  [CHANNELS-1:0][HADDR_SIZE -1:0] inbuffer_flit;
  wire  [CHANNELS-1:0]                  inbuffer_last,
                                        inbuffer_valid,
                                        inbuffer_ready;

  //AHB interface
  logic [ELEMENTS-1:0]                  bus_HSEL;
  logic [ELEMENTS-1:0][HADDR_SIZE -1:0] bus_HADDR;
  logic [ELEMENTS-1:0][HDATA_SIZE -1:0] bus_HWDATA;
  logic [ELEMENTS-1:0][HDATA_SIZE -1:0] bus_HRDATA;
  logic [ELEMENTS-1:0]                  bus_HWRITE;
  logic [ELEMENTS-1:0][            2:0] bus_HSIZE;
  logic [ELEMENTS-1:0][            2:0] bus_HBURST;
  logic [ELEMENTS-1:0][            3:0] bus_HPROT;
  logic [ELEMENTS-1:0][            1:0] bus_HTRANS;
  logic [ELEMENTS-1:0]                  bus_HMASTLOCK;
  logic [ELEMENTS-1:0]                  bus_HREADYOUT;
  logic [ELEMENTS-1:0]                  bus_HRESP;

  logic [            2:0] requested_priority_lvl;   //requested priority level
  logic [ELEMENTS   -1:0] priority_masters;         //all masters at this priority level

  logic [ELEMENTS   -1:0] pending_master,           //next master waiting to be served
                          last_granted_master;      //for requested priority level
  logic [ELEMENTS   -1:0] last_granted_masters [3]; //per priority level, for round-robin


  logic [ELEMENTS_BITS-1:0] granted_master_idx;     //granted master as index

  logic [ELEMENTS   -1:0] granted_master;

  ////////////////////////////////////////////////////////////////
  //
  //Module Body
  //
  //get highest priority from selected masters
  assign requested_priority_lvl = highest_requested_priority(bus_HSEL);

  //get pending masters for the highest priority requested
  assign priority_masters = requesters(bus_HSEL, requested_priority_lvl);

  //get last granted master for the priority requested
  assign last_granted_master = last_granted_masters[requested_priority_lvl];

  //get next master to serve
  assign pending_master = nxt_master(priority_masters, last_granted_master, granted_master);

  //select new master
  always @(posedge HCLK, negedge HRESETn) begin
    if      ( !HRESETn  ) granted_master <= 'h1;
    else if ( !mst_HSEL ) granted_master <= pending_master;
  end

  //store current master (for this priority level)
  always @(posedge HCLK, negedge HRESETn) begin
    if      ( !HRESETn  ) last_granted_masters[requested_priority_lvl] <= 'h1;
    else if ( !mst_HSEL ) last_granted_masters[requested_priority_lvl] <= pending_master;
  end

  //get signals from current requester
  always @(posedge HCLK, negedge HRESETn) begin
    if      ( !HRESETn  ) granted_master_idx <= 'h0;
    else if ( !mst_HSEL ) granted_master_idx <= onehot2int(pending_master);
  end

  generate
    for (e=0; e < ELEMENTS; e=e+1) begin
      assign bus_HSEL      [e] = mst_HSEL;
      assign bus_HADDR     [e] = mst_HADDR;
      assign bus_HWDATA    [e] = mst_HWDATA;
      assign bus_HWRITE    [e] = mst_HWRITE;
      assign bus_HSIZE     [e] = mst_HSIZE;
      assign bus_HBURST    [e] = mst_HBURST;
      assign bus_HPROT     [e] = mst_HPROT;
      assign bus_HTRANS    [e] = mst_HTRANS;
      assign bus_HMASTLOCK [e] = mst_HMASTLOCK;
    end
  endgenerate

  assign mst_HRDATA    = bus_HRDATA    [granted_master_idx];
  assign mst_HREADYOUT = bus_HREADYOUT [granted_master_idx];
  assign mst_HRESP     = bus_HRESP     [granted_master_idx];

  //Instantiate RISC-V DMA
  riscv_dma #(
    .XLEN (HDATA_SIZE),
    .PLEN (HADDR_SIZE),

    .NOC_PACKET_SIZE (16),

    .TABLE_ENTRIES (4),
    .DMA_REQMASK_WIDTH (5),
    .DMA_REQUEST_WIDTH (199),
    .DMA_REQFIELD_SIZE_WIDTH (64),
    .TABLE_ENTRIES_PTRWIDTH ($clog2(4))
  )
  dma (
    //Common signals
    .clk               ( HCLK    ),
    .rst               ( HRESETn ),

    //NoC Interface
    .noc_in_req_flit   ( mod_in_flit   [C_DMA_REQ] ),
    .noc_in_req_last   ( mod_in_last   [C_DMA_REQ] ),
    .noc_in_req_valid  ( mod_in_valid  [C_DMA_REQ] ),
    .noc_in_req_ready  ( mod_in_ready  [C_DMA_REQ] ),

    .noc_in_res_flit   ( mod_in_flit   [C_DMA_RES] ),
    .noc_in_res_last   ( mod_in_last   [C_DMA_RES] ),
    .noc_in_res_valid  ( mod_in_valid  [C_DMA_RES] ),
    .noc_in_res_ready  ( mod_in_ready  [C_DMA_RES] ),

    .noc_out_req_flit  ( mod_out_flit  [C_DMA_REQ] ),
    .noc_out_req_last  ( mod_out_last  [C_DMA_REQ] ),
    .noc_out_req_valid ( mod_out_valid [C_DMA_REQ] ),
    .noc_out_req_ready ( mod_out_ready [C_DMA_REQ] ),

    .noc_out_res_flit  ( mod_out_flit  [C_DMA_RES] ),
    .noc_out_res_last  ( mod_out_last  [C_DMA_RES] ),
    .noc_out_res_valid ( mod_out_valid [C_DMA_RES] ),
    .noc_out_res_ready ( mod_out_ready [C_DMA_RES] ),

    //Interrupts
    .irq           (),

    //AHB input interface
    .mst_HSEL      ( bus_HSEL      [0] ),
    .mst_HADDR     ( bus_HADDR     [0] ),
    .mst_HWDATA    ( bus_HWDATA    [0] ),
    .mst_HRDATA    ( bus_HRDATA    [0] ),
    .mst_HWRITE    ( bus_HWRITE    [0] ),
    .mst_HSIZE     ( bus_HSIZE     [0] ),
    .mst_HBURST    ( bus_HBURST    [0] ),
    .mst_HPROT     ( bus_HPROT     [0] ),
    .mst_HTRANS    ( bus_HTRANS    [0] ),
    .mst_HMASTLOCK ( bus_HMASTLOCK [0] ),
    .mst_HREADYOUT ( bus_HREADYOUT [0] ),
    .mst_HRESP     ( bus_HRESP     [0] ),

    //AHB output interface
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
    .slv_HREADY    ( slv_HREADY    ),
    .slv_HRESP     ( slv_HRESP     )
  );

  //Instantiate RISC-V Message Passing Buffer End-Point
  riscv_mpb #(
    .PLEN     ( HADDR_SIZE ),
    .XLEN     ( HDATA_SIZE ),
    .CHANNELS ( CHANNELS   ),
    .SIZE     ( 2          )
  )
  mpb (
    //Common signals
    .HRESETn ( HRESETn ),
    .HCLK    ( HCLK    ),

    //NoC Interface
    .noc_in_flit   ( {mod_in_flit   [C_MPB_RES], mod_in_flit   [C_MPB_REQ]} ),
    .noc_in_last   ( {mod_in_last   [C_MPB_RES], mod_in_last   [C_MPB_REQ]} ),
    .noc_in_valid  ( {mod_in_valid  [C_MPB_RES], mod_in_valid  [C_MPB_REQ]} ),
    .noc_in_ready  ( {mod_in_ready  [C_MPB_RES], mod_in_ready  [C_MPB_REQ]} ),

    .noc_out_flit  ( {mod_out_flit  [C_MPB_RES], mod_out_flit  [C_MPB_REQ]} ),
    .noc_out_last  ( {mod_out_last  [C_MPB_RES], mod_out_last  [C_MPB_REQ]} ),
    .noc_out_valid ( {mod_out_valid [C_MPB_RES], mod_out_valid [C_MPB_REQ]} ),
    .noc_out_ready ( {mod_out_ready [C_MPB_RES], mod_out_ready [C_MPB_REQ]} ),

    //AHB input interface
    .mst_HSEL      ( bus_HSEL      [1] ),
    .mst_HADDR     ( bus_HADDR     [1] ),
    .mst_HWDATA    ( bus_HWDATA    [1] ),
    .mst_HRDATA    ( bus_HRDATA    [1] ),
    .mst_HWRITE    ( bus_HWRITE    [1] ),
    .mst_HSIZE     ( bus_HSIZE     [1] ),
    .mst_HBURST    ( bus_HBURST    [1] ),
    .mst_HPROT     ( bus_HPROT     [1] ),
    .mst_HTRANS    ( bus_HTRANS    [1] ),
    .mst_HMASTLOCK ( bus_HMASTLOCK [1] ),
    .mst_HREADYOUT ( bus_HREADYOUT [1] ),
    .mst_HRESP     ( bus_HRESP     [1] )
  );

  generate
    for (c=0; c < CHANNELS; c=c+1) begin
      riscv_noc_channels_mux #(
        .PLEN     (HADDR_SIZE),
        .CHANNELS (CHANNELS)
      )
      noc_channels_mux (
        .clk       ( HCLK    ),
        .rst       ( HRESETn ),

        .in_flit   ( {mod_out_flit  [C_MPB_REQ + c], mod_out_flit  [C_DMA_REQ + c]} ),
        .in_last   ( {mod_out_last  [C_MPB_REQ + c], mod_out_last  [C_DMA_REQ + c]} ),
        .in_valid  ( {mod_out_valid [C_MPB_REQ + c], mod_out_valid [C_DMA_REQ + c]} ),
        .in_ready  ( {mod_out_ready [C_MPB_REQ + c], mod_out_ready [C_DMA_REQ + c]} ),

        .out_flit  ( muxed_flit     [c] ),
        .out_last  ( muxed_last     [c] ),
        .out_valid ( muxed_valid    [c] ),
        .out_ready ( muxed_ready    [c] )
      );

      riscv_noc_buffer #(
        .PLEN         ( HADDR_SIZE   ),
        .BUFFER_DEPTH ( BUFFER_DEPTH ),
        .FULLPACKET   ( 0            )
      )
      out_buffer (
        .clk         ( HCLK    ),
        .rst         ( HRESETn ),

        .in_flit     ( muxed_flit    [c] ),
        .in_last     ( muxed_last    [c] ),
        .in_valid    ( muxed_valid   [c] ),
        .in_ready    ( muxed_ready   [c] ),

        .out_flit    ( noc_out_flit  [c][HDATA_SIZE-1:0] ),
        .out_last    ( noc_out_last  [c] ),
        .out_valid   ( noc_out_valid [c] ),
        .out_ready   ( noc_out_ready [c] ),

        .packet_size ( )
      );

      riscv_noc_buffer #(
        .PLEN         ( HADDR_SIZE   ),
        .BUFFER_DEPTH ( BUFFER_DEPTH ),
        .FULLPACKET   ( 0            )
      )
      in_buffer (
        .clk         ( HCLK    ),
        .rst         ( HRESETn ),

        .in_flit     ( noc_in_flit    [c] ),
        .in_last     ( noc_in_last    [c] ),
        .in_valid    ( noc_in_valid   [c] ),
        .in_ready    ( noc_in_ready   [c] ),

        .out_flit    ( inbuffer_flit  [c] ),
        .out_last    ( inbuffer_last  [c] ),
        .out_valid   ( inbuffer_valid [c] ),
        .out_ready   ( inbuffer_ready [c] ),

        .packet_size ( )
      );

      riscv_noc_demux #(
        .PLEN     ( HADDR_SIZE          ),
        .CHANNELS ( CHANNELS            ),
        .MAPPING  ( {48'h0, 8'h2, 8'h1} )
      )
      noc_demux (
        .clk       ( HCLK    ),
        .rst       ( HRESETn ),

        .in_flit   ( inbuffer_flit  [c] ),
        .in_last   ( inbuffer_last  [c] ),
        .in_valid  ( inbuffer_valid [c] ),
        .in_ready  ( inbuffer_ready [c] ),

        .out_flit  ( {mod_in_flit   [C_DMA_REQ + c], mod_in_flit  [C_MPB_REQ + c]} ),
        .out_last  ( {mod_in_last   [C_DMA_REQ + c], mod_in_last  [C_MPB_REQ + c]} ),
        .out_valid ( {mod_in_valid  [C_DMA_REQ + c], mod_in_valid [C_MPB_REQ + c]} ),
        .out_ready ( {mod_in_ready  [C_DMA_REQ + c], mod_in_ready [C_MPB_REQ + c]} )
      );
    end
  endgenerate
endmodule
