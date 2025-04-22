/**
 * @file usart.h
 * @author Sage Marks and Matt Krueger
 * @brief Definition of USART communication used in Lab5
 * @version 0.1
 * @date 2025-04-21
 * 
 * @copyright Copyright (c) 2025
 * 
 */

#ifndef USART_H
#define USART_H

void USART0_Init(unsigned int ubrr);
void USART0_Transmit(unsigned char data); 
unsigned char USART0_Receive(void);
void USART0_SendString(const char* str); 

#endif