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
; Debug ROM at a0
; --------------------------------------------------------------

DebugROM:
		if DEBUG
	RaiseError	"ROM DEBUG %<pal2>%<.l a0 hex>", .rt, 0

.rt
	Console.Write "%<pal0>%<.l a0 sym|split>%<pal2>%<symdisp>%<endl>  "
		dbset	20,d0					; fill rest of the screen

.write
		dbset	7,d1					; length of a line

.line
	Console.Write "%<.w (a0)+ hex> "			; write next word
		dbf	d1,.line				; loop for this line
	Console.Write "   "					; some blank
		dbf	d0,.write				; loop for all
		rts
	endif
; ==============================================================
; --------------------------------------------------------------
; Debug single objects
;
; input:
;    a0 = object ptr
; --------------------------------------------------------------

DebugOne:
		if DEBUG
	RaiseError	"OBJECT %<pal2>%<.w a0 hex> %<pal1>DEBUG", .rt, 0

.rt
	Console.WriteLine "%<pal0>Ptr:       %<pal2>%<.l ptr(a0) hex>"
	Console.WriteLine "%<pal0>%<.l ptr(a0) sym|split>%<pal2>%<symdisp>"
	Console.WriteLine "%<pal0>Disp layer:%<pal2>%<.w dprev(a0) hex> %<pal2>%<.w dnext(a0) hex>"
; --------------------------------------------------------------

	Console.Write     "%<pal0>Platform:  "
		move.w	plat(a0),a1				; load platform pointer to a1
		lea	.writeplat(pc),a2			; load routine to a2
		bsr.w	.writeinfo				; write ptr info
; --------------------------------------------------------------

	Console.Write     "%<pal0>Touch:     "
		move.w	touch(a0),a1				; load touch pointer to a1
		lea	.writetouch(pc),a2			; load routine to a2
		bsr.w	.writeinfo				; write ptr info
; --------------------------------------------------------------

	Console.Write     "%<pal0>Dyn Art:   "
		move.w	dyn(a0),a1				; load dynart pointer to a1
		lea	.writedart(pc),a2			; load routine to a2
		bsr.w	.writeinfo				; write ptr info
; --------------------------------------------------------------

		tst.w	resp(a0)				; check if respawn address was set
		bne.s	.respawn				; branch if yes
	Console.Write    "%<pal0>Respawn:   "
		bsr.w	.null					; write null text
		bra.s	.flags

.respawn
		move.w	resp(a0),a1				; load respawn address to a1
	Console.WriteLine "%<pal0>Respawn:   %<pal2>%<.w a1 hex>%<pal0> - %<pal2>%<.b (a1) hex>"
; --------------------------------------------------------------

.flags
	; write flags
	Console.Write     "%<pal0>Flags:     "
		lea	.flagsarray(pc),a5			; load flags array to a5
		dbset	16,d6					; load flags length to d6
		move.w	flags(a0),d7				; load flags to d7
		jsr	DebugPrintFlags(pc)			; print flags
	Console.BreakLine					; create a line break

	Console.WriteLine "%<pal0>Position:  %<pal2>%<.w xpos(a0) hex>.%<.b xpos+2(a0) hex>  %<.w ypos(a0) hex>.%<.b ypos+2(a0) hex>"
	Console.WriteLine "%<pal0>Display:   %<pal2>%<.b width(a0) dem>x%<.b height(a0) dem> %<pal0>frame %<pal2>%<.b frame(a0) hex>"
	Console.WriteLine "%<pal0>Mappings:  %<pal0>%<.l map(a0) sym|split>%<pal2>%<symdisp>"
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
		rts
; --------------------------------------------------------------

.flagsarray
		dc.b .b15-.flagsarray-0, .b14-.flagsarray-1, .b13-.flagsarray-2, .b12-.flagsarray-3
		dc.b .b11-.flagsarray-4, .b10-.flagsarray-5, .b9-.flagsarray-6,  .b8-.flagsarray-7
		dc.b .b7-.flagsarray-8,  .b6-.flagsarray-9,  .b5-.flagsarray-10, .b4-.flagsarray-11
		dc.b .b3-.flagsarray-12, .b2-.flagsarray-13, .b1-.flagsarray-14, .b0-.flagsarray-15

.b15		dc.b "onscreen", 0
.b11		dc.b "yflip", 0
.b10		dc.b "xflip", 0
.b8		dc.b "singlesprite", 0
.b14
.b13
.b12
.b9
.b7
.b6
.b5
.b4
.b3
.b2
.b1
.b0		dc.b "?", 0
	even
; --------------------------------------------------------------
; function to write pointer info
;
; in:
;    a1 = pointer
;    a2 = routine if not null
; --------------------------------------------------------------

.writeinfo
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
; ==============================================================
; --------------------------------------------------------------
; Debug all platform objects
; --------------------------------------------------------------

DebugPlatforms:
	RaiseError	"PLATFORM DEBUG", .rt, 0

.rt
		lea	PlatformList.w,a1			; load platform list to a1
		dbset	platformcount,d0			; load list size to d0
; --------------------------------------------------------------

.plat
		move.w	(a1),a0					; load parent to a0
		cmp.w	#0,a0					; check if no parent is loaded
		bne.s	.hasparent				; branch if some is
; --------------------------------------------------------------

	Console.WriteLine "%<pal0>Platform %<pal2>%<.w a1 hex> %<pal1>free"
		bra.w	.next					; skip over to next platform
; --------------------------------------------------------------

.hasparent
	Console.WriteLine "%<pal0>Platform %<pal2>%<.w a1 hex> %<pal0>with parent %<pal2>%<.w a0 hex>"
	Console.WriteLine "%<pal0>%<.l ptr(a0) sym|split>%<pal2>%<symdisp>"
	Console.Write "%<pal0>Size: %<pal2>%<.b pwidth(a1) dem>x%<.b pheight(a1) dem> %<pal0>Flags: %<pal2>"

	; write flags
		lea	.flagsarray(pc),a5			; load flags array to a5
		dbset	8,d6					; load flags length to d6
		move.b	pflags(a1),d7				; load flags to d7
		jsr	DebugPrintFlags(pc)			; print flags
	Console.WriteLine "%<endl>%<pal0>%<.l map(a1) sym|split>%<pal2>%<symdisp>%<endl>"
; --------------------------------------------------------------

.next
		add.w	#psize,a1				; go to next platform
		dbf	d0,.plat				; loop for all platforms
		rts
; --------------------------------------------------------------

.flagsarray
		dc.b .b7-.flagsarray-0, .b6-.flagsarray-1, .b5-.flagsarray-2, .b4-.flagsarray-3
		dc.b .b3-.flagsarray-4, .b2-.flagsarray-5, .b1-.flagsarray-6, .b0-.flagsarray-7

.b7		dc.b "pactive", 0
.b6		dc.b "?", 0
.b5		dc.b "plrb", 0
.b4		dc.b "ptop", 0
.b3		dc.b "ppushp2", 0
.b2		dc.b "ppushp1", 0
.b1		dc.b "pstandp2", 0
.b0		dc.b "pstandp1", 0
	even
; ==============================================================
; --------------------------------------------------------------
; Debug all touch objects
; --------------------------------------------------------------

DebugTouchs:
	RaiseError	"TOUCH DEBUG", .rt, 0

.rt
		lea	TouchList.w,a1				; load platform list to a1
		dbset	touchcount,d0				; load list size to d0
; --------------------------------------------------------------

.plat
		move.w	(a1),a0					; load parent to a0
		cmp.w	#0,a0					; check if no parent is loaded
		bne.s	.hasparent				; branch if some is
; --------------------------------------------------------------

	Console.WriteLine "%<pal0>Touch %<pal2>%<.w a1 hex> %<pal1>free"
		bra.w	.next					; skip over to next platform
; --------------------------------------------------------------

.hasparent
	Console.WriteLine "%<pal0>Touch %<pal2>%<.w a1 hex> %<pal0>with parent %<pal2>%<.w a0 hex>"
	Console.WriteLine "%<pal0>%<.l ptr(a0) sym|split>%<pal2>%<symdisp>"
	Console.WriteLine "%<pal0>Size: %<pal2>%<.b twidth(a1) dem>x%<.b theight(a1) dem> %<pal0>Extra: %<pal2>%<.b textra(a1) hex>"
	Console.Write "%<pal0>Flags: %<pal2>"

	; write flags
		lea	.flagsarray(pc),a5			; load flags array to a5
		dbset	8,d6					; load flags length to d6
		move.b	tflags(a1),d7				; load flags to d7
		jsr	DebugPrintFlags(pc)			; print flags
	Console.BreakLine					; make a line break
	Console.BreakLine					; make a line break
; --------------------------------------------------------------

.next
		add.w	#tsize,a1				; go to next platform
		dbf	d0,.plat				; loop for all platforms
		rts
; --------------------------------------------------------------

.flagsarray
		dc.b .b7-.flagsarray-0, .b6-.flagsarray-1, .b5-.flagsarray-2, .b4-.flagsarray-3
		dc.b .b3-.flagsarray-4, .b2-.flagsarray-5, .b1-.flagsarray-6, .b0-.flagsarray-7

.b7
.b6
.b5
.b4
.b3
.b2
.b1
.b0		dc.b "?", 0
	even
; ==============================================================
; --------------------------------------------------------------
; Debug all dynamic art objects
; --------------------------------------------------------------

DebugDynArts:
	RaiseError	"DYNART DEBUG", .rt, 0

.rt
		lea	DartList.w,a1				; load platform list to a1
		dbset	dyncount,d0				; load list size to d0
; --------------------------------------------------------------

.plat
		move.w	(a1),a0					; load parent to a0
		cmp.w	#0,a0					; check if no parent is loaded
		bne.s	.hasparent				; branch if some is
; --------------------------------------------------------------

	Console.WriteLine "%<pal0>DynArt %<pal2>%<.w a1 hex> %<pal1>free"
		bra.w	.next					; skip over to next platform
; --------------------------------------------------------------

.hasparent
	Console.WriteLine "%<pal0>DynArt %<pal2>%<.w a1 hex> %<pal0>with parent %<pal2>%<.w a0 hex>"
	Console.WriteLine "%<pal0>%<.l ptr(a0) sym|split>%<pal2>%<symdisp>"
	Console.WriteLine "%<pal0>Art: %<.l dart(a1) sym|split>%<pal2>%<symdisp>"
	Console.WriteLine "%<pal0>Map: %<.l dmap(a1) sym|split>%<pal2>%<symdisp>"
	Console.WriteLine "%<pal0>Last: %<pal2>%<.b dlast(a1) hex> %<pal0>Bit: %<pal2>%<.b dbit(a1) hex> %<pal0>Width: %<pal2>%<.b dwidth(a1) hex>"

	; calculate the allocation
		moveq	#0,d2
		move.b	dbit(a1),d2				; load starting bit to d2
		fmulu	dynallocsize,d2,d3			; shift up by bit count

		moveq	#0,d1
		move.b	dwidth(a1),d1				; load width to d1
		fmulu.w	dynallocsize,d1,d3			; shift up by bit count
		move.w	d1,d3					; copy to d3

		add.w	#vDynamic/32,d2				; add start of VRAM allocation to d2
		add.w	d2,d1					; and to d1 too
		subq.w	#1,d1					; decrement 1 from last tile
	Console.WriteLine "%<pal0>Alloc: %<pal2>%<.w d3 hex> %<pal0>tiles; %<pal2>%<.w d2 hex>%<pal1>-%<pal2>%<.w d1 hex> %<pal0>in VRAM%<endl>"
; --------------------------------------------------------------

.next
		lea	dsize(a1),a1				; go to next platform
		dbf	d0,.plat				; loop for all platforms
		rts
; ==============================================================
; --------------------------------------------------------------
; Routine to print a set of flags based on bit patterns
;
; input:
;   d6 = loop counter (how many bits to check)
;   d7 = register that stores the bit pattern
;   a5 = table to read strings from
;
; thrash: d4-d7/a4-a5
; --------------------------------------------------------------

DebugPrintFlags:
	Console.Write "%<pal2>"					; switch palette
		moveq	#0,d5					; reset flip-flop
		moveq	#0,d4					; clear offset
; --------------------------------------------------------------

.writeflags
		move.b	(a5)+,d4				; load flags offset to d4

		btst	d6,d7					; check if flags are set
		beq.s	.nowrite				; branch if not
		tas	d5					; check if the first flag was already written
		beq.s	.nosep					; branch if not
	Console.Write "%<pal1>|%<pal2>"				; write a separator

.nosep
		lea	-1(a5,d4.w),a4				; load flags text to a4
	Console.Write "%<.l a4 str>"				; write a string

.nowrite
		dbf	d6,.writeflags				; loop for all flags
; --------------------------------------------------------------

		tst.b	d5					; check if any bits were set
		bne.s	.rts					; branch if yes
	Console.Write "%<pal0>none%<pal2>"			; write null flags

.rts
		rts
; ==============================================================
; --------------------------------------------------------------
; Debug object lists
; --------------------------------------------------------------

DebugList:
		if DEBUG
	RaiseError	"OBJECT LIST DEBUG", .rt, 0

.rt								; bit0 = free, bit1 = next, bit2 = prev
		lea	DebugWritePtr_Blank+1(pc),a5		; load blank string to a5
		lea	.text(pc),a4				; load text code to a4

		move.w	#ObjList,d7				; load object list start address to d7
		move.w	#ObjListEnd-ObjList,d3			; load list size to d3
		moveq	#-1,d0					; this allows switching to free RAM space
; --------------------------------------------------------------

		move.w	FreeHead.w,a0				; load the next free object to a0

.free
		move.w	a0,d0					; copy object to d0
		sub.w	d7,d0					; subtract the beginning of object list from object address
		cmp.w	d3,d0					; check if the object is within bounds
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
		cmp.w	d3,d0					; check if the object is within bounds
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
		cmp.w	d3,d0					; check if the object is within bounds
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
		lea	size(a1),a1				; go to next object
		dbf	d2,.proc				; loop for every object
; --------------------------------------------------------------

	; process all orphan objects
		btst	#0,d5					; check if any orphans exist
		beq.s	.noorphans				; branch if not

	Console.Write "%<pal0>Orphans:%<pal2>"			; write header
		moveq	#7-1,d6					; line offset
		moveq	#0,d4					; write all objects with this attribute
		bsr.w	.writeattribute				; write it out
; --------------------------------------------------------------

.noorphans
	; process all objects in multiple lists
		btst	#7,d5					; check if any multi objects exist
		beq.s	.nomulti				; branch if not

	Console.Write "%<pal0>Multiple lists:   %<pal2>"	; write header
		moveq	#5-1,d6					; line offset
		moveq	#7,d4					; write all objects with this attribute
		bsr.w	.writeattribute				; write it out
; --------------------------------------------------------------

.nomulti
	; process all objects in multiple lists
		moveq	#(1<<2)|(1<<3)|(1<<4)|(1<<5),d6		; load all invalid config bits to d3
		and.w	d5,d6					; and with the actual bitfield
		beq.s	.noinvalid				; branch if none set

	Console.Write "%<pal0>Invalid:%<pal2>"			; write header
		moveq	#7-1,d6					; line offset

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
		moveq	#7-1,d6					; line offset
		move.w	TailNext.w,a0				; load the first used object to a0

.dnext
		move.w	a0,d0					; copy object to d0
		sub.w	d7,d0					; subtract the beginning of object list from object address
		cmp.w	d3,d0					; check if the object is within bounds
		bhs.s	.ndend					; branch if not

		jsr	DebugWritePtr(pc)			; write object pointer
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
		moveq	#7-1,d6					; line offset
		move.w	FreeHead.w,a0				; load the next free object to a0

.dfree
		move.w	a0,d0					; copy object to d0
		sub.w	d7,d0					; subtract the beginning of object list from object address
		cmp.w	d3,d0					; check if the object is within bounds
		bhs.s	.dfend					; branch if not

		jsr	DebugWritePtr(pc)			; write object pointer
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
		rts						; done!
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
		bsr.s	DebugWritePtr				; write object pointer
	Console.Write " "					; write a space

.nomatch
		lea	size(a0),a0				; go to next object
		lea	size(a1),a1				; go to next object
		dbf	d2,.proca				; loop for every object
	Console.BreakLine					; insert a line break
		rts
; --------------------------------------------------------------

.text
	Console.Write "%<.w a0 hex>%<pal0>"			; write the pointer
		rts
; ==============================================================
; --------------------------------------------------------------
; function to write number of data items per line
; splitting line when done
;
; in:
;    d6 = line position
;    a4 = normal line code
;    a5 = break line string
; --------------------------------------------------------------

DebugWritePtr:
		subq.b	#1,d6					; check if we don't have enough room for the ptr
		bcc.s	.isroom					; branch if we do
		move.b	-1(a5),d6				; reset the position counter
	Console.Write "%<.l a5 str>"				; write the str

.isroom
		jmp	(a4)					; write data

DebugWritePtr_Blank:
		dc.b 7-1, "   ", 0				; blank line
		even
	endif
; ==============================================================
; --------------------------------------------------------------
; Debug all display layers
; --------------------------------------------------------------

DebugLayers:
	RaiseError	"DISPLAY LAYER DEBUG", .rt, 0

.text
	Console.Write "%<.w a1 hex>%<pal0>"			; write the pointer
		rts
; --------------------------------------------------------------

.rt
		lea	DebugWritePtr_Blank+1(pc),a5		; load blank string to a5
		lea	.text(pc),a4				; load text code to a4
		lea	DisplayList.w,a0			; load start of list to a0
		moveq	#0,d0					; load current layer to d0

.layer
	Console.Write "%<pal0>Layer %<.w d0 dem>:%<pal1>%<.w a0>%<pal0>>%<pal2>"
		moveq	#6-1,d6					; set remaining space to 6
		move.w	ddnext(a0),a1				; load first object to a1
; --------------------------------------------------------------

.objloop
		move.w	a1,d2					; copy the pointer to d2
		sub.w	#ObjList,d2				; sub the start of object list from d2
		cmp.w	#ObjListEnd-ObjList,d2			; check if this is inside of the list
		bhs.s	.outside				; branch if not

.ptr
		jsr	DebugWritePtr(pc)			; write this pointer
		move.w	dnext(a1),a1				; load next object
	Console.Write ">%<pal2>"				; write the separator
		bra.s	.objloop
; --------------------------------------------------------------

.colorstr	dc.b pal1, 0, pal3, 0				; color strings

.outside
		lea	.colorstr(pc),a2			; load color str to a2
		move.w	a1,d2					; copy the pointer to d2
		sub.w	#DisplayList,d2				; subtract the beginning of display list from d2

		cmp.w	#dislayercount * ddsize,d2		; lazily check if its within the list
		bhs.s	.stilloutside				; branch if not

.inside
		addq.w	#2,a2					; use different color

.stilloutside
	Console.Write "%<.l a2 str>"				; write the color
		jsr	DebugWritePtr(pc)			; write this pointer
	Console.BreakLine					; insert a line break
; --------------------------------------------------------------

		addq.b	#1,d0					; go to the next layer
		addq.w	#ddsize,a0				;

		cmp.b	#dislayercount,d0			; check if this is the last layer
		bne.w	.layer					; branch if not
		rts
; --------------------------------------------------------------

	if DEBUG=0
		exception	exNDebug			; throw an exception instead
	endif
