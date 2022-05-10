@echo off

:clean
rm *.obj
rm *.lst
rm *.crf
rm *.map

:build
masm m24clk.asm,m24clk.obj,m24clk.lst,m24clk.crf
link m24clk.obj,m24clk.exe,m24clk.map;
exe2bin m24clk.exe m24clk.sys
rm m24clk.exe
