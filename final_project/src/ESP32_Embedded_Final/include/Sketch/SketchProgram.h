/**
 * @file SketchProgram.h
 * @author Matt Krueger & Sage Marks
 * @brief definitions for the Sketch program 
 * @version 0.1
 * @date 2025-05-05
 * 
 * @copyright Copyright (c) 2025
 * 
 * This defines the functions that are used inside of the Sketch program. These handle the coloring and drawing inside of the program. 
 * 
 */

#ifndef SKETCH
#define SKETCH

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <Arduino.h>

void initSketch(MatrixPanel_I2S_DMA* disp, uint16_t color);
void handleEtchCommand(const String& cmd);
void nextEtchColor();
void prevEtchColor();

#endif