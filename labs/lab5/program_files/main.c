#include <avr/io.h>															
#include <stdio.h>												
#include <stdlib.h>								
#include <string.h>					
#include <util/delay.h> // timing purposes											
#include <i2cmaster.h>	// I2C library													

/**
 * @brief initializes all modules
 *
 * setup calls sequence of initializers to configure the lab5 program:
 * 1. usart
 * 2. adc
 * 3. i2c
 *
 * @param none
 *
 * @return none
 */
void setup() {
	USART0_Init(MYUBRR);			
	ADC_init();											
	i2c_init();										
}

int main(void) {
	setup();																//Call setup function
	
	char command_buffer[32];												//Initialize a string that is 32 characters in length to read commands
	
	while (1) {
		int bytes_read = read_line(command_buffer, 32);						//Loop that reads from the Serial terminal continuously
		
		if (bytes_read > 0) {												//If data is read, process it as a command
			char command = command_buffer[0];								//First character of buffer is command type
			char* params;													//Initialize a pointer to the parameters
			
			if (bytes_read > 1) {
				params = command_buffer + 1;								//If there are parameters, point to them
				} else {
				params = "";												//Otherwise, use an empty string
			}
			
			process_command(command, params);								//Call the command processing function
		}
	}
	
	return 0;
}