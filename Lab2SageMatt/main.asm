;					Declare I/O pins as input and output
sbi DDRB, 0;		sets PB0 to output for SER
sbi DDRB, 1;		sets PB1 to output for RCLK
sbi DDRB, 2;		sets PB2 to output for SRCLK
cbi DDRB, 3;		sets PB3 to input for push button signal
sbi PORTB, 3;		enables the internal pull up resistor for PB3 (push button switch)

;					display a digit
;					increment mode
incrementloop:
ldi R16, 0x3f;		load 0
rcall display;		display 0
rcall delay;		delay to show 0
ldi R16, 0x06;		load 1
rcall display;		display 1
rcall delay;		delay to show 1
ldi R16, 0x5b;		load 2
rcall display;		display 2
rcall delay;		delay to show 2
ldi R16, 0x4f;		load 3
rcall display;		display 3
rcall delay;		delay to show 3
ldi R16, 0x66;		load 4
rcall display;		display 4
rcall delay;		delay to show 4
ldi R16, 0x6d;		load 5
rcall display;		display 5
rcall delay;		delay to show 5
ldi R16, 0x7d;		load 6
rcall display;		display 6
rcall delay;		delay to show 6
ldi R16, 0x07;		load 7
rcall display;		display 7
rcall delay;		delay to show 7
ldi R16, 0x7f;		load 8
rcall display;		display 8
rcall delay;		delay to show 8
ldi R16, 0x6f;		load 9
rcall display;		display 9
rcall delay;		delay to show 9
ldi R16, 0x77;		load A
rcall display;		display A
rcall delay;		delay to show A
ldi R16, 0x7c;		load b
rcall display;		display b
rcall delay;		delay to show b
ldi R16, 0x39;		load c
rcall display;		display c
rcall delay;		delay to show c
ldi R16, 0x5e;		load d
rcall display;		display d
rcall delay;		delay to show d
ldi R16, 0x79;		load e
rcall display;		display e
rcall delay;		delay to show e
ldi R16, 0x71;		load f
rcall display;		display f
rcall delay;		delay to show f
rjmp incrementloop; infinite loop
 

display:
					; backup used registers on stack
push R16
push R17
in R17, SREG
push R17
ldi R17, 8;			loop --> test all 8 bits
loop:
rol R16;			rotate left through Carry (checks the value of the carry)
BRCS set_ser_in_1;	branch if Carry is set (carry is a 1)
cbi PORTB, 0;		sets the SER data pin low
rjmp end
set_ser_in_1:
sbi PORTB, 0;		sets the SER data pin high
end:
sbi PORTB, 2;		pulses the shift register clock high
cbi PORTB, 2;		pulses the shift register clock low
dec R17;			decrements the register with a value of 8 to iterate through all bits
brne loop;			branches back to loop unless R17 value is 0
sbi PORTB, 1;		pulses the register storage clock high
cbi PORTB, 1;		register storage clock is now low
;					restore registers from stack
pop R17;			last in first out (stack)
out SREG, R17
pop R17
pop R16
ret

delay: ;			loop that creates a delay so we can see numbers shift
;					similar to loop from lab 1
	ldi r30, 0x20;
	ldi r31, 0xd0;
d1:
	ldi r29, 0x73;
d2: 
	nop;
	dec r29;
	brne d2;
	sbiw r31:r30, 1;
	brne d1;
	ret;
