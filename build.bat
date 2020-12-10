@echo off
"tools/asm68k.exe" /m /p main.asm, _out.md, , _out.lst>_out.log
type _out.log
if not exist _out.md pause & exit
"tools/fixheadr.exe" s1built.md
del _out.log
