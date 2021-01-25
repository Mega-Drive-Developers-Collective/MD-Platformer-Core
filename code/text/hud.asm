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

		move.l	d1,(a6)					; send the VDP command
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
;   a2 = input string pointer, terminated with 0
;   a3 = custom routine pointer
;   a4 = relative address pointer
;
; thrash: d0-d5/a2/a4
; --------------------------------------------------------------

hudPrint:
		bsr.s	vdpVramToCommand			; convert d1 from VRAM address to command
		add.w	#vFont/32,d0				; reset the tile offset
		move.w	sr,-(sp)				; store sr in stack
		move	#$2700,sr				; disable ints

		move.l	d1,(a6)					; send the VDP command
		swap	d1					; swap bits out
		bra.s	.text
; --------------------------------------------------------------

.command
		jsr	hudPrintCommands-$80(pc,d3.w)		; run this command then
		bra.s	.text
; --------------------------------------------------------------

.char
		add.w	d0,d3					; add the defined offset to character
		move.w	d3,-4(a6)				; write to the VDP command port
		addq.w	#2,d1					; go to the next tile

.text
		moveq	#0,d3					; clear d3
		move.b	(a2)+,d3				; load the next byte into d3
		bgt.s	.char					; branch if postive; this is a character
		bmi.s	.command				; branch if negative; is a command

		move.w	(sp)+,sr				; return the sr from stack
		rts
; ==============================================================
; --------------------------------------------------------------
; Hud print run code command
; --------------------------------------------------------------

hudPrintCode:
		move.b	(a2)+,d3				; load the argument
		jmp	(a3)					; run the custom routine
; ==============================================================
; --------------------------------------------------------------
; Hud print add offset to write position command
; --------------------------------------------------------------

hudPrintOffset:
		move.b	(a2)+,d3				; load the offset
		ext.w	d3					; extend to word
		add.w	d3,d1					; add offset to the position

		swap	d1					; swap bits in
		move.l	d1,(a6)					; send the VDP command
		swap	d1					; swap bits out
		rts
; ==============================================================
; --------------------------------------------------------------
; Hud print go to next line command
; --------------------------------------------------------------

hudPrintNextLine:
		moveq	#$7F,d3					; prepare a mask to d3
		and.w	d1,d3					; AND with the line position
		sub.w	d3,d1					; subtract the current line position from address
		add.w	#$80,d1					; go to the next line

		swap	d1					; swap bits in
		move.l	d1,(a6)					; send the VDP command
		swap	d1					; swap bits out
		rts
; ==============================================================
; --------------------------------------------------------------
; Hud print set tile low byte command
; --------------------------------------------------------------

hudPrintTileLow:
		move.b	(a2)+,d0				; load the tile byte directly
		rts
; ==============================================================
; --------------------------------------------------------------
; Hud print set tile high byte command
; --------------------------------------------------------------

hudPrintTileHigh:
		move.b	(a2)+,d3				; load the tile byte into d3
		lsl.l	#8,d3					; we can do this faster but I'm lazy atm
		move.b	d0,d3					; copy the tile low byte to d3
		move.w	d3,d0					; copy the full tile back
		rts
; ==============================================================
; --------------------------------------------------------------
; Hud print fill line with tile command
; --------------------------------------------------------------

hudPrintFill:
		moveq	#$7E,d3					; prepare a mask to d3
		and.w	d1,d3					; AND with the line position
		beq.s	.ret					; branch if 0, nothing needs filling

		lsr.w	#1,d3					; halve the length
		subq.w	#1,d3					; account for dbf

.fill
		move.w	d0,-4(a6)				; write to the VDP command port
		addq.w	#2,d1					; go to the next tile
		dbf	d3,.fill				; loop until done

.ret
		rts
; ==============================================================
; --------------------------------------------------------------
; Hud print set pointer command
; --------------------------------------------------------------

hudPrintSetPtr:
		move.b	(a2)+,d3				; load high byte to d3
		lsl.l	#8,d3					; we can do this faster but I'm lazy atm
		move.b	(a2)+,d3				; load low byte to d3
		move.w	d3,a4					; save it to relative pointer
		rts
; --------------------------------------------------------------

hudPrintCommands:
		bra.s	hudPrintHexByte			; $80	; write a hex byte from pointer
		bra.s	hudPrintHexWord			; $82	; write a hex word from pointer
		bra.s	hudPrintHexLong			; $84	; write a hex long from pointer
		bra.s	hudPrintTileHigh		; $86	; set the high byte of tile offset register

		bra.s	hudPrintDecByte			; $89	; write a dec byte from pointer
		bra.s	hudPrintDecWord			; $8A	; write a dec word from pointer
		bra.s	hudPrintDecLong			; $8C	; write a dec long from pointer
		bra.s	hudPrintTileLow			; $8E	; set the low byte of tile offset register

		bra.s	hudPrintNextLine		; $90	; go to the next line in the plane
		bra.s	hudPrintOffset			; $92	; offset the current pointer
		bra.s	hudPrintCode			; $94	; run supplied code
		bra.s	hudPrintFill			; $96	; fill rest of the line with blank
		bra.s	hudPrintSetPtr			; $98	; set the relative pointer
		bra.w	hudPrintReadPtrWord		; $9A	; read the relative word pointer
		bra.w	hudPrintReadPtrLong		; $9E	; read the relative long pointer
; ==============================================================
; --------------------------------------------------------------
; Hud print write hex byte command
; --------------------------------------------------------------

hudPrintHexByte:
		move.b	(a2)+,d3				; load the offset to d3
		ext.w	d3					; extend to a word
		move.b	(a4,d3.w),d3				; load the byte into d3

		ror.l	#8,d3					; shift bits away as a preparation
		moveq	#2-1,d4					; print 2 nibbles
		bra.s	hudPrintHex				; print this hex number
; ==============================================================
; --------------------------------------------------------------
; Hud print write hex byte command
; --------------------------------------------------------------

hudPrintHexWord:
		move.b	(a2)+,d3				; load the offset to d3
		ext.w	d3					; extend to a word
		move.w	(a4,d3.w),d3				; load the word into d3

		swap	d3					; swap the words as preparation
		moveq	#4-1,d4					; print 4 nibbles
; ==============================================================
; --------------------------------------------------------------
; Hud print hex number subroutine
; --------------------------------------------------------------

hudPrintHex:
		rol.l	#4,d3					; shift the next nibble into d3
		moveq	#$F,d5					; prepare mask to d5
		and.w	d3,d5					; AND with the current nibble data

		move.b	.table(pc,d5.w),d5			; load the ascii value representation
		add.w	d0,d5					; add tile offset to d5
		move.w	d5,-4(a6)				; write into VDP

		addq.w	#2,d1					; go to the next tile
		dbf	d4,hudPrintHex				; continue looping for all nibbles
		rts

.table		dc.b "0123456789ABCDEF"				; number to ascii conversion table
; ==============================================================
; --------------------------------------------------------------
; Hud print write hex byte command
; --------------------------------------------------------------

hudPrintHexLong:
		move.b	(a2)+,d3				; load the offset to d3
		ext.w	d3					; extend to a word
		move.l	(a4,d3.w),d3				; load the longword into d3

		moveq	#8-1,d4					; print 8 nibbles
		bra.s	hudPrintHex				; print this hex number
; ==============================================================
; --------------------------------------------------------------
; Hud print write dec byte command
; --------------------------------------------------------------

hudPrintDecByte:
		move.b	(a2)+,d3				; load the offset to d3
		ext.w	d3					; extend to a word
		move.b	(a4,d3.w),d3				; load the byte into d3
		bra.s	hudPrintDec				; print this dec number
; ==============================================================
; --------------------------------------------------------------
; Hud print write dec word command
; --------------------------------------------------------------

hudPrintDecWord:
		move.b	(a2)+,d3				; load the offset to d3
		ext.w	d3					; extend to a word
		move.w	(a4,d3.w),d3				; load the word into d3
		bra.s	hudPrintDec				; print this dec number
; ==============================================================
; --------------------------------------------------------------
; Hud print write dec long command
; --------------------------------------------------------------

hudPrintDecLong:
		move.b	(a2)+,d3				; load the offset to d3
		ext.w	d3					; extend to a word
		move.l	(a4,d3.w),d3				; load the longword into d3
; ==============================================================
; --------------------------------------------------------------
; Hud print dec number subroutine
; --------------------------------------------------------------

hudPrintDec:
		lea	.digs(pc),a4				; load digits table to a4
		moveq	#10-1,d4				; load the digit counter
		moveq	#-1,d5					; reset counter
; --------------------------------------------------------------

.digits
		addq.w	#1,d5					; increase digit count
		sub.l	(a4),d3					; decrement digit count
		bcc.s	.digits					; branch if did not underflow
		add.l	(a4)+,d3				; fix the digit count

		tst.l	d4					; check if a digit was already processed
		bmi.s	.draw					; branch if yes
		tst.w	d5					; check if this digit is 0
		beq.s	.skip					; branch if yes
		bset	#31,d4					; set digit as drawn

.draw
		move.b	.table(pc,d5.w),d5			; load the ascii value representation
		add.w	d0,d5					; add tile offset to d5
		move.w	d5,-4(a6)				; write into VDP

.skip
		moveq	#-1,d5					; reset counter
		dbf	d4,.digits				; continue looping for all digits
; --------------------------------------------------------------

		tst.l	d4					; check if any digit was processed
		bmi.s	.ret					; branch if yes
		clr.w	d5					; clear d5 because oops

		move.b	.table(pc),d5				; load the ascii value representation for 0
		add.w	d0,d5					; add tile offset to d5
		move.w	d5,-4(a6)				; write into VDP

.ret
		rts
; --------------------------------------------------------------

.table		dc.b "0123456789"				; number to ascii conversion table

.digs		dc.l 1000000000, 100000000, 10000000, 1000000
		dc.l 100000, 10000, 1000, 100, 10, 1
; ==============================================================
; --------------------------------------------------------------
; Hud print read pointer command
; --------------------------------------------------------------

hudPrintReadPtrLong:
		move.b	(a2)+,d3				; load the offset to d3
		ext.w	d3					; extend to a word
		move.l	(a4,d3.w),a4				; read the pointer from a4 into a4 again
		rts

hudPrintReadPtrWord:
		move.b	(a2)+,d3				; load the offset to d3
		ext.w	d3					; extend to a word
		move.w	(a4,d3.w),a4				; read the pointer from a4 into a4 again
		rts
; --------------------------------------------------------------
