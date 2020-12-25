; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2020/12
;
;   Object debug routines
; --------------------------------------------------------------

; ==============================================================
; --------------------------------------------------------------
; Debug object lists
; --------------------------------------------------------------

oDebugList:
		if DEBUG
	RaiseError	"OBJECT LIST DEBUG", .rt, 0

.rt								; bit0 = free, bit1 = next, bit2 = prev
		move.w	#ObjList,d7				; load object list start address to d7
		move.w	#ObjListEnd-ObjList,d6			; load list size to d6
		moveq	#-1,d0					; this allows switching to free RAM space
; --------------------------------------------------------------

		move.w	FreeHead.w,a0				; load the next free object to a0

.free
		move.w	a0,d0					; copy object to d0
		sub.w	d7,d0					; subtract the beginning of object list from object address
		cmp.w	d6,d0					; check if the object is within bounds
		bhs.s	.freend					; branch if not

		move.l	d0,a1					; convert this to a RAM pointer
		bset	#0,(a1)+				; enable free list
		move.w	prev(a0),a0				; load next object to a0
		bra.s	.free					; continue loop
; --------------------------------------------------------------

.freend
		move.w	TailNext.w,a0				; load the first used object to a0

.next
		move.w	a0,d0					; copy object to d0
		sub.w	d7,d0					; subtract the beginning of object list from object address
		cmp.w	d6,d0					; check if the object is within bounds
		bhs.s	.nxend					; branch if not

		move.l	d0,a1					; convert this to a RAM pointer
		bset	#1,(a1)+				; enable next list
		move.w	next(a0),a0				; load next object to a0
		bra.s	.next					; continue loop
; --------------------------------------------------------------

.nxend
		move.w	TailPrev.w,a0				; load the first used object to a0

.prev
		move.w	a0,d0					; copy object to d0
		sub.w	d7,d0					; subtract the beginning of object list from object address
		cmp.w	d6,d0					; check if the object is within bounds
		bhs.s	.pvend					; branch if not

		move.l	d0,a1					; convert this to a RAM pointer
		bset	#2,(a1)+				; enable prev list
		move.w	prev(a0),a0				; load next object to a0
		bra.s	.prev					; continue loop
; --------------------------------------------------------------

.pvend
	; check all objects if they belong to the correct lists. Only bits 1 and 6 should get set
		moveq	#0,d5					; load bitfield to d5
		clr.w	d0					; clear low word
		move.l	d0,a1					; load object params to a1

		lea	ObjList.w,a0				; load object list to a0
		dbset	objcount,d2				; load object list length to d2

.proc
		move.b	(a1),d1					; load object attributes to d1
		bset	d1,d5					; enable attributes
		add.w	#size,a1				; go to next object
		dbf	d2,.proc				; loop for every object
; --------------------------------------------------------------

	; process all orphan objects
		btst	#0,d5					; check if any orphans exist
		beq.s	.noorphans				; branch if not

	Console.Write "%<pal0>Orphans:%<pal2>"			; write header
		moveq	#8,d3					; line offset
		moveq	#0,d4					; write all objects with this attribute
		bsr.w	.writeattribute				; write it out
; --------------------------------------------------------------

.noorphans
	; process all objects in multiple lists
		btst	#7,d5					; check if any multi objects exist
		beq.s	.nomulti				; branch if not

	Console.Write "%<pal0>Multiple lists:   %<pal2>"		; write header
		moveq	#18,d3					; line offset
		moveq	#7,d4					; write all objects with this attribute
		bsr.w	.writeattribute				; write it out
; --------------------------------------------------------------

.nomulti
	; process all objects in multiple lists
		moveq	#(1<<2)|(1<<3)|(1<<4)|(1<<5),d3		; load all invalid config bits to d3
		and.w	d5,d3					; and with the actual bitfield
		beq.s	.noinvalid				; branch if none set

	Console.Write "%<pal0>Invalid:%<pal2>"			; write header
		moveq	#8,d3					; line offset

		moveq	#2,d4					; write all objects with this attribute
		bsr.w	.writeattribute				; write it out
		moveq	#3,d4					; write all objects with this attribute
		bsr.w	.writeattribute				; write it out
		moveq	#4,d4					; write all objects with this attribute
		bsr.w	.writeattribute				; write it out
		moveq	#5,d4					; write all objects with this attribute
		bsr.w	.writeattribute				; write it out
; --------------------------------------------------------------

.noinvalid
	; process all used objects
	Console.Write "%<endl>%<pal0>Used:   %<pal2>"		; write header
		moveq	#8,d3					; line offset
		move.w	TailNext.w,a0				; load the first used object to a0

.dnext
		move.w	a0,d0					; copy object to d0
		sub.w	d7,d0					; subtract the beginning of object list from object address
		cmp.w	d6,d0					; check if the object is within bounds
		bhs.s	.ndend					; branch if not

		bsr.w	.writeptr				; write object pointer
	Console.Write "%<pal1>>%<pal2>"				; write a >

		move.w	next(a0),a0				; load next object to a0
		bra.s	.dnext					; continue loop
; --------------------------------------------------------------

.ndend
		cmp.w	#TailPtr,a0				; check if this is the tail object
		beq.s	.writetail				; branch if so
	Console.WriteLine "%<pal3>%<.w a0 hex>"			; write invalid object
		bra.s	.notail

.writetail
	Console.WriteLine "%<pal0>tail"				; write tail
; --------------------------------------------------------------

.notail
	; process all free objects
	Console.Write "%<endl>%<pal0>Free:   %<pal2>"		; write header
		moveq	#8,d3					; line offset
		move.w	FreeHead.w,a0				; load the next free object to a0

.dfree
		move.w	a0,d0					; copy object to d0
		sub.w	d7,d0					; subtract the beginning of object list from object address
		cmp.w	d6,d0					; check if the object is within bounds
		bhs.s	.dfend					; branch if not

		bsr.s	.writeptr				; write object pointer
	Console.Write "%<pal1><%<pal2>"				; write a <

		move.w	prev(a0),a0				; load next object to a0
		bra.s	.dfree					; continue loop
; --------------------------------------------------------------

.dfend
		cmp.w	#0,a0					; check if this is the tail object
		beq.s	.writet2il				; branch if so
	Console.WriteLine "%<pal3>%<.w a0 hex>"			; write invalid object
		bra.s	.not2il

.writet2il
	Console.WriteLine "%<pal0>0"				; write tail
; --------------------------------------------------------------

.not2il
		bra.s	*					; done!
; --------------------------------------------------------------
; function to write object pointer
;
; in:
;    d3 = line position
;    a0 = object
; --------------------------------------------------------------

.writeptr
		cmp.b	#40-5,d3				; check if we don't have enough room for the ptr
		bls.s	.isroom					; branch if we do
		moveq	#3,d3					; clear position counter
	Console.Write "   "					; insert a line break

.isroom
	Console.Write "%<.w a0 hex>"				; write the pointer
		addq.b	#5,d3					; advance position counter
		rts
; --------------------------------------------------------------
; function to write objects with specific attribute
;
; in:
;    d4 = attribute
;    d3 = line position
; --------------------------------------------------------------

.writeattribute
		move.l	d0,a1					; load object params to a1
		lea	ObjList.w,a0				; load object list to a0
		dbset	objcount,d2				; load object list length to d2

.proca
		cmp.b	(a1),d4					; check if attribute matches
		bne.s	.nomatch				; branch if not
		bsr.s	.writeptr				; write object pointer
	Console.Write " "					; write a space

.nomatch
		add.w	#size,a0				; go to next object
		add.w	#size,a1				; go to next object
		dbf	d2,.proca				; loop for every object
	Console.BreakLine					; insert a line break
		rts
	endif
; ==============================================================
; --------------------------------------------------------------
; Debug single objects
;
; input:
;    a0 = object ID
; --------------------------------------------------------------

oDebug:
		if DEBUG
	RaiseError	"OBJECT %<pal2>%<.w a0 hex> %<pal1>DEBUG", .rt, 0

.rt
	Console.WriteLine "%<pal0>Ptr:       %<pal2>%<.l ptr(a0) hex>"
	Console.WriteLine "%<pal0>%<.l ptr(a0) sym|split>%<pal2>%<symdisp>"
	Console.WriteLine "%<pal0>Display:   %<pal2>%<.w dprev(a0) hex> %<pal2>%<.w dnext(a0) hex>"
; --------------------------------------------------------------

	Console.Write     "%<pal0>Platform:  "
		move.w	plat(a0),a1				; load platform pointer to a1
		lea	.writeplat(pc),a2			; load routine to a2
		bsr.w	.writeptr				; write ptr info
; --------------------------------------------------------------

	Console.Write     "%<pal0>Touch:     "
		move.w	touch(a0),a1				; load touch pointer to a1
		lea	.writetouch(pc),a2			; load routine to a2
		bsr.w	.writeptr				; write ptr info
; --------------------------------------------------------------

	Console.Write     "%<pal0>Dyn Art:   "
		move.w	dyn(a0),a1				; load dynart pointer to a1
		lea	.writedart(pc),a2			; load routine to a2
		bsr.w	.writeptr				; write ptr info
; --------------------------------------------------------------

	Console.WriteLine "%<pal0>Respawn:   %<pal2>%<.w resp(a0) hex>"
	Console.WriteLine "%<pal0>Flags:     %<pal2>%<.w flags(a0) hex>"
	Console.WriteLine "%<pal0>Position:  %<pal2>%<.w xpos(a0) hex>.%<.b xpos+2(a0) hex>  %<.w ypos(a0) hex>.%<.b ypos+2(a0) hex>"
	Console.WriteLine "%<pal0>Disp size: %<pal2>%<.b width(a0) dem>x%<.b height(a0) dem>"
	Console.WriteLine "%<pal0>Map/frame: %<pal0>%<.l map(a0) sym|split>%<pal2>%<symdisp> / %<.b frame(a0) hex>"
	Console.WriteLine "%<pal0>Tile:      %<pal2>%<.w tile(a0) hex>"
; --------------------------------------------------------------

	Console.Write "%<pal0>Exram:     %<pal2>"		; write header
		moveq	#11,d0					; set the text position to d0
		moveq	#0,d2					; clear d2
		add.w	#exram,a0				; go to exram address
		dbset	size-exram,d1				; set loop counter to d1

.exram
		cmp.b	#36-3,d0				; check if we can fit more stuff in
		bls.s	.canfit					; branch if yes
		moveq	#11,d0					; set the text position to d0
		addq.w	#8,d2					; increment d2
	Console.Write "   %<pal3>+$%<.b d2 hex>%<pal2>       "	; pad to next line

.canfit
	Console.Write "%<.b (a0)+ hex> "			; write next part
		addq.b	#3,d0					; mark as written
		dbf	d1,.exram				; loop for all of exram
		bra.s	*
; --------------------------------------------------------------
; function to write pointer info
;
; in:
;    a1 = pointer
;    a2 = routine if not null
; --------------------------------------------------------------

.writeptr
		cmp.w	#0,a1					; check if null
		beq.s	.null					; branch if yes
		jmp	(a2)					; run custom routine

.null
	Console.WriteLine "%<pal0>null"				; write null text
		rts
; --------------------------------------------------------------

.writeplat
	Console.WriteLine "%<pal2>%<.b pwidth(a1) dem>x%<.b pheight(a1) dem> %<.b pflags(a1) hex> %<pal0>%<.l pmap(a1) sym|split>%<pal2>%<symdisp>"
		rts
; --------------------------------------------------------------

.writetouch
	Console.WriteLine "%<pal2>%<.b twidth(a1) dem>x%<.b theight(a1) dem> %<.b tflags(a1) hex> %<.b textra(a1) hex>"
		rts
; --------------------------------------------------------------

.writedart
	Console.WriteLine "%<pal2>%<.b dwidth(a1) dem> %<.b dbit(a1) hex> %<.b dlast(a1) hex>"
	Console.WriteLine "%<pal0>Dart art:  %<pal0>%<.l dart(a1) sym|split>%<pal2>%<symdisp>"
	Console.WriteLine "%<pal0>Dart map:  %<pal0>%<.l dmap(a1) sym|split>%<pal2>%<symdisp>"
		rts
	endif
; --------------------------------------------------------------

	if DEBUG=0
		exception	exNoDebug			; throw an exception instead
	endif
