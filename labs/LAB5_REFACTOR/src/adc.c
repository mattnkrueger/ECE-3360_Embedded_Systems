/**
 * @brief initializes 10-bit Analog to Digital Converter
 * 
 * Configures ADC registers of ATmega328p:
 * 1. reference voltage 5v (internal)
 * 2. prescalar 128 to obtain frequency of 125Khz; datasheet suggests best accuracy within 50kHz - 200kHz
 * 3. enable ADC
 * 4. delay 1ms for stability
 *
 * ADC Clock:
 * 					ADC_clk = 16 MHz / p
 * 							= 16 MHz / 128 
 *							= 125kHz
 */

#include <avr/io.h>
#include "adc.h"

void ADC_init() 
{															
	ADMUX = (1 << REFS0);								 	// ADMUX (ADC Multiplexer Selection Register): 010r0000 denotes ADC0 with AVcc with external capacitor at AREF Pin (5v)
	ADCSRA |= (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);	// ADCSRA (ADC Control and Status Register A): 10000111 denotes prescalar 128 and enabled
	ADCSRA |= (1 << ADEN);													
	_delay_ms(1);												
}

/**
 * @brief reads value from ADC
 * 
 * Reads value at ADC0 Channel
 * 1. clear selection & select channel 0
 * 2. start conversion & wait until completed
 * 3. read result from ADC register
 * 4. convert result and return as float
 *
 * ADC Conversion:
 * 					ADC = Vin * 1024 / Vref
 * 							= adc_at_reg * 1024 / 5
 *
 * @return float 
 */
float read_ADC() 
{															
	ADMUX &= 0xF0;  							// mask only 11110000 of ADMUX (REFS1, REFS0, ADLAR, reserved) ... reserved not needed and is ignored in following command 
	ADMUX |= (0 & 0x07); 						// select channel 0 and config
	ADCSRA |= (1 << ADSC);  					// starts conversion by writing logical 1 at ADSC
	
	while (ADCSRA & (1 << ADSC));				// blocking while loop for conversion in progress (ADSC still high)
	uint16_t adc_at_reg = ADC;
	float voltage = adc_at_reg * (5.0 / 1023.0);

	_delay_ms(1);															
	return voltage;															
}