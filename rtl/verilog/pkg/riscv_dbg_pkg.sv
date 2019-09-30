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
//              Network on Chip Package                                       //
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

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  `define WIDTH 64

  `define DEPTH 8

  `define SYSTEM_VENDOR_ID 2
  `define SYSTEM_DEVICE_ID 2
  `define NUM_MODULES 0

  `define SUBNET_BITS 6
  `define LOCAL_SUBNET 0
  `define DEBUG_ROUTER_BUFFER_SIZE 4

  `define BUFFER_SIZE 4

  `define FULLPACKET 0

  // Width of memory addresses
  `define ADDR_WIDTH 64

  // System word length
  `define DATA_WIDTH 64

  `define MOD_VENDOR 4
  `define MOD_TYPE 4
  `define MOD_VERSION 4
  `define MOD_EVENT_DEST_DEFAULT 4
  `define CAN_STALL 0
  `define MAX_REG_SIZE 64

  // The maximum number of payload words the packet could consist of.
  // The actual number of payload words is given by data_num_words.
  `define MAX_DATA_NUM_WORDS ((`DATA_WIDTH + 15) >> 4)
