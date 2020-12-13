@echo off
"..\..\..\tools\asm68k" /k /m /o l. /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- ErrorHandler.asm, ErrorHandler.bin, , ErrorHandler.lst
"..\convsym" ErrorHandler.lst "ErrorHandler.Global.ASM68K.asm" -input asm68k_lst -inopt "/processLocals-" -output asm -outopt "ErrorHandler.%%s equ ErrorHandler+$%%X" -filter "__global_.+"
"..\convsym" ErrorHandler.lst "ErrorHandler.Global.AS.asm" -input asm68k_lst -inopt "/processLocals-" -output asm -outopt "ErrorHandler_%%s: label ErrorHandler+$%%X" -filter "__global_.+"
pause
