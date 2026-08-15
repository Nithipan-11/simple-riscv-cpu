@echo off
cd /d C:\Users\Nithi\simple_riscv
"C:\iverilog\bin\iverilog.exe" -g2012 -o sim tb_cpu.v cpu.v control.v alu.v regfile.v imem.v dmem.v
"C:\iverilog\bin\vvp.exe" sim
