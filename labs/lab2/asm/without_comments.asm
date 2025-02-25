sbi DDRB, 0         
sbi DDRB, 1         
sbi DDRB, 2         
cbi DDRB, 3    

ldi R21, 0
ldi R22, 0
ldi R26, 0xe8
ldi R27, 0x03

IncNumberCheck:				
  rcall ButtonCheck
  sbrc R22, 0
  rjmp DecNumberCheck
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
  rjmp IncNumberCheck

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

IncDisp:					
  rcall display
  rjmp IncNumberCheck

DecNumberCheck:				
  rcall ButtonCheck
  sbrs R22, 0
  rjmp IncNumberCheck
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

DispDec:
  rcall display
  rjmp DecNumberCheck

ButtonCheck:
  sbic PINB, 3
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

display:
  push R16
  push R17
  in R17, SREG
  push R17
  ldi R17, 8
  
  loop:
    rol R16
    BRCS set_ser_in_1
    cbi PORTB, 0
  rjmp end

  set_ser_in_1:
    sbi PORTB, 0

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

Delay:
	ldi r30, 0x5d	  	
	ldi r31, 0x00
d1:
	ldi   r29, 0x2a		    	
d2:
	nop				
	dec   r29            		
	brne  d2			
	sbiw r31:r30, 1			
	brne d1				
	ret