/**
 * @file PackersLogo.h
 * @author Matt Krueger & Sage Marks
 * @brief definitions for the Packers Logo image 
 * @version 0.1
 * @date 2025-05-05
 * 
 * @copyright Copyright (c) 2025
 * 
 * This gives the definition of the function included in the PackersLogo image to be displayed to the screen
 */

#ifndef LOGO_DRAWER_H
#define LOGO_DRAWER_H

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>

void drawLogo(MatrixPanel_I2S_DMA* display);

#endif
