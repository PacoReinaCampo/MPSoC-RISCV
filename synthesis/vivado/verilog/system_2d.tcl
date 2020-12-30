###################################################################################
##                                            __ _      _     _                  ##
##                                           / _(_)    | |   | |                 ##
##                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |                 ##
##               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |                 ##
##              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |                 ##
##               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|                 ##
##                  | |                                                          ##
##                  |_|                                                          ##
##                                                                               ##
##                                                                               ##
##              MPSoC-SPRAM CPU                                                  ##
##              Synthesis Test Makefile                                          ##
##                                                                               ##
###################################################################################

###################################################################################
##                                                                               ##
## Copyright (c) 2018-2019 by the author(s)                                      ##
##                                                                               ##
## Permission is hereby granted, free of charge, to any person obtaining a copy  ##
## of this software and associated documentation files (the "Software"), to deal ##
## in the Software without restriction, including without limitation the rights  ##
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     ##
## copies of the Software, and to permit persons to whom the Software is         ##
## furnished to do so, subject to the following conditions:                      ##
##                                                                               ##
## The above copyright notice and this permission notice shall be included in    ##
## all copies or substantial portions of the Software.                           ##
##                                                                               ##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    ##
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      ##
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   ##
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        ##
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, ##
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     ##
## THE SOFTWARE.                                                                 ##
##                                                                               ##
## ============================================================================= ##
## Author(s):                                                                    ##
##   Francisco Javier Reina Campo <frareicam@gmail.com>                          ##
##                                                                               ##
###################################################################################

read_verilog -sv ../../../rtl/verilog/pkg/arbiter/arb_rr.sv
read_verilog -sv ../../../rtl/verilog/pkg/functions/optimsoc_functions.sv
read_verilog -sv ../../../rtl/verilog/pkg/config/optimsoc_config.sv
read_verilog -sv ../../../rtl/verilog/pkg/constants/optimsoc_constants.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interfaces/riscv/mriscv_trace_exec.sv
read_verilog -sv ../../../bench/verilog/glip/glip_channel.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interfaces/common/dii_channel_flat.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interfaces/common/dii_channel.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/debug_interface.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/blocks/buffer/dii_buffer.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/blocks/buffer/osd_fifo.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/ctm/common/osd_ctm.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/ctm/riscv/mriscv/osd_ctm_mriscv.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/blocks/eventpacket/osd_event_packetization_fixedwidth.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/him/osd_him.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/mam/ahb3/mam_ahb3_adapter.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/mam/ahb3/osd_mam_ahb3_if.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/mam/ahb3/osd_mam_ahb3.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/mam/common/osd_mam.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/blocks/eventpacket/osd_event_packetization.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/blocks/regaccess/osd_regaccess_demux.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/blocks/regaccess/osd_regaccess_layer.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/blocks/regaccess/osd_regaccess.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/blocks/tracesample/osd_tracesample.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/scm/osd_scm.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/stm/common/osd_stm.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/stm/riscv/mriscv/osd_stm_mriscv.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/blocks/timestamp/osd_timestamp.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/dem_uart/osd_dem_uart.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/dem_uart/osd_dem_uart_16550.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/modules/dem_uart/osd_dem_uart_ahb3.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interconnect/debug_ring_expand.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interconnect/debug_ring.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interconnect/ring_router_demux.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interconnect/ring_router_gateway_demux.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interconnect/ring_router_gateway_mux.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interconnect/ring_router_gateway.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interconnect/ring_router_mux_rr.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interconnect/ring_router_mux.sv
read_verilog -sv ../../../soc/dbg/rtl/verilog/soc/interconnect/ring_router.sv
read_verilog -sv ../../../soc/dma/rtl/verilog/ahb3/core/mpsoc_dma_initiator_nocreq.sv
read_verilog -sv ../../../soc/dma/rtl/verilog/ahb3/core/mpsoc_dma_packet_buffer.sv
read_verilog -sv ../../../soc/dma/rtl/verilog/ahb3/core/mpsoc_dma_request_table.sv
read_verilog -sv ../../../soc/dma/rtl/verilog/ahb3/ahb3/mpsoc_dma_ahb3_initiator.sv
read_verilog -sv ../../../soc/dma/rtl/verilog/ahb3/ahb3/mpsoc_dma_ahb3_initiator_nocres.sv
read_verilog -sv ../../../soc/dma/rtl/verilog/ahb3/ahb3/mpsoc_dma_ahb3_initiator_req.sv
read_verilog -sv ../../../soc/dma/rtl/verilog/ahb3/ahb3/mpsoc_dma_ahb3_interface.sv
read_verilog -sv ../../../soc/dma/rtl/verilog/ahb3/ahb3/mpsoc_dma_ahb3_target.sv
read_verilog -sv ../../../soc/dma/rtl/verilog/ahb3/ahb3/mpsoc_dma_ahb3_top.sv
read_verilog -sv ../../../soc/mpi/rtl/verilog/ahb3/core/mpi_buffer.sv
read_verilog -sv ../../../soc/mpi/rtl/verilog/ahb3/core/mpi_buffer_endpoint.sv
read_verilog -sv ../../../soc/mpi/rtl/verilog/ahb3/ahb3/mpi_ahb3.sv
read_verilog -sv ../../../rtl/verilog/mpsoc/riscv_mpsoc2d.sv
read_verilog -sv ../../../soc/noc/rtl/verilog/core/noc_buffer.sv
read_verilog -sv ../../../soc/noc/rtl/verilog/core/noc_demux.sv
read_verilog -sv ../../../soc/noc/rtl/verilog/core/noc_mux.sv
read_verilog -sv ../../../soc/noc/rtl/verilog/core/noc_vchannel_mux.sv
read_verilog -sv ../../../soc/noc/rtl/verilog/router/noc_router.sv
read_verilog -sv ../../../soc/noc/rtl/verilog/router/noc_router_input.sv
read_verilog -sv ../../../soc/noc/rtl/verilog/router/noc_router_lookup.sv
read_verilog -sv ../../../soc/noc/rtl/verilog/router/noc_router_lookup_slice.sv
read_verilog -sv ../../../soc/noc/rtl/verilog/router/noc_router_output.sv
read_verilog -sv ../../../soc/noc/rtl/verilog/topology/noc_mesh2d.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/cache/riscv_dcache_core.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/cache/riscv_dext.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/cache/riscv_icache_core.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/cache/riscv_noicache_core.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/decode/riscv_id.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/execute/riscv_alu.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/execute/riscv_bu.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/execute/riscv_div.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/execute/riscv_execution.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/execute/riscv_lsu.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/execute/riscv_mul.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/fetch/riscv_if.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/memory/riscv_dmem_ctrl.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/memory/riscv_imem_ctrl.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/memory/riscv_membuf.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/memory/riscv_memmisaligned.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/memory/riscv_mmu.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/memory/riscv_mux.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/memory/riscv_pmachk.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/memory/riscv_pmpchk.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/riscv_bp.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/riscv_core.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/riscv_du.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/riscv_memory.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/riscv_rf.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/riscv_state.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/core/riscv_wb.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/memory/riscv_ram_1r1w_generic.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/memory/riscv_ram_1r1w.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/memory/riscv_ram_1rw_generic.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/memory/riscv_ram_1rw.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/memory/riscv_ram_queue.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/pu/riscv_biu2ahb3.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/pu/riscv_module_ahb3.sv
read_verilog -sv ../../../soc/pu/rtl/verilog/pu/riscv_pu_ahb3.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/adapter/networkadapter_conf.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/adapter/networkadapter_ct.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/bootrom/bootrom.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/interconnection/bus/ahb3_bus_b3.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/interconnection/decode/ahb3_decode.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/interconnection/mux/ahb3_mux.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/spram/sram_sp_impl_plain.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/spram/sram_sp.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/spram/ahb3_sram_sp.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/spram/ahb32sram.sv
read_verilog -sv ../../../soc/rtl/verilog/soc/riscv_tile.sv
read_verilog -sv ../../../soc/spram/rtl/verilog/ahb3/core/mpsoc_ahb3_spram.sv
read_verilog -sv ../../../soc/spram/rtl/verilog/ahb3/core/mpsoc_ram_1r1w.sv
read_verilog -sv ../../../soc/spram/rtl/verilog/ahb3/core/mpsoc_ram_1r1w_generic.sv

read_verilog -sv riscv_mpsoc2d_wrapper.sv

read_xdc system_2d.xdc

synth_design -part xc7z020-clg484-1 \
-include_dirs ../../../soc/pu/rtl/verilog/pkg \
-include_dirs ../../../soc/rtl/verilog/soc/bootrom \
-include_dirs ../../../bench/cpp/verilator/inc \
-include_dirs ../../../bench/cpp/glip \
-include_dirs ../../../soc/dma/rtl/verilog/ahb3/pkg \
-include_dirs ../../../soc/spram/rtl/verilog/ahb3/pkg \
-top riscv_mpsoc2d_wrapper

opt_design
place_design
route_design

report_utilization
report_timing

write_verilog -force system_2d.v
write_bitstream -force system_2d.bit
