#include <avr/io.h>
//#include <util/delay.h>

#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#define FOSC 16000000 // Clock Speed
#define BAUD 9600
#define MYUBRR FOSC/16/BAUD-1 //will be 103

////////////////////////////////////////////////////////////
// USART FUNCTIONS
////////////////////////////////////////////////////////////

//Function that initializes the USART
void USART0_Init( unsigned int ubrr)//From data sheet
{
	/*Set baud rate */
	UBRR0H = (unsigned char)(ubrr>>8);
	UBRR0L = (unsigned char)ubrr;
	/*Enable receiver and transmitter */
	UCSR0B = (1<<RXEN0)|(1<<TXEN0);
	/* Set frame format: 8data, 1stop bit */
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

//Function to send USART data
void USART0_Transmit( unsigned char data )
{
	/* Wait for empty transmit buffer */
	while ( !( UCSR0A & (1<<UDRE0)) )
	;
	/* Put data into buffer, sends the data */
	UDR0 = data;
}

//Function to recieve USART data
unsigned char USART0_Receive( void )
	{
	/* Wait for data to be received */
	while ( !(UCSR0A & (1<<RXC0)) )
	;
	/* Get and return received data from buffer */
	return UDR0;
}

void USART0_SendString(const char* str)
	{
	while (*str) {
	USART0_Transmit(*str++);
	}
}

/////////////////////////////////////////////////////////
// ADC FUNCTIONS
/////////////////////////////////////////////////////////

// Function to initialize ADC
void ADC_init() {
	// external capacitor
	ADMUX = (1<<REFS0);  // Use Vcc reference (5 volts)

	// Set ADC prescaler to 64 (for 16 MHz clock)
	ADCSRA |= (1 << ADPS2) | (1 << ADPS1);  // Prescaler 64
	// For stable ADC conversions 250Khz

	// Enable the ADC
	ADCSRA |= (1 << ADEN);
}

// Function to read ADC value from the specified channel
float read_ADC() {

	// Start the conversion
	ADCSRA |= (1 << ADSC);  // Start conversion

	// Wait for the conversion to finish
	while (ADCSRA & (1 << ADSC));  // Wait for the ADSC flag to be cleared (conversion complete)

	// Read the ADC value (low and high byte)
	uint16_t adc_Value = ADC;  // Combine ADCL and ADCH (ADC is 10-bit)
	float voltage = adc_Value * (5 / 1023.0);

	//need to convert the value to a string to send
	return voltage;  // Return the ADC value
}

void setup() {
	// Initialize USART
	USART_Init(MYUBRR);

	// Initialize ADC
	ADC_init();
}

void loop() {
	
	unsigned char received = USART0_Receive();
	
	if (received == 'G')
		{
		USART0_SendString("v = ");
		float voltage = read_ADC();
		
	}
}