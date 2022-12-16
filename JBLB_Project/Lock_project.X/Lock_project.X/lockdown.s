#include <xc.inc>
    
global	lockdown_setup, inc_failed_attempts, clear_failed_attempts, timerindex001, timerindex010, timerindex100, timerindexArray
extrn	EEPROM_read_loop, EEPROM_write_loop, eeprom_write_counter, eeprom_read_counter
extrn	failed_attempts, lockdown_on
extrn	welcome
extrn	LCD_clear, LCD_lockdown, LCD_timer
extrn	second_delay

psect	udata_acs	    ; reserve data space in access ram
counter:	    ds 1	    ; reserve one byte for character
lockdown_timer:	    ds 1
timerindex001:	    ds 1
timerindex010:	    ds 1
timerindex100:	    ds 1
    
psect	udata_bank7 ; reserve data anywhere in RAM (here at 0x700)
timerindexArray:    ds 0x0A

psect	data
timerindex:
	db	'0','1','2','3','4','5','6','7','8','9'
	timerindexLength   EQU	10	; length of data

;EEPROM DATA:
;000-003: pin
;004	: failed_attempts
;005	: lockdown_on
;006	: timer 1s
;007	: timer 10s
;008	: timer 100s
   

psect	lockdown_code, class = CODE
lockdown_setup:
	call timer_setup
retrieve_failed_attempts:
	movlw	1			;load failed_attempts
	movwf	eeprom_read_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x04
	lfsr	0, failed_attempts
	call	EEPROM_read_loop
	movlw	0xFF			;if failed_attempts is FF, make it 0
	cpfseq	failed_attempts, B
	goto	retrieve_lockdown_on
	movlw	0
	movwf	failed_attempts, B
retrieve_lockdown_on:				;load the lockdown byte in eeprom
	movlw	1
	movwf	eeprom_read_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x05
	lfsr	0, lockdown_on
	call	EEPROM_read_loop
	movlw	0xFF			;if lockdown_on is FF, make it 0, then return to welcome
	cpfseq	lockdown_on, B
	goto	lockdown_check
	movlw	0
	movwf	lockdown_on, B
	return
lockdown_check:				;if lockdown_on is not FF, check what it is
	movlw	0x01			;if lockdown_on is 0, return to welcome
	cpfseq	lockdown_on, B		;if lockdown_on is 1, retrieve timer from eeprom
	return
	movlw	1			;read timer, retrieve each digit individually
	movwf	eeprom_read_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x06			
	lfsr	0, timerindex001
	call	EEPROM_read_loop
	movlw	1			
	movwf	eeprom_read_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x07
	lfsr	0, timerindex010
	call	EEPROM_read_loop
	movlw	1			
	movwf	eeprom_read_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x08
	lfsr	0, timerindex100
	call	EEPROM_read_loop
	goto	lockdown

lockdown:
	movlw	1			;set lockdown_on in eeprom
	movwf	lockdown_on, B
	lfsr	0, lockdown_on		    
	movlw	1			; counter length
	movwf	eeprom_write_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x05
	call	EEPROM_write_loop
	call	LCD_clear
	call	LCD_lockdown
lockdown_loop:
	call	update_eeprom_timer	; send timer to eeprom every second
	call	LCD_timer
	call	second_delay
	goto	timer_decrement		; timer_decrement loops back to lockdown_loop
lockdown_end:
	movlw	0			;clear lockdown_on in eeprom
	movwf	lockdown_on, B
	lfsr	0, lockdown_on		    
	movlw	1			; counter length
	movwf	eeprom_write_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x05
	call	EEPROM_write_loop
	goto	welcome

inc_failed_attempts:
	lfsr	0, failed_attempts
	incf	INDF0, A			; Put new value in eeprom    
	movlw	1			; counter length
	movwf	eeprom_write_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x04
	call	EEPROM_write_loop
	call	check_failed_attempts
	return
	
clear_failed_attempts:
	lfsr	0, failed_attempts
	movlw	0
	movwf	INDF0, A		; Put 0 value in eeprom    
	movlw	1			; counter length
	movwf	eeprom_write_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x04
	call	EEPROM_write_loop
	return
	
check_failed_attempts:
	movlw	2			; check if greater than 2
	cpfsgt	failed_attempts, B
	return
check3:	movlw	3			; check if equal to 3
	cpfseq	failed_attempts, B
	goto	check4
	call	level1
	goto	lockdown
check4:	movlw	4			; check if equal to 4
	cpfseq	failed_attempts, B
	goto	greater
	call	level2
	goto	lockdown
greater:call	level3
	goto	lockdown
	
level1:
	movlw	0x00
	movwf	timerindex001, B
	movlw	0x01
	movwf	timerindex010, B
	movlw	0x00
	movwf	timerindex100, B
	return
	
level2:
	movlw	0x00
	movwf	timerindex001, B
	movlw	0x02
	movwf	timerindex010, B
	movlw	0x00
	movwf	timerindex100, B
	return
	
level3:
	movlw	0x08
	movwf	timerindex001, B
	movlw	0x09
	movwf	timerindex010, B
	movlw	0x09
	movwf	timerindex100, B
	return
	
timer_decrement:
	movlw   0x00		;Needs 0 to compare to
	cpfseq	timerindex001, B	;checks if 1s is 0
	goto	dec1s
	cpfseq	timerindex010, B	;checks if 10s is 0
	goto	dec10s
	cpfseq	timerindex100, B	;checks if 100s is 0
	goto	dec100s
	goto	lockdown_end	;if all 0 then timer complete
	
dec1s:	
	decf	timerindex001, B
	goto	lockdown_loop
dec10s:
	decf	timerindex010, B
	movlw	0x09		
	movwf	timerindex001, B	;sets 1s back to 9
	goto	lockdown_loop
dec100s:
	decf	timerindex100, B
	movlw	0x09		
	movwf	timerindex001, B	;sets 1s back to 9		
	movwf	timerindex010, B	;sets 10s back to 9
	goto	lockdown_loop
	
	
	
timer_setup:
	lfsr	0, timerindexArray	; Load FSR0 with address in RAM	
	movlw	low highword(timerindex)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(timerindex)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(timerindex)		; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	timerindexLength	; bytes to read
	movwf 	counter, A		; our counter register
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop
	return
	
update_eeprom_timer:
	movlw	1			; counter length
	movwf	eeprom_write_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	0, timerindex001	; move 1s to eeprom	    
	lfsr	1, 0x06
	call	EEPROM_write_loop
	movlw	1			; counter length
	movwf	eeprom_write_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	0, timerindex010	; move 10s to eeprom	    
	lfsr	1, 0x07
	call	EEPROM_write_loop
	movlw	1			; counter length
	movwf	eeprom_write_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	0, timerindex100	; move 100s to eeprom	    
	lfsr	1, 0x08
	call	EEPROM_write_loop
	return