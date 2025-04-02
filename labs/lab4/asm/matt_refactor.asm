;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                     Lab 4: ECE:3360 Embedded Systems									  ;
; 																										  ;	
;												 Authors:												  ;
; 	 									 Matt Krueger & Sage Marks								          ;
; 																										  ;
; 											Project Statement:											  ;
; 					This AVR program controls a PWM cooling fan monitor, LCD display,					  ;
; 					active-Low pushbutton, and RPG Encoder to create a monitoring system.		  	      ;
;																								          ;
; 					Extra Credit achieved by using Tachometer to monitor the RPM of the fan.			  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "m328pdef.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                           Register Aliases                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.def tmp2 			= r24						  ; temporary register 
.def tmp1 	    	= r23						  ; temporary register
.def count 	    	= r22						  ; stores counter for timer0
.def rpg_prev_a 	= r21						  ; tracks previous RPG A signal
.def rpg_prev_b	 	= r20						  ; tracks previous RPG B signal
.def fan_state		= r19						  ; boolean flag for fan on/off
.def prev_dc_q 	    = r18						  ; tracks previous duty cycle quotient
.def current_dc_q 	= r16						  ; tracks  current duty cycle quotient

.cseg
.org 0x0000
rjmp reset										  ; jump over interrupts & LUTs

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                          Interrupt Vectors                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org 0x0002
rjmp pushbutton_isr

.org 0x0006  
rjmp rpg_a_isr

.org 0x0008
rjmp rpg_b_isr

.org 0x0034  							 	 	  ; end of interrupt vector 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                           Lookup Tables                                                 ;
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
;                                      Component Configuration                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
configure_outputs:
	sbi DDRB, 5								      ; R/S on LCD (Instruction/register selection) (arduino pin 13)
	sbi DDRB, 2									  ; E on LCD (arduino pin ~10)
	sbi DDRC, 3									  ; D7 on LCD (arduino pin A3) 
	sbi DDRC, 2									  ; D6 on LCD (arduino pin A2)
	sbi DDRC, 1									  ; D5 on LCD (arduino pin A1)
	sbi DDRC, 0									  ; D4 on LCD (arduino pin A0)
	sbi DDRD, 3									  ; PWM fan signal (arduino pin ~3)
	sbi DDRD, 5									  ; LED indicator for fan interrupt (arduino pin ~5)
	ret
	
configure_inputs:
	cbi DDRB, 1									  ; A signal from RPG (arduino pin 4)
	cbi DDRB, 0									  ; B signal from RPG (arduino pin ~5)
	cbi DDRD, 2									  ; Pushbutton signal (arduino pin 7) 
	ret

configure_timer0:
	; timer used for main loop timing
	;
	; TCCR0A 
	;   -------------------------------------------------------------
	;	| COM0A1 | COM0A0 | COM0B1 | COM0B0 | - | - | WGM01 | WGM00 |
	;   -------------------------------------------------------------
	; COM0A1 [0]:
	; COM0A0 [0]: ^
	; COM0B1 [0]:
	; COM0B0 [0]: ^
	; RES    [-]:
	; RES    [-]:
	; WGM01  [0]:
	; WGM00  [0]: ^
	; 
	; TCCR0A
	;   ------------------------------------------------------
	;	| FOC0A | FOC0B | - | - | WGM02 | CS02 | CS01 | CS00 |
	;   ------------------------------------------------------
	; FOC0A  [0]:
	; FOC0B  [0]: ^
	; RES    [-]:
	; RES    [-]:
	; WGM02  [0]:
	; CS02   [0]:
	; CS01   [0]:
	; CS00   [0]:
	ldi count, 0x38
	ldi tmp1, (1 << CS01) 	
	out TCNT0, count
	out TCCR0B, tmp1
	ret

configure_timer2:
	; timer used for pwm on fan
	;
	; TCCR2A
	;   -------------------------------------------------------------
	;	| COM2A1 | COM2A0 | COM2B1 | COM2B0 | - | - | WGM21 | WGM20 |
	;   -------------------------------------------------------------
	; COM2A1 [0]:
	; COM2A0 [0]: ^
	; COM2B1 [0]:
	; COM2B0 [0]: ^
	; RES    [-]:
	; RES    [-]:
	; WGM21  [0]:
	; WGM20  [0]: ^
	; 
	; TCCR2A 
	;   ------------------------------------------------------
	;	| FOC2A | FOC2B | - | - | WGM22 | CS22 | CS21 | CS20 |
	;   ------------------------------------------------------
	; FOC2A  [0]:
	; FOC2B  [0]: ^
	; RES    [-]:
	; RES    [-]:
	; WGM22  [0]:
	; CS22   [0]:
	; CS21   [0]:
	; CS20   [0]:
	ldi r16, (1 << COM2B1) | (1 << WGM21) | (1 << WGM20) 
	sts TCCR2A, r16
	ldi r16, (1 << WGM22) | ( 1<< CS20)
	sts TCCR2B, r16
	ldi r16, 199           ; top - 200
	sts OCR2A, r16
	ldi current_dc_q, 100      ; bottom - 100
	sts OCR2B, current_dc_q    ; initial fan pwm: 50%
	ret

configure_pushbutton_interrupt:
	ldi r16, (1 << ISC01)  		
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
	cbi PORTB, 5		
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
		ldi r17, 0x02
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                            MAIN CODE                                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
reset:
	rcall configure_outputs
	rcall configure_inputs
	rcall configure_timer0
	rcall configure_timer2
	rcall configure_pushbutton_interrupt   
	rcall configure_rpg_interrupt         
	rcall configure_lcd
	initialize_rpg:
		ldi r18, 0
		mov rpg_prev_a, r18						  ; previous a set to 0
		mov rpg_prev_b, r18						  ; previous b set to 0
	initialize_fan:
		mov prev_dc_q, current_dc_q				  ; fan state set to 50%
		ldi fan_state, 0xff						  ; fan flagged to 1 (on)
	sei											  ; enable global interrupts

program_loop:
	; TODO -> display with LCD. this should run inside the loop as it needs to be constantly refreshed.
	rjmp program_loop;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 Pushbutton Interrupt Service Routine 									  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pushbutton_isr:
	; this should simply toggle the current value inside of the fan state.
	; look into the pwm 0 weird error shit going on 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                      RPG Interrupt Service Routine 									  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rpg_a_isr:
	detect_current_a:
		in r16, PINB
		andi r16, (1 << PB1)       	
		ldi r17, 1					
		sbrs r16, PB1 
		ldi r17, 0
	mov rpg_prev_a, r17
	cpse r17, rpg_prev_b
	rjmp rpg_cw	
	rjmp rpg_ccw	
rpg_b_isr:
	detect_current_b:
		in r16, PINB
		andi r16, (1 << PB0)
		ldi r17, 1					
		sbrs r16, PB0 
		ldi r17, 0
	mov rpg_prev_b, r17
	cpse r17, rpg_prev_a
	rjmp rpg_cw		
	rjmp rpg_ccw	
rpg_cw:
	cpi current_dc_q, 79
	breq at_ceiling
	inc current_dc_q
	at_ceiling:
	reti
rpg_ccw:
	cpi current_dc_q, 0   
	breq at_floor
	dec current_dc_q
	at_floor:
	reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                            LCD Display												  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
displayCString:
	lpm r0, Z+
	tst r0 			
	breq done 			
	swap r0 			
	out PORTC, r0
	rcall LCDStrobe 
	swap r0 				
	out PORTC, r0 			
	rcall LCDStrobe 	
	rjmp displayCString
done:
	ret

set_8_bit_mode:
	ldi r17, 0x03
	out PORTC, r17
	ret

LCDStrobe:
	sbi PORTB, 2					
	ldi r27, 0x00			
	ldi r26, 0x05		
	Strobe_loop:  
		rcall delay_100us  
		sbiw r27:r26, 1   
		brne Strobe_loop  
		cbi PORTB, 2				
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                            Timer0 Delays                                                ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delay_100ms:
	ldi r27, 0x03
	ldi r26, 0xE8
	loop_100ms:
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
	in tmp1, TCCR2B 
	ldi tmp2, 0x00
	out TCCR2B, tmp2
	in tmp2, TIFR2
	sbr tmp2, 1<<TOV2
	out TIFR2, tmp2
	out TCNT2, count
	out TCCR2B, tmp1
	wait_for_overflow:
		in tmp2, TIFR2
		sbrs tmp2, TOV2
		rjmp wait_for_overflow
		ret