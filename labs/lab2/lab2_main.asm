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
sbi DDRB, 0         
sbi DDRB, 1         
sbi DDRB, 2         
cbi DDRB, 3         

ldi R20, 0; this register is going to be used to track the state that the button is in (been pressed or not)

numberloop:
  cpi R20, 0; compare register R20 with 0 to see if it has been pressed
  brne increment; branch to increment loop if the button has been pressed

display0:
  ldi R16, 0x3f; display 0		
  rjmp displaydigit; relative jump to display and digit check

ButtonCheck:
  sbic PINB, 3; skip if button is pressed (if line is low skip) (a button press makes the line low)
  ret;(button not pressed jump back to display loop for 0)
WaitForRelease:
  sbis PINB, 3; skip if the button has been released (line is back to high)
  rjmp WaitForRelease;
  ldi R20, 1; set the register that keeps track of if the button was pressed to 1
  rjmp numberloop; when button is pressed we move into the increment mode

displaydigit:
  rcall display; display number loaded into the register
  rcall ButtonCheck; check if the button has been pressed
  rjmp numberloop; jump back to number loop, the ButtonCheck subroutine has routed back to here if button is not pressed

increment:
	ldi R16, 0x06; 1
	rcall displaydigitincrement;
	ldi R16, 0x5b; 2
	rcall displaydigitincrement;
	ldi R16, 0x4f; 3
	rcall displaydigitincrement;
	ldi R16, 0x66; 4
	rcall displaydigitincrement;
	ldi R16, 0x6d; 5
	rcall displaydigitincrement;
	ldi R16, 0x7d; 6
	rcall displaydigitincrement;
	ldi R16, 0x07; 7
	rcall displaydigitincrement;
	ldi R16, 0x7f; 8
	rcall displaydigitincrement;
	ldi R16, 0x6f; 9
	rcall displaydigitincrement;
	ldi R16, 0x77; A
	rcall displaydigitincrement;
	ldi R16, 0x7c; b
	rcall displaydigitincrement;
	ldi R16, 0x39; C
	rcall displaydigitincrement;
	ldi R16, 0x5e; d
	rcall displaydigitincrement;
	ldi R16, 0x79; E
	rcall displaydigitincrement;
	ldi R16, 0x71; f
	rcall displaydigitincrement;
	ldi R16, 0x3f; 0
	rcall displaydigitincrement;
	rjmp increment; jump back to the top to continue the increment mode

displaydigitincrement:
	rcall display; display number
	rcall delay; delay to see the number
	ret; return to where subroutine was called	

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

delay:
	ldi r30, 0x10       ; 
	ldi r31, 0xd0       ; 208 (11010000)

  ; Delay Outer
  delay_outer:
    ldi r29, 0x57     

  ; Delay Inner
  delay_inner: 
      nop
      dec r29
      brne delay_inner
      sbiw r31:r30, 1
      brne delay_outer
ret
