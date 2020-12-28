; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2020/12
;
;   Miscellaneous object routines
; --------------------------------------------------------------

; ==============================================================
; --------------------------------------------------------------
; Object list and property intiailization routine
;
; thrash: d0-d1/a0
; --------------------------------------------------------------

oInitializeAll:
	memclr.l DisplayList.w, dislayercount * ddsize, d0, a0	; clear display lists
	memclr.l PlatformList.w, platformcount * psize, d0, a0	; clear platform objects list
	memclr.l TouchList.w, touchcount * tsize, d0, a0	; clear touch objects list
	memclr.l DartList.w, dyncount * dsize, d0, a0		; clear dynamic objects list
	memclr.l DynAllocTable.w, dynallocbytes, d0, a0		; clear allocations table
	memclr.l RespawnList.w, ObjListEnd - RespawnList, d0, a0; clear respawn and object table
; --------------------------------------------------------------

	; setup tail object
		move.w	#TailPtr,TailNext.w			; set the first object as the tail object
		move.w	#TailPtr,TailPrev.w			; set the last object as the tail object
		move.l	#.rts,TailPtr.w				; set the next rts as the tail object pointer

	; setup free object list
		lea	ObjList.w,a0				; load the objects list into a0
		move.w	a0,FreeHead.w				; set the first object as the first free object
		dbset	objcount-1,d0				; load object count to d0
		moveq	#size,d1				; load object size to d1
; --------------------------------------------------------------

.load
		add.w	d1,a0					; go to the next object now
		move.w	a0,prev-size(a0)			; save new previous pointer
		dbf	d0,.load				; loop for every object
		clr.w	prev(a0)				; set the last previos pointer to 0

		move.l	#DefaultRenderList,RenderList.w		; set default render list

.rts
		rts
; ==============================================================
; --------------------------------------------------------------
; Default render list that only renders every object layer
; --------------------------------------------------------------

DefaultRenderList:
.x =	ddnext							; set initial offset
	rept dislayercount					; run for every layer
		dc.l ($01<<24) | ProcMapsLayer, DisplayList+.x	; include layer info
.x =		.x+ddsize					; go to next layer
	endr
		dc.w 0						; end token
