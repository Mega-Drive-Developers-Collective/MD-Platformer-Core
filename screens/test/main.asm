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
		st	pPoll.w					; init pads

		move.b	#4,VintRoutine.w			; enable screen v-int routine
		jsr	oInitializeAll				; initialize all objects
		jsr	dmaQueueInit				; initialize DMA queue
		move.w	#$8174,(a6)				; enable ints

		lea	ObjSonic(pc),a3				; load object pointer to a3
		jsr	oLoadImportant.w			; load an important object

.proc
	RunObjects						; run all objects
		jsr	ProcAlloc				; update allocations
		jsr	ProcMaps				; update sprite table
	vsync							; wait for the next frame
		bra.s	.proc					; infinite loop
; --------------------------------------------------------------

		include	"screens/test/objects/sonic/object.asm"
		include	"screens/test/objects/monitors/object.asm"
