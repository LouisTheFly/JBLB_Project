#include <xc.inc>

global  pin, pin_length, setup, pass, fail, char, get_pin, welcome, failed_attempts, lockdown_on
    
extrn	pin_setup, pin_check, pin_set, pin_enter, EEPROM_read
extrn	keypad_setup, FF_unswap, keypad_press
extrn	LCD_Setup, LCD_clear, LCD_Write_Message, LCD_Send_Byte_I, LCD_Send_Byte_D, LCD_Welcome, LCD_fail, LCD_pass, LCD_unlocked_options
extrn	sticky_key_delay, display_delay
extrn	lockdown_setup, inc_failed_attempts, clear_failed_attempts
extrn	motor_lock, motor_unlock

psect	udata_acs	    ; reserve data space in access ram
char:	    ds 1	    ; reserve one byte for character
location:   ds 1	    ; reserve one byte for character location
temp:	    ds 1	    ; reserve one byte for calculations
pin_length: ds 1	    ; reserve one byte for checking pin length
pin:	    ds 4	    ; reserve four bytes for storing typed pin
failed_attempts:    ds 1
lockdown_on:	    ds 1
    
psect code, abs
setup:
	org	0x0
	call	LCD_Setup
	call    keypad_setup
	call	pin_setup
	call	lockdown_setup
	goto	welcome
	org	0x100

get_pin:
	call	EEPROM_read	; Get new pin if reset
welcome:
	call	motor_lock	; Locks if not already
	movlw	4		; Allowed length of pin
	movwf	pin_length, B
	lfsr	1, pin
	call	LCD_clear
	call	LCD_Welcome
	call	pin_enter
	goto	pin_check

fail:
	call	LCD_clear
	call	LCD_fail
	call	display_delay
	call	inc_failed_attempts
	goto	welcome

pass:
	call	LCD_clear
	call	LCD_pass
	call	motor_unlock
	call	FF_unswap
	call	clear_failed_attempts
	call	display_delay
	call	LCD_clear
	call	LCD_unlocked_options
options:
	call	keypad_press
	movwf	char, B		    ;places typed number into char
	call	sticky_key_delay    ;prevents multiple key presses
checkA:	movlw	'A'		    ;checking if char is A, to relock
	cpfseq	char, B
	goto	checkB
	goto	welcome
checkB:	movlw	'B'		    ;checking if char is B, to set new pin
	cpfseq	char, B
	goto	options
	goto	pin_set
	
	
	

end