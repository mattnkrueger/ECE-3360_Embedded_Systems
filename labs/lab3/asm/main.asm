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
.def tmp1 = r23  	 	 	 	 	 	 	 	 	; temporary variables 1 
.def tmp2 = r24  	 	 	 	 	 	 	 	    ; temporary variablues 2
.def count = r22	 	 	 	 	 	 	 	 	; count of loops for timer delay
.def rpg_current_state = r21                     	; current state of RPG
.def rpg_previous_state = r20            		    ; register to hold previous state of RPG

; register aliases 16..19 were redacted for clarity as they are not as consistently throughout the program.
; these registers are used to track the two LUTs, however during some subroutines their function is more ambiguous.

; power_on:
;   ENTRY POINT OF THE PROGRAM
;   - initializes the timer and rpg before jumping to reset_program
;   - additionally initializes the password index to 0 and the password correctness flag to 1 (this fixes bug where the first program loop never works)
power_on:
	rcall setup_timer								
	rcall setup_rpg
	ldi r19, 0x00    
	ldi tmp1, 1       
	mov r0, tmp1      
	rjmp start_program

; setup_rpg:
;   INITIALIZE THE ROTARY PULSE GENERATOR
;   - load PIND into rpg_previous_state (76......)
;   - mask all other bits beside wanted RPG bits 6 and 7 
setup_rpg:
	in rpg_previous_state, PIND 	              	    
	andi rpg_previous_state, 0xC0                   
	ret

; setup_timer:
;    INITIALIZE TIMER0 
; 	- Timer/Counter setup for 500 μs delay
;   - 8-bit timer, so we need to set the prescalar to 64
;   - atmega328p has a CPU clock speed of 16 MHz, so 
;          		16,000,000/64 = 250,000
;           	1/250,000 = 4 μs per cycle
;   - setting count of loops to 131, we have 125 more loops to 
;     reach max 8 bit value of 255. 
;           	125 * 4 μs = 500 μs
;
;   TCNT0: timer counter
;   TCCR0B: timer/counter control register (CS02:00 = 011 -> fclk/64)
setup_timer:
	ldi count, 0x83 		 	 	 	 	 	 	
	ldi tmp1, (1<<CS01)|(1<<CS00)
	out TCNT0, count 	 	 	 	 	 	
	out TCCR0B, tmp1 	 	 	 	 	 
	ret

; start_program:
;   INITIAL DISPLAY 
;   - initialize the 7-segment display, call rpg check, and display number
;   - dislpay a dash on the 7-segment display "-" (0x40)
start_program:
	ldi r16, 0x40            	 	 	 	 	 	
	rcall display 	 	 	 	 	 	 	 	 	
	rcall rpg_check									
	cpi r17, 0x00									
	breq program_loop 						    
	rjmp start_program

; program_loop:
;   MAIN PROGRAM LOOP
;   - update the value to be displayed on the 7-segment display via rpg interaction
;   - checks for button press & duration, and compares with password or resets program (after 5 button clicks, code is either correct & LED shines or incorrect and program resets after 7 seconds)
program_loop:
	rcall compute_current_seven_segment_hex
	rcall rpg_check 

	; button_check:
	;   BUTTON LISTENER
	; 	- if the pushbutton is pressed for <1 second, add current value stored in r17 to password value
	;   - if the pushbutton is pressed for 1<t<2 seconds, do nothing
	; 	- if the pushbutton is pressed for >2 second, reset the password value
	button_check:
		sbic PINB, 3 	 	  	 	 	 	 	 	  
		rjmp program_loop                           
        
	; less_than_one:
	; 	- pressed less than 1 second second, compare value with password digit 
	;   - loops 0000011111010000 (2000) 2000 times * 500 microseconds = 1 second
	less_than_one:
		ldi R26, 0xd0		                         
		ldi R27, 0x07								 

        ; less_than_one_loop:
		;   - loop contained in less_than_one subroutine
		less_than_one_loop:                          
			rcall timer_delay_500us                  
			sbiw R27:R26, 1						     
			breq one_to_two                          
			sbis PINB, 3                             
			rjmp less_than_one_loop		             
			rjmp compute_hex_at_password_index                           

	; one_to_two:
	; 	- pressed 1<t<2 seconds, do nothing
	;   - identical to less_than_one subroutine, but does not do anything if button is pressed
	;   - loops 0000011111010000 (2000) 2000 times * 500 microseconds = 1 second (we already know that the less than one loop has been completed)
	one_to_two:
		ldi R26, 0xd0		                         
		ldi R27, 0x07								 

		; one_to_two loop:
		;   - loop contained in one_to_two subroutine
		one_to_two_loop:
			rcall timer_delay_500us                  
			sbiw R27:R26, 1						     
			breq greater_than_two                    
			sbis PINB, 3                             
			rjmp one_to_two_loop		             
			rjmp program_loop                      

	; greater_than_two:
	; 	- pressed >2 seconds, reset the password value
	;   - we know that 2 seconds has already elapsed while the user is pressing the button
	;   - simply wait until the button is released, and then reset the program 
	greater_than_two:
		sbis PINB, 3 							     
		rjmp greater_than_two                        
		rjmp reset_program                              

    ; compute_hex_at_password_index:
	;   TRAVERSE THE PASSWORD LOOKUP TABLE
	;   - load the value of the password at the current index
	;   - compare with the user's selected digit
	;   - if the values are equal, jump to correct_value_at_index
	;   - otherwise, continue to incorrect_value_at_index
    compute_hex_at_password_index:
		ldi ZL, low(password_codes << 1)             
		add ZL, r19                                  
		lpm r18, Z                                   
        cp r17, r18                                  
		breq correct_value_at_index                           
 
		; incorrect_value_at_index:
		;   USER PASSWORD IS INCORRECT
		; 	- increment the index of the password lookup table
		;   - set r0 to 0 (this functions as a flag to indicate that the user's	code is incorrect)
		;   - if the index of the password lookup table is 5, jump to incorrect_code_display
		;   - else, jump to program_loop to continue current attempt
		incorrect_value_at_index:
			inc r19                                  
			ldi tmp1, 0                              
			mov r0, tmp1                             
			cpi r19, 0x05                            
			breq incorrect_password_display              
			rjmp program_loop                      
        
	; incorrect_password_display:
	;    DISPLAY IF USER ENTERS INCORRECT CODE
	; 	- display the incorrect code pattern "_"
	incorrect_password_display:
		ldi R26, 0xb0                                
		ldi R27, 0x36                                
		ldi r16, 0x08                                
		rcall display                                

		; incorrect_password_display_loop:
		; 	- display "_" for 7 seconds and then reset
		incorrect_password_display_loop:
			rcall timer_delay_500us                  
			sbiw R27:R26, 1                          
			breq reset_program                          
			rjmp incorrect_password_display_loop         
		
	; correct_value_at_index:
	;   USER VALUE AT INDEX IS CORRECT
	; 	- set r0 to 1 (this functions as a flag to indicate that the user's code is correct)
	;   - if r0 = 0, jump to incorrect_value_at_index 
	;   - else, continue to program_loop
    correct_value_at_index: 
		Mov tmp1, r0                                 
		cpi tmp1, 0                                  
		breq incorrect_value_at_index                         
    	inc r19                                      
        ldi tmp1, 1                                  
        mov r0, tmp1                                 
        cpi r19, 0x05                                
        breq check_password_correctness
		rjmp program_loop                          
        
    ; check_password_correctness:
	;   CHECK IF THE USER PASSWORD IS CORRECT 
	; 	- set r0 to 1 (this functions as a flag to indicate that the user's code is correct)
	;   - if r0 = 1, jump to LED_ON, else continue to reset_program
	;   - triggered after 5 button presses regardless of correctness
    check_password_correctness:
    	mov tmp1, r0                                 
        cpi tmp1, 0x01                               
        breq correct_password                        
        
    ; reset_program:
	;   RESET THE PROGRAM
	; 	- set r0 to 1 (true initially... user hasnt entered the wrong code yet)
	;   - reset the index of the password lookup table to 0
	;   - jump to power_on to restart the program
	;
	;   'ldi r17, 0x01'
	;   - no significance of 0x01 other than it isnt 0x00... needed to fix error when
	;	  restarting resetting at 0. Because r17 would be set to 0x00, it would branch 
	;     after the cpi in start_program, skipping the display of the "-". 
	;	  This fixes the issue; the user can now stay at "-" until rotary is moved cw.
    reset_program:
		ldi tmp1, 1                                  
		mov r0, tmp1                                 
		ldi r19, 0x00               
		ldi r17, 0x01                 
		rjmp power_on                                
        
    ; correct_password:
	;   
	; 	- display the LED on the arduino board
	;   - display a "." on the 7-segment display
	;   - only displayed if the user's code is correct
	;   - runs for 4 seconds
    correct_password:
    	ldi R26, 0x40                                
		ldi R27, 0x1f                                
    	sbi PORTB, 5                                 
		ldi r16, 0x80                                
		rcall display                                

		; correct_password_loop:
		; 	- display the LED on the arduino board for 4 seconds
		correct_password_loop:
			rcall timer_delay_500us                  
			sbiw R27:R26, 1                          
			breq  LED_off                            
			rjmp correct_password_loop               

		; LED_off:
		; 	- turn off the LED on the arduino board
		LED_off:
			cbi PORTB, 5                              
			rjmp reset_program                           

    ; rpg_check:
	; 	- check the state of the RPG
	;   - if the state has not changed, jump to no_change
	;   - otherwise, jump to check_state
	;   - rotary pulse generator has 3 pins: A, B, and C
	;   - A and B are used to determine the direction of the rotation
	;   - A and B are set to pin 6 and 7 of the arduino board
	;   - C is used to reset the program
    rpg_check:
		rcall timer_delay_500us                       
		in rpg_current_state, PIND                             
		andi rpg_current_state, 0xC0                           
		cp rpg_current_state, rpg_previous_state                 
		breq no_change                                
		cpi rpg_current_state, 0x00                            
		breq check_state                              
		rjmp save_rpg_state                           

	; check_state:
	; 	- check the state of the RPG
	;   - if the state is 0x80, jump to cw_check  (10000000 - A is high)
	;   - if the state is 0x40, jump to ccw_check (01000000 - B is high
	;   - otherwise, jump to save_rpg_state
	check_state:
		cpi rpg_previous_state, 0x80                    
		breq cw_check                                  
		cpi rpg_previous_state, 0x40                    
		breq ccw_check                                
		rjmp save_rpg_state                               

	; ccw_check:
	; 	- check the state of the RPG
	;   - if the state is 0x00, jump to counter_clockwise
	;   - otherwise, jump to ret
	ccw_check:
		cpi rpg_current_state, 0x00                            
		breq counter_clockwise                        
		ret                                           

	; cw_check:
	; 	- check the state of the RPG
	;   - if the state is 0x00, jump to clockwise
	;   - otherwise, jump to ret
	cw_check:
		cpi rpg_current_state, 0x00                            
		breq clockwise                                
		ret                                           

	; counter_clockwise:
	; 	- check the state of the RPG
	;   - if the state is 0x40, jump to save_rpg_state
	;   - otherwise, jump to ret
	;   - note - if the current value displayed is '0', and the user continues to rotate clockwise, remain at 0
	counter_clockwise:
		cpi r16, 0x40                                 
		breq save_rpg_state                               
		dec r17                                       
		cpi r17, 0xff                               
		breq display_min_bound                        
		rjmp save_rpg_state                           

	; clockwise:
	; 	- check the state of the RPG
	;   - if the state is 0x40, jump to firstMovement
	;   - otherwise, jump to ret
	;   - note - if the current value displayed is 'f', and the user continues to rotate clockwise, remain at 'f'
	clockwise:
		cpi r16, 0x40                                 
		breq first_movement                           
		inc r17                                       
		cpi r17, 0x10                               
		breq display_max_bound                        
		rjmp save_rpg_state                               

	; first_movement:	
	; 	- set the value of r17 to 0
	;   - jump to save_rpg_state
	first_movement:
		ldi r17, 0x00                                 
		rjmp save_rpg_state                           

	; display_min_bound:
	; 	- set the value of r17 to 0
	;   - jump to save_rpg_state
	display_min_bound:
		ldi r17, 0x00                                 
		rjmp save_rpg_state                           

	; display_max_bound:
	; 	- set the value of r17 to 0xf
	;   - jump to save_rpg_state
	display_max_bound:
		ldi r17, 0x0f                                 
		rjmp save_rpg_state

	; save_rpg_state:
	; 	- save the current state of the RPG
	;   - move the current state of the RPG to the previous state
	;   - this is used to determine the direction of the rotation
	save_rpg_state:
		mov rpg_previous_state, rpg_current_state               

	; no_change:
	;   RPG STATE HAS NOT CHANGED
	; 	- if this code block is reached, simply return
	no_change:
		ret                                          

; compute_current_seven_segment_hex:
;   TRAVERSE THE SEVEN SEGMENT DISPLAY LOOKUP TABLE
; 	- find the value to be displayed on the 7-segment display
;   - lookup the value in the seven_segment_codes table
;   - load the value into r16
compute_current_seven_segment_hex:
	ldi ZL, low(seven_segment_codes << 1)            
	add ZL, r17                                      

; display_call:
;   DISPLAY THE VALUE ON THE 7-SEGMENT DISPLAY (driver)
; 	- calls the function display after loading z into r16 (current hex code) before returning to loop
display_call:
	lpm r16, Z                                      
	rcall display                                   
	ret                                             

; display:
;   DISPLAY THE VALUE ON THE 7-SEGMENT DISPLAY
; 	- display the current value on the 7-segment display
;   - utilizes the stack to save the value of r16 and r17 and the status register
display:
	push r16                                        
	push r17                                        
	in r17, SREG                                    
	push r17                                        
	ldi r17, 8                                      
  
  ; rotate_bits:
  ;   SERIAL INPUT OF DATA TO 74HC595 SHIFT REGISTER
  ;   - subroutine for 74hc595 shift register to shift in the value of the hex code to be displayed on the 7-segment display
  ;   - shift the value of r16 to the left
  ;   - if the carry flag is set, set the value of PORTB.0
  ;   - otherwise, clear the value of PORTB.0
  ;   - this runs 8 times to rotate all 8 bits of the hex code into the shift register
  rotate_bits:
    rol r16                                         
    brcs set_ser_in_1                               
    cbi PORTB, 0                                    
  	rjmp shift_register_out                         

  ; set_ser_in_1:
  ;   PULSE 1 TO SERIAL INPUT OF 74HC595 SHIFT REGISTER
  ;   - subroutine for 74hc595 shift register to shift in the value of the hex code to be displayed on the 7-segment display
  ;   - set the value of PORTB 0
  set_ser_in_1:
    sbi PORTB, 0

  ; shift_register_out:
  ;   OUTPUT DATA TO 74HC595 SHIFT REGISTER
  ;   - subroutine for 74hc595 shift register to shift in the value of the hex code to be displayed on the 7-segment display
  ;   - pulse srclk and rclk to shift in the value of the hex code to be displayed on the 7-segment display. 
  ;   - first shifts all digits in from r16 using rotate_bit loop, then stores them (upon storage, because OE active, there is output from shift register... electrical circuit handles the rest).
  ;   - restore the values in registers pushed onto stack
  shift_register_out:
    sbi PORTB, 2                                    
    cbi PORTB, 2                                    
    dec r17                                         
    brne rotate_bits                                
    sbi PORTB, 1                                    
    cbi PORTB, 1                                    
	pop r17                                         
	out SREG, r17                                   
	pop r17                                         
	pop r16                                         
	ret                                             

;timer_delay_500us:
;   DELAY FOR 500 MICROSECONDS 
;   - delay for 500 microseconds using timer0 of the atmega328p
;   
;	relevant registers:
;		- TCCR0: timer counter control register - setting modes of timer/counter
;       - TIFR0: timer counter interrupt flag register - if TOV0 set (1), then the timer is overflown
; 		- TCNT0: timer counter register - counts up with each pulse to the value loaded into it
timer_delay_500us:
	in tmp1, TCCR0B                                  
	ldi tmp2, 0x00                                   
	out TCCR0B, tmp2                                 
	in tmp2, TIFR0                                   
	sbr tmp2, 1<<TOV0                                
	out TIFR0, tmp2                                  
	out TCNT0, count                                 
	out TCCR0B, tmp1                                 

	; wait_for_overflow:
	;   - wait for the value of TOV0 to be set (overflown)
	wait_for_overflow:
		in tmp2, TIFR0                               
		sbrs tmp2, TOV0                              
		rjmp wait_for_overflow                                   
		ret                                         
