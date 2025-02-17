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

ldi R21, 0; this register keeps track of the number being displayed in decimal
ldi R22, 0; this register keeps track of if the register is in increment or decrement mode (0=increment) (1=decrement)
ldi R23, 0; 0 means it has not rolled over, 1 means it has rolled over for increment
ldi R26, 0xe8; this and register 29 are used to keep track of amount of time button is pressed for 
ldi R27, 0x03; this and register 28 are used to keep track of amount of time button is pressed for
;R27:R26 gives a value of 1000, the delay loop is 1 ms so that if you go through the delay loop 1000 times it has been 1 second
;delay loop is 1 ms so we check the button ~every milisecond


IncNumberCheck:
  rcall ButtonCheck;
  sbrc R22, 0;
  rjmp DecNumberCheck;
  cpi R21, 0x00;
  breq disp0;
  cpi R21, 0x01;
  breq disp1;
  cpi R21, 0x02;
  breq disp2;
  cpi R21, 0x03;
  breq disp3
  cpi R21, 0x04;
  breq disp4;
  cpi R21, 0x05;
  breq disp5;
  cpi R21, 0x06;
  breq disp6;
  cpi R21, 0x07;
  breq disp7;
  cpi R21, 0x08;
  breq disp8;
  cpi R21, 0x09;
  breq disp9;
  cpi R21, 0x0a;
  breq dispA;
  cpi R21, 0x0b;
  breq dispb;
  cpi R21, 0x0c;
  breq dispC;
  cpi R21, 0x0d;
  breq dispd;
  cpi R21, 0x0e;
  breq dispE;
  cpi R21, 0x0f;
  breq dispf;
  rjmp IncNumberCheck;


;check value of number
; if equal display if not jump
;check for button press
;check value of next number
;if equal go to specific number display if not jump
;rjmp back to number check

disp0:
  ldi R16, 0x3f;
  rjmp IncDisp;
disp1:
  ldi R16, 0x06; 1
  rjmp IncDisp;
disp2:
  ldi R16, 0x5b; 2
  rjmp IncDisp;
disp3:
  ldi R16, 0x4f; 3
  rjmp IncDisp;
disp4:
  ldi R16, 0x66; 4
  rjmp IncDisp;
disp5:
  ldi R16, 0x6d; 5
  rjmp IncDisp;
disp6:
  ldi R16, 0x7d; 6
  rjmp IncDisp;
disp7:
  ldi R16, 0x07; 7
  rjmp IncDisp;
disp8:
  ldi R16, 0x7f; 8
  rjmp IncDisp;
disp9:
  ldi R16, 0x6f; 9
  rjmp IncDisp;
dispA:	
  ldi R16, 0x77; A
  rjmp IncDisp;
dispb:
  ldi R16, 0x7c; b
  rjmp IncDisp;
dispC:
  ldi R16, 0x39; C
  rjmp IncDisp;
dispd:
  ldi R16, 0x5e; d
  rjmp IncDisp;
dispE:
  ldi R16, 0x79; E
  rjmp IncDisp;
dispf:
  ldi R16, 0x71; f
  rjmp IncDisp;

IncDisp:
  rcall display;
  rjmp IncNumberCheck;

DecNumberCheck: 
  rcall ButtonCheck;
  sbrs R22, 0;
  rjmp IncNumberCheck;
  cpi R21, 0x00;
  breq disp0Dec;
  cpi R21, 0x01;
  breq disp1Dec;
  cpi R21, 0x02;
  breq disp2Dec;
  cpi R21, 0x03;
  breq disp3Dec;
  cpi R21, 0x04;
  breq disp4Dec;
  cpi R21, 0x05;
  breq disp5Dec;
  cpi R21, 0x06;
  breq disp6Dec;
  cpi R21, 0x07;
  breq disp7Dec;
  cpi R21, 0x08;
  breq disp8Dec;
  cpi R21, 0x09;
  breq disp9Dec;
  cpi R21, 0x0a;
  breq dispADec;
  cpi R21, 0x0b;
  breq dispbDec;
  cpi R21, 0x0c;
  breq dispCDec;
  cpi R21, 0x0d;
  breq dispdDec;
  cpi R21, 0x0e;
  breq dispEDec;
  cpi R21, 0x0f;
  breq dispfDec;
  rjmp DecNumberCheck;

disp0Dec:
  ldi R16, 0xbf; 0 with decimal
  rjmp DispDec;
disp1Dec:
  ldi R16, 0x86; 1 with decimal
  rjmp DispDec;
disp2Dec:
  ldi R16, 0xdb; 2 with decimal
  rjmp DispDec;
disp3Dec:
  ldi R16, 0xcf; 3 with decimal
  rjmp DispDec;
disp4Dec:
  ldi R16, 0xe6; 4 with decimal
  rjmp DispDec;
disp5Dec:
  ldi R16, 0xed; 5 with decimal
  rjmp DispDec;
disp6Dec:
  ldi R16, 0xfd; 6 with decimal
  rjmp DispDec;
disp7Dec:
  ldi R16, 0x87; 7 with decimal
  rjmp DispDec;
disp8Dec:
  ldi R16, 0xff; 8 with decimal
  rjmp DispDec;
disp9Dec:
  ldi R16, 0xef; 9 with decimal
  rjmp DispDec;
dispADec:
  ldi R16, 0xf7; A with decimal
  rjmp DispDec;
dispbDec:
  ldi R16, 0xfc; b with decimal
  rjmp DispDec;
dispCDec:
  ldi R16, 0xb9; C with decimal
  rjmp DispDec;
dispdDec:
  ldi R16, 0xde; d with decimal
  rjmp DispDec;
dispEDec:
  ldi R16, 0xf9; E with decimal
  rjmp DispDec;
dispfDec:
  ldi R16, 0xf1; f with decimal
  rjmp DispDec;

DispDec:
  rcall display;
  rjmp DecNumberCheck;

ButtonCheck:
  sbic PINB, 3; skip if button is pressed (if line is low skip) (a button press makes the line low)
  ret;(button not pressed jump back to display loop)
ButtonPressLoop:
  rcall Delay;
  sbiw R27:R26, 1;
  breq OneToTwo;
  sbis PINB, 3; skip if the button has been released (line is back to high)
  rjmp ButtonPressLoop;
  cpi R22, 1;
  breq DecButtonCheck;
IncButtonCheck:
  cpi R21, 0x0f;
  breq rolloverInc;
  cpi R23, 1;
  breq WaitForRelease;
  inc R21;
  rjmp WaitForRelease;
rolloverInc:
  ldi R21, 0x00;
  ldi R23, 1;
  rjmp WaitForRelease
DecButtonCheck:
  cpi R21, 0x00;
  breq rolloverDec;
  cpi R23, 1;
  breq WaitForRelease;
  dec R21;
  rjmp WaitForRelease;
rolloverDec:
  ldi R21, 0x0f;
  ldi R23, 1;
  rjmp WaitForRelease;
OneToTwo:
  ;reset the counter
  ldi R26, 0xe8; resets counter to 1000 (1 second limit)
  ldi R27, 0x03; resets counter to 1000 (1 second limit)
  OneToTwoLoop:
    rcall Delay
    sbiw R27:R26, 1;
    breq TwoToThree;
    sbis PINB, 3; skip if the button has been released (line is back to high)
    rjmp OneToTwoLoop;
	cpi R23, 1;
	breq WaitForRelease;
    cpi R22, 1; if we are in decrement mode
    breq IncMode
    ldi R22, 1; switch to decrement mode
    rjmp WaitForRelease;
TwoToThree:
  ldi R23, 0;
  ldi R22, 0; reset, we are in increment mode
  ldi R21, 0; display 0
  rjmp WaitForRelease;
IncMode:; switch to increment mode
  ldi R22, 0;
WaitForRelease:
  sbis PINB, 3; skip if the button has been released (line is back to high)
  rjmp WaitForRelease;
  ldi R26, 0xe8; resets counter to 1000 (1 second limit)
  ldi R27, 0x03; resets counter to 1000 (1 second limit)
  ret;

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
ret;

;This delay loop lasts for about 1ms (check button every ms)
Delay:
	ldi r30, 0x5d	  	; r31:r30  <-- load a 16-bit value into counter register for outer loop
	ldi r31, 0x00;
d1:
	ldi   r29, 0x2a		    	; r29 <-- load a 8-bit value into counter register for inner loop
d2:
	nop				; no operation
	dec   r29            		; r29 <-- r29 - 1
	brne  d2			; branch to d2 if result is not "0"
	sbiw r31:r30, 1			; r31:r30 <-- r31:r30 - 1
	brne d1				; branch to d1 if result is not "0"
	ret;