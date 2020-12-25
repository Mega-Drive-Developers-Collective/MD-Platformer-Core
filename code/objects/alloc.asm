; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2020/12
;
;   VRAM allocation processing and dynamic art loading library
; --------------------------------------------------------------

; ==============================================================
; --------------------------------------------------------------
; Routine to process dynamic art objects
;
; in:
;   a0 = target object
;
; thrash: d0-d6/a0-a1/a3
; --------------------------------------------------------------

ProcAlloc:
		lea	DartList.w,a1				; load dynamic art list to a1
		add.b	#dynallocdelta,DynAllocTimer.w		; update dynamic allocator timer
		bcs.s	AllocRefactor				; if overflowed, force a refactor
		dbset	dyncount,d0				; load number of dynamic objects to d0
; --------------------------------------------------------------

.dloop
		tst.w	(a1)					; check if this is active
		bpl.s	.skip					; if not, branch

		moveq	#0,d4
		move.w	(a1),a0					; load the parent to a0
		move.b	frame(a0),d4				; load display frame to d4
		cmp.b	dlast(a1),d4				; check if we are currently displaying this frame
		beq.s	.skip					; if so, just skip it
		bsr.s	AllocUpdate				; update this
; --------------------------------------------------------------

.skip
		add.w	#dsize,a1				; go to next object
		dbf	d0,.dloop				; loop for all objects
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to update dynamic art object in VRAM
;
; in:
;   a0 = object
;   a1 = dynamic art address
;   d4 = frame
;
; thrash: d5-d6/a3
; --------------------------------------------------------------

AllocUpdate:
		move.b	d4,dlast(a1)				; save d4 as the new last frame
		move.l	dart(a1),d6				; load art data to d6
		move.l	dmap(a1),a3				; load art mappings to a3

		moveq	#0,d5
		move.w	tile(a0),d5				; load tile settings to d5
		and.w	#$7FF,d5				; get only the settings part
		lsl.w	#5,d5					; get the VRAM offset to d5
; --------------------------------------------------------------

	; add specifics of the code here


		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to refactor dynamic art objects in VRAM
;
; in:
;   a0 = target object
;
; thrash: d0-d6/a0-a1/a3
; --------------------------------------------------------------

AllocRefactor:
		lea	DartList.w,a1				; load dynamic art list to a1
		lea	DynAllocTable.w,a0			; load alloc table to a0

		moveq	#0,d0					; prepare bit to d0
		moveq	#0,d2					; prepare first free bit to d2
		dbset	dynallocbits,d1				; prepare max num of bits to d1
; --------------------------------------------------------------

.ckclr
		btst	d0,(a0)					; check if bit is set
		beq.s	.ckset					; if not, find if there are any set bits
		addq.b	#1,d0					; go to next bit
		addq.b	#1,d2					;

		bclr	#4,d0					; check if the byte is now all done
		sne	d3					; if yes, set d3
		ext.w	d3					; extend to word
		sub.w	d3,a0					; sub from the alloc pointer
		dbf	d1,.ckclr				; loop until we find a bit that is clear
		rts						; no free tiles anywhere, refactoring is not necessary
; --------------------------------------------------------------

.ckset	; TODO: broken
	;	btst	d0,(a0)					; check if bit is set
	;	bne.s	.refac					; if yes, we must refactor
	;	addq.b	#1,d0					; go to next bit

	;	bclr	#4,d0					; check if the byte is now all done
	;	sne	d3					; if yes, set d3
	;	ext.w	d3					; extend to word
	;	sub.w	d3,a0					; sub from the alloc pointer
	;	dbf	d1,.ckset				; loop until we find a bit that is clear
	;	rts						; no refactoring needed
; --------------------------------------------------------------

	; this actually refactors all the art
.refac
		dbset	dyncount,d0				; load number of dynamic objects to d0
		move.w	d2,d1					; copy free bit to d1

.reloop
		tst.w	(a1)					; check if this is active
		bpl.s	.skip					; if not, branch
		cmp.b	dbit(a1),d1				; check if this was after the first free bit
		blt.s	.skip					; if not, skip
		move.b	d2,dbit(a1)				; set the new address
; --------------------------------------------------------------

		move.w	(a1),a0					; load the parent to a0
		move.w	tile(a0),d4				; load tile settings to d4
		and.w	#$F800,d4				; get only the settings part

		move.w	d2,d3					; copy the bit offset we are in
		lsl.w	#dynallocsize,d3			; multiply by number of bits for tile count
		add.w	#vDynamic/32,d3				; add the initial tile offset to d3
		or.w	d3,d4					; then save the tile address
		move.w	d4,tile(a0)				; save as tile settings

		moveq	#0,d4
		move.b	frame(a0),d4				; load display frame to d4
		bsr.w	AllocUpdate				; update art
; --------------------------------------------------------------

		moveq	#0,d4
		move.b	dwidth(a1),d4				; load number of bits to reserve

		lea	DynAllocTable.w,a0			; load alloc table to a0
		move.w	d2,d3					; copy bit to d3
		lsr.w	#3,d3					; divide by 8 (8 bits per byte)
		add.w	d3,a0					; add byte offset

		moveq	#7,d3					; get only the bit to d3
		and.w	d2,d3					; and bit with d3
		add.w	d4,d2					; go to the bit after this object
; --------------------------------------------------------------

.setbit
		bset	d3,(a0)					; set the bit
		addq.b	#1,d3					; go to next bit

		bclr	#4,d3					; check if the byte is now all done
		sne	d5					; if yes, set d2
		ext.w	d5					; extend to word
		sub.w	d5,a0					; sub from the alloc pointer
		dbf	d4,.setbit				; loop until all bits are set
; --------------------------------------------------------------

.skip
		add.w	#dsize,a1				; go to next object
		dbf	d0,.reloop				; loop for all objects
; --------------------------------------------------------------

	; finally, mark all the other bits free
		moveq	#0,d0
		move.b	d2,d0					; copy starting bit to d0
		lsr.w	#3,d0					; divide by 8 (8 bits per byte)

		lea	DynAllocTable.w,a2			; load alloc table to a2
		add.w	d0,a2					; add byte offset
; --------------------------------------------------------------

		dbset	dynallocbits,d1				; prepare max num of bits to d1
		sub.w	d2,d1					; sub the number of bits done from d1
		and.w	#7,d2					; get only the bit to d0
; --------------------------------------------------------------

.clrlp
		bclr	d2,(a0)					; clear the bit
		addq.b	#1,d2					; go to next bit

		bclr	#4,d2					; check if the byte is now all done
		sne	d0					; if yes, set d2
		ext.w	d0					; extend to word
		sub.w	d0,a0					; sub from the alloc pointer
		dbf	d1,.clrlp				; loop until all bits are cleared
		rts
; --------------------------------------------------------------
