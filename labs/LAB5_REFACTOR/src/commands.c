/**
 * @file adc.h
 * @author Sage Marks and Matt Krueger
 * @brief Implementation of terminal emulation commands used in Lab5
 * @version 0.1
 * @date 2025-04-21
 * 
 * @copyright Copyright (c) 2025
 * 
 */

#include <avr/io.h>
#include <string.h>
#include <stdlib.h>

#include "commands.h"
#include "adc.h"
#include "usart.h"
#include "dac.h"

#ifndef COMMAND_TIMEOUT_MS
#define COMMAND_TIMEOUT_MS 100									     // timeout length
#endif

/**
 * @brief Get single voltage measurement from ADC
 * 
 * Takes no parameters, and returns the current voltage reading from the ADC. 
 * ADC is configured for 10-bit resolution.
 *
 */
void G_command() 
{
	float voltage = read_ADC();											
	char vstr[16];														
	sprintf(vstr, "%.3f", voltage);	
	USART0_SendString("v = ");					
	USART0_SendString(vstr);						
	USART0_SendString(" V\r\n");												
}

/**
 * @brief Get multiple voltage measurements from ADC
 * 
 * Takes a string of "M,n,dt"
 * - M = command
 * - n = number of readings (2-20)
 * - dt = delay between readings (1-10 seconds)
 * And takes n readings from the ADC, printing the time and voltage
 * If a reading is not valid, it will print an error message
 * 
 * @param params string containing formatted parameters 
 */
void M_command(char* params) 
{
	char* first_comma = strchr(params, ',');							
	char* second_comma;													

	if (first_comma != NULL)											
	{			
		second_comma = strchr(first_comma + 1, ',');					
	} 
	else 
	{
		second_comma = NULL;												
	}
	
	if (!first_comma || !second_comma)
	{
		USART0_SendString("Error: Incorrect M format\r\n");
		return;
	}
	
	int num_readings = atoi(first_comma + 1);								
	int delay_seconds = atoi(second_comma + 1);								
	
	if (num_readings < 2 || num_readings > 20)								
	{
		USART0_SendString("Error: Number of readings must be 2-20\r\n");
		return;
	}
	
	if (delay_seconds < 1 || delay_seconds > 10)				
	{
		USART0_SendString("Error: Delay must be 1-10 seconds\r\n");
		return;
	}
	
	int elapsed_time = 0;											
	char time_str[16];												
	char vstr[16];													
	
	for (int i = 0; i < num_readings; i++)							
	{
		float voltage = read_ADC();									

		sprintf(time_str, "t=%d s, v=", elapsed_time);				
		sprintf(vstr, "%.3f V", voltage);							

		USART0_SendString(time_str);								
		USART0_SendString(vstr);									
		USART0_SendString("\r\n");									
		
		if (i < num_readings - 1)									
		{
			for (int j = 0; j < delay_seconds; j++)					
			{
				_delay_ms(1000);									
			}
			elapsed_time += delay_seconds;							
		}
	}
}

/**
 * @brief Set DAC Output Voltage
 * 
 * Takes a string of "S,n,v"
 * 
 * @param params 
 */
void S_command(char* params) 
{
	char* first_comma = strchr(params, ',');
	char* second_comma;													

	if (first_comma != NULL)											
	{
		second_comma = strchr(first_comma + 1, ',');					
	}
	else
	{
		second_comma = NULL;											
	}
	
	if (!first_comma || !second_comma)									
	{
		USART0_SendString("Error: Incorrect S format\r\n");
		return;
	}
	
	int channel = atoi(first_comma + 1);								
	float input_voltage = atof(second_comma + 1);						
	
	if (channel != 0 && channel != 1)									
	{										
		USART0_SendString("Error: Channel must be 0 or 1\r\n");
		return;
	}
	
	if (input_voltage < 0.0 || input_voltage > 5.0)						
	{						
		USART0_SendString("Error: Voltage must be 0.0-5.0\r\n");
		return;
	}
	
	float dac_value = DAC_voltage_conversion(input_voltage);				
	float actual_voltage = dac_value * (5.0 / 256.0);					
	
	if (channel == 0)													
	{
		set_DAC_channel0(dac_value);									
		USART0_SendString("DAC channel 0 set to ");						
	} 
	else if (channel == 1)
	{
		set_DAC_channel1(dac_value);									
		USART0_SendString("DAC channel 1 set to ");						
	}
	else 
	{
		USART0_SendString("Error: DAC channel must be 0 or 1\r\n");		
		return;
	}
	
	char vstr[32];														
	sprintf(vstr, "%.2f V (%dd)\r\n", actual_voltage, dac_value);		
	USART0_SendString(vstr);											
}

/**
 * @brief maps the command to the correct function
 * 
 * takes a single character command and a string of parameters
 * if the command is not recognized, it will print an error message
 * 
 * @param command command to be executed
 * @param params parameters following the command
 */
void process_command(char command, char* params) 
{
	switch (command) 
	{														
		case 'G':														
		G_command();
		break;
		case 'S':														
		S_command(params);
		break;
		case 'M':
		M_command(params);												
		break;
		default:
		USART0_SendString("Unknown command\r\n");						
		break;
	}
}

/**
 * @brief reads incoming data at RX
 * 
 * clocks in the data until a newline or carriage return is received
 * stores the data in a buffer
 * 
 * @param buffer pointer of buffer to store the incoming data; not returned as this is a char* and modified in place
 * @param max_length maximum length of the buffer
 * @return int length of the data received
 */
int read_line(char* buffer, int max_length) 
{
	int idx = 0;														
	unsigned long start_time = 0;										
	
	while (idx < max_length - 1)										
	{											
		if (UCSR0A & (1<<RXC0)) 
		{																
			char c = UDR0;												
			
			if (c == '\r' || c == '\n') 
			{															
				buffer[idx] = '\0';	
				return idx;												
			}
			buffer[idx++] = c;		
			start_time = 0;				
		} 
		else 
		{
			_delay_ms(1);												
			if (++start_time > COMMAND_TIMEOUT_MS)						
			{						
				buffer[idx] = '\0';										
				
				if (idx > 0) 
				{
					return idx;											
				} 
				else 
				{
					return -1;											
				}
			}
		}
	}

	buffer[max_length - 1] = '\0';										
	return max_length - 1;												
}