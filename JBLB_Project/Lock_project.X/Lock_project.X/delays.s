#include <xc.inc>

global	sticky_key_delay, port_delay, motor_delay, display_delay, second_delay
    
psect	udata_acs   ; reserve data space in access ram
Counter1:   ds 1    ; reserve one byte for Counter 1
Counter2:   ds 1    ; reserve one byte for Counter 2
Counter3:   ds 1    ; reserve one byte for Counter 3

psect	delay_code, class = CODE

; Fixed length delay to prevent quick presses
sticky_key_delay:
	movlw	0xFF
	movwf	Counter1, B
	movlw	0xFF
	movwf	Counter2, B
	movlw	0x10
	movwf	Counter3, B
	call	delay_loop
	return

; Fixed length delay to allow ports to reach value
port_delay:
	movlw	0xFF
	movwf	Counter1, B
	movlw	0xFF
	movwf	Counter2, B
	movlw	0x01
	movwf	Counter3, B
	call	delay_loop
	return
	
; Fixed length delay to allow ports to reach value
motor_delay:
	movlw	0xFF
	movwf	Counter1, B
	movlw	0xFF
	movwf	Counter2, B
	movlw	0x05
	movwf	Counter3, B
	call	delay_loop
	return
	
; Fixed length delay to allow ports to reach value
display_delay:
	movlw	0xFF
	movwf	Counter1, B
	movlw	0xFF
	movwf	Counter2, B
	movlw	0x40
	movwf	Counter3, B
	call	delay_loop
	return

; One second delay for timer
second_delay:
	movlw	0xFF
	movwf	Counter1, B
	movlw	0xFF
	movwf	Counter2, B
	movlw	0x52
	movwf	Counter3, B
	call	delay_loop
	return

; Multiplicative delay
delay_loop:
	decfsz	Counter1, F, B
	goto	delay_loop
	decfsz	Counter2, F, B
	goto	delay_loop
	decfsz	Counter3, F, B
	goto	delay_loop
	return

end