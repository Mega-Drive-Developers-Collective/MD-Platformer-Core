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
	oAttributes	Test_Map, 1, 0, 64, 16			; setup attributes
;	oCreatePlat	Test_Pmap, (1<<pactive) | (1<<ptop) | (1<<plrb), 64, 16; setup platform
;	oCreateTouch	0, 0, 64, 16				; setup touch
	oCreateDynArt	Test_Art, Test_Dmap, 7			; setup dynamic art
	oAddDisplay	2, a0, a1, 1				; enable display

		lea	Test_Ani(pc),a2				; load animation script to a2
		moveq	#1,d0
		jsr	oAniStartSpeed				; start animation

		move.w	#150,xpos(a0)				; x-pos vaguely in the screen centre
		move.w	#100,ypos(a0)				; y-pos vaguely in the screen centre
		clr.w	xvel(a0)
		clr.w	yvel(a0)
		move.l	#.act,(a0)				; set new routine
; --------------------------------------------------------------

.act
		btst	#2,pHeld1A+1.w				; check if left is pressed
		beq.s	.nol					; branch if no
		sub.w	#$1C,xvel(a0)				; change velocity

.nol
		btst	#3,pHeld1A+1.w				; check if right is pressed
		beq.s	.nor					; branch if no
		add.w	#$1C,xvel(a0)				; change velocity

.nor
		btst	#6,pPress1A+1.w				; check if A is pressed
		beq.s	.noa					; branch if no
		move.w	#-$600,yvel(a0)				; change velocity

.noa
		jsr	oGravity				; deal with gravity
		jsr	oClipTest				; do clipping test

		move.w	xvel(a0),d0				; load x-velocity to d0
		beq.s	.abs					; branch if 0
		bclr	#xflip,flags(a0)			; face the normal way

		tst.w	d0					; check speed again
		bpl.s	.abs					; branch if positive
		neg.w	d0					; negate speed
		bset	#xflip,flags(a0)			; flip player

.abs
		lsr.w	#4,d0					; divide by 16
		move.w	d0,anispeed(a0)				; set animation speed

		lea	Test_Ani(pc),a2				; load animation script to a2
		jsr	oAnimate				; run animation script
		oNext						; run next object
; --------------------------------------------------------------

Test_Ani:	include	"screens/test/objects/sonic/sprite.ani"	; test (Sonic) animations
Test_Pmap:	dc.w 0						; platform mappings
Test_Map:	include	"screens/test/objects/sonic/sprite.map"	; test (Sonic) sprite mappings
Test_Dmap:	include	"screens/test/objects/sonic/dyn.map"	; test (Sonic) dynamic mappings
	incdma	Test_Art, "screens/test/objects/sonic/art.unc"	; test (Sonic) art
	incdma	Test_Pal, "screens/test/test.pal"		; test (Sonic&Tails) palette
; --------------------------------------------------------------
