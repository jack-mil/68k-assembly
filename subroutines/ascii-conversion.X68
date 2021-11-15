*-----------------------------------------------------------
* Title      :
* Written by : Jackson Miller
* Date       : 11/11/2021
* Description: Define and test some subroutines to convert ascii and number values
*-----------------------------------------------------------
	OPT		NOMEX
	OPT		SEX

CODE	EQU		0
TEXT	EQU		1
CR		EQU		$0D
LF		EQU		$0A
NUL		EQU		$00


	SECTION TEXT
	ORG		$800	; set address for TEXT data

	SECTION CODE
	ORG		$2000	; set address for program code

* ----------------------------- *
*       Macro Definitions       *
* ----------------------------- *

* print the text string
* use 'ENDL' as second argument to add return and linefeed
Print	MACRO
	; store string constants in text section
	SECTION TEXT
MSG\@	DC.B	'\1'	; store block of message text with label MSG_#
	IFARG	2
		IFC '\2','ENDL'
			DC.B	CR,LF
		ENDC
	ENDC
	DC.B	NUL		; add nul terminator

	; store logic in code section
	SECTION CODE
	movem.l  D0/A1,-(SP) ; save state
	lea		MSG\@,A1    ; address of string to display in A1
	move    #14,D0      ; task 14, display string
	trap    #15         ; perform task
	movem.l (SP)+,D0/A1 ; restore state
	ENDM

PrintResult	MACRO
	movem.l	D0/A1,-(SP)		; save state
	lea		\1,A1			; address of message
	move	#14,D0			; task 14, display string
	trap	#15				; perform tests
	movem.l	(SP)+,D0/A1		; restore state
	ENDM

TestRoutine MACRO		; RoutineToTest,testValue,expectedOutput
	move.\0 \2,-(SP)	; load stack with test value

	bsr		\1			; execute subroutine

	IFC '\3','FAIL'			; if test should fail
		IF <CS> THEN		; ensure carry flag set
			move.l	#1,D0
			PrintResult	tpass
		ELSE
			move.l	#0,D0
			PrintResult	tfail
		ENDI
		MEXIT				; Exit macro processing
	ENDC

	move.\0	(SP)+,D1		; pull result from stack into D1

	IF.\0 D1 <EQ> \3 AND.\0 <CC> THEN	; check pass condition
		move.l	#1,D0
		PrintResult	tpass
	ELSE
		move.l	#0,D0
		PrintResult	tfail
	ENDI
	ENDM

TestIntToAscii	MACRO		; TestIntToAscii testValue,expectedValue
	move.w	\1,D0			; load D0 with test value

	jsr WordToStr16

	IF.L D0 <EQ> \2 THEN		; check pass condition
		move.l    #1,D0
		PrintResult	tpass
	ELSE
		move.l    #0,D0
		PrintResult	tfail
	ENDI
	ENDM

* ------------------------- *
*  Begin Program Execution	*
* ------------------------- *
START

	* * --- Setup Output Window --- *
	move.b	#33,D0				; Task 33 sets output window size
	move.l	#85*$10000+800,D1	; Set screen size to 85 x 768
	trap	#15					; execute task

	* ---- CharToInt10 Tests ---- *
	Print	<* Begin CharToInt10 Tests *>,ENDL

	Print	<* Case 01: 0x00 = ERR *>,ENDL
	TestRoutine.b CharToInt10,#$0,FAIL

	Print	<* Case 02: 0x2F = ERR *>,ENDL
	TestRoutine.b CharToInt10,#$2F,FAIL

	Print	<* Case 03: Ox30 = 0x00 *>,ENDL
	TestRoutine.b CharToInt10,#$30,#$00

	Print	<* Case 04: 0x39 = 0x09 *>,ENDL
	TestRoutine.b CharToInt10,#$39,#$09

	Print	<* Case 05: 0x3A = ERR *>,ENDL
	TestRoutine.b CharToInt10,#$3A,FAIL

	Print	<* Case 06: 0xFF = ERR *>,ENDL
	TestRoutine.b CharToInt10,#$FF,FAIL

	Print	,ENDL

	* ---- CharToInt16 Tests ---- *
	Print   <* Begin CharToInt16 Tests *>,ENDL

	Print	<* Case 01: 0x00 = ERR *>,ENDL
	TestRoutine.b CharToInt16,#$0,FAIL

	Print	<* Case 02: 0x2F = ERR *>,ENDL
	TestRoutine.b CharToInt10,#$2F,FAIL

	Print	<* Case 03: Ox30 = 0x00 *>,ENDL
	TestRoutine.b CharToInt16,#$30,#$00

	Print	<* Case 04: 0x39 = 0x09 *>,ENDL
	TestRoutine.b CharToInt16,#$39,#$09

	Print	<* Case 05: 0x3A = ERR *>,ENDL
	TestRoutine.b CharToInt16,#$3A,FAIL

	Print	<* Case 06: 0xFF = ERR *>,ENDL
	TestRoutine.b CharToInt16,#$FF,FAIL

	Print	<* Case 07: 0x40 = ERR *>,ENDL
	TestRoutine.b CharToInt16,#$40,FAIL

	Print	<* Case 08: 0x41 = 0x0A *>,ENDL
	TestRoutine.b CharToInt16,#$41,#$0A

	Print	<* Case 09: 0x46 = 0x0F *>,ENDL
	TestRoutine.b CharToInt16,#$46,#$0F

	Print	<* Case 10: 0x47 = ERR *>,ENDL
	TestRoutine.b CharToInt16,#$47,FAIL

	Print	<* Case 11: 0x60 = ERR *>,ENDL
	TestRoutine.b CharToInt16,#$60,FAIL

	Print	<* Case 12: 0x61 = 0x0A *>,ENDL
	TestRoutine.b CharToInt16,#$61,#$0A

	Print	<* Case 13: 0x66 = 0x0F *>,ENDL
	TestRoutine.b CharToInt16,#$66,#$0F

	Print	<* Case 14: 0x67 = ERR  *>,ENDL
	TestRoutine.b CharToInt16,#$67,FAIL

	Print	,ENDL
	* ---- IntToStr16 Tests ---- *
	Print	<* Begin IntToStr16 Tests *>,ENDL
	Print	<* Case 01: 0x0000 = "0000" *>,ENDL
	TestIntToAscii #$0000,#$30303030
	Print	<* Case 02: 0x1234 = "1234" *>,ENDL
	TestIntToAscii #$1234,#$31323334
	Print	<* Case 03: 0xABCD = "ABCD" *>,ENDL
	TestIntToAscii #$ABCD,#$41424344
	Print	<* Case 04: 0xFFFF = "FFFF" *>,ENDL
	TestIntToAscii #$FFFF,#$46464646

	SIMHALT					; halt simulator


* ------------------------- *
*   Subroutine definitions  *
* ------------------------- *

offset		EQU		8	; the input and output argument will
						; be offset by 8 from the stack frame pointer
						; (subroutine return address, and A6 backup)

* Convert a single ASCII number char to number *
* Reads a base 10 numerical ascii byte from the stack,
* and replaces it with it's numerical value.
* e.g. 0x34 ('4') => 0x04
CharToInt10
	link	A6,#0		; create stack frame to access input parameter
						; (size zero because no local variables needed)
	move.l  D0,-(SP)	; save D0
	move.b  offset(A6),D0	; access input parameter from stack frame

	IF.B D0 <HS> #$30 AND.B	D0 <LS> #$39 THEN
		sub.w	#$30,D0			; subtract ascii offset for integer
		move.b	D0,offset(A6)	; store result in stack frame
	ELSE
		ori   #1,CCR			; set carry flag if character out of range
	ENDI

	movem.l (SP)+,D0	; restore D0
	unlk	A6			; return and destroy stack frame
	rts

* Convert a single ASCII hex digit to number *
* Reads a base 16 numerical ascii byte from the stack,
* and replaces it with it's numerical value.
* e.g. 0x61 ('A') => 0x0A
CharToInt16
	link	A6,#0		; create stack frame to access input parameter
						; (size zero because no local variables needed)
	move.l  D0,-(SP)	; save D0
	move.b  offset(A6),D0	; access input parameter from stack frame

	; check number or character range
	IF.B D0 <GE> #$30 AND.B D0 <LE> #$39 THEN
		sub.b #$30,D0				; subtract ascii offset for integer
		move.b  D0,(offset,A6)		; store result on eventual top of stack
	ELSE
		ori	#$20,D0					; convert uppercase to lowercase
		IF.B D0 <GE> #$61 AND.B D0 <LE> #$66 THEN
			sub.b	#$61,D0				; Subtract 'a' character
			add.b	#$0A,D0				; add 10
			move.b	D0,(offset,A6)		; store result on eventual top of stack
		ELSE
			ori		#1,CCR				; set carry flag if character out of range
		ENDI
	ENDI

	movem.l (SP)+,D0		; restore D0
	unlk	A6				; return and destroy stack frame
	rts


* Convert a 16 bit word to ascii string representation *
* Put word value in D0. Subroutine will convert to long-word ascii string in D0 *
WordToStr16
	movem.l	D1,-(SP)			; save D1 for loop variable

	DBLOOP	D1 = #3				; Loop 4 times
		lsl.l	#4,D0			; shift entire register four bits left
		lsr.b	#4,D0			; shift byte four bits right, to isolate first nibble
		IF.B D0 <LT> #$09 THEN	; if in '0'-'9' range
			add.b	#$30,D0			; add number char ascii offset
		ELSE					; else in range 'A'-'F'
			add.b	#$37,D0			; add capital letter ascii offset
		ENDI
		move.b	D0,-(SP)		; store result ascii byte on stack
		lsr.l	#8,D0			; shift ascii byte out
	UNLESS

	; pop bytes from the stack and assemble into a long-word
	DBLOOP	D1 = #3
		lsl.l	#8,D0
		move.b	(SP)+,D0
	UNLESS

	movem.l	(SP)+,D1			; Restore D1
	rts

*------------------------------------
* Variable storage and strings
* dc (define constant) is used to place data in memory
	SECTION		TEXT
tfail	DC.B	'Test failed',CR,LF,NUL		; pass and fail strings
tpass	DC.B	'Test passed',CR,LF,NUL

	END		START			; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
