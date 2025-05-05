/**
 * @file Color_Select_Screen.h
 * @author Matt Krueger & Sage Marks
 * @brief definitions for the color selection screen of the EtchASketch
 * @version 0.1
 * @date 2025-05-04
 * 
 * @copyright Copyright (c) 2025
 */
#ifndef COLOR_SELECT_SCREEN_H
#define COLOR_SELECT_SCREEN_H

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>

// extern is supposedly standard instead of using macros to define program wide vars
extern MatrixPanel_I2S_DMA* dma_display_cs;
extern const char* colorNames[];
extern uint16_t colorValues[];
extern int selectedColorIndex;
extern const int numColors;

/**
 * @brief initialize the color values allowed for use in etchasketch
 * 
 * @param display 
 */
void initColorSelector(MatrixPanel_I2S_DMA* display);

/**
 * @brief 
 * 
 * @param colorValues 
 */
void drawColorSelector(uint16_t colorValues[]);

/**
 * @brief 
 * 
 */
void nextColor();

/**
 * @brief 
 * 
 */
void prevColor();

/**
 * @brief Get the Current Color object
 * 
 * @return uint16_t 
 */
uint16_t getCurrentColor(); 


#endif