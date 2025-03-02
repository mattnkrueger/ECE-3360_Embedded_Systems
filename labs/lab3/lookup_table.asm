.cseg
.org 0x0000

sbi DDRB, 0         
sbi DDRB, 1         
sbi DDRB, 2         
cbi DDRB, 3  

lookup_table:
.dB 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07; 0-7
.dB 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71; 8-f

PowerOn:; only leave this loop when the RPG is rotated CW
ldi r16, 0x40; displays a dash
rcall display
rjmp PowerOn

findValue:
	ldi ZL, low(lookup_table << 1); use of lpm requires multiplication of byte address by 2
	add ZL, r17; puts us at the correct address to use lookup table
displayCall:
	lpm r16, Z; loads the value from program memory(LUT) to register r16
	rcall display;
	rjmp findValue;








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
