#include <xc.inc>

global	motor_lock, motor_unlock
    
extrn	LCD_delay_ms
    
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1

psect	motor_code, class = CODE
motor_lock:
	movlw	0x14
	movwf	counter, B
lock_loop:
	clrf	TRISH, A
	setf	LATH, A
	movlw	2
	call	LCD_delay_ms
	clrf	LATH, A
	movlw	18
	call	LCD_delay_ms
	decfsz	counter, B
	bra	lock_loop
	return
	
motor_unlock:
	movlw	0x14
	movwf	counter, B
unlock_loop:
	clrf	TRISH, A
	setf	LATH, A
	movlw	1
	call	LCD_delay_ms
	clrf	LATH, A
	movlw	19
	call	LCD_delay_ms
	decfsz	counter, B
	bra	unlock_loop
	return
	
end