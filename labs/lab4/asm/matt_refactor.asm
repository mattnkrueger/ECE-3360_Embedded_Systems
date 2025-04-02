; Lab 4: ECE:3360 Embedded Systems
; Authors: 
; 	- Matt Krueger
; 	- Sage Marks
; 
; Project Statement:
; 	- This AVR program controls a cooling fan monitor, utilizing a PWM controlled fan, LCD display, Active-Low Pushbutton, and Rotary Pulse Generator.
;
; This program is interrupt driven, and uses the following interrupts:
; - [TODO] signal via Pushbutton -> toggle_fan
; - [TODO] signal via RPG -> rpg_check
; - [TODO] signal via RPG -> rpg_check
; See `configure_interrupts` for details.
;
; Extra Credit achieved by using Tachometer to monitor the RPM of the fan.
.include "m328pdef.inc"

; REGISTER ALIASES
;
; This section defines registers frequently used inside of the program
.def count = r22								; counter for timer
.def tmp1 = r23									; temporary register used to store TCCR0B
.def tmp2 = r24									; temporary register used to store TIFR0
.def rpg_current_state = r21					; current state (gray code) used for RPG logic
.def rpg_previous_state = r20					; previous state (gray code) used for RPG logic
.def dc_ocr0b = r16								; pwm duty cycle control
.def fan_state = r19							; current fan state used in toggling of PWM fan
.def previous_duty_cycle = r18					; previous duty cycle to return to after toggling the fan

.cseg
.org 0x0000
rjmp RESET

; INTERRUPT VECTORS
; 
; This section maps interrupt vectors to respective Interrupt Service Routines
; - External Interrupt request 0 (INT0): 
; 				pushbutton falling edge -> toggle_fan
; - Pin Change Interrupt request 0 (PCINT0):
; 				RPG B logic change -> rpg_change
; - Pin Change Interrupt request 1 (PCINT1):
; 				RPG B logic change -> rpg_change
.org 0x0002
rjmp toggle_fan

.org 0x0006  
rjmp rpg_change

.org 0x0008
rjmp rpg_change

.org 0x0034 ; end of interrupt vector table

; LOOKUP TABLE
;
; This section is used to store string pattern to be displayed inside of main loop
; - the LCD Displays in the form
;   				row1:	DC = [duty cycle]%
; 					row2:   Fan: [status]
; - this code lives on program memory following the Interrupt Vector Table

; non-extra credit display strings
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

; extra credit display strings
status_suffix_gt_ok:
	.db "RPM OK", 0x00

status_suffix_lt_stopped:
	.db "Stopped", 0x00

status_suffx_lt_low:
	.db "low RPM", 0x00

; SETUP & CONFIGURATION
;
; This section is used to configure the ports, timers, rpg, and interrupts
; - this code is ran upon startup or reset 
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
	; falling edge triggered
	ldi r16, (1 << ISC1) | (1 << ISC0)		
	sts EICRA, r16
	; mask INT0
	ldi r17, (1 << INT0)			
	sts EIMSK, r17
	ret 

configure_rpg_interrupt:
	; enable pin change interrupts for PCINT[1..0]
	ldi r16, (1 << PCIE1) | (PCIE0) 
	sts PCICR, r16
	; mask bits inside of PCMSK0
	ldi r17, (1 << PCINT1) | (1 << PCINT0)
	sts PCMSK0, r17
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
	in rpg_previous_state, PINB
	andi rpg_previous_state, 0x03		; mask (0000 0011) to get pins 9 (A) and 8 (B) of PIND
	ret

configure_pwm:
	; TODO rewrite

; MAIN CODE
;
; This program is interrupt driven.
; - 1st: the components are configured
; - 2nd: the program enters an infinite loop, 
;   	 waiting for interrupts via user interface
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

rpg_check:
	rcall delay_1ms
	lds r16, OCR2B
	in rpg_current_state, PIND
	andi rpg_current_state, 0x30
	cp rpg_current_state, rpg_previous_state
	breq no_change
	cpi rpg_current_state, 0x00
	breq check_state
	rjmp save_rpg_state
	check_state:
		cpi rpg_previous_state, 0x10
		breq clockwise
		cpi rpg_previous_state, 0x20
		breq counter_clockwise
		rjmp save_rpg_state
	clockwise:
		cpi dc_ocr0b, 79				; 79 is the max duty cycle
		breq save_rpg_state
		inc dc_ocr0b
		rjmp save_rpg_state
	counter_clockwise:
		cpi dc_ocr0b, 0					; 0 is the min duty cycle (0% duty cycle i.e. off)
		breq save_rpg_state
		dec dc_ocr0b
	save_rpg_state:
		mov rpg_previous_state, rpg_current_state;
	no_change:
		ret

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

; TIMERS & DELAYS
;
; This section defines the timers utilized in the program. 
; Its critical to time the LCD process correctly, thus we have implemented various timers to avoid confusion.
;
; Please note that PWM uses timer0 in fast pwm non-inverting mode (and not included in this section). 
; See `configure_pwm` for details
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