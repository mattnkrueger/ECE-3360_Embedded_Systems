.cseg
.org 0x0000

; PORT B
sbi DDRB, 0; SER          
sbi DDRB, 1; RCLK          
sbi DDRB, 2; SRCLK         
cbi DDRB, 3; pushbutton signal
sbi DDRB, 5; LED on arduino board

; PORT D
cbi DDRD, 6; A signal from RPG
cbi DDRD, 7; B signal from RPG  


seven_segment_codes:
.db 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07; 0-7
.db 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71; 8-f

password_codes:
.db 0x0a, 0x0a, 0x05, 0x0c, 0x04, 0x00; Code digits AA5C4

; pointer aliases
.def hexPtr = r19 ; points to current hex value to be displayed in the 7-Segment
.def lockerPtr = r18 ; points to current hex value in the correct code 

; register aliases
.def sevenSegDisplay = r16 ; current hex pattern in 7-segment

;initial RPG state
.def RPGpreviousState = r20
.def RPGstate = r21
in RPGpreviousState, PIND; load the values of PINB into the RPG previous state register
andi RPGpreviousState, 0xC0;
ldi r17, 0xff;


ldi r19, 0x00;

;One time setup for a base timer delay of 500 microseconds
timerSetup:
	.def tmp1 = r23 ; Use r23 for temporary variables
	.def tmp2 = r24 ; Use r24 for temporary values
	.def count = r22; Use r22 for the count

	ldi count, 0x83;set timer to start at 131
	ldi tmp1, (1<<CS01)|(1<<CS00); set prescalar of fclk/64
	out TCNT0, count; load starting count value
	out TCCR0B, tmp1; load prescalar

PowerOn:
	ldi r16, 0x40; displays a dash
	rcall display;
	rcall delay;
	rcall RPGCheck;
	cpi r17, 0x00;
	breq NumberDisplay;
	rjmp PowerOn;

NumberDisplay:; loop that continuously displays values updated from the RPG
	rcall findvalue;
	rcall RPGcheck;
    
	ButtonCheck:
		sbic PINB, 3;				skip if button is pressed (if line is low skip) (a button press makes the line low)
		rjmp NumberDisplay;
        
	less_than_one:
		ldi R26, 0xd0;				this and register 29 are used to keep track of amount of time button is pressed for (initialized to decimal 2000 together)
		ldi R27, 0x07;				this and register 28 are used to keep track of amount of time button is pressed for (initialized to decimal 2000 together)
		looploop:
		rcall delay;
		sbiw R27:R26, 1;			subtract 1 from the registers that hold a value of 1000ms (1 second)
		breq one_to_two;
		sbis PINB, 3;				skip if the button has been released (line is back to high)
		rjmp looploop;		
		rjmp findCode

	one_to_two:
		ldi R26, 0xd0;				this and register 29 are used to keep track of amount of time button is pressed for (initialized to decimal 2000 together)
		ldi R27, 0x07;				this and register 28 are used to keep track of amount of time button is pressed for (initialized to decimal 2000 together)

		actual_loop:
		rcall delay;
		sbiw R27:R26, 1;			subtract 1 from the registers that hold a value of 1000ms (1 second)
		breq greater_than_two;
		sbis PINB, 3;				skip if the button has been released (line is back to high)
		rjmp actual_loop;		
		rjmp NumberDisplay

	greater_than_two:
		sbis PINB, 3 ; if still on
		rjmp greater_than_two
		rjmp reset_code

      
    findCode:
		ldi ZL, low(password_codes << 1); use of lpm requires multiplication of byte address by 2
		add ZL, r19; puts us at the correct address to use lookup table
		lpm r18, Z; loads value from lookup table into register r18
        cp r17, r18;
		breq correct_digit
	incorrect_digit:
        inc r19;
		ldi tmp1, 0; incorrect code
        MOV r0, tmp1
		cpi r19, 0x05;
		breq incorrect_code_display
        rjmp NumberDisplay;
        
	incorrect_code_display:
		ldi R26, 0xb0;				low byte, this and register 29 are used to keep track of amount of time button is pressed for (initialized to decimal 14000 together)
		ldi R27, 0x36;				high byte, this and register 28 are used to keep track of amount of time button is pressed for (initialized to decimal 14000 together)
		ldi r16, 0x08;
		rcall display;
		incorrect_code_display_loop:
		rcall delay
		sbiw R27:R26, 1;
		breq reset_code;
		rjmp incorrect_code_display_loop
		
    correct_digit:
		Mov tmp1, r0;
		cpi tmp1, 0
		breq incorrect_digit;
    	inc r19
        ldi tmp1, 1;
        MOV r0, tmp1;
        cpi r19, 0x05
        breq correct_code_check;
		rjmp NumberDisplay;
        
    correct_code_check:
    	MOV tmp1, r0;
        cpi tmp1, 0x01
        breq LED_ON;
        
    ; else continue
    reset_code:
		ldi r19, 0x00
		rjmp PowerOn;
        
    LED_ON:
    	ldi R26, 0x40;				this and register 29 are used to keep track of amount of time button is pressed for (initialized to decimal 2000 together)
		ldi R27, 0x1f;				this and register 28 are used to keep track of amount of time button is pressed for (initialized to decimal 2000 together)
    	sbi PORTB, 5; turns the LED on
		ldi r16, 0x80;
		rcall display;
    LED_on_loop:
		rcall delay;
    	sbiw R27:R26, 1;
        breq  LED_off;
        rjmp LED_on_loop;

	LED_off:
		cbi PORTB, 5;
		rjmp reset_code;

RPGCheck:
	rcall delay;
	in RPGstate, PIND; loads current RPG state
	andi RPGstate, 0xC0; mask all other bits besides RPG bits
	cp RPGstate, RPGpreviousState; compare current and previous RPG states
	breq no_change; branch if they are the same
	cpi RPGstate, 0x00
	breq CheckState
	rjmp Save_State
	CheckState:
		cpi RPGpreviousState, 0x80; check if the previous bit pattern is 10 (BA)
		breq CWcheck;
		cpi RPGpreviousState, 0x40; check if the previous bit pattern is 01 (BA)
		breq CCWCheck;
		rjmp Save_State;
	CCWCheck:
		cpi RPGstate, 0x00;
		breq CounterClockwise;
		ret;
	CWcheck:
		cpi RPGstate, 0x00;
		breq Clockwise;
		ret;
	CounterClockwise:
		cpi r16, 0x40;
		breq Save_State;
		dec r17;
		cpi r17, 0xff;
		breq stay0;
		rjmp Save_State;
	Clockwise:
		cpi r16, 0x40;
		breq firstMovement;
		inc r17; count is increased with clockwise rotation
		cpi r17, 0x10;
		breq stayF;
		rjmp Save_State;
	firstMovement:
		ldi r17, 0x00;
		rjmp Save_State;
	stay0:
		ldi r17, 0x00;
		rjmp Save_state;
	stayF:
		ldi r17, 0x0f;
	Save_State:
		mov RPGpreviousState, RPGstate;
	no_change:
		ret


findValue:
	ldi ZL, low(seven_segment_codes << 1); use of lpm requires multiplication of byte address by 2
	add ZL, r17; puts us at the correct address to use lookup table

displayCall:
	lpm r16, Z; loads the value from program memory(LUT) to register r16
	rcall display;
	ret;

display:
  push R16;				put registers on the stack (last in first out system)
  push R17
  in R17, SREG
  push R17
  ldi R17, 8;			Load 8 for 8 bits
  ; Loop
  
  loop:
    rol R16;			rotate left with carry (covers each bit)
    BRCS set_ser_in_1;  branch if the carry is set
    cbi PORTB, 0;		sets serial line to 0 (0 is the value of the bit being sent)
  rjmp end
  ; Set SER Input High
  set_ser_in_1:
    sbi PORTB, 0;		sets the serial line to 1 (1 is the value of the bit being sent)
  ; End
  end:
    sbi PORTB, 2;		sets SRCLK to high (cycles bit through the shift register)
    cbi PORTB, 2;		sets SRCLK to low (only cycles one bit at a time then it checks the carry bit)
    dec R17;			decrement R17 until it is 0
    brne loop;			branch to loop checking carry bit
    sbi PORTB, 1;		sets RCLK to high (puts bit values on output that goes to display)
    cbi PORTB, 1;		sets RCLK to low (so we can change 7 segment display when we call display again)
  pop R17;				take registers off the stack
  out SREG, R17
  pop R17
  pop R16
ret;

; Wait for TIMER0 to roll over.
delay:
	; Stop timer 0.
	in tmp1,TCCR0B ; Save configuration
	ldi tmp2,0x00 ; Stop timer 0
	out TCCR0B,tmp2
	; Clear overflow flag.
	in tmp2,TIFR0 ; tmp <-- TIFR0
	sbr tmp2,1<<TOV0 ; Clear TOV0, write logic 1
	out TIFR0,tmp2
	; Start timer with new initial count
	out TCNT0,count ; Load counter
	out TCCR0B,tmp1 ; Restart timer
	wait:
		in tmp2,TIFR0 ; tmp <-- TIFR0
		sbrs tmp2,TOV0 ; Check overflow flag
		rjmp wait
		ret


