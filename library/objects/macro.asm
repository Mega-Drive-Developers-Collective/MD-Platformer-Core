; ==============================================================
; --------------------------------------------------------------
; MD Platformer Core
;
;   by Mega Drive Developers Collective
;      AURORA FIELDS 2020/12
;
;   Object helper macros
; --------------------------------------------------------------

; ==============================================================
; --------------------------------------------------------------
; Macro to run object lists
; --------------------------------------------------------------

RunObjects		macro
		lea	ObjList.w,a0				; load first object slot into a0
		move.l	ptr(a0),a1				; load its pointer to a1
		jsr	(a1)					; jump to its code
	endm
; ==============================================================
; --------------------------------------------------------------
; Macro to jump to the next object
; --------------------------------------------------------------

oNext			macro
		movea.w	next(a0),a0				; load the next object address to a0
		move.l	ptr(a0),a1				; load its pointer to a1
		jmp	(a1)					; jump to its code
	endm
; ==============================================================
; --------------------------------------------------------------
; Macro to add object to display list
;
;   layer =	The destination display layer
;   obj =	The address register for the source object
;   fre =	A free-to-user address register
;   chk =	If 1, the code also checks if the object is
;		  displayed already
; --------------------------------------------------------------

oAddDisplay		macro	layer, obj, fre, chk
	if layer >= dislayercount
		inform 2,"Invalid display layer!"
	endif

	if \chk
		tst.w	ddnext(\reg)				; check if displayed already
		bne.s	.no\@					; if yes, skip
	endif

		move.w	#DisplayList + (\layer*ddsize),ddnext(\obj); put end marker as the next pointer
		move.w	DisplayList + ddprev + (\layer*ddsize).w,\fre; copy the pointer from the end marker to dst register
		move.w	\fre,ddprev(\obj)			; copy that to prev pointer
		move.w	\obj,ddnext(\fre)			;
		move.w	\obj,DisplayList + ddprev + (\layer*ddsize).w; copy the pointer from the end marker to dst register
.no\@
	endm
; ==============================================================
; --------------------------------------------------------------
; Macro to add object to display list using an address register
;
;   reg =	The address regsister containing target
;		  display layer
;   obj =	The address register for the source object
;   fre =	A free-to-user address register
;   chk =	If 1, the code also checks if the object is
;		  displayed already
; --------------------------------------------------------------

oAddDisplayReg		macro	reg, obj, fre, chk
	local layer
layer EQUR	\reg						; convert register

	if \chk
		tst.w	ddnext(\reg)				; check if displayed already
		bne.s	.no\@					; if yes, skip
	endif

		move.w	layer,ddnext(\obj)			; put end marker as the next pointer
		move.w	ddprev(layer),\fre			; copy the pointer from the end marker to dst register
		move.w	\fre,dprev(\obj)			; copy that to prev pointer
		move.w	\obj,ddnext(\fre)			;
		move.w	\obj,ddprev(layer)			; copy the pointer from the end marker to dst register
.no\@
	endm
; ==============================================================
; --------------------------------------------------------------
; Macro to remove object from display list
;
;   obj =	The address register for the source object
;   fre =	A free-to-user address register
;   chk =	If 1, the code also checks if the object is
;		  displayed already
; --------------------------------------------------------------

oRmvDisplay		macro	obj, fre, chk
	if \chk
		tst.w	ddnext(\reg)				; check if displayed already
		beq.s	.yes\@					; if not, skip
	endif

		move.w	ddprev(\obj),\fre			; load the prev pointer to dst
		move.w	ddnext(\obj),ddnext(\fre)		; copy the next object pointer from src to dst
		move.w	ddnext(\obj),\fre			; load the next pointer to dst
		move.w	ddprev(\obj),ddprev(\fre)		; copy the prev object pointer from src to dst
.yes\@
	endm
