; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2021/01
;
;   Library for handling floor and wall clipping for objects
; --------------------------------------------------------------

; ==============================================================
; --------------------------------------------------------------
; Routine to test clipping code
;
; in:
;   a0 = target object
;
; thrash: d0
; --------------------------------------------------------------

oClipTest:
		tst.w	xvel(a0)				; check if moving left
		bge.s	.nol					; branch if no
		tst.w	xpos(a0)				; check if to left
		bpl.s	.nol					; branch if no
		clr.w	xpos(a0)				; stop moving
		clr.w	xvel(a0)				;
; --------------------------------------------------------------

.nol
		tst.w	xvel(a0)				; check if moving left
		ble.s	.nor					; branch if no
		cmp.w	#320,xpos(a0)				; check if to left
		ble.s	.nor					; branch if no
		move.w	#320,xpos(a0)				; stop moving
		clr.w	xvel(a0)				;
; --------------------------------------------------------------

.nor
		tst.w	yvel(a0)				; check if moving down
		ble.s	.rts					; branch if no
		cmp.w	#200,ypos(a0)				; check if too low down
		ble.s	.rts					; branch if not
		move.w	#200,ypos(a0)				; stop moving
		clr.w	yvel(a0)				;
; --------------------------------------------------------------

.rts
		rts
