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
//              Network on Chip Multiplexer                                   //
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

`include "riscv_mpsoc_pkg.sv"
`include "riscv_noc_pkg.sv"

module riscv_noc_channels_mux #(
  parameter PLEN = 64,
  parameter CHANNELS = 2
)
  (
    input                               clk,
    input                               rst,

    input      [CHANNELS-1:0][PLEN-1:0] in_flit,
    input      [CHANNELS-1:0]           in_last,
    input      [CHANNELS-1:0]           in_valid,
    output reg [CHANNELS-1:0]           in_ready,

    output reg               [PLEN-1:0] out_flit,
    output reg                          out_last,
    output reg                          out_valid,
    input                               out_ready
  );

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  wire [CHANNELS-1:0] selected;
  reg  [CHANNELS-1:0] active;

  reg                 activeroute;
  reg                 nxt_activeroute;

  wire [CHANNELS-1:0] req_masked;

  integer c;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  assign req_masked = {CHANNELS{~activeroute & out_ready}} & in_valid;

  always @(*) begin
    out_flit = {PLEN{1'b0}};
    out_last = 1'b0;
    for (c = 0; c < CHANNELS; c=c+1) begin
      if (selected[c]) begin
        out_flit = in_flit[c];
        out_last = in_last[c];
      end
    end
  end

  always @(*) begin
    nxt_activeroute = activeroute;
    in_ready = {CHANNELS{1'b0}};

    if (activeroute) begin
      if (|(in_valid & active) && out_ready) begin
        in_ready = active;
        out_valid = 1;
        if (out_last)
          nxt_activeroute = 1'b0;
      end
      else begin
        out_valid = 1'b0;
        in_ready = 'b0;
      end
    end
    else begin
      out_valid = 1'b0;
      if (|in_valid && out_ready) begin
        out_valid = 1'b1;
        nxt_activeroute = ~out_last;
        in_ready = selected;
      end
    end
  end // always @ (*)

  always @(posedge clk) begin
    if (rst) begin
      activeroute <= 0;
      active <= {{CHANNELS-1{1'b0}},1'b1};
    end
    else begin
      activeroute <= nxt_activeroute;
      active <= selected;
    end
  end

  riscv_arb_rr #(
    .N (CHANNELS)
  )
  arb_rr (
    .nxt_gnt (selected),
    .req     (req_masked),
    .gnt     (active),
    .en      (1'b1)
  );
endmodule
