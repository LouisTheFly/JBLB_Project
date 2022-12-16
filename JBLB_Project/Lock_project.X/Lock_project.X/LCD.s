#include <xc.inc>

global  LCD_Setup, LCD_clear, LCD_Write_Message, LCD_Send_Byte_I, LCD_Send_Byte_D, LCD_Welcome, LCD_fail, LCD_pass, LCD_unlocked_options, LCD_newpin, LCD_renewpin, LCD_passnewpin, LCD_failnewpin, LCD_lockdown, LCD_timer, LCD_delay_ms
extrn	timerindex001, timerindex010, timerindex100, timerindexArray

psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage
counter:    ds 1    ; reserve one byte for a counter variable

	LCD_E	EQU 5	; LCD enable bit
    	LCD_RS	EQU 4	; LCD register select bit

psect	udata_bank4 ; reserve data for messages (here at 0x400)
EnterPinArray:	    ds 0x0A
FailArray:	    ds 0x09
PassArray:	    ds 0x08
LockdownArray:	    ds 0x0B
OptionRelockArray:  ds 0x0A
OptionNewPinArray:  ds 0x0B
EnterNewPinArray:   ds 0x0E
ReenterNewPinArray: ds 0x0D
PassNewPinArray:    ds 0x0C
FailNewPinArray:    ds 0x0C

psect	data    
EnterPinTable:
	db	'E','n','t','e','r',' ','P','i','n',':'
	EnterPinTableLength   EQU	10	; length of data
	align	2
FailTable:
	db	'I','N','C','O','R','R','E','C','T'
	FailTableLength   EQU	9	; length of data
	align	2
PassTable:
	db	'U','n','l','o','c','k','e','d'
	PassTableLength   EQU	8	; length of data
	align	2
LockdownTable:
	db	'L','O','C','K','E','D',' ','D','O','W','N'
	LockdownTableLength   EQU	11	; length of data
	align	2
OptionRelockTable:
	db	'A',' ','-',' ','R','e','l','o','c','k'
	OptionRelockTableLength   EQU	10	; length of data
	align	2
OptionNewPinTable:
	db	'B',' ','-',' ','N','e','w',' ','P','i','n'
	OptionNewPinTableLength   EQU	11	; length of data
	align	2
EnterNewPinTable:
	db	'E','n','t','e','r',' ','N','e','w',' ','P','i','n',':'
	EnterNewPinTableLength   EQU	14	; length of data
	align	2
ReenterNewPinTable:
	db	'R','e','-','e','n','t','e','r',' ','P','i','n',':'
	ReenterNewPinTableLength   EQU	13	; length of data
	align	2
PassNewPinTable:
	db	'P','i','n',' ','A','c','c','e','p','t','e','d'
	PassNewPinTableLength   EQU	12	; length of data
	align	2
FailNewPinTable:
	db	'D','o',' ','N','o','t',' ','M','a','t','c','h'
	FailNewPinTableLength   EQU	12	; length of data
	align	2


psect	lcd_code,class=CODE
LCD_Setup:
	clrf    LATB, A
	movlw   11000000B	    ; RB0:5 all outputs
	movwf	TRISB, A
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	movlw	00110000B	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00001111B	; display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	movlw	00000110B	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	return
	
table_read_loop: 
	tblrd*+				; one byte from PM to TABLAT, increment TBLPRT
	movf	TABLAT, W, A		; move data from TABLAT to W
	call	LCD_Send_Byte_D		; send data to LCD
	decfsz	counter, A		; count down to zero
	bra	table_read_loop
	return

; Message sending routines
LCD_Welcome:
	lfsr	0, EnterPinArray	; Load FSR0 with address in RAM	
	movlw	low highword(EnterPinTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(EnterPinTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(EnterPinTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	EnterPinTableLength	; bytes to read
	movwf 	counter, A		; our counter register
	call	table_read_loop
	call	LCD_newline
	call	LCD_cursoron
	return

LCD_fail:
	lfsr	0, FailArray		; Load FSR0 with address in RAM	
	movlw	low highword(FailTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(FailTable)		; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(FailTable)		; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	FailTableLength		; bytes to read
	movwf 	counter, A		; our counter register
	call	table_read_loop
	call	LCD_cursoroff
	return

LCD_pass:
	lfsr	0, PassArray		; Load FSR0 with address in RAM	
	movlw	low highword(PassTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(PassTable)		; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(PassTable)		; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	PassTableLength		; bytes to read
	movwf 	counter, A		; our counter register
	call	table_read_loop
	call	LCD_cursoroff
	return
	
LCD_unlocked_options:
	lfsr	0, OptionRelockArray		; Load FSR0 with address in RAM	
	movlw	low highword(OptionRelockTable)	; address of data in PM
	movwf	TBLPTRU, A			; load upper bits to TBLPTRU
	movlw	high(OptionRelockTable)		; address of data in PM
	movwf	TBLPTRH, A			; load high byte to TBLPTRH
	movlw	low(OptionRelockTable)		; address of data in PM
	movwf	TBLPTRL, A			; load low byte to TBLPTRL
	movlw	OptionRelockTableLength		; bytes to read
	movwf 	counter, A			; our counter register
	call	table_read_loop
	call	LCD_newline
	lfsr	0, OptionNewPinArray		; Load FSR0 with address in RAM	
	movlw	low highword(OptionNewPinTable)	; address of data in PM
	movwf	TBLPTRU, A			; load upper bits to TBLPTRU
	movlw	high(OptionNewPinTable)		; address of data in PM
	movwf	TBLPTRH, A			; load high byte to TBLPTRH
	movlw	low(OptionNewPinTable)		; address of data in PM
	movwf	TBLPTRL, A			; load low byte to TBLPTRL
	movlw	OptionNewPinTableLength		; bytes to read
	movwf 	counter, A			; our counter register
	call	table_read_loop
	return
	
LCD_newpin:
	lfsr	0, EnterNewPinArray	; Load FSR0 with address in RAM	
	movlw	low highword(EnterNewPinTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(EnterNewPinTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(EnterNewPinTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	EnterNewPinTableLength	; bytes to read
	movwf 	counter, A		; our counter register
	call	table_read_loop
	call	LCD_newline
	call	LCD_cursoron
	return

LCD_renewpin:
	lfsr	0, ReenterNewPinArray	; Load FSR0 with address in RAM	
	movlw	low highword(ReenterNewPinTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(ReenterNewPinTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(ReenterNewPinTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	ReenterNewPinTableLength	; bytes to read
	movwf 	counter, A		; our counter register
	call	table_read_loop
	call	LCD_newline
	call	LCD_cursoron
	return

LCD_passnewpin:
	lfsr	0, PassNewPinArray	; Load FSR0 with address in RAM	
	movlw	low highword(PassNewPinTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(PassNewPinTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(PassNewPinTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	PassNewPinTableLength	; bytes to read
	movwf 	counter, A		; our counter register
	call	table_read_loop
	call	LCD_cursoroff
	return
	
LCD_failnewpin:
	lfsr	0, FailNewPinArray	; Load FSR0 with address in RAM	
	movlw	low highword(FailNewPinTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(FailNewPinTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(FailNewPinTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	FailNewPinTableLength	; bytes to read
	movwf 	counter, A		; our counter register
	call	table_read_loop
	call	LCD_newline
	call	LCD_cursoron
	return

LCD_lockdown:
	call	LCD_cursoroff
	lfsr	0, LockdownArray	; Load FSR0 with address in RAM	
	movlw	low highword(LockdownTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(LockdownTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(LockdownTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	LockdownTableLength	; bytes to read
	movwf 	counter, A		; our counter register
	call	table_read_loop
	return
	

    
LCD_timer:
	call	LCD_newline
	movf	timerindex100, W, B
	lfsr	2, timerindexArray
	addwf	FSR2, F, A
	movf	INDF2, W, A
	call	LCD_Send_Byte_D
	movf	timerindex010, W, B
	lfsr	2, timerindexArray
	addwf	FSR2, F, A
	movf	INDF2, W, A
	call	LCD_Send_Byte_D
	movf    timerindex001, W, B
	lfsr	2, timerindexArray
	addwf	FSR2, F, A
	movf	INDF2, W, A
	call	LCD_Send_Byte_D
	call	LCD_cursorleft
	call	LCD_cursorleft
	call	LCD_cursorleft
	return

;Screen functions
LCD_clear:				
	movlw	00000001B		; display clear
	call	LCD_Send_Byte_I
	movlw	2			; wait 2ms
	call	LCD_delay_ms
	return
	
LCD_newline:
	movlw	11000000B		; move to next line
	call	LCD_Send_Byte_I
	movlw	2			; wait 2ms
	call	LCD_delay_ms
	return

LCD_cursoron:
	movlw	00001111B		; Cursor on
	call	LCD_Send_Byte_I		
	movlw	2			; wait 2ms
	call	LCD_delay_ms
	return

LCD_cursoroff:
	movlw	00001100B		; Cursor off
	call	LCD_Send_Byte_I		
	movlw	2			; wait 2ms
	call	LCD_delay_ms
	return
	
LCD_cursorleft:
	movlw	00010000B		; Cursor left
	call	LCD_Send_Byte_I		
	movlw	2			; wait 2ms
	call	LCD_delay_ms
	return

LCD_cursorright:
	movlw	00010100B		; Cursor right
	call	LCD_Send_Byte_I		
	movlw	2			; wait 2ms
	call	LCD_delay_ms
	return
	
; Internal stuff	
LCD_Write_Message:	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter, A
LCD_Loop_message:
	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
	return

LCD_Send_Byte_I:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return

LCD_Send_Byte_D:	    ; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A	; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit	    
        call    LCD_Enable  ; Pulse enable Bit 
	movlw	10	    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E, A	    ; Writes data to LCD
	return
    
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return


    end


