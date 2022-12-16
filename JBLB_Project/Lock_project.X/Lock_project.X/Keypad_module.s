#include <xc.inc>

global	keypad_setup, keypad_press, FF_swap, FF_unswap
extrn	port_delay

psect	udata_acs   ; reserve data space in access ram
zeroes:	    ds 1    ; reserve one byte for zeroes
counter:    ds 1    ; reserve one byte for a counter variable
file_loc:   ds 4    ; reserve three bytes for location in data memory
temp:	    ds 1    ; reserve one byte for calculations
location:   ds 1    ; reserve one byte for character location

psect	udata_bank5 ; reserve data anywhere in RAM (here at 0x500)
myArray:    ds 0x10 ; reserve 16 bytes for message data
 
psect	data    
	; ******* myTable, data in programme memory, and its length *****
myTable:
	db	'1','2','3','F'
	db	'4','5','6','E'
	db	'7','8','9','D'
	db	'A','0','B','C'

	myTable_l   EQU	16	; length of data
	;align	2
    
psect	keypad_code, class = CODE
keypad_setup:
	banksel	PADCFG1		;Select PADCFG1 bank	
	bsf	REPU		;Set pull up resistors
	banksel	0		;Set back to access
	clrf	LATE, A		;Clear the bits in LAT E
	movlw	0xF0		;Set LAT E such that 0-3 are inputs and 4-7 are outputs
	movwf	TRISE, A
	call	port_delay
	
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	counter, A		; our counter register
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop
	return

FF_swap:
	movlw	11111111B
	lfsr	0, myArray
	incf	FSR0, A
	incf	FSR0, A
	incf	FSR0, A
	movwf	INDF0, A
	return

FF_unswap:
	movlw	'F'
	lfsr	0, myArray
	incf	FSR0, A
	incf	FSR0, A
	incf	FSR0, A
	movwf	INDF0, A
	return
	
keypad_press:
	movlw	0x00
	movwf	zeroes, B
	movlw	0xF0
	movwf	TRISE, A
	call	port_delay	;Allow PORTE to reach value
	movf	PORTE, W, A
	subwf	TRISE, W, A	;TRISE - PORTE placed in W
	cpfslt	zeroes, B
	goto	keypad_press
	
	;movf	PORTE, W
	;subwf	TRISE, W	;TRISE - PORTE placed in W
	movwf	temp, B		;Put in temporary variable
	swapf	temp, F, B		;Swap to work on high nibble
	
	call	colrow_check
	mullw	4
	movff	PROD, location
	
	movlw	0x0F
	movwf	TRISE, A
	;swapf	TRISE, F    ;Swap row to column in TRISE
	call	port_delay  ;Allow PORTE to reach value
	movf	PORTE, W, A
	subwf	TRISE, W, A   ;TRISE - PORTE placed in W
	movwf	temp, B	    ;Put in temporary variable
	
	call	colrow_check
	addwf	location, F, B
	movf	location, W, B
	
	call	keypad_check   ;Return with character in w
	
	return

colrow_check:
	btfsc	temp, 0, B
	retlw	0
	btfsc	temp, 1, B
	retlw	1
	btfsc	temp, 2, B
	retlw	2
	btfsc	temp, 3, B
	retlw	3
	return

keypad_check:
	movwf	temp, B
	movlw	0x00
	movwf	low file_loc, B
	movlw	0x05
	movwf	high file_loc, B
	movf	temp, W, B
	addwf	low file_loc, F, B
	;lfsr	0, file_loc
	movff	low file_loc, FSR0L
	movff	high file_loc, FSR0H
	movf	INDF0, W, A
	return
	
	


end