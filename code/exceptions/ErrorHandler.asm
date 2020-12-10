
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

; Advanced execution flags
; WARNING! For experts only, DO NOT USES them unless you know what you're doing
_eh_return		equ	$20
_eh_enter_console	equ	$40
_eh_align_offset	equ	$80

; ---------------------------------------------------------------
; Errors vector table
; ---------------------------------------------------------------

; Default screen configuration
_eh_default			equ	0 ;_eh_show_sr_usp

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
	__ErrorMessage "LINE 1010 EMULATOR", _eh_default

exLineF:
	__ErrorMessage "LINE 1111 EMULATOR", _eh_default

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

; ---------------------------------------------------------------
; Software exception handlers
; ---------------------------------------------------------------

.checksum
		move.l	(sp)+,a0				; load item back from stack
	__ErrorMessage "CHECKSUM FAILED", _eh_default
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
; Import error handler global functions
; ---------------------------------------------------------------

ErrorHandler.__global__error_initconsole equ ErrorHandler+$146
ErrorHandler.__global__errorhandler_setupvdp equ ErrorHandler+$234
ErrorHandler.__global__console_loadpalette equ ErrorHandler+$A1C
ErrorHandler.__global__console_setposasxy_stack equ ErrorHandler+$A58
ErrorHandler.__global__console_setposasxy equ ErrorHandler+$A5E
ErrorHandler.__global__console_getposasxy equ ErrorHandler+$A8A
ErrorHandler.__global__console_startnewline equ ErrorHandler+$AAC
ErrorHandler.__global__console_setbasepattern equ ErrorHandler+$AD4
ErrorHandler.__global__console_setwidth equ ErrorHandler+$AE8
ErrorHandler.__global__console_writeline_withpattern equ ErrorHandler+$AFE
ErrorHandler.__global__console_writeline equ ErrorHandler+$B00
ErrorHandler.__global__console_write equ ErrorHandler+$B04
ErrorHandler.__global__console_writeline_formatted equ ErrorHandler+$BB0
ErrorHandler.__global__console_write_formatted equ ErrorHandler+$BB4


; ---------------------------------------------------------------
; Error handler external functions (compiled only when used)
; ---------------------------------------------------------------


	if ref(ErrorHandler.__extern_scrollconsole)
ErrorHandler.__extern__scrollconsole:

	endc

	if ref(ErrorHandler.__extern__console_only)
ErrorHandler.__extern__console_only:
	dc.l	$46FC2700, $4FEFFFF2, $48E7FFFE, $47EF003C
	jsr		ErrorHandler.__global__errorhandler_setupvdp(pc)
	jsr		ErrorHandler.__global__error_initconsole(pc)
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
	incbin	"code/exceptions/ErrorHandler.bin"

; ---------------------------------------------------------------
; WARNING!
;	DO NOT put any data from now on! DO NOT use ROM padding!
;	Symbol data should be appended here after ROM is compiled
;	by ConvSym utility, otherwise debugger modules won't be able
;	to resolve symbol names.
; ---------------------------------------------------------------