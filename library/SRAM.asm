; ==============================================================
; --------------------------------------------------------------
; SRAM variables table
; --------------------------------------------------------------

SRAM_Toggle =		$A130F1					; the address that is used to toggle SRAM
SRAM =			$200000
sInitDef =		"SRAM"					; default init value

	rsreset
sChecksum		rs.w 1					; SRAM checksum
sInitVal		rs.l 1					; init value (redundancy)
sData			rs.w 0					; address of the user data
sLevel			rs.w 1					; current level
sSize			rs.w 0					; size of SRAM (word align)
; ==============================================================
; --------------------------------------------------------------
; SRAM load function
; --------------------------------------------------------------

SRAM_Load:
		move.b	#1,SRAM_Toggle				; enable sram

		lea	SRAM+2+(sSize*0),a1			; load SRAM mirror 1 to a1
		bsr.s	.validate				; check if this is a valid SRAM
		beq.s	.load					; branch if yes

		lea	SRAM+2+(sSize*1),a1			; load SRAM mirror 2 to a1
		bsr.s	.validate				; check if this is a valid SRAM
		beq.s	.load					; branch if yes

		lea	SRAM+2+(sSize*2),a1			; load SRAM mirror 3 to a1
		bsr.s	.validate				; check if this is a valid SRAM
		bne.w	SRAM_Reset				; branch if not
; --------------------------------------------------------------

.load
		add.w	#sData,a1				; skip straight to user data

	;	move.w	(a1)+,v_level.w				; sLevel -> level+act

		move.b	#0,SRAM_Toggle				; disable sram
		rts
; ==============================================================
; --------------------------------------------------------------
; Validate SRAM data
; --------------------------------------------------------------

.validate
		move.l	a1,a0					; copy SRAM to a0
		move.w	(a0),d0					; load checksum to d0
		bsr.s	SRAM_Checksum				; validate checksum

		cmp.w	d0,d1					; check if checksum matches
		rts
; ==============================================================
; --------------------------------------------------------------
; Calculate checksum for SRAM
; --------------------------------------------------------------

SRAM_Checksum:
		moveq	#$42,d1					; prepare a random init value (avoid 0 and $FF)
		moveq	#(sSize-2)/2-1,d2			; load word count to d2
		addq.w	#2,a0					; skip over checksum in data

.loop
		sub.w	(a0)+,d1				; subtract the next word from counter
		ror.w	#2,d1					; rotate right by 2 bits
		dbf	d2,.loop				; loop for every word
		rts
; ==============================================================
; --------------------------------------------------------------
; SRAM save function
; --------------------------------------------------------------

SRAM_Write	macro	dat
		move.\0	\dat,(a1)+				; write to SRAM mirror 1
		move.\0	\dat,(a2)+				; write to SRAM mirror 2
		move.\0	\dat,(a3)+				; write to SRAM mirror 3
    endm
; --------------------------------------------------------------

SRAM_Save:
		move.b	#1,SRAM_Toggle				; enable sram

		lea	SRAM+sData+(sSize*0),a1			; load SRAM mirror 1 (skip header)
		lea	SRAM+sData+(sSize*1),a2			; load SRAM mirror 2 (skip header)
		lea	SRAM+sData+(sSize*2),a3			; load SRAM mirror 3 (skip header)
		movem.l	a1-a3,-(sp)				; store SRAM mirrors in stack
; --------------------------------------------------------------

;	SRAM_Write.w	v_level.w				; level+act -> sLevel
; --------------------------------------------------------------

		moveq	#3-1,d0					; do 3 mirrors

.checksum
		move.l	(sp)+,a0				; load mirror from stack to a0
		subq.w	#sData,a0				; subtract the header address from it
		move.l	a0,a1					; copy the address to a1

		jsr	SRAM_Checksum(pc)			; calculate checksum
		move.w	d1,(a1)					; update checksum
		dbf	d0,.checksum				; repeat for all mirrors
; --------------------------------------------------------------

		move.b	#0,SRAM_Toggle				; disable sram
		rts
; ==============================================================
; --------------------------------------------------------------
; SRAM reset function
; --------------------------------------------------------------

SRAM_Reset:
		move.b	#1,SRAM_Toggle				; enable sram
		lea	SRAM_Default(pc),a0			; load default SRAM data to a0

		lea	SRAM+2+(sSize*0),a1			; load SRAM mirror 1 (skip checksum)
		lea	SRAM+2+(sSize*1),a2			; load SRAM mirror 2 (skip checksum)
		lea	SRAM+2+(sSize*2),a3			; load SRAM mirror 3 (skip checksum)
		movem.l	a1-a3,-(sp)				; store SRAM mirrors in stack
; --------------------------------------------------------------

		moveq	#(sSize-2)/2-1,d0			; load repeat count to d0

.word
		move.w	(a0),(a1)+				; copy word to mirror 1
		move.w	(a0),(a2)+				; copy word to mirror 2
		move.w	(a0)+,(a3)+				; copy word to mirror 3
		dbf	d0,.word				; loop until done
; --------------------------------------------------------------

		moveq	#3-1,d0					; do 3 mirrors

.checksum
		move.l	(sp)+,a0				; load mirror from stack to a0
		subq.w	#2,a0					; subtract the checksum address from it
		move.l	a0,a1					; copy the address to a1

		jsr	SRAM_Checksum(pc)			; calculate checksum
		move.w	d1,(a1)					; update checksum
		dbf	d0,.checksum				; repeat for all mirrors
; --------------------------------------------------------------

		move.b	#0,SRAM_Toggle				; disable sram
		rts
; ==============================================================
; --------------------------------------------------------------
; Default values for all SRAM entries
; --------------------------------------------------------------

SRAM_Default:
		dc.l sInitDef					; set init value
		dc.w 0						; GHZ act 1
		dc.l 0						; score set to 0
		dc.b 0, 0					; lives and emeralds to 0
; ==============================================================
; --------------------------------------------------------------
; Check the code fits before 2MB mark
; --------------------------------------------------------------

	if $200000<=offset(*)
		inform 2,"SRAM functions are past the SRAM load area!"
	endif
