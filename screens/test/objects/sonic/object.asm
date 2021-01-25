; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2021/01
;
;   Sonic test object
; --------------------------------------------------------------

ObjSonic:
	oAttributes	Test_Map, 1, 0, 13, 16			; setup attributes
;	oCreateTouch	0, 0, 64, 16				; setup touch
	oCreateDynArt	Test_Art, Test_Dmap, 7			; setup dynamic art
	oAddDisplay	2, a0, a1, 1				; enable display

		move.w	#150,xpos(a0)				; x-pos vaguely in the screen centre
		move.w	#100,ypos(a0)				; y-pos vaguely in the screen centre
		clr.w	xvel(a0)
		clr.w	yvel(a0)
		move.l	#.act,(a0)				; set new routine
; --------------------------------------------------------------

.act
		cmp.w	#200-1,ypos(a0)				; check if we're on floor
		blt.s	.chkspeed				; branch if not
		btst	#6,pPress1A+1.w				; check if A is pressed
		beq.s	.noa					; branch if no

		move.w	#-$680,yvel(a0)				; change velocity
		bra.s	.noa

.chkspeed
		btst	#6,pHeld1A+1.w				; check if A is held
		bne.s	.noa					; branch if yes

		move.w	#-$400,d0				; prepare max speed
		cmp.w	yvel(a0),d0				; check if moving upwards faster
		blt.s	.noa					; branch if not
		move.w	d0,yvel(a0)				; set y-velocity
; --------------------------------------------------------------

.noa
		moveq	#$08,d0					; set deceleration speed to d0
		btst	#2,pHeld1A+1.w				; check if left is pressed
		beq.s	.nol					; branch if no
		sub.w	#$1C,xvel(a0)				; change velocity
		moveq	#$00,d0					; no deceleration

.nol
		btst	#3,pHeld1A+1.w				; check if right is pressed
		beq.s	.nor					; branch if no
		add.w	#$1C,xvel(a0)				; change velocity
		moveq	#$00,d0					; no deceleration
; --------------------------------------------------------------

.nor
		tst.w	xvel(a0)				; check if moving
		beq.s	.nomove					; branch if not
		bmi.s	.neg					; branch if backwards

		sub.w	d0,xvel(a0)				; apply deceleration
		bcc.s	.nomove					; branch if no carry
		bra.s	.clr					; clear speed

.neg
		add.w	d0,xvel(a0)				; apply deceleration
		bcc.s	.nomove					; branch if no carry

.clr
		clr.w	xvel(a0)				; otherwise clear velocity
; --------------------------------------------------------------

.nomove
		jsr	platCheck				; do platform tests
		beq.s	.noplat					; branch if no collision
		add.w	d2,xpos(a0)				; offset position
		add.w	d3,ypos(a0)				; offset position

.noplat
		jsr	oGravity				; deal with gravity
		jsr	oClipTest				; do clipping test
; --------------------------------------------------------------

		lea	Test_Ani(pc),a2				; load animation script to a2
		move.w	xvel(a0),d1				; load x-velocity to d1
		beq.s	.abs					; branch if 0
		bclr	#xflip,flags(a0)			; face the normal way

		tst.w	d1					; check speed again
		bpl.s	.abs					; branch if positive
		neg.w	d1					; negate speed
		bset	#xflip,flags(a0)			; flip player

.abs
		cmp.w	#200-1,ypos(a0)				; check if we're on floor
		bge.s	.floor					; branch if yes
		moveq	#3,d0					; set rolling animation
		add.w	#$300,d1				; adjust
		bra.s	.walk
; --------------------------------------------------------------

.floor
		tst.w	d1					; check if we're moving
		beq.s	.stand					; branch if not

		moveq	#1,d0					; set walking animation to d0
		cmp.w	#$600,d1				; check if going fast
		blo.s	.walk					; branch if not

		moveq	#2,d0					; set running animation
		sub.w	#$100,d1				; adjust
; --------------------------------------------------------------

.walk
		cmp.b	ani(a0),d0				; check if ani number matches
		bne.s	.set					; branch if no

		lsr.w	#4,d1					; divide by 16
		move.w	d1,anispeed(a0)				; set animation speed
		bra.s	.animate
; --------------------------------------------------------------

.stand
		moveq	#4,d0					; set animation
		cmp.b	ani(a0),d0				; check if ani number matches
		beq.s	.animate				; branch if yes

.set
		move.b	d0,ani(a0)				; set animation
		jsr	oAniStartSpeed				; start animation

.animate
		jsr	oAnimate				; run animation script
		oNext						; run next object
; --------------------------------------------------------------

Test_Ani:	include	"screens/test/objects/sonic/sprite.ani"	; test (Sonic) animations
Test_Map:	include	"screens/test/objects/sonic/sprite.map"	; test (Sonic) sprite mappings
Test_Dmap:	include	"screens/test/objects/sonic/dyn.map"	; test (Sonic) dynamic mappings
Test_Art:	incdma	"screens/test/objects/sonic/art.unc"	; test (Sonic) art
Test_Pal:	incdma	"screens/test/test.pal"			; test (Sonic&Tails) palette
; --------------------------------------------------------------
