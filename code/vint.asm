; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2020/12
;
;   Main vertical interrupt handlers
; --------------------------------------------------------------

; ==============================================================
; --------------------------------------------------------------
; Main V-int handler
; --------------------------------------------------------------

Vint_Main:
		movem.l	d0-a5,-(sp)				; push all registers (except a6)

.wait
		moveq	#8,d0					; prepare mask to d0
		and.w	(a6),d0					; check if vertical blanking is taking place
		beq.s	.wait					; if not, branch

		moveq	#$7C,d0					; load routine mask to d0, prevent invalid offsets
		and.b	VintRoutine.w,d0			; AND v-int routine counter with d0
		move.l	.routines(pc,d0.w),a0			; load routine address to a0
		jsr	(a0)					; run specific routine

		addq.l	#1,VintCount.w				; increment v-int counter
		movem.l	(sp)+,d0-a5				; pop all registers
		rte
; --------------------------------------------------------------

.routines
		dc.l irNull					; $00: routine that does nothing
		dc.l irScreen					; $04: routine for screen modes
; ==============================================================
; --------------------------------------------------------------
; V-int routine: Screens
; --------------------------------------------------------------

irScreen:
	dma	VscrollTable, 0, 20*4, VSRAM			; DMA vscroll table to VSRAM
	dma	HscrollTable, vHscroll, 224*4, VRAM		; DMA hscroll table to VRAM
	dma	SpriteTable, vSprites, 80*8, VRAM		; DMA sprite table to VRAM
		jsr	dmaQueueProcess				; process the DMA queue
		jsr	pRead					; read pad data
; ==============================================================
; --------------------------------------------------------------
; V-int routine: Null (do nothing)
; --------------------------------------------------------------

irNull:
		rts
