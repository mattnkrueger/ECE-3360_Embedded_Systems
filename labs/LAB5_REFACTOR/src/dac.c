/**
 * @file dac.h
 * @author Sage Marks and Matt Krueger
 * @brief Implementation of DAC methods used in Lab5
 * @version 0.1
 * @date 2025-04-21
 * 
 * @copyright Copyright (c) 2025
 * 
 */

#include <avr/io.h>
#include "dac.h"
#include "i2cmater.h"

#ifndef MAX518_ADDR
#define MAX518_ADDR 0x2C											 // address of MAX518 device for I2C
#endif

/**
 * @brief Set the DAC channel object
 * 
 * Writes value to the specified channel register of MAX518
 * Utilizes I2C to communicate with the DAC
 * 
 * @param channel channel to be set (0 or 1)
 * @param value value to be set at the specified channel
 */
void set_DAC_channel(uint8_t channel, uint8_t value) 
{
	i2c_start((MAX518_ADDR << 1) | I2C_WRITE);				
	i2c_write(channel);													
	i2c_write(value);													
	i2c_stop();															
}

/**
 * @brief DAC voltage conversion
 *
 *  Converts voltage to a value between 0 and 255
 *  
 *  Equation:
 * 					DAC = Vin * 256 / Vref
 * 
 * @param voltage 
 * @return int
 */
int DAC_voltage_conversion(float voltage)								
{																		
	int return_voltage = voltage * 256.0 / 5.0 + 0.5;					
	return return_voltage;												
}
