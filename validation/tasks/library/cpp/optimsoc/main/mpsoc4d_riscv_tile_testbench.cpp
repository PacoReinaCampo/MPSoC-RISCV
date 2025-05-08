#include "Vmpsoc4d_riscv_tile_testbench__Syms.h"
#include "Vmpsoc4d_riscv_tile_testbench__Dpi.h"

#include <VerilatedToplevel.h>
#include <VerilatedControl.h>

#include <ctime>
#include <cstdlib>

using namespace simutilVerilator;

VERILATED_TOPLEVEL(mpsoc4d_riscv_tile_testbench, clk, rst)

int main(int argc, char *argv[])
{
    mpsoc4d_riscv_tile_testbench ct("TOP");

    VerilatedControl &simctrl = VerilatedControl::instance();
    simctrl.init(ct, argc, argv);

    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[0].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[1].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[2].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[3].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[4].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[5].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[6].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[7].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[8].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[9].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[10].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[11].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[12].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[13].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[14].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.addMemory("TOP.mpsoc4d_riscv_tile_testbench.u_system.gen_ct[15].u_ct.gen_sram.u_ram.sp_ram.gen_soc_sram_sp_impl.u_impl");
    simctrl.setMemoryFuncs(do_readmemh, do_readmemh_file);
    simctrl.run();

    return 0;
}
