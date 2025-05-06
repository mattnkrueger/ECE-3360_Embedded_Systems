/**
 * @file EtchASketch.h
 * @author Matt Krueger & Sage Marks
 * @brief definitions for the EtchASketch program 
 * @version 0.1
 * @date May 7th, 2025
 * 
 * @copyright Copyright (c) 2025
 * 
 * This defines the functions that are used inside of the Sketch program. These handle the coloring and drawing inside of the program. 
 * comments included in .cpp file
 * 
 */

#ifndef ETCH_A_SKETCH_H
#define ETCH_A_SKETCH_H

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <Arduino.h>

void initEtchASketch(MatrixPanel_I2S_DMA* disp, uint16_t color);
void handleEtchCommand(const String& cmd);
void nextEtchColor();
void prevEtchColor();

#endif 