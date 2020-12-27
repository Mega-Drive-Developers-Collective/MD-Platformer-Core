; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2020/12
;
;   Software & hardware initialization and main software loop
; --------------------------------------------------------------

; ==============================================================
; --------------------------------------------------------------
; Hardware initialization data
; --------------------------------------------------------------

InitData:
		dc.w .zdataend-.zdatastart-1		; d0	; driver length
		dc.w $100				; d1	; value for Z80 reset
		dc.w $40				; d2	; value for enabling pads
		dc.w .endregs-.regs-1			; d3	; VDP registers list
		dc.w $8000				; d4	; VDP register increment
		dc.w 16*4/2				; d5	; number of colors to clear
		dc.w 20					; d6	; number of scroll positions to clear
		dc.w VDP_PSG-VDP_Data			; d7	; offset for a5 later on

	; z80 sound driver data
.zdatastart
		dc.b $AF					; xor	a
		dc.b $01, $D9, $1F				; ld	bc,1FD9h
		dc.b $11, $27, $00				; ld	de,0027h
		dc.b $21, $26, $00				; ld	hl,0026h
		dc.b $F9					; ld	sp,hl
		dc.b $77					; ld	(hl),a
		dc.b $ED, $B0					; ldir
		dc.b $DD, $E1					; pop	ix
		dc.b $FD, $E1					; pop	iy
		dc.b $ED, $47					; ld	i,a
		dc.b $ED, $4F					; ld	r,a
		dc.b $D1					; pop	de
		dc.b $E1					; pop	hl
		dc.b $F1					; pop	af
		dc.b $08					; ex	af,af'
		dc.b $D9					; exx
		dc.b $C1					; pop	bc
		dc.b $D1					; pop	de
		dc.b $E1					; pop	hl
		dc.b $F1					; pop	af
		dc.b $F9					; ld	sp,hl
		dc.b $F3					; di
		dc.b $ED, $56					; im	1
		dc.b $36, $E9					; ld	(hl),E9h
		dc.b $E9					; jp	(hl)
	even
.zdataend

	; VDP register dump
.regs
		dc.b $04				; $80	; 8-colour mode
		dc.b $14				; $81	; enable DMA and MD mode
		dc.b (vPlaneA >> 10)			; $82	; plane A address
		dc.b (vWindow >> 10)			; $83	; window plane address
		dc.b (vPlaneB >> 13)			; $84	; plane B address
		dc.b (vSprites >> 9)			; $85	; sprite table address
		dc.b $00				; $86	; use lower 64k VRAM for sprites
		dc.b $00				; $87	; background colour line 0 index 0
		dc.b $00				; $88	; unused
		dc.b $00				; $89	; unused
		dc.b $FF				; $8A	; h-int line count
		dc.b $08				; $8B	; line hscroll, 2 tile vscroll
		dc.b $81				; $8C	; 40 tile display, no S/H
		dc.b (vHscroll >> 10)			; $8D	; hscroll table address
		dc.b $00				; $8E	; use lower 64k VRAM for planes
		dc.b $02				; $8F	; auto-increment
		dc.b $01				; $90	; 64x32 tile plane size
		dc.b $00				; $91	; window horizontal size
		dc.b $00				; $92	; window vertical size
		dc.b $00				; $93	; filler
.endregs

	vdp	dc.l,0,CRAM,WRITE				; CRAM WRITE to 0
	vdp	dc.l,0,VSRAM,WRITE				; VSRAM WRITE to 0
		dc.b $9F, $BF, $DF, $FF				; PSG volume commands
; ==============================================================
; --------------------------------------------------------------
; Hardware startup routine
; --------------------------------------------------------------

Init:
		move	#$2F00,sr				; disable interrupts
		move.l	hVDP_Control.w,a6			; load VDP control port to a6

		tst.l	PAD_Control1-1				; test port A and B control
		bne.s	.aok					; if enabled, branch
		tst.w	PAD_ControlX-1				; test port C control

.aok
		bne.w	SoftInit				; if enabled, branch
; --------------------------------------------------------------

		move.l	hZ80_Bus.w,a1				; load Z80 bus request address to a1
		moveq	#$F,d0					; prepare revision ID mask to d0
		and.b	HW_Version-Z80_Bus(a1),d0		; AND with actual revision ID
		beq.s	.rev0					; if 0, skip
		move.l	$100.w,HW_TMSS-Z80_Bus(a1)		; satistify TMSS
; --------------------------------------------------------------

.rev0
		move	(a6),ccr				; check if DMA is taking place and reset latch
		bvs.s	.rev0					; if yes, branch
	vdpfill	0, 0, $10000, 0					; fill entire VRAM with 0 but don't wait
; --------------------------------------------------------------

		move.l	EndOfROM.w,a0				; load ROM end address to a0
		sub.w	#56-1,a0				; this will trip the detection before ROM ends (in case it would happen mid-transfer)
		move.l	a0,usp					; store in usp

		move.l	CheckInit.w,d0				; load default checksum init value
		sub.l	Checksum(pc),d0				; remove the checksum from the equation
		lea	0.w,sp					; load start of ROM to sp
; --------------------------------------------------------------

.chkloop
		movem.l	(sp)+,d1-a6				; load 56 ($38) bytes from ROM
		add.l	d1,d0					; add all registers to d0
		add.l	d2,d0
		add.l	d3,d0
		add.l	d4,d0
		add.l	d5,d0
		add.l	d6,d0
		add.l	d7,d0

		add.l	a0,d0
		add.l	a1,d0
		add.l	a2,d0
		add.l	a3,d0
		add.l	a4,d0
		add.l	a5,d0
		add.l	a6,d0

		move.l	usp,a0					; get the end ROM address to a0
		cmp.l	sp,a0					; check if we have passed the address
;		bhs.s	.chkloop				; if not, go back to loop
; --------------------------------------------------------------

		move.l	EndOfROM.w,a0				; load ROM end address to a0

.chkend
		add.w	(sp)+,d0				; add remaining words to d0
		cmp.l	sp,a0					; check if we have passed the address
;		bhs.s	.chkend					; if not, go back to loop
; --------------------------------------------------------------

		move.l	sp,d1					; copy sp to d1
		cmp.l	Checksum.w,d0				; check if the checksum matches
; TODO:		beq.s	.checksumok				; branch if checksum matches
;		lea	Stack.w,sp				; reset stack pointer
;	exception	exChecksum				; cheksum fuckup
; --------------------------------------------------------------

.checksumok
		movem.l	hInitAregs.w,a1-a6			; load initial register set to a1-a6
		lea	InitData(pc),a0				; load initialization data to a0
		movem.w	(a0)+,d0-d7				; load some register values

		move.b	d2,(a4)					; enable pad1
		move.b	d2,2(a4)				; enable pad2
		move.b	d2,4(a4)				; enable padex
; --------------------------------------------------------------

		move.w	d1,(a1)					; request Z80 bus
		move.w	d1,(a2)					; Z80 reset on

.waitz80
		btst	d1,(a1)					; check if the bus is free
		bne.s	.waitz80				; branch if not

.loadz80
		move.b	(a0)+,(a3)+				; copy driver to Z80 RAM
		dbf	d0,.loadz80				; loop for every byte
; --------------------------------------------------------------

		moveq	#0,d0					; clear d0
		move.w	d0,(a2)					; Z80 reset off
		move.w	d0,(a1)					; enable Z80
		move.w	d1,(a2)					; Z80 reset on
; --------------------------------------------------------------

.fill
		move	(a6),ccr				; check if DMA is taking place and reset latch
		bvs.s	.fill					; if yes, branch

.regs
		move.b	(a0)+,d4				; load next register value
		move.w	d4,(a6)					; send it to VDP control port
		add.w	d1,d4					; go to next register address
		dbf	d3,.regs				; loop for every register
; --------------------------------------------------------------

		move.l	(a0)+,(a6)				; load CRAM WRITE command to VDP

.cram
		move.l	d0,(a5)					; clear CRAM completely
		dbf	d5,.cram				; loop for every entry
; --------------------------------------------------------------

		move.l	(a0)+,(a6)				; load VSRAM WRITE command to VDP

.vsram
		move.l	d0,(a5)					; clear VSRAM completely
		dbf	d6,.vsram				; loop for every entry
; --------------------------------------------------------------

		add.w	d7,a5					; load PSG data port to a5
	rept 4
		move.b	(a0)+,(a5)				; mute PSG channel
	endr
; ==============================================================
; --------------------------------------------------------------
; Software startup routine
; --------------------------------------------------------------

SoftInit:
		moveq	#0,d0					; clear d0-d7
		move.l	d0,d1
		move.l	d1,d2
		move.l	d2,d3
		move.l	d3,d4
		move.l	d4,d5
		move.l	d5,d6
		move.l	d6,d7
		move.l	d7,a0					; clear a0-a5
		move.l	a0,a1
		move.l	a1,a2
		move.l	a2,a3
		move.l	a3,a4
		move.l	a4,a5
		move.l	a5,usp					; clear usp
; --------------------------------------------------------------

	; clear entire RAM
		lea	0.w,sp					; load end of RAM to sp

.clearloop
		movem.l	d0-a5,-(sp)				; clear 56 ($34) bytes of RAM
		movem.l	d0-a5,-(sp)				; clear 56 ($34) bytes of RAM
		movem.l	d0-a5,-(sp)				; clear 56 ($34) bytes of RAM
		movem.l	d0-a5,-(sp)				; clear 56 ($34) bytes of RAM
		movem.l	d0-a4,-(sp)				; clear 32 ($30) bytes of RAM

		cmp.l	#$FFFF0000,sp				; check if past end of RAM
		bhi.s	.clearloop				; if not, go back to loop
; --------------------------------------------------------------

	; reset RAM variables
		move.w	#$4E73,Hint.l				; rte
		move.w	#$4EF9,Vint.w				; jmp xxxxxx.l
		move.l	#Vint_Main,Vint+2.w			; v-int handler address
; ==============================================================
; --------------------------------------------------------------
; Main software loop
; --------------------------------------------------------------

.mode
		move.l	hVDP_Control.w,a6			; load VDP control port to a6
		lea	Stack.w,sp				; reset stack pointer

		moveq	#0,d0
		move.b	Gamemode.w,d0				; load game mode to d0
		move.l	.table(pc,d0.w),a0			; load game mode address to a0
		jsr	(a0)					; jump to the routine
		bra.s	.mode					; run the next mode
; --------------------------------------------------------------

.table
		dc.l gmTest				; $00	; test game mode
