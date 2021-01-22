
; ===============================================================
; ---------------------------------------------------------------
; Error handling and debugging modules
; 2016-2017, Vladikcomper
; ---------------------------------------------------------------
; Error handler functions and calls
; ---------------------------------------------------------------

; ---------------------------------------------------------------
; Error handler control flags
; ---------------------------------------------------------------

; Screen appearence flags
_eh_address_error	equ	$01		; use for address and bus errors only (tells error handler to display additional "Address" field)
_eh_show_sr_usp		equ	$02		; displays SR and USP registers content on error screen
_eh_disassemble		equ	$10		; disassembles the instruction where the error happened + vint and hint handlers

; Advanced execution flags
; WARNING! For experts only, DO NOT USES them unless you know what you're doing
_eh_return		equ	$20
_eh_enter_console	equ	$40
_eh_align_offset	equ	$80

; ---------------------------------------------------------------
; Errors vector table
; ---------------------------------------------------------------

; Default screen configuration
_eh_default			equ	_eh_disassemble ;_eh_show_sr_usp

; ---------------------------------------------------------------
exBus:
	__ErrorMessage "BUS ERROR", _eh_default|_eh_address_error

exAddr:
	__ErrorMessage "ADDRESS ERROR", _eh_default|_eh_address_error

exIll:
	__ErrorMessage "ILLEGAL INSTRUCTION", _eh_default

exDiv:
	__ErrorMessage "ZERO DIVIDE", _eh_default

exChk:
	__ErrorMessage "CHK INSTRUCTION", _eh_default

Trapv:
	__ErrorMessage "TRAPV INSTRUCTION", _eh_default

exPriv:
	__ErrorMessage "PRIVILEGE VIOLATION", _eh_default

exTrace:
	__ErrorMessage "TRACE", _eh_default

exLineA:
	__ErrorMessage "LINE A EMULATOR", _eh_default

exLineF:
	__ErrorMessage "LINE F EMULATOR", _eh_default

exMisc:
	__ErrorMessage "MISC EXCEPTION", _eh_default

; ---------------------------------------------------------------
; Software exception table
; ---------------------------------------------------------------
Trap0:
Trap1:
Trap2:
Trap3:
Trap4:
Trap5:
Trap6:
Trap7:
Trap8:
Trap9:
TrapA:
TrapB:
TrapC:
TrapD:
TrapE:

TrapF:
		pea	(a0)					; push a0 into the stack
		move.l	6(sp),a0				; load return address to a0
		move.w	(a0),a0					; load the error number to a0
		move.w	.errors(pc,a0.w),a0			; load table offset to a0
		jmp	.errors(pc,a0.w)			; jump to the correct error code
; ---------------------------------------------------------------

.errors
		dc.w .checksum-.errors			; 0	; exChecksum
		dc.w .createplat-.errors		; 2	; exCreatePlat
		dc.w .createtouch-.errors		; 4	; exCreateTouch
		dc.w .createdart-.errors		; 6	; exCreateDynArt
		dc.w .createobj-.errors			; 8	; exCreateObj
		dc.w .nodebug-.errors			; A	; exNoDebug
		dc.w .fulldma-.errors			; C	; exFullDMA
		dc.w .addkosm-.errors			; E	; exAddKosm
		dc.w .addkos-.errors			; 10	; exAddKos
; ---------------------------------------------------------------
; Software exception handlers
; ---------------------------------------------------------------

.checksum
		move.l	(sp)+,a0				; load item back from stack
	RaiseError	"CHECKSUM FAILED", .pchecksum, 0

.pchecksum
	Console.WriteLine "%<pal0>Expected checksum:   %<pal2>%<.l Checksum.w hex>"
	Console.WriteLine "%<pal0>Calculated checksum: %<pal2>%<.l d0 hex>"
	Console.WriteLine "%<pal0>End Address: %<.l d1 sym|split>%<pal2>%<symdisp>"
		bra.s	*
; ---------------------------------------------------------------

.createplat
		move.l	(sp)+,a0				; load item back from stack
	__ErrorMessage "PLATFORM ARRAY FULL", _eh_default
; ---------------------------------------------------------------

.createtouch
		move.l	(sp)+,a0				; load item back from stack
	__ErrorMessage "TOUCH ARRAY FULL", _eh_default
; ---------------------------------------------------------------

.createdart
		move.l	(sp)+,a0				; load item back from stack
	__ErrorMessage "DYNART ARRAY FULL", _eh_default
; ---------------------------------------------------------------

.createobj
		move.l	(sp)+,a0				; load item back from stack
		move.l	6(sp),2(sp)				; copy previous routine pointer as the debug routine. Hax I know.
	__ErrorMessage "OBJECT ARRAY FULL", _eh_default
; ---------------------------------------------------------------

.addkosm
		move.l	(sp)+,a0				; load item back from stack
		move.l	6(sp),2(sp)				; copy previous routine pointer as the debug routine. Hax I know.
	__ErrorMessage "KOSINSKI MODULE ARRAY FULL", _eh_default
; ---------------------------------------------------------------

.addkos
		move.l	(sp)+,a0				; load item back from stack
		move.l	6(sp),2(sp)				; copy previous routine pointer as the debug routine. Hax I know.
	__ErrorMessage "KOSINSKI ARRAY FULL", _eh_default
; ---------------------------------------------------------------

.nodebug
		move.l	(sp)+,a0				; load item back from stack
	if DEBUG
		__ErrorMessage "DEBUG EXCEPTION WHEN DEBUG=1 ???", _eh_default
	else
		__ErrorMessage "BUILD WITH DEBUG=1", _eh_default
	endif
; ---------------------------------------------------------------

.fulldma
	if DEBUG
		move.l	(sp)+,a0				; load item back from stack
	__ErrorMessage "DMA QUEUE FULL", _eh_default
	endif

; ---------------------------------------------------------------
; Import error handler global functions
; ---------------------------------------------------------------

	include "code/exceptions/source/ErrorHandler.Global.ASM68K.asm"

; ---------------------------------------------------------------
; Error handler external functions (compiled only when used)
; ---------------------------------------------------------------


	if ref(ErrorHandler.__extern_scrollconsole)
ErrorHandler.__extern__scrollconsole:

	endc

	if ref(ErrorHandler.__extern__console_only)
ErrorHandler.__extern__console_only:
	dc.l	$46FC2700, $4FEFFFF2, $48E7FFFE, $47EF003C
	jsr	ErrorHandler.__global__errorhandler_setupvdp(pc)
	jsr	ErrorHandler.__global__error_initconsole(pc)
	dc.l	$4CDF7FFF, $487A0008, $2F2F0012, $4E7560FE
	endc

	if ref(ErrorHandler.__extern__vsync)
ErrorHandler.__extern__vsync:
	dc.l	$41F900C0, $000444D0, $6BFC44D0, $6AFC4E75
	endc

; ---------------------------------------------------------------
; Include error handler binary module
; ---------------------------------------------------------------

ErrorHandler:
	incbin	"code/exceptions/source/ErrorHandler.bin"

; ---------------------------------------------------------------
; WARNING!
;	DO NOT put any data from now on! DO NOT use ROM padding!
;	Symbol data should be appended here after ROM is compiled
;	by ConvSym utility, otherwise debugger modules won't be able
;	to resolve symbol names.
; ---------------------------------------------------------------
