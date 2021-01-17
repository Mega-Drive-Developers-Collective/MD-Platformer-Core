; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS, Nat The Porcupin 2020/12
;
;   Mappings rendering subroutines and macros
; --------------------------------------------------------------

; ==============================================================
; --------------------------------------------------------------
; macro to include sprite pieces
;
;   tile =	VDP base tile pattern for this sprite
;   width =	width of the sprite piece, from 1 to 4 tiles
;   height =	height of the sprite piece, from 1 to 4 tiles
;   x =		x-offset from centre of object for this sprite
;   y =		y-offset from centre of object for this sprite
; --------------------------------------------------------------

sprite		macro tile, width, height, x, y
	__sprite $00, \tile, \width, \height, \x, \y
	endm

spritt		macro tile, width, height, x, y
	__sprite $FF, \tile, \width, \height, \x, \y
	endm

__sprite	macro term, tile, width, height, x, y
	if ((\width) < 1) | ((\width) > 4)
		inform 2, "Sprite width \width is invalid. Must be 1 to 4"
	endif

	if ((\height) < 1) | ((\height) > 4)
		inform 2, "Sprite height \height is invalid. Must be 1 to 4"
	endif

		dc.w \term | (((\width)-1) << 10) | (((\height)-1) << 8); include object size and link data and terminator
		dc.w (\y)					; include y-pos
		dc.w (\x) & $1FF				; include x-pos
		dc.w \tile					; include tile pattern
	endm
; ==============================================================
; --------------------------------------------------------------
; Routine to convert mappings to sprites
;
; thrash: d0-d7/a0-a5
; --------------------------------------------------------------

ProcMaps:
		moveq	#0,d6				; 4	; clear link value
		moveq	#80-1,d7			; 4	; load max num of sprites to d7
		lea	SpriteTable.w,a0		; 8	; load sprite table address to a0
		move.l	RenderList.w,a5			;	; load list of rendering routines to a5
		bra.s	.checkend			; 10	; skip over a bit
; --------------------------------------------------------------

.next
	if DEBUG						; some code to make sure Regen doesn't crash. Shitty
		move.l	(a5)+,d0			;	; load next routine into a0
		and.l	#$FFFFFF,d0			;	; clear extra bits
		move.l	d0,a3				;	; copy to a3
	else
		move.l	(a5)+,a3			;	; load next routine into a3
	endif

		move.l	(a5)+,a4			;	; load parameter to a4
		jsr	(a3)				;	; run this routine

.checkend
		tst.b	(a5)				;	; check for the end token
		bne.s	.next				; 10/8	; branch if wan't yet
		clr.b	-5(a0)				; 16	; clear the link counter of the last sprite
		rts					; 16
; ==============================================================
; --------------------------------------------------------------
; Routine to convert a display layer to sprites
;
; input:
;   d6 = link value
;   d7 = sprite pieces left
;   a0 = sprite table address
;   a4 = display layer address
;
; thrash: d0-d3/a1/a3-a4
; --------------------------------------------------------------

ProcMapsLayer:
		move.w	(a4),a1				; 8	; load layer pointer to a1
		tst.w	dnext(a1)			; 12	; check if this object is valid
		beq.s	ProcMapsLayer_Rts		; 10/8	; if yes, there are objects left
; --------------------------------------------------------------

.obj
		moveq	#$FF-(1<<(onscreen&7)),d0	; 4	; setup d0 for and (and clear upper word)
		and.b	d0,flags(a1)			; 16	; clear onscreen flag
; --------------------------------------------------------------

	; x-pos onscreen check
		move.b	width(a1),d0			; 12	; load object width to d0
		move.w	xpos(a1),d1			; 12	; load x-pos to d1
		sub.w	CameraX.w,d1			; 12	; subtract camera x-pos from d1 (get relative position)

		move.w	d1,d3				; 4	; copy x-pos to d3
		add.w	d0,d3				; 4	; add width to x-pos

		add.w	d0,d0				; 4	; double width
		add.w	#320,d0				; 8	; add screen width to d0
		cmp.w	d0,d3				; 4	; check if is onscreen from x-axis
		bhs.s	.offscreen			; 10/8	; branch if not
; --------------------------------------------------------------

	; y-pos onscreen check
		moveq	#0,d0				; 4	; clear upper bytes of d0
		move.b	height(a1),d0			; 12	; load object height to d0
		move.w	ypos(a1),d2			; 12	; load y-pos to d2
		sub.w	CameraY.w,d2			; 12	; subtract camera y-pos from d2 (get relative position)

		move.w	d2,d3				; 4	; copy y-pos to d3
		add.w	d0,d3				; 4	; add height to y-pos

		add.w	d0,d0				; 4	; double height
		add.w	#240,d0				; 8	; add screen height to d0 (NOTE: PAL compatible, will not be useful for v28!!!)
		cmp.w	d0,d3				; 4	; check if is onscreen from y-axis
		bhs.s	.offscreen			; 10/8	; branch if not
; --------------------------------------------------------------

		move.w	#128,d0				; 8	; prepare sprite deadzone offset to d0
		add.w	d0,d1				; 4	; add to x-pos
		add.w	d0,d2				; 4	; add to y-pos

	if onscreen = 7					; 16	; this code only works if this is the same bit
		or.b	d0,flags(a1)				; also add this to flags
	else
		or.b	#1<<(onscreen&7),flags(a1)	; 20	; enable onscreen flag
	endif
; --------------------------------------------------------------

	; send off to render code
		tst.w	d7				; 4	; check if there are more pieces to render
		bmi.s	.offscreen			; 10/8	; branch if not

		bsr.s	ProcMapObj			; 18	; process object mappings
	;	bmi.s	.offscreen			; 10/8	; branch if the end token was met
	;	clr.b	-4(a0)				; 16	; clear the link counter of the last sprite
; --------------------------------------------------------------

.offscreen
		move.w	dnext(a1),a1			; 12	; load next object to a1
		tst.w	dnext(a1)			; 12	; check if this object is valid
		bne.s	.obj				; 10/8	; if yes, there are objects left

ProcMapsLayer_Rts:
		rts					; 16
; ==============================================================
; --------------------------------------------------------------
; Routine to convert object mappings to sprites
;
; input:
;   d0 = $0080
;   d1 = x-pos
;   d2 = y-pos
;   d6 = link value
;   d7 = sprite pieces left
;   a0 = sprite table address
;   a1 = object address
;
; thrash: d0-d3/a3
; --------------------------------------------------------------

ProcMapObj:	; 106 or 146 cycles max
		btst	#norender,flags(a1)		; 10	; check if sprites should be rendered
		bne.s	ProcMapsLayer_Rts		; 10/8	; branch if rendering is disabled

		move.l	map(a1),a3			; 16	; load object mappings address to a3
		btst	#singlesprite,flags(a1)		; 10	; check if in single sprite mode
		bne.s	.single				; 10/8	; branch if yes

		move.b	frame(a1),d0			; 12	; load frame number to d0
		beq.s	ProcMapsLayer_Rts		; 10/8	; if 0, force a blank frame
		add.w	d0,d0				; 4	; double it (read from mappings)
		add.w	-2(a3,d0.w),a3			; 18	; add mappings offset from table
; --------------------------------------------------------------

.single
		move.w	tile(a1),d3			; 12	; load tile pattern to d3
		moveq	#(1<<(xflip&7))|(1<<(yflip&7)),d0; 4	; load flags mask to d0
		and.b	flags(a1),d0			; 12	; and with object flags
		jmp	.table(pc,d0.w)			; 14+10	; jump to flip routine
; --------------------------------------------------------------

.table
		bra.w	ProcMapObjNoflip		; $00	; no flipping
		bra.w	ProcMapObjXflip			; $04	; x-flipping
		bra.w	ProcMapObjYflip			; $08	; y-flipping
		bra.w	ProcMapObjXYflip		; $0C	; xy-flipping
; ==============================================================
; --------------------------------------------------------------
; Routine to convert object mappings to sprites with no flipping
;
; input:
;   d0 = $00000000
;   d1 = x-pos
;   d2 = y-pos
;   d3 = tile pattern
;   d6 = link value
;   d7 = sprite pieces left
;   a0 = sprite table address
;   a1 = object address
;   a3 = mappings address
;
; out:
;   mi = end token was used
;   pl = ran out of sprite pieces
;
; thrash: d3-d4
; --------------------------------------------------------------

ProcMapObjNoflip:
		swap	d3				; 4	; swap tile pattern to high word
		move.w	d1,d3				; 4	; load x-pos to low word

.loop		; 1 loop = 98 to 100 cycles
		move.l	(a3)+,d4			; 12	; load y-pos, size and link data to d4
		add.w	d2,d4				; 4	; add y-pos to low word
		swap	d4				; 4	; swap words

		addq.b	#1,d6				; 4	; increment link value
		move.b	d6,d4				; 4	; save link value to data
		move.l	d4,(a0)+			; 12	; send to sprite table
; --------------------------------------------------------------

		move.l	(a3)+,d4			; 12	; load x-pos and pattern data to d4
		swap	d4				; 4	; swap words
		add.l	d3,d4				; 8	; add tile pattern and x-pos to d4
		move.l	d4,(a0)+			; 12	; send to sprite table
; --------------------------------------------------------------

		tst.b	-7(a3)				; 12	; check if end token was set
		dbmi	d7,.loop			; 10-14	; if not and more sprite pieces exist, loop
		rts					; 16	; mi = end token was used
; ==============================================================
; --------------------------------------------------------------
; Routine to convert object mappings to sprites with y-flipping
;
; input:
;   d0 = $0000000C
;   d1 = x-pos
;   d2 = y-pos
;   d3 = tile pattern
;   d6 = link value
;   d7 = sprite pieces left
;   a0 = sprite table address
;   a1 = object address
;   a3 = mappings address
;
; out:
;   mi = end token was used
;   pl = ran out of sprite pieces
;
; thrash: d0-d5
; --------------------------------------------------------------

ProcMapObjYflip:
		swap	d3				; 4	; swap tile pattern to high word
		move.w	d1,d3				; 4	; load x-pos to low word
		move.w	#$1000,d0			; 8	; prepare flip value to d0

.loop		; 1 loop = 140-142 cycles
		moveq	#$F,d5				; 4	; prepare value to d5
		and.b	(a3),d5				; 8	; and the sprite size data with d5
		add.w	d5,d5				; 4	; double it
; --------------------------------------------------------------

		move.l	(a3)+,d4			; 12	; load y-pos, size and link data to d4
		neg.w	d4				; 4	; negate y-offfset
		sub.w	ProcMapYflipTbl(pc,d5.w),d4	; 14	; add the y-flip table offset to d4
		add.w	d2,d4				; 4	; add y-pos to low word
		swap	d4				; 4	; swap words

		addq.b	#1,d6				; 4	; increment link value
		move.b	d6,d4				; 4	; save link value to data
		move.l	d4,(a0)+			; 12	; send to sprite table
; --------------------------------------------------------------

		move.l	(a3)+,d4			; 12	; load x-pos and pattern data to d4
		eor.w	d0,d4				; 8	; eor with flip value
		swap	d4				; 4	; swap words
		add.l	d3,d4				; 8	; add tile pattern and x-pos to d4
		move.l	d4,(a0)+			; 12	; send to sprite table
; --------------------------------------------------------------

		tst.b	-7(a3)				; 12	; check if end token was set
		dbmi	d7,.loop			; 10-14	; if not and more sprite pieces exist, loop
		rts					; 16	; mi = end token was used
; ==============================================================
; --------------------------------------------------------------
; Table of offsets for the y-flip table
; --------------------------------------------------------------

ProcMapYflipTbl:
		dc.w $0008,$0010,$0018,$0020		; $00	; sequence of 1 tile, 2 tiles, 3 tiles, 4 tiles, 1 tile ...
		dc.w $0008,$0010,$0018,$0020		; $04
		dc.w $0008,$0010,$0018,$0020		; $08
		dc.w $0008,$0010,$0018,$0020		; $0C
; ==============================================================
; --------------------------------------------------------------
; Routine to convert object mappings to sprites with xy-flipping
;
; input:
;   d0 = $0000000C
;   d1 = x-pos
;   d2 = y-pos
;   d3 = tile pattern
;   d6 = link value
;   d7 = sprite pieces left
;   a0 = sprite table address
;   a1 = object address
;   a3 = mappings address
;
; out:
;   mi = end token was used
;   pl = ran out of sprite pieces
;
; thrash: d0-d5
; --------------------------------------------------------------

ProcMapObjXYflip:
		move.w	#$1800,d0			; 8	; prepare flip value to d0

.loop		; 1 loop = 162-164 cycles
		moveq	#$F,d5				; 4	; prepare value to d5
		and.b	(a3),d5				; 8	; and the sprite size data with d5
		add.w	d5,d5				; 4	; double it
; --------------------------------------------------------------

		move.l	(a3)+,d4			; 12	; load y-pos, size and link data to d4
		neg.w	d4				; 4	; negate y-offfset
		sub.w	ProcMapYflipTbl(pc,d5.w),d4	; 14	; add the y-flip table offset to d4
		add.w	d2,d4				; 4	; add y-pos to low word
		swap	d4				; 4	; swap words

		addq.b	#1,d6				; 4	; increment link value
		move.b	d6,d4				; 4	; save link value to data
		move.l	d4,(a0)+			; 12	; send to sprite table
; --------------------------------------------------------------

		move.l	(a3)+,d4			; 12	; load x-pos and pattern data to d4
		eor.w	d0,d4				; 8	; eor with flip value
		add.w	d3,d4				; 4	; add tile pattern to d4
		swap	d4				; 4	; swap words

		neg.w	d4				; 4	; negate x-offfset
		sub.w	ProcMapXflipTbl(pc,d5.w),d4	; 14	; add the x-flip table offset to d4
		add.w	d1,d4				; 4	; add x-pos to d4
		move.l	d4,(a0)+			; 12	; send to sprite table
; --------------------------------------------------------------

		tst.b	-7(a3)				; 12	; check if end token was set
		dbmi	d7,.loop			; 10-14	; if not and more sprite pieces exist, loop
		rts					; 16	; mi = end token was used
; ==============================================================
; --------------------------------------------------------------
; Table of offsets for the x-flip table
; --------------------------------------------------------------

ProcMapXflipTbl:
		dcb.w 4,$0008				; $00	; width = 1 tile
		dcb.w 4,$0010				; $04	; width = 2 tiles
		dcb.w 4,$0018				; $08	; width = 3 tiles
		dcb.w 4,$0020				; $0C	; width = 4 tiles
; ==============================================================
; --------------------------------------------------------------
; Routine to convert object mappings to sprites with x-flipping
;
; input:
;   d0 = $00000004
;   d1 = x-pos
;   d2 = y-pos
;   d3 = tile pattern
;   d6 = link value
;   d7 = sprite pieces left
;   a0 = sprite table address
;   a1 = object address
;   a3 = mappings address
;
; out:
;   mi = end token was used
;   pl = ran out of sprite pieces
;
; thrash: d0-d5
; --------------------------------------------------------------

ProcMapObjXflip:
		move.w	#$800,d0			; 8	; prepare flip value to d0

.loop		; 1 loop = 140-142 cycles
		moveq	#$F,d5				; 4	; prepare value to d5
		and.b	(a3),d5				; 8	; and the sprite size data with d5
		add.w	d5,d5				; 4	; double it
; --------------------------------------------------------------

		move.l	(a3)+,d4			; 12	; load y-pos, size and link data to d4
		add.w	d2,d4				; 4	; add y-pos to low word
		swap	d4				; 4	; swap words

		addq.b	#1,d6				; 4	; increment link value
		move.b	d6,d4				; 4	; save link value to data
		move.l	d4,(a0)+			; 12	; send to sprite table
; --------------------------------------------------------------

		move.l	(a3)+,d4			; 12	; load x-pos and pattern data to d4
		eor.w	d0,d4				; 8	; eor with flip value
		add.w	d3,d4				; 4	; add tile pattern to d4
		swap	d4				; 4	; swap words

		neg.w	d4				; 4	; negate x-offfset
		sub.w	ProcMapXflipTbl(pc,d5.w),d4	; 14	; add the x-flip table offset to d4
		add.w	d1,d4				; 4	; add x-pos to d4
		move.l	d4,(a0)+			; 12	; send to sprite table
; --------------------------------------------------------------

		tst.b	-7(a3)				; 12	; check if end token was set
		dbmi	d7,.loop			; 10-14	; if not and more sprite pieces exist, loop
		rts					; 16	; mi = end token was used
