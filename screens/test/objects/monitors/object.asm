; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2021/01
;
;   Monitor test object
; --------------------------------------------------------------

ObjMonitor:
	oAttributes	ObjMonitor_Map, 0, 0, 12, 16		; setup attributes
	oAddDisplay	3, a0, a1, 1				; enable display
	oCreatePlat	Test_Pmap, (1<<pactive) | (1<<ptop) | (1<<plrb), 12, 16; setup platform

		lea	ObjMonitor_Ani(pc),a2			; load animation script to a2
		moveq	#0,d0
		move.b	arg(a0),d0				; load animation from arg
		jsr	oAniStartSpeed				; start animation

		move.w	#240,xpos(a0)				; x-pos vaguely in the screen centre
		move.w	#0,ypos(a0)				; y-pos vaguely in the screen centre
		move.w	#(vMonitor / 32),tile(a0)		; set tile data
		move.l	#.act,(a0)				; set new routine
; --------------------------------------------------------------

.act
		jsr	oGravity				; deal with gravity
		jsr	oClipTest				; do clipping test

		lea	ObjMonitor_Ani(pc),a2			; load animation script to a2
		jsr	oAnimate				; run animation script
		oNext						; run next object
; --------------------------------------------------------------

ObjMonitor_Ani:	include	"screens/test/objects/monitors/sprite.ani"
ObjMonitor_Map:	include	"screens/test/objects/monitors/sprite.map"
