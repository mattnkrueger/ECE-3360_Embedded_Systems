;
; es_lab_1_matt_krueger.asm
;
; Created: 2/4/2025 11:09:33 AM
; Author : mnkrueger
;

; I have erased all comments on starting code, replacing them with comments for my own learning.
; Research done on web & datasheets provided on ICON.
; - matt krueger

; ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; INITIAL SETUP 
; Duration - 0 (done during assembly)
; ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

.include "m328Pdef.inc"                     ; file includes register/bit definitions for ATmega328P (ref: https://raw.githubusercontent.com/DarkSector/AVR/master/asm/include/m328Pdef.inc)
.cseg                                       ; "code segment" - tells assembler to place instructions into the flash memory (program code is stored in the flash memory). Other segments: .dseg (data segment SRAM), .eseg (EEPROM non-volatile storage). .cseg is read-only during execution & persistent. Segment order .dseg -> .eseg -> .cseg
.org 0                                      ; "origin" - tells assembler where to place the code in memory. `.org 0` sets the program counter (PC) to address 0 in flash memory. Defines the starting address for data/code. PC is a special reg in CPU to keep track of the current instruction address. When ATmega328P is powered on, it resets to 0. 

; ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; PORT DEFINITIONS
; Duration - 4 cycles -> 
; ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; `sbi` - set bit in I/O register. (2 cycles)
; `DDRB` - data direction register for port B. 
; `sbi` sets specific bit to 1 (high) in specified `DDRB` pin.
sbi   DDRB,1                                ; set bit 1 of DDRB to 1; PB1 as output 
sbi   DDRB,2                                ; set bit 2 of DDRB to 1; PB2 as output

; ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; BLINKY ROUTINE: "loop"
; Duration - 16 cycles 
; ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; loop to define the order of the blinking lights.
; PB2 -> delay -> PB1 -> delay -> PB2 -> ... -> inf
; `sbi` - set bit in I/O register to high (2 cycles)
; `cbi` - clear bit in I/O register to low (2 cycles)
; `rcall` - relative call. Calls subroutine whilst keeping track of location on stack to return to (3 cycles)
; `rjump` - jump to label. Does not keep track of location on stack; it just goes to label (2 cycles)
loop:										; label to mark specific location in code. "loop" is not a keyword. This could be renamed. These instructions define the blinky loop.
	sbi   PORTB,1                           ; set PB1 to 1 (high) -> pin 9 on device is outputting vo
	cbi   PORTB,2                           ; clear PB2 to 0 (low)
	rcall delay_long                        ; call subroutine (while saving current program counter on stack to return to after completion of subroutine. Calls subroutine `delay_long`.
	cbi   PORTB,1                           ; clear PB1 to 0 (low)
	sbi   PORTB,2                           ; set PB2 to 1 (high)
	rcall delay_long                        ; call subroutine (while saving current program counter on stack to return to after completion of subroutine. Calls subroutine `delay_long`.
rjmp loop									; 'jumps' back to "loop" marker to repeat the cycle

; ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; SUBROUTINE: "delay_long"
;
; ------------- back of envelope calculations -------------
; (x)67,107,855/16,000,000 = 3.042s
; x = 3.042/4.19424
; thus x = .72528
;
; count * .72528 -> 65535 * .72528 = 47531.25 floored -> 47531  
; ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; `ldi` - load immediately. Loads a constant into a register (can only use general purpose registers r16-r31). Holds an 8-bit value (executes at runtime; .equ executes at assembly time) (1 cycle)
; `low(count)` - extracts lower 8 bits of "count" variable 
; `high(count)` - extracts upper 8 bits of "count" variable
; NOTE on low()/high() directives: because registers only hold 8 bits, they are required to split the store the data register file on CPU (NOT sram/eeprom/flash)
; `nop` - wait 1 clock cycle (1 cycle)
; `dec` - decrement by one bit (flags: Zero (Z), Negative (N), Overflow (V) (1 cycle)
; `brne` - branch if not equal. Jumps to specified instruction if the value of the previous operation is non-zero. IMPORTANT for timer. (1 or 2 cycles)
; `sbiw` - subtract immediate from word. Subtracts two 16 bit values. must specify which registers subtracting to (2 cycles)
; `.exit` - exit program 
; `.equ` - directive executed at assembly time to hold a constant. Could not find where this is stored. Guessing that it is on flash as assembly code resides there.

; Modified for 0.3042s delay with 16MHz clock
; Original was 4.119424s
;
; 635 needed 
; 643 = (1+1+2)*x + 1+1+1

.equ count1 = 0x14c3                     ; .equ (defines a constant) sets count to 0xffff (65535 which is largest 16 bit value & maximum delay) at assembly time. SIMPLY AN ALIAS

delay_long:									; label to mark specific location on code. `delay_long` defines the time that elapses between led light switches.

	ldi r30, low(count1)					; loads lower 8 bits of count ffff (1111) into register 30 
	ldi r31, high(count1)					; loads upper 8 bits of count ffff (1111) into register 31
	ldi r27, 156

	d1:                                     ; marker for first delay
		ldi r29, 0xff		    	        ; load 1111 (high) into register 29 

	d2:                                     ; marker for second delay
		nop				                    ; no operation; wait 1 cycle
		dec r29            					; r29 = r29 - 1 (this will run 255 times since ff loaded into r29)
		brne d2								; check if dec 29 flags Z. Only continues once value in register 29 is 0.
		sbiw r31:r30, 1			            ; subtract 1 from timer registers.
		brne d1				                ; check if timer has reached 0 (Z flag). if it has -> go back to d1

	; added loop to reach 635
	d3:
		nop 
		dec r27
		brne d3
		nop
		nop
		nop
		nop
		nop

		
ret											; return from sub routine to location on stack from which it was called.

.exit                                       ; exit program
