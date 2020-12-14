@echo off
"tools/asm68k.exe" /m /p main.asm, _out.md, _out.sym, _out.lst>_out.log
type _out.log
if not exist _out.md pause & exit
"tools/fixheadr.exe" s1built.md
"code/exceptions/ConvSym.exe" _out.sym _out.md -input asm68k_sym -a
del _out.log
del _out.sym
