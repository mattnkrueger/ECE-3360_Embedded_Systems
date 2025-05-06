/**
 * @file PixelArt.h
 * @author Matt Krueger & Sage Marks
 * @brief definitions of functions used for static pixel art screen
 * @version 0.1
 * @date May 7th, 2025
 * 
 * @copyright Copyright (c) 2025
 * 
 * Provides functions for use in pixel art image view
 * comments inside of .cpp file
 * 
 */

#ifndef IMAGES_H
#define IMAGES_H

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>

void drawLogo(MatrixPanel_I2S_DMA* display);
int getCurrentImageIndex();
void drawCurrentImage(MatrixPanel_I2S_DMA* display);
void prevImage();
void nextImage();

#endif
