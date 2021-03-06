TITLE Project 6 - String Primitives and Macros      (Proj6_malpayae.asm)

; Author:	Eva Malpaya
; Last Modified:	3/16/2021
; OSU email address: malpayae@oregonstate.edu
; Course number/section:   CS271 Section 401
; Project Number:	6                Due Date:	3/14/2021
; Description: This program gets 10 valid integers from the user,
; stores them in an array, then displays them, their sum, and their
; average.

INCLUDE Irvine32.inc

;--------------------------------------------------------------
; Name:	mGetString
;
; Displays a prompt, then places user's keyboard input into a memory
; location.
;
; Preconditions: mPrompt is address of a null-terminated string, 
; mUserInput is address of a string one size bigger than mCount, 
; mBytesRead is a DWORD
;
; Receives:
; mPrompt		= prompt address
; mUserInput	= input buffer
; mCount		= max size user can enter
; mBytesRead	= characters entered by user
;
; Returns:		mUserInput and mBytesRead udpated
;--------------------------------------------------------------
mGetString MACRO mPrompt, mUserInput, mCount, mBytesRead

	; preserve registers
	PUSH	EDX
	PUSH	ECX

	; Display a prompt
	mDisplayString mPrompt

	; Get user's keyboard input into a memory location
	MOV		EDX, mUserInput
	MOV		ECX, mCount
	CALL	ReadString
	MOV		mUserInput, EDX
	MOV		mBytesRead, EAX

	; restore registers
	POP		ECX
	POP		EDX

ENDM


;--------------------------------------------------------------
; Name:	mDisplayString
;
; Prints the string store in the specified memory location.
;
; Preconditions: mString is a null-terminated string
;
; Receives:
; mString		= string to print
;
; Returns:		none; output to terminal only
;--------------------------------------------------------------
mDisplayString MACRO mString

	; preserve registers
	PUSH	EDX

	MOV		EDX, mString
	CALL	WriteString

	; restore registers
	POP		EDX

ENDM

;--------------------------------------------------------------
; Constants
;
;
;--------------------------------------------------------------

COUNT =		32		; length user input string can accomodate
ARRAYSIZE = 10		; Number of valid numbers to get from the user


.data
prog_title			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures ",13,10,0
author				BYTE	"Written by: Eva Malpaya ",13,10,0
ec_1				BYTE	"**EC: Program numbers user input lines & displays running subtotal.",13,10,0	; ec = extra credit
prompt_intro		BYTE	13,10,"Please provide 10 signed decimal integers. ",13,10
					BYTE	"Each number needs to be small enough to fit inside a 32 bit register. ",13,10
					BYTE	"After you have finished inputting the raw numbers I will display ",13,10
					BYTE	"a list of the integers, their sum, and their average value. ",13,10,13,10,0
prompt				BYTE	"Please enter a signed number:  ",0
error				BYTE	"ERROR: You did not enter an signed number or your number was too big. ",13,10,0
prompt_again		BYTE	"Please try again: ",0
display				BYTE	13,10,"You entered the following numbers: ",13,10,0
display_sum			BYTE	"The sum of these numbers is: ",0
display_avg			BYTE	"The rounded average is: ",0
goodbye				BYTE	13,10,"Thanks for playing!  ",0
list_delim			BYTE	", ",0
space				BYTE	" ",0
line				BYTE	"Line ",0
colon				BYTE	": ",0
subtotal			BYTE	"Subtotal: ",0
array				SDWORD	ARRAYSIZE DUP(?)
userInput			BYTE	ARRAYSIZE DUP(33)
bytesRead			DWORD	0
numInt				SDWORD	0	; the string converted to a number
sum					SDWORD	0
avg					SDWORD	0

.code
main PROC
	; Introduce the program
	PUSH	OFFSET ec_1			;16
	PUSH	OFFSET prog_title	;12
	PUSH	OFFSET author		;8
	CALL	introduction

	; Get 10 valid integers from the user
	PUSH	OFFSET subtotal		;60	;ec
	PUSH	OFFSET colon		;56
	PUSH	OFFSET line			;52 ;ec
	PUSH	OFFSET space		;48	
	LEA		EDI, numInt	
	PUSH	EDI					;44
	PUSH	OFFSET error		;40
	PUSH	OFFSET array		;36
	PUSH	OFFSET userInput	;32
	PUSH	bytesRead			;28
	PUSH	COUNT				;24
	PUSH	ARRAYSIZE			;20
	PUSH	OFFSET prompt_intro	;16
	PUSH	OFFSET prompt		;12
	PUSH	OFFSET prompt_again	;8
	CALL	testProgram

	; Calculate the sum
	LEA		EDI, sum
	PUSH	EDI					;16
	PUSH	OFFSET array		;12
	PUSH	ARRAYSIZE			;8
	CALL	calculateSum

	; Calculate the average
	PUSH	sum					;20
	LEA		EDI, avg
	PUSH	EDI					;16
	PUSH	OFFSET array		;12
	PUSH	ARRAYSIZE			;8
	CALL	calculateAvg

	; Display the integers, their sum, and their average
	;mDisplayString display
	PUSH	OFFSET list_delim	;36
	PUSH	OFFSET display		;32
	PUSH	OFFSET display_sum	;28
	PUSH	OFFSET display_avg	;24
	PUSH	OFFSET array		;20
	PUSH	ARRAYSIZE			;16
	PUSH	sum					;12	
	PUSH	avg					;8
	CALL	displayResults

	; Say goodbye
	PUSH	OFFSET goodbye		;8
	CALL	farewell

	Invoke ExitProcess,0	; exit to operating system
main ENDP

;--------------------------------------------------------------
; Name:	introduction
;
; Introduces the program title, programmer's name, and any
; additional extra credit print statements.
;
; Preconditions: all inputs are addresses of null-terminated 
; strings
;
; Postconditions: none.
;
; Receives:
; [ebp+16]		= extra credit statement
; [ebp+12]		= program title
; [ebp+8]		= programmer's name
;
; Returns:		none; output to terminal only
;--------------------------------------------------------------
introduction PROC
	PUSH	EBP
	MOV		EBP, ESP
	; preserve registers	

	; Introduce the program title
	mDisplayString [EBP+12]

	; Introduce the programmer's name
	mDisplayString [EBP+8]

	; Display the extra credit print statements 
	mDisplayString [EBP+16]

	; restore registers
	POP		EBP
	RET		12
introduction ENDP

;--------------------------------------------------------------
; Name:	testProgram
;
; Test program using ReadVal and WriteVal proceures to 
; get 10 valid integers from the user, store them in an array
; and display them, their sum, and their integers.
;
; Preconditions: strings are addresses to null-terminated strings,
; [ebp+36] is an SDWORD array of [ebp+24] size, [ebp+44] is an SDWORD,
; [ebp+28] is a DWORD, [ebp+24] is one less than [ebp+20]
;
; Postconditions: none.
;
; Receives:
; [ebp+60]		= subtotal string (extra credit 1)
; [ebp+56]		= colon string
; [ebp+52]		= line (number) string (extra  credit 1)
; [ebp+48]		= space string
; [ebp+44]		= user's validated SDWORD
; [ebp+40]		= error message string
; [ebp+36]		= array to hold user's numbers
; [ebp+32]		= string to hold user's input
; [ebp+28]		= characters entered by user
; [ebp+24]		= max size user can enter
; [ebp+20]		= size of array for user's numbers
; [ebp+16]		= prompt intro string
; [ebp+12]		= prompt string
; [ebp+8]		= prompt to try again string
;
; Returns:		[ebp+26] filled with converted, validated SDWORDs;
;				[ebp+28] is update with characters entered by user
;--------------------------------------------------------------
testProgram PROC
	; Create local variables
	LOCAL	lineNumber: DWORD
	LOCAL	subTotalSum: DWORD

	; Handled by LOCAL dir
	;PUSH	EBP
	;MOV		EBP, ESP

	; preserve registers	
	PUSH	EAX		
	PUSH	ECX
	PUSH	ESI
	PUSH	EDI

	; initialize local variables
	MOV		lineNumber, 1
	MOV		subTotalSum, 0

	; Prep array
	MOV		ECX, [EBP+20]		; array length into ECX
	MOV		EDI, [EBP+36]		; Address of array into EDI

	; Display the prompt intro
	mDisplayString [EBP+16]		;prompt_intro

	; Get 10 valid integers from the user.
	MOV		ECX, [EBP+20]		;ARRAYSIZE

	;-------------------------------------
	; This loop will fill the array with
	; validated, converted SDWORDS from
	; the user.
	;
	;-------------------------------------
_fillLoop:
	; EXTRA CREDIT 1 - display line number
	; for valid input only
	mDisplayString [EBP+52]		;line
	PUSH	lineNumber
	CALL	WriteVal
	mDisplayString [EBP+56]		;colon

	; Read in a validated input
	PUSH	[EBP+44]			;32	;numInt
	PUSH	[EBP+8]				;28	;prompt_again
	PUSH	[EBP+40]			;24	;error
	PUSH	[EBP+12]			;20	;prompt
	PUSH	[EBP+24]			;16	;COUNT
	PUSH	[EBP+32]			;12	;userInput
	PUSH	[EBP+28]			;8	;bytesRead
	CALL	ReadVal

	; Move the validated input into the array
	MOV		ESI, [EBP+44]		; validated input
	MOV		EAX, [ESI]			
	MOV		[EDI], EAX			; into array
	ADD		EDI, 4				; Move to next spot in array to fill

	; EXTRA CREDIT 1 - display running subtotal
	ADD		subTotalSum, EAX
	mDisplayString [EBP+60]		;subtotal
	PUSH	subTotalSum
	CALL	WriteVal
	CALL	CrLf

	MOV		EAX, 0
	MOV		[ESI], EAX			; reset placeholder for user's validated SDWORD


	INC		lineNumber			; EXTRA CREDIT 1 - increment only for valid entries
	LOOP	_fillLoop
	

	; restore registers
	POP		EDI
	POP		ESI
	POP		ECX
	POP		EAX
	;POP		EBP				; Handled by LOCAL dir
	RET		56
testProgram ENDP

;--------------------------------------------------------------
; Name:	ReadVal
;
; Invokes the mGetString macro to get user input in form of ascii 
; digits, validates the user's input, converts the input to SDWORD,
; then stores it into the provided memory variable.
;
; Preconditions: strings are addresses to null-terminated strings,
; [ebp+32] is an SDWORD, [ebp+8] is a DWORD, [ebp+24] is one less than
; input buffer
;
; Postconditions: none.
;
; Receives:
; [ebp+32]		= user's validated SDWORD
; [ebp+28]		= prompt to try again string
; [ebp+24]		= error message string
; [ebp+20]		= prompt string
; [ebp+16]		= max size user can enter
; [ebp+12]		= string to hold user's input
; [ebp+8]		= characters entered by user
;
; Returns:		[ebp+32] filled with a converted, validated SDWORD;
;				[ebp+8] is update with characters entered by user
;--------------------------------------------------------------
ReadVal PROC
	; Create local variables
	LOCAL	isValid:	DWORD	; bool for character validation ;1 if valid; 0 if not
	LOCAL	isNegative:	DWORD	; bool for whether user input is negative; 1 if negative; 0 if not

	; Handled by LOCAL dir
	;PUSH	EBP
	;MOV		EBP, ESP
	
	; preserve registers	
	PUSH	EAX		
	PUSH	EBX		
	PUSH	ECX
	PUSH	ESI
	PUSH	EDI

	; initialize local variables
	MOV		isValid, 1
	MOV		isNegative, 0

	;-------------------------------------
	; This loop will repeat until a valid
	; signed integer is entered by the user.
	;
	;-------------------------------------
_startLoop:
	; Invoke myGetString macro to get user input in form of string of digits.
	; If the user entered an invalid response in the preceding attempt,
	; it will prompt with the 'try again' message instead.

	MOV		EAX, isValid
	CMP		EAX, 0
	JE		_getStringAgain		; user entered invalid input in preceding attempt
	JMP		_getString

_getStringAgain:
	mGetString [EBP+28], [EBP+12], [EBP+16], [EBP+8]
	JMP		_continueStartLoop
_getString:
	mGetString [EBP+20], [EBP+12], [EBP+16], [EBP+8]

	; Check input string size -
	; Too large
	MOV		EAX, [EBP+8]
	CMP		EAX, 4
	JG		_sizeInvalid
	; Too Small - empty string
	CMP		EAX, 0
	JE		_sizeInvalid

_continueStartLoop:
	LEA		EDI, isValid
	PUSH	EDI						;16	;isValid
	PUSH	[EBP+8]					;12	;bytesRead
	PUSH	[EBP+12]				;8	;userInput
	CALL	validate

	; if the input was invalid, send an error message
	MOV		EAX, isValid
	CMP		EAX, 0
	JE		_notifyInvalid

	; else string is valid
	JMP		_stringIsValid

_sizeInvalid:
	MOV		isValid, 0				; set the bool value if string size was invalid

	; if invalid input given, display the error message
_notifyInvalid:
	mDisplayString [EBP+24]			;error

	JMP		_startLoop

	;-------------------------------------
	; Start conversion after user has
	; entered a validated string of ascii
	; digits.
	;
	;-------------------------------------
_stringIsValid:

; converting to SDWORD
							; Prepare:
	MOV		ECX, [EBP+8]	; length of validated string
	MOV		ESI, [EBP+12]	; String holding user input

	MOV		EDI, [EBP+32]	; SDWORD to hold converted value
	MOV		EAX, 0
	MOV		[EDI], EAX
	
	;-------------------------------------
	; This loop performs the actual conversion
	; of the ascii digit string to SDWORD. Formula
	; is from Module 8, Exploration 1 of course
	; material (retreived March 2021).
	;
	;-------------------------------------
_convertLoop:				; For length of string
	LODSB					; Place byte into AL

	; check whether user entered a sign
_potentialSign:
	; check if plus sign
	CMP		AL, 43			;+
	JE		_continueConvert

	; check if negative sign
	CMP		AL, 45			;-
	JE		_isNeg
	JMP		_startConvert

	; if it's negative, set the bool checker value
_isNeg:
	MOV		isNegative, 1
	JMP		_continueConvert

	; have reached number portion of string; 
	; start conversion
_startConvert:
	SUB		AL, 48			; subtract 48, per Module formula
	MOVSX	EBX, AL

	MOV		EAX, [EDI]		; multiply by 10, per Module formula
	IMUL	EAX, 10			

	ADD		EAX, EBX		; Add these two together, per Module formula
	MOV		[EDI], EAX		; Store it into the SDWORD holder of user input
_continueConvert:
	LOOP	_convertLoop	; repeat for length of string

	; check if number is negative to perform additional needed steps
	CMP		isNegative, 1
	JE		_makeNeg
	JMP		_endReadVal

	; if number is negative, perform two's complement negation
	; so Module formula can work
_makeNeg:
	MOV		EAX, [EDI]
	IMUL	EAX, -1
	MOV		[EDI], EAX		

_endReadVal:	

	; restore registers
	POP		EDI
	POP		ESI
	POP		ECX
	POP		EBX		
	POP		EAX
	;POP		EBP					; Handled by LOCAL dir
	RET		28
ReadVal ENDP

;--------------------------------------------------------------
; Name:	validate
;
; Validates whether a string has valid number or sign characters only.
;
; Preconditions: [ebp+8] is a null-terminated string filled with user's Input,
; [ebp+12] and [ebp+12] are DWORDs, [ebp+12] holds characters entered by the user, 
; [ebp+16] is reset to 1 (valid)
;
; Postconditions: none.
;
; Receives:
; [ebp+16]		= bool value for whether input is valid
; [ebp+12]		= characters entered by user
; [ebp+8]		= string to hold user's inputr
;
; Returns:		[ebp+16] is set to 0 if string is invalid; remains at 1 if valid;
;--------------------------------------------------------------
validate PROC
	; Create local variables
	LOCAL	index:	DWORD	; placeholder in string while checking

	; Handled by LOCAL dir
	;PUSH	EBP
	;MOV		EBP, ESP

	; preserve registers
	PUSH	EAX		
	PUSH	ECX
	PUSH	ESI
	PUSH	EDI

	; initialize local variables
	MOV		index, 0

	;Prep string
	MOV		ECX, [EBP+12]	; String length into loop counter
	INC		ECX				; Account for null-terminator
	MOV		ESI, [EBP+8]	; Address of string into ESI

	MOV		EDI, [EBP+16]	; Reset bool value
	MOV		EAX, 1
	MOV		[EDI], EAX

	;-------------------------------------
	; This loop parses each character in the
	; string, checking via ascii code whether
	; it is a number or sign character.
	; If it is not, bool value is set to
	; 0 = invalid.
	;
	;-------------------------------------
_validateLoop:	
	LODSB					; Put a character BYTE into AL

	; check if first character in string
	PUSH	EAX				; preserve AL before first char check

	MOV		EAX, index		
	CMP		EAX, 0			; if first character, check for sign first
	JE		_checkSign
	JMP		_checkNumber

_checkSign:
	POP		EAX				; restore AL after first char check

	; check if a sign character; if it is, continue to
	; next character in string
	CMP		AL, 43			; + positive sign
	JE		_isValidChar

	CMP		AL, 45			; - negative sign
	JE		_isValidChar
	JMP		_continueCheck

	; check if characters are numbers
_checkNumber:
	POP		EAX				; restore AL after first char check

_continueCheck:

	; check if end of string
	CMP		AL, 0
	JE		_endOfString	; if it is, end validation

	CMP		AL, 48			; 0 - check if less than range of number digits in ascii
	JL		_invalidChar
	CMP		AL, 57			; 9 - check if greater than range of number digits in ascii
	JG		_invalidChar
	JMP		_isValidChar

_isValidChar:
	INC		index			; if valid character, move to the next character in the string
	STOSB
	LOOP	_validateLoop
	JMP		_endOfString	; when reached end of string, end validation

_invalidChar:
	MOV		EDI, [EBP+16]	; if invalid character, update the bool value
	MOV		EAX, 0
	MOV		[EDI], EAX

_endOfString:
	; restore registers
	POP		EDI
	POP		ESI
	POP		ECX
	POP		EAX
	;POP		EBP			; Handled by LOCAL dir
	RET		12
validate ENDP

;--------------------------------------------------------------
; Name:	WriteVal
;
; Converts an SDWORD value into a string of ascii digits.
; Invokes the mDisplayString macro to print the converted string
; to the terminal.
;
; Preconditions: [ebp+8] is an initialized SDWORD
;
; Postconditions: none.
;
; Receives:
; [ebp+8]		= SDWORD to convert into string of ascii digits
;
; Returns:		none; output to terminal only
;--------------------------------------------------------------
WriteVal PROC
	; Create local variables
	LOCAL	string[33]:	BYTE		; placeholder for string
	LOCAL	reverseString[33]: BYTE	; placeholder for reversed string
	LOCAL	number: DWORD			; placeholder for SDWORD
	LOCAL	byteCounter: DWORD		; used ty count number of characters in string

	; Handled by LOCAL dir
	;PUSH	EBP
	;MOV		EBP, ESP

	; preserve registers
	PUSH	EAX		
	PUSH	EBX		
	PUSH	ECX
	PUSH	EDX
	PUSH	ESI
	PUSH	EDI

	MOV		byteCounter, 0

	; Place SDWORD to convert into temp placeholder
	MOV		EAX, 0
	MOV		EAX, [EBP+8]	
	MOV		number, EAX

	; Prep local variable to hold the converted string
	LEA			EDI, string

	;-------------------------------------
	; This section performs the actual conversion
	; of the SDWORD to a ascii digit string to SDWORD. 
	; Formula is the reverse of the one from 
	; Module 8, Exploration 1 of course material 
	; used to convert the user input into an SDWORD
	; (retreived March 2021).
	;
	;-------------------------------------
_startNumberConversion:
	MOV		ECX, 99				; random high loop counter number; will repeat until null-terminator found

	MOV		EAX, number			; check if number is negative (less than zero) for special handling
	CMP		EAX, 0			
	JL		_negNegative
	JMP		_isANumberLoop

_negNegative:
	NEG		EAX					; perform two's complement conversion for formula to work if negative

_isANumberLoop:
	MOV		EBX, 10				; divide by 10, per reverse of Module formula (gets right-most digit)
	CDQ
	IDIV	EBX
	MOV		EBX, EAX			; store the remainder to get the next digit to convert

	MOV		EAX, EDX			; add 48 to quotient to get correct ascii digit, per reverse of Module formula 
	ADD		EAX, 48			
	STOSB						; move to the next place in the string
	INC		byteCounter			; increment the character counter

	MOV		EAX, EBX			; add the needed numbers together to get final correct ascii digit, per reverse of Module formula

	CMP		EAX, 0				; when reached zero, no more digits to convert
	JE		_noMoreLoops
	JMP		_continueIsANumber

_noMoreLoops:
	MOV		ECX, 1				; end the conversion loop; altering ECX purposefully to allow for differing number length input

_continueIsANumber:
	LOOP	_isANumberLoop

	; Special handling if number is negative
	MOV		EAX, number
	CMP		EAX, 0
	JGE		_isPositive
	JMP		_isNegative

_isPositive:					; if positive, end the string (will not print '+' sign character to match expected output)
	JMP		_addNullTerminator

_isNegative:					; if negative, add the negative sign
	MOV		AL, 45				; - negative sign
	STOSB						; move to the next place in the string
	INC		byteCounter		

_addNullTerminator:				; add null-terminator to completed converted string so prints correctly
	MOV		AL, 0
	STOSB
	INC		byteCounter

	;-------------------------------------
	; Due to endianness, we must reverse
	; the converted string so it prints
	; correctly. Adapted from the 
	; StringManipulator.asm demo video
	; from one of the Module Explorations
	; (retrieved March 2021).
	;
	;-------------------------------------
	; Set up the loop counter and indices
	  MOV	ECX, byteCounter	; length of string
	  LEA	ESI, string
	  ADD	ESI, ECX			; start at end of string
	  DEC	ECX					; so as to not print extra characters
	  DEC	ESI					; get past the null-terminator
	  DEC	ESI
	  LEA	EDI, reverseString

	; Reverse the string
_revLoop:
	STD							; set direction flag
	LODSB						; get next character from input string
	CLD							; clear the direction flag
	STOSB						; move to next place in output string
	LOOP	_revLoop

	; add null-terminator to complete the reversed string
	MOV		AL, 0
	STOSB

	; Print the ascii representation of the converted SDWORD
	LEA		EDX, reverseString			
	mDisplayString EDX

_endOfWriteVal:
	; restore registers
	POP		EDI
	POP		ESI
	POP		EDX
	POP		ECX
	POP		EBX		
	POP		EAX
	;POP		EBP				; Handled by LOCAL dir
	RET		4
WriteVal ENDP


	;PUSH	sum					;16
	;PUSH	OFFSET array		;12
	;PUSH	ARRAYSIZE			;8
;--------------------------------------
; 
; (if necessary).
; preconditions:	
; postconditions:	
; receives:			
; returns:			
;--------------------------------------
calculateSum PROC
	PUSH	EBP
	MOV		EBP, ESP
	; preserve registers
	PUSH	EAX		
	PUSH	EBX		
	PUSH	ECX
	PUSH	EDX
	PUSH	ESI
	PUSH	EDI


	; calculate
	MOV		ESI, [EBP+12]	;array
	MOV		ECX, [EBP+8]	;ARRAYSIZE
	MOV		EDI, [EBP+16]
	MOV		EAX, [EDI]	;sum

_sumLoop:
	MOV		EBX, [ESI]
	ADD		EAX, EBX			; add value in the array to sum
	ADD		ESI, TYPE SDWORD	; point to next element in the array
	LOOP	_sumLoop

	;MOV		[EBP+16], EAX
	;MOV		EAX, [EBP+16]	; debug only
	;CALL	WriteInt		; debug only

	MOV		EDI, [EBP+16]
	MOV		[EDI], EAX

	; restore registers
	POP		EDI
	POP		ESI
	POP		EDX
	POP		ECX
	POP		EBX		
	POP		EAX
	POP		EBP
	RET		12
calculateSum ENDP



;--------------------------------------------------------------
; Name: calculateAvg
; 
; Calculates the average of a given array.
;
; Preconditions:	sum calculated, array filled of size ARRAYSIZE
;
; Postconditions:	none.
;
; Receives:			
; sum				;20
; avg				;16
; OFFSET array		;12
; ARRAYSIZE			;8
;
; Returns:			avg filled with calculated average
;--------------------------------------------------------------
calculateAvg PROC
	PUSH	EBP
	MOV		EBP, ESP
	; preserve registers
	PUSH	EAX		
	PUSH	EBX		
	PUSH	ECX
	PUSH	EDX
	PUSH	ESI
	PUSH	EDI

	; Calculate the average = sum / array size
	MOV		EAX, [EBP+20]	; sum
	MOV		EBX, [EBP+8]	; arraysize
	CDQ
	IDIV	EBX

	; If the average is negative, round down instead.
	; Used the below link as reference for rounding 
	; negatives to 'floor' (Retrieved March 2021):
	; https://www.calculator.net/rounding-calculator.html?cnum=-321.9&cpre=0&cpren=2&cmode=nearest&sp=0&x=0&y=0
	CMP		EAX, 0
	JL		_roundDown
	JMP		_storeAverage

_roundDown:
	DEC		EAX

_storeAverage:
	MOV		EDI, [EBP+16]
	MOV		[EDI], EAX

	; restore registers
	POP		EDI
	POP		ESI
	POP		EDX
	POP		ECX
	POP		EBX		
	POP		EAX
	POP		EBP
	RET 16
calculateAvg ENDP

;--------------------------------------------------------------
; Name: printArray
; 
; Traverses an array and prints out its values with a space
; in-between each number.
;
; Preconditions:		some array is a DWORD array the size of array size,
;						array size is the size of the array,
;						some print message contains null-terminated string
;
; Postconditions:		none.
;
; Receives:			
; some Print message	;16
; some array			;12
; its array size		;8
;
; Returns:				none; output to terminal only
;--------------------------------------------------------------
printArray PROC
	PUSH	EBP
	MOV		EBP, ESP

	; preserve registers
	PUSH	EAX		
	PUSH	EBX		
	PUSH	ECX
	PUSH	EDX
	PUSH	ESI
	PUSH	EDI

	; Access the list
	MOV		ECX, [EBP+8]	; List length into ECX
	MOV		ESI, [EBP+12]	; Address of list into EDI


	; traverse the list and print each number
	; with a space in-between. Prints new line
	; every 20 numbers
_displayLoop:
	MOV		EAX, [ESI]		; Print out a number in the list
	;CALL	WriteInt		; debug only
	PUSH	EAX				;8
	;CALL	WriteInt		; debug only
	CALL	WriteVal

	CMP		ECX, 1
	JE		_noDelim
	mDisplayString [EBP+16]		; print out delim character


_noDelim:
	ADD		ESI, 4			; Move to the next element in list
	LOOP	_displayLoop

	; restore registers
	POP		EDI
	POP		ESI
	POP		EDX
	POP		ECX
	POP		EBX		
	POP		EAX
	POP		EBP			
	RET		12
printArray ENDP


	;PUSH	OFFSET list_delim	;36
	;PUSH	OFFSET display		;32
	;PUSH	OFFSET display_sum	;28
	;PUSH	OFFSET display_avg	;24
	;PUSH	OFFSET array		;20
	;PUSH	ARRAYSIZE			;16
	;PUSH	sum					;12	
	;PUSH	avg					;8

;--------------------------------------------------------------
; Name: displayResults
; 
; Prints array, their sum, and their average.
;
; Preconditions:		some array is a DWORD array the size of array size,
;						array size is the size of the array,
;						strings are null-terminated, sum and avg calculated
;
; Postconditions:		none.
;
; Receives:			
; OFFSET list_delim		;36
; OFFSET display		;32
; OFFSET display_sum	;28
; OFFSET display_avg	;24
; OFFSET array			;20
; ARRAYSIZE				;16
; sum					;12	
; avg					;8
;
; Returns:				none; output to terminal only
;--------------------------------------------------------------
displayResults PROC
	PUSH	EBP
	MOV		EBP, ESP
	; preserve registers	
	PUSH	EAX		
	PUSH	EBX		
	PUSH	ECX
	PUSH	EDX
	PUSH	ESI
	PUSH	EDI

	; Display the integers in the array
	mDisplayString [EBP+32]
	PUSH	[EBP+36]		;16	;list_delim
	PUSH	[EBP+20]		;12	;array
	PUSH	[EBP+16]		;8	;ARRAYSIZE
	CALL	printArray
	CALL	CrLf			; Was told can use this per Piazza question @446 discussion thread


	; Display the sum
	mDisplayString [EBP+28]
	PUSH	[EBP+12]		;8	;sum
	CALL	WriteVal
	CALL	CrLf			; Was told can use this per Piazza question @446 discussion thread

	; Display the average
	mDisplayString [EBP+24]
	PUSH	[EBP+8]			;8	;avg
	CALL	WriteVal
	CALL	CrLf			; Was told can use this per Piazza question @446 discussion thread

	; restore registers
	POP		EDI
	POP		ESI
	POP		EDX
	POP		ECX
	POP		EBX		
	POP		EAX
	POP		EBP
	RET		32
displayResults ENDP

;--------------------------------------------------------------
; Name: farewell
; 
; Displays a parting message.
;
; Preconditions:		goodbye is a null-terminated string
;
; Postconditions:		none.
;
; Receives:				
; goodbye 				;8
;
; Returns:				none; output to terminal only
;--------------------------------------------------------------

farewell PROC
	PUSH	EBP
	MOV		EBP, ESP
	; preserve registers
	PUSH	EDX

	; display the goodbye messsage
	MOV		EDX, [EBP+8]
	CALL	WriteString

	; restore registers
	POP		EDX
	POP		EBP
	RET		4
farewell ENDP


END main
