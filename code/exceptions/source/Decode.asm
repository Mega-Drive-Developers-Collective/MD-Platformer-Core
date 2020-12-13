; ===========================================================================
; ---------------------------------------------------------------------------
; 68k decoder macros
;
; register usage:
;   a0 = instruction address
;   a1 = text buffer address
;   a2 = script address
;   a3 = stack address
;   a4-a6 = various other uses
;
;   d0 = instruction word
;   d1 = command parameter
;   d2-d5 = various other uses
;   d6 = instruction size
; ---------------------------------------------------------------------------
; equates

d68k_white =	$0000							; text color white
d68k_green =	$6000							; text color green
d68k_blue =	$2000							; text color blue
d68k_red =	$4000							; text color red

dcwhite =	$80|(d68k_white>>8)					; white that can be included in a string
dcgreen =	$80|(d68k_green>>8)					; green that can be included in a string
dcblue =	$80|(d68k_blue>>8)					; blue that can be included in a string
dcred =		$80|(d68k_red>>8)					; red that can be included in a string

	rsset 0
d68ke_Exec		rs.w 1						; execute routine
d68ke_Jump		rs.w 1						; jump command
d68ke_Finish		rs.w 1						; script finish command
d68ke_Print		rs.w 1						; print string command
d68ke_PrintNum		rs.w 1						; print number from stack command
d68ke_ReadSrc		rs.w 1						; read words from the source and AND it
d68ke_Read		rs.w 1						; read words and AND it
d68ke_InsSz		rs.w 1						; print normal instruction size
d68ke_Reg		rs.w 1						; print a register
d68ke_DataReg		rs.w 1						; print a data register
d68ke_AddrReg		rs.w 1						; print an address register
d68ke_Mode		rs.w 1						; print an addressing mode
d68ke_Cmp		rs.w 1						; check and jump if true
d68ke_SmallSz		rs.w 1						; print small instruction size
d68ke_Push		rs.w 1						; push words into stack
d68ke_Pop		rs.w 1						; move stack pointer
d68ke_Swap		rs.w 1						; swap top of stack with another entry
d68ke_Size		rs.w 1						; create instruction size
d68ke_Char		rs.w 1						; print character
d68ke_Mode2		rs.w 1						; print an alternate addressing mode

	rsset 0
d68kn_Byte		rs.w 1						; byte number type
d68kn_Word		rs.w 1						; word number type
d68kn_Addr		rs.w 1						; addr number type
d68kn_Long		rs.w 1						; long number type
; ---------------------------------------------------------------------------
; constants

d68k_StoreSrc =	$FFFF8000						; stored source address
d68k_StoreDst =	$FFFF8004						; stored destination address
d68k_Stack =	$FFFF8100						; stack address
d68k_ShowAddr = 1							; set to 1 to enable printing address to output buffer
; ---------------------------------------------------------------------------
; macros

; create a routine reference
d68k_Ref	macro addr
	rept narg							; run for all args
		dc.w \addr-*-2						; routine offset
	shift								; shift to next entry
	endr
    endm

; execute a 68k routine
d68k_Exec	macro addr, extra
	dc.b d68ke_Exec, 0
	d68k_Ref	\addr
    endm

; jump to a script address
d68k_Jump	macro addr
	dc.b d68ke_Jump, 0
	d68k_Ref	\addr
    endm

; finish decoding and exit
d68k_Finish	macro
	dc.b d68ke_Finish, 0
    endm

; print external string with an additional character
d68k_Print	macro extra, addr
	dc.b d68ke_Print, \extra
	d68k_Ref	\addr
    endm

; write a single character
d68k_Char	macro char
	dc.b d68ke_Char, \char
    endm

; print a number from stack of a specific type
d68k_PrintNum	macro type
	dc.b d68ke_PrintNum, \type
    endm

; pop certain number of bytes from stack
d68k_Pop	macro offset
	dc.b d68ke_Pop, \offset
    endm

; swap the topmost entry with entry at a specific offset
d68k_Swap	macro offset
	dc.b d68ke_Swap, \offset
    endm

; read number of times from the opcode to stack with specific AND values
d68k_ReadSrc	macro and
	dc.b d68ke_ReadSrc, narg-1

	rept narg
		dc.w \and
	shift
	endr
    endm

; read a number of words from the ROM into the stack with specific AND values
d68k_Read	macro and
	dc.b d68ke_Read, narg-1

	rept narg
		dc.w \and
	shift
	endr
    endm

; push number of values to stack
d68k_Push	macro val
	dc.b d68ke_Push, narg-1

	rept narg
		dc.w \val
	shift
	endr
    endm

; print normal instruction size with a shift amount
d68k_InsSz	macro shift
	dc.b d68ke_InsSz, \shift
    endm

; print a small instruction size based on a specific bit
d68k_SmallSz	macro bit
	dc.b d68ke_SmallSz, \bit
    endm

; force a specific instruction size for instruction
d68k_Size	macro size
	dc.b d68ke_Size, \size
    endm

; print a specific register with a shift count (bit3 decides between data and address)
d68k_Reg	macro shift
	dc.b d68ke_Reg, \shift
    endm

; print a data register with a shift count
d68k_DataReg	macro shift
	dc.b d68ke_DataReg, \shift
    endm

; print an address register with a shift count
d68k_AddrReg	macro shift
	dc.b d68ke_AddrReg, \shift
    endm

; print a regular addressing mode based on a few stack values and an additional character
d68k_Mode	macro char
	dc.b d68ke_Mode, \char
    endm

; print a regular addressing mode based on a few stack values and an additional character but with different shift values
d68k_Mode2	macro char
	dc.b d68ke_Mode2, \char
    endm

; compare the top of stack with the check value, offset the stack a specific value and if compare matches, jump to address
d68k_Cmp	macro offset, check, addr
	dc.b d68ke_Cmp, \offset
	dc.w \check
	d68k_Ref	\addr
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; 68k decoder program
;
; input:
;   a0 = source instruction address
;   a1 = destination buffer address
;
; output:
;   a0 = next instruction address
;   a1 = next buffer address
;   buffer = text generated with color highlight, and end token
; ---------------------------------------------------------------------------

d68k_HighNibble:
		d68k_Ref d68k_i0xxx, d68k_iMove, d68k_iMove, d68k_iMove
		d68k_Ref d68k_i4xxx, d68k_i5xxx, d68k_iBCC,  d68k_iMoveq
		d68k_Ref d68k_i8xxx, d68k_iSub,  d68k_iData, d68k_iBxxx
		d68k_Ref d68k_iCxxx, d68k_iAdd,  d68k_iExxx, d68k_iData
; ---------------------------------------------------------------------------

Decode68k:
		lea	d68k_Stack.w,a3					; load stack address

	if d68k_ShowAddr
		move.l	a0,(a3)+					; copy ROM address to stack
		jsr	d68k_PrintAddr(pc)				; print it
		move.w	#dcred|' ',(a1)+				; write a space
	endif

		move.l	a1,d68k_StoreDst.w				; copy destination address to RAM
		move.l	a0,d68k_StoreSrc.w				; copy source address to RAM

		move.w	(a0)+,d0					; load the next byte from source
		move.w	d0,d1						; copy to d1
		and.w	#$F000,d1					; get the highest nibble
		rol.w	#5,d1						; rotate 6 bits, so each nibble gets a long word
		lea	d68k_HighNibble(pc,d1.w),a2			; load script data to a2
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to jump to another script address
; ---------------------------------------------------------------------------

d68k_rJump:
		add.w	(a2)+,a2					; add offset to script address
; ===========================================================================
; ---------------------------------------------------------------------------
; Run decoder script
; ---------------------------------------------------------------------------

d68k_RunScript:
		moveq	#0,d2
		move.b	(a2)+,d2					; load next instruction to d2
		moveq	#0,d1
		move.b	(a2)+,d1					; load argument to d1
		ext.w	d1						; extend to word

		move.w	.ins(pc,d2.w),d2				; load target offset to d1
		jmp	.ins(pc,d2.w)					; execute it
; ---------------------------------------------------------------------------

.ins		dc.w d68k_rExec-.ins, d68k_rJump-.ins, d68k_rFinish-.ins, d68k_rPrint-.ins
		dc.w d68k_rPrintNum-.ins, d68k_rReadSrc-.ins, d68k_rRead-.ins, d68k_rInsSz-.ins
		dc.w d68k_rPrintReg-.ins, d68k_rPrintDataReg-.ins, d68k_rPrintAddrReg-.ins
		dc.w d68k_rMode-.ins, d68k_rCmp-.ins, d68k_rPrintSmallSize-.ins, d68k_rPush-.ins
		dc.w d68k_rPop-.ins, d68k_rSwap-.ins, d68k_rSize-.ins, d68k_rChar-.ins
		dc.w d68k_rMode2-.ins
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to execute ASM code
; ---------------------------------------------------------------------------

d68k_rExec:
		move.w	(a2)+,a4					; load next address as the base address
		add.w	a2,a4						; add script address to it
		jmp	(a4)						; execute the code
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print a string
; ---------------------------------------------------------------------------

d68k_rPrint:
		move.w	(a2)+,a4					; load next address as the base address
		add.w	a2,a4						; add script address to it

d68k_rPrint3:
		pea	d68k_RunScript(pc)				; run the script later

d68k_rPrint2:
		moveq	#0,d2						; set colour to default
		bra.s	.print
; ---------------------------------------------------------------------------

.char
		move.b	(a4)+,d2					; load character to d1
		move.w	d2,(a1)+					; save into buffer

.print
		tst.b	(a4)						; check the next character
		bgt.s	.char						; if positive, read character
		beq.s	.null						; if null, its the end marker

		moveq	#$7F,d2						; prepare AND value
		and.b	(a4)+,d2					; get only the color component
		lsl.w	#8,d2						; shift into place
		bra.s	.print
; ---------------------------------------------------------------------------

.null
		move.b	d1,d2						; copy extra parameter to d2
		beq.s	.rts						; if was null, skip this
		move.w	d2,(a1)+					; save into buffer

.rts
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print a character
; ---------------------------------------------------------------------------

d68k_rChar:
		move.w	d1,(a1)+					; save into buffer
		bra.s	d68k_JumpScript1
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to compare stack variable with value and jump if the same
; ---------------------------------------------------------------------------

d68k_rCmp:
		move.w	-2(a3),d2					; load value from stack
		add.w	d1,a3						; offset stack with parameter

		cmp.w	(a2)+,d2					; check if value is the same
		beq.w	d68k_rJump					; if yes, execute a jump
		addq.w	#2,a2						; skip parameter
		bra.s	d68k_JumpScript1
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to move stack pointer
; ---------------------------------------------------------------------------

d68k_rPop:
		add.w	d1,a3						; offset the stack pointer
		bra.s	d68k_JumpScript1
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to read a value from source
; ---------------------------------------------------------------------------

d68k_rRead:
		move.w	(a0)+,d3					; read value from source
		bra.s	d68k_rRead2					; run common code

d68k_rReadSrc:
		move.w	d0,d3						; read instruction to d3
; ---------------------------------------------------------------------------

d68k_rRead2:
		move.w	(a2)+,d2					; read AND value from script
		and.w	d3,d2						; AND with the read value
		move.w	d2,(a3)+					; write to stack
		dbf	d1,d68k_rRead2					; loop for all writes
; ===========================================================================
; ---------------------------------------------------------------------------
; Go back to runnin the script
; ---------------------------------------------------------------------------

d68k_JumpScript1:
		jmp	d68k_RunScript(pc)				; run the script now
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to push data to stack
; ---------------------------------------------------------------------------

d68k_rPush:
		move.w	(a2)+,(a3)+					; push value from script
		dbf	d1,d68k_rPush					; loop for all pushes
		bra.s	d68k_JumpScript1				; continue script execute
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to swap stack entries
; ---------------------------------------------------------------------------

d68k_rSwap:
		move.w	-2(a3),d2					; copy stack entry to d2
		move.w	-2(a3,d1.w),-2(a3)				; write earlier entry to stack top
		move.w	d2,-2(a3,d1.w)					; write the other entry to target
		bra.s	d68k_JumpScript1				; continue script execute
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print a number from stack
; ---------------------------------------------------------------------------

d68k_rPrintNum:
		pea	d68k_RunScript(pc)				; run the script later
		move.w	.tbl(pc,d1.w),d1				; load target offset to d1
		jmp	.tbl(pc,d1.w)					; execute it
; ---------------------------------------------------------------------------

.tbl		dc.w d68k_PrintByte-.tbl, d68k_PrintWord-.tbl
		dc.w d68k_PrintAddr2-.tbl, d68k_PrintLong-.tbl
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print an address as characters
; ---------------------------------------------------------------------------

d68k_PrintAddr:
		moveq	#6-1,d3						; prepare loop count to d3
		move.l	-(a3),d1					; read data from stack
		rol.l	#8,d1						; skip highest 8 bits
		bra.s	d68k_PrintCom
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print a longword as characters
; ---------------------------------------------------------------------------

d68k_PrintLong:
		moveq	#8-1,d3						; prepare loop count to d3
		move.l	-(a3),d1					; read data from stack
		bra.s	d68k_PrintCom
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print a byte as characters
; ---------------------------------------------------------------------------

d68k_PrintByte:
		moveq	#2-1,d3						; prepare loop count to d3
		move.w	-(a3),d1					; read data from stack
		ror.l	#8,d1						; shift into place
		bra.s	d68k_PrintCom
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print a word as characters
; ---------------------------------------------------------------------------

d68k_PrintWord:
		moveq	#4-1,d3						; prepare loop count to d3
		move.w	-(a3),d1					; read data from stack
		swap	d1						; shift 16 bits
; ===========================================================================
; ---------------------------------------------------------------------------
; Common routine to print a number as characters
;
; input:
;   d1 = data to write, shifted in place
;   d3 = character count
; ---------------------------------------------------------------------------

d68k_PrintCom:
		move.w	#d68k_red|'$',(a1)+				; write hex symbol
		move.w	#d68k_red,d4					; prepare red colour to d4

.char
		rol.l	#4,d1						; get first 4 bits into view
		moveq	#$F,d2						; get bitmask to d2
		and.w	d1,d2						; get only single digt

		move.b	d68k_DigitTbl(pc,d2.w),d4			; load digit into d4
		move.w	d4,(a1)+					; copy into buffer
		dbf	d3,.char					; loop for every character
		rts
; ---------------------------------------------------------------------------

d68k_DigitTbl:	dc.b '0123456789ABCDEF'
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print an address register
;
; input:
;   d2 = register number
; ---------------------------------------------------------------------------

d68k_rPrintAddrReg:
		bsr.s	d68k_ShiftIns					; shift instruction into place

d68k_PrintAddrReg2:
		pea	d68k_RunScript(pc)				; run the script later

d68k_PrintAddrReg3:
		move.w	#d68k_green|'a',(a1)+				; write a into buffer
		move.w	#d68k_green,d1					; prepare green color

		and.w	#7,d2						; keep in range
		move.b	d68k_DigitTbl(pc,d2.w),d1			; load number into d1
		move.w	d1,(a1)+					; save into buffer
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print a data register
;
; input:
;   d2 = register number
; ---------------------------------------------------------------------------

d68k_rPrintDataReg:
		bsr.s	d68k_ShiftIns					; shift instruction into place

d68k_PrintDataReg2:
		pea	d68k_RunScript(pc)				; run the script later

d68k_PrintDataReg3:
		move.w	#d68k_green|'d',(a1)+				; write d into buffer
		move.w	#d68k_green,d1					; prepare green color

		and.w	#7,d2						; keep in range
		move.b	d68k_DigitTbl(pc,d2.w),d1			; load number into d2
		move.w	d1,(a1)+					; save into buffer
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print a register. If bit4 is set, its a address register. If clear, data
;
; input:
;   d2 = register number
; ---------------------------------------------------------------------------

d68k_rPrintReg:
		bsr.s	d68k_ShiftIns					; shift instruction into place

d68k_PrintReg2:
		pea	d68k_RunScript(pc)				; run the script later

d68k_PrintReg3:
		bclr	#3,d2						; check if address or data
		bne.s	d68k_PrintAddrReg3				; branch if address
		bra.s	d68k_PrintDataReg3
; ===========================================================================
; ---------------------------------------------------------------------------
; Shift instruction into place according to d1
;
; input:
;   d1 = shift count
;
; output:
;   d2 = result
; ---------------------------------------------------------------------------

d68k_ShiftIns:
		move.w	d0,d2						; copy instruction into d2
		lsr.w	d1,d2						; shift according to param
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to load instruction size
; ---------------------------------------------------------------------------

d68k_rSize:
		move.w	d1,d6						; save size to d6
; ===========================================================================
; ---------------------------------------------------------------------------
; Go back to runnin the script
; ---------------------------------------------------------------------------

d68k_JumpScript2:
		jmp	d68k_RunScript(pc)				; run the script now
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to print instruction size
; ---------------------------------------------------------------------------

d68k_rInsSz:
		bsr.s	d68k_ShiftIns					; shift instruction into place
		move.w	#d68k_blue,d6					; prepare green color
		and.w	#3,d2						; keep in range
		move.b	d68k_InsSize(pc,d2.w),d6			; load instruction size to d6

d68k_rInsSz2:
		beq.w	d68k_Data					; execute as data
		move.w	#d68k_blue|'.',(a1)+				; print . into buffer
		move.w	d6,(a1)+					; copy it to buffer
		bra.s	d68k_JumpScript2

d68k_InsSize:	dc.b 'bwl', 0
; ---------------------------------------------------------------------------

d68k_MoveSz:
		moveq	#12,d1						; shift 12 bits
		bsr.s	d68k_ShiftIns					; shift instruction into place

		move.w	#d68k_blue,d6					; prepare green color
		and.w	#3,d2						; keep in range
		move.b	.size(pc,d2.w),d6				; load instruction size to d6
		bra.s	d68k_rInsSz2					; execute common code

.size		dc.b 0, 'blw'
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to check and print instruction mode
; ---------------------------------------------------------------------------

d68k_rMode2:
		moveq	#9,d3						; register shift count 9
		moveq	#6,d4						; mode shift count 6
		bra.s	d68k_ModeCom

d68k_rMode:
		moveq	#0,d3						; register shift count 0
		moveq	#3,d4						; mode shift count 3

d68k_ModeCom:
		tst.b	d1						; check character argument
		beq.s	.skip						; if was null, skip this
		move.w	d1,(a1)+					; save into buffer
; ---------------------------------------------------------------------------

.skip
		move.b	d3,d1						; load the shift count to d1
		bsr.s	d68k_ShiftIns					; shift instruction into place
		moveq	#7,d3						; get the register mask
		move.w	d3,d5						; copy into d5
		and.w	d2,d3						; and with the read value

		move.b	d4,d1						; load the shift count to d1
		bsr.s	d68k_ShiftIns					; shift instruction into place
		and.w	d5,d2						; keep mode in range

		move.w	d2,d4						; copy mode to d4
		cmp.w	d5,d4						; check if mode 7
		bne.s	.not7						; if not, skip
		add.w	d3,d4						; add register to mode check

.not7
		move.w	-(a3),d1					; load mode check from stack
		btst	d4,d1						; check if the mode is actually valid
		beq.w	d68k_Data					; execute as data
; ---------------------------------------------------------------------------

		exg	d3,d2						; swap register and mode
		add.w	d3,d3						; double mode
		move.w	.tbl(pc,d3.w),d3				; load target offset to d1
		jmp	.tbl(pc,d3.w)					; execute it
; ---------------------------------------------------------------------------

.tbl		dc.w d68k_PrintDataReg2-.tbl,  d68k_rModeAreg-.tbl
		dc.w d68k_rModeAind-.tbl,  d68k_rModeApind-.tbl
		dc.w d68k_rModeAmind-.tbl, d68k_rModeAoind-.tbl
		dc.w d68k_rModeANXN-.tbl,  .reg-.tbl
; ---------------------------------------------------------------------------

.reg
		add.w	d2,d2						; double register
		move.w	.tbl2(pc,d2.w),d2				; load target offset to d1
		jmp	.tbl2(pc,d2.w)					; execute it
; ---------------------------------------------------------------------------

.tbl2		dc.w d68k_rModeAddrW-.tbl2, d68k_rModeAddrL-.tbl2
		dc.w d68k_rModePind-.tbl2,  d68k_rModePCXN-.tbl2
		dc.w d68k_rModeImm-.tbl2,   d68k_rModeData2-.tbl2
		dc.w d68k_rModeData2-.tbl2, d68k_rModeData2-.tbl2
; ===========================================================================
; ---------------------------------------------------------------------------
; print address register string
; ---------------------------------------------------------------------------

d68k_rModeAreg:
		cmp.b	#'b',d6						; check if instruction is a byte instruction
		bne.w	d68k_PrintAddrReg2				; if not, branch

d68k_rModeData2:
		jmp	d68k_Data(pc)					; invalid instruction
; ===========================================================================
; ---------------------------------------------------------------------------
; print address register and pc-relative indirect string
; ---------------------------------------------------------------------------

d68k_rModeAmind:
		move.w	#d68k_white|'-',(a1)+				; write - into buffer
		bra.s	d68k_rModeAind
; ---------------------------------------------------------------------------

d68k_ModeAoind2:
		move.w	d0,d2						; copy instruction to d2

d68k_rModeAoind:
		move.w	d2,a4						; copy register temporarily
		move.w	(a0)+,(a3)+					; read word from source
		jsr	d68k_PrintWord(pc)				; print it
		move.w	a4,d2						; get it back
; ---------------------------------------------------------------------------

d68k_rModeAind:
		pea	d68k_RunScript(pc)				; run the script later

d68k_rModeAind2:
		move.w	#d68k_white|'(',(a1)+				; write ( into buffer
		jsr	d68k_PrintAddrReg3(pc)				; write the address register into buffer
		move.w	#d68k_white|')',(a1)+				; write ) into buffer
		rts
; ---------------------------------------------------------------------------

d68k_ModeApind2:
		move.w	d0,d2						; copy instruction to d2
		move.w	-(a3),d1					; load shfit count to d1
		ror.w	d1,d2						; rotate according to count

d68k_rModeApind:
		bsr.s	d68k_rModeAind2					; write indirect data into buffer
		move.w	#d68k_white|'+',(a1)+				; write + into buffer
		bra.s	d68k_JumpScript3
; ---------------------------------------------------------------------------

d68k_rModePind:
	if checkall
		sub.l	a4,a4
	else
		move.l	a0,a4						; copy current address to a4
	endif
		add.w	(a0)+,a4					; offset with the word
		move.l	a4,d1						; copy result to d1
		jsr	d68k_ResolveAddr(pc)				; print it

		move.l	d68k_StrPC(pc),(a1)+				; write (p into buffer
		move.l	d68k_StrPC+4(pc),(a1)+				; write c) into buffer
		bra.s	d68k_JumpScript3
; ===========================================================================
; ---------------------------------------------------------------------------
; print address register indirect and pc-relative with register displacement
; ---------------------------------------------------------------------------

d68k_rModeANXN:
		move.w	d2,a4						; copy register temporarily
		move.w	(a0)+,d5					; read extension word from source
		move.w	d5,(a3)+					; store it in stack
		jsr	d68k_PrintByte(pc)				; print byte displacement

		move.w	#d68k_white|'(',(a1)+				; write ( into buffer
		move.w	a4,d2						; get regiser back
		jsr	d68k_PrintAddrReg3(pc)				; print address register
; ---------------------------------------------------------------------------

d68k_ModeCommXN:
		move.w	d5,d1						; copy extension to d1
		and.w	#$700,d1					; check if any unused bits are set
		bne.s	d68k_rModeData2					; if yes, its data nao

		move.w	#d68k_white|',',(a1)+				; write , into buffer
		move.w	d5,d2						; copy extension to d2
		rol.w	#4,d2						; get the register bits to low bits
		jsr	d68k_PrintReg3(pc)				; print the register

		btst	#11,d5						; check if this is a longword
		sne	d1						; if yes, results in 4
		and.w	#4,d1						; if not, results in 0
		move.l	d68k_SizeXN(pc,d1.w),(a1)+			; read size into buffer
		move.w	#d68k_white|')',(a1)+				; write ) into buffer
; ===========================================================================
; ---------------------------------------------------------------------------
; Go back to running the script
; ---------------------------------------------------------------------------

d68k_JumpScript3:
		jmp	d68k_RunScript(pc)				; run the script now
; ---------------------------------------------------------------------------

d68k_StrPC:	dc.w d68k_white|'(', d68k_green|'p', d68k_green|'c', d68k_white|')'

d68k_rModePCXN:
		move.w	(a0)+,d1					; read extension word from source
		move.w	d1,d5						; copy extension to d4
		ext.w	d1						; extend byte offset to word
		subq.w	#2,d1						; account for the word read

		ext.l	d1						; extend it to longword

	if checkall
		addq.l	#2,d1
	else
		add.l	a0,d1						; add current address to d1
	endif
		jsr	d68k_ResolveAddr(pc)				; print resulting address

		move.l	d68k_StrPC(pc),(a1)+				; write (p into buffer
		move.w	d68k_StrPC+4(pc),(a1)+				; write c into buffer
		bra.s	d68k_ModeCommXN					; run the rest of the code the same

d68k_SizeXN:	dc.w d68k_blue|'.', d68k_blue|'w', d68k_blue|'.', d68k_blue|'l'
; ===========================================================================
; ---------------------------------------------------------------------------
; print direct address word and long
; ---------------------------------------------------------------------------

d68k_rPrintSmallSize:
		pea	d68k_RunScript(pc)				; run the script later
		btst	d1,d0						; check if bit was set

d68k_PrintSmallSize2:
		sne	d6						; if yes, results in 4
		and.w	#4,d6						; if not, results in 0
		move.l	d68k_SizeXN(pc,d6.w),d6				; read size into d6
		move.l	d6,(a1)+					; copy into buffer
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; print direct address word and long
; ---------------------------------------------------------------------------

d68k_rModeAddrW:
		move.w	(a0)+,d1					; load address into d1
		ext.l	d1						; extend to longword
		move.l	d1,(a3)+					; save into stack

		jsr	d68k_PrintLong(pc)				; print it
		move.l	d68k_SizeXN(pc),(a1)+				; write .w into buffer
		bra.s	d68k_JumpScript3
; ---------------------------------------------------------------------------

d68k_rModeAddrL:
		move.l	(a0)+,(a3)+					; load address into stack
		jsr	d68k_PrintLong(pc)				; print it
		move.l	d68k_SizeXN+4(pc),(a1)+				; write .l into buffer
		bra.s	d68k_JumpScript3
; ===========================================================================
; ---------------------------------------------------------------------------
; print direct address word and long
; ---------------------------------------------------------------------------

d68k_rModeImm:
		pea	d68k_RunScript(pc)				; run the script later
		move.w	#d68k_white|'#',(a1)+				; write # into buffer

		cmp.b	#'l',d6						; check if this is a long instruction
		bne.s	.ckbyte						; if not, check for byte
		move.l	(a0)+,(a3)+					; load the value from source
		jmp	d68k_PrintLong(pc)				; print it
; ---------------------------------------------------------------------------

.ckbyte
		move.w	(a0)+,(a3)+					; load the value from source
		cmp.b	#'b',d6						; check if this is a byte instruction
		bne.w	d68k_PrintWord					; if not, its a word
		jmp	d68k_PrintByte(pc)				; print it
; ===========================================================================
; ---------------------------------------------------------------------------
; Print instruction as a data entry
; ---------------------------------------------------------------------------

d68k_iData:	d68k_Exec	d68k_Data				; execute as assembly

d68k_Data:
		move.l	d68k_StoreDst.w,a1				; restore original destination address
		move.l	d68k_StoreSrc.w,a0				; restore original source address

		lea	.script2(pc),a2					; load secondary script to a2
		jmp	d68k_RunScript(pc)				; run the script now
; ---------------------------------------------------------------------------

.str		dc.b dcblue, 'dc.w', 0
		even

.script2	d68k_Print	' ', .str				; print the string out
; ===========================================================================
; ---------------------------------------------------------------------------
; Common type 7 instruction handler
; ---------------------------------------------------------------------------

d68k_CommonIns7:
		d68k_Read	$FFFF					; read the instruction from source
		d68k_PrintNum	d68kn_Word				; write the word value
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; MOVEQ instruction handler
; ---------------------------------------------------------------------------

d68k_iMoveq:	d68k_ReadSrc	$100					; read the instruction from source
		d68k_Cmp	-2, $100, d68k_iData			; check if this is invalid, and if so, present as data

		d68k_Print	'q', d68k_sMove				; print MOVEQ
		d68k_Print	0, d68k_sVal				; print #
		d68k_ReadSrc	$FF					; read the instruction from source
		d68k_PrintNum	d68kn_Byte				; write the byte value
		d68k_Jump	d68k_WriteReg1				; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; MOVE instruction handler
; ---------------------------------------------------------------------------

d68k_iMove:	d68k_Print	0, d68k_sMove				; print MOVE
		d68k_ReadSrc	$1C0					; read the instruction from source
		d68k_Cmp	-2, $40, .printa			; check if this is a MOVEA, and if so, print a

.cont
		d68k_Exec	d68k_MoveSz				; load size from assembly
		d68k_Push	$1FF, $FFF				; push check values into stack
		d68k_Mode	' '					; print source addressing mode
		d68k_Mode2	','					; print destination addressing mode
		d68k_Finish

.printa		d68k_Print	0, d68k_sA				; print A
		d68k_Jump	.cont					; run rest of the code
; ===========================================================================
; ---------------------------------------------------------------------------
; ADD and SUB instruction handlers
; ---------------------------------------------------------------------------

d68k_iAdd:	d68k_Print	0, d68k_sAdd				; print ADD
		d68k_Jump	d68k_iAddSub				; add and sub share code


d68k_iSub:	d68k_Print	0, d68k_sSub				; print SUB
; ---------------------------------------------------------------------------

d68k_iAddSub:	d68k_ReadSrc	$130, $C0 				; read the instruction from source
		d68k_Cmp	-2, $C0, .adda				; check if this is a ADDA/SUBA, and brach if yes
		d68k_Cmp	-2, $100, .addx				; check if this is a ADDX/SUBX, and brach if yes
		d68k_Push	$FFF, $1FD				; push check values into stack
		d68k_Jump	d68k_CommonIns1				; common instruction type 1
; ---------------------------------------------------------------------------

.adda		d68k_Print	0, d68k_sA				; print A
		d68k_SmallSz	8					; print small instruction size
		d68k_Push	$FFF					; push check value into stack
		d68k_Mode	' '					; print source addressing mode
		d68k_Jump	d68k_CommonIns6				; go to standard handler
; ---------------------------------------------------------------------------

.addx		d68k_Print	0, d68k_sX				; print X
		d68k_InsSz	6					; print instruction size
; ===========================================================================
; ---------------------------------------------------------------------------
; Write standard -(AN),-(AN) or DN,DN register pair
; ---------------------------------------------------------------------------

d68k_iSpecialReg:
		d68k_Exec	d68k_SpecialReg				; load special register pair from assembly
		d68k_Finish
; ---------------------------------------------------------------------------

d68k_SpecialReg:
		move.w	d0,d2						; copy instruction to d2
		move.w	d0,d3						; copy instruction to d3
		rol.w	#16-9,d3					; rotate register into place

		move.w	#d68k_white|' ',(a1)+				; write a space
		btst	#3,d0						; check if this is DN,DN
		bne.s	.anan						; if not, branch
; ---------------------------------------------------------------------------

		jsr	d68k_PrintDataReg3(pc)				; print source register
		move.w	#d68k_white|',',(a1)+				; write a ,
		move.w	d3,d2						; copy destination register to d2
		jsr	d68k_PrintDataReg3(pc)				; print it
		bra.s	.runs
; ---------------------------------------------------------------------------

.anan
		bsr.s	.printan					; write source register
		move.w	d3,d2						; copy destination register to d1
		move.w	#d68k_white|',',(a1)+				; write a ,
		bsr.s	.printan					; write destination register

.runs
		jmp	d68k_RunScript(pc)				; run the script now
; ---------------------------------------------------------------------------

.printan
		move.l	#((d68k_white|'-')<<16)|d68k_white|'(',(a1)+	; write -( into buffer
		jsr	d68k_PrintAddrReg3(pc)				; print address register
		move.w	#d68k_white|')',(a1)+				; write ) into buffer
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; CXXX instruction handler
; ---------------------------------------------------------------------------

d68k_iCxxx:	d68k_ReadSrc	$F8, $38, $1F0, $1C0			; read the instruction from source
		d68k_Cmp	0, $0C0, d68k_iMulu			; check if DIVU, and if so, branch
		d68k_Cmp	-2, $1C0, d68k_iMuls			; check if DIVS, and if so, branch
		d68k_Cmp	-2, $100, d68k_iAbcd			; check if ABCD, and if so, branch

		d68k_Pop	4					; go check the last check value
		d68k_Cmp	0, $140, .chk				; check if EXG, and if so, branch
		d68k_Cmp	0, $180, .chk				; check if EXG, and if so, branch
	;	d68k_Cmp	0, $1C0, .chk				; check if EXG, and if so, branch
		d68k_Jump	d68k_iAnd				; go to AND code
; ---------------------------------------------------------------------------

.chk		d68k_Pop	-4					; go check the last check value
		d68k_Cmp	0, $00, d68k_iExg			; check if AND, and if so, branch
		d68k_Cmp	0, $08, d68k_iExg			; check if AND, and if so, branch

d68k_iAnd:	d68k_Print	0, d68k_sAnd				; print AND
		d68k_Push	$FFD, $1FD				; push check values into stack
		d68k_Jump	d68k_CommonIns1				; common instruction type 1
; ===========================================================================
; ---------------------------------------------------------------------------
; EXG instruction handler
; ---------------------------------------------------------------------------

d68k_iExg:	d68k_Print	' ', d68k_sExg				; print EXG
		d68k_Pop	-2					; go check the last check value
		d68k_Cmp	0, $48, .an1				; check if AN <-> AN, and if so, branch
		d68k_Cmp	0, $40, .dn1				; check if DN <-> DN, and if so, branch
		d68k_Cmp	0, $88, .dn1				; check if DN <-> AN, and if so, branch
		d68k_Jump	d68k_iData				; invalid mode
; ---------------------------------------------------------------------------

.an1		d68k_AddrReg	9					; print areg
		d68k_Jump	.common1				; run common code

.dn1		d68k_DataReg	9					; print dreg

.common1	d68k_Char	','					; print ,
		d68k_Cmp	0, $40, d68k_CommonIns9			; check if DN <-> DN, and if so, branch
; ===========================================================================
; ---------------------------------------------------------------------------
; Common type 10 instruction handler
; ---------------------------------------------------------------------------

d68k_CommonIns10:
		d68k_AddrReg	0					; print areg
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; XBCD instruction handlers
; ---------------------------------------------------------------------------

d68k_iAbcd:	d68k_Print	0, d68k_sA				; print a
		d68k_Jump	d68k_iSAbcd				; go to common code

d68k_iSbcd:	d68k_Print	0, d68k_sS				; print s

d68k_iSAbcd:	d68k_Print	0, d68k_sBcd
		d68k_Jump	d68k_iSpecialReg			; load special register pair from assembly
; ===========================================================================
; ---------------------------------------------------------------------------
; MULX and DIVX instruction handlers
; ---------------------------------------------------------------------------

d68k_iDivu:	d68k_Print	'u', d68k_sDiv				; print DIVU
		d68k_Jump	d68k_iMulDiv				; go to common code
; ---------------------------------------------------------------------------

d68k_iDivs:	d68k_Print	's', d68k_sDiv				; print DIVS
		d68k_Jump	d68k_iMulDiv				; go to common code
; ---------------------------------------------------------------------------

d68k_iMulu:	d68k_Print	'u', d68k_sMul				; print MULU
		d68k_Jump	d68k_iMulDiv				; go to common code
; ---------------------------------------------------------------------------

d68k_iMuls:	d68k_Print	's', d68k_sMul				; print MULS
; ---------------------------------------------------------------------------

d68k_iMulDiv:	d68k_Size	'w'					; set instruction size
		d68k_Push	$FFD					; push check value into stack
		d68k_Jump	d68k_WriteReg2				; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; 8XXX instruction handler
; ---------------------------------------------------------------------------

d68k_i8xxx:	d68k_ReadSrc	$38, $1F0, $1C0				; read the instruction from source
		d68k_Cmp	0, $0C0, d68k_iDivu			; check if DIVU, and if so, branch
		d68k_Cmp	-2, $1C0, d68k_iDivs			; check if DIVS, and if so, branch
		d68k_Cmp	-2, $100, d68k_iSbcd			; check if SBCD, and if so, branch

	; OR
		d68k_Print	0, d68k_sOr				; print OR
		d68k_Push	$FFD, $1FD				; push check values into stack
; ===========================================================================
; ---------------------------------------------------------------------------
; Common type 1 instruction handler
; ---------------------------------------------------------------------------

d68k_CommonIns1:
		d68k_InsSz	6					; print instruction size
		d68k_Char	' '					; print space
		d68k_ReadSrc	$100, $100 				; read the instruction from source

	; stack: EA, EA, INS, INS
		d68k_Swap	-6					; swap with the last entry
	; stack: INS, EA, INS, EA
		d68k_Swap	-2					; swap with the first value
	; stack: INS, EA, EA, INS
		d68k_Cmp	-2, $000, .skip				; check if EA -> DN, and if so, branch

		d68k_Swap	-2					; swap the first entry out (use second entry for mode check)
		d68k_DataReg	9					; print dreg
		d68k_Char	','					; print ,

.skip	; stack: INS, EA, EA
		d68k_Mode	0					; print addressing mode
		d68k_Pop	-2					; pop both EA entries out
		d68k_Cmp	-2, $100, d68k_Finish1			; check if DN -> EA, and if so, branch
; ===========================================================================
; ---------------------------------------------------------------------------
; Standard register write
; ---------------------------------------------------------------------------

d68k_WriteReg1:
		d68k_Char	','					; print ,
		d68k_DataReg	9					; print dreg

d68k_Finish1:
		d68k_Finish

d68k_WriteReg2:
		d68k_Mode	' '					; print source addressing mode
		d68k_Jump	d68k_WriteReg1				; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; BXXX instruction handler
; ---------------------------------------------------------------------------

d68k_iBxxx:	d68k_ReadSrc	$38, $100, $C0				; read the instruction from source
		d68k_Cmp	-2, $C0, d68k_iCmpa			; check if this is CMPA, and branch if yes
		d68k_Cmp	-2, $100, d68k_iEor			; check if this is EOR or CMPM, and branch if yes

		d68k_Print	0, d68k_sCmp				; print CMP
		d68k_InsSz	6					; print instruction size
		d68k_Push	$FFF					; push check value into stack
		d68k_Jump	d68k_WriteReg2				; go to standard handler
; ---------------------------------------------------------------------------

d68k_iCmpa:	d68k_Print	'a', d68k_sCmp				; print CMPA
		d68k_SmallSz	8					; print small instruction size
		d68k_Push	$FFF					; push check value into stack
		d68k_Mode	' '					; print source addressing mode
; ===========================================================================
; ---------------------------------------------------------------------------
; Common type 6 instruction handler
; ---------------------------------------------------------------------------

d68k_CommonIns6:
		d68k_Char	','					; print ,
		d68k_AddrReg	9					; print areg
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; EOR instruction handler
; ---------------------------------------------------------------------------

d68k_iEor:
		d68k_Cmp	-2, $08, d68k_iCmpm			; check if this is CMPM, and branch if yes
		d68k_Print	0, d68k_sEor				; print EOR
		d68k_InsSz	6					; print instruction size
		d68k_Char	' '					; print a space
		d68k_DataReg	9					; print dreg
		d68k_Push	$1FD					; push check value into stack
		d68k_Jump	d68k_CommonIns8				; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; CMPM instruction handler
; ---------------------------------------------------------------------------

d68k_iCmpm:	d68k_Print	'm', d68k_sCmp				; print CMPM
		d68k_InsSz	6					; print instruction size
		d68k_Char	' '					; print a space

		d68k_Push	0					; push shift count to stack
		d68k_Exec	d68k_ModeApind2				; write source register
		d68k_Char	','					; print ,
		d68k_Push	9					; push shift count to stack
		d68k_Exec	d68k_ModeApind2				; write destination register
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; 0XXX instruction handler
; ---------------------------------------------------------------------------

d68k_i0xxx:	d68k_ReadSrc	$C0, $80, $38, $100			; read the instruction from source
		d68k_Cmp	-2, $000, d68k_i00xx			; check if this is a misc instruction, and brach if yes
		d68k_Cmp	-2, $08, d68k_iMovep			; check if this is MOVEP, and branch if yes
; ===========================================================================
; ---------------------------------------------------------------------------
; BTST, BCHG, BCLR & BSET instruction handlers
; ---------------------------------------------------------------------------

	; BXXX DN, EA
		d68k_Exec	d68k_PrintBXXX				; print BXXX instruction string
		d68k_Pop	-2					; movep check out
		d68k_Cmp	-2, $00, .btst				; check if this is BTST, and branch if yes
		d68k_Push	$1FD					; push check value into stack
		d68k_Jump	.common					; run common code

.btst		d68k_Push	$FFD					; push check value into stack

.common		d68k_DataReg	9					; print dreg
; ===========================================================================
; ---------------------------------------------------------------------------
; Common instruction type 5 handler
; ---------------------------------------------------------------------------

d68k_CommonIns5:
		d68k_Size	'b'					; set instruction size
; ===========================================================================
; ---------------------------------------------------------------------------
; Common instruction type 4 handler
; ---------------------------------------------------------------------------

d68k_CommonIns8:
		d68k_Mode	','					; print source addressing mode
		d68k_Finish
; ---------------------------------------------------------------------------

	; BXXX #, EA
d68k_iBit:
		d68k_Exec	d68k_PrintBXXX				; print BXXX instruction string
		d68k_Pop	-2					; movep check out
		d68k_Cmp	-2, $00, .btst				; check if this is BTST, and branch if yes
		d68k_Push	$1FD					; push check value into stack
		d68k_Jump	.common					; run common code

.btst		d68k_Push	$7FD					; push check value into stack

.common		d68k_Char	'#'					; print #
		d68k_Read	$FFFF					; read the offset from source
		d68k_PrintNum	d68kn_Word				; write the word value
		d68k_Jump	d68k_CommonIns5				; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; Print BXXX instruction string
; ---------------------------------------------------------------------------

d68k_PrintBXXX:
		move.w	d0,d1						; copy the instruction to d1
		and.w	#$C0,d1						; keep in range
		lsr.w	#4,d1						; shift into place

		move.w	#d68k_blue,d2					; prepare blue color to d2
		lea	.ins(pc,d1.w),a4				; load table to a4
		moveq	#4-1,d1						; load repeat count to d1

.load
		move.b	(a4)+,d2					; load character to d2
		move.w	d2,(a1)+					; save to buffer
		dbf	d1,.load					; print all characters

		move.w	#d68k_white|' ',(a1)+				; write a space
		jmp	d68k_RunScript(pc)				; run the script now

.ins		dc.b 'btstbchgbclrbset'
; ===========================================================================
; ---------------------------------------------------------------------------
; MOVEP instruction handler
; ---------------------------------------------------------------------------

d68k_iMovep:	d68k_Print	'p', d68k_sMove				; print MOVEP
		d68k_SmallSz	6					; print small instruction size
		d68k_Char	' '					; print space

		d68k_Cmp	0, $00, .skip1				; check if this is EA -> DN, and brach if yes
		d68k_DataReg	9					; print dreg
		d68k_Char	','					; print ,

.skip1		d68k_Exec	d68k_ModeAoind2				; write d16(AN) part
		d68k_Cmp	-2, $80, d68k_Finish1			; check if this is DN -> EA, and brach if yes
		d68k_Jump	d68k_WriteReg1				; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; 00XX instruction handler
; ---------------------------------------------------------------------------

d68k_i00xx:	d68k_ReadSrc	$C0, $63F, $E00	 			; read the instruction from source
		d68k_Cmp	0, $E00, d68k_iData			; check if this is invalid, and if so, present as data
		d68k_Cmp	-2, $800, d68k_iBit			; check if this is BXXX, and brach if yes

	; XXXI
		d68k_Exec	.print					; print instruction
		d68k_InsSz	6					; print instruction size
		d68k_Char	' '					; print a space
		d68k_Exec	d68k_rModeImm				; print data

		d68k_Char	','					; print ,
		d68k_Cmp	0, $03C, .srccr				; check if this to SR/CCR, and brach if yes
		d68k_Cmp	0, $23C, .srccr				; check if this is SR/CCR, and brach if yes
; ---------------------------------------------------------------------------

	; XXXI #,EA
		d68k_Push	$1FD					; push check value into stack
		d68k_Mode	0						; print source addressing mode
		d68k_Finish
; ---------------------------------------------------------------------------

.print
		move.w	(a3),d1						; read instruction from stack
		lsr.w	#8,d1						; shift down
		move.w	.tbl(pc,d1.w),d1				; load table entry to d1
		lea	.tbl(pc,d1.w),a4				; load string address to a4

		moveq	#'i',d1						; write i at the end
		jmp	d68k_rPrint3(pc)				; print it out
; ---------------------------------------------------------------------------

.tbl		dc.w d68k_sOr-.tbl,  d68k_sAnd-.tbl, d68k_sSub-.tbl, d68k_sAdd-.tbl
		dc.w 0,              d68k_sEor-.tbl, d68k_sCmp-.tbl
; ---------------------------------------------------------------------------


.srccr	; XXXI #,SR/CCR
		d68k_Pop	-2					; pop ADDQ/SUBQ test word
		d68k_Cmp	0, $40, .sr				; check for SR, and branch if so
		d68k_Cmp	-2, $00, .ccr				; check for CCR, and branch if so
		d68k_Jump	d68k_iData				; invalid mode
; ---------------------------------------------------------------------------

.ccr		d68k_Print	'r', d68k_sCC				; print CCR
		d68k_Finish

.sr		d68k_Print	'r', d68k_sS2				; print SR
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; 5XXX instruction handler
; ---------------------------------------------------------------------------

d68k_i5xxx:	d68k_ReadSrc	$38, $100, $C0 				; read the instruction from source
		d68k_Cmp	-2, $C0, .scc				; check if this is a DBc or Scc, and brach if yes
; ===========================================================================
; ---------------------------------------------------------------------------
; ADDQ and SUBQ instruction handlers
; ---------------------------------------------------------------------------

	; ADDQ and SUBQ
		d68k_Cmp	-2, $100, .subq				; check if this is a SUBQ, and brach if yes
		d68k_Print	'q', d68k_sAdd				; print addq
		d68k_Jump	.common					; common code

.subq		d68k_Print	'q', d68k_sSub				; print subq
; ---------------------------------------------------------------------------

.common		d68k_InsSz	6					; print instruction size
		d68k_Char	' '					; print space
		d68k_Exec	d68k_PrintTinyValue			; print the value
		d68k_Push	$1FF					; push check value into stack
		d68k_Jump	d68k_CommonIns8				; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; SCC instruction handler
; ---------------------------------------------------------------------------

.scc		d68k_Pop	-2					; pop ADDQ/SUBQ test word
		d68k_Cmp	-2, $08, .dbcc				; check if this is a DBCC, and brach if yes

	; Scc
		d68k_Print	0, d68k_sS				; print s
		d68k_Push	.scctbl-d68k_PrintCC			; push table offset to stack
		d68k_Exec	d68k_PrintCC2				; print condition code

		d68k_Size	'b'					; set instruction size
		d68k_Jump	d68k_CommonIns3				; run common instruction code
; ===========================================================================
; ---------------------------------------------------------------------------
; DBCC instruction handler
; ---------------------------------------------------------------------------

.dbcc	; DBcc
		d68k_Print	0, d68k_sDB				; print db
		d68k_Push	.scctbl-d68k_PrintCC			; push table offset to stack
		d68k_Exec	d68k_PrintCC2				; print condition code
		d68k_Char	' '					; print space
		d68k_DataReg	0					; print dreg

		d68k_Char	','					; print ,
		d68k_Read	$FFFF	 				; read the offset from source
		d68k_Push	-2					; push address offset to stack
		d68k_Jump	d68k_iDoAddr				; run common instruction code

.scctbl		dc.b 't', 0, 'f', 0
; ===========================================================================
; ---------------------------------------------------------------------------
; BCC instruction handler
; ---------------------------------------------------------------------------

d68k_iBCC:	d68k_Push	.bcctbl-d68k_PrintCC			; push table offset to stack
		d68k_Print	0, d68k_sB				; print b
		d68k_Exec	d68k_PrintCC				; print condition code

		d68k_ReadSrc	$FF	 				; read the instruction from source
		d68k_Cmp	0, $00, .word				; check if word, and if so, branch
		d68k_Print	' ', d68k_sDotS				; print .s
		d68k_Push	0					; push address offset to stack
		d68k_Jump	.common					; common code
; ---------------------------------------------------------------------------

.bcctbl		dc.b 'rasr'

.word		d68k_Read	$FFFF	 				; read the offset from source
		d68k_Print	' ', d68k_sDotW				; print .w
		d68k_Push	-2					; push address offset to stack

.common		d68k_Swap	-2					; swap arguments
; ===========================================================================
; ---------------------------------------------------------------------------
; BCC and DBCC address calculation and printout
; ---------------------------------------------------------------------------

d68k_iDoAddr:
		d68k_Exec	d68k_CalcAddr				; calculate address
		d68k_PrintNum	d68kn_Addr				; write the address value
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; Calculate address from source and stack
; ---------------------------------------------------------------------------

d68k_CalcAddr:
		move.w	-(a3),d1					; load address
		move.w	-(a3),d2					; load offset
		bne.s	.word						; branch if it was not 0
		ext.w	d1						; extend address to word

.word		add.w	d2,d1						; add offset
		ext.l	d1						; extend to long
	if checkall
		addq.l	#2,d1
	else
		add.l	a0,d1						; add source address
	endif
		move.l	d1,(a3)+					; store in stack
		jmp	d68k_RunScript(pc)				; run the script now
; ===========================================================================
; ---------------------------------------------------------------------------
; Condition code print handler
; ---------------------------------------------------------------------------

d68k_PrintCC:
		pea	d68k_RunScript(pc)				; run the script later

d68k_PrintCC3:
		move.w	-(a3),d1					; load table offset to d1
		lea	d68k_PrintCC(pc,d1.w),a4			; load table to a4

		move.w	d0,d1						; copy instruction to d1
		and.w	#$0F00,d1					; keep in range
		lsr.w	#7,d1						; shift down

		move.l	#(d68k_blue<<16)|d68k_blue,d3			; load color to d3
		cmp.w	#4,d1						; check if this is the two first entries
		blt.s	.a2						; read from a2

		move.b	.cctbl-4(pc,d1.w),d2				; load first letter to d2
		swap	d2						; swap words
		move.b	.cctbl-3(pc,d1.w),d2				; load second letter to d2
		bra.s	.c
; ---------------------------------------------------------------------------

.a2
		move.b	(a4,d1.w),d2					; load first alternate letter to d2
		swap	d2						; swap words
		move.b	1(a4,d1.w),d2					; load second alternate letter to d2

.c
		move.l	d2,(a1)+					; save to buffer
		rts
; ---------------------------------------------------------------------------

.cctbl		dc.b 'hilscccsneeqvcvsplmigeltgtle'
; ---------------------------------------------------------------------------

d68k_PrintCC2:
		bsr.s	d68k_PrintCC3					; print the CC
		tst.b	-1(a1)						; check if last was blank
		seq	d1						; set d1 if yes

		and.w	#2,d1						; keep in range
		sub.w	d1,a1						; advance the pointer
		jmp	d68k_RunScript(pc)				; run the script now
; ===========================================================================
; ---------------------------------------------------------------------------
; EXXX instruction handler
; ---------------------------------------------------------------------------

d68k_iExxx:	d68k_ReadSrc	$20, $C0				; read the instruction from source
		d68k_Cmp	-2, $C0, .ea				; check if EA, and if so, branch

	; shift # or DN
		d68k_Push	3					; push shift count to stack
		d68k_Exec	d68k_PrintShift				; print shift instruction
		d68k_InsSz	6					; print instruction size
		d68k_Char	' '					; print space
		d68k_Cmp	-2, $00, .imm				; check if #, and if so, branch

	; shift DN
		d68k_DataReg	9					; print dreg
		d68k_Jump	.common					; common code

.imm	; shift #
		d68k_Exec	d68k_PrintTinyValue			; print the value

.common		d68k_Char	','					; print ,
		d68k_Jump	d68k_CommonIns9				; common instruction type 9

.ea	; shift EA
		d68k_Push	9					; push shift count to stack
		d68k_Exec	d68k_PrintShift				; print shift instruction
		d68k_Size	'w'					; set instruction size
		d68k_Push	$1FC					; push check value into stack
		d68k_Jump	d68k_CommonIns4				; run common instruction code
; ===========================================================================
; ---------------------------------------------------------------------------
; Print tiny value from instruction to stack
; ---------------------------------------------------------------------------

d68k_PrintTinyValue:
		move.w	#d68k_white|'#',(a1)+				; write a #

		move.w	d0,d1						; copy instruction to d1
		rol.w	#16-9,d1					; rotate register into place
		and.w	#7,d1						; keep in range
		bne.s	.not0						; branch if not
		moveq	#8,d1						; set to 8 instead

.not0
		add.w	#d68k_red|'0',d1				; turn into digit
		move.w	d1,(a1)+					; print it!
; ===========================================================================
; ---------------------------------------------------------------------------
; Go back to running the script
; ---------------------------------------------------------------------------

d68k_JumpScript4:
		jmp	d68k_RunScript(pc)				; run the script now
; ===========================================================================
; ---------------------------------------------------------------------------
; Shift instruction print handler
; ---------------------------------------------------------------------------

d68k_PrintShift:
		move.w	-(a3),d1					; load shift count to d1
		jsr	d68k_ShiftIns(pc)				; shift into place

		moveq	#0,d3
		and.w	#3,d2						; keep in range
		move.b	.inssz(pc,d2.w),d3				; load the correct size

		move.b	.insoffs(pc,d2.w),d2				; load the correct offset
		lea	.insdata(pc,d2.w),a4				; load the array to a4
		move.w	#d68k_blue,d2					; prepare color to d2

.copyloop
		move.b	(a4)+,d2					; load letter
		move.w	d2,(a1)+					; write to buffer
		dbf	d3,.copyloop					; loop for all entries

		btst	#8,d0						; check which direction to use
		seq	d3						; if yes, results in 0
		ext.w	d3						; if not, results in $FFFF

		move.b	.direction+1(pc,d3.w),d2			; load direction character
		move.w	d2,(a1)+					; print into buffer
		bra.s	d68k_JumpScript4
; ---------------------------------------------------------------------------

.inssz		dc.b 2-1, 2-1, 3-1, 2-1
.insoffs	dc.b 2, 0, 4, 4
.direction	dc.b 'r'
.insdata	dc.b 'lsasrox'
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; 4XXX instruction handler
; ---------------------------------------------------------------------------

d68k_i4xxx:	; doing it this way saves like a massive total of 8 bytes! oh my god! =/
		d68k_ReadSrc	$80, $40, $100				; read the instruction from source
		d68k_Cmp	-2, $100, d68k_iLeaChk			; check if LEA or CHK, and if so, branch
		d68k_Exec	.grab					; print shift instruction
; ---------------------------------------------------------------------------

.grab
		move.w	d0,d1						; copy instruction to d1
		and.w	#$0E00,d1					; get 3 upper bits of second nibble
		lsr.w	#7,d1						; shift into place

		move.w	d0,d2						; copy instruction to d2
		and.w	#$C0,d2						; check for a specific value
		cmp.w	#$C0,d2						;
		bne.s	.nope						; branch if not
		addq.w	#2,d1						; go to next entry

.nope
		move.w	.tbl(pc,d1.w),d1				; load offset to d1
		lea	.tbl(pc,d1.w),a2				; get entry as script
		bra.s	d68k_JumpScript4
; ---------------------------------------------------------------------------

.tbl		dc.w d68k_iNegx-.tbl, d68k_iMovefSRCCR-.tbl, d68k_iClr-.tbl,  d68k_iMovefSRCCR-.tbl
		dc.w d68k_iNeg-.tbl,  d68k_iMovetSRCCR-.tbl, d68k_iNot-.tbl,  d68k_iMovetSRCCR-.tbl
		dc.w d68k_iNbcd-.tbl, d68k_iNbcd-.tbl,       d68k_iTst-.tbl,  d68k_iTas-.tbl
		dc.w d68k_iMovem-.tbl,d68k_iMovem-.tbl,      d68k_i4E4X-.tbl, d68k_iJmpJsr-.tbl
; ===========================================================================
; ---------------------------------------------------------------------------
; MOVE from/to SR and CCR instruction handlers
; ---------------------------------------------------------------------------

d68k_iMovefSRCCR:
		d68k_Print	' ', d68k_sMove				; print MOVE
		d68k_ReadSrc	$200					; read the instruction from source
		d68k_Cmp	-2, $000, .sr				; check for SR, and branch if so
; ---------------------------------------------------------------------------

		d68k_Print	'r', d68k_sCC				; print CCR
		d68k_Size	'b'					; set instruction size
		d68k_Jump	.common					; common code

.sr		d68k_Print	'r', d68k_sS2				; print S
		d68k_Size	'w'					; set instruction size
; ---------------------------------------------------------------------------

.common		d68k_Push	$3FD					; push check value into stack
		d68k_Jump	d68k_CommonIns8				; print addressing mode
; ---------------------------------------------------------------------------

d68k_iMovetSRCCR:
		d68k_Print	' ', d68k_sMove				; print MOVE
		d68k_ReadSrc	$200					; read the instruction from source

		d68k_Size	'w'					; set instruction size
		d68k_Cmp	0, $200, .sz				; check for SR, and branch if so
		d68k_Size	'b'					; set instruction size
; ---------------------------------------------------------------------------

.sz		d68k_Push	$FFD					; push check value into stack
		d68k_Mode	0					; print addressing mode
		d68k_Char	','					; print ,
; ---------------------------------------------------------------------------

		d68k_Cmp	-2, $200, .sr				; check for SR, and branch if so
		d68k_Print	'r', d68k_sCC				; print CCR
		d68k_Finish

.sr		d68k_Print	'r', d68k_sS2				; print S
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; 4XXX common type instruction handlers
; ---------------------------------------------------------------------------

d68k_iNegx:	d68k_Print	'x', d68k_sNeg				; print negx
		d68k_Jump	d68k_CommonIns2				; common code
; ---------------------------------------------------------------------------

d68k_iNeg:	d68k_Print	0, d68k_sNeg				; print neg
		d68k_Jump	d68k_CommonIns2				; common code
; ---------------------------------------------------------------------------

d68k_iClr:	d68k_Print	0, d68k_sClr				; print clr
		d68k_Jump	d68k_CommonIns2				; common code
; ---------------------------------------------------------------------------

d68k_iNot:	d68k_Print	0, d68k_sNot				; print not
		d68k_Jump	d68k_CommonIns2				; common code
; ---------------------------------------------------------------------------

d68k_iTst:	d68k_Print	0, d68k_sTst				; print tst
; ===========================================================================
; ---------------------------------------------------------------------------
; Common type 2 instruction handler
; ---------------------------------------------------------------------------

d68k_CommonIns2:
		d68k_InsSz	6					; print instruction size
; ===========================================================================
; ---------------------------------------------------------------------------
; Common type 3 instruction handler
; ---------------------------------------------------------------------------

d68k_CommonIns3:
		d68k_Push	$1FD					; push check value into stack
; ===========================================================================
; ---------------------------------------------------------------------------
; Common type 4 instruction handler
; ---------------------------------------------------------------------------

d68k_CommonIns4:
		d68k_Mode	' '					; print source addressing mode
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; NBCD instruction handler
; ---------------------------------------------------------------------------

d68k_iNbcd:	d68k_ReadSrc	$38, $80				; read the instruction from source
		d68k_Cmp	-4, $80, d68k_iExt			; check if it's EXT or MOVEM, and if so, branch
		d68k_Cmp	0, $40, d68k_iPea			; check if it's PEA or SWAP, and if so, branch

		d68k_Print	0, d68k_sNbcd				; print NBCD
		d68k_Size	'w'					; set instruction size
		d68k_Jump	d68k_CommonIns3				; run common instruction code
; ===========================================================================
; ---------------------------------------------------------------------------
; PEA instruction handler
; ---------------------------------------------------------------------------

d68k_iPea:	d68k_Pop	2					; check the middle value quickly
		d68k_Cmp	-4, $00, d68k_iSwap			; check if it's SWAP, and if so, branch

		d68k_Print	0, d68k_sPea				; print PEA
		d68k_Size	'w'					; set instruction size
		d68k_Push	$7E5					; push check value into stack
		d68k_Jump	d68k_CommonIns4				; run common instruction code
; ===========================================================================
; ---------------------------------------------------------------------------
; TAS instruction handler
; ---------------------------------------------------------------------------

d68k_iTas:	d68k_ReadSrc	$3F					; read the instruction from source
		d68k_Cmp	-2, $3C, d68k_iIllegal			; check for illegal instruction

		d68k_Print	0, d68k_sTas				; print TAS
		d68k_Size	'b'					; set instruction size
		d68k_Jump	d68k_CommonIns3				; run common instruction code
; ===========================================================================
; ---------------------------------------------------------------------------
; SWAP instruction handler
; ---------------------------------------------------------------------------

d68k_iSwap:	d68k_Print	' ', d68k_sSwap				; print SWAP
; ===========================================================================
; ---------------------------------------------------------------------------
; Common type 9 instruction handler
; ---------------------------------------------------------------------------

d68k_CommonIns9:
		d68k_DataReg	0					; print dreg
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; JMP and JSR instruction handlers
; ---------------------------------------------------------------------------

d68k_iJmpJsr:	d68k_ReadSrc	$40, $80				; read the instruction from source
		d68k_Cmp	-2, $00, d68k_iData			; check for invalid instruction

		d68k_Cmp	-2, $00, .jsr				; check for JSR, and if so, branch
		d68k_Print	0, d68k_sJmp				; print JMP
		d68k_Jump	.common					; run common instruction code

.jsr		d68k_Print	0, d68k_sJsr				; print JSR

.common		d68k_Size	'w'					; set instruction size
		d68k_Push	$7E4					; push check value into stack
		d68k_Jump	d68k_CommonIns4				; run common instruction code
; ===========================================================================
; ---------------------------------------------------------------------------
; ILLEGAL instruction handler
; ---------------------------------------------------------------------------

d68k_iIllegal:	d68k_Print	0, d68k_sIllegal			; print ILLEGAL
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; EXT instruction handler
; ---------------------------------------------------------------------------

d68k_iExt2:	d68k_Print	0, d68k_sExt				; print EXT
		d68k_SmallSz	6					; print small instruction size
		d68k_Char	' '					; print space
		d68k_Jump	d68k_CommonIns9				; common instruction type 9
; ---------------------------------------------------------------------------

d68k_iExt:	d68k_Pop	2					; check the middle value quickly
		d68k_Cmp	-4, $00, d68k_iExt2			; check if it's EXT, and if so, branch
; ===========================================================================
; ---------------------------------------------------------------------------
; MOVEM instruction handler
; ---------------------------------------------------------------------------

d68k_iMovem:	d68k_ReadSrc	$400, $380				; read the instruction from source
		d68k_Cmp	-2, $80, .continue 			; check if valid, and if so, branch
		d68k_Jump	d68k_iData				; treat as data
; ---------------------------------------------------------------------------

.continue	d68k_Print	'm', d68k_sMove				; print MOVEM
		d68k_SmallSz	6					; print small instruction size
		d68k_Char	' '					; print space
		d68k_Read	$FFFF					; read the registers to stack

		d68k_Swap	-2					; swap with the last entry
		d68k_Cmp	0, $000, .skip1				; check if ARG -> EA, and if so, branch
		d68k_Push	$7EC					; push check value into stack
		d68k_Mode	0					; print source addressing mode
		d68k_Char	','					; print ,

.skip1		d68k_Exec	.regs					; print registers
		d68k_Cmp	-2, $400, d68k_Finish1			; check if EA -> ARG, and if so, branch
		d68k_Push	$1F4					; push check value into stack
		d68k_Jump	d68k_CommonIns8				; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; MOVEM registers handler
; ---------------------------------------------------------------------------

.regs
		move.w	-4(a3),d3					; copy register list to d3
		bne.s	.notnull					; branch if 1 or more registers are used
		move.w	#d68k_red|'0',(a1)+				; write a single red 0
		bra.s	.cont
; ---------------------------------------------------------------------------

.notnull
		move.w	d0,d1						; copy instruction to d1
		and.w	#$38,d1						; get the eamode to d1
		cmp.w	#8*4,d1						; check if -(AN)
		bne.s	.normal						; branch if not

	; now here is some WTF for you. For this one specific mode, the bitfield is FUCKING BACKWARDS. You heard me right. Backwards. WTF Motorola!!!
		move.w	d3,d1						; copy register list to d1
		moveq	#0,d3						; clear register list
		moveq	#16-1,d4					; set repeat count to d4

.invert
		lsr.w	#1,d1						; shift the next bit to carry
		addx.w	d3,d3						; add carry and shift d3
		dbf	d4,.invert					; repeat like 16 times wtf
; ---------------------------------------------------------------------------

.normal
		moveq	#0,d6						; set current bit to 0
		moveq	#-1,d2						; set starting bit to null
		moveq	#0,d7						; no registers are written

.loop
		lsr.w	#1,d3						; shift the next bit into carry
		bcc.s	.notset						; if not set, branch
		tst.b	d2						; check if we have found a starting bit
		bpl.s	.next						; if yes, go to next iteration
		move.w	d6,d2						; set as the new starting bit
; ---------------------------------------------------------------------------

.next
		addq.w	#1,d6						; go to next bit
		cmp.w	#17,d6						; check if bit 17
		ble.s	.loop						; if not, go to loop

.cont
		jmp	d68k_RunScript(pc)				; run the script now
; ---------------------------------------------------------------------------

.notset
		tst.b	d2						; check if we have found a starting bit
		bmi.s	.next						; if not, go to next iteration
		move.w	d6,d5						; copy ending bit to d5
		subq.w	#1,d5						; align it correctly

	; print separator
		tas	d7						; check if we have written a register already
		bpl.s	.nowrite					; branch if not
		move.w	#d68k_white|'/',(a1)+				; write a /

	; print out an appropriate version of the bit string
.nowrite
		move.w	d2,a4						; store a4 temporarily
		jsr	d68k_PrintReg3(pc)				; print the starting register
		cmp.w	d5,a4						; check if the distance is 0 registers
		beq.s	.reset						; branch if yes

		move.w	#d68k_white|'-',(a1)+				; write a -
		move.w	d5,d2						; copy ending register to d2
		jsr	d68k_PrintReg3(pc)				; print it

.reset
		moveq	#-1,d2						; set no starting bit
		bra.s	.next						; go to next iteration
; ===========================================================================
; ---------------------------------------------------------------------------
; LEA and CHK instruction handlers
; ---------------------------------------------------------------------------

d68k_iLeaChk:	d68k_Size	'w'					; set instruction size
		d68k_Cmp	-2, $00, .chk				; check if CHK, and if so, branch
; ---------------------------------------------------------------------------

	; LEA
		d68k_Cmp	-2, $00, d68k_iData			; check for invalid instruction

		d68k_Print	' ', d68k_sLea				; print lea
		d68k_Push	$7E4					; push check value into stack
		d68k_Mode	0					; print source addressing mode
		d68k_Jump	d68k_CommonIns6				; go to standard handler
; ---------------------------------------------------------------------------

.chk	; CHK
		d68k_Print	' ', d68k_sChk				; print chk
		d68k_Push	$FFD					; push check value into stack
		d68k_Mode	0					; print source addressing mode
		d68k_Jump	d68k_WriteReg1				; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; TRAP instruction handler
; ---------------------------------------------------------------------------

d68k_iTrap:	; LEWD OWO
		d68k_Print	0, d68k_sTrap				; print TRAP
		d68k_ReadSrc	$0F					; read the instruction from source
		d68k_PrintNum	d68kn_Byte				; write the byte value
		d68k_Finish
; ===========================================================================
; ---------------------------------------------------------------------------
; LINK and UNLK instruction handler
; ---------------------------------------------------------------------------

d68k_iLink:	d68k_Pop	-2					; pop temporary value
		d68k_Cmp	-2, $08, .unlk				; check if UNLK, and if so, branch

		d68k_Print	' ', d68k_sLink				; print link
		d68k_AddrReg	0					; print areg
		d68k_Char	','					; print ,
		d68k_Char	'#'					; print #
		d68k_Jump	d68k_CommonIns7
; ---------------------------------------------------------------------------

.unlk		d68k_Print	' ', d68k_sUnlk				; print unlk
		d68k_Jump	d68k_CommonIns10			; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; MOVE USP instruction handler
; ---------------------------------------------------------------------------

d68k_iMvUSP:	d68k_Print	' ', d68k_sMove				; print MOVE
		d68k_Cmp	0, $08, .skip1				; check if USP -> AN, and if so, branch
		d68k_AddrReg	0					; print areg
		d68k_Char	','					; print ,

.skip1		d68k_Print	0, d68k_sUSP				; print USP
		d68k_Cmp	-2, $00, d68k_Finish1			; check if AN -> USP, and if so, branch
		d68k_Char	','					; print ,
		d68k_Jump	d68k_CommonIns10			; go to standard handler
; ===========================================================================
; ---------------------------------------------------------------------------
; 4E7X instruction handler
; ---------------------------------------------------------------------------

d68k_i4E4X:	d68k_ReadSrc	$08, $30, $40				; read the instruction from source
		d68k_Cmp	-2, $00, d68k_iJmpJsr			; check if JMP or JSR, and if so, branch

		d68k_Cmp	0, $00, d68k_iTrap			; check if TRAP, and if so, branch
		d68k_Cmp	0, $10, d68k_iLink			; check if LINK or UNLK, and if so, branch
		d68k_Cmp	-2, $20, d68k_iMvUSP			; check if MOVE from/to USP, and if so, branch

		d68k_Cmp	-2, $08, d68k_iData			; check if invalid, and if so, branch
		d68k_Exec	.i4E7X					; print 4E7X instructions
; ---------------------------------------------------------------------------

.i4E7X
		moveq	#7,d3						; load mask into d3
		and.w	d0,d3						; AND instruction with d3
		move.b	d68k_MiscInsTbl(pc,d3.w),d3			; load instruction offset to d3
		bmi.w	d68k_Data					; if negative, this is an invalid instruction

		lea	d68k_iStop(pc,d3.w),a4				; load string to a4
		moveq	#0,d1						; no extra characters
		jsr	d68k_rPrint2(pc)				; copy the string over
; ---------------------------------------------------------------------------

		tst.b	d3						; check instruction
		bne.s	d68k_rFinish					; branch if not stop
		move.w	(a0)+,(a3)+					; load value int stack
		jsr	d68k_PrintWord(pc)				; print it
; ===========================================================================
; ---------------------------------------------------------------------------
; Command to put end marker and finish execution
; ---------------------------------------------------------------------------

d68k_rFinish:
		clr.w	(a1)+						; set end token
		rts
; ---------------------------------------------------------------------------

d68k_MiscInsTbl:
		dc.b d68k_iReset-d68k_iStop,   d68k_iNop-d68k_iStop, 0, d68k_iRte-d68k_iStop
		dc.b -2, d68k_iRts-d68k_iStop, d68k_iTrapv-d68k_iStop,  d68k_iRtr-d68k_iStop

d68k_iStop:	dc.b dcblue, 'stop', dcwhite, ' #', 0
d68k_iReset:	dc.b dcblue, 'reset', 0
d68k_iTrapv:	dc.b dcblue, 'trapv', 0
d68k_iNop:	dc.b dcblue, 'nop', 0
d68k_iRtr:	dc.b dcblue, 'rtr', 0
d68k_iRte:	dc.b dcblue, 'rte', 0
d68k_iRts:	dc.b dcblue, 'rts', 0
; ===========================================================================
; ---------------------------------------------------------------------------
; Various common things
; ---------------------------------------------------------------------------

d68k_sA:	dc.b dcblue, 'a'
d68k_sNull:	dc.b 0
d68k_sX:	dc.b dcblue, 'x', 0
d68k_sDB:	dc.b dcblue, 'd'
d68k_sB:	dc.b dcblue, 'b', 0
d68k_sDotS:	dc.b dcblue, '.'
d68k_sS:	dc.b dcblue, 's', 0
d68k_sDotW:	dc.b dcblue, '.w', 0

d68k_sEor:	dc.b dcblue, 'e'
d68k_sOr:	dc.b dcblue, 'or', 0
d68k_sAnd:	dc.b dcblue, 'and', 0
d68k_sCmp:	dc.b dcblue, 'cmp', 0
d68k_sAdd:	dc.b dcblue, 'add', 0
d68k_sSub:	dc.b dcblue, 'sub', 0
d68k_sMul:	dc.b dcblue, 'mul', 0
d68k_sDiv:	dc.b dcblue, 'div', 0
d68k_sNbcd:	dc.b dcblue, 'n'
d68k_sBcd:	dc.b dcblue, 'bcd', 0
d68k_sExg:	dc.b dcblue, 'exg', 0
d68k_sSwap:	dc.b dcblue, 'swap', 0
d68k_sMove:	dc.b dcblue, 'move', 0
d68k_sLea:	dc.b dcblue, 'lea', 0
d68k_sPea:	dc.b dcblue, 'pea', 0
d68k_sChk:	dc.b dcblue, 'chk', 0
d68k_sClr:	dc.b dcblue, 'clr', 0
d68k_sNot:	dc.b dcblue, 'not', 0
d68k_sNeg:	dc.b dcblue, 'neg', 0
d68k_sTst:	dc.b dcblue, 'tst', 0
d68k_sTas:	dc.b dcblue, 'tas', 0
d68k_sLink:	dc.b dcblue, 'link', 0
d68k_sUnlk:	dc.b dcblue, 'unlk', 0
d68k_sExt:	dc.b dcblue, 'ext', 0
d68k_sJmp:	dc.b dcblue, 'jmp', 0
d68k_sJsr:	dc.b dcblue, 'jsr', 0
d68k_sIllegal:	dc.b dcblue, 'illegal', 0

d68k_sTrap:	dc.b dcblue, 'trap'
d68k_sVal:	dc.b dcwhite, ' #', 0
d68k_sUSP:	dc.b dcgreen, 'usp', 0
d68k_sS2:	dc.b dcgreen, 's', 0
d68k_sCC:	dc.b dcgreen, 'cc', 0
	even
; ---------------------------------------------------------------------------

d68k_PrintAddr2:
		move.l	-(a3),d1					; load address from stack. DO NOT CHANGE!
; ===========================================================================
; ---------------------------------------------------------------------------
; Handler for writing your own addresses into the buffer.
; This could be used to handle reading from a listing file based on
; the provided address
;
; input:
;   d1 = address to write
;   a1 = text buffer address
; ---------------------------------------------------------------------------

d68k_ResolveAddr:
		move.l	d1,(a3)+					; push the address onto stack
		jmp	d68k_PrintAddr(pc)				; print it
; ---------------------------------------------------------------------------
