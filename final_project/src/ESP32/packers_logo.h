/**
 * @file packers_logo.h
 * @author Matt Krueger & Sage Marks
 * @brief definitions for logo program
 * @version 0.1
 * @date 2025-05-04
 * 
 * @copyright Copyright (c) 2025
 * 
 */
#ifndef LOGO_DRAWER_H
#define LOGO_DRAWER_H

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>

/**
 * @brief draws the packers logo
 * 
 * @param display 
 */
void drawLogo(MatrixPanel_I2S_DMA* display);

#endif
