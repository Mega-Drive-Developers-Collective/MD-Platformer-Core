; ==============================================================
; --------------------------------------------------------------
; Routine to create and remove platform objects
;
; in:
;   a0 = target object
; --------------------------------------------------------------

oRmvPlat		macro
		move.w	plat(a0),a1				; load platform pointer to a1
		clr.w	(a1)					; clear parent pointer
		clr.w	plat(a0)				; also clear platform pointer
    endm
; --------------------------------------------------------------

oCreatePlat		macro map, flags, width, height
		jsr	CreatePlatform.w			; jump to routine for creating platform data
		dc.b \width, \height				; add width and height data
		dc.l (\flags<<24)|\map				; add mappings and flags data
    endm
; --------------------------------------------------------------

CreatePlatform:
		lea	PlatformList.w,a1			; load platform list to a1
		tst.w	(a1)					; check if object exists
		beq.s	.create					; branch if not
		moveq	#platformcount-2,d0			; prepare platform count to d0
; --------------------------------------------------------------

.next
		addq.w	#psize,a1				; go to next object
		tst.w	(a1)					; check if object exists
		dbeq	d0,.next				; if yes, keep looping for all objects
		beq.s	.create					; if it didn't exist, branch
	exception	exCreatePlat				; handle platform exception
; --------------------------------------------------------------

.create
		move.w	a1,plat(a0)				; store platform pointer to object
		move.l	(sp)+,a2				; get data from stack
		move.w	a0,(a1)+				; load the parent pointer
		move.w	(a2)+,(a1)+				; load width and height
		move.l	(a2)+,(a1)+				; load flags and mappings
		jmp	(a2)					; jump to the address after the data
; ==============================================================
; --------------------------------------------------------------
; Routine to create and remove touch objects
;
; in:
;   a0 = target object
; --------------------------------------------------------------

oRmvTouch		macro
		move.w	touch(a0),a1				; load touch pointer to a1
		clr.w	(a1)					; clear parent pointer
		clr.w	touch(a0)				; also clear touch pointer
    endm
; --------------------------------------------------------------

oCreateTouch		macro flags, extra, width, height
		jsr	CreateTouch.w				; jump to routine for creating touch data
		dc.b \width, \height				; add width and height data
		dc.b \flags, \extra				; add flags data
    endm
; --------------------------------------------------------------

CreateTouch:
		lea	TouchList.w,a1				; load touch list to a1
		tst.w	(a1)					; check if object exists
		beq.s	.create					; branch if not
		moveq	#touchcount-2,d0			; prepare touch count to d0
; --------------------------------------------------------------

.next
		addq.w	#tsize,a1				; go to next object
		tst.w	(a1)					; check if object exists
		dbeq	d0,.next				; if yes, keep looping for all objects
		beq.s	.create					; if it didn't exist, branch
	exception	exCreateTouch				; handle touch exception
; --------------------------------------------------------------

.create
		move.w	a1,touch(a0)				; store touch pointer to object
		move.l	(sp)+,a2				; get data from stack
		move.w	a0,(a1)+				; load the parent pointer
		move.l	(a2)+,(a1)+				; load all data
		jmp	(a2)					; jump to the address after the data
; ==============================================================
; --------------------------------------------------------------
; Routine to create dynamic art objects
;
; in:
;   a0 = target object
; --------------------------------------------------------------

oCreateDynArt		macro art, map, width
		jsr	CreateDynArt.w				; jump to routine for creating dynamic art data
		dc.l ($FF<<24)|\art				; add art and last frame data
		dc.l (\width<<24)|\map				; add vram size and mappings data
    endm
; --------------------------------------------------------------

CreateDynArt:
		lea	DartList.w,a1				; load dynamic art list to a1
		tst.w	(a1)					; check if object exists
		beq.s	.create					; branch if not
		moveq	#dyncount-2,d0				; prepare touch count to d0
; --------------------------------------------------------------

.next
		add.w	#dsize,a1				; go to next object
		tst.w	(a1)					; check if object exists
		dbeq	d0,.next				; if yes, keep looping for all objects
		beq.s	.create					; if it didn't exist, branch
	exception	exCreateDynArt				; handle touch exception
; --------------------------------------------------------------

.create
		move.w	a1,dyn(a0)				; store dynamic art pointer to object
		st	DynAllocTimer.w				; force dynamic allocator to refactor
		move.l	(sp)+,a2				; get data from stack

		move.w	a0,(a1)+				; load the parent pointer
		move.l	(a2)+,(a1)+				; load art and last frame data
		move.l	(a2)+,(a1)+				; load vram size and mappings data
		move.w	#$FF00,(a1)+				; reset bit address
		jmp	(a2)					; jump to the address after the data
; ==============================================================
; --------------------------------------------------------------
; Routine to remove dynamic art objects
;
; in:
;   a0 = target object
; --------------------------------------------------------------

RmvDynArt:
		tst.w	dyn(a0)					; check if dynamic art was even loaded
		bpl.s	.rts					; branch if not
		move.w	dyn(a0),a1				; load dynamic art pointer to a1
		move.b	dbit(a1),d0				; load starting bit address
		beq.s	.clear					; if no art was loaded, skip clearing
; --------------------------------------------------------------

	; clear alloc table to free tiles
		moveq	#0,d1
		move.b	d0,d1					; copy starting bit to d1
		lsr.w	#3,d1					; divide by 8 (8 bits per byte)

		lea	DynAllocTable.w,a2			; load alloc table to a2
		add.w	d1,a2					; add byte offset
		and.w	#7,d0					; get only the bit to d0

		moveq	#0,d1
		move.b	dwidth(a1),d1				; load number of bits to d1
		subq.w	#1,d1					; sub 1 for dbf
; --------------------------------------------------------------

.bit
		bclr	d0,(a2)					; clear the bit to mark it as free
		addq.b	#1,d0					; go to next bit

		bclr	#4,d0					; check if the byte is now all done
		sne	d2					; if yes, set d2
		ext.w	d2					; extend to word
		sub.w	d2,a2					; sub from the alloc pointer
		dbf	d1,.bit					; loop until all bits are clear
; --------------------------------------------------------------

.clear
		clr.w	(a1)					; clear parent pointer
		clr.w	dyn(a0) 				; also clear dynamic art pointer

.rts
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to process dynamic art objects
;
; in:
;   a0 = target object
; --------------------------------------------------------------

ProcAlloc:
		lea	DartList.w,a1				; load dynamic art list to a1
		add.b	#dynallocdelta,DynAllocTimer.w		; update dynamic allocator timer
		bcs.s	AllocRefactor				; if overflowed, force a refactor
		moveq	#dyncount-1,d0				; load number of dynamic objects to d0
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
; --------------------------------------------------------------

AllocUpdate:
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
; --------------------------------------------------------------

AllocRefactor:
		lea	DynAllocTable.w,a0			; load alloc table to a0
		moveq	#0,d0					; prepare bit to d0
		moveq	#0,d2					; prepare first free bit to d2

	if dynallocbits<$81
		moveq	#dynallocbits-1,d1			; prepare max num of bits to d1
	else
		move.w	#dynallocbits-1,d1			; preapre max num of bits to d1
	endif
; --------------------------------------------------------------

.ckclr
		btst	d0,(a0)					; check if bit is set
		beq.s	.ckset					; if not, find if there are any set bits
		addq.b	#1,d0					; go to next bit
		addq.b	#1,d2					; go to next bit

		bclr	#4,d0					; check if the byte is now all done
		sne	d2					; if yes, set d2
		ext.w	d2					; extend to word
		sub.w	d2,a0					; sub from the alloc pointer
		dbf	d1,.ckclr				; loop until we find a bit that is clear
		rts						; no free tiles anywhere, refactoring is not necessary
; --------------------------------------------------------------

.ckset
		btst	d0,(a0)					; check if bit is set
		bne.s	.refac					; if yes, we must refactor
		addq.b	#1,d0					; go to next bit

		bclr	#4,d0					; check if the byte is now all done
		sne	d2					; if yes, set d2
		ext.w	d2					; extend to word
		sub.w	d2,a0					; sub from the alloc pointer
		dbf	d1,.ckset				; loop until we find a bit that is clear
		rts						; no refactoring needed
; --------------------------------------------------------------

	; this actually refactors all the art
.refac
		moveq	#dyncount-1,d0				; load number of dynamic objects to d0
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
		add.w	#dynallocstart/32,d3			; add the initial tile offset to d3
		or.w	d3,d4					; then save the tile address
		move.w	d4,tile(a0)				; save as tile settings

		moveq	#0,d4
		move.b	frame(a0),d4				; load display frame to d4
		move.b	d4,dlast(a1)				; copy as the last frame
		bsr.w	AllocUpdate				; update art
; --------------------------------------------------------------

		moveq	#0,d4
		move.b	dwidth(a0),d4				; load number of bits to reserve

		lea	DynAllocTable.w,a0			; load alloc table to a0
		move.w	d2,d3					; copy bit to d3
		lsr.w	#3,d3					; divide by 8 (8 bits per byte)
		add.w	d3,a0					; add byte offset

		move.w	d2,d3					; copy bit to d3
		and.w	#7,d3					; get only the bit to d3
		add.w	d4,d2					; go to the bit after this object
; --------------------------------------------------------------

.setbit
		bset	d0,(a0)					; set the bit
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

	if dynallocbits<$81
		moveq	#dynallocbits-1,d1			; prepare max num of bits to d1
	else
		move.w	#dynallocbits-1,d1			; preapre max num of bits to d1
	endif

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
