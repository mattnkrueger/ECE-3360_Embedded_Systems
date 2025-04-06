
;Lab 4 Matt Krueger and Sage Marks

.def count = r22; counter for timer
.def tmp1 = r23; temporary register used to store TCCR0B
.def tmp2 = r24; temporary register used to store TIFR0
.def rpg_current_state = r21;
.def rpg_previous_state = r20;
.def dc_ocr2b = r16;
.def fan_state = r19
.def prev_dc = r18

.include "m328pdef.inc"

; jump to main code
.cseg
.org 0x0000
rjmp start;

; interrupt vector for INT0
.org 0x0002
rjmp toggle_fan

.org 0x0006
rjmp rpg_change

prefix_string:
	.db "DC = ", 0x00 

suffix_string:
	.db "%", 0x00 

.org 0x0034 ; end of interrupt vector table
start:
 ldi r16, high(RAMEND)
 out SPH, r16
 ldi r16, low(RAMEND)
 out SPL, r16

configure_ports:
	;outputs
	sbi DDRB, 5; R/S on LCD (Instruction/register selection) (arduino pin 13)
	sbi DDRB, 2; E on LCD (arduino pin ~10)
	sbi DDRC, 0; D4 on LCD (arduino pin A0)
	sbi DDRC, 1; D5 on LCD (arduino pin A1)
	sbi DDRC, 2; D6 on LCD (arduino pin A2)
	sbi DDRC, 3; D7 on LCD (arduino pin A3) 
	sbi DDRD, 3; PWM fan signal (arduino pin ~3)

	sbi DDRD, 5;
	
	;inputs
	cbi DDRD, 2; Pushbutton signal (arduino pin 7) INTERRUPT INT0
	cbi DDRB, 1; A signal from RPG (arduino pin 9) PCINT1
	cbi DDRB, 0; B signal from RPG (arduino pin 8) PCINT0

setup_PBS_interrupt:
	lds r16, EICRA; load EICRA into r16 
	;andi r16, ~((1<<ISC01) | (1<<ISC00))  ; Clear existing bits
	ldi r16, 0b10; set ISC01 to 1 to trigger on falling edge (this is for the pushbutton active low)
	sts EICRA, r16; writeback to EICRA
	ldi r16, 0b01
	out EIMSK, r16; enable INT0 interrupt in EIMSK

setup_RPG_interrupt:;PB0 PCINT0
	lds r16, PCICR;
	sbr r16, (1<<PCIE0);
	sts PCICR, r16
	sbr r16, (1<<PCINT0);
	sts PCMSK0, r16

setup_timer:
	ldi count, 0x38;
	ldi tmp1, (1<<CS01) ; prescaler of /8 -> 16MHz/8 = 2MHz per tick
	out TCNT0, count; load the timer counter register with pstart value (0x38 0011 1000 -> 56 decimal)
	out TCCR0B, tmp1; load the timer control register with the pstart value (0x01 0000 001 -> 1 decimal) this ends timer configuration for timer0

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
	in rpg_previous_state, PINB;
	andi rpg_previous_state, 0x03; mask (0000 0011) to get pins 5 (A) and 4 (B)
	

setup_pwm:
	; Fast PWM, non-inverting (COM0B1=1), TOP=OCR0A (Mode 7)
	ldi r16, (1 << COM2B1)| (1 << WGM21) | (1 << WGM20)
	sts TCCR2A, r16

	; Prescaler=1 (CS20=1), Fast PWM with TOP=OCR0A (WGM02=1)
	ldi r16, (1 << WGM22) | ( 1<< CS20)
	sts TCCR2B, r16

	; Set TOP for 25kHz (OCR0A = 79)
	ldi r16, 199
	sts OCR2A, r16

	; Set duty cycle (e.g., 50% = 40)
	;initial duty cycle is 0%
	ldi dc_ocr2b, 100 ; NOTE - alias for OCR2B r16 -> dc_ocr2b
	sts OCR2B, dc_ocr2b  ; OCR2B controls duty cycle!

	;initial fan state is on
	mov prev_dc, dc_ocr2b;
	ldi fan_state, 0xff

sei
sbi PORTD, 5;
program_loop:
    nop
	nop
	rjmp program_loop;

toggle_fan:
	push r17
    in r17, SREG
    push r17
	lds r17, OCR2B           ; Get current PWM value
	tst fan_state
	brne turn_off            ; If currently ON, turn OFF
	turn_on:
		sbi PORTD, 5;
		ldi fan_state, 0xFF      ; Set state to ON
		mov r17, prev_dc         ; Restore saved duty cycle
		rjmp update_pwm
	turn_off:
		cbi PORTD, 5;
		clr fan_state            ; Set state to OFF
		mov prev_dc, r17         ; Save current duty cycle
		ldi r17, 0               ; Set duty to 0
	update_pwm:
		sts OCR2B, r17           ; Update PWM register
		;mov dc_ocr2b, r17        ; Keep variable in sync
	pop r17
	out SREG, r17
	pop r17
	reti

rpg_change:
    push r16
    in r16, SREG
    push r16
    push r17
    
    ; Read current state of RPG pins (A and B)
    in r17, PINB
    andi r17, 0x03             ; Mask to get just the two RPG pins
    
    ; Combine previous and current states for direction detection
    ; Shift previous state left by 2 and combine with current state
    mov r16, rpg_previous_state
    lsl r16
    lsl r16
    or r16, r17                ; r16 now contains [prev1 prev0 curr1 curr0]
    
    ; Update previous state for next time
    mov rpg_previous_state, r17
    
    ; Check rotation pattern based on combined states
    ; Common patterns for clockwise: 0b0001, 0b0111, 0b1000, 0b1110
    ; Common patterns for counter-clockwise: 0b0010, 0b0100, 0b1011, 0b1101
    
    ; Check for clockwise rotation
    cpi r16, 0b0001
    breq clockwise
    cpi r16, 0b0111
    breq clockwise
    cpi r16, 0b1000
    breq clockwise
    cpi r16, 0b1110
    breq clockwise
    
    ; Check for counter-clockwise rotation
    cpi r16, 0b0010
    breq counter_clockwise
    cpi r16, 0b0100
    breq counter_clockwise
    cpi r16, 0b1011
    breq counter_clockwise
    cpi r16, 0b1101
    breq counter_clockwise
    
    ; If we're here, it's not a valid rotation pattern or it's a half step
    rjmp exit_rpg_isr
    
clockwise:
    lds r16, OCR2B            ; Get current duty cycle
    cpi r16, 199              ; Check if at max
    breq exit_rpg_isr
    inc r16                   ; Increase duty cycle
    sts OCR2B, r16            ; Update PWM register
    rjmp exit_rpg_isr
    
counter_clockwise:
    lds r16, OCR2B            ; Get current duty cycle
    tst r16                   ; Check if at min (0)
    breq exit_rpg_isr
    dec r16                   ; Decrease duty cycle
    sts OCR2B, r16            ; Update PWM register
    
exit_rpg_isr:
    pop r17
    pop r16
    out SREG, r16
    pop r16
    reti

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