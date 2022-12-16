#include <xc.inc>

global	pin_setup, pin_check, pin_set, pin_enter, EEPROM_write_loop, EEPROM_read, EEPROM_read_loop, eeprom_read_counter, eeprom_write_counter

extrn	char, pin, pin_length, setup, pass, fail, get_pin, welcome
extrn	LCD_newpin, LCD_renewpin, LCD_clear, LCD_Send_Byte_D, LCD_passnewpin, LCD_failnewpin
extrn	keypad_press, FF_swap
extrn	sticky_key_delay, display_delay
    
psect	udata_acs   ; reserve data space in access ram
counter:	ds 1    ; reserve one byte for a counter variable
eeprom_read_counter:	ds 1
eeprom_write_counter:	ds 1
temp_pin1:	ds 4
temp_pin2:	ds 4

;psect	eedata	    ;EEPROM memory reserved
;stored_pin:	ds 4
    
psect	udata_bank6 ; reserve data anywhere in RAM (here at 0x600)
PinArray:    ds 0x4  ; reserve 4 bytes for message data
 
psect	data
PinTable:
	db	'0','0','0','0'
	PinTableLength   EQU	4	; length of data
	;align	2
    
psect	pin_code, class = CODE
pin_setup:				; check if something other than (0000) is in EEPROM, if it is, don't overwrite it
	call	EEPROM_read
	lfsr	0, PinArray
	movlw	0xFF	    ;checks if the pin is FFs
	cpfseq	POSTINC0, A
	return
	call	FF_swap
	return
	
pin_enter:
	call	keypad_press
	movwf	char, B		    ; places typed number into char
	movff	char, POSTINC1
	movf	char, W, B		    ; send char to LCD
	call	LCD_Send_Byte_D
	call	sticky_key_delay    ;prevents multiple key presses
	decfsz	pin_length, B	    ;checks pin if 4 chars have been typed
	goto	pin_enter
	return
	
pin_check:
	lfsr	0, PinArray
	lfsr	1, pin
	movf	POSTINC0, W, A	    ;Specifically for pin length 4
	cpfseq	POSTINC1, A
	goto	fail
	movf	POSTINC0, W, A
	cpfseq	POSTINC1, A
	goto	fail
	movf	POSTINC0, W, A
	cpfseq	POSTINC1, A
	goto	fail
	movf	POSTINC0, W, A
	cpfseq	POSTINC1, A
	goto	fail
	goto	pass
	
pin_set:
	; type new pin
	call	LCD_clear
	call	LCD_newpin
	movlw	4		; Allowed length of pin
	movwf	pin_length, B
	lfsr	1, temp_pin1
	call	pin_enter
	; type again
	call	LCD_clear
	call	LCD_renewpin
	movlw	4		; Allowed length of pin
	movwf	pin_length, B
	lfsr	1, temp_pin2
	call	pin_enter
	
	;check pins match
	lfsr	0, temp_pin1
	lfsr	1, temp_pin2
	movf	POSTINC0, W, A	    ;Specifically for pin length 4
	cpfseq	POSTINC1, A
	goto	newpin_fail
	movf	POSTINC0, W, A
	cpfseq	POSTINC1, A
	goto	newpin_fail
	movf	POSTINC0, W, A
	cpfseq	POSTINC1, A
	goto	newpin_fail
	movf	POSTINC0, W, A
	cpfseq	POSTINC1, A
	goto	newpin_fail
	goto	newpin_pass
	
newpin_fail:
	call	LCD_clear
	call	LCD_failnewpin
	call	display_delay
	goto	pin_set
	
newpin_pass:
	call	LCD_clear
	call	LCD_passnewpin
	call	display_delay
	movlw	4		    ; pin length
	movwf	eeprom_write_counter, B
	lfsr	0, temp_pin1
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x00
	call	EEPROM_write_loop
	goto	get_pin

EEPROM_write_loop:
	movff	FSR1, EEADR	    ; moving low bit of address to write to
	incf	FSR1, A
	movff	POSTINC0, EEDATA    ; moving data
	bcf	EECON1, 6, A	    ; CFGS These bits allow writing
	bcf	EECON1, 7, A	    ; EEPGD
	bsf	EECON1, 2, A	    ; WREN
	bcf	EECON1, 0, A	    ; RD off
	bcf	GIE		    ;Disable global interrupts 
	movlw	0x55		    ;This is required for some reason
	movwf	EECON2, A
	movlw	0xAA
	movwf	EECON2, A
EEPROM_wait:
	bsf	EECON1, 1, A	    ; WR
	btfsc	EECON1, 1, A	    ; WR
	goto	EEPROM_wait
	bsf	GIE		    ;Re-enables global interrupts
	decfsz	eeprom_write_counter, A
	goto	EEPROM_write_loop
	return

EEPROM_read:
	call	LCD_clear
	movlw	4		    ; pin length
	movwf	eeprom_read_counter, B
	movlw	0x00
	movwf	EEADRH, A
	lfsr	1, 0x00
	lfsr	0, PinArray
EEPROM_read_loop:
	movff	FSR1, EEADR
	bcf	EECON1, 6, A	    ; CFGS These bits allow writing
	bcf	EECON1, 7, A	    ; EEPGD
	bcf	EECON1, 2, A	    ; WREN off
	bsf	EECON1, 0, A	    ; RD
	nop
	movf	EEDATA, W, A
	movwf	POSTINC0, A
	incf	FSR1, A
	
	decfsz	eeprom_read_counter, A
	goto	EEPROM_read_loop
	return


;EEPROM_sucks:
;	for i in range(1E100)
;	    print(EEPROM sucks)
end
