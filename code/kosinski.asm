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

; ==============================================================
; --------------------------------------------------------------
; Routine to process the kosinski moduled queue
;
; thrash: d0-d1/a2
; --------------------------------------------------------------

kosmQueueProc:
		tst.b	kosmQueueLeft.w				; check if any modules are left to be decompressed
		bne.s	.proc					; if yes, branch

.done
		rts
; --------------------------------------------------------------

.proc
		bmi.s	.decomp					; branch if currently decompressing
		cmpi.b	#kosqueueentries,kosQueueLeft.w		; check if kosinski queue is full
		bhs.s	.done					; branch if so
		ori.b	#$80,kosmQueueLeft.w			; set as currently decompressing

		movea.l	kosmQueueSource.w,a1			; load the kosinski module source address to a1
		lea	kosmBuffer.w,a2				; load the destination buffer address to a2
		jmp	kosQueueAdd(pc)				; add current module to decompression queue
; --------------------------------------------------------------

.decomp
		tst.b	kosQueueLeft.w				; check if the previous module was decompressed
		bne.s	.done					; branch if its still in progress

	; DMA the module data
		andi.b	#$7F,kosmQueueLeft.w			; set as currently not decompressing
		move.w	#$800,d3				; load the default module size

		subq.b	#1,kosmQueueLeft.w			; decrease the modules left to decompress
		bne.s	.skip					; if not the last module, branch
		move.w	kosmLastSize.w,d3			; load the size of the last module to d3

.skip
		move.w	kosmQueueDest.w,d5			; load the destination VRAM address to d5
		move.w	d5,d0					; copy it to d0
		add.w	d3,d0					; add the module size to d0
		add.w	d3,d0					; twice since its in words, not bytes
		move.w	d0,kosmQueueDest.w			; save the new destination

		move.l	kosmQueueSource.w,d0			; load the kosinski module source address to d0
		move.l	kosQueueSource.w,d1			; load the kosinski source address to d1
		sub.l	d1,d0					; load the difference to d0
		andi.l	#$F,d0					; for some reason, align to the next $10 bytes
		add.l	d0,d1					;
		move.l	d1,kosmQueueSource.w			; save the new kosinski module source address

		move.l	#kosmBuffer&$FFFFFF,d4			; load the kosinski moduled buffer as the source address for DMA
		jsr	dmaQueueAdd.w				; add the DMA into DMA queue
		tst.b	kosmQueueLeft.w				; check if there are more modules left
		bne.s	.done					; branch if yes
; --------------------------------------------------------------

	; shift the queue
		lea	kosmQueue.w,a0				; load the new destination for queue data
		lea	kosmQueue+6.w,a1			; load the source for the queue data

	rept kosmqueueentries-1
		move.l	(a1)+,(a0)+				; copy the entry upwards
		move.w	(a1)+,(a0)+				;
	endr

		clr.l	(a0)+					; clear the last entry
		clr.w	(a0)+					;
; --------------------------------------------------------------

		move.l	kosmQueueSource.w,d0			; load the new source address for the queue
		beq.s	kosmQueueAdd_Rts			; branch if the queue is empty now
		movea.l	d0,a1					; copy the source address to a1

		move.w	kosmQueueDest.w,d2			; load the destination address
		bra.s	kosmQueueInit				; initialize the next module file
; ==============================================================
; --------------------------------------------------------------
; Routine to queue a kosinski module file
;
; input:
;   d2 = destination VRAM address
;   a1 = source ROM address
;
; thrash: d0-d1/a2
; --------------------------------------------------------------

kosmQueueFindSlot:
		dbset	kosmqueueentries-1,d0			; load the number of entries for the kosinsko moduled queue to d0

.loop
		addq.w	#6,a2					; go to the next slot
		tst.l	(a2)					; check if this is free

	if SAFE
		dbeq	d0,.loop				; keep looping until a free entry is found or the entire queue is exhausted
		beq.s	.create					; if it didn't exist, branch
	exception	exAddKosm				; handle kosinski moduled queue exception

	else
		bne.s	.loop					; keep looping until there is an empty slot. Will bork if full
	endif
; --------------------------------------------------------------

.create
		move.l	a1,(a2)+				; store source address
		move.w	d2,(a2)+				; store destination VRAM address

kosmQueueAdd_Rts:
		rts
; --------------------------------------------------------------

kosmQueueAdd:
		lea	kosmQueue.w,a2				; load kosm queue address to a1
		tst.l	(a2)					; check first entry
		bne.s	kosmQueueFindSlot			; if it's not free, initialize the file immediately
; ==============================================================
; --------------------------------------------------------------
; Routine to initialize a kosinski module file
;
; input:
;   d2 = destination VRAM address
;   a1 = source ROM address
;
; thrash: d0-d1
; --------------------------------------------------------------

kosmQueueInit:
		move.w	(a1)+,d1				; load destination size to d1
		lsr.w	#1,d1					; divide into number of words

		move.w	d1,d0					; copy into d1
		rol.w	#5,d0					; shift the size bits into place (this assumes each archive is $800 words)
		andi.w	#$1F,d0					; get only the number of full modules

		andi.w	#$7FF,d1				; get the size of the last module in words
		bne.s	.partial				; branch if not 0
		subq.b	#1,d0					; decrease the number of modules
		move.w	#$800,d1				; force the last module to be $800 words

.partial
		move.w	d1,kosmLastSize.w			; store the size of the last module
		move.w	d2,kosmQueueDest.w			; store the destination VRAM address
		move.l	a1,kosmQueueSource.w			; store the source address of the first module

		addq.b	#1,d0					; correct the number of modules
		move.b	d0,kosmQueueLeft.w			; store the number of modules
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to add a list of kosinski modules into the queue
;
; input:
;   a3 = kosinski module queue list
;
; thrash: d0-d3/a1-a2
; --------------------------------------------------------------

kosmQueueList_Next:
		move.l	(a3)+,a1				; load kosinski module source address
		move.w	(a3)+,d2				; load the destination VRAM address
		bsr.s	kosmQueueAdd				; add to the queue
; --------------------------------------------------------------

kosmQueueList:
		tst.w	(a3)					; check if we found the end token
		bpl.s	kosmQueueList_Next			; if not, keep loopimg
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to queue a kosinski module list from the global array
;
; input:
;   d0 = num offset into the array, in multiples of 2
;
; thrash: d0-d3/a1-a3
; --------------------------------------------------------------

kosmQueueGlobal:
		move.w	kosmGlobalTable(pc,d0.w),d0		; load the offset from the table
		lea	kosmGlobalTable(pc,d0.w),a3		; load the kosinski module list to a3
		bra.s	kosmQueueList				; load this list data now
; --------------------------------------------------------------

kosmGlobalTable:
		dc.w .test-kosmGlobalTable			; $00 - test

.test
	kosmEntry vStatic, kosmHud
		dc.w -1
; ==============================================================
; --------------------------------------------------------------
; Routine to queue a kosinski file
;
; input:
;   a1 = source ROM address
;   a2 = destination ROM address
;
; thrash: d0/a3
; --------------------------------------------------------------

kosQueueAdd:
		moveq	#$7F,d0					; prepare mask to d0 (clears the decompression bit)
		and.b	kosQueueLeft.w,d0			; AND with the amount of modules left

	if SAFE
		cmp.b	#kosqueueentries,d0			; check if queue is full
		blo.s	.free					; branch if not
	exception	exAddKos				; handle kosinski queue exception

.free
	endif

		lsl.w	#3,d0					; multiply by 8 (the size of the queue)
		add.w	#kosQueue,d0				; add the actual queue address
		move.w	d0,a3					; get the final address to a3

		move.l	a1,(a3)+				; store the source address
		move.l	a2,(a3)+				; store the destination address
		addq.b	#1,kosQueueLeft.w			; increment the number of kos entries left

kosQueueAdd_Rts:
		rts
; ==============================================================
; --------------------------------------------------------------
; Kosinski decompression macros
; --------------------------------------------------------------

kosBitstream		macro
		dbf	d2,.skip\@
		moveq	#7,d2					; set repeat count to 8.
		move.b	d1,d0					; use the remaining 8 bits.
		not.w	d3					; have all 16 bits been used up?
		bne.s	.skip\@					; branch if not.

		move.b	(a0)+,d0				; get desc field low-byte.
		move.b	(a0)+,d1				; get desc field hi-byte.

	if kosuselut
		move.b	(a4,d0.w),d0				; invert bit order...
		move.b	(a4,d1.w),d1				; ... for both bytes.
	endif

.skip\@
	endm

kosReadbit		macro
	if kosuselut
		add.b	d0,d0					; get a bit from the bitstream.
	else
		lsr.b	#1,d0					; get a bit from the bitstream.
	endif
	endm
; ==============================================================
; --------------------------------------------------------------
; Routine to process kosinski decompression queue
;
; input:
;   a1 = source ROM address
;   a2 = destination ROM address
;
; thrash: d0/a3
; --------------------------------------------------------------

kosQueueProc:
		tst.b	kosQueueLeft.w				; check if there are any kosinski files left
		beq.s	kosQueueAdd_Rts				; if not, branch
		bpl.s	kosQueueProc_Start			; branch if not interrupted by v-int

		movem.w	kosRegisters.w,d0-d6			; load all the data register stuff
		movem.l	kosRegisters+(2*7).w,a0-a1/a5		; load all the address register stuff
		moveq	#(1<<kosunroll)-1,d7			; prepare the loop unroll value
		lea	KosDec_ByteMap(pc),a4			; prepare the LUT

		move.l	kosRoutine.w,-(sp)			; store the routine address to stack
		move.w	kosSR.w,-(sp)				; store the SR into the stack
		rte						; restore the SR and routine address, running the code again
; --------------------------------------------------------------

kosQueueProc_Start:
		ori.b	#$80,kosQueueLeft.w			; set as currently decompressing
		movea.l	kosQueueSource.w,a0			; load the source address of the kosinski file
		movea.l	kosQueueDest.w,a1			; load the destination address of the data
; ==============================================================
; --------------------------------------------------------------
; Routine to decompress a kosinski file immediately.
; Be aware that using this file while there are items in the
; kosinski decompression queue will cause severe issues.
;
; input:
;   a1 = source ROM address
;   a2 = destination ROM address
;
; thrash: d0-d7/a0-a5
; --------------------------------------------------------------

kosDec:
; note: I actually don't know how this works exactly, so the comments
; are just from Flamewing's original code
		moveq	#(1<<kosunroll)-1,d7
	if kosuselut
		moveq	#0,d0
		moveq	#0,d1
		lea	KosDec_ByteMap(pc),a4			; load LUT pointer.
	endif

		move.b	(a0)+,d0				; get desc field low-byte.
		move.b	(a0)+,d1				; get desc field hi-byte.

	if kosuselut
		move.b	(a4,d0.w),d0				; invert bit order...
		move.b	(a4,d1.w),d1				; ... for both bytes.
	endif

		moveq	#7,d2					; set repeat count to 8.
		moveq	#0,d3					; d3 will be desc field switcher
		bra.s	.fetchnewcode
; --------------------------------------------------------------

.fetchcodeloop
	; code 1 (Uncompressed byte).
		kosBitstream
		move.b	(a0)+,(a1)+
; --------------------------------------------------------------

.fetchnewcode
		kosReadbit
		bcs.s	.fetchcodeloop				; if code = 1, branch.

	; codes 00 and 01.
		moveq	#-1,d5
		lea	(a1),a5
		kosBitstream

	if kosunrollextreme
		kosReadbit
		bcs.w	.code_01
; --------------------------------------------------------------

	; code 00 (Dictionary ref. short).
		kosBitstream
		kosReadbit
		bcs.s	.copy45

		kosBitstream
		kosReadbit
		bcs.s	.copy3

		kosBitstream
		move.b	(a0)+,d5				; d5 = displacement.
		adda.w	d5,a5

		move.b	(a5)+,(a1)+
		move.b	(a5)+,(a1)+
		bra.s	.fetchnewcode
; --------------------------------------------------------------

.copy3
		kosBitstream
		move.b	(a0)+,d5				; d5 = displacement.
		adda.w	d5,a5

		move.b	(a5)+,(a1)+
		move.b	(a5)+,(a1)+
		move.b	(a5)+,(a1)+
		bra.w	.fetchnewcode
; --------------------------------------------------------------

.copy45
		kosBitstream
		kosReadbit
		bcs.s	.copy5

		kosBitstream
		move.b	(a0)+,d5				; d5 = displacement.
		adda.w	d5,a5

		move.b	(a5)+,(a1)+
		move.b	(a5)+,(a1)+
		move.b	(a5)+,(a1)+
		move.b	(a5)+,(a1)+
		bra.w	.fetchnewcode
; --------------------------------------------------------------

.copy5
		kosBitstream
		move.b	(a0)+,d5				; d5 = displacement.
		adda.w	d5,a5

		move.b	(a5)+,(a1)+
		move.b	(a5)+,(a1)+
		move.b	(a5)+,(a1)+
		move.b	(a5)+,(a1)+
		move.b	(a5)+,(a1)+
		bra.w	.fetchnewcode
; --------------------------------------------------------------

	else
		moveq	#0,d4					; d4 will contain copy count.
		kosReadbit
		bcs.s	.code_01

	; code 00 (Dictionary ref. short).
		kosBitstream
		kosReadbit
		addx.w	d4,d4

		kosBitstream
		kosReadbit
		addx.w	d4,d4

		kosBitstream
		move.b	(a0)+,d5				; d5 = displacement.

.streamcopy
		adda.w	d5,a5
		move.b	(a5)+,(a1)+				; do 1 extra copy (to compensate +1 to copy counter).

.copy
		move.b	(a5)+,(a1)+
		dbf	d4,.copy
		bra.w	.fetchnewcode
	endif
; --------------------------------------------------------------

.code_01
		moveq	#0,d4					; d4 will contain copy count.

	; code 01 (Dictionary ref. long / special).
		kosBitstream
		move.b	(a0)+,d6				; d6 = %LLLLLLLL.
		move.b	(a0)+,d4				; d4 = %HHHHHCCC.
		move.b	d4,d5					; d5 = %11111111 HHHHHCCC.
		lsl.w	#5,d5					; d5 = %111HHHHH CCC00000.
		move.b	d6,d5					; d5 = %111HHHHH LLLLLLLL.

	if kosunroll=3
		and.w	d7,d4					; d4 = %00000CCC.
	else
		andi.w	#7,d4
	endif
		bne.s	.streamcopy				; if CCC=0, branch.

	; special mode (extended counter)
		move.b	(a0)+,d4				; read cnt
		beq.s	.quit					; if cnt=0, quit decompression.
		subq.b	#1,d4
		beq.w	.fetchnewcode				; if cnt=1, fetch a new code.

		adda.w	d5,a5
		move.b	(a5)+,(a1)+				; do 1 extra copy (to compensate +1 to copy counter).

		move.w	d4,d6
		not.w	d6
		and.w	d7,d6
		add.w	d6,d6
		lsr.w	#kosunroll,d4
		jmp	.largecopy(pc,d6.w)
; --------------------------------------------------------------

.largecopy
	rept (1<<kosunroll)
		move.b	(a5)+,(a1)+
	endr
		dbf	d4,.largecopy
		bra.w	.fetchnewcode
; --------------------------------------------------------------

	if kosunrollextreme
.streamcopy
		adda.w	d5,a5
		move.b	(a5)+,(a1)+				; do 1 extra copy (to compensate +1 to copy counter).

	if kosunroll=3
		eor.w	d7,d4
	else
		eori.w	#7,d4
	endif

		add.w	d4,d4
		jmp	.mediumcopy(pc,d4.w)
; --------------------------------------------------------------

.mediumcopy
	rept 8
		move.b	(a5)+,(a1)+
	endr
		bra.w	.fetchnewcode
	endif
; --------------------------------------------------------------

.quit
		move.l	a0,kosQueueSource.w			; save the new source address for the kosinski file
		move.l	a1,kosQueueDest.w			; save the new destination address

		andi.b	#$7F,kosQueueLeft.w			; disable decompression bit
		subq.b	#1,kosQueueLeft.w			; decrease the amount of kosinski files left
		beq.s	kosQueueProc_End			; branch if none are left
; --------------------------------------------------------------

		lea	kosQueue.w,a0				; load the new destination for queue data
		lea	kosQueue+8.w,a1				; load the source for the queue data

	rept kosqueueentries-1
		move.l	(a1)+,(a0)+				; copy the entry upwards
		move.l	(a1)+,(a0)+				;
	endr

kosQueueProc_End:
		rts
; --------------------------------------------------------------

	if kosuselut
KosDec_ByteMap:
		dc.b $00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0
		dc.b $08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8
		dc.b $04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4
		dc.b $0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
		dc.b $02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2
		dc.b $0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
		dc.b $06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6
		dc.b $0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
		dc.b $01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1
		dc.b $09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9
		dc.b $05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5
		dc.b $0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
		dc.b $03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3
		dc.b $0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
		dc.b $07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7
		dc.b $0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF
	endif
; --------------------------------------------------------------
