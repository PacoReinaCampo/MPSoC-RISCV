@echo off
call ../../../../settings64_vivado.bat

xvlog -prj mpsoc2d.prj^
-i ../../../../soc/pu/rtl/verilog/pkg^
-i ../../../../soc/rtl/verilog/soc/bootrom^
-i ../../../../soc/dma/rtl/verilog/wb/pkg
xelab mpsoc2d_riscv_testbench
xsim -R mpsoc2d_riscv_testbench
pause
