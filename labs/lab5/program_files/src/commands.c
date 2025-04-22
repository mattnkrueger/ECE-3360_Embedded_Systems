////////////////////////////////////////////////////////////
// Command Functions
////////////////////////////////////////////////////////////

//Reading from the ADC and G command
void G_command() 
{
	float voltage = read_ADC();												//Read a voltage measurement through ADC channel 0						
	char vstr[16];															//Initialize a buffer voltage string to be sent across serial communication
	sprintf(vstr, "%.3f", voltage);											//Format the float into the string
	USART0_SendString("v = ");												//Sent over USART in this format
	USART0_SendString(vstr);												//Send voltage string
	USART0_SendString(" V\r\n");												//End with a carriage and new line character 
}

//M command that takes multiple readings from the ADC at set intervals and time amounts
void M_command(char* params) 
{
																			//Find the comma separators
																			//strchr looks for instances of specific characters in a string, in this case it is looking for the commas needed for the command
	char* first_comma = strchr(params, ',');								//Find the address of the first comma
	char* second_comma;														//Create a pointer to the second comma character
	if (first_comma != NULL)												//If the first comma was detected we can look for the second
	{			
		second_comma = strchr(first_comma + 1, ',');						//Search for second comma and save address in pointer
	} 
	else 
	{
		second_comma = NULL;												//No first comma found set to NULL
	}
	
	if (!first_comma || !second_comma)										//If two commas are not detected the formatting is incorrect and send a message saying so
	{
		USART0_SendString("Error: Incorrect M format\r\n");
		return;
	}
	
	int num_readings = atoi(first_comma + 1);								//Convert the ASCII label for the number of readings (starting address after the first comma) to an integer
	int delay_seconds = atoi(second_comma + 1);								//Convert the ASCII label for the delay between readings (starting address after the second comma) to an integer
	
	if (num_readings < 2 || num_readings > 20)								//Ensure number of readings is between 2 and 20
	{
		USART0_SendString("Error: Number of readings must be 2-20\r\n");
		return;
	}
	
	if (delay_seconds < 1 || delay_seconds > 10)							//Ensure that the delay time is between 1 and 10 seconds
	{
		USART0_SendString("Error: Delay must be 1-10 seconds\r\n");
		return;
	}
	
	int elapsed_time = 0;													//track the time elapsed for USART communication
	char time_str[16];														//empty time string
	char vstr[16];															//empty voltage string
	
	for (int i = 0; i < num_readings; i++)									//Take a measurement for each reading
	{
		float voltage = read_ADC();											//Take reading at current time

		sprintf(time_str, "t=%d s, v=", elapsed_time);						//Format string with a float using sprintf to include elapsed time

		USART0_SendString(time_str);										//Send time string over USART
		
		sprintf(vstr, "%.3f V", voltage);									//Format string with a float using sprintf to include voltage reading
		USART0_SendString(vstr);											//Send voltage string
		USART0_SendString("\r\n");											//Send carriage and new line character
		
		if (i < num_readings - 1)											//For all measurements except the last one	
		{
			for (int j = 0; j < delay_seconds; j++)							//Delay between readings 
			{
				_delay_ms(1000);											//Delay 1-second intervals
			}
			elapsed_time += delay_seconds;									//Update time elapsed in seconds for display
		}
	}
}

//S command and DAC functionality
void S_command(char* params) 
{
																			// Find the comma separators
																			//strchr looks for instances of specific characters in a string, in this case it is looking for the commas needed for the command
	char* first_comma = strchr(params, ',');
	char* second_comma;														//Create a pointer to the second comma character
	if (first_comma != NULL)												//If the first comma was detected we can look for the second
	{
		second_comma = strchr(first_comma + 1, ',');						//Search for second comma and save address in pointer
	}
	else
	{
		second_comma = NULL;												//No first comma found set to NULL
	}
	if (!first_comma || !second_comma)										//If there are not two commas send an error
	{
		USART0_SendString("Error: Incorrect S format\r\n");
		return;
	}
	
	int channel = atoi(first_comma + 1);									//Convert the ASCII label for the channel (address after the first comma) to an integer
	float input_voltage = atof(second_comma + 1);							//Convert the ASCII label for the voltage input (starting address after the second comm) to a float
	
	if (channel != 0 && channel != 1)										//Ensure valid channel was input
	{										
		USART0_SendString("Error: Channel must be 0 or 1\r\n");
		return;
	}
	
	if (input_voltage < 0.0 || input_voltage > 5.0)							//Ensure valid voltage was input
	{						
		USART0_SendString("Error: Voltage must be 0.0-5.0\r\n");
		return;
	}
	
	int dac_value = DAC_voltage_conversion(input_voltage);					//Convert the input voltage into a value that the DAC can read (0-255)
	
	float actual_voltage = dac_value * (5.0 / 256.0);						//Calculate the actual voltage that will be present on DAC output after float to integer rounding
	
	if (channel == 0)														//If channel 0 was specified
	{
		set_DAC_channel0(dac_value);										//Set channel 0 output voltage
		USART0_SendString("DAC channel 0 set to ");							//Initial display string for channel 0
	} 
	else																	//Channel 1 was specified
	{
		set_DAC_channel1(dac_value);										//Set channel 1 output voltage
		USART0_SendString("DAC channel 1 set to ");							//Initial display string for channel 1
	}
	
	char vstr[32];															//Initialize buffer to put voltage information in
	sprintf(vstr, "%.2f V (%dd)\r\n", actual_voltage, dac_value);			//Use sprintf to format display and round the voltage, while showing the integer vlaue sent to the DAC
	USART0_SendString(vstr);												//Send string over USART
}

//By reading the command character sends you to that command logic to perform action
//Takes the character that represents a specific command and the pointer to the command parameters
//Returns nothing
void process_command(char command, char* params) 
{
	switch (command) 
	{														
		case 'G':															//If Case G go to the G command
		G_command();
		break;
		case 'S':															//If Case S go to the S command
		S_command(params);
		break;
		case 'M':
		M_command(params);													//If Case M go to the M command
		break;
		default:
		USART0_SendString("Unknown command\r\n");								//If none of the commands let the user know input is unknown
		break;
	}
}


//Function that reads a line of text from the USART until newline character or timeout has been reached
//Takes a pointer to the buffer string and the max number of characters to be read
//Returns the length of the string (number of characters that have been read)
int read_line(char* buffer, int max_length) 
{
	int idx = 0;															//Buffer index (counts the number of characters read in serial communication)
	unsigned long start_time = 0;											//Track time that has elapsed for a timeout
	
	while (idx < max_length - 1)											//Continue reading until buffer is full (excluding null terminating character)
	{											
		if (UCSR0A & (1<<RXC0)) 
		{																	//Check if character is available to be received (UCSR0A -> USART Control and Status Register A)																//RXC0 -> specific bit position in this register
			char c = UDR0;													//Read the character from the serial communication
			
			if (c == '\r' || c == '\n') 
			{																//If the character is the carriage character or the new line character
				buffer[idx] = '\0';											//Null terminate the string
				return idx;													//Return the number of characters
			}
			buffer[idx++] = c;												//Store characters in the buffer and increment the index
			start_time = 0;													// Reset timeout counter when character is received
		} 
		else 
		{
			_delay_ms(1);													//No character to read, delay
			if (++start_time > COMMAND_TIMEOUT_MS)							//If we have a timeout
			{						
				buffer[idx] = '\0';											//Null-terminate the string
				
				if (idx > 0) 
				{
					return idx;												//Return character count if data was received
				} 
				else 
				{
					return -1;												//Return -1 for timeout with no data
				}
			}
		}
	}
	buffer[max_length - 1] = '\0';											//Reaching here means buffer is full
																			//Null terminate the buffer string
	return max_length - 1;													//Return the number of characters that have been read
}