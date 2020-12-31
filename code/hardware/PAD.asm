; ==============================================================
; --------------------------------------------------------------
; Routine to read pad status into RAM
; --------------------------------------------------------------

pRead:
		tst.b	pPoll.w					; test poll stat
		bne.w	pInit					; if was set, poll controllers again

		lea	$A10003,a0				; load pad1 data to a0
		lea	pHeld1A.w,a1				; load pad1a buttons to a1
		lea	pMode1.w,a2				; load pad1 mode to a2

	if PAD_ENABLE_MULTI
		cmp.w	#$EAEA,(a2)				; Check if EA is active
		beq.w	pReadEA					; if so, branch
	endif

		bsr.s	.readpad				; read port 1 pads
		addq.w	#2,a0					; load pad2 data to a0
; ==============================================================
; --------------------------------------------------------------
; Figure out what type of pad we have to deal with
; --------------------------------------------------------------

.readpad
		move.b	(a2)+,d0				; load pad type to d0
		beq.s	.pad3					; read 3-button pad if 0
		subq.b	#2,d0					; check 6-button pad and mouse
		bcs.s	.pad6					; process pad6
		beq.s	.mouse					; process mouse

	if PAD_ENABLE_MULTI
		cmp.b	#$80-2,d0				; check if TeamPlayer
		beq.w	pReadTeamPlay				; branch if yes
	endif

		clr.l	(a1)+					; clear button data for all
		bra.w	.clear					; clear the rest
; ==============================================================
; --------------------------------------------------------------
; Read 3-button pad
; --------------------------------------------------------------

.pad3
		moveq	#0,d2					; load TH low to d2
		move.b	d2,(a0)					; TH LOW
		moveq	#1<<PAD_TH,d3				; load TH high to d3

		moveq	#(1<<PAD_TL)|(1<<PAD_TR),d0		; get only Start+A mask
		and.b	(a0),d0					; and with the buttons from pad
		move.b	d3,(a0)					; TH HIGH
		lsl.b	#2,d0					; shift into place

		moveq	#(1<<PAD_TL)|(1<<PAD_TR)|$F,d1		; get B+C+UDLR mask to d1
		and.b	(a0),d1					; and with the buttons from pad
		or.b	d1,d0					; fuse all buttons
		not.b	d0					; flip stats of buttons (1 is pressed as opposed to not pressed)
; --------------------------------------------------------------

		move.w	(a1),d1					; copy button presses for last frame
		eor.w	d0,d1					; enable newly held buttons
		move.w	d0,(a1)+				; save held buttons to RAM
		and.w	d0,d1					; remove held buttons from pressed buttons
		move.w	d1,(a1)+				; save as pressed buttons

	if PAD_ENABLE_MULTI
		rept 3
			clr.l	(a1)+				; clear button data for all
		endr
	endif
		rts
; ==============================================================
; --------------------------------------------------------------
; Read 6-button pad
; --------------------------------------------------------------

.pad6
		moveq	#1<<PAD_TH,d3				; load TH high to d3
		move.b	d3,(a0)					; TH HIGH
		moveq	#0,d2					; load TH low to d2
		moveq	#0,d0
		moveq	#0,d1

		move.b	(a0),d1					; read B+C+UDLR to d1
		move.b	d2,(a0)					; TH LOW
		and.b	#(1<<PAD_TL)|(1<<PAD_TR)|$F,d1		; get only those buttons

		move.b	(a0),d0					; read Start+A into d0
		move.b	d3,(a0)					; TH HIGH
		and.b	#(1<<PAD_TL)|(1<<PAD_TR),d0		; get only Start+A
		move.b	d2,(a0)					; TH LOW
		lsl.b	#2,d0					; shift buttons into place

		move.b	d3,(a0)					; TH HIGH
		or.l	d0,d1					; combine 3-button pad buttons into place already
		move.b	d2,(a0)					; TH LOW
	pad_delay8						;
		move.b	d3,(a0)					; TH HIGH
	pad_delay4						;

		moveq	#$F,d0					; prepare d0 with mask
		and.b	(a0),d0					; read the extra buttons
		lsl.w	#8,d0					; shift Mode+XYZ buttons up
		or.w	d1,d0					; fuse all buttons
		not.w	d0					; flip stats of buttons (1 is pressed as opposed to not pressed)
; --------------------------------------------------------------

		move.w	(a1),d1					; copy button presses for last frame
		eor.w	d0,d1					; enable newly held buttons
		move.w	d0,(a1)+				; save held buttons to RAM
		and.w	d0,d1					; remove held buttons from pressed buttons
		move.w	d1,(a1)+				; save as pressed buttons

	if PAD_ENABLE_MULTI
		rept 3
			clr.l	(a1)+				; clear button data for all
		endr
	endif
		rts
; ==============================================================
; --------------------------------------------------------------
; Read mouse
; --------------------------------------------------------------

.mouse
		move.b	#(1<<PAD_TH)|(1<<PAD_TR),(a0)		; TH+TR HIGH
		moveq	#0,d0					; load TR low to d2
	pad_delay4						;

		bsr.w	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; check first packet value
		bne.s	.merror					; branch if invalid

		move.b	d0,(a0)					; next packet
		bsr.w	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; check packet value
		cmp.b	#$B,d1					; check if B
		bne.s	.merror					; if not, its not a mouse

		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; check packet value
		cmp.b	#$F,d1					; check if B
		bne.s	.merror					; if not, its not a mouse

		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; check packet value
		cmp.b	#$F,d1					; check if B
		beq.s	.ismouse				; if not, its not a mouse
; --------------------------------------------------------------

.merror
		clr.w	(a1)+					; clear button data
		move.w	#$8000,(a1)+				; set as invalid data
		bra.s	.clear					; clear rest
; --------------------------------------------------------------

.ismouse
		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		moveq	#0,d2					; clear the high byte
		move.b	(a0),d2					; load [YO XO YS XS]
		lsl.b	#4,d2					; [YO XO YS XS | 0- 0- 0- 0-]

		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; load [S- M- R- L-]
		or.b	d1,d2					; [YO XO YS XS | S- M- R- L-]
		lsl.w	#8,d2					; [YO XO YS XS | S- M- R- L- || 0- 0- 0- 0- | 0- 0- 0- 0-]

		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		move.b	(a0),d2					; load [X7 X6 X5 X4]
		lsl.b	#4,d2					; [X7 X6 X5 X4 | 0- 0- 0- 0-]

		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; load [X3 X2 X1 X0]
		or.b	d1,d2					; [X7 X6 X5 X4 | X3 X2 X1 X0]
		lsl.l	#8,d2					; [YO XO YS XS | S- M- R- L- || X7 X6 X5 X4 | X3 X2 X1 X0 || 0- 0- 0- 0- | 0- 0- 0- 0-]

		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		move.b	(a0),d2					; load [Y7 Y6 Y5 Y4]
		lsl.b	#4,d2					; [Y7 Y6 Y5 Y4 | 0- 0- 0- 0-]

		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; load [Y3 Y2 Y1 Y0]
		or.b	d1,d2					; [Y7 Y6 Y5 Y4 | Y3 Y2 Y1 Y0]
; --------------------------------------------------------------

		move.w	d2,(a1)+				; save [X7 X6 X5 X4 | X3 X2 X1 X0 || Y7 Y6 Y5 Y4 | Y3 Y2 Y1 Y0]
		swap	d2					; [0- 0- 0- 0- | 0- 0- 0- 0- || YO XO YS XS | S- M- R- L-]

		move.b	(a1),d1					; load [YO XO YS XS | S- M- R- L-] from previous frame
		move.b	d2,(a1)+				; save [YO XO YS XS | S- M- R- L-]

		eor.b	d2,d1					; enable newly held buttons
		and.b	d2,d1					; remove held buttons from pressed buttons
		and.b	#$F,d1					; [S- M- R- L-]
		move.b	d1,(a1)+				; save as pressed buttons
; --------------------------------------------------------------

.clear
	if PAD_ENABLE_MULTI
		rept 3
			clr.l	(a1)+				; clear button data for all
		endr
	endif
		rts
; ==============================================================
; --------------------------------------------------------------
; Do a handshake with a mouse or teamplayer
; --------------------------------------------------------------

pHandShake:
		moveq	#5,d1					; max 6 attempts
		eor.b	#1<<PAD_TR,d0				; switch TR level
		beq.s	.tllo

.tlhi		btst	#PAD_TL,(a0)
		dbeq	d1,.tlhi				; wait for 6 attempts or for TL to be high
		rts

.tllo		btst	#PAD_TL,(a0)
		dbne	d1,.tllo				; wait for 6 attempts or for TL to be low
		rts
; ==============================================================
; --------------------------------------------------------------
; Read TeamPlayer
; --------------------------------------------------------------

	if PAD_ENABLE_MULTI
pReadTeamPlay:
		move.b	#(1<<PAD_TH)|(1<<PAD_TR),(a0)		; TH+TR HIGH
		moveq	#1<<PAD_TR,d0				; prepare the TR flip-flop

		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; check first packet value
		cmp.b	#3,d1					; check if 3
		bne.s	.terror					; branch if invalid

		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; check packet value
		cmp.b	#$F,d1					; check if F
		bne.s	.terror					; if not, its not a teamplayer

		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; check packet value
		bne.s	.terror					; if not 0, its not a teamplayer

		move.b	d0,(a0)					; next packet
		bsr.s	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; check packet value
		beq.s	.isteam					; if not 0, its not a teamplayer
; --------------------------------------------------------------

.terror
		move.l	#$80008000,d0				; load fill value to d0
	rept 4
		move.l	d0,(a1)+				; fill controls with invalid data
	endr
		rts
; --------------------------------------------------------------

.isteam
		move.b	d0,(a0)					; next packet
		moveq	#4-1,d2					; get 4 controller types
		moveq	#0,d3					; prepare value

.taploop
		bsr.s	pHandShake				; do handshake
		moveq	#3,d1					; prepare mask to d1
		and.b	(a0),d1					; get controller type

		move.b	d0,(a0)					; next packet
		or.b	d1,d3					; add the next controller type to d3
		ror.b	#2,d3					; shift controller array to make space
		dbf	d2,.taploop				; loop for every controller

		move.b	d3,1(a2)				; save into controller RAM
		bsr.s	.mpad					; get button presses
		bsr.s	.mpad					;
		bsr.s	.mpad					;
		bsr.s	.mpad					;

		move.b	#(1<<PAD_TH)|(1<<PAD_TR),(a0)		; TH+TR HIGH
		rts
; ==============================================================
; --------------------------------------------------------------
; Read TeamPlayer pad
; --------------------------------------------------------------

.mpad
		moveq	#3,d1					; prepare mask to d1
		and.b	d3,d1					; and next controller to d1
		lsr.b	#2,d3					; shift controller bits away
		add.b	d1,d1					; double offset
		jmp	.mtable(pc,d1.w)			; jump to handler
; --------------------------------------------------------------

.mtable
		bra.s	.mpad3					; 3-button pad
		bra.s	.mpad6					; 6-button pad
		nop						; invalid
								; empty
; --------------------------------------------------------------

		clr.l	(a1)+					; clear
		rts
; ==============================================================
; --------------------------------------------------------------
; Read TeamPlayer 3-button pad
; --------------------------------------------------------------

.mpad3
		bsr.w	pHandShake				; do handshake
		moveq	#$F,d2					; prepare UDLR mask to d2
		and.b	(a0),d2					; and with the buttons from pad

		move.b	d0,(a0)					; next packet
		bsr.w	pHandShake				; do handshake
		moveq	#$F,d1					; prepare SABC mask to d1
		and.b	(a0),d1					; and with the buttons from pad
		move.b	d0,(a0)					; next packet

		lsl.b	#4,d1					; shift buttons into place
		or.b	d1,d2					; fuse them together
		not.b	d2					; flip stats of buttons (1 is pressed as opposed to not pressed)

		move.w	(a1),d1					; copy button presses for last frame
		eor.w	d2,d1					; enable newly held buttons
		move.w	d2,(a1)+				; save held buttons to RAM
		and.w	d2,d1					; remove held buttons from pressed buttons
		move.w	d1,(a1)+				; save as pressed buttons
		rts
; ==============================================================
; --------------------------------------------------------------
; Read TeamPlayer 6-button pad
; --------------------------------------------------------------

.mpad6
		bsr.w	pHandShake				; do handshake
		move.w	#$F00F,d2				; prepare UDLR mask to d2 and also 4 highest bits for controller bits
		and.b	(a0),d2					; and with the buttons from pad

		move.b	d0,(a0)					; next packet
		bsr.w	pHandShake				; do handshake
		moveq	#$F,d1					; prepare SABC mask to d1
		and.b	(a0),d1					; and with the buttons from pad

		move.b	d0,(a0)					; next packet
		lsl.b	#4,d1					; shift buttons into place
		or.b	d1,d2					; fuse them together

		bsr.w	pHandShake				; do handshake
		moveq	#$F,d1					; prepare MXYZ mask to d1
		and.b	(a0),d1					; and with the buttons from pad
		move.b	d0,(a0)					; next packet

		lsl.w	#8,d1					; shift buttons into place
		or.w	d1,d2					; fuse together
		not.w	d2					; flip stats of buttons (1 is pressed as opposed to not pressed)

		move.w	(a1),d1					; copy button presses for last frame
		eor.w	d2,d1					; enable newly held buttons
		move.w	d2,(a1)+				; save held buttons to RAM
		and.w	d2,d1					; remove held buttons from pressed buttons
		move.w	d1,(a1)+				; save as pressed buttons
		rts
; ==============================================================
; --------------------------------------------------------------
; Read EA 4-way play
; --------------------------------------------------------------

pReadEA:
		moveq	#4-1,d2					; loop counter
		moveq	#$C,d3					; controller latch

.loop
		move.b	d3,2(a0)				; latch controller in port 2
	pad_delay8						;
		move.b	#0,(a0)					; TH LOW

		move.w	#$FF00|(1<<PAD_TL)|(1<<PAD_TR),d0	; prepare mask (high byte to ensure 3-button pads don't break)
		and.b	(a0),d0					; get only START+A
		move.b	#$40,(a0)				; TH HIGH
		lsl.b	#2,d0					; shift buttons into place

		moveq	#(1<<PAD_TL)|(1<<PAD_TR)|$F,d1		; get B+C+UDLR mask to d1
		and.b	(a0),d1					; and with the buttons from pad
		move.b	#0,(a0)					; TH LOW
		or.b	d1,d0					; fuse buttons
	pad_delay4						;

		move.b	#$40,(a0)				; TH HIGH
	pad_delay8						;
		move.b	#0,(a0)					; TH LOW
	pad_delay4						;

		moveq	#$F,d1					; prepare mask to d1
		and.b	(a0),d1					; and with data
		bne.s	.not6					; apparently <>0 means 3-button pad
		move.b	#$40,(a0)				; TH HIGH

	pad_delay4						;
		moveq	#$F,d1					; prepare MXYZ mask to d1
		and.b	(a0),d1					; and with the buttons from pad
		lsl.w	#8,d1					; shift into place
		and.w	#$F0FF,d0				; clear some extra bits
		or.w	d1,d0					; add the new button presses in

.not6
		move.b	#$40,(a0)				; TH HIGH
		not.w	d0					; flip stats of buttons (1 is pressed as opposed to not pressed)

		move.w	(a1),d1					; copy button presses for last frame
		eor.w	d0,d1					; enable newly held buttons
		move.w	d0,(a1)+				; save held buttons to RAM
		and.w	d0,d1					; remove held buttons from pressed buttons
		move.w	d1,(a1)+				; save as pressed buttons

		add.b	#$10,d3					; latch next controller next time
		dbf	d2,.loop				; loop for all controllers
		rts
	endif
; ==============================================================
; --------------------------------------------------------------
; Routine to initialize pads correctly into RAM
; --------------------------------------------------------------

pInit:
		clr.b	pPoll.w					; clear poll stat
		lea	$A10003,a0				; load pad1 data to a0
; --------------------------------------------------------------

	if PAD_ENABLE_MULTI
		move.b	#1<<PAD_TH,6(a0)			; set TH as output on port 1
	pad_delay8						;
		move.b	#$7F,8(a0)				; all lines are output on port 2
	pad_delay8						;
		move.b	#$7C,2(a0)				; write special code to port 2
	pad_delay8						;

		moveq	#$F,d2					; load mask to d2
		and.b	(a0),d2					; get get data from port 1
		bra.s	.notEA					; if those bits were not 0, branch

		move.b	#$C,2(a1)				; reset latch
		move.w	#$EAEA,pMode1.w				; enable EA 4-way play
		rts
	endif
; --------------------------------------------------------------

.notEA
		lea	pMode1.w,a1				; load pad1 mode to a1
		bsr.s	.detect					; detect pad1
		addq.w	#2,a0					; go to pad2 data
; ==============================================================
; --------------------------------------------------------------
; Routine to detect between pad3, pad6 and mouse
; --------------------------------------------------------------

.detect
		move.b	#(1<<PAD_TH)|(1<<PAD_TR),6(a0)		; set output to TH+TR
		move.b	#(1<<PAD_TH)|(1<<PAD_TR),(a0)		; TH+TR HIGH
		moveq	#1<<PAD_TR,d0				; prepare the TR flip-flop
		moveq	#3-1,d3					; do 3 reads

		moveq	#$F,d2					; load mask to d2
		and.b	(a0),d2					; get packet value
		move.b	d0,(a0)					; next packet

.getcode
		lsl.w	#4,d2					; make some room for the next data
		bsr.w	pHandShake				; do handshake
		moveq	#$F,d1					; load mask to d1
		and.b	(a0),d1					; get packet value

		move.b	d0,(a0)					; next packet
		or.b	d1,d2					; add packet to d2
		dbf	d3,.getcode				; do every read

	if PAD_ENABLE_MULTI
		cmp.w	#$3F00,d2				; check if this is a multitap
		beq.s	.multitap				; if yes, branch
	endif
		cmp.w	#$0BFF,d2				; check if this is a mouse
		bne.s	.check6					; if not, branch

.mouse
		move.b	#2,(a1)+				; set mode as mouse
		move.b	#(1<<PAD_TH)|(1<<PAD_TR),(a0)		; TH+TR HIGH
		rts
; --------------------------------------------------------------

	if PAD_ENABLE_MULTI
.multitap
		move.b	#$80,(a1)+				; set mode as TeamPlayer
		move.b	#(1<<PAD_TH)|(1<<PAD_TR),(a0)		; TH+TR HIGH
		rts
	endif
; --------------------------------------------------------------

.check6
		move.b	#1<<PAD_TH,6(a0)			; set output to TH
		moveq	#0,d2					; load TH low to d2
		moveq	#1<<PAD_TH,d3				; load TH high to d3
		move.b	d2,(a0)					; TH LOW
	pad_delay8						;
		move.b	d3,(a0)					; TH HIGH
	pad_delay8						;
		move.b	d2,(a0)					; TH LOW
	pad_delay8						;
		move.b	d3,(a0)					; TH HIGH
	pad_delay8						;
		move.b	d2,(a0)					; TH LOW
	pad_delay8						;
		move.b	(a0),d0					; load 6-button check
		move.b	d3,(a0)					; TH HIGH (needs to be high for reading to work)
; --------------------------------------------------------------

		and.b	#$F,d0					; check if UDLR is pressed at once
		sne	d1					; if yes, it is 6-button
		addq.b	#1,d1					; 3-button = 0, 6-button = 1
		move.b	d1,(a1)+				; send to a0
		rts
; --------------------------------------------------------------
