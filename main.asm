; ==============================================================
; --------------------------------------------------------------
; Macros and equates
; --------------------------------------------------------------

		opt ae+						; set automatic even's to on
		opt w-						; disable warnings
		opt l.						; local lable symbol is . (dot)
		opt v+						; output local labels in .sym file
		opt ws+						; allow white spaces in operand parsing
		opt ow+						; optimize word addressing
		opt op+						; optimize pc relative addressing
		opt os+						; optimize short branches
		opt oz+						; optimize zero displacement
; --------------------------------------------------------------

		include "code/equates.asm"			; include equates
		include "library/objects/macro.asm"		; include object macros
		include "code/exceptions/Debugger.asm"		; include exception handler macros
; ==============================================================
; --------------------------------------------------------------
; ROM header
; --------------------------------------------------------------
Header		SECTION org(0), word				; create header section
		dc.l 0,      Init,   exBus,  exAddr
		dc.l exIll,  exDiv,  exChk,  Trapv
		dc.l exPriv, exTrace,exLineA,exLineF
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l Hint,   exMisc, Vint,   exMisc
		dc.l Trap0,  Trap1,  Trap2,  Trap3
		dc.l Trap4,  Trap5,  Trap6,  Trap7
		dc.l Trap8,  Trap9,  TrapA,  TrapB
		dc.l TrapC,  TrapD,  TrapE,  TrapF

hVDP_Data:	dc.l $C00000
hVDP_Control:	dc.l $C00004
hZ80_Bus:	dc.l $A11100
hZ80_Reset:	dc.l $A11200
hPAD_Data1:	dc.l $A10003
hPAD_Data2:	dc.l $A10005
		dc.l exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc

		dc.b 'SEGA MEGA DRIVE '
		dc.b '(C)MDDC 2020.DEC'
		dc.b 'MDDC ENGINE TEST                                '
		dc.b 'MDDC ENGINE TEST                                '
		dc.b 'FNGIN-0000AB00'
		dc.w 0
		dc.b 'J               '
		dc.l 0
EndOfROM:	dc.l -1						; filled automatically by fixheader
		dc.l $FF0000, $FFFFFF
		dc.l $20202020, $20202020, $20202020
Checksum:	dc.l 0						; checksum final result
CheckInit:	dc.l 0						; checksum init value
		dc.b '                                            '
		dc.b 'JUE             '
; ==============================================================
; --------------------------------------------------------------
; Library fast functions
; --------------------------------------------------------------

Fast		SECTION org($200), size($7E00), word		; create $200-$8000 word section
		include "library/objects/fast.asm"		; include object fast routines
; ==============================================================
; --------------------------------------------------------------
; Library functions
; --------------------------------------------------------------

Library		SECTION						; create library section
		include "library/objects/alloc.asm"		; include alloc routines
		include "library/SRAM.asm"			; include SRAM routines
; ==============================================================
; --------------------------------------------------------------
; Game functions
; --------------------------------------------------------------

Main		SECTION						; create main section
		include "code/init.asm"				; include init routine


Vint_Main:
		rte

; ==============================================================
; --------------------------------------------------------------
; Exception library
; --------------------------------------------------------------

Error		SECTION						; create error section
		include "code/exceptions/ErrorHandler.asm"	; include exception handler code
		END
