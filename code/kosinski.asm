; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2021/01
;      Based on Flamewing's fast Kosinski moduled decompressor
;
;   Kosinski moduled processing routines
; --------------------------------------------------------------

_Kos_RunBitStream macro
	dbra	d2,.skip\@
	moveq	#7,d2					; Set repeat count to 8.
	move.b	d1,d0					; Use the remaining 8 bits.
	not.w	d3						; Have all 16 bits been used up?
	bne.s	.skip\@					; Branch if not.
	move.b	(a0)+,d0				; Get desc field low-byte.
	move.b	(a0)+,d1				; Get desc field hi-byte.
	if _Kos_UseLUT
	move.b	(a4,d0.w),d0			; Invert bit order...
	move.b	(a4,d1.w),d1			; ... for both bytes.
	endif
.skip\@
	endm

_Kos_ReadBit macro
	if _Kos_UseLUT
	add.b	d0,d0					; Get a bit from the bitstream.
	else
	lsr.b	#1,d0					; Get a bit from the bitstream.
	endif
	endm
; ===========================================================================
; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; ---------------------------------------------------------------------------
; Adds a Kosinski Moduled archive to the module queue
; Inputs:
; a1 = address of the archive
; d2 = destination in VRAM
; ---------------------------------------------------------------------------
Queue_Kos_Module:
	lea	(Kos_module_queue).w,a2
	tst.l	(a2)	; is the first slot free?
	beq.s	Process_Kos_Module_Queue_Init	; if it is, branch

.findFreeSlot:
	addq.w	#6,a2	; otherwise, check next slot
	tst.l	(a2)
	bne.s	.findFreeSlot

	move.l	a1,(a2)+	; store source address
	move.w	d2,(a2)+	; store destination VRAM address
	rts
; End of function Queue_Kos_Module
; ===========================================================================

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; ---------------------------------------------------------------------------
; Initializes processing of the first module on the queue
; ---------------------------------------------------------------------------
Process_Kos_Module_Queue_Init:
	move.w	(a1)+,d3				; get uncompressed size
	lsr.w	#1,d3
	move.w	d3,d0
	rol.w	#5,d0
	andi.w	#$1F,d0					; get number of complete modules
	move.b	d0,(Kos_modules_left).w
	andi.w	#$7FF,d3				; get size of last module in words
	bne.s	.gotleftover			; branch if it's non-zero
	subq.b	#1,(Kos_modules_left).w	; otherwise decrement the number of modules
	move.w	#$800,d3				; and take the size of the last module to be $800 words

.gotleftover:
	move.w	d3,(Kos_last_module_size).w
	move.w	d2,(Kos_module_destination).w
	move.l	a1,(Kos_module_queue).w
	addq.b	#1,(Kos_modules_left).w	; store total number of modules
	rts
; End of function Process_Kos_Module_Queue_Init
; ===========================================================================

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; ---------------------------------------------------------------------------
; Processes the first module on the queue
; ---------------------------------------------------------------------------
Process_Kos_Module_Queue:
	tst.b	(Kos_modules_left).w
	bne.s	.modulesLeft

.done:
	rts
; ---------------------------------------------------------------------------
.modulesLeft:
	bmi.s	.decompressionStarted
	cmpi.w	#4,(Kos_decomp_queue_count).w
	bcc.s	.done					; branch if the Kosinski decompression queue is full
	movea.l	(Kos_module_queue).w,a1
	lea	(Kos_decomp_buffer).w,a2
	bsr.w	Queue_Kos				; add current module to decompression queue
	ori.b	#$80,(Kos_modules_left).w	; and set bit to signify decompression in progress
	rts
; ---------------------------------------------------------------------------
.decompressionStarted:
	tst.w	(Kos_decomp_queue_count).w
	bne.s	.done					; branch if the decompression isn't complete

	; otherwise, DMA the decompressed data to VRAM
	andi.b	#$7F,(Kos_modules_left).w
	move.w	#$800,d3
	subq.b	#1,(Kos_modules_left).w
	bne.s	.skip	; branch if it isn't the last module
	move.w	(Kos_last_module_size).w,d3

.skip:
	move.w	(Kos_module_destination).w,d5
	move.w	d5,d0
	add.w	d3,d0
	add.w	d3,d0
	move.w	d0,(Kos_module_destination).w	; set new destination
	move.l	(Kos_module_queue).w,d0
	move.l	(Kos_decomp_queue).w,d1
	sub.l	d1,d0
	andi.l	#$F,d0
	add.l	d0,d1					; round to the nearest $10 boundary
	move.l	d1,(Kos_module_queue).w	; and set new source
	move.l	#Kos_decomp_buffer,d4
	jsr	dmaQueueAdd.w
	tst.b	(Kos_modules_left).w
	bne.s	.exit					; return if this wasn't the last module

	lea	(Kos_module_queue).w,a0
	lea	(Kos_module_queue+6).w,a1

	rept kosmqueueentries-1
	move.l	(a1)+,(a0)+	; otherwise, shift all entries up
	move.w	(a1)+,(a0)+
	endr

	moveq	#0,d0
	move.l	d0,(a0)+				; and mark the last slot as free
	move.w	d0,(a0)+
	move.l	(Kos_module_queue).w,d0
	beq.s	.exit					; return if the queue is now empty
	movea.l	d0,a1
	move.w	(Kos_module_destination).w,d2
	bra.w	Process_Kos_Module_Queue_Init

.exit:
	rts
; End of function Process_Kos_Module_Queue
; ===========================================================================

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; ---------------------------------------------------------------------------
; Adds Kosinski-compressed data to the decompression queue
; Inputs:
; a1 = compressed data address
; a2 = decompression destination in RAM
; ---------------------------------------------------------------------------
Queue_Kos:
	move.w	(Kos_decomp_queue_count).w,d0
	lsl.w	#3,d0
	lea	(Kos_decomp_queue).w,a3
	move.l	a1,(a3,d0.w)			; store source
	move.l	a2,4(a3,d0.w)			; store destination
	addq.w	#1,(Kos_decomp_queue_count).w
	rts
; End of function Queue_Kos
; ===========================================================================

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; ---------------------------------------------------------------------------
; Checks if V-int occured in the middle of Kosinski queue processing
; and stores the location from which processing is to resume if it did
; ---------------------------------------------------------------------------
Set_Kos_Bookmark:
	tst.w	(Kos_decomp_queue_count).w
	bpl.s	.done					; branch if a decompression wasn't in progress
	move.l	$3E(sp),d0				; check address V-int is supposed to rte to
	cmpi.l	#Process_Kos_Queue_Start,d0
	bcs.s	.done
	cmpi.l	#Process_Kos_Queue_End,d0
	bcc.s	.done
	move.l	$3E(sp),(Kos_decomp_bookmark).w
	move.l	#Backup_Kos_Registers,$3E(sp)	; force V-int to rte here instead if needed

.done:
	rts
; End of function Set_Kos_Bookmark
; ===========================================================================

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; ---------------------------------------------------------------------------
; Processes the first entry in the Kosinski decompression queue
; ---------------------------------------------------------------------------
Process_Kos_Queue:
	tst.w	(Kos_decomp_queue_count).w
	beq.w	Process_Kos_Queue_End
	bmi.w	Restore_Kos_Bookmark	; branch if a decompression was interrupted by V-int

Process_Kos_Queue_Start:
	ori.w	#$8000,(Kos_decomp_queue_count).w	; set sign bit to signify decompression in progress
	movea.l	(Kos_decomp_queue).w,a0
	movea.l	(Kos_decomp_destination).w,a1

	; what follows is identical to the normal Kosinski decompressor
	moveq	#(1<<_Kos_LoopUnroll)-1,d7
	if _Kos_UseLUT
	moveq	#0,d0
	moveq	#0,d1
	lea	KosDec_ByteMap(pc),a4		; Load LUT pointer.
	endif
	move.b	(a0)+,d0				; Get desc field low-byte.
	move.b	(a0)+,d1				; Get desc field hi-byte.
	if _Kos_UseLUT
	move.b	(a4,d0.w),d0			; Invert bit order...
	move.b	(a4,d1.w),d1			; ... for both bytes.
	endif
	moveq	#7,d2					; Set repeat count to 8.
	moveq	#0,d3					; d3 will be desc field switcher.
	bra.s	.FetchNewCode
; ---------------------------------------------------------------------------
.FetchCodeLoop:
	; Code 1 (Uncompressed byte).
	_Kos_RunBitStream
	move.b	(a0)+,(a1)+

.FetchNewCode:
	_Kos_ReadBit
	bcs.s	.FetchCodeLoop			; If code = 1, branch.

	; Codes 00 and 01.
	moveq	#-1,d5
	lea	(a1),a5
	_Kos_RunBitStream
	if _Kos_ExtremeUnrolling
	_Kos_ReadBit
	bcs.w	.Code_01

	; Code 00 (Dictionary ref. short).
	_Kos_RunBitStream
	_Kos_ReadBit
	bcs.s	.Copy45
	_Kos_RunBitStream
	_Kos_ReadBit
	bcs.s	.Copy3
	_Kos_RunBitStream
	move.b	(a0)+,d5				; d5 = displacement.
	adda.w	d5,a5
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	bra.s	.FetchNewCode
; ---------------------------------------------------------------------------
.Copy3:
	_Kos_RunBitStream
	move.b	(a0)+,d5				; d5 = displacement.
	adda.w	d5,a5
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	bra.w	.FetchNewCode
; ---------------------------------------------------------------------------
.Copy45:
	_Kos_RunBitStream
	_Kos_ReadBit
	bcs.s	.Copy5
	_Kos_RunBitStream
	move.b	(a0)+,d5				; d5 = displacement.
	adda.w	d5,a5
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	bra.w	.FetchNewCode
; ---------------------------------------------------------------------------
.Copy5:
	_Kos_RunBitStream
	move.b	(a0)+,d5				; d5 = displacement.
	adda.w	d5,a5
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	move.b	(a5)+,(a1)+
	bra.w	.FetchNewCode
; ---------------------------------------------------------------------------
	else
	moveq	#0,d4					; d4 will contain copy count.
	_Kos_ReadBit
	bcs.s	.Code_01

	; Code 00 (Dictionary ref. short).
	_Kos_RunBitStream
	_Kos_ReadBit
	addx.w	d4,d4
	_Kos_RunBitStream
	_Kos_ReadBit
	addx.w	d4,d4
	_Kos_RunBitStream
	move.b	(a0)+,d5				; d5 = displacement.

.StreamCopy:
	adda.w	d5,a5
	move.b	(a5)+,(a1)+				; Do 1 extra copy (to compensate +1 to copy counter).

.copy:
	move.b	(a5)+,(a1)+
	dbra	d4,.copy
	bra.w	.FetchNewCode
	endif
; ---------------------------------------------------------------------------
.Code_01:
	moveq	#0,d4					; d4 will contain copy count.
	; Code 01 (Dictionary ref. long / special).
	_Kos_RunBitStream
	move.b	(a0)+,d6				; d6 = %LLLLLLLL.
	move.b	(a0)+,d4				; d4 = %HHHHHCCC.
	move.b	d4,d5					; d5 = %11111111 HHHHHCCC.
	lsl.w	#5,d5					; d5 = %111HHHHH CCC00000.
	move.b	d6,d5					; d5 = %111HHHHH LLLLLLLL.
	if _Kos_LoopUnroll=3
	and.w	d7,d4					; d4 = %00000CCC.
	else
	andi.w	#7,d4
	endif
	bne.s	.StreamCopy				; if CCC=0, branch.

	; special mode (extended counter)
	move.b	(a0)+,d4				; Read cnt
	beq.s	.Quit					; If cnt=0, quit decompression.
	subq.b	#1,d4
	beq.w	.FetchNewCode			; If cnt=1, fetch a new code.

	adda.w	d5,a5
	move.b	(a5)+,(a1)+				; Do 1 extra copy (to compensate +1 to copy counter).
	move.w	d4,d6
	not.w	d6
	and.w	d7,d6
	add.w	d6,d6
	lsr.w	#_Kos_LoopUnroll,d4
	jmp	.largecopy(pc,d6.w)
; ---------------------------------------------------------------------------
.largecopy:
	rept (1<<_Kos_LoopUnroll)
	move.b	(a5)+,(a1)+
	endr
	dbra	d4,.largecopy
	bra.w	.FetchNewCode
; ---------------------------------------------------------------------------
	if _Kos_ExtremeUnrolling
.StreamCopy:
	adda.w	d5,a5
	move.b	(a5)+,(a1)+				; Do 1 extra copy (to compensate +1 to copy counter).
	if _Kos_LoopUnroll=3
	eor.w	d7,d4
	else
	eori.w	#7,d4
	endif
	add.w	d4,d4
	jmp	.mediumcopy(pc,d4.w)
; ---------------------------------------------------------------------------
.mediumcopy:
	rept 8
	move.b	(a5)+,(a1)+
	endr
	bra.w	.FetchNewCode
	endif
; ---------------------------------------------------------------------------
.Quit:
	move.l	a0,(Kos_decomp_queue).w
	move.l	a1,(Kos_decomp_destination).w
	andi.w	#$7FFF,(Kos_decomp_queue_count).w	; clear decompression in progress bit
	subq.w	#1,(Kos_decomp_queue_count).w
	beq.s	.Done								; branch if there aren't any entries remaining in the queue
	lea	(Kos_decomp_queue).w,a0
	lea	(Kos_decomp_queue+8).w,a1				; otherwise, shift all entries up

	rept kosqueueentries-1
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	endr

.Done:
Process_Kos_Queue_End:
	rts
; ---------------------------------------------------------------------------
Restore_Kos_Bookmark:
	movem.w	(Kos_decomp_stored_registers).w,d0-d6
	movem.l	(Kos_decomp_stored_registers+2*7).w,a0-a1/a5
	move.l	(Kos_decomp_bookmark).w,-(sp)
	move.w	(Kos_decomp_stored_SR).w,-(sp)
	moveq	#(1<<_Kos_LoopUnroll)-1,d7
	lea	KosDec_ByteMap(pc),a4		; Load LUT pointer.
	rte
; End of function Process_Kos_Queue
; ===========================================================================
Backup_Kos_Registers:
	move	sr,(Kos_decomp_stored_SR).w
	movem.w	d0-d6,(Kos_decomp_stored_registers).w
	movem.l	a0-a1/a5,(Kos_decomp_stored_registers+2*7).w
	rts
; ===========================================================================

	if _Kos_UseLUT
KosDec_ByteMap:
	dc.b	$00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0
	dc.b	$08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8
	dc.b	$04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4
	dc.b	$0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
	dc.b	$02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2
	dc.b	$0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
	dc.b	$06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6
	dc.b	$0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
	dc.b	$01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1
	dc.b	$09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9
	dc.b	$05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5
	dc.b	$0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
	dc.b	$03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3
	dc.b	$0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
	dc.b	$07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7
	dc.b	$0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF
	endif
; ===========================================================================
