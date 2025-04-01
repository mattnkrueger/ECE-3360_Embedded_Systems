;Lab 4 Matt Krueger and Sage Marks
; 
; This AVR program controls a cooling fan monitor, utilizing a PWM controlled fan, LCD display, Active-Low Pushbutton, and Rotary Pulse Generator.

.include "m328pdef.inc"

; REGISTER ALIASES
;
; This section defines registers frequently used inside of the program
.def count = r22; counter for timer
.def tmp1 = r23; temporary register used to store TCCR0B
.def tmp2 = r24; temporary register used to store TIFR0
.def rpg_current_state = r21; current state (gray code) used for RPG logic
.def rpg_previous_state = r20; previous state (gray code) used for RPG logic
.def dc_ocr0b = r16; pwm duty cycle control
.def fan_state = r19; current fan state used in toggling of PWM fan
.def previous_duty_cycle = r18; previous duty cycle to return to after toggling the fan

.cseg
.org 0x0000
rjmp RESET

; INTERRUPT VECTORS
; 
; This section maps interrupt vectors to respective Interrupt Service Routines
; - INT0 (0x0002) signal via Pushbutton -> toggle_fan
; - INT1 (0x0004) signal via RPG -> RPG rotation
.org 0x0002
rjmp toggle_fan

; LOOKUP TABLE
;
; This section is used to store string pattern to be displayed inside of main loop
; - the LCD Displays in the form
;   				row1:	DC = [duty cycle]%
; 					row2:   Fan: [status]
; - this code lives on program memory following the Interrupt Vector Table
.org 0x0034 ; end of interrupt vector table
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

; extras for tachometer 5% EC

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
	;outputs
	sbi DDRB, 5; R/S on LCD (Instruction/register selection) (arduino pin 13)
	sbi DDRB, 2; E on LCD (arduino pin ~10)
	sbi DDRC, 0; D4 on LCD (arduino pin A0)
	sbi DDRC, 1; D5 on LCD (arduino pin A1)
	sbi DDRC, 2; D6 on LCD (arduino pin A2)
	sbi DDRC, 3; D7 on LCD (arduino pin A3) 
	sbi DDRD, 3; PWM fan signal (arduino pin ~3)
	
	;inputs
	cbi DDRD, 2; Pushbutton signal (arduino pin 7) INTERRUPT INT0
	cbi DDRD, 4; A signal from RPG (arduino pin 4)
	cbi DDRD, 5; B signal from RPG (arduino pin ~5)
	ret

configure_timer0:
	ldi count, 0x38; count of 56
	ldi tmp1, (1<<CS01); prescaler of /8 -> 16MHz/8 = 2MHz per tick
	out TCNT0, count
	out TCCR0B, tmp1
	ret

; EIMSK - external interrupt mask register - set int1 or int0 enable (or both)
; EIFR  - external interrupt flag register - prompt mcu jump to vector table
configure_int0_interrupt:

; PCICR - pin change interrupt control register - enable which pin change i/os to enable (2,1,0)
; PCIFR - pin change interrupt flag register - prompt mcu jump to vector table
; PCMSK2 - pin change mask register 2 - PCINT[23..16] mask
; PCMSK1 - pin change mask register 1 - PCINT[14..8] mask
; PCMSK0 - pin change mask register 0 - PCINT[7..0] mask
configure_pin_change_d_interrupts

configure_lcd:
	rcall timer_delay_100ms;
	cbi PORTB, 5; set R/S to low (data transferred is treated as commands)
	rcall set_8_bit_mode;
	rcall LCDStrobe;
	rcall timer_delay_10ms;
	rcall set_8_bit_mode;
	rcall LCDStrobe;
	rcall timer_delay_1ms;
	rcall set_8_bit_mode;
	rcall LCDStrobe;
	rcall timer_delay_1ms;
	set_4_bit_mode:
		ldi r17, 0x02; sets to 4-bit mode
		out PORTC, r17;
		rcall LCDStrobe;
	rcall timer_delay_10ms;
	set_interface:
		ldi r17, 0x02;
		out PORTC, r17;
		rcall LCDStrobe;
		rcall timer_delay_100us;
		ldi r17, 0x08;
		out PORTC, r17;
		rcall LCDStrobe;
		rcall timer_delay_1ms
	enable_display_cursor:
		ldi r17, 0x00;
		out PORTC, r17;
		rcall LCDStrobe;
		rcall timer_delay_100us;
		ldi r17, 0x08;
		out PORTC, r17;
		rcall LCDStrobe;
		rcall timer_delay_10ms
	clear_home:
		ldi r17, 0x00;
		out PORTC, r17;
		rcall LCDStrobe;
		rcall timer_delay_100us;
		ldi r17, 0x01;
		out PORTC, r17;
		rcall LCDStrobe;
		rcall timer_delay_10ms;
	set_cursor_move_direction:
		ldi r17, 0x00;
		out PORTC, r17;
		rcall LCDStrobe;
		rcall timer_delay_100us;
		ldi r17, 0x06;
		out PORTC, r17;
		rcall LCDStrobe;
		rcall timer_delay_1ms;
	turn_on_display:
		ldi r17, 0x00;
		out PORTC, r17;
		rcall LCDStrobe;
		rcall timer_delay_100us;
		ldi r17, 0x0C;
		out PORTC, r17;
		rcall LCDStrobe;
		rcall timer_delay_1ms;
		ret

configure_rpg:
	in rpg_previous_state, PIND
	andi rpg_previous_state, 0x30; mask (0011 0000) to get pins 5 (A) and 4 (B)
	ret

configure_pwm:
	ldi r16, (1 << COM0B1) | (1 << WGM21) | (1 << WGM20)
	out TCCR0A, r16
	ldi r16, (1 << WGM02) | (1 << CS21)
	out TCCR0B, r16
	ldi r16, 79
	out OCR0A, r16
	ldi dc_ocr0b, 25 
	out OCR0B, dc_ocr0b
	mov previous_duty_cycle, dc_ocr0b
	ldi fan_state, 0xff
	ret

; MAIN CODE
;
; This program is interrupt driven.
; - 1st: the components are configured
; - 2nd: the program enters an infinite loop, 
;   	 waiting for interrupts via user interface
RESET:
	rcall configure_ports
	rcall configure_timer0
	rcall configure_int0_interrupt
	rcall configure_lcd
	rcall configure_rpg
	rcall configure_pwm
	sei

; Interrupt service routine for INT0 (pushbutton)
toggle_fan:
	push r0 
    in r0, SREG
    push r0
	com fan_state 
    tst fan_state        
    breq turn_fan_off
	turn_fan_on: 
		mov dc_ocr0b, previous_duty_cycle 
		rjmp update_pwm
	turn_fan_off:
		mov previous_duty_cycle, dc_ocr0b 
		ldi dc_ocr0b, 0
    update_pwm:
		sts OCR2B, dc_ocr0b
		pop r0
		out SREG, r0 
		pop r0
		reti

program_loop:
	; rcall rpg_check;
	rjmp program_loop;

rpg_check:
	rcall timer_delay_1ms;
	lds r16, OCR2B;
	in rpg_current_state, PIND;
	andi rpg_current_state, 0x30;
	cp rpg_current_state, rpg_previous_state
	breq no_change
	cpi rpg_current_state, 0x00
	breq check_state
	rjmp save_rpg_state
	check_state:
		cpi rpg_previous_state, 0x10;
		breq clockwise;
		cpi rpg_previous_state, 0x20;
		breq counter_clockwise;
		rjmp save_rpg_state;
	clockwise:
		cpi dc_ocr0b, 79; ; 79 is the max duty cycle
		breq save_rpg_state
		inc dc_ocr0b
		rjmp save_rpg_state
	counter_clockwise:
		cpi dc_ocr0b, 0; 0 is the min duty cycle (0% duty cycle i.e. off)
		breq save_rpg_state
		dec dc_ocr0b
	save_rpg_state:
		mov rpg_previous_state, rpg_current_state;
	no_change:
		ret

displayCString:
	lpm r0,Z+ ; r0 <-- first byte
	tst r0 ; Reached end of message ?
	breq done ; Yes => quit
	swap r0 ; Upper nibble in place
	out PORTC,r0 ; Send upper nibble out
	rcall LCDStrobe ; Latch nibble
	swap r0 ; Lower nibble in place
	out PORTC,r0 ; Send lower nibble out
	rcall LCDStrobe ; Latch nibble
	rjmp displayCString; continue until done
done:
	ret

set_8_bit_mode:
	ldi r17, 0x03;
	out PORTC, r17;
	ret;

LCDStrobe:
	sbi PORTB, 2; set E to high (initiate data transfer). 
	ldi r27, 0x00; load X reg
	ldi r26, 0x05; (000 0101) loads 5 to run 100us 5 times
	Strobe_loop:
		rcall timer_delay_100us;
		sbiw r27:r26, 1; decrement X reg
		brne Strobe_loop;
		cbi PORTB, 2; set E to low (end of data transfer)
		ret

timer_delay_1_s:
	ldi r27, 0xFF;
	ldi r26, 0xFF;
	loop_4_s:
		rcall timer_delay_100us;
		sbiw r27:r26, 1;
		brne loop_4_s;
		ret;

;delays
timer_delay_100ms:
	ldi r27, 0x03;
	ldi r26, 0xE8;
	loop_100ms:
		rcall timer_delay_100us;
		sbiw r27:r26, 1;
		brne loop_100ms;
		ret;

timer_delay_10ms:
	ldi r27, 0x00;
	ldi r26, 0x64;
	loop_10ms:
		rcall timer_delay_100us;
		sbiw r27:r26, 1;
		brne loop_10ms;
		ret;

timer_delay_1ms:
	ldi r27, 0x00;
	ldi r26, 0x0a;
	loop_1ms:
		rcall timer_delay_100us;
		sbiw r27:r26, 1;
		brne loop_1ms;
		ret;

timer_delay_100us:
	in tmp1, TCCR0B 
	ldi tmp2, 0x00;
	out TCCR0B, tmp2;
	in tmp2, TIFR0;
	sbr tmp2, 1<<TOV0;
	out TIFR0, tmp2;
	out TCNT0, count;
	out TCCR0B, tmp1;
	wait_for_overflow:
		in tmp2, TIFR0;
		sbrs tmp2, TOV0;
		rjmp wait_for_overflow;
		ret;