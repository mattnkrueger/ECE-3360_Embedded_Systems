; Assignment: Lab 3
; Date: 2025-03-12 
; Authors: Sage Marks & Matt Krueger
; 
; Description: 
; 	This programs a simple lock with a 7-segment display, pushbutton, and a rotary pulse generator.

.cseg
.org 0x0000

; Port B Data Direction Configuration
sbi DDRB, 0											; SER          
sbi DDRB, 1											; RCLK          
sbi DDRB, 2											; SRCLK         
cbi DDRB, 3											; pushbutton signal
sbi DDRB, 5											; LED on arduino board

; Port D Data Direction Configuration
cbi DDRD, 6											; A signal from RPG
cbi DDRD, 7 										; B signal from RPG  

; Lookup table for 7-segment display
seven_segment_codes:
.db 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07 	; 0-7
.db 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71 	; 8-f

; Lookup table for password (AA5C4)
password_codes:
.db 0x0a, 0x0a, 0x05, 0x0c, 0x04, 0x00

; Register Aliases
.def hexPtr = r19 			                   	 	; points to current hex value to be displayed in the 7-Segment
.def lockerPtr = r18                      	        ; points to current hex value in the correct code sequence
.def sevenSegDisplay = r16  	 	 	 	   	 	; current hex pattern in 7-segment
.def RPGpreviousState = r20            		        ; register to hold previous state of RPG
.def RPGstate = r21                     	        ; register to hold current state of RPG
.def tmp1 = r23  	 	 	 	 	 	 	 	 	; use r23 for temporary variables 
.def tmp2 = r24  	 	 	 	 	 	 	 	    ; use r24 for temporary values
.def count = r22	 	 	 	 	 	 	 	 	; use r22 for the count

; Initial Rotary Pulse Generator State
in RPGpreviousState, PIND 	              	        ; load PIND into RPGpreviousState (11xxxxxx)
andi RPGpreviousState, 0xC0                     	; mask all other bits beside RPG bits 
ldi r17, 0xff    	 	 	 	 	 	  	  	    ; 


ldi r19, 0x00;

; timer_setup:
; 	- Timer/Counter setup for 500 μs delay
;   - 8-bit timer, so we need to set the prescalar to 64
;   - atmega328p has a CPU clock speed of 16 MHz, so 
;          		16,000,000/64 = 250,000
;           	1/250,000 = 4 μs per cycle
;   - setting count of loops to 131, we have 125 more loops to 
;     reach max 8 bit value of 255. 
;           	125 * 4 μs = 500 μs
timer_setup:
	.def tmp1 = r23 ; Use r23 for temporary variables
	.def tmp2 = r24 ; Use r24 for temporary values
	.def count = r22; Use r22 for the count

	ldi count, 0x83 		 	 	 	 	 	 	; set timer to start at 131
	ldi tmp1, (1<<CS01)|(1<<CS00) 	 	 	 	 	; set prescalar of fclk/64
	out TCNT0, count 	 	 	 	 	 	 	 	; load starting count value
	out TCCR0B, tmp1 	 	 	 	 	 	 	 	; load prescalar

; power_on:
;   - initialize the 7-segment display, call rpg check, and display number
power_on:
	ldi r16, 0x40            	 	 	 	 	 	; display dash
	rcall display 	 	 	 	 	 	 	 	 	; call display subroutine
	rcall delay										; delay for 500 μs
	rcall rpg_check									; call rpg check subroutine
	cpi r17, 0x00									; check if count is 0
	breq number_display 						    ; if count is 0, display number
	rjmp power_on									; if count is not 0, repeat

; number_display:
;   - main loop for program
;   - update the value to be displayed on the 7-segment display via rpg interaction
;   - display the current value of the count
number_display:
	rcall findvalue
	rcall rpg_interaction
    
	; button_check:
	; 	- if the pushbutton is pressed for <1 second, add current value stored in r17 to password value
	;   - if the pushbutton is pressed for 1<t<2 seconds, do nothing
	; 	- if the pushbutton is pressed for >2 second, reset the password value
	button_check:
		sbic PINB, 3 	 	  	 	 	 	 	 	  ; skip if button is not pressed
		rjmp number_display                           ; if button is not pressed, jump to number_display
        
	; less_than_one:
	; 	- pressed less than 1 second second, compare value with password digit 
	;   - loops 0000011111010000 (2000) 2000 times * 500 microseconds = 1 second
	less_than_one:
		ldi R26, 0xd0		                         ; load immediate value 0xd0 (11010000) into R26
		ldi R27, 0x07								 ; load immediate value 0x07 (00000111) into R27

        ; less than one loop:
		;   - loop contained in less_than_one subroutine
		less_than_one_loop:                          
			rcall delay                              ; delay for 500 microseconds
			sbiw R27:R26, 1							 ; subtract 1							 
			breq one_to_two                          ; if R27:R26 = 0, jump to one_to_two
			sbis PINB, 3                             ; skip if button is not pressed
			rjmp less_than_one_loop		             ; loop again (skipped if button is pressed)
			rjmp find_code                           ; if button is pressed, jump to find_code

	; one_to_two:
	; 	- pressed 1<t<2 seconds, do nothing
	;   - identical to less_than_one subroutine, but does not do anything if button is pressed
	;   - loops 0000011111010000 (2000) 2000 times * 500 microseconds = 1 second (we already know that the less than one loop has been completed)
	one_to_two:
		ldi R26, 0xd0		                         ; load immediate value 0xd0 (11010000) into R26
		ldi R27, 0x07								 ; load immediate value 0x07 (00000111) into R27

		; one_to_two loop:
		;   - loop contained in one_to_two subroutine
		one_to_two_loop:
			rcall delay                              ; delay for 500 microseconds
			sbiw R27:R26, 1						     ; subtract 1
			breq greater_than_two                    ; if R27:R26 = 0, jump to greater_than_two
			sbis PINB, 3                             ; skip if button is not pressed
			rjmp one_to_two_loop		             ; loop again (skipped if button is pressed)
			rjmp number_display                      ; if button is pressed, jump to number_display

	; greater_than_two:
	; 	- pressed >2 seconds, reset the password value
	;   - we know that 2 seconds has already elapsed while the user is pressing the button
	;   - simply wait until the button is released, and then reset the program 
	greater_than_two:
		sbis PINB, 3 							     ; skip if button is not pressed
		rjmp greater_than_two                        ; loop again (skipped if button is pressed)
		rjmp reset_code                              ; if button is released, jump to reset_code

    ; find_code:
	;   - load the value of the password at the current index
	;   - compare with the user's selected digit
	;   - if the values are equal, jump to correct_digit
	;   - otherwise, continue to incorrect_digit
    find_code:
		ldi ZL, low(password_codes << 1)             ; load immediate value 0x01 (00000001) into ZL
		add ZL, r19                                  ; add the current value of r19 to ZL
		lpm r18, Z                                   ; load the value at Z into r18
        cp r17, r18                                  ; compare the current value of r17 with r18
		breq correct_digit                           ; if r17 = r18, jump to correct_digit, else continue to incorrect_digit
 
		; incorrect_digit:
		; 	- increment the index of the password lookup table
		;   - set r0 to 0 (this functions as a flag to indicate that the user's	code is incorrect)
		;   - if the index of the password lookup table is 5, jump to incorrect_code_display
		;   - else, jump to number_display to continue current attempt
		incorrect_digit:
			inc r19                                  ; increment the index of the password lookup table
			ldi tmp1, 0                              ; set r0 to 0
			MOV r0, tmp1                             ; move the value of tmp1 to r0
			cpi r19, 0x05                            ; compare the current value of r19 with 0x05
			breq incorrect_code_display              ; if r19 = 0x05, jump to incorrect_code_display, else continue to number_display
			rjmp number_display                      ; jump to number_display to continue current attempt
        
	; incorrect_code_display:
	; 	- display the incorrect code pattern "_"
	incorrect_code_display:
		ldi R26, 0xb0                                ; load immediate value 0xb0 (10110000) into R26
		ldi R27, 0x36                                ; load immediate value 0x36 (00110110) into R27
		ldi r16, 0x08                                ; load immediate value 0x08 (00001000) into r16
		rcall display                                ; call display subroutine

		; incorrect_code_display_loop:
		; 	- display "_" for 7 seconds
		incorrect_code_display_loop:
			rcall delay                              ; delay for 500 microseconds
			sbiw R27:R26, 1                          ; subtract 1
			breq reset_code                          ; if R27:R26 = 0, jump to reset_code
			rjmp incorrect_code_display_loop         ; loop again
		
	; correct_digit:
	; 	- set r0 to 1 (this functions as a flag to indicate that the user's code is correct)
	;   - if r0 = 0, jump to incorrect_digit 
	;   - else, continue to number_display
    correct_digit: 
		Mov tmp1, r0                                 ; move the value of r0 to tmp1
		cpi tmp1, 0                                  ; compare the value of tmp1 with 0
		breq incorrect_digit                         ; if tmp1 = 0, jump to incorrect_digit, else continue to number_display. This is to ensure that the user's code is correct	
    	inc r19                                      ; increment the index of the password lookup table
        ldi tmp1, 1                                  ; set r0 to 1
        MOV r0, tmp1                                 ; move the value of tmp1 to r0
        cpi r19, 0x05                                ; compare the current value of r19 with 0x05
        breq correct_code_check                      ; if r19 = 0x05, jump to correct_code_check, else continue to number_display
		rjmp number_display                          ; jump to number_display
        
    ; correct_code_check:
	; 	- set r0 to 1 (this functions as a flag to indicate that the user's code is correct)
	;   - if r0 = 1, jump to LED_ON
    correct_code_check:
    	MOV tmp1, r0                                 ; move the value of r0 to tmp1
        cpi tmp1, 0x01                               ; compare the value of tmp1 with 0x01
        breq correct_password                        ; if tmp1 = 0x01, jump to LED_ON, else continue to reset_code
        
    ; reset_code:
	; 	- set r0 to 1 (true initially... user hasnt entered the wrong code yet)
	;   - reset the index of the password lookup table to 0
	;   - jump to power_on to restart the program
    reset_code:
		ldi tmp1, 1                                  ; set r0 to 1
		MOV r0, tmp1                                 ; move the value of tmp1 to r0
		ldi r19, 0x00                                ; reset the index of the password lookup table to 0
		rjmp power_on                                ; jump to power_on to restart the program
        
    ; correct_password:
	; 	- display the LED on the arduino board
	;   - display a "." on the 7-segment display
	;   - only displayed if the user's code is correct
	;   - runs for 4 seconds
    correct_password:
    	ldi R26, 0x40                                ; load immediate value 0x40 (01000000) into R26
		ldi R27, 0x1f                                ; load immediate value 0x1f (00011111) into R27
    	sbi PORTB, 5                                 ; set the LED on the arduino board
		ldi r16, 0x80                                ; load immediate value 0x80 (10000000) into r16
		rcall display                                ; call display subroutine

		; correct_password_loop:
		; 	- display the LED on the arduino board for 4 seconds
		correct_password_loop:
			rcall delay                              ; delay for 500 microseconds
			sbiw R27:R26, 1                          ; subtract 1
			breq  LED_off                            ; if R27:R26 = 0, jump to LED_off
			rjmp correct_password_loop               ; loop again

		; LED_off:
		; 	- turn off the LED on the arduino board
		LED_off:
			cbi PORTB, 5                              ; turn off the LED on the arduino board
			rjmp reset_code                           ; jump to reset_code to restart the program

    ; rpg_check:
	; 	- check the state of the RPG
	;   - if the state has not changed, jump to no_change
	;   - otherwise, jump to check_state
	;   - rotary pulse generator has 3 pins: A, B, and C
	;   - A and B are used to determine the direction of the rotation
	;   - A and B are set to pin 6 and 7 of the arduino board
	;   - C is used to reset the program
    rpg_check:
		rcall delay                                   ; delay for 500 microseconds
		in RPGstate, PIND                             ; load the state of the RPG into RPGstate
		andi RPGstate, 0xC0                           ; mask all other bits beside RPG bits
		cp RPGstate, RPGpreviousState                 ; compare the current state of the RPG with the previous state
		breq no_change                                ; if the state has not changed, jump to no_change
		cpi RPGstate, 0x00                            ; compare the current state of the RPG with 0x00
		breq check_state                              ; if the state is 0x00, jump to check_state
		rjmp save_rpg_state                           ; if the state is not 0x00, jump to save_rpg_state

	; check_state:
	; 	- check the state of the RPG
	;   - if the state is 0x80, jump to cw_check  (10000000 - A is high)
	;   - if the state is 0x40, jump to ccw_check (01000000 - B is high
	;   - otherwise, jump to save_rpg_state
	check_state:
		cpi RPGpreviousState, 0x80                    ; compare the previous state of the RPG with 0x80
		breq cw_check                                  ; if the previous state is 0x80, jump to cw_check
		cpi RPGpreviousState, 0x40                    ; compare the previous state of the RPG with 0x40
		breq ccw_check                                ; if the previous state is 0x40, jump to ccw_check
		rjmp save_rpg_state                               ; if the previous state is not 0x80 or 0x40, jump to save_rpg_state

	; ccw_check:
	; 	- check the state of the RPG
	;   - if the state is 0x00, jump to counter_clockwise
	;   - otherwise, jump to ret
	ccw_check:
		cpi RPGstate, 0x00                            ; compare the current state of the RPG with 0x00
		breq counter_clockwise                        ; if the current state is 0x00, jump to counter_clockwise
		ret                                           ; if the current state is not 0x00, jump to ret

	; cw_check:
	; 	- check the state of the RPG
	;   - if the state is 0x00, jump to clockwise
	;   - otherwise, jump to ret
	cw_check:
		cpi RPGstate, 0x00                            ; compare the current state of the RPG with 0x00
		breq clockwise                                ; if the current state is 0x00, jump to clockwise
		ret                                           ; if the current state is not 0x00, jump to ret

	; counter_clockwise:
	; 	- check the state of the RPG
	;   - if the state is 0x40, jump to save_state
	;   - otherwise, jump to ret
	;   - note - if the current value displayed is '0', and the user continues to rotate clockwise, remain at 0
	counter_clockwise:
		cpi r16, 0x40                                 ; compare the current state of the RPG with 0x40
		breq save_state                               ; if the current state is 0x40, jump to save_state
		dec r17                                       ; decrement the value of r17
		cpi r17, 0xff                                 ; compare the value of r17 with 0xff
		breq display_min_bound                        ; if the value of r17 is 0xff, jump to display_min_bound
		rjmp save_rpg_state                           ; if the value of r17 is not 0xff, jump to save_rpg_state

	; clockwise:
	; 	- check the state of the RPG
	;   - if the state is 0x40, jump to firstMovement
	;   - otherwise, jump to ret
	;   - note - if the current value displayed is 'f', and the user continues to rotate clockwise, remain at 'f'
	clockwise:
		cpi r16, 0x40                                 ; compare the current state of the RPG with 0x40
		breq first_movement                           ; if the current state is 0x40, jump to first_movement
		inc r17                                       ; increment the value of r17
		cpi r17, 0x10                                 ; compare the value of r17 with 0x10
		breq display_max_bound                        ; if the value of r17 is 0x10, jump to display_max_bound
		rjmp save_rpg_state                               ; if the value of r17 is not 0x10, jump to save_rpg_state

	; first_movement:	
	; 	- set the value of r17 to 0
	;   - jump to save_rpg_state
	first_movement:
		ldi r17, 0x00                                 ; set the value of r17 to 0
		rjmp save_rpg_state                           ; jump to save_rpg_state

	; display_min_bound:
	; 	- set the value of r17 to 0
	;   - jump to save_rpg_state
	display_min_bound:
		ldi r17, 0x00                                 ; set the value of r17 to 0
		rjmp save_rpg_state                           ; jump to save_rpg_state

	; display_max_bound:
	; 	- set the value of r17 to 0xf
	;   - jump to save_rpg_state
	display_max_bound:
		ldi r17, 0x0f                                 ; set the value of r17 to 0xf
		rjmp save_rpg_state

	; save_rpg_state:
	; 	- save the current state of the RPG
	;   - move the current state of the RPG to the previous state
	;   - this is used to determine the direction of the rotation
	save_rpg_state:
		mov RPGpreviousState, RPGstate               ; move the current state of the RPG to the previous state

	; no_change:
	; 	- if the state has not changed, simply ret
	no_change:
		ret                                          ; return

; compute_current_seven_segment_hex:
; 	- find the value to be displayed on the 7-segment display
;   - lookup the value in the seven_segment_codes table
;   - load the value into r16
compute_current_seven_segment_hex:
	ldi ZL, low(seven_segment_codes << 1)            ; load the address of the seven_segment_codes table into ZL
	add ZL, r17                                      ; add the current value of r17 to ZL

; display_call:
; 	- display the current value on the 7-segment display
display_call:
	lpm r16, Z                                      ; load the value at Z into r16
	rcall display                                   ; call the display subroutine	
	ret                                             ; return

; display:
; 	- display the current value on the 7-segment display
;   - utilizes the stack to save the value of r16 and r17 and the status register
display:
	push r16                                        ; push the value of r16 onto the stack
	push r17                                        ; push the value of r17 onto the stack
	in r17, SREG                                    ; load the value of the status register into r17
	push r17                                        ; push the value of r17 onto the stack
	ldi r17, 8                                      ; load the value of 8 into r17
  
  ; rotate_bits:
  ;   - subroutine for 74hc595 shift register to shift in the value of the hex code to be displayed on the 7-segment display
  ;   - shift the value of r16 to the left
  ;   - if the carry flag is set, set the value of PORTB.0
  ;   - otherwise, clear the value of PORTB.0
  ;   - this runs 8 times to rotate all 8 bits of the hex code into the shift register
  rotate_bits:
    rol r16                                         ; rotate the value of r16 to the left
    brcs set_ser_in_1                               ; if the carry flag is set, jump to set_ser_in_1
    cbi PORTB, 0                                    ; otherwise, clear the value of PORTB.0
  	rjmp shift_register_out                         ; jump to shift_register_out

  ; set_ser_in_1:
  ;   - subroutine for 74hc595 shift register to shift in the value of the hex code to be displayed on the 7-segment display
  ;   - set the value of PORTB 0
  set_ser_in_1:
    sbi PORTB, 0

  ; shift_register_out:
  ;   - subroutine for 74hc595 shift register to shift in the value of the hex code to be displayed on the 7-segment display
  ;   - pulse rclk and srclk to shift in the value of the hex code to be displayed on the 7-segment display
  ;   - restore the values in registers pushed onto stack
  shift_register_out:
    sbi PORTB, 2                                    ; set portb 2
    cbi PORTB, 2                                    ; clear portb 2
    dec r17                                         ; decrement the value of r17
    brne rotate_bits                                ; if the value of r17 is not 0, jump to rotate_bits
    sbi PORTB, 1                                    ; set portb 1
    cbi PORTB, 1                                    ; clear portb 1
	pop r17                                         ; pop the value of r17 from the stack
	out SREG, r17                                   ; restore the value of the status register
	pop r17                                         ; pop the value of r17 from the stack
	pop r16                                         ; pop the value of r16 from the stack
	ret                                             ; return

; delay:
;   - delay for 500 microseconds
delay:
	in tmp1,TCCR0B                                  ; load the value of TCCR0B into tmp1
	ldi tmp2,0x00                                   ; load the value of 0x00 into tmp2
	out TCCR0B,tmp2                                 ; load the value of tmp2 into TCCR0B
	in tmp2,TIFR0                                   ; load the value of TIFR0 into tmp2
	sbr tmp2,1<<TOV0                                ; set the value of TOV0 in tmp2
	out TIFR0,tmp2                                  ; load the value of tmp2 into TIFR0
	out TCNT0,count                                 ; load the value of count into TCNT0
	out TCCR0B,tmp1                                 ; load the value of tmp1 into TCCR0B

	; wait:
	;   - wait for the value of TOV0 to be set
	wait:
		in tmp2,TIFR0                               ; load the value of TIFR0 into tmp2
		sbrs tmp2,TOV0                              ; skip if TOV0 is set
		rjmp wait                                   ; jump to wait if TOV0 is not set
		ret                                         ; return