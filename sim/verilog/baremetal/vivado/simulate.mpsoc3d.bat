@echo off
call ../../../../settings64_vivado.bat

xvlog -prj mpsoc3d.prj^
-i ../../../../soc/pu/rtl/verilog/pkg^
-i ../../../../soc/rtl/verilog/soc/bootrom^
-i ../../../../soc/dma/rtl/verilog/wb/pkg
xelab mpsoc3d_riscv_testbench
xsim -R mpsoc3d_riscv_testbench
pause
