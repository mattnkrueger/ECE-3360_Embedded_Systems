#define FOSC 16000000														//Define oscillator frequency for USART initialization (datasheet) 
#define BAUD 9600															//Define BAUD Rate (datasheet)
#define MYUBRR FOSC/16/BAUD-1												//Defined for USART initialization (datasheet)

#define MAX518_ADDR 0x2C													//Define the i2c address of the MAX518 DAC
#define COMMAND_TIMEOUT_MS 100												//Define the length of time until a timeout occurs

////////////////////////////////////////////////////////////
// USART Functions
////////////////////////////////////////////////////////////

void USART0_Init(unsigned int ubrr) 
{																			//USART initialization function from the ATMEGA328P datasheet
	UBRR0H = (unsigned char)(ubrr>>8);
	UBRR0L = (unsigned char)ubrr;
	UCSR0B = (1<<RXEN0)|(1<<TXEN0);
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

void USART0_Transmit(unsigned char data) 
{																			//USART transmission function from the ATMEGA328P datasheet
	while (!(UCSR0A & (1<<UDRE0)));
	UDR0 = data;
}

unsigned char USART0_Receive(void) 
{																			//USART receive function from the ATMEGA328P datasheet
	while (!(UCSR0A & (1<<RXC0)));
	return UDR0;
}

void USART0_SendString(const char* str) 
{																			//USART send string function that utilizes the transmit function
	while (*str) 
	{
		USART0_Transmit(*str++);
	}
}