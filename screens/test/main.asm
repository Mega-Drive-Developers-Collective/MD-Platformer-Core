; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2020/12
;
;   Test game mode main code
; --------------------------------------------------------------

gmTest:
		move.b	#4,VintRoutine.w			; enable screen v-int routine
		jsr	oInitializeAll				; initialize all objects

	vsync							; wait for the next frame
		bra.s	*
