/////////////////////////////////////////////////////////
// ADC Functions
/////////////////////////////////////////////////////////

//Function that initializes the ADC
void ADC_init() 
{															
	ADMUX = (1<<REFS0);														//Reference voltage of 5V internal
	ADCSRA |= (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);					//best ADC accuracy is reached with a frequency from 50Khz - 200kHz (stated in data sheet)
																			//We opt for a prescalar of 128 to get a frequency of 125Khz
	ADCSRA |= (1 << ADEN);													//Enable ADC
	_delay_ms(1);															//Delay for ADC stabilization
}

//Function that reads from the ADC
float read_ADC() 
{															
	ADMUX &= 0xF0;															//Clear channel selection bits in MUX
	ADMUX |= (0 & 0x07);													//Enable channel 0
	ADCSRA |= (1 << ADSC);													//Start conversion by setting the ADSC bit
	while (ADCSRA & (1 << ADSC));											//wait for conversion to complete
	uint16_t adc_Value = ADC;												//Read the 10 bit ADC value
	float voltage = adc_Value * (5.0 / 1023.0);								//Convert the ADC value to a float with equation from the data sheet
	_delay_ms(1);															//Allow time for ADC to settle
	return voltage;															//Return the voltage value as a float
}