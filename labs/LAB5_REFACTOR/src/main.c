/**
 * @file main.c
 * @author Sage Marks and Matt Krueger
 * @brief Main program file for Lab5
 * @version 0.1
 * @date 2025-04-21
 * 
 * @copyright Copyright (c) 2025
 * 
 */

// external libraries
#include <avr/io.h>															
#include <stdio.h>												
#include <stdlib.h>								
#include <string.h>					
#include <util/delay.h> 

// internal source files
#include "usart.h"		
#include "adc.h"		
#include "dac.h"		
#include "commands.h"	
#include "i2cmaster.h"

// preprocessor directives
// USART0 configuration
#define FOSC 16000000												// oscilation frequency
#define BAUD 9600													// baud rate 		
#define MYUBRR FOSC/16/BAUD-1										// -> 103; asynchronous normal mode U2Xn=0 for UBRR (USART Baud Rate Register)
																	// divides 16MHz clock by (103+1)*16 = 1664
																	// 16MHz / 1664 ~= 9600 bps

/**
 * @brief initializes all modules
 */
void setup() {
	USART0_Init(MYUBRR);			
	ADC_init();											
	i2c_init();										
}

/**
 * @brief program loop
 * 
 * Reads characters placed in the terminal emulator (Serial Monitor)
 * The characters make a command, which is parsed and mappped to method of another component:
 * - DAC
 * - ADC 
 * - USART
 * Ultimately, the result of the command is echoed to the terminal emulator handled downstream 
 * 
 * For Lab5, we did not use the Arduino IDE, which uses the setup() and loop() methods, rather we 
 * explicitly called setup() and created an infinite loop while(1). The effect is the same.
 * 
 * @return int 
 */
int main(void) {
	setup();														
	
	// create buffer to hold the incoming command
	char command_buffer[32];										
	
	// read incoming bytes. If there are any, process the command
	while (1) {
		int bytes_read = read_line(command_buffer, 32);				
		
		if (bytes_read > 0) {										
			char command = command_buffer[0];						
			char* params;											
			
			if (bytes_read > 1) {
				params = command_buffer + 1;						
				} else {
				params = "";										
			}
			
			process_command(command, params);						
		}
	}
	
	return 0;
}