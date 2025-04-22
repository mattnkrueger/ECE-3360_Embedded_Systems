/**
 * @file dac.h
 * @author Sage Marks and Matt Krueger
 * @brief Definiton of DAC methods used in Lab5
 * @version 0.1
 * @date 2025-04-21
 * 
 * @copyright Copyright (c) 2025
 * 
 */

#ifndef DAC_H
#define DAC_H

void set_DAC_channel(uint8_t channel, uint8_t value);
int DAC_voltage_conversion(float voltage);

#endif