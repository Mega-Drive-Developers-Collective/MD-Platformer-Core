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

		lea	.test(pc),a3				; load object pointer to a3
		jsr	oLoadImportant.w			; load an important object
	RunObjects						; run all objects
		jsr	ProcAlloc				; update allocations

		move.w	TailNext.w,a0				; load first object slot into a0
		jsr	oDebug					; debug it nao
	vsync							; wait for the next frame
		bra.s	*
; --------------------------------------------------------------

.test
	oAttributes	.map, 1	, 0, 64, 16			; setup attributes
	oCreatePlat	.pmap, (1<<ptop) | (1<<plrb), 64, 16	; setup platform
	oCreateTouch	0, 0, 64, 16				; setup touch
	oCreateDynArt	.dart, .dmap, 8
		oNext						; run next object

.map
	dc.w 0

.pmap
	dc.w 0

.dart
	dc.w 0

.dmap
	dc.w 0
