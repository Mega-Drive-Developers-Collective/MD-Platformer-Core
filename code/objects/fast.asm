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
;
; thrash: d0/a1-a2
;
; macro arguments:
;   map =	platform mappings left side address
;   flags =	platform flags
;   width =	width of the collision area from centre
;   height =	height of the collision area from centre
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
		dc.l ((\flags) << 24) | \map			; add mappings and flags data
	endm
; --------------------------------------------------------------

CreatePlatform:
		lea	PlatformList.w,a1			; load platform list to a1
		tst.w	(a1)					; check if object exists
		beq.s	.create					; branch if not
		dbset	platformcount-1,d0			; prepare platform count to d0
; --------------------------------------------------------------

.next
		addq.w	#psize,a1				; go to next object
		tst.w	ptr(a1)					; check if object exists
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
; --------------------------------------------------------------

	; remove this object from the list from current position
		move.w	prev(a0),a1				; copy previous pointer to a1
		move.w	next(a0),next(a1)			; copy next pointer to previous object
		move.w	next(a0),a1				; get next object to a1
		move.w	prev(a0),prev(a1)			; copy previous pointer
; --------------------------------------------------------------

	; add this object to the beginning of the list
		move.w	TailNext.w,a1				; load head object to a1
		move.w	a0,TailNext.w				; save as the new head object
		move.w	prev(a1),prev(a0)			; copy the prev pointer from old head to this object
		move.w	a0,prev(a1)				; save this object as prev pointer for old head
		move.w	a1,next(a0)				; save old head as the next pointer for this object
		jmp	(a2)					; jump to the address after the data
; ==============================================================
; --------------------------------------------------------------
; Routine to create and remove touch objects
;
; in:
;   a0 = target object
;
; thrash: d0/a1-a2
;
; macro arguments:
;   flags =	touch type flags
;   extra =	extra flags dependent on normal flags
;   width =	width of the collision area from centre
;   height =	height of the collision area from centre
; --------------------------------------------------------------

oRmvTouch		macro
		move.w	touch(a0),a1				; load touch pointer to a1
		clr.w	ptr(a1)					; clear parent pointer
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
		tst.w	ptr(a1)					; check if object exists
		beq.s	.create					; branch if not
		dbset	touchcount-1,d0				; prepare touch count to d0
; --------------------------------------------------------------

.next
		addq.w	#tsize,a1				; go to next object
		tst.w	ptr(a1)					; check if object exists
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
;
; thrash: d0/a1-a2
;
; macro arguments:
;   art =	address of the art used for dynamic art object
;   map =	address of the dynamic mappings
;   width =	the number of bits to reserve for the dynamic art
; --------------------------------------------------------------

oCreateDynArt		macro art, map, width
		jsr	CreateDynArt.w				; jump to routine for creating dynamic art data
		dc.l ($FF << 24) | \art				; add art and last frame data
		dc.l ((\width) << 24) | \map			; add vram size and mappings data
	endm
; --------------------------------------------------------------

CreateDynArt:
		lea	DartList.w,a1				; load dynamic art list to a1
		tst.w	ptr(a1)					; check if object exists
		beq.s	.create					; branch if not
		dbset	dyncount-1,d0				; prepare dymart count to d0
; --------------------------------------------------------------

.next
		lea	dsize(a1),a1				; go to next object
		tst.w	ptr(a1)					; check if object exists
		dbeq	d0,.next				; if yes, keep looping for all objects
		beq.s	.create					; if it didn't exist, branch
	exception	exCreateDynArt				; handle dynart exception
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
;
; thrash: d0-d2/a1-a2
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

		add.w	#DynAllocTable,d1			; add alloc table to d1
		move.w	d1,a2					; load result into a2
		and.w	#7,d0					; get only the bit to d0

		moveq	#0,d1
		move.b	dwidth(a1),d1				; load number of bits to d1
		subq.w	#1,d1					; sub 1 for dbf
; --------------------------------------------------------------

.bit
		bclr	d0,(a2)					; clear the bit to mark it as free
		addq.b	#1,d0					; go to next bit

		bclr	#3,d0					; check if the byte is now all done
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
; Routine to set object attributes
;
; in:
;   a0 = target object
;   a1 = data array
;
; thrash: a1
;
; For the macro, include any number of these arguments:
;   map =	object mappings address
;   frame =	initial display frame of object
;   flags =	initial set of flags for object
;   width =	width of the object in pixels from centre
;   height =	height of the object in pixels from centre
;   tile =	VDP tile pattern for this object
; --------------------------------------------------------------

oAttributes		macro map, frame, flags, width, height, tile
	local xarg						; use lbl only inside the macro
xarg =		narg						; uhh this looks like a asm68k bug? why does I have to do this
		lea	.data\@(pc),a1				; load data to a1
		jmp	ObjAttributes\#xarg			; jump to routine for setting attributes

.data\@:
	if narg >= 6
		dc.w \tile					; include tile data
	endif

	if narg >= 5
		dc.b \height, \width				; include width + height data
	elseif narg >= 4
		dc.b \width, \width				; include width + height data
	endif

	if narg >= 3
		dc.w \flags					; include flags data
	endif

	if narg >= 2
		dc.l ((\frame) << 24) | \map			; include mappings data with initial frame
	elseif narg >= 1
		dc.l \map					; include mappings data
	endif
	endm
; --------------------------------------------------------------

ObjAttributes6:
		move.w	(a1)+,tile(a0)				; set tile pattern

ObjAttributes5:
ObjAttributes4:
		move.b	(a1)+,height(a0)			; set object height
		move.b	(a1)+,width(a0)				; set object width

ObjAttributes3:
		move.w	(a1)+,flags(a0)				; set object flags

ObjAttributes2:
ObjAttributes1:
		move.l	(a1)+,map(a0)				; set mappings data

ObjAttributes0:
		jmp	(a1)					; jump back to code
; ==============================================================
; --------------------------------------------------------------
; Routine to delete an object
;
; in:
;   a0 = target object
;
; thrash: a1
; --------------------------------------------------------------

oDelete:
	oRmvDisplay	a0, a1, 1				; remove object display
	oRmvPlat						; remove platform object stuff
	oRmvTouch						; remove touch object stuff
		jsr	RmvDynArt.w				; remove dynamic art allocation

oDeleteUnsafe:
		move.w	prev(a0),a1				; copy previous pointer to a1
		move.w	next(a0),next(a1)			; copy next pointer to previous object
		move.w	next(a0),a1				; get next object to a1
		move.w	prev(a0),prev(a1)			; copy previous pointer

		move.w	FreeHead.w,prev(a0)			; get the head of the free list to previous pointer of this object
		move.w	a0,FreeHead.w				; save as the new head of free list
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to load an important object with a specific pointer
; Causes an exception when no free slots are found
;
; in:
;   a3 = object routine pointer
;
; out:
;   a1 = free object
;
; thrash: a2
; --------------------------------------------------------------

oLoadImportant:
		bsr.s	oLoad					; load an object
		bne.s	.free					; branch if a free slot was found
	exception	exCreateObj				; signal an exception
; --------------------------------------------------------------

.free
		move.l	a3,ptr(a1)				; copy pointer value
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to load an object
;
; out:
;   a1 = free object
;   z=1 = all slots are full
;   z=0 = object was loaded successfully
;
; thrash: a2
; --------------------------------------------------------------

oLoad:
		move.w	FreeHead.w,a1				; load the next free object to a1
		cmp.w	#0,a1					; check if its a null pointer
		beq.s	.rts					; branch if so (z=1)
		move.w	prev(a1),FreeHead.w			; copy the next free object pointer to list start
; --------------------------------------------------------------

	; clear object memory
		lea	dprev(a1),a2				; load the first byte to clear to a2
	if (size - dprev) & 2
		clr.w	(a2)+					; clear a word of data
	endif

	rept (size - dprev) / 4					; repeat for every object property
		clr.l	(a2)+					; clear a longword of data
	endr
; --------------------------------------------------------------

		move.w	TailPrev.w,a2				; load last object to a2
		move.w	a1,TailPrev.w				; save as the new last object
		move.w	next(a2),next(a1)			; copy the next pointer from old tail to new object
		move.w	a1,next(a2)				; save new object as next pointer for old tail
		move.w	a2,prev(a1)				; save old tail as prev pointer for new object

.rts
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to handle object velocity
;
; in:
;   a0 = target object
;
; thrash: d0
; --------------------------------------------------------------

oVelocity:
		move.w	xvel(a0),d0				; load x-velocity to d0
		ext.l	d0					; extend it to a longword
		asl.l	#8,d0					; change from 8.8 fixed point to 16.8 fixed point (needed for x-pos)
		add.l	d0,xpos(a0)				; add this to x-pos

		move.w	yvel(a0),d0				; load y-velocity to d0
		ext.l	d0					; extend it to a longword
		asl.l	#8,d0					; change from 8.8 fixed point to 16.8 fixed point (needed for y-pos)
		add.l	d0,ypos(a0)				; add this to y-pos
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to handle object velocity with Gravity
;
; in:
;   a0 = target object
;
; thrash: d0
; --------------------------------------------------------------

oGravity:
		move.w	xvel(a0),d0				; load x-velocity to d0
		ext.l	d0					; extend it to a longword
		asl.l	#8,d0					; change from 8.8 fixed point to 16.8 fixed point (needed for x-pos)
		add.l	d0,xpos(a0)				; add this to x-pos

		move.w	yvel(a0),d0				; load y-velocity to d0
		ext.l	d0					; extend it to a longword
		asl.l	#8,d0					; change from 8.8 fixed point to 16.8 fixed point (needed for y-pos)
		add.l	d0,ypos(a0)				; add this to y-pos

		add.w	#_gravity,yvel(a0)			; add gravity constant
		rts
