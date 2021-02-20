@echo off
call ../../../../settings64_msim.bat

vlib work
vlog -sv -f mpsoc2d.vc
vsim -c -do run.do work.mpsoc3d_riscv_testbench
pause
