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

		lea	.test(pc),a3				; load object pointer to a3
		jsr	oLoadImportant.w			; load an important object

.proc
	RunObjects						; run all objects
		jsr	ProcAlloc				; update allocations
		jsr	ProcMaps				; update sprite table

	vsync							; wait for the next frame
		move.w	TailNext.w,a0				; load head object to a0
	;	jsr	DebugOne				; debug it
		bra.s	.proc					; infinite loop
; --------------------------------------------------------------

.test2
.test
	oAttributes	Test_Map, 1, 0, 64, 16			; setup attributes
;	oCreatePlat	Test_Pmap, (1<<pactive) | (1<<ptop) | (1<<plrb), 64, 16; setup platform
;	oCreateTouch	0, 0, 64, 16				; setup touch
	oCreateDynArt	Test_Art, Test_Dmap, 7			; setup dynamic art
	oAddDisplay	2, a0, a1, 1				; enable display

		move.w	#150,xpos(a0)				; x-pos vaguely in the screen centre
		move.w	#100,ypos(a0)				; y-pos vaguely in the screen centre
		move.l	#.loop,(a0)				; set new routine
; --------------------------------------------------------------

.loop
		btst	#0,pPress1A.w				; check the X button
		beq.s	.nox					; branch if no
		jmp	DebugLayers				; debug layers
; --------------------------------------------------------------

.nox
		btst	#1,pPress1A.w				; check the Y button
		beq.s	.noy					; branch if no
		jmp	DebugDynArts				; debug dynart
; --------------------------------------------------------------

.noy
		btst	#2,pPress1A.w				; check the Z button
		beq.s	.noz					; branch if no
		jmp	DebugOne				; debug dynart
; --------------------------------------------------------------

.noz
	; check flippity floppity
		btst	#5,pPress1A+1.w				; check for C button
		beq.s	.noc					; branch if no
		add.b	#1<<(xflip&7),flags(a0)			; switch x-flip or y-flip
		and.b	#(1<<(xflip&7))|(1<<(yflip&7))|(1<<(onscreen&7)),flags(a0); only ever switch flip bits
; --------------------------------------------------------------

.noc
	; check object movement
		moveq	#0,d0					; change movement to 0
		btst	#0,pHeld1A+1.w				; check if up is pressed
		beq.s	.noup					; branch if no
		subq.w	#1,d0					; change to upwards speed

.noup
		btst	#1,pHeld1A+1.w				; check if down is pressed
		beq.s	.nodwn					; branch if no
		addq.w	#1,d0					; change to downwards speed

.nodwn
		add.w	d0,ypos(a0)				; change y-pos based on speed
; --------------------------------------------------------------

		moveq	#0,d0					; change movement to 0
		btst	#2,pHeld1A+1.w				; check if left is pressed
		beq.s	.nol					; branch if no
		subq.w	#1,d0					; change to leftwards speed

.nol
		btst	#3,pHeld1A+1.w				; check if right is pressed
		beq.s	.nor					; branch if no
		addq.w	#1,d0					; change to rightwards speed

.nor
		add.w	d0,xpos(a0)				; change x-pos based on speed
; --------------------------------------------------------------

.delay =	4						; delay per frame change
.maxframe =	215						; actually is 250 but there is garbage because this would use 2 sets of art......
		tst.b	exram(a0)				; check for delay count
		bne.s	.nob					; branch if not 0
		addq.b	#1,exram(a0)				; make sure counter wont underflow
; --------------------------------------------------------------

		btst	#6,pHeld1A+1.w				; check the A button
		beq.s	.noa					; branch if no
		move.b	#.delay,exram(a0)			; set delay counter

		addq.b	#1,frame(a0)				; increment frame
		cmp.b	#.maxframe,frame(a0)			; check if this is the max frame
		bls.s	.noa					; branch if not
		move.b	#1,frame(a0)				; skip null frame
; --------------------------------------------------------------

.noa
		btst	#4,pHeld1A+1.w				; check the B button
		beq.s	.nob					; branch if no
		move.b	#.delay,exram(a0)			; set delay counter

		subq.b	#1,frame(a0)				; decrement frame
		bne.s	.nob					; branch if not 0
		move.b	#.maxframe,frame(a0)			; set to max frame
; --------------------------------------------------------------

.nob
		subq.b	#1,exram(a0)				; decrease delay count

		tst.b	pPress1A+1.w				; check the Start button press
		bpl.s	.nos					; branch if no
		move.l	#.nos,(a0)				; make this object stick to current animation
		clr.w	pPress1A.w				; prevent a infinite loop

		lea	.test2(pc),a3				; load object pointer to a3
		jsr	oLoadImportant.w			; load an important object

.nos
		oNext						; run next object
; --------------------------------------------------------------

Test_Pmap:	dc.w 0						; platform mappings
Test_Map:	include	"screens/test/sonic/sprite.map"		; test (Sonic) sprite mappings
Test_Dmap:	include	"screens/test/sonic/dyn.map"		; test (Sonic) dynamic mappings
	incdma	Test_Art, "screens/test/sonic/art.unc"		; test (Sonic) art
	incdma	Test_Pal, "screens/test/sonic/test.pal"		; test (Sonic&Tails) palette
; --------------------------------------------------------------

