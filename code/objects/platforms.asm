; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2020/12
;
;   Platform collision code
; --------------------------------------------------------------

; ==============================================================
; --------------------------------------------------------------
; Routine to test platform collisions for object.
; Note: Run before applying physics. They will be taken into
; account for calculation.
;
; in:
;   a0 = test object
;
; out:
;   d6 = x-offset
;   d7 = y-offset
;   a1 = target platform (0 if none)
;   eq = no collision (ne = collision)
;
; thrash: d0-d7/a1-a2
; --------------------------------------------------------------

platCheck:
		move.w	xvel(a0),d2				; load x-velocity to d2
		ext.l	d2					; extend it to a longword
		asl.l	#8,d2					; change from 8.8 fixed point to 16.8 fixed point (needed for x-pos)
		add.l	xpos(a0),d2				; add x-pos to d2

		moveq	#0,d4
		move.b	d2,d4					; load object width to d4
		ext.w	d4					; extend to a word

		swap	d4					; swap words
		sub.l	d4,d2					; subtract from x-pos
		swap	d4					; swap back
		add.w	d4,d4					; double width
		swap	d2					; swap x-pos words
; --------------------------------------------------------------

		move.w	yvel(a0),d3				; load y-velocity to d3
		ext.l	d3					; extend it to a longword
		asl.l	#8,d3					; change from 8.8 fixed point to 16.8 fixed point (needed for y-pos)
		add.l	ypos(a0),d3				; add y-pos to d2

		moveq	#0,d5
		move.b	d3,d5					; load object height to d5
		ext.w	d5					; extend to a word

		swap	d5					; swap words
		sub.l	d5,d3					; subtract from y-pos
		swap	d5					; swap back
		add.w	d5,d5					; double height
		swap	d3					; swap y-pos words
; --------------------------------------------------------------

		lea	PlatformList.w,a1			; load platform list to a1
		dbset	platformcount,d0			; prepare platform count to d0

.platloop
		tst.w	ptr(a1)					; check if object exists
		beq.s	.next					; go to next platform check
		tst.b	pflags(a1)				; check if enabled
		bpl.s	.next					; branch if not
		move.w	ptr(a1),a2				; load the parent object to a2
; --------------------------------------------------------------

		moveq	#0,d0					; clear d0
		move.b	pwidth(a1),d0				; load platform width to d0
		move.w	d0,d1					; copy to d1 too
		add.w	xpos(a2),d0				; add x-pos of platform to d0

		cmp.w	d2,d0					; check if object is past platform right position
		bls.s	.next					; branch if so
		sub.w	d1,d0					; subtract the width from d0
		sub.w	d1,d0					; twice to get full width

		sub.w	d4,d0					; subtract the object width from platform
		cmp.w	d2,d0					; check if object is before platform left position
		bhi.s	.next					; branch if so
; --------------------------------------------------------------

		moveq	#0,d0					; clear d0
		move.b	pheight(a1),d0				; load platform height to d0
		move.w	d0,d6					; copy to d6 too
		add.w	ypos(a2),d0				; add y-pos of platform to d0

		cmp.w	d3,d0					; check if object is below platform bottom position
		bls.s	.next					; branch if so
		sub.w	d6,d0					; subtract the height from d0
		sub.w	d6,d0					; twice to get full height

		sub.w	d5,d0					; subtract the object height from platform
		cmp.w	d3,d0					; check if object is above platform top position
		blo.s	.found					; branch if not
; --------------------------------------------------------------

.next
		addq.w	#psize,a1				; go to next object
		dbf	d0,.next				; loop for all objects

		moveq	#0,d0					; clear d0
		moveq	#0,d1					; clear d1
		move.w	d1,a1					; set platform to null and z=1
		rts
; --------------------------------------------------------------

.found
	; handle collision detection
		sub.w	xpos(a2),d2				; subtract x-pos of platform from target left position
		sub.w	d1,d2					; subtract the width
		move.w	d2,d0					; copy to d0
		bmi.s	.toleft					; branch if we should push target to left

		add.w	d1,d2					; add the width
		add.w	d1,d2					; add the width
		add.w	d4,d2					; subtract the width from d2
		move.w	d2,d0					; copy to d0
		neg.w	d0					; negate offset

.toleft
		sub.w	ypos(a2),d3				; subtract y-pos of platform from target top position
		move.w	d3,d4					; copy to d1
		bpl.s	.totop					; branch if we should push target to top

		sub.w	d5,d3					; subtract the width from d3
		move.w	d3,d4					; copy to d1
		neg.w	d4					; negate offset

.totop
		cmp.w	d4,d0					; check if we should snap to the top
	;	bhi.s	platSnapTopBottom			; snap top to or bottom
; ==============================================================
; --------------------------------------------------------------
; Routine to calculate where to snap target to based on positions
; left or right version
;
; in:
;   d6 = horizontal offset
;   a0 = target object
;   a1 = target platform
;   a2 = platform object
;
; out:
;   d6 = x-offset
;   d7 = y-offset
;   a1 = target platform (0 if none)
;   eq = no collision (ne = collision)
;
; thrash: d0-d7/a1-a2
; --------------------------------------------------------------

platSnapLeftRight:
		btst	#plrb,pflags(a1)			; check if LRB is enabled
		beq.s	platSnapTopBottom2			; branch if not

platSnapLeftRight2:
		bset	#yflip,flags(a2)

		neg.w	d2					; check which direction to use
		beq.s	.snap					; branch if neither
		bpl.s	.right					; branch if to the right
; --------------------------------------------------------------

	; left
		tst.w	xvel(a0)				; check which direction we're moving
		blt.s	.snap					; if we're moving left, just snap the position
		bra.s	.clear					; clear speeds
; --------------------------------------------------------------

	; right
.right
		tst.w	xvel(a0)				; check which direction we're moving
		bpl.s	.snap					; if we're moving right, just snap the position

.clear
		clr.w	xvel(a0)				; clear velocity
; --------------------------------------------------------------

	; snap position
.snap
		moveq	#0,d3					; clear the y-offset
		tst.w	d2					; check if x-offset is not 0
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to calculate where to snap target to based on positions
; top or bottom version
;
; in:
;   d7 = vertical offset
;   a0 = target object
;   a1 = target platform
;   a2 = platform object
;
; out:
;   d6 = x-offset
;   d7 = y-offset
;   a1 = target platform (0 if none)
;   eq = no collision (ne = collision)
;
; thrash: d0-d7/a1-a2
; --------------------------------------------------------------

platSnapTopBottom:
		btst	#ptop,pflags(a1)			; check if LRB is enabled
		beq.s	platSnapLeftRight2			; branch if not

platSnapTopBottom2:
		bclr	#yflip,flags(a2)
		rts
