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
	; load test palette
	dma	Test_Pal, 0, 32*2, CRAM				; DMA test palette to CRAM


		move.b	#4,VintRoutine.w			; enable screen v-int routine
		jsr	oInitializeAll				; initialize all objects
		jsr	dmaQueueInit				; initialize DMA queue
		move.w	#$8174,(a6)				; enable ints

		lea	.test(pc),a3				; load object pointer to a3
		jsr	oLoadImportant.w			; load an important object

.proc
	RunObjects						; run all objects
		jsr	ProcAlloc				; update allocations
		jsr	ProcMaps				; update sprite table

	vsync							; wait for the next frame
		bra.s	.proc					; infinite loop
; --------------------------------------------------------------

.test
	oAttributes	Test_Map, 1, 0, 64, 16			; setup attributes
	oCreatePlat	Test_Pmap, (1<<pactive) | (1<<ptop) | (1<<plrb), 64, 16; setup platform
	oCreateTouch	0, 0, 64, 16				; setup touch
	oCreateDynArt	Test_Art, Test_Dmap, 8			; setup dynamic art
	oAddDisplay	2, a0, a1, 1				; enable display

		move.w	#150,xpos(a0)				; x-pos vaguely in the screen centre
		move.w	#100,ypos(a0)				; y-pos vaguely in the screen centre
		move.l	#.loop,(a0)				; set new routine
; --------------------------------------------------------------

.loop
		subq.b	#1,exram(a0)				; decrease counter
		bcc.s	.next					; branch if no underflow
		addq.b	#1,frame(a0)				; go to next frame
		move.b	#8-1,exram(a0)				; set delay

		cmp.b	#250,frame(a0)				; check max frame
		bls.s	.next					; branch if not reached
		move.b	#1,frame(a0)				; skip null frame

.next
		oNext						; run next object
; --------------------------------------------------------------

Test_Pmap:	dc.w 0						; platform mappings
Test_Map:	include	"screens/test/sonic/sprite.map"		; test (Sonic) sprite mappings
Test_Dmap:	include	"screens/test/sonic/dyn.map"		; test (Sonic) dynamic mappings
	incdma	Test_Art, "screens/test/sonic/art.unc"		; test (Sonic) art
	incdma	Test_Pal, "screens/test/sonic/test.pal"		; test (Sonic&Tails) palette
; --------------------------------------------------------------

