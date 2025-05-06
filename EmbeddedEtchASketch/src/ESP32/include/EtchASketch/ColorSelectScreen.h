/**
 * @file ColorSelectScreen.h
 * @author Matt Krueger & Sage Marks
 * @brief definitions for the color selection screen
 * @version 0.1
 * @date May 7th, 2025
 * 
 * @copyright Copyright (c) 2025
 * 
 * This defines the functions used to create the color selection screen that is initially shown when the user selects the Sketch program
 * Comments included inside of .cpp file
 * 
 */

#ifndef COLOR_SELECT_SCREEN_H
#define COLOR_SELECT_SCREEN_H

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>

extern MatrixPanel_I2S_DMA* dma_display_cs;
extern const char* colorNames[];
extern uint16_t colorValues[];
extern int selectedColorIndex;
extern const int numColors;

void initColorSelector(MatrixPanel_I2S_DMA* display);
void drawColorSelector(uint16_t colorValues[]);
void nextColor();
void prevColor();
uint16_t getCurrentColor();

#endif