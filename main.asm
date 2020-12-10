; ==============================================================
; --------------------------------------------------------------
; Macros and equates
; --------------------------------------------------------------

		opt ae+						; set automatic even's to on
		opt w-						; disable warnings
		opt l.						; local lable symbol is . (dot)
		include "code/equates.asm"			; include equates
; ==============================================================
; --------------------------------------------------------------
; ROM header
; --------------------------------------------------------------

		dc.l Stack, EntryPoint, exBus, exAddress
		dc.l exIllegal, exZeroDivide, exChk, Trapv
		dc.l exPrivilege, exTrace, exLineA, exLineF
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l Vint, exMisc, Hint, exMisc
		dc.l Trap0, Trap1, Trap2, Trap3
		dc.l Trap4, Trap5, Trap6, Trap7
		dc.l Trap8, Trap9, TrapA, TrapB
		dc.l TrapC, TrapD, TrapE, TrapF
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc

		dc.b 'SEGA MEGA DRIVE '
		dc.b '(C)MDDC 2020.DEC'
		dc.b 'MDDC ENGINE TEST                                '
		dc.b 'MDDC ENGINE TEST                                '
		dc.b 'FNGIN-0000'
Checksum:	dc.w 0, 0, 0
		dc.b 'J               '
		dc.l 0, EndOfROM-1
		dc.l $FF0000, $FFFFFF
		dc.l $20202020, $20202020, $20202020
		dc.b '                                                    '
		dc.b 'JUE             '
; ==============================================================
; --------------------------------------------------------------
; library functions
; --------------------------------------------------------------

		include "library/objects.asm"			; include object equates
		include "library/SRAM.asm"			; include SRAM routines







EntryPoint:
Vint:
Hint:

Trap0:
Trap1:
Trap2:
Trap3:
Trap4:
Trap5:
Trap6:
Trap7:
Trap8:
Trap9:
TrapA:
TrapB:
TrapC:
TrapD:
TrapE:
TrapF:
Trapv:
exBus:
exAddress:
exIllegal:
exZeroDivide:
exChk:
exPrivilege:
exTrace:
exLineA:
exLineF:
exMisc:


EndOfROM:
	END
