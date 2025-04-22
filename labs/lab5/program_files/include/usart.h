#ifndef USART_H
#define USART_H

void USART0_Init(unsigned int ubrr) {};
void USART0_Transmit(unsigned char data) {}; 
unsigned char USART0_Receive(void) {};
void USART0_SendString(const char* str) {}; 

#endif