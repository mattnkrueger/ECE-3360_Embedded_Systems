;Lab 4 Matt Krueger and Sage Marks

.def count = r22; counter for timer
.def tmp1 = r23; temporary register used to store TCCR0B
.def tmp2 = r24; temporary register used to store TIFR0
.def rpg_current_state = r21;
.def rpg_previous_state = r20;
.def dc_ocr2b = r16;
.def fan_state = r13
.def prev_dc = r12

.include "m328pdef.inc"

; jump to main code
.cseg
.org 0x0000

; interrupt vector for INT0
.org 0x0002
rjmp int0_interrupt

; interrupt vector for Timer2 Overflow
.org 0x0012
rjmp timer2_overflow_interrupt

rjmp reset;
prefix_string:
	.db "DC = ", 0x00 

suffix_string:
	.db "%", 0x00 

.org 0x0034 ; end of interrupt vector table
setup_interrupts:
	lds r16, EICRA; load EICRA into r16 (r15 is not a valid register for most operations)
	sbr r16, (1<<ISC01); set ISC01 to 1 to trigger on falling edge (this is for the pushbutton active low)
	sts EICRA, r16; writeback to EICRA
	sbi EIMSK, INT0; enable INT0 interrupt in EIMSK
	ret;

int0_interrupt:
	mov prev_dc, dc_ocr2b; store the previous duty cycle
	eor fan_state, 0xff; toggle fan off on
	cpi fan_state, 0xff
	breq turn_fan_on
	turn_fan_off:
		ldi dc_ocr2b, 0 ; set duty cycle to 0%
		reti;
	turn_fan_on:
		mov dc_ocr2b, prev_dc; restore the previous duty cycle
		reti;

timer2_overflow_interrupt:
	; first, load the prefix string into Z register
	ldi r30,LOW(2*prefix_string) 
	ldi r31,HIGH(2*prefix_string)
	rcall displayCString;

	; second, get the current duty cycle

	; third, load the suffix string into Z register
	ldi r30,LOW(2*suffix_string)
	ldi r31,HIGH(2*suffix_string)
	rcall displayCString;

	rcall setup_pwm; reset the timer for next interrupt
	reti

configure_ports:
	;outputs
	sbi DDRB, 5; R/S on LCD (Instruction/register selection) (arduino pin 13)
	sbi DDRB, 2; E on LCD (arduino pin ~10)
	sbi DDRC, 0; D4 on LCD (arduino pin A0)
	sbi DDRC, 1; D5 on LCD (arduino pin A1)
	sbi DDRC, 2; D6 on LCD (arduino pin A2)
	sbi DDRC, 3; D7 on LCD (arduino pin A3) 
	sbi DDRD, 3; PWM fan signal (arduino pin ~3)
	sbi DDRD, 1; TESTING FOR Interrupts (arduino pin 1)
	
	;inputs
	cbi DDRD, 2; Pushbutton signal (arduino pin 7) INTERRUPT INT0
	cbi DDRD, 4; A signal from RPG (arduino pin 4)
	cbi DDRD, 5; B signal from RPG (arduino pin ~5)

setup_timer:
	ldi count, 0x38;
	ldi tmp1, (1<<CS01) ; prescaler of /8 -> 16MHz/8 = 2MHz per tick
	out TCNT0, count; load the timer counter register with preset value (0x38 0011 1000 -> 56 decimal)
	out TCCR0B, tmp1; load the timer control register with the preset value (0x01 0000 001 -> 1 decimal) this ends timer configuration for timer0

initialize_LCD:
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

setup_rpg:
	in rpg_previous_state, PIND;
	andi rpg_previous_state, 0x30; mask (0011 0000) to get pins 5 (A) and 4 (B)

setup_pwm:
	; Fast PWM, non-inverting (COM0B1=1), TOP=OCR0A (Mode 7)
	ldi r16, (1 << COM2B1)| (1 << WGM21) | (1 << WGM20)
	sts TCCR2A, r16

	; Prescaler=8 (CS01=1), Fast PWM with TOP=OCR0A (WGM02=1)
	ldi r16, (1 << WGM22) | (1 << CS21)
	sts TCCR2B, r16

	; Set TOP for 25kHz (OCR0A = 79)
	ldi r16, 79
	sts OCR2A, r16

	; Set duty cycle (e.g., 50% = 40)
	;initial duty cycle is 0%
	ldi dc_ocr2b, 25 ; NOTE - alias for OCR2B r16 -> dc_ocr2b
	sts OCR2B, dc_ocr2b  ; OCR2B controls duty cycle!

	;initial fan state is on
	ldi fan_state, 0xff

reset:
	rcall configure_ports
	rcall setup_interrupts
	rcall initialize_LCD
	rcall setup_timer
	rcall setup_rpg
	rcall setup_pwm
	sei

program_loop:
	rcall rpg_check;
	rcall update_pwm;
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
		cpi dc_ocr2b, 79; ; 79 is the max duty cycle
		breq save_rpg_state
		inc dc_ocr2b
		rjmp save_rpg_state
	counter_clockwise:
		cpi dc_ocr2b, 0; 0 is the min duty cycle (0% duty cycle i.e. off)
		breq save_rpg_state
		dec dc_ocr2b
	save_rpg_state:
		mov rpg_previous_state, rpg_current_state;
	no_change:
		ret

update_pwm:
	sts OCR2B, dc_ocr2b;
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
	in tmp1, TCCR0B;
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