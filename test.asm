.def rpg_prev_a = r17
.def rpg_prev_b = r15
.def dc_ocr0b = r19

.cseg
.org 0x0000
rjmp reset

.org 0x0006
rjmp rpg_a_isr

.org 0x0008
rjmp rpg_b_isr

.org 0x0034
configure_rpg_interrupt:
	; Pin change interrupt control register -> set Pin change enabled for pins [7..0]
	lds r16, PCICR 
	ori r16, (1 << PCIE0)
	sts PCICR, r16
	; Enable pins 0 and 1
	lds r16, PCMSK0
	ori r16, (1 << PCINT1) | (1 << PCINT0)
	sts PCMSK0, r16
	ret

configure_inputs:
	cbi DDRB, 1
	cbi DDRB, 0
	ret

reset:
	rcall configure_rpg_interrupt
	rcall configure_inputs

	ldi r18, 0
	mov rpg_prev_a, r18
	mov rpg_prev_b, r18

	sei

	loop:
		nop 
		rjmp loop

rpg_a_isr:
	detect_current_a:
		in r16, PINB
		andi r16, (1 << PB1)       	
		ldi r17, 1					
		sbrs r16, PB1 
		ldi r17, 0
	mov rpg_prev_a, r17
	cpse r17, rpg_prev_b
	rjmp rpg_cw							; current a != prev b --> CW
	rjmp rpg_ccw						; current a == prev b --> CCW
	
rpg_b_isr:
	detect_current_b:
		in r16, PINB
		andi r16, (1 << PB0)
		ldi r17, 1					
		sbrs r16, PB0 
		ldi r17, 0
	mov rpg_prev_b, r17
	cpse r17, rpg_prev_a
	rjmp rpg_cw							; current b != prev a --> CWW
	rjmp rpg_ccw						; current b == prev a --> CW
	
rpg_cw:
	cpi dc_ocr0b, 79
	breq at_ceiling
	inc dc_ocr0b
	at_ceiling:
	reti

rpg_ccw:
	cpi dc_ocr0b, 0
	breq at_floor
	dec dc_ocr0b
	at_floor:
	reti
	