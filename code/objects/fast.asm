; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2020/12
;
;   Fast ROM object library code and macros (16-bit access)
; --------------------------------------------------------------

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
		dc.l (\flags<<24) | \map			; add mappings and flags data
    endm
; --------------------------------------------------------------

CreatePlatform:
		lea	PlatformList.w,a1			; load platform list to a1
		tst.w	(a1)					; check if object exists
		beq.s	.create					; branch if not
		dbset	platformcount-2,d0			; prepare platform count to d0
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
		dbset	touchcount-2,d0				; prepare touch count to d0
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
		dc.l ($FF<<24) | \art				; add art and last frame data
		dc.l (\width<<24) | \map			; add vram size and mappings data
    endm
; --------------------------------------------------------------

CreateDynArt:
		lea	DartList.w,a1				; load dynamic art list to a1
		tst.w	(a1)					; check if object exists
		beq.s	.create					; branch if not
		dbset	dyncount-2,d0				; prepare touch count to d0
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
; Routine to delete an object safely
;
; in:
;   a0 = target object
;
; thrash:
;   a1
; --------------------------------------------------------------

oDelete:
	oRmvDisplay	a0, a1, 1		; remove object display
	oRmvPlat				; remove platform object stuff
	oRmvTouch				; remove touch object stuff
		jsr	RmvDynArt.w		; remove dynamic art allocation

oDeleteUnsafe:
		move.w	prev(a0),a1		; copy previous pointer to a1
		move.w	next(a0),next(a1)	; copy next pointer to previous object
		move.w	next(a0),a1		; get next object to a1
		move.w	prev(a0),prev(a1)	; copy previous pointer

		move.w	FreeHead.w,prev(a0)	; get the head of the free list to previous pointer of this object
		move.w	a0,FreeHead.w		; save as the new head of free list
		rts
