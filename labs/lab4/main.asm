;Lab 4 Matt Krueger and Sage Marks

;outputs
sbi DDRB, 5; R/S on LCD (Instruction/register selection)
sbi DDRB, 3; E on LCD 
sbi DDRC, 0; D4 on LCD
sbi DDRC, 1; D5 on LCD
sbi DDRC, 2; D6 on LCD
sbi DDRC, 3; D7 on LCD

;inputs
cbi DDRD, 7; Pushbutton signal
cbi DDRD, 6; A signal from RPG
cbi DDRD, 5; B signal from RPG

.def count = r22
.def tmp1 = r23
.def tmp2 = r24

setup_timer:
	ldi count, 0x38;
	ldi tmp1, (1<<CS01); prescalar of /8
	out TCNT0, count;
	out TCCR0B, tmp1;

initialize_LCD:
	rcall timer_delay_100ms;
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


; Send the character 'E' to the LCD. The ASCII
; character 'E' is 0x45
sbi PORTB, 5
ldi r25,'g'
swap r25 ; Swap nibbles
out PORTC,r25 ; Send upper nibble
rcall LCDStrobe ; Strobe Enable line
rcall timer_delay_100us ; Wait
swap r25 ; Get lower nibble ready
out PORTC,r25 ; Send lower nibble
rcall LCDStrobe ; Strobe Enable line
rcall timer_delay_100us;

loop:
	nop;
	rjmp loop;

set_8_bit_mode:
	ldi r17, 0x03;
	out PORTC, r17;
	ret;

LCDStrobe:
	sbi PORTB, 3;
	ldi r27, 0x00;
	ldi r26, 0x05;
	Strobe_loop:
		rcall timer_delay_100us;
		sbiw r27:r26, 1
		brne Strobe_loop;
		cbi PORTB, 3;
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