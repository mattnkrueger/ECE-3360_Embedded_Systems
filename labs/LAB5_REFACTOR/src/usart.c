/**
 * @file usart.h
 * @author Sage Marks and Matt Krueger
 * @brief Implementation of USART methods used in Lab5
 * @version 0.1
 * @date 2025-04-21
 * 
 * ATTRIBUTION:
 * 		Code segments in this file were taken directly from the Atmega328P datasheet:
 * 		https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-7810-Automotive-Microcontrollers-ATmega328P_Datasheet.pdf
 *
 * 		Addition of USART0_SendString() 
 *
 */

#include "usart.h"

/**
 * @brief initialize USART0 
 * 
 * @param ubrr usart baurd rate register
 */
void USART0_Init(unsigned int ubrr) 
{																		
	// set baud rate
	UBRR0H = (unsigned char)(ubrr>>8);
	UBRR0L = (unsigned char)ubrr;

	// enable receiver and transmitter
	UCSR0B = (1<<RXEN0)|(1<<TXEN0);

	// set frame format: 8dat, 2stop bit 
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

/**
 * @brief transmit data over USART to terminal emulator
 * 
 * @param data 
 */
void USART0_Transmit(unsigned char data) 
{																		
	// wait for empty transmit buffer
	while (!(UCSR0A & (1<<UDRE0)));

	// put data into buffer, sends the data
	UDR0 = data;
}

/**
 * @brief receive data over USART from terminal emulator
 * 
 * @return unsigned char 
 */
unsigned char USART0_Receive(void) 
{																		
	// wait for data to be received
	while (!(UCSR0A & (1<<RXC0)));

	// get and return data from buffer
	return UDR0;
}

/**
 * @brief sends string of data over USART to terminal emulator
 * 
 * @param str pointer to a constant character
 */
void USART0_SendString(const char* str) 
{																		
	// while not null terminated '\0', transmit character
	while (*str) 
	{
		USART0_Transmit(*str++);
	}
}