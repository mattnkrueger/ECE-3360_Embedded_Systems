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
.def rpg_current_state = r21;
.def rpg_previous_state = r20;
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
rjmp rpg_change

.org 0x0008
rjmp rpg_change

.org 0x0034  							 	 	  ; end of interrupt vector 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                           Lookup Tables                                                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
duty_cycle_prefix:
	.db "DC = ", 0x00 

DUMMY_DC:
	.db "%", 0x00 

duty_cycle_suffix:
	.db "%", 0x00 

status_prefix:
	.db "Fan: ", 0x00

status_suffix_on:
	.db "ON ", 0x00

status_suffix_off:
	.db "OFF", 0x00

status_suffix_gt_ok:
	.db "RPM OK ", 0x00

status_suffix_lt_stopped:
	.db "Stopped", 0x00

status_suffx_lt_low:
	.db "low RPM", 0x00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                      Component Configuration                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
configure_outputs:
    ; port B
	sbi DDRB, 5								      ; R/S on LCD (Instruction/register selection) (arduino pin 13)
	sbi DDRB, 2									  ; E on LCD (arduino pin ~10)
	; port C
	sbi DDRC, 3									  ; D7 on LCD (arduino pin A3) 
	sbi DDRC, 2									  ; D6 on LCD (arduino pin A2)
	sbi DDRC, 1									  ; D5 on LCD (arduino pin A1)
	sbi DDRC, 0									  ; D4 on LCD (arduino pin A0)
	; port D
	sbi DDRD, 3									  ; PWM fan signal (arduino pin ~3)
	sbi DDRD, 5									  ; LED indicator for fan interrupt (arduino pin ~5)
	ret
	
configure_inputs:
	; port B
	cbi DDRB, 1									  ; A signal from RPG (arduino pin 4)
	cbi DDRB, 0									  ; B signal from RPG (arduino pin ~5)
	; port d
	cbi DDRD, 2									  ; Pushbutton input signal
	ret

configure_timer0:
	ldi count, 0x38
	ldi tmp1, (1 << CS01) 	
	out TCNT0, count
	out TCCR0B, tmp1
	ret

configure_timer2:
	ldi r16, (1 << COM2B1) | (1 << WGM21) | (1 << WGM20) 
	sts TCCR2A, r16
	ldi r16, (1 << WGM22) | ( 1<< CS20)
	sts TCCR2B, r16
	ldi r16, 199           
	sts OCR2A, r16
	ldi current_dc_q, 100      
	sts OCR2B, current_dc_q   
	ret

configure_pushbutton_interrupt:
	ldi r16, (1 << ISC01)  		
	sts EICRA, r16
	ldi r16, (1 << INT0)			
	out EIMSK, r16
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
	rcall lcd_strobe
	rcall delay_10ms
	rcall set_8_bit_mode
	rcall lcd_strobe
	rcall delay_1ms
	rcall set_8_bit_mode
	rcall lcd_strobe
	rcall delay_1ms
	set_4_bit_mode:
		ldi r17, 0x02
		out PORTC, r17
		rcall lcd_strobe
	rcall delay_10ms
	set_interface:
		ldi r17, 0x02
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_100us
		ldi r17, 0x08
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_1ms
	enable_display_cursor:
		ldi r17, 0x00
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_100us
		ldi r17, 0x08
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_10ms
	clear_home:
		ldi r17, 0x00
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_100us
		ldi r17, 0x01
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_10ms
	set_cursor_move_direction:
		ldi r17, 0x00
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_100us
		ldi r17, 0x06
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_1ms
	turn_on_display:
		ldi r17, 0x00
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_100us
		ldi r17, 0x0C
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_1ms
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                            MAIN CODE                                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
reset:
	; configure components
	rcall configure_outputs
	rcall configure_inputs
	rcall configure_timer0
	rcall configure_timer2
	rcall configure_pushbutton_interrupt   
	rcall configure_rpg_interrupt         
	rcall configure_lcd

	; read initial rpg state
	in rpg_previous_state, PINB
	andi rpg_previous_state, 0x03

	; initialie fan to on with current duty cycle quotient set in configuration subroutine
	mov prev_dc_q, current_dc_q
	ldi fan_state, 0xff						 

	; enable global interrupts
	sei											

main:
	; continuously display duty cycle
	rcall display_current_dc
	rjmp main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 Pushbutton Interrupt Service Routine 									  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pushbutton_isr:
	push r17					 ;Keep SREG the same before and after ISR
    in r17, SREG
    push r17

	rcall delay_100ms		;delay for pushbutton signal 

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
		rjmp update_pwm
	turn_off:
		cbi PORTD, 5			 ; Turn LED on	
		clr fan_state            ; Set state to OFF
		mov prev_dc_q, r17         ; Save current duty cycle
		ldi r17, 0               ; Set duty to 0
	update_pwm:
		sts OCR2B, r17           ; Update PWM register with the stored value
	wait:
		sbis PIND, 2			 ; Make sure that the push button is back to high before leaving and enabling interrupts again
		rjmp wait;				 ; low again could start another interrupt

	rcall delay_100ms		 ; delay before exiting and renabling interrupts, debouncing

	exit_toggle:
		pop r17
		out SREG, r17
		pop r17
		reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                      RPG Interrupt Service Routine 									  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rpg_change:
    ; save registers that will be operated on 
    push r16
    in r16, SREG
    push r16
    push r17

	; exit if fan is off
	tst fan_state
	breq exit_rpg_isr		   

	; detect state of RPG pins
	;      	  ------------------------------------------
	;      	  | 0 |  0 | 0 | 0 | 0 | 0 | currA | currB |
	;      	  ------------------------------------------
	in r17, PINB
	andi r17, 0x03      

    ; build sequence
	; previous state bits are shifted twice, and then combined (bitwise or)
	; because rpg A and B are two bits, shifting twice will result:
	;      	  ------------------------------------------
	;      	  | 0 |  0 | 0 | 0 | prevA | prevB | 0 | 0 |
	;      	  ------------------------------------------
	; then applying or with current A and current B (without shifting), will result:
	;      --------------------------------------------------
	;      | 0 |  0 | 0 | 0 | prevA | prevB | currA | currB |
	;      --------------------------------------------------
	; now, register 16 is in the form of a unique gray code encoding a cw or ccw turn.
    mov r16, rpg_previous_state
    lsl r16             
    lsl r16           
    or r16, r17        

	; update previous state
    mov rpg_previous_state, r17
    
	; cases:
    ; 	- counter-clockwise: 0b0001, 0b0111, 0b1000, 0b1110
    ; 	- clockwise: 0b0010, 0b0100, 0b1011, 0b1101
	; if none of these cases, jumps to exit
    ; if ccw
    cpi r16, 0b0001
    breq counter_clockwise
    cpi r16, 0b0111
    breq counter_clockwise
    cpi r16, 0b1000
    breq counter_clockwise
    cpi r16, 0b1110
    breq counter_clockwise
    
    ; if cw
    cpi r16, 0b0010
    breq clockwise
    cpi r16, 0b0100
    breq clockwise
    cpi r16, 0b1011
    breq clockwise
    cpi r16, 0b1101
    breq clockwise

    ; if other
    rjmp exit_rpg_isr
    
clockwise:
    lds r16, OCR2B            ; Get current duty cycle
    cpi r16, 199              ; Check if at max (199)
    breq exit_rpg_isr
    inc r16                   ; Increase duty cycle
    sts OCR2B, r16            ; Update PWM register
    rjmp exit_rpg_isr
    
	counter_clockwise:
		lds r16, OCR2B            ; Get current duty cycle
		cpi r16, 0                   ; Check if at min (0)
		breq exit_rpg_isr
		dec r16                   ; Decrease duty cycle
		sts OCR2B, r16            ; Update PWM register
    
	exit_rpg_isr:
		pop r17
		pop r16
		out SREG, r16
		pop r16
		reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                            LCD Display												  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
display_to_lcd:
	lpm r0, Z+
	tst r0 			
	breq done 			
	swap r0 			
	out PORTC, r0
	rcall lcd_strobe 
	swap r0 				
	out PORTC, r0 			
	rcall lcd_strobe 	
	rjmp display_to_lcd
done:
	ret

set_8_bit_mode:
	ldi r17, 0x03
	out PORTC, r17
	ret

lcd_strobe:
	sbi PORTB, 2					
	ldi r27, 0x00			
	ldi r26, 0x05		
	strobe_loop:  
		rcall delay_100us  
		sbiw r27:r26, 1   
		brne strobe_loop  
		cbi PORTB, 2				
		ret

dc_to_string:
	nop
	ret

display_current_dc:
	sbi PORTB, 5
	ldi r30, LOW(2*duty_cycle_prefix)
	ldi r31, HIGH(2*duty_cycle_prefix)
	rcall display_to_lcd
	ldi r30, LOW(2*DUMMY_DC)
	ldi r31, HIGH(2*DUMMY_DC)
	rcall dc_to_string
	ldi r30, LOW(2*duty_cycle_suffix)
	ldi r31, HIGH(2*duty_cycle_suffix)
	rcall display_to_lcd
	cbi PORTB, 5
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
	in tmp1, TCCR0B 
	ldi tmp2, 0x00
	out TCCR0B, tmp2
	in tmp2, TIFR0
	sbr tmp2, (1 << TOV0)
	out TIFR0, tmp2
	out TCNT0, count
	out TCCR0B, tmp1
	wait_for_overflow:
		in tmp2, TIFR0
		sbrs tmp2, TOV0
		rjmp wait_for_overflow
		ret