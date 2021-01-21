; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2021/01
;
;   Animation routines
; --------------------------------------------------------------

	rsset $F0
ahold			rs.b 1					; hold animation in place
askip1			rs.b 1					; skip 1 byte
ajump			rs.b 1					; jump some bytes
aload			rs.b 1					; load a new animation
aact			rs.b 1					; increment act
asubact			rs.b 1					; increment subact
			rs.b 9					; unused
adelete			rs.b 1					; delete animation
; ==============================================================
; --------------------------------------------------------------
; Routine to initialize an animation with animation speed
;
; in:
;   d0 = animation ID
;   a0 = object
;   a2 = animation script
;
; thrash: d0-d1
; --------------------------------------------------------------

oAniStartSpeed:
		move.w	d0,d1					; copy animation number to d1
		add.w	d1,d1					; double d1
		add.w	d1,d1					; quadruple d1

		move.w	-4(a2,d1.w),d1				; load animation speed to d1
		move.w	d1,anispeed(a0)				; reset animation speed
		move.b	d1,aniacc(a0)				; set accumulator
; ==============================================================
; --------------------------------------------------------------
; Routine to initialize an animation without animation speed
;
; in:
;   d0 = animation ID
;   a0 = object
;
; thrash: d0-d1
; --------------------------------------------------------------

oAniStart:
		move.b	d0,ani(a0)				; set animation number
		clr.b	anioff(a0)				; clear animation offset

oAniStart_Rts:
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to run animation
;
; in:
;   a0 = object
;   a2 = animation script
;
; thrash: d0-d3/a2-a4
; --------------------------------------------------------------

oAnimate:
		moveq	#0,d0					; clear high byte
		move.b	ani(a0),d0				; load animation number to d0
		beq.s	oAniStart_Rts				; branch if 0

		add.w	d0,d0					; double d0
		add.w	d0,d0					; quadruple d0
		move.l	a2,a4					; copy animation script to a4
		add.w	-2(a4,d0.w),a4				; load animation data address to a4

		move.b	anioff(a0),d0				; load the animation offset to d0
		ext.w	d0					; extend offset to word
		add.w	d0,a4					; load the current script position
; --------------------------------------------------------------

		moveq	#0,d0
		move.b	aniacc(a0),d0				; load accumulator to d0
		add.w	anispeed(a0),d0				; add animation speed to d0
		move.b	d0,aniacc(a0)				; save accumulator back

		moveq	#0,d2					; clear upper byte of d2
		clr.b	d0					; clear the lower byte

		tst.w	d0					; check if animation moved
		beq.s	.rts					; branch if not
		bmi.s	.backwards				; do backwards processing
; --------------------------------------------------------------

	; forwards processor
		move.w	#$100,d1				; prepare offset to d1

.forwards
		addq.b	#1,anioff(a0)				; increment animation offset
		move.b	(a4)+,d2				; load the next byte in the script
		cmp.b	#$F0,d2					; check if this is a command
		blo.s	.nocom					; process forwards command if so

		lea	.fparam(pc),a3				; load forward param routine to a3
		add.b	d2,d2					; double the offset
		jsr	oAniCommands-$E0(pc,d2.w)		; run the commands processor
		bra.s	.forwards
; --------------------------------------------------------------

.nocom
		sub.w	d1,d0					; check if this is the desired frame
		bne.s	.forwards				; branch if not
		move.b	d2,frame(a0)				; save frame and exit

.rts
		rts
; --------------------------------------------------------------

.fparam
		addq.b	#1,anioff(a0)				; increment animation offset
		move.b	(a4)+,d3				; load the next byte to d2
		rts
; --------------------------------------------------------------

	; backwards processor
.bcom
		lea	.bparam(pc),a3				; load backward param routine to a3
		add.b	d2,d2					; double the offset
		jsr	oAniCommands-$E0(pc,d2.w)		; run the commands processor
; --------------------------------------------------------------

.bck
		subq.b	#1,anioff(a0)				; decrement animation offset
		move.b	(a4),d2					; load the prev byte in the script
		subq.w	#1,a4					; decrement the offset

		cmp.b	#$F0,d2					; check if this is a command
		bhi.s	.bcom					; process forwards command if so

		sub.w	d1,d0					; check if this is the desired frame
		bne.s	.bck					; branch if not
		move.b	d2,frame(a0)				; save frame and exit
		rts
; --------------------------------------------------------------

.backwards
		move.w	#-$100,d1				; prepare offset to d1
		bra.s	.bck
; --------------------------------------------------------------

.bparam
		subq.b	#1,anioff(a0)				; increment animation offset
		move.b	(a4),d3					; load the prev byte to d2
		subq.w	#1,a4					; decrement the offset
		rts
; ==============================================================
; --------------------------------------------------------------
; Animation load new command
; --------------------------------------------------------------

oAniLoad:
		jsr	(a3)					; get the next param to d3
		moveq	#0,d0					; clear d0
		move.b	d3,d0					; load param as animation number
		jsr	oAniStartSpeed(pc)			; initialize animation
		jmp	oAnimate(pc)				; run animation processor again
; ==============================================================
; --------------------------------------------------------------
; Animation hold command
; forces the frame to stay as the next frame
; --------------------------------------------------------------

oAniHold:
		clr.w	d0					; force the remaining amount as 0
		clr.w	d1					; also force the offset as 0. Yank.
		rts
; ==============================================================
; --------------------------------------------------------------
; Animation skip 1 byte command
; --------------------------------------------------------------

oAniSkip1:
		moveq	#1,d3					; skip 1 byte
		bra.s	oAniAddOff				; jump offset
; ==============================================================
; --------------------------------------------------------------
; Animation jump command
; changes the animation offset by the specified amount
; --------------------------------------------------------------

oAniJump:
		jsr	(a3)					; get the next param to d3
		ext.w	d3					; extend to word

oAniAddOff:
		tst.w	d1					; check if going backwards
		bpl.s	.fwd					; branch if not
		neg.w	d3					; negate offset

.fwd
		add.w	d3,a4					; offset the script
		add.b	d3,anioff(a0)				; offset the animation too

oAniNull:
		rts
; ==============================================================
; --------------------------------------------------------------
; Animation increment act command
; --------------------------------------------------------------

oAniAct:
		addq.b	#2,act(a0)				; increment act routine
		jmp	(a3)					; skip a byte
; ==============================================================
; --------------------------------------------------------------
; Animation increment subact command
; --------------------------------------------------------------

oAniSubact:
		addq.b	#2,subact(a0)				; increment subact routine
		jmp	(a3)					; skip a byte
; --------------------------------------------------------------

	dcb.b	6,$FF						; this will allow the code above to work
oAniCommands:
		bra.s	oAniHold			; $F0	; Animation hold command
		bra.s	oAniSkip1			; $F1	; Animation skip 1 byte
		bra.s	oAniJump			; $F2	; Animation jump command
		bra.s	oAniLoad			; $F3	; Animation load new command
		bra.s	oAniAct				; $F4	; Animation increment act command
		bra.s	oAniSubact			; $F5	; Animation increment subact command
		bra.s	oAniNull			; $F6	; null
		bra.s	oAniNull			; $F7	; null
		bra.s	oAniNull			; $F8	; null
		bra.s	oAniNull			; $F9	; null
		bra.s	oAniNull			; $FA	; null
		bra.s	oAniNull			; $FB	; null
		bra.s	oAniNull			; $FC	; null
		bra.s	oAniNull			; $FD	; null
		bra.s	oAniNull			; $FE	; null
;		bra.s	oAniDelete			; $FF	; Animation delete command
; ==============================================================
; --------------------------------------------------------------
; Animation delete command
; --------------------------------------------------------------

		addq.w	#4,sp					; do not return
		jmp	oDelete.w				; delete safely
; --------------------------------------------------------------
