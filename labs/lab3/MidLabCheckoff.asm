.cseg
.org 0x0000

sbi DDRB, 0; SER          
sbi DDRB, 1; RCLK          
sbi DDRB, 2; SRCLK         
cbi DDRB, 3; pushbutton signal
cbi DDRB, 4; A signal from RPG
cbi DDRB, 5; B signal from RPG  

lookup_table:
.db 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07; 0-7
.db 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71; 8-f

;initial RPG state
.def RPGpreviousState = r20
.def RPGstate = r21
in RPGpreviousState, PINB; load the values of PINB into the RPG previous state register
andi RPGpreviousState, 0x30;
ldi r17, 0xff;

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
	rcall delay;
	rcall RPGcheck;
	rjmp NumberDisplay;


RPGCheck:
	in RPGstate, PINB; loads current RPG state
	andi RPGstate, 0x30; mask all other bits besides RPG bits
	cp RPGstate, RPGpreviousState; compare current and previous RPG states
	breq no_change; branch if they are the same
	cpi RPGstate, 0x00
	breq CheckState
	rjmp Save_State
	CheckState:
		cpi RPGpreviousState, 0x20; check if the previous bit pattern is 10 (BA)
		breq CWcheck;
		cpi RPGpreviousState, 0x10; check if the previous bit pattern is 01 (BA)
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
	ldi ZL, low(lookup_table << 1); use of lpm requires multiplication of byte address by 2
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