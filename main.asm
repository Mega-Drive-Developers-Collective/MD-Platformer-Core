Main		SECTION org(0)
; ==============================================================
; --------------------------------------------------------------
; Macros and equates
; --------------------------------------------------------------

		opt ae+						; set automatic even's to on
		opt w-						; disable warnings
		opt l.						; local lable symbol is . (dot)
; --------------------------------------------------------------

		include "code/equates.asm"			; include equates
		include "library/objects/macro.asm"		; include object macros
		include "code/exceptions/Debugger.asm"		; include exception handler macros
; ==============================================================
; --------------------------------------------------------------
; ROM header
; --------------------------------------------------------------

		dc.l 0,      Init,   exBus,  exAddr
		dc.l exIll,  exDiv,  exChk,  Trapv
		dc.l exPriv, exTrace,exLineA,exLineF
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l Vint,   exMisc, Hint,   exMisc
		dc.l Trap0,  Trap1,  Trap2,  Trap3
		dc.l Trap4,  Trap5,  Trap6,  Trap7
		dc.l Trap8,  Trap9,  TrapA,  TrapB
		dc.l TrapC,  TrapD,  TrapE,  TrapF
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
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
EndOfROM:	dc.l -1					; filled automatically by fixheader
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

		include "library/objects/fast.asm"		; include object fast routines
; ==============================================================
; --------------------------------------------------------------
; Library functions
; --------------------------------------------------------------

		include "library/objects/alloc.asm"		; include alloc routines
		include "library/SRAM.asm"			; include SRAM routines
; ==============================================================
; --------------------------------------------------------------
; Game functions
; --------------------------------------------------------------

		include "code/init.asm"				; include init routine


Vint_Main:
		rte

; ==============================================================
; --------------------------------------------------------------
; Exception library
; --------------------------------------------------------------

		include "code/exceptions/ErrorHandler.asm"	; include exception handler code
		END
