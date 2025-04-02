; Lab 4: ECE:3360 Embedded Systems
; Authors: 
; 	- Matt Krueger
; 	- Sage Marks
; 
; Project Statement:
; 	This AVR program controls a cooling fan monitor, utilizing a PWM controlled fan,
;	LCD display, Active-Low Pushbutton, and Rotary Pulse Generator.
;
; This program is interrupt driven, and uses the following interrupts:
; 	- INT0        to detect RPG usage
; 	- PCINT[1..0] to detect RPG usage
;
; Extra Credit achieved by using Tachometer to monitor the RPM of the fan.
.include "m328pdef.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                           Register Aliases                                                ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.def count = r22								
.def tmp1 = r23								
.def tmp2 = r24							
.def rpg_prev_a = r21
.def rpg_prev_b = r20
.def dc_ocr0b = r16		
.def fan_state = r19	
.def previous_duty_cycle = r18

.cseg
.org 0x0000
rjmp RESET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                          Interrupt Vectors                                                ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org 0x0002
rjmp toggle_fan

.org 0x0006  
rjmp rpg_a_isr

.org 0x0008
rjmp rpg_b_isr

.org 0x0034 ; end of interrupt vector table

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                           Lookup Tables                                                   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
duty_cycle_prefix:
	.db "DC = ", 0x00 

duty_cycle_suffix:
	.db "%", 0x00 

status_prefix:
	.db "Fan: ", 0x00

status_suffix_on:
	.db "ON", 0x00

status_suffix_off:
	.db "OFF", 0x00

status_suffix_gt_ok:
	.db "RPM OK", 0x00

status_suffix_lt_stopped:
	.db "Stopped", 0x00

status_suffx_lt_low:
	.db "low RPM", 0x00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                      Component Configuration                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
configure_ports:
	; outputs
	sbi DDRB, 5				; R/S on LCD (Instruction/register selection) (arduino pin 13)
	sbi DDRB, 2				; E on LCD (arduino pin ~10)
	sbi DDRC, 0				; D4 on LCD (arduino pin A0)
	sbi DDRC, 1				; D5 on LCD (arduino pin A1)
	sbi DDRC, 2				; D6 on LCD (arduino pin A2)
	sbi DDRC, 3				; D7 on LCD (arduino pin A3) 
	sbi DDRD, 3				; PWM fan signal (arduino pin ~3)
	; inputs
	cbi DDRD, 2				; Pushbutton signal (arduino pin 7) 
	cbi DDRD, 4				; A signal from RPG (arduino pin 4)
	cbi DDRD, 5				; B signal from RPG (arduino pin ~5)
	ret

configure_timer0:
	ldi count, 0x38			; count of 56
	ldi tmp1, (1<<CS01)		; prescaler of /8 -> 16MHz/8 = 2MHz per tick
	out TCNT0, count
	out TCCR0B, tmp1
	ret

configure_pushbutton_interrupt:
	ldi r16, (1 << ISC1) | (1 << ISC0)		
	sts EICRA, r16
	ldi r17, (1 << INT0)			
	sts EIMSK, r17
	ret 

configure_rpg_interrupt:
	ldi r16, (1 << PCIE0)
	sts PCICR, r16
	ldi r16, (1 << PCINT1) | (1 << PCINT0)
	sts PCMSK0, r16
	ret

configure_lcd:
	rcall delay_100ms
	cbi PORTB, 5			; set R/S to low (data transferred is treated as commands)
	rcall set_8_bit_mode
	rcall LCDStrobe
	rcall delay_10ms
	rcall set_8_bit_mode
	rcall LCDStrobe
	rcall delay_1ms
	rcall set_8_bit_mode
	rcall LCDStrobe
	rcall delay_1ms
	set_4_bit_mode:
		ldi r17, 0x02		; sets to 4-bit mode
		out PORTC, r17
		rcall LCDStrobe
	rcall delay_10ms
	set_interface:
		ldi r17, 0x02
		out PORTC, r17
		rcall LCDStrobe
		rcall delay_100us
		ldi r17, 0x08
		out PORTC, r17
		rcall LCDStrobe
		rcall delay_1ms
	enable_display_cursor:
		ldi r17, 0x00
		out PORTC, r17
		rcall LCDStrobe
		rcall delay_100us
		ldi r17, 0x08
		out PORTC, r17
		rcall LCDStrobe
		rcall delay_10ms
	clear_home:
		ldi r17, 0x00
		out PORTC, r17
		rcall LCDStrobe
		rcall delay_100us
		ldi r17, 0x01
		out PORTC, r17
		rcall LCDStrobe
		rcall delay_10ms
	set_cursor_move_direction:
		ldi r17, 0x00
		out PORTC, r17
		rcall LCDStrobe
		rcall delay_100us
		ldi r17, 0x06
		out PORTC, r17
		rcall LCDStrobe
		rcall delay_1ms
	turn_on_display:
		ldi r17, 0x00
		out PORTC, r17
		rcall LCDStrobe
		rcall delay_100us
		ldi r17, 0x0
		out PORTC, r17
		rcall LCDStrobe
		rcall delay_1ms
		ret

configure_rpg:
	ldi r18, 0
	mov rpg_prev_a, r18
	mov rpg_prev_b, r18
	ret

configure_pwm:
	; TODO rewrite

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                            MAIN CODE                                                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESET:
	rcall configure_ports
	rcall configure_timer0
	rcall configure_pushbutton_interrupt   ; Interrupt [TODO]
	rcall configure_rpg_interrupt          ; Interrupt [TODO]
	rcall configure_lcd
	rcall configure_rpg
	rcall configure_pwm
	sei

program_loop:
	rjmp program_loop;

toggle_fan:
	; TODO: rewrite

; RPG ISRs 
rpg_a_isr:
	detect_current_a:
		in r16, PINB
		andi r16, (1 << PB1)       	
		ldi r17, 1					
		sbrs r16, PB1 
		ldi r17, 0
	mov rpg_prev_a, r17
	cpse r17, rpg_prev_b
	rjmp rpg_cw							; current a != prev b --> CW
	rjmp rpg_ccw						; current a == prev b --> CCW
rpg_b_isr:
	detect_current_b:
		in r16, PINB
		andi r16, (1 << PB0)
		ldi r17, 1					
		sbrs r16, PB0 
		ldi r17, 0
	mov rpg_prev_b, r17
	cpse r17, rpg_prev_a
	rjmp rpg_cw							; current b != prev a --> CWW
	rjmp rpg_ccw						; current b == prev a --> CW
rpg_cw:
	cpi dc_ocr0b, 79
	breq at_ceiling
	inc dc_ocr0b
	at_ceiling:
	reti
rpg_ccw:
	cpi dc_ocr0b, 0
	breq at_floor
	dec dc_ocr0b
	at_floor:
	reti

displayCString:
	lpm r0, Z+ 				; auto post increment Z, to read next char 
	tst r0 					; check for terminating char 0x00
	breq done 			
	swap r0 				; swap upper nibble
	out PORTC, r0 			; send upper nibble to LCD
	rcall LCDStrobe 
	swap r0 				; now, lower nibble
	out PORTC, r0 			; send lower nibble to LCD
	rcall LCDStrobe 	
	rjmp displayCString		; continue for entire string
done:
	ret

set_8_bit_mode:
	ldi r17, 0x03
	out PORTC, r17
	ret

LCDStrobe:
	sbi PORTB, 2					; set E to high (initiate data transfer). 
	ldi r27, 0x00					; load X reg
	ldi r26, 0x05					; (000 0101) loads 5 to run 100us 5 times
	Strobe_loop:
		rcall delay_100us
		sbiw r27:r26, 1
		brne Strobe_loop
		cbi PORTB, 2				; set E to low (end of data transfer)
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                        Timers and Delays                                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delay_100ms:
	ldi r27, 0x03
	ldi r26, 0xE8
	loop_100ms
		rcall delay_100us
		sbiw r27:r26, 1
		brne loop_100ms
		ret

delay_10ms:
	ldi r27, 0x00
	ldi r26, 0x64
	loop_10ms:
		rcall delay_100us
		sbiw r27:r26, 1
		brne loop_10ms
		ret

delay_1ms:
	ldi r27, 0x00
	ldi r26, 0x0a
	loop_1ms:
		rcall delay_100us
		sbiw r27:r26, 1
		brne loop_1ms
		ret

delay_100us:
	in tmp1, TCCR0B 
	ldi tmp2, 0x00
	out TCCR0B, tmp2
	in tmp2, TIFR0
	sbr tmp2, 1<<TOV0
	out TIFR0, tmp2
	out TCNT0, count
	out TCCR0B, tmp1
	wait_for_overflow
		in tmp2, TIFR0
		sbrs tmp2, TOV0
		rjmp wait_for_overflow
		ret