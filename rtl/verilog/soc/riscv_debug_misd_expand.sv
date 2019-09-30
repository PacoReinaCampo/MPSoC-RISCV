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
//              Degub Interface                                               //
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
`include "riscv_dbg_pkg.sv"

module riscv_debug_misd_expand #(
  parameter XLEN = 64,
  parameter CHANNELS = 2,
  parameter CORES_PER_MISD = 8
)
  (
    input                            clk,
    input                            rst,

    input  [2*CORES_PER_MISD-1:0][XLEN -1:0] id_map,

    input  [2*CORES_PER_MISD-1:0][XLEN -1:0] dii_in_data,
    input  [2*CORES_PER_MISD-1:0]            dii_in_last,
    input  [2*CORES_PER_MISD-1:0]            dii_in_valid,
    output [2*CORES_PER_MISD-1:0]            dii_in_ready,

    output [2*CORES_PER_MISD-1:0][XLEN -1:0] dii_out_data,
    output [2*CORES_PER_MISD-1:0]            dii_out_last,
    output [2*CORES_PER_MISD-1:0]            dii_out_valid,
    input  [2*CORES_PER_MISD-1:0]            dii_out_ready,

    input  [CHANNELS-1:0][XLEN -1:0] ext_in_data,
    input  [CHANNELS-1:0]            ext_in_last,
    input  [CHANNELS-1:0]            ext_in_valid,
    output [CHANNELS-1:0]            ext_in_ready, // extension input ports

    output [CHANNELS-1:0][XLEN -1:0] ext_out_data,
    output [CHANNELS-1:0]            ext_out_last,
    output [CHANNELS-1:0]            ext_out_valid,
    input  [CHANNELS-1:0]            ext_out_ready // extension output ports
  );

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  genvar i;

  logic [CHANNELS-1:0][2*CORES_PER_MISD:0][XLEN -1:0] chain_data;
  logic [CHANNELS-1:0][2*CORES_PER_MISD:0]            chain_last;
  logic [CHANNELS-1:0][2*CORES_PER_MISD:0]            chain_valid;
  logic [CHANNELS-1:0][2*CORES_PER_MISD:0]            chain_ready;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  generate
    for(i=0; i<2*CORES_PER_MISD; i=i+1) begin : gen_router
      riscv_ring_router #(
        .XLEN (XLEN)
      )
      ring_router (
        .clk             (clk),
        .rst             (rst),

        .id              ( id_map[i]                   ),

        .ring_in0_data   ( chain_data  [0][i][XLEN-1:0]),
        .ring_in0_last   ( chain_last  [0][i]          ),
        .ring_in0_valid  ( chain_valid [0][i]          ),
        .ring_in0_ready  ( chain_ready [0][i]          ),

        .ring_in1_data   ( chain_data  [1][i][XLEN-1:0]),
        .ring_in1_last   ( chain_last  [1][i]          ),
        .ring_in1_valid  ( chain_valid [1][i]          ),
        .ring_in1_ready  ( chain_ready [1][i]          ),

        .ring_out0_data  ( chain_data  [0][i+1][XLEN-1:0]),
        .ring_out0_last  ( chain_last  [0][i+1]          ),
        .ring_out0_valid ( chain_valid [0][i+1]          ),
        .ring_out0_ready ( chain_ready [0][i+1]          ),

        .ring_out1_data  ( chain_data  [1][i+1][XLEN-1:0]),
        .ring_out1_last  ( chain_last  [1][i+1]          ),
        .ring_out1_valid ( chain_valid [1][i+1]          ),
        .ring_out1_ready ( chain_ready [1][i+1]          ),

        .local_in_data   ( dii_in_data   [i][XLEN-1:0] ),
        .local_in_last   ( dii_in_last   [i]           ),
        .local_in_valid  ( dii_in_valid  [i]           ),
        .local_in_ready  ( dii_in_ready  [i]           ),

        .local_out_data  ( dii_out_data  [i][XLEN-1:0] ),
        .local_out_last  ( dii_out_last  [i]           ),
        .local_out_valid ( dii_out_valid [i]           ),
        .local_out_ready ( dii_out_ready [i]           )
      );
    end // for (i=0; i<2*CORES_PER_MISD, i++)
  endgenerate

  // the expanded ports
  generate
    for(i=0; i<CHANNELS; i=i+1) begin
      assign chain_data  [i][0] = ext_in_data  [i];
      assign chain_last  [i][0] = ext_in_last  [i];
      assign chain_valid [i][0] = ext_in_valid [i];

      assign ext_in_ready[i] = chain_ready[i][0];

      assign ext_out_data  [i] = chain_data  [i][2*CORES_PER_MISD];
      assign ext_out_last  [i] = chain_last  [i][2*CORES_PER_MISD];
      assign ext_out_valid [i] = chain_valid [i][2*CORES_PER_MISD];

      assign chain_ready[i][2*CORES_PER_MISD] = ext_out_ready[i];
    end
  endgenerate
endmodule // debug_ring_expand
