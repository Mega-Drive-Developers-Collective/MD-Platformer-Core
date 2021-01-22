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
; --------------------------------------------------------------

		tst.b	kosQueueLeft.w				; check if decompression was in progress
		bmi.s	.koschk					; branch if yes

.rte
		rte
; --------------------------------------------------------------

.routines
		dc.l irNull					; $00: routine that does nothing
		dc.l irScreen					; $04: routine for screen modes
; --------------------------------------------------------------

	; checks if we need to run special code
.koschk
		cmpi.l	#kosQueueProc_Start,2(sp)		; check if the code was after the start of the decompressor
		blo.s	.rte					; branch if not
		cmpi.l	#kosQueueProc_End,2(sp)			; check if the code was before the end of the decompressor
		bhs.s	.rte					; branch if not

		move	(sp),sr					; load the SR from from stack into sr
		move.w	(sp)+,kosSR.w				; get the SR from stack into RAM
		move.l	(sp)+,kosRoutine.w			; load the routine address from stack
		movem.w	d0-d6,kosRegisters.w			; save all the data registers
		movem.l	a0-a1/a5,kosRegisters+(2*7).w		; save all the address registers
		rts						; return the the routine before decompression
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
