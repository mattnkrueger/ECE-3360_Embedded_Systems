
;Lab 4 Matt Krueger and Sage Marks

.def dc_high = r29
.def dc_low = r28
.def tmp2 = r24; temporary register used to store TIFR0
.def tmp1 = r23; temporary register used to store TCCR0B
.def count = r22; counter for timer
.def rpg_current_state = r21;
.def rpg_previous_state = r20;
.def fan_state = r19
.def prev_dc_q = r18
.def current_dc_q = r16;
.def rpg_threshold = r4
.def rpg_accumulator = r5

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

fan_string:
	.db "Fan: ", 0x00

on_string:
	.db "ON ", 0x00

off_string:
	.db "OFF", 0x00

space_string:
	.db " ", 0x00

.org 0x0034 ; end of interrupt vector table
;-----------------------------------------------------------------------------------------------
;Initialization
;-----------------------------------------------------------------------------------------------
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

	sbi DDRD, 5; Output for LED (debugging)
	
	;inputs
	cbi DDRD, 2; Pushbutton signal (arduino pin 7) INTERRUPT INT0
	cbi DDRB, 1; A signal from RPG (arduino pin 9) PCINT1
	cbi DDRB, 0; B signal from RPG (arduino pin 8) PCINT0

setup_PBS_interrupt:
	lds r16, EICRA; load EICRA into r16 
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

Dc_:_display:
	;diplays DC :
	sbi PORTB, 5;
	ldi r30,LOW(2*prefix_string) ; Load Z register low
	ldi r31,HIGH(2*prefix_string) ; Load Z register high
	rcall displayCString;


;move the cursor to the second line and write the state of the fan (ON or OFF)
;This is for writing the FAN:
;Handle changing On and Off in subroutine
Cursor_2nd_Row:
	cbi PORTB, 5
	ldi r17, 0x0C
	out PORTC, r17
	rcall LCDStrobe;
	rcall timer_delay_100us
	ldi r17, 0x00
	out PORTC, r17;
	rcall LCDStrobe;
	rcall timer_delay_1ms;
	sbi PORTB, 5;
Initial_Fan_On_Dispaly:
	ldi r30,LOW(2*fan_string) ; Load Z register low
	ldi r31,HIGH(2*fan_string) ; Load Z register high
	rcall displayCString;
	rcall timer_delay_1ms;
	rcall fan_on;

setup_rpg:
	in rpg_previous_state, PINB;
	andi rpg_previous_state, 0x03; mask (0000 0011) to get pins 5 (A) and 4 (B)

	clr rpg_accumulator
	ldi r16, 3
	mov rpg_threshold, r16
	clr r16

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
	ldi current_dc_q, 195 ; NOTE - alias for OCR2B r16 -> current_dc_q
	sts OCR2B, current_dc_q  ; OCR2B controls duty cycle!

	;initial fan state is on
	mov prev_dc_q, current_dc_q;
	ldi fan_state, 0xff

initial_state:
	sbi PORTD, 5; turn off LED initially
	cbi PORTD, 2; disable internal pullup resistor
	sei

	rcall pwm_cursor
	rcall pwm_to_percent
	rcall pwm_display

program_loop:
	nop;
	nop
	rjmp program_loop;

;-----------------------------------------------------------------------------------------------
;Interrupt Service Routines
;-----------------------------------------------------------------------------------------------

toggle_fan:
	push r17					 ;Keep SREG the same before and after ISR
    in r17, SREG
    push r17

	;debouncing
	rcall timer_delay_100ms		;delay for pushbutton signal 
	ldi r20, (1<< INTF0)
	out EIFR, r20
	sbic PIND,2					;ensure that the button was pressed and is low
	rjmp exit_toggle

	toggle_code:
	lds r17, OCR2B               ; Get current PWM value
	tst fan_state				 ; If fan state is 0 (off)
	brne turn_off                ; If currently ON (0xFF), turn OFF (0x00)
	turn_on:
		sbi PORTD, 5			 ; Turn LED OFF
		ldi fan_state, 0xFF      ; Set state to ON
		mov r17, prev_dc_q         ; Restore saved duty cycle
		in rpg_previous_state, PINB
		andi rpg_previous_state, 0x03
		rjmp update_pwm
	turn_off:
		cbi PORTD, 5			 ; Turn LED on	
		clr fan_state            ; Set state to OFF
		mov prev_dc_q, r17         ; Save current duty cycle
		ldi r17, 0               ; Set duty to 0
	update_pwm:
		sts OCR2B, r17           ; Update PWM register with the stored value
	update_fan_display:
		tst fan_state
		brne display_on
		rcall On_Off_Cursor_2nd_Row;
		rcall fan_off;
		rjmp exit_toggle;
		display_on:
		rcall On_Off_Cursor_2nd_Row;
		rcall fan_on
	exit_toggle:
		pop r17
		out SREG, r17
		pop r17
		reti


rpg_change:
    push r16
    in r16, SREG
    push r16
    push r17
    push r30
    
    rcall timer_delay_100us
    tst fan_state
    breq exit_rpg_isr           ; IF the state is off do not update RPG
    
    
    ; Read current state of RPG pins (A and B)
    in r17, PINB
    andi r17, 0x03              ; Mask to get just the two RPG pins
    
    ; Combine previous and current states for direction detection
    mov r16, rpg_previous_state
    lsl r16
    lsl r16
    or r16, r17                 ; r16 now contains [prev1 prev0 curr1 curr0]
    
    ; Update previous state for next time
    mov rpg_previous_state, r17
    
    ; Check for counter clockwise rotation
    cpi r16, 0b0001
    breq counter_clockwise
    cpi r16, 0b0111
    breq counter_clockwise
    cpi r16, 0b1000
    breq counter_clockwise
    cpi r16, 0b1110
    breq counter_clockwise
    
    ; Check for clockwise rotation
    cpi r16, 0b0010
    breq clockwise
    cpi r16, 0b0100
    breq clockwise
    cpi r16, 0b1011
    breq clockwise
    cpi r16, 0b1101
    breq clockwise
    
    ; If we're here, it's not a valid rotation pattern or it's a half step
    rjmp exit_rpg_isr
    
clockwise:
    inc rpg_accumulator          ; Increment the accumulator
    mov r30, rpg_accumulator     ; Use r30 as temporary register
    cp r30, rpg_threshold       ; Compare with threshold
    brne exit_rpg_isr        ; If not reached threshold, skip OCR2B update
    
    clr rpg_accumulator          ; Reset accumulator
    lds r30, OCR2B              ; Get current duty cycle
    cpi r30, 198                ; Check if at max (199)
    breq full_speed_call        ; If at max, don't increment
	cpi r30, 199
	breq exit_rpg_isr
    inc r30                     ; Increase duty cycle
    sts OCR2B, r30              ; Update PWM register
    rjmp exit_rpg_update
    
counter_clockwise:
    inc rpg_accumulator          ; Increment the accumulator
    mov r30, rpg_accumulator     ; Use r30 as temporary register
    cp r30, rpg_threshold       ; Compare with threshold
    brne exit_rpg_isr			; If not reached threshold, skip OCR2B update
    
    clr rpg_accumulator          ; Reset accumulator
    lds r30, OCR2B              ; Get current duty cycle
    cpi r30, 2                  ; Check if at min (2 or 1%)
    breq exit_rpg_isr			; If at min, don't decrement
    dec r30                     ; Decrease duty cycle
    sts OCR2B, r30              ; Update PWM register
	rjmp exit_rpg_update

exit_rpg_update:
    rcall PWM_cursor
    rcall pwm_to_percent
    rcall pwm_display
    rjmp exit_rpg_isr

full_speed_call:
	rcall pwm_full_speed

exit_rpg_isr:
    pop r30
    pop r17
    pop r16
    out SREG, r16
    pop r16
    reti

;-----------------------------------------------------------------------------------------
;SUBROUTINES
;-----------------------------------------------------------------------------------------

;------------------------------------------------------------------
;pwm percentage display
;------------------------------------------------------------------

;pwm to percentage 0-999
pwm_to_percent:
	push r1
	push r14
	push r15
	push r16
	push r17
	push r18
	push r19
	push r20
	push r21
	push r22
	lds r16, low(OCR2B)		; multiplicand low byte
	lds r17, high(OCR2B)	; multiplicand high byte
	ldi r18, low(100)	; multiplier low byte
	ldi r19, high(100)	; multiplier high byte
	rcall mpy16u		; get OCR0B x 100
	ldi r18, low(199)	;divisor low byte (divide by OCR2A)
	ldi r19, high(199)	;divisor high byte (divide by OCR2A)
	rcall div16u		;result in r17:r16
						;remainder in r15:r14

	mov r16, r14		;multiply remainder by 10 and divide again
	mov r17, r15
	ldi r18, low(10)
	ldi r19, high(10)
	rcall mpy16u
		
	;save the value to R29:R28
	mov r29, r17
	mov r28, r16

	ldi r18, low(199)	;divisor low byte (divide by OCR2A)
	ldi r19, high(199)	;divisor high byte (divide by OCR2A)
	rcall div16u		;result in r17:r16 (third digit is here)
	add r28, r16
	adc r29, r1

	pop r22
	pop r21
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	pop r15
	pop r14
	pop r1
	ret

;Code that displays the pwm percentage
pwm_display:
	push r0
	push r1
	push r2
	push r14
	push r15
	push r16
	push r17
	push r18
	push r19
	push r20
	
	mov r16, dc_low
	mov r17, dc_high
	ldi r18, low(10)
	ldi r19, high(10)
	rcall div16u			;result in r17:r16
							;remainder in r15:r14
	mov r0, r14
	rcall div16u
	mov r1, r14
	rcall div16u
	mov r2, r14

	rcall display_char1
	rcall display_char2
	rcall display_decimal
	rcall display_char3

	
	ldi r30,LOW(2*suffix_string) ; Load Z register low
	ldi r31,HIGH(2*suffix_string) ; Load Z register high
	rcall displayCString;

	ldi r30,LOW(2*space_string) ; Load Z register low
	ldi r31,HIGH(2*space_string) ; Load Z register high
	rcall displayCString;

	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	pop r15
	pop r14
	pop r2
	pop r1
	pop r0
	ret

;DIVISION CODE TAKEN FROM ATMEL AVR200.ASM
div16u:	
	clr	r14	;clear remainder Low byte
	sub	r15, r15;clear remainder High byte and carry
	ldi	r20, 17	;init loop counter
	d16u_1:	
		rol	r16		;shift left dividend
		rol	r17
		dec	r20		;decrement counter
		brne	d16u_2		;if done
		ret			;    return
	d16u_2:	
		rol	r14	;shift dividend into remainder
		rol	r15
		sub	r14, r18	;remainder = remainder - divisor
		sbc	r15, r19	;
		brcc	d16u_3		;if result negative
		add	r14, r18	;    restore remainder
		adc	r15, r19
		clc			;    clear carry to be shifted into result
		rjmp	d16u_1		;else
	d16u_3:	
		sec			;    set carry to be shifted into result
		rjmp	d16u_1


;Multiplication for getting value of 0-999, taken from ATMEL AVR200.asm CODE
mpy16u:	
	clr	r21		;clear 2 highest bytes of result
	clr	r20
	ldi	r22,16	;init loop counter
	lsr	r19
	ror	r18
	m16u_1:	
		brcc	noad8		;if bit 0 of multiplier set
		add	r20,r16	;add multiplicand Low to byte 2 of res
		adc	r21,r17	;add multiplicand high to byte 3 of res
	noad8:	
		ror	r21		;shift right result byte 3
		ror	r20		;rotate right result byte 2
		ror	r19		;rotate result byte 1 and multiplier High
		ror	r18		;rotate result byte 0 and multiplier Low
		dec	r22		;decrement loop counter
		brne	m16u_1		;if not done, loop more
		mov r16, r18
		mov r17, r19
		ret

PWM_cursor:
	cbi PORTB, 5
	ldi r17, 0x08 
	out PORTC, r17
	rcall LCDStrobe;
	rcall timer_delay_100us
	ldi r17, 0x05
	out PORTC, r17;
	rcall LCDStrobe;
	rcall timer_delay_1ms;
	sbi PORTB, 5;
	ret

pwm_full_speed:
	inc r30
	sts OCR2B, r30    ; Set OCR2B = OCR2A
	rcall pwm_cursor
	ldi r16, 1
	mov r2, r16
	rcall display_char1
	ldi r16, 0
	mov r2, r16
	rcall display_char1
	rcall display_char1
	rcall display_decimal
	rcall display_char1
								 ;% sign
	ldi r30,LOW(2*suffix_string) ; Load Z register low
	ldi r31,HIGH(2*suffix_string) ; Load Z register high
	rcall displayCString;
	exit_full_speed:
		ldi r16, 2
		mov rpg_accumulator, r16
		ret
;------------------------------------------------------------------
;FAN ON AND OFF STUFF (display)
;-------------------------------------------------------------------
;turns on the cursor for the 2nd row
On_Off_Cursor_2nd_Row:
	cbi PORTB, 5
	ldi r17, 0x0C 
	out PORTC, r17
	rcall LCDStrobe;
	rcall timer_delay_100us
	ldi r17, 0x05
	out PORTC, r17;
	rcall LCDStrobe;
	rcall timer_delay_1ms;
	sbi PORTB, 5;
	ret
fan_on:
	ldi r30,LOW(2*on_string) ; Load Z register low
	ldi r31,HIGH(2*on_string) ; Load Z register high
	rcall displayCString;
	ret;

fan_off:
	ldi r30,LOW(2*off_string) ; Load Z register low
	ldi r31,HIGH(2*off_string) ; Load Z register high
	rcall displayCString;
	ret;

;--------------------------------------------------------------
;Displaying strings, characters, and decimal points
;--------------------------------------------------------------
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

display_char1:
	push r16
	ldi r25, 0x30
	add r25, r2
	mov r16, r25
	andi r25, 0xf0
	swap r25
	out PORTC, r25 ; Send upper nibble
	rcall LCDStrobe ; Strobe Enable line
	rcall timer_delay_100us ; wait
	andi r16, 0x0f
	out PORTC, r16 ; Send lower nibble
	rcall LCDStrobe ; Strobe Enable line
	rcall timer_delay_100us
	pop r16
	ret

display_char2:
	push r16
	ldi r25, 0x30
	add r25, r1
	mov r16, r25
	andi r25, 0xf0
	swap r25
	out PORTC, r25 ; Send upper nibble
	rcall LCDStrobe ; Strobe Enable line
	rcall timer_delay_100us ; wait
	andi r16, 0x0f
	out PORTC, r16 ; Send lower nibble
	rcall LCDStrobe ; Strobe Enable line
	rcall timer_delay_100us
	pop r16
	ret

display_char3:
	push r16
	ldi r25, 0x30
	add r25, r0
	mov r16, r25
	andi r25, 0xf0
	swap r25
	out PORTC, r25 ; Send upper nibble
	rcall LCDStrobe ; Strobe Enable line
	rcall timer_delay_100us ; wait
	andi r16, 0x0f
	out PORTC, r16 ; Send lower nibble
	rcall LCDStrobe ; Strobe Enable line
	rcall timer_delay_100us
	pop r16
	ret

display_decimal:
	ldi r25, 0x02
	out PORTC,r25 ; Send upper nibble
	rcall LCDStrobe ; Strobe Enable line
	rcall timer_delay_100us ; wait
	ldi r25,0x0e
	out PORTC,r25 ; Send lower nibble
	rcall LCDStrobe ; Strobe Enable line
	rcall timer_delay_100us
	ret

;----------------------------------------------------------------------
;LCD initialization and Strobe
;----------------------------------------------------------------------
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

;----------------------------------------------------------------------
;delays
;-------------------------------------------------------------------------
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