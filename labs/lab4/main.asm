;Lab 4 Matt Krueger and Sage Marks

;outputs
sbi DDRB, 5; R/S on LCD (Instruction/register selection)
sbi DDRB, 2; E on LCD 
sbi DDRC, 0; D4 on LCD
sbi DDRC, 1; D5 on LCD
sbi DDRC, 2; D6 on LCD
sbi DDRC, 3; D7 on LCD
sbi DDRD, 3; PWM fan signal

;inputs
cbi DDRD, 7; Pushbutton signal
cbi DDRD, 4; A signal from RPG
cbi DDRD, 5; B signal from RPG

.def count = r22
.def tmp1 = r23
.def tmp2 = r24

.def rpg_current_state = r21;
.def rpg_previous_state = r20;

rjmp setup;
msg1:
	.db "DC = --% ", 0x00

setup:

setup_timer:
	ldi count, 0x38;
	ldi tmp1, (1<<CS01); prescalar of /8
	out TCNT0, count;
	out TCCR0B, tmp1;

initialize_LCD:
	rcall timer_delay_100ms;
	cbi PORTB, 5;
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

;Main program displaying stuff
setup_rpg:
	in rpg_previous_state, PIND;
	andi rpg_previous_state, 0x30;

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
	ldi r16, 25
	sts OCR2B, r16  ; OCR0B controls duty cycle!

sbi PORTB, 5;
Duty_Cycle_Display:
	ldi r30,LOW(2*msg1) ; Load Z register low
	ldi r31,HIGH(2*msg1) ; Load Z register high
	rcall displayCString;

;ACTUAL PROGRAM HERE
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
		cpi r16, 79;
		breq save_rpg_state
		inc r16
		rjmp save_rpg_state
	counter_clockwise:
		cpi r16, 0;
		breq save_rpg_state
		dec r16
	save_rpg_state:
		mov rpg_previous_state, rpg_current_state;
	no_change:
		ret

update_pwm:
	sts OCR2B, r16;
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
	rjmp displayCstring
done:
	ret

set_8_bit_mode:
	ldi r17, 0x03;
	out PORTC, r17;
	ret;

LCDStrobe:
	sbi PORTB, 2;
	ldi r27, 0x00;
	ldi r26, 0x05;
	Strobe_loop:
		rcall timer_delay_100us;
		sbiw r27:r26, 1
		brne Strobe_loop;
		cbi PORTB, 2;
		ret
	

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