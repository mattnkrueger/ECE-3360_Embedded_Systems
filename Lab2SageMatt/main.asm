; main.asm (Lab2)
; 
; purpose:
;   This Assembly file contains functionality for a 7-Segment display controlled by a 74hc595 shift register IC. 
;   Additional functionality is implemented via an active-low push button. The 7-Segment displays a sequence of hexidecimal numbers.
;
;   Functionality of the 7-Segment display:
;       1. increment count (0,1,..,e,f)
;       2. decrement count (f,e,..,1,0)
;       3. reset count (show 0)
;
; authors:
;   - Sage Marks
;   - Matt Krueger

; Assign i/o from Arduino Uno 
sbi DDRB, 0         ;		SER <- PB0 (output)
sbi DDRB, 1         ;		RCLK <- PB1 (output)
sbi DDRB, 2         ;		SRCLK <- PB2 (output)
cbi DDRB, 3         ;		PBTN -> PB3 (input)
sbi PORTB, 3        ;		PBTN pull-up resistor <- PB3 (output)

; increment loop
;   cycle through hexidecimal digits in ascending order 
; 
;   for each value:
;       load the digit
;       delay before showing digit
;       display the digit
;
;   rcall is used to track progress of sequence on stack
incrementloop:
  ; 0
  ldi R16, 0x3f		
  rcall delay		
  rcall display		

  ; 1
  ldi R16, 0x06
  rcall delay
  rcall display

  ; 2
  ldi R16, 0x5b
  rcall delay
  rcall display

  ; 3
  ldi R16, 0x4f
  rcall delay
  rcall display

  ; 4
  ldi R16, 0x66
  rcall delay
  rcall display

  ; 5
  ldi R16, 0x6d
  rcall delay
  rcall display

  ; 6
  ldi R16, 0x7d
  rcall delay
  rcall display

  ; 7
  ldi R16, 0x07
  rcall delay
  rcall display

  ; 8
  ldi R16, 0x7f
  rcall delay
  rcall display

  ; 9
  ldi R16, 0x6f
  rcall delay
  rcall display

  ; A
  ldi R16, 0x77
  rcall delay
  rcall display

  ; B
  ldi R16, 0x7c
  rcall delay
  rcall display

  ; C
  ldi R16, 0x39
  rcall delay
  rcall display

  ; D
  ldi R16, 0x5e
  rcall delay
  rcall display

  ; E
  ldi R16, 0x79
  rcall delay
  rcall display

  ; F
  ldi R16, 0x71
  rcall delay
  rcall display
rjmp incrementloop;

; display
;   output hexidecimal bit representation to 7-Segment display
display:
  push R16
  push R17
  in R17, SREG
  push R17
  ldi R17, 8;			loop --> test all 8 bits
  
  ; loop 
  ; 
  loop:
    rol R16;			rotate left through Carry (checks the value of the carry)
    BRCS set_ser_in_1;	branch if Carry is set (carry is a 1)
    cbi PORTB, 0;		sets the SER data pin low
  rjmp end

  ; set_ser_in_1
  ;
  set_ser_in_1:
    sbi PORTB, 0;		sets the SER data pin high

  ; end
  ;
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

; delay
;   execute a brief pause to give 7-Segment display time before switching hexidecimal output
;   
;   approx. 24,675,000 cycles | 1.5 seconds
delay:
	ldi r30, 0x20       ; 32  (00100000)
	ldi r31, 0xd0       ; 208 (11010000)

  ; delay_outer
  delay_outer:
    ldi r29, 0x73     ; 115 (01110011)

  ; delay_inner
  delay_inner: 
      nop
      dec r29
      brne delay_inner
      sbiw r31:r30, 1
      brne delay_outer
ret
