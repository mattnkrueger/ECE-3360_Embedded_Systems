; ---- main.asm (Embedded Systems Lab 2 - Spring 2025)
; 
; Purpose:
;   This Assembly file contains functionality for a 7-Segment display controlled by a 74hc595 shift register IC. 
;   Additional functionality is implemented via an active-low push button. The 7-Segment displays a sequence of hexidecimal numbers.
;
;   Functionality of the 7-Segment display:
;       1. increment count (0,1,..,e,f)
;       2. decrement count (f,e,..,1,0)
;       3. reset count (show 0)
;
; Authors:
;   - Sage Marks
;   - Matt Krueger


; ---- I/O Configuration
;
;   port assignments:
;       SER <- PB0 (output)
;       RCLK <- PB1 (output)
;       SRCLK <- PB2 (output)
;       PBTN -> PB3 (input)
;       PBTN pull-up resistor <- PB3 (output)
sbi DDRB, 0         
sbi DDRB, 1         
sbi DDRB, 2         
cbi DDRB, 3         
sbi PORTB, 3        

; ---- Increment loop
;
;   Cycle through hexidecimal digits in ascending order 
; 
;   For each value:
;       1. load the digit
;       2. delay before showing digit
;       3. display the digit
;
;   rcall is used to track progress of sequence on stack
increment_loop:
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
rjmp increment_loop;

; ---- Display
;
;   Output hexidecimal bit representation to 7-Segment display utilizing stack and 74hc595 shift register for storage
display:
  push R16
  push R17
  in R17, SREG
  push R17
  ldi R17, 8
  
  ; Loop
  loop:
    rol R16
    BRCS set_ser_in_1
    cbi PORTB, 0
  rjmp end

  ; Set SER Input High
  set_ser_in_1:
    sbi PORTB, 0

  ; End
  end:
    sbi PORTB, 2
    cbi PORTB, 2
    dec R17
    brne loop
    sbi PORTB, 1
    cbi PORTB, 1

  pop R17
  out SREG, R17
  pop R17
  pop R16
ret

; ---- Delay
;
;   Execute a brief pause to give 7-Segment display time before switching hexidecimal output
;   
;   Approx. 24,675,000 cycles | 1.5 seconds
delay:
	ldi r30, 0x20       ; 32  (00100000)
	ldi r31, 0xd0       ; 208 (11010000)

  ; Delay Outer
  delay_outer:
    ldi r29, 0x73     ; 115 (01110011)

  ; Delay Inner
  delay_inner: 
      nop
      dec r29
      brne delay_inner
      sbiw r31:r30, 1
      brne delay_outer
ret
