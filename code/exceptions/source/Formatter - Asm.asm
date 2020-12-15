; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2020, AURORA FIELDS
; ---------------------------------------------------------------
; String formatters : Symbols
; ---------------------------------------------------------------
; INPUT:
;		d1		Value
;
; OUTPUT:
;		(a0)++	ASCII characters upon conversion
;
; WARNING!
;	1) Formatters can only use registers a3 / d0-d4
;	2) Formatters should decrement d7 after each symbol write,
;		return Carry flag from the last decrement;
;		stop if carry is set (means buffer is full)
; ---------------------------------------------------------------

d68k_Store			reg d5/d6/a0-a2/a4/a6		; stored registers for decoder
d68k_StoreSz =			4*7				; size of decoder stored registers
; ---------------------------------------------------------------

FormatAsm_Handlers:
		ext.l	d1				; $00	; handler for word
		bra.s	FormatAsm			; $02

		jmp	FormatAsm(pc)			; $04	; handler for longword

		ext.w	d1				; $08	; handler for byte
		ext.l	d1
; ---------------------------------------------------------------

FormatAsm:
		movem.l	d68k_Store,d68k_StoreRegs		; push variables into temporary storage
		move.l	d1,a1					; copy instruction address to a1
		lea	d68k_String,a0				; load destination address to a0
		jsr	Decode68k(pc)				; decode instruction

		move.l	a0,d4					; copy end pointer to d4
		movem.l	d68k_StoreRegs,d68k_Store		; pop variables from temporary storage
; ---------------------------------------------------------------

	; flush
		sub.w	#(d68k_String+2)&$FFFF,d4		; subtract the start position from end
		lea	d68k_String,a3				; load string data to a3
; ---------------------------------------------------------------

.copy
		tst.w	d7					; SPECIAL CASE
		bne.s	.not0					; branch if not special case
		cmp.b	#_setpat,(a3)				; check if the last byte of buffer is _setpat command
		bne.s	.not0					; branch if not

		addq.w	#1,d4					; add 1 to counter
		bra.s	.flush					; flush NOW
; ---------------------------------------------------------------

.not0
		move.b	(a3)+,(a0)+				; copy a byte into buffer
		dbf	d7,.loop				; check if buffer is full, but if not, branch

.flush
		jsr	(a4)					; run flush function
		bcs.s	.end					; do something if something

.loop
		dbf	d4,.copy				; run the next copy operation

.end
		rts
; ---------------------------------------------------------------
