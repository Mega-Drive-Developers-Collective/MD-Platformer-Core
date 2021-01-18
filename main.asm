; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2020/12
;
;   Main include file & ROM header
;
; Note: When writing code, leave a6 free for VDP control port
; --------------------------------------------------------------

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

		include "code/main.mac"				; include main assembler macros
		include "code/equates.mac"			; include equates
		include "code/math.mac"				; include math macros
		include "code/objects/main.mac"			; include object macros
		include "code/hardware/VDP.mac"			; include VDP macros
		include "code/hardware/Z80.mac"			; include Z80 macros
		include "code/hardware/PAD.mac"			; include PAD macros
		include "code/hardware/misc.mac"		; include miscellaneous macros
		include "code/VRAM.mac"				; include VRAM macros
		include "code/exceptions/Debugger.asm"		; include exception handler macros

Main		SECTION org(0)					; create main section
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
		dc.l Hint,   exMisc, Vint,   exMisc
		dc.l Trap0,  Trap1,  Trap2,  Trap3
		dc.l Trap4,  Trap5,  Trap6,  Trap7
		dc.l Trap8,  Trap9,  TrapA,  TrapB
		dc.l TrapC,  TrapD,  TrapE,  TrapF

hInitAregs:							; address registers for init routine
hZ80_Bus:	dc.l Z80_Bus				; a1	; Z80 bus request
hZ80_Reset:	dc.l Z80_Reset				; a2	; Z80 reset
hZ80_RAM:	dc.l Z80_RAM				; a3	; Z80 RAM start
hPAD_Control1:	dc.l PAD_Control1			; a4	; PAD 1 control
hVDP_Data:	dc.l VDP_Data				; a5	; VDP data port
hVDP_Control:	dc.l VDP_Control			; a6	; VDP control port

		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc, exMisc, exMisc, exMisc
		dc.l exMisc
hPAD_Data1:	dc.l PAD_Data1					; PAD 1 data

		dc.b 'SEGA MEGA DRIVE '
		dc.b '(C)MDDC 2020.DEC'
		dc.b 'MDDC ENGINE TEST                                '
		dc.b 'MDDC ENGINE TEST                                '
		dc.b 'FNGIN-0000AB00'
		dc.w 0
		dc.b 'J               '
		dc.l 0
EndOfROM:	dc.l -1						; filled automatically by fixheader
hStartOfRAM:	dc.l $FF0000, $FFFFFF
		dc.l $20202020, $20202020, $20202020
Checksum:	dc.l 0						; checksum final result
CheckInit:	dc.l 0						; checksum init value
		dc.b '                                            '
		dc.b 'JUE             '
; ==============================================================
; --------------------------------------------------------------
; Library fast functions
; --------------------------------------------------------------

		include "code/objects/fast.asm"			; include object fast routines
; ==============================================================
; --------------------------------------------------------------
; Library functions
; --------------------------------------------------------------

		include "code/objects/animate.asm"		; include animation routines
		include "code/objects/alloc.asm"		; include alloc routines
		include "code/objects/misc.asm"			; include misc object routines
		include "code/objects/render.asm"		; include object rendering routines
		include "code/SRAM.asm"				; include SRAM routines
; ==============================================================
; --------------------------------------------------------------
; Game functions
; --------------------------------------------------------------

		include "code/init.asm"				; include init routine
		include "code/vint.asm"				; include V-int routines
		include "code/hardware/PAD.asm"			; include PAD routines
; ==============================================================
; --------------------------------------------------------------
; Test screen mode
; --------------------------------------------------------------

		include "screens/test/main.asm"			; include test screen main code
; ==============================================================
; --------------------------------------------------------------
; Exception library
; --------------------------------------------------------------

		include "code/objects/debug.asm"		; include object debugging routines
		include "code/exceptions/ErrorHandler.asm"	; include exception handler code
		END
