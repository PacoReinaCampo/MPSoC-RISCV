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
//              Direct Memory Access Package                                  //
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

  `define FLIT_WIDTH        64

  `define FLIT_TYPE_PAYLOAD 2'b00
  `define FLIT_TYPE_HEADER  2'b01
  `define FLIT_TYPE_LAST    2'b10
  `define FLIT_TYPE_SINGLE  2'b11

  //Type of flit
  //The coding is chosen, so that
  //type[0] signals that this is the first flit of a packet
  //type[1] signals that this is the last  flit of a packet

  `define FLIT_TYPE_MSB    `FLIT_WIDTH - 1
  `define FLIT_TYPE_WIDTH  2
  `define FLIT_TYPE_LSB    `FLIT_TYPE_MSB - `FLIT_TYPE_WIDTH + 1

  //This is the flit content size
  `define FLIT_CONTENT_WIDTH 32
  `define FLIT_CONTENT_MSB   63
  `define FLIT_CONTENT_LSB   0

  //The following fields are only valid for header flits
  `define FLIT_DEST_WIDTH 5

  //destination address field of header flit
  `define FLIT_DEST_MSB `FLIT_CONTENT_MSB
  `define FLIT_DEST_LSB `FLIT_DEST_MSB - `FLIT_DEST_WIDTH + 1

  //packet type field  of header flit
  `define PACKET_CLASS_MSB   `FLIT_DEST_LSB - 1
  `define PACKET_CLASS_WIDTH 3
  `define PACKET_CLASS_LSB   `PACKET_CLASS_MSB - `PACKET_CLASS_WIDTH + 1

  `define PACKET_CLASS_DMA 3'b010

  //source address field  of header flit
  `define SOURCE_MSB   23
  `define SOURCE_WIDTH 5
  `define SOURCE_LSB   19

  //packet id field  of header flit
  `define PACKET_ID_MSB   18
  `define PACKET_ID_WIDTH 4
  `define PACKET_ID_LSB   15

  `define PACKET_TYPE_MSB   14
  `define PACKET_TYPE_WIDTH 2
  `define PACKET_TYPE_LSB   13

  `define PACKET_TYPE_L2R_REQ  2'b00
  `define PACKET_TYPE_R2L_REQ  2'b01
  `define PACKET_TYPE_L2R_RESP 2'b10
  `define PACKET_TYPE_R2L_RESP 2'b11

  `define PACKET_REQ_LAST 12
  `define PACKET_RES_LAST 12

  `define SIZE_MSB   61
  `define SIZE_WIDTH 62
  `define SIZE_LSB   0

  `define DMA_REQUEST_WIDTH 199

  `define DMA_REQFIELD_LADDR_WIDTH 64
  `define DMA_REQFIELD_SIZE_WIDTH  64
  `define DMA_REQFIELD_RTILE_WIDTH 5
  `define DMA_REQFIELD_RADDR_WIDTH 32

  `define DMA_REQFIELD_LADDR_MSB 198
  `define DMA_REQFIELD_LADDR_LSB 134
  `define DMA_REQFIELD_SIZE_MSB  133
  `define DMA_REQFIELD_SIZE_LSB  70
  `define DMA_REQFIELD_RTILE_MSB 69
  `define DMA_REQFIELD_RTILE_LSB 65
  `define DMA_REQFIELD_RADDR_MSB 64
  `define DMA_REQFIELD_RADDR_LSB 1
  `define DMA_REQFIELD_DIR       0

  `define DMA_REQUEST_INVALID 1'b0
  `define DMA_REQUEST_VALID   1'b1

  `define DMA_REQUEST_L2R 1'b0
  `define DMA_REQUEST_R2L 1'b1

  `define DMA_REQMASK_WIDTH 5
  `define DMA_REQMASK_LADDR 0
  `define DMA_REQMASK_SIZE  1
  `define DMA_REQMASK_RTILE 2
  `define DMA_REQMASK_RADDR 3
  `define DMA_REQMASK_DIR   4

  `define DMA_RESPFIELD_SIZE_WIDTH 64
