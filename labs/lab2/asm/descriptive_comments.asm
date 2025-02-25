; Commands Used

; SBI: Set Bit in I/O Register
; - sets a specified bit in I/O register to 1
; - operates on the lower 32 I/O registers (0-31)

; CBI: Clear Bit in I/O Register
; - clears a specified bit in an I/O register
; - operates on the lower 32 I/O registers (0-31)

; LDI: Load Immediate
; - loads an 8-bit constant directly to register 16-31
; - 'immediate' is the constant to be loaded

; RCALL: Relative Call to Subroutine
; - relative call to address within PC - 2K + 1 to PC + 2K 
; - the return address is stored on the stack

; SBRC: Skip if Bit in Register is Cleared
; - tests a single bit in a register and skips the next instruction if the bit is cleared

; RJMP: Relative Jump
; - relative jump to an address within PC - 2K + 1 to PC + 2K 
; - return address is NOT stored on the stack

; CPI: Compare with Immediate
; - compare a register and a constant
; - the register is compared with the constant
; - after comparison, the zero flag (Z) is set if the two values are equal THUS the conditional branches can be used

; BREQ: Branch if Equal
; - conditional relative branch
; - tests the zero flag (Z) and branches relatively to PC if Z is set
; - used immediately after CP, CPI, SUB, or SUBI instructions
; - branch PC - 63 to PC + 64

; IN: Load an I/O Location to Register
; - loads data from the I/O space into register in the register file

; ROL - Rotate Left through Carry
; - shifts all bits in register one place to the left
; - the C flag is shifted into bit 0 of the register
; - bit 7 is shifted into the C flag

; BRCS: Branch if Carry Set
; - conditional relative branch
; - tests the carry flag (C) and branches relatively to PC if C is set

sbi DDRB, 0         ; set PB0 as output (Pin 8) 
sbi DDRB, 1         ; set PB1 as output (Pin 9)
sbi DDRB, 2         ; set PB2 as output (Pin 10)
cbi DDRB, 3         ; set PB3 as input (Pin 11)

ldi R21, 0          ; load 0 into R21
ldi R22, 0          ; load 0 into R22 
ldi R26, 0xe8       ; load 0xe8 into R26 (232)
ldi R27, 0x03       ; load 0x03 into R27 (3)

; Subroutine: IncNumberCheck
; - compares the value in R21 with a constant
; - if the value in R21 is equal to the constant, the corresponding value is displayed
IncNumberCheck:				
  rcall ButtonCheck   ; check if the button is pressed
  sbrc R22, 0         ; skip if R22 bit 0 is cleared
  rjmp DecNumberCheck ; skipped or jumped
  cpi R21, 0x00       
  breq disp0          
  cpi R21, 0x01       
  breq disp1          
  cpi R21, 0x02       
  breq disp2          
  cpi R21, 0x03
  breq disp3
  cpi R21, 0x04
  breq disp4
  cpi R21, 0x05
  breq disp5
  cpi R21, 0x06
  breq disp6
  cpi R21, 0x07
  breq disp7
  cpi R21, 0x08
  breq disp8
  cpi R21, 0x09
  breq disp9
  cpi R21, 0x0a
  breq dispA
  cpi R21, 0x0b
  breq dispb
  cpi R21, 0x0c
  breq dispC
  cpi R21, 0x0d
  breq dispd
  cpi R21, 0x0e
  breq dispE
  cpi R21, 0x0f
  breq dispf
  rjmp IncNumberCheck ; stay in IncNumberCheck (loop)

; Subroutines: Display
; - loads hex value in R16
; - jumps to IncDisp
disp0:
  ldi R16, 0x3f
  rjmp IncDisp
disp1:
  ldi R16, 0x06
  rjmp IncDisp
disp2:
  ldi R16, 0x5b
  rjmp IncDisp
disp3:
  ldi R16, 0x4f
  rjmp IncDisp
disp4:
  ldi R16, 0x66
  rjmp IncDisp
disp5:
  ldi R16, 0x6d
  rjmp IncDisp
disp6:
  ldi R16, 0x7d
  rjmp IncDisp
disp7:
  ldi R16, 0x07
  rjmp IncDisp
disp8:
  ldi R16, 0x7f
  rjmp IncDisp
disp9:
  ldi R16, 0x6f
  rjmp IncDisp
dispA:	
  ldi R16, 0x77
  rjmp IncDisp
dispb:
  ldi R16, 0x7c
  rjmp IncDisp
dispC:
  ldi R16, 0x39
  rjmp IncDisp
dispd:
  ldi R16, 0x5e
  rjmp IncDisp
dispE:
  ldi R16, 0x79
  rjmp IncDisp
dispf:
  ldi R16, 0x71
  rjmp IncDisp

; Subroutine: IncDisp
; - calls display subroutine 
; - jumps to IncNumberCheck
IncDisp:					
  rcall display
  rjmp IncNumberCheck

; Subroutine: DecNumberCheck
; - compares the value in R21 with a constant
; - if the value in R21 is equal to the constant, the corresponding value is displayed
DecNumberCheck:				
  rcall ButtonCheck   ; check if the button is pressed
  sbrs R22, 0         ; skip if R22 bit 0 is set
  rjmp IncNumberCheck ; skipped or jumped
  cpi R21, 0x00
  breq disp0Dec
  cpi R21, 0x01
  breq disp1Dec
  cpi R21, 0x02
  breq disp2Dec
  cpi R21, 0x03
  breq disp3Dec
  cpi R21, 0x04
  breq disp4Dec
  cpi R21, 0x05
  breq disp5Dec
  cpi R21, 0x06
  breq disp6Dec
  cpi R21, 0x07
  breq disp7Dec
  cpi R21, 0x08
  breq disp8Dec
  cpi R21, 0x09
  breq disp9Dec
  cpi R21, 0x0a
  breq dispADec
  cpi R21, 0x0b
  breq dispbDec
  cpi R21, 0x0c
  breq dispCDec
  cpi R21, 0x0d
  breq dispdDec
  cpi R21, 0x0e
  breq dispEDec
  cpi R21, 0x0f
  breq dispfDec
  rjmp DecNumberCheck

; Subroutines: Display Decrement
; - loads hex value in R16
; - jumps to DecDisp
disp0Dec:
  ldi R16, 0xbf
  rjmp DispDec
disp1Dec:
  ldi R16, 0x86
  rjmp DispDec
disp2Dec:
  ldi R16, 0xdb
  rjmp DispDec
disp3Dec:
  ldi R16, 0xcf
  rjmp DispDec
disp4Dec:
  ldi R16, 0xe6
  rjmp DispDec
disp5Dec:
  ldi R16, 0xed
  rjmp DispDec
disp6Dec:
  ldi R16, 0xfd
  rjmp DispDec
disp7Dec:
  ldi R16, 0x87
  rjmp DispDec
disp8Dec:
  ldi R16, 0xff
  rjmp DispDec
disp9Dec:
  ldi R16, 0xef
  rjmp DispDec
dispADec:
  ldi R16, 0xf7
  rjmp DispDec
dispbDec:
  ldi R16, 0xfc
  rjmp DispDec
dispCDec:
  ldi R16, 0xb9
  rjmp DispDec
dispdDec:
  ldi R16, 0xde
  rjmp DispDec
dispEDec:
  ldi R16, 0xf9
  rjmp DispDec
dispfDec:
  ldi R16, 0xf1
  rjmp DispDec

; Subroutine: DecDisp
; - calls display subroutine
; - jumps to DecNumberCheck
DispDec:
  rcall display
  rjmp DecNumberCheck

; Subroutine: ButtonCheck
; - checks if the button is pressed
; - returns if the button is pressed
ButtonCheck:
  sbic PINB, 3 ; skip if the button is not pressed
  ret
ButtonPressLoop:
  rcall Delay     
  sbiw R27:R26, 1 
  breq OneToTwo   
  sbis PINB, 3    
  rjmp ButtonPressLoop  
  cpi R22, 1
  breq DecButtonCheck
IncButtonCheck:
  inc R21
  cpi R21, 0x10
  breq rolloverInc
  rjmp WaitForRelease
rolloverInc:
  ldi R21, 0x00
  rjmp WaitForRelease
DecButtonCheck:
  dec R21
  cpi R21, 0xff
  breq rolloverDec
  rjmp WaitForRelease
rolloverDec:
  ldi R21, 0x0f
  rjmp WaitForRelease
OneToTwo:						
  ldi R26, 0xe8
  ldi R27, 0x03
  OneToTwoLoop:
    rcall Delay
    sbiw R27:R26, 1
    breq Reset
    sbis PINB, 3
    rjmp OneToTwoLoop
    cpi R22, 1
    breq IncMode
    ldi R22, 1
    rjmp WaitForRelease
Reset:
  ldi R22, 0
  ldi R21, 0
  rjmp WaitForRelease
IncMode:
  ldi R22, 0
WaitForRelease:
  sbis PINB, 3
  rjmp WaitForRelease
  ldi R26, 0xe8
  ldi R27, 0x03
  ret

; Subroutine: Display
; - Load 8-bit data (R16) representing the 7-segment display pattern.
; - Rotate left (ROL R16) to shift bits one by one into Carry.
; - Check Carry flag:
; - If 1, set PB0 (SER) high.
; - If 0, set PB0 (SER) low.
; - Pulse PB2 (SRCLK) to shift the bit into the register.
; - Repeat for 8 bits.
; - Pulse PB1 (RCLK) to latch the data to the output.
display:
  push R16     ; push R16 to the stack
  push R17     ; push R17 to the stack
  in R17, SREG ; loads status register into R17
  push R17     ; push R17 (status register) to the stack
  ldi R17, 8   ; load 8 into R17 (counter for 8 bits)
  
  loop:
    rol R16    ; rotate left through carry 
    BRCS set_ser_in_1 ; branch if carry set
    cbi PORTB, 0     ; clear PB0
  rjmp end

  set_ser_in_1:
    sbi PORTB, 0 ; set PB0

  end:
    sbi PORTB, 2 ; set PB2
    cbi PORTB, 2 ; clear PB2
    dec R17     ; decrement R17
    brne loop   ; branch if not equal to 0
    sbi PORTB, 1 ; set PB1
    cbi PORTB, 1 ; clear PB1

  pop R17      ; pop R17 from the stack
  out SREG, R17 ; store R17 into status register
  pop R17     ; pop R17 from the stack
  pop R16    ; pop R16 from the stack
ret

; Subroutine: Delay
; - delay subroutine
Delay:
	ldi r30, 0x5d	  	; load 0x5d into r30 (93)
	ldi r31, 0x00     ; load 0x00 into r31 (0)
d1:
	ldi   r29, 0x2a		; load 0x2a into r29 (42)	
d2:
	nop				        ; no operation
	dec   r29         ; decrement r29	
	brne  d2			    ; branch if r29 is not equal to 0
	sbiw r31:r30, 1		; subtract immediate from word	
	brne d1				    ; branch if r31:r30 is not equal to 0
	ret