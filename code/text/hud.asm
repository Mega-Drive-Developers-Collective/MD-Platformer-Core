; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2021/01
;
;   HUD and text rendering routines
; --------------------------------------------------------------

	rsset $80
txptrwbh		rs.w 1				; $80	; command to use a word pointer to write hex byte data on screen
txptrwwh		rs.w 1				; $82	; command to use a word pointer to write hex word data on screen
txptrwlh		rs.w 1				; $84	; command to use a word pointer to write hex long data on screen
txtileh			rs.w 1				; $86	; command to set the high byte of the tile

txptrwbd		rs.w 1				; $88	; command to use a word pointer to write dec byte data on screen
txptrwwd		rs.w 1				; $8A	; command to use a word pointer to write dec word data on screen
txptrwld		rs.w 1				; $8C	; command to use a word pointer to write dec long data on screen
txtilel			rs.w 1				; $8E	; command to set the low byte of the tile

txline			rs.w 1				; $90	; go to the next line
txadd			rs.w 1				; $92	; add the next byte amount to VRAM destination
txcode			rs.w 1				; $94	; run code pointer provided by the caller. An extra byte is provided as an argument
txfill			rs.w 1				; $96	; fills the rest of the line with tile offset
txsetptr		rs.w 1				; $98	; set relative address pointer in a4
txreadptrw		rs.l 1				; $9A	; read relative word pointer from a4
txreadptrl		rs.l 1				; $9E	; read relative long pointer from a4
; ==============================================================
; --------------------------------------------------------------
; Macro for setting relative pointers
; --------------------------------------------------------------

hudSetPtr		macro ptr
		dc.b txsetptr					; this is the command to use
		dc.b ((\ptr)>>8)&$FF, (\ptr)&$FF		; this is the pointer to use
	endm
; ==============================================================
; --------------------------------------------------------------
; Routine to write a string mappings onto VRAM without processing
;
; in:
;   d0 = base VRAM tile
;   d1 = VRAM destination address
;   a2 = input string pointer, terminated with 0
;
; thrash: d0-d5/a2/a4
; --------------------------------------------------------------

hudPrintSimple:
		bsr.s	vdpVramToCommand			; convert d1 from VRAM address to command
		add.w	#vFont/32,d0				; reset the tile offset

		move.w	sr,-(sp)				; store sr in stack
		move	#$2700,sr				; disable ints
		bra.s	.text
; --------------------------------------------------------------

.char
		add.w	d0,d3					; add the defined offset to character
		move.w	d3,-4(a6)				; write to the VDP command port

.text
		moveq	#0,d3					; clear d3
		move.b	(a2)+,d3				; load the next byte into d3
		bne.s	.char					; branch if not 0; this is a character

		move.w	(sp)+,sr				; return the sr from stack
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to convert VRAM address to VDP WRITE command
;
; in:
;   d1 = VRAM destination address
;
; out:
;   d1 = VDP command
;
; thrash: d0-d5/a2/a4
; --------------------------------------------------------------

vdpVramToCommand:
		swap	d1					; swap words
		clr.w	d1					; clear the lower word
		swap	d1					; swap words again
		rol.l	#2,d1					; rotate 2 bits into the next word

		addq.w	#1,d1					; when shifted into place, this actually adds $4000 to the result
		ror.w	#2,d1					; shift rest of VRAM bits into place
		swap	d1					; swap bits again
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to write a string mappings onto VRAM
;
; in:
;   d0 = base VRAM tile
;   d1 = VRAM destination address
;   a4 = rendering code
;
; thrash: d0-d5/a2/a4
; --------------------------------------------------------------

hudPrint:
		move.w	sr,-(sp)				; store sr in stack
		move	#$2700,sr				; disable ints

		move.l	hVDP_Control.w,a5			; load VDP control port to a5
		lea	-4(a5),a6				; load VDP data port to a6

		lea	-$E(sp),sp				; reserve some space in stack
		move.l	sp,a3					; a3 = console RAM
		move.l	a3,usp					; store in USP too

		bsr.s	vdpVramToCommand			; convert VRAM address to VDP command
		move.l	d1,(a3)+				; copy the VRAM command to RAM
		move.l	#(40<<16) | 40,(a3)+			; copy line widths to RAM

		add.w	#vFont / 32,d0				; set the font base address
		swap	d0					; swap words
		move.w	#$80,d0					; set the line size in bytes in d0
		move.l	d0,(a3)+				; copy to memory
		move.w	#($5D<<8),(a3)+				; load magic word to RAM

		move.l	sp,a3					; a3 = console RAM
		move.l	d1,(a5)					; set VDP command
		jsr	(a4)					; run code

		lea	$E(sp),sp				; get the space back
		move.l	hVDP_Control.w,a6			; load VDP control port to a6
		move.w	(sp)+,sr				; return the sr from stack
		rts
; --------------------------------------------------------------
