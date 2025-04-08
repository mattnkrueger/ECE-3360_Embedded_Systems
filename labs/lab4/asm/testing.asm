;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																								          ;
;                                     Lab 4: ECE:3360 Embedded Systems									  ;
;																								          ;
;												 Authors:												  ;
; 	 									 Sage Marks & Matt Krueger 								          ;
; 																										  ;
; 											Project Statement:											  ;
; 					This AVR program controls a pwm cooling fan, LCD display,					  		  ;
; 					active-Low pushbutton, and RPG Encoder to create a fan monitoring system.		  	  ;
;																								          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "m328pdef.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                           Register Aliases                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.def dc_high			 = r29 					   ; Y reg
.def dc_low 			 = r28 					   ; Y reg
.def tmp2                = r24                     ; temporary register 
.def tmp1                = r23                     ; temporary register
.def count               = r22                     ; stores counter for timer0
.def rpg_current_state   = r21
.def rpg_previous_state  = r20
.def fan_state           = r19                     ; boolean flag for fan on/off
.def previous_dc_divisor = r18                     ; tracks previous duty cycle divisor
.def current_dc_divisor  = r17                     ; tracks current duty cycle divisor
.def rpg_accumulator     = r5 					   ; accumulator for our rpg <1% change per turn
.def rpg_threshold 		 = r4 					   ; max for accumulator

.cseg
.org 0x0000
rjmp reset										   ; jump over interrupts & LUTs

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                          Interrupt Vectors                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org 0x0002
rjmp toggle_fan

.org 0x0006  
rjmp rpg_change

.org 0x0008
rjmp rpg_change

.org 0x0034  							 	 	  ; end of interrupt vector 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                           Lookup Tables                                                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
	sbi DDRD, 3									  ; pwm fan signal (arduino pin ~3)
	sbi DDRD, 5									  ; green LED indicator for fan ON (arduino pin ~5)
	sbi DDRD, 7									  ; red LED indicator for fan OFF(arduino pin ~7)
	ret
	
configure_inputs:
	; port B
	cbi DDRB, 1									  ; A signal from RPG (arduino pin 4)
	cbi DDRB, 0									  ; B signal from RPG (arduino pin ~5)

	; port d
	cbi DDRD, 2									  ; Pushbutton input signal
	ret

configure_timer0:
	; TCCR0A:
	;      --------------------------------------------------------------        ---------------------------------
	;      | COM0A1 |  COM0A0 | COM0B1 | COM0B0 | - | - | WGM01 | WGM00 |  --->  | 0 | 0 | 0 | 0 | - | - | 0 | 0 |
	;      --------------------------------------------------------------        ---------------------------------
	; TCCR0B:
	;              ------------------------------------------------------        ---------------------------------
	;              | FOC0A | FOC0B | - | - | WGM02 | CS02 | CS01 | CS00 |  --->  | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
	;              ------------------------------------------------------        ---------------------------------
	;
	; Configuration:
	; - clock source: 16MHz prescaled by 8 to yield a 2MHz tick
	;    							1/2MHz = 0.5us per tick
	;
	; - counter operation: normal with top of 0xFF, counting up from `count` (56 decimal)
	;             					256 - 56 = 200 ticks before overflow,
	;             					200 ticks * 0.5us = 100us	
	;			this means that timer overflows every 100us, yeilding a delay of 100us
    ;
	; - *important note* because we are passing a count into the tcnt0 register, tcnt0 resets at turnover.
	;    Therefore, we must reload at every overflow (see delay section for details)
	ldi count, 0x38
	ldi tmp1, (1 << CS01) 						  
	out TCNT0, count							  
	out TCCR0B, tmp1
	ret

configure_timer2:
	; TCCR2A:
	;      --------------------------------------------------------------        ---------------------------------
	;      | COM2A1 |  COM2A0 | COM2B1 | COM2B0 | - | - | WGM21 | WGM20 |  --->  | 0 | 0 | 1 | 0 | - | - | 1 | 1 |
	;      --------------------------------------------------------------        ---------------------------------
	; TCCR2B:
	;               -----------------------------------------------------        ---------------------------------
	;               | FOC2A | FOC2B | - | - | WGM22 | CS22 | CS21 | CS20|  --->  | 0 | 0 | - | - | 1 | 0 | 0 | 1 |
	;               -----------------------------------------------------        ---------------------------------
	;
	; Configuration:
	; - counter operation: Clear OC2B on compare match, set OC2B at BOTTOM (0). All wgm bits set, so top is fast-pwm with a top of OCR2A
	; 						 With these selections, we can simlpy increment/decrement OCR2B to achieve the duty cycle. 
	;  					     Setting OCR2A to 199, we can increment/decrement OCR2B from 0 to 199 to achieve a duty cycle of 0-99%
	;                        Thus, an increment/decrement of 1 in OCR2B will change the duty cycle by +/-0.5%
	;
	; - clock source: no prescaling. 16MHz clock, so 1 tick = 0.0625us
	ldi r16, (1 << COM2B1) | (1 << WGM21) | (1 << WGM20) 	  ; Fast pwm, non-inverting (COM0B1=1), TOP=OCR0A (Mode 7)
	sts TCCR2A, r16
	ldi r16, (1 << WGM22) | ( 1<< CS20)					  		; Prescaler=1 (CS20=1), Fast pwm with TOP=OCR0A (WGM02=1)
	sts TCCR2B, r16
	ldi r16, 199           
	sts OCR2A, r16
	ldi current_dc_divisor, 195      									; initial duty cycle is 195/200 = 97.5%
	sts OCR2B, current_dc_divisor   
	ret

configure_pushbutton_interrupt:
	; configure INT0 interrupt to trigger on falling edge
	; this is used to control on/off of fan
	ldi r16, (1 << ISC01)  		; falling edge
	sts EICRA, r16
	ldi r16, (1 << INT0)		; enable int0
	out EIMSK, r16
	ret 

configure_rpg_interrupt:
	; configure PCINT0 and PCINT1 
	; this is used to control the duty cycle of the fan
	ldi r16, (1 << PCIE0) 						; enable PCINT 7..0
	sts PCICR, r16
	ldi r16, (1 << PCINT1) | (1 << PCINT0)      ; PCINT1..0 mask
	sts PCMSK0, r16
	ret

configure_lcd:
    ; LCD power-up sequence
	rcall delay_100ms						      ; wait >40ms
	cbi PORTB, 5								  ; set R/S to low (data transferred is treated as commands)

    ; set 8-bit mode by sending 0011 0000 3 times
	rcall set_8_bit_mode						 
	rcall lcd_strobe						
	rcall delay_10ms	 					      ; wait for >4.1ms after setting 8-bit (via datasheet pg 45)						
	rcall set_8_bit_mode			
	rcall lcd_strobe				
	rcall delay_1ms								  ; subsequent delays >100us. 
	rcall set_8_bit_mode
	rcall lcd_strobe
	rcall delay_1ms 							  ; delay between commands >100us

	; set 4-bit mode
	set_4_bit_mode:
		ldi r17, 0x02							  
		out PORTC, r17
		rcall lcd_strobe
	rcall delay_10ms

	; finilize 4-bit mode 
	set_interface:
		ldi r17, 0x02
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_100us
		ldi r17, 0x08
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_1ms
	; now 4 bit mode is set

	rcall delay_10ms

	; enable_display_cursor:
	; 	ldi r17, 0x00;
	; 	out PORTC, r17;
	; 	rcall lcd_strobe;       ; additional strobe included inside of slides: 
	; 	rcall delay_100us;		; not needed as it is overwritten by turn on display
	; 	ldi r17, 0x08;			; delaying before next command to ensure not busy is sufficient
	; 	out PORTC, r17;
	; 	rcall lcd_strobe;
	; 	rcall delay_10ms

	; reset cursor to home
	clear_home:
		ldi r17, 0x00
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_100us
		ldi r17, 0x01 				; 0000 0001 -> return cursor to home
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_10ms

    ; set cursor move direction to right
	set_cursor_move_direction:
		ldi r17, 0x00
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_100us
		ldi r17, 0x06 				; 0000 0110 -> cursor move direction to right
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_1ms

	; turn on display... overwrites display off command enable_display_cursor
	turn_on_display:
		ldi r17, 0x00
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_100us
		ldi r17, 0x0C 				; 0000 1100 -> display on, cursor off, blink off
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_1ms

    ; The following code is for displaying static strings. these are overwritten by the dynamic strings in isrs
	;  ---------------------------------------------------
	;  | D | C | _ | = | _ |  |  |  |  |  |  |  |  |  |  |
	;  | F | a | n | : | _ |  |  |  |  |  |  |  |  |  |  |
	;  ---------------------------------------------------
	; display prefix on first row
	display_dc_prefix:					
		sbi PORTB, 5									
		ldi r30, LOW(2 * prefix_string) 				; "DC = "
		ldi r31, HIGH(2 * prefix_string)   				; obtain address of prefix string
		rcall write_string_to_lcd

	;move the cursor to the second row
	move_cursor_to_second_row:
		cbi PORTB, 5
		ldi r17, 0x0C
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_100us
		ldi r17, 0x00      							    ; move cursor to beginning of second row (ddram 40)
		out PORTC, r17
		rcall lcd_strobe
		rcall delay_1ms

	; display fan status on second row
	display_fan_status:
		sbi PORTB, 5
		ldi r30, LOW(2 * fan_string) 					; "Fan: "
		ldi r31, HIGH(2 * fan_string)				    ; obtain address of fan string
		rcall write_string_to_lcd
	
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
	andi rpg_previous_state, 0x03				; mask to get pins 5 (A) and 4 (B)

	; initialie fan to on with current duty cycle quotient set in configuration subroutine
	mov previous_dc_divisor, current_dc_divisor
	ldi fan_state, 0xff							; set fan state to on (1)
	rcall fan_on

	; initial LED indicators used on circuit
	sbi PORTD, 5
	cbi PORTD, 7
	; enable global interrupts
	sei											

	; display initial pwm value
	rcall move_cursor_to_dc_addr_lcd
	rcall convert_dc_to_percentage
	rcall write_dc_to_lcd

; program loop. because this is an interrupt-driven program, nothing is in main loop
main:
	rjmp main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 Pushbutton Interrupt Service Routine 									  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
toggle_fan:
	push r17					 
    in r17, SREG
    push r17

	;debouncing (issue with manufacturing uc, fixed by prof Beichel)
	rcall delay_100ms							
	ldi r20, (1<< INTF0)						
	out EIFR, r20
	sbic PIND,2				
	rjmp exit_toggle

	toggle_code:
		lds r17, OCR2B               			; get current pwm value
		tst fan_state				 			; if fan state is 0 (off)
		brne turn_off                			; if currently ON (0xFF), turn OFF (0x00)

	turn_on:
		; change indicator LEDs (simply to let user know if button has worked correctly)
		sbi PORTD, 5			 				; turn green led on
		cbi PORTD, 7			 				; turn red led off

		; set fan state to on and restore saved duty cycle
		ldi fan_state, 0xFF      				
		mov r17, previous_dc_divisor       			
		in rpg_previous_state, PINB
		andi rpg_previous_state, 0x03		
		rjmp update_pwm

	turn_off:
		; change indicator LEDs (simply to let user know if button has worked correctly)
		cbi PORTD, 5			   				; turn green led off
		sbi PORTD, 7			   				; turn red led on

		; set fan state to off and save current duty cycle
		clr fan_state              				; set state to OFF
		mov previous_dc_divisor, r17         				; save current duty cycle
		ldi r17, 0                 				; set duty to 0

	update_pwm:
		sts OCR2B, r17           				; update pwm register with the stored value

	update_fan_display:
		tst fan_state				
		brne display_on
		rcall move_cursor_to_onoff_addr_lcd 
		rcall fan_off
		rjmp exit_toggle

		display_on:
		rcall move_cursor_to_onoff_addr_lcd  
		rcall fan_on

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
    push r30

	; exit if fan is off
    rcall delay_100us
	tst fan_state
    breq exit_rpg_isr           

	; detect state of RPG pins
	;      	  ------------------------------------------
	;      	  | 0 |  0 | 0 | 0 | 0 | 0 | currA | currB |
	;      	  ------------------------------------------
	in r17, PINB
	andi r17, 0x03      

    ; build sequence
	; previous state bits are shifted twice, and then combined.
	; because rpg A and B are two bits, shifting twice will result:
	;      	  ------------------------------------------
	;      	  | 0 |  0 | 0 | 0 | prevA | prevB | 0 | 0 |
	;      	  ------------------------------------------
	; then applying bitwise or with current A and current B (without shifting), will result:
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
    inc rpg_accumulator                                 ; increment accumulator and compare with threshold
    mov r30, rpg_accumulator                            
    cp r30, rpg_threshold                               
    brne exit_rpg_isr                                   ; if threshold not reached, skip OCR2B update
    
    clr rpg_accumulator                                 ; reset accumulator
    lds r30, OCR2B                                      ; get current duty cycle
    cpi r30, 199
    breq exit_rpg_isr
    inc r30                                             ; increment
    sts OCR2B, r30                                      ; update ocr2b
    rjmp exit_rpg_update
    
counter_clockwise:
    inc rpg_accumulator                                 ; increment the accumulator
    mov r30, rpg_accumulator                            ; use r30 as temporary register
    cp r30, rpg_threshold                               ; compare with threshold
    brne exit_rpg_isr                                   ; if not reached threshold, skip OCR2B update
    
    clr rpg_accumulator                                 ; reset accumulator
    lds r30, OCR2B                                      ; get current duty cycle
    cpi r30, 2                                          ; check if at min (2 or 1%)
    breq exit_rpg_isr                                   ; if at min, don't decrement
    dec r30                                             ; decrease duty cycle
    sts OCR2B, r30                                      ; update pwm register
    rjmp exit_rpg_update

exit_rpg_update:
    rcall move_cursor_to_dc_addr_lcd				    ; move cursor to dc address
    rcall convert_dc_to_percentage						; convert pwm to percent
    rcall write_dc_to_lcd								; display pwm
    rjmp exit_rpg_isr

exit_rpg_isr:
    pop r30
    pop r17
    pop r16
    out SREG, r16
    pop r16
    reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                            LCD Display												  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_8_bit_mode:
	; set 8-bit mode by sending 0011 0000 (this is a subroutine called 3 times to set 8-bit mode)
	ldi r17, 0x03
	out PORTC, r17
	ret

lcd_strobe:
	sbi PORTB, 2                     ; set E to high (initiate data transfer)
	ldi r27, 0x00                    
	ldi r26, 0x05                    ; delay 500us
	strobe_loop:
		rcall delay_100us          
		sbiw r27:r26, 1            
		brne strobe_loop           
		cbi PORTB, 2                 ; set E to low (end of data transfer)
		ret

write_string_to_lcd:
	lpm r0,Z+                        ; start of loaded memory address
	tst r0                           ; check for terminating character 
	breq done                        ; if done, exit
	swap r0                          ; else, swap nibbles
	out PORTC, r0                    ; send upper nibble out
	rcall lcd_strobe                 ; latch nibble
	swap r0                          ; lower nibble in place
	out PORTC,r0                     ; send lower nibble out
	rcall lcd_strobe                 ; latch nibble
	rjmp write_string_to_lcd         ; continue until done
done:
	ret

write_char1:
	push r16

	; add 0x30 to r2 and move to r16
	ldi r25, 0x30 								
	add r25, r2
	mov r16, r25

	; mask upper nibble, swap, and send
	andi r25, 0xf0
	swap r25
	out PORTC, r25 
	rcall lcd_strobe 
	rcall delay_100us

	; mask lower nibble, send, and strobe
	andi r16, 0x0f
	out PORTC, r16 
	rcall lcd_strobe
	rcall delay_100us
	pop r16
	ret

write_char2:
	push r16

	; add 0x30 to r1 and move to r16
	ldi r25, 0x30
	add r25, r1
	mov r16, r25

	; mask upper nibble, swap, and send
	andi r25, 0xf0
	swap r25
	out PORTC, r25 						
	rcall lcd_strobe 					
	rcall delay_100us 					

	; mask lower nibble, send, and strobe
	andi r16, 0x0f
	out PORTC, r16 					
	rcall lcd_strobe 		
	rcall delay_100us
	pop r16
	ret

write_char3:
	push r16

	; load 0x30 into r25 and add r0
	ldi r25, 0x30
	add r25, r0
	mov r16, r25

	; mask upper nibble, swap, and send
	andi r25, 0xf0
	swap r25
	out PORTC, r25 						
	rcall lcd_strobe 			
	rcall delay_100us 	

	; mask lower nibble, send, and strobe
	andi r16, 0x0f
	out PORTC, r16 			
	rcall lcd_strobe 
	rcall delay_100us
	pop r16
	ret

write_decimal:
	; load 0x02 into r25 and send
	ldi r25, 0x02
	out PORTC,r25 					
	rcall lcd_strobe 	
	rcall delay_100us 

	; load 0x0e into r25 and send
	ldi r25,0x0e
	out PORTC,r25 					
	rcall lcd_strobe 				
	rcall delay_100us
	ret

; move cursor to ddram 05 of lcd
move_cursor_to_dc_addr_lcd:							
	cbi PORTB, 5
	ldi r17, 0x08 
	out PORTC, r17
	rcall lcd_strobe
	rcall delay_100us
	ldi r17, 0x05					        ; move cursor to position 5
	out PORTC, r17
	rcall lcd_strobe
	rcall delay_1ms
	sbi PORTB, 5
	ret

; move cursor to ddram 05 of lcd and display longer string (100.0%)
pwm_full_speed:
	inc r30
	sts OCR2B, r30   
	rcall move_cursor_to_dc_addr_lcd
	ldi r16, 1
	mov r2, r16
	rcall write_char1
	ldi r16, 0
	mov r2, r16
	rcall write_char1
	rcall write_char1
	rcall write_decimal
	rcall write_char1
	ldi r30,LOW(2 * suffix_string) 	  	 	  	 ; "%"
	ldi r31,HIGH(2 * suffix_string)  			 ; obtain address of suffix string
	rcall write_string_to_lcd

	exit_full_speed:
		ldi r16, 2
		mov rpg_accumulator, r16
		ret

; move cursor to ddram 45 of lcd
move_cursor_to_onoff_addr_lcd:
	cbi PORTB, 5
	ldi r17, 0x0C  						
	out PORTC, r17
	rcall lcd_strobe
	rcall delay_100us
	ldi r17, 0x05							; move cursor to position 45
	out PORTC, r17
	rcall lcd_strobe
	rcall delay_1ms
	sbi PORTB, 5
	ret

; load address of "ON" in mem for display
fan_on:
	ldi r30,LOW(2 * on_string) 
	ldi r31,HIGH(2 * on_string)
	rcall write_string_to_lcd
	ret

; load address of "OFF" in mem for display
fan_off:
	ldi r30,LOW(2 * off_string) 
	ldi r31,HIGH(2 * off_string)
	rcall write_string_to_lcd
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                     Duty Cycle to LCD Subroutine                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; because dc is displayed as a percentage, we need to multiply by 100. 
; even though registers are 8 bits and range from 0-255, multiplying 2 8-bit values results in a 16-bit value.
; 
; we use the following subroutines to apply the 16-bit multiplication and division as AVR does not have support for these operations
; Application Note AN_0936 “AVR200: Multiply and Divide Routines”:
; - mpy16u: 16-bit multiplication
; - div16u: 16-bit division
; 
; example calc:
;    let ocr2b = 98
;    let ocr2a = 199
;    -> (98 + 1) * 100 / (199 + 1) = 49.5%
;
convert_dc_to_percentage:
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
	push r24
	push r25
	push r30
	push r31
	
	; timer counter is 0 indexed, so we need to add 1 to the ocr2b to get the actual dividend.
	; additionally, we need to make this a 16-bit value to work with mpy/div subroutines
	lds r24, OCR2B						
	clr r25
	adiw r25:r24, 1						; ocr2b + 1 
	
	; move into r17:r16 for mpy16u
	mov r16, r24
	mov r17, r25

	; multiply r19:r18 * r17:r16
	ldi r18, 100				
	clr r19
	rcall mpy16u						; product in r17:r16

	; now we have duty cycle dividend * 100  in 17:16.
	; lets say we have ocr2b of 98, which one turn less than 50% dc:
	;                      (98 + 1) * 100 = 9900
	;
	;
	; we now need to divide by duty cycle divisor to get the duty cycle percentage
	; duty cycle divisor is ocr2a + 1, which is 199 + 1 = 200
	;            9900 / (199 + 1) = 49 (quotient) . (implied decimal point) 5 (remainder)
	; 			 = 49.5%

	; timer counter is 0 indexed, so we need to add 1 to the ocr2a to get the actual divisor
	lds r24, OCR2A
	clr r25
	adiw r25:r24, 1						; ocr2a + 1	

	; move into r18:r19 for div16u
	mov r18, r24
	mov r19, r25
	
	; divide r17:r16 / r19:r18
	rcall div16u					; quotient in r17:r16 (but lives in r16 as quotient never exceeds 255), remainder in 15:14 (but lives in r14 as it never exceeds 255)

	; because our resolution is so low, we can simply save quotient to upper byte and remainder to lower byte to send to write_dc_to_lcd
	; why does this work? 
	;     - our ocr2a is 200, so we can never represent a quotient greater than 200, which fits within 8 bits
	;     - similarly, our remainder will always be less than 200, which fits within 8 bits

	;save the value to R29:R28
	mov r29, r16
	mov r28, r14

    pop r31
	pop r30
	pop r25
	pop r24
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

write_dc_to_lcd:
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
	
	; get duty cycle
	mov r16, dc_low
	mov r17, dc_high

	; divide by 10
	ldi r18, low(10)
	ldi r19, high(10)

	rcall div16u								
	mov r0, r14
	rcall div16u
	mov r1, r14
	rcall div16u
	mov r2, r14

	rcall write_char1
	rcall write_char2
	rcall write_decimal
	rcall write_char3
	
	ldi r30,LOW(2 * suffix_string) 			   ; "%"
	ldi r31,HIGH(2 * suffix_string)	           ; obtain address of suffix string
	rcall write_string_to_lcd;

    ; this handles case where 100.0% and then decremented to some other value in form xx.x%
	; this overwrites the "%" with a space
	ldi r30,LOW(2 * space_string) 		       ; " "
	ldi r31,HIGH(2 * space_string) 			   ; obtain address of space string
	rcall write_string_to_lcd;

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

; division code taken from ATMEL AVR200.asm
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


; Multiplication for getting value of 0-999, taken from ATMEL AVR200.asm
; mpy16u: r17:r16 <- r17:r16 * r19:r18
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
	out TCNT0, count  							; reload tcnt0 with count (56)
	out TCCR0B, tmp1
	wait_for_overflow:
		in tmp2, TIFR0
		sbrs tmp2, TOV0
		rjmp wait_for_overflow
		ret