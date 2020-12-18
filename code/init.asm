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
; Hardware startup routine
; --------------------------------------------------------------

Init:
		tst.l	($A10008).l				; test port A and B control
		bne.s	.aok
		tst.w	($A1000C).l				; test port C control

.aok
		bne.s	.finish
		lea	SetupValues(pc),a5
		movem.w	(a5)+,d5-d7
		movem.l	(a5)+,a0-a4
; --------------------------------------------------------------

		move.b	-$10FF(a1),d0				; get hardware version
		andi.b	#$F,d0
		beq.s	.skipsecurity
		move.l	$100.w,$2F00(a1)

.skipsecurity
		move.w	(a4),d0					; check	if VDP works
		moveq	#0,d0
		movea.l	d0,a6
		move.l	a6,usp					; set usp to $0
; --------------------------------------------------------------

		moveq	#$18-1,d1

.vdp
		move.b	(a5)+,d5				; add $8000 to value
		move.w	d5,(a4)					; move value to	VDP register
		add.w	d7,d5					; next register
		dbf	d1,.vdp

		move.l	(a5)+,(a4)
		move.w	d0,(a3)					; clear	the screen
; --------------------------------------------------------------

		move.w	d7,(a1)					; stop the Z80
		move.w	d7,(a2)					; reset	the Z80

.waitz80
		btst	d0,(a1)					; has the Z80 stopped?
		bne.s	.waitz80				; if not, branch
		moveq	#$26-1,d2

.z80
		move.b	(a5)+,(a0)+
		dbf	d2,.z80
		move.w	d0,(a2)
		move.w	d0,(a1)					; start	the Z80
		move.w	d7,(a2)					; reset	the Z80
; --------------------------------------------------------------

.ram
		move.l	d0,-(a6)
		dbf	d6,.ram					; clear	the entire RAM
; --------------------------------------------------------------

		move.l	(a5)+,(a4)				; set VDP display mode and increment
		move.l	(a5)+,(a4)				; set VDP to CRAM write
		moveq	#$20-1,d3

.cram
		move.l	d0,(a3)
		dbf	d3,.cram				; clear	the CRAM
; --------------------------------------------------------------

		move.l	(a5)+,(a4)
		moveq	#$14-1,d4

.registers
		move.l	d0,(a3)
		dbf	d4,.registers
; --------------------------------------------------------------

		moveq	#4-1,d5

.psg
		move.b	(a5)+,$11(a3)				; reset	the PSG
		dbf	d5,.psg
		move.w	d0,(a2)

; --------------------------------------------------------------
		movem.l	(a6),d0-a6				; clear	all registers
		move	#$2700,sr				; set the sr

.finish
		bra.s	SoftInit
; --------------------------------------------------------------

SetupValues:	dc.w $8000					; VDP register start number
		dc.w $3FFF					; size of RAM/4
		dc.w $100					; VDP register diff

		dc.l $A00000					; start	of Z80 RAM
		dc.l $A11100					; Z80 bus request
		dc.l $A11200					; Z80 reset
		dc.l $C00000					; VDP data
		dc.l $C00004					; VDP control

		dc.b 4						; VDP $80 - 8-colour mode
		dc.b $14					; VDP $81 - Megadrive mode, DMA enable
		dc.b ($C000>>10)				; VDP $82 - foreground nametable address
		dc.b ($F000>>10)				; VDP $83 - window nametable address
		dc.b ($E000>>13)				; VDP $84 - background nametable address
		dc.b ($D800>>9)					; VDP $85 - sprite table address
		dc.b 0						; VDP $86 - unused
		dc.b 0						; VDP $87 - background colour
		dc.b 0						; VDP $88 - unused
		dc.b 0						; VDP $89 - unused
		dc.b 255					; VDP $8A - HBlank register
		dc.b 0						; VDP $8B - full screen scroll
		dc.b $81					; VDP $8C - 40 cell display
		dc.b ($DC00>>10)				; VDP $8D - hscroll table address
		dc.b 0						; VDP $8E - unused
		dc.b 1						; VDP $8F - VDP increment
		dc.b 1						; VDP $90 - 64 cell hscroll size
		dc.b 0						; VDP $91 - window h position
		dc.b 0						; VDP $92 - window v position
		dc.w $FFFF					; VDP $93/94 - DMA length
		dc.w 0						; VDP $95/96 - DMA source
		dc.b $80					; VDP $97 - DMA fill VRAM
		dc.l $40000080					; VRAM address 0

		dc.b $AF					; xor	a
		dc.b $01, $D9, $1F				; ld	bc,1fd9h
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
		dc.b $36, $E9					; ld	(hl),e9h
		dc.b $E9					; jp	(hl)

		dc.w $8104					; VDP display mode
		dc.w $8F02					; VDP increment
		dc.l $C0000000					; CRAM write mode
		dc.l $40000010					; VSRAM address 0

		dc.b $9F, $BF, $DF, $FF				; values for PSG channel volumes
; ==============================================================
; --------------------------------------------------------------
; Software startup routine
; --------------------------------------------------------------

SoftInit:
		move	#$2F00,sr				; we DO NOT want interrupts while we do this
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
		clr.l	d0					; clear d0-d7
		clr.l	d1
		clr.l	d2
		clr.l	d3
		clr.l	d4
		clr.l	d5
		clr.l	d6
		clr.l	d7
		move.l	d1,a0					; clear a0-a6
		move.l	d2,a1
		move.l	d3,a2
		move.l	d4,a3
		move.l	d5,a4
		move.l	d6,a5
		move.l	d7,a6
; --------------------------------------------------------------

	; clear entire RAM
		lea	0.w,sp					; load end of RAM to sp

.clearloop
		movem.l	d0-a6,-(sp)				; clear 56 ($38) bytes of RAM
		movem.l	d0-a6,-(sp)				; clear 56 ($38) bytes of RAM
		movem.l	d0-a6,-(sp)				; clear 56 ($38) bytes of RAM
		movem.l	d0-a6,-(sp)				; clear 56 ($38) bytes of RAM
		movem.l	d0-d7,-(sp)				; clear 32 ($20) bytes of RAM

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
		dc.l gmTest
; --------------------------------------------------------------

gmTest:
		move.b	#4,VintRoutine.w			; enable screen v-int routine
	vsync							; wait for the next frame
		bra.s	*
