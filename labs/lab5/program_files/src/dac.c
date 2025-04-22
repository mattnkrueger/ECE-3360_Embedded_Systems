////////////////////////////////////////////////////////////
// DAC Functions
////////////////////////////////////////////////////////////

//Function that sets DAC channel 0
void set_DAC_channel0(int value) 
{
	i2c_start((MAX518_ADDR << 1) | I2C_WRITE);								//Start the i2c communication in write mode using the i2c address
	i2c_write(0x00);														//Write to output channel 0
	i2c_write(value);														//Write the value to be set at the DAC output
	i2c_stop();																//Stop i2c communication
}

//Function that sets DAC channel 1
void set_DAC_channel1(int value) 
{
	i2c_start((MAX518_ADDR << 1) | I2C_WRITE);								//Start the i2c communication in write mode using the i2c address
	i2c_write(0x01);														//Write to output channel 1
	i2c_write(value);														//Write the value to be set at the DAC output
	i2c_stop();																//Stop i2c communication
}

//Function that converts the DAC value to an integer from a float
int DAC_voltage_conversion(float voltage)									//A value from 0 - 255 is needed to set the DAC
{																			//Uses a reference voltage of 5
	int return_voltage = voltage * 256.0 / 5.0 + 0.5;						//Add 0.5 for correct rounding		 														
	return return_voltage;													//Return integer voltage value
}
