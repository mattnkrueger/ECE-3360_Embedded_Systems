/**
 * @file EtchASketch.cpp
 * @author Matt Krueger & Sage Marks
 * @brief implementation of Sketch program
 * @version 0.1
 * @date May 7th, 2025
 * 
 * @copyright Copyright (c) 2025
 * 
 * This sketch implements the Sketch program (extended 'EtchASketch' with colors) for the LED Matrix. 
 */

#include "EtchASketch/EtchASketch.h"
#include "EtchASketch/ColorSelectScreen.h"
#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <Arduino.h>

// center the cursor to start drawing
static int x = 32;
static int y = 32;
static uint16_t drawColor;
static MatrixPanel_I2S_DMA* display;

// variables for thresholding movement
static int rpg1Counter = 0;
static int rpg2Counter = 0;
static const int MOVEMENT_THRESHOLD = 1; 

// track our current color index
static int etchColorIndex = 0; 

/**
 * @brief Function that intializes the etch a sketch
 *
 * resets RPG counters and direction
 * sets the location of the cursor to the center
 * 
 * @param disp matrix object to draw on
 * @param color current color in use
 */
void initEtchASketch(MatrixPanel_I2S_DMA* disp, uint16_t color) {
  display = disp;
  drawColor = color;
  
  // find the index of the initial color
  for (int i = 0; i < numColors; i++) {
    if (colorValues[i] == color) {
      etchColorIndex = i;
      break;
    }
  }
  
  // set the cursor to the middle of the screen (64x64 LED Matrix)
  x = 32;
  y = 32;

  // clear screen
  display->fillScreen(display->color565(0, 0, 0));

  // draw current pixel the cursor is on in selected color
  display->drawPixel(x, y, drawColor);
}

/** 
 * @brief Function that finds new color you wish to draw with (from up arrow)
 * 
 * This function increments the color values and has wrap around fucntionality
 * Draws your current pixel in this new color
 *
 */
void nextEtchColor() {
  etchColorIndex = (etchColorIndex + 1) % numColors;
  drawColor = colorValues[etchColorIndex];
  
  // redraw the current cursor position with the new color
  display->drawPixel(x, y, drawColor);
}

/**
 * @brief Function that finds new color you wish to draw with (from down arrow)
 *
 * This function decrements the color values and has wrap around fucntionality
 * Draws your current pixel in this new color
 */
void prevEtchColor() {
  etchColorIndex = (etchColorIndex - 1 + numColors) % numColors;
  drawColor = colorValues[etchColorIndex];
  
  // redraw the current cursor position with the new color
  display->drawPixel(x, y, drawColor);
}

/**
 * @brief Function that handles commands relating to the Etch A Sketch
 * 
 * Color cycling with arrows and RPG movement for drawing. 
 * - Up arrow increments the pointer of the color
 * - Down arrow decrements the pointer
 * - RPG2 (left) controls left/right (ccw/cw)
 * - RPG1 (right) controls up/down   (ccw/cw)
 * 
 * @param cmd command from the Arduino received over UART
 */
void handleEtchCommand(const String& cmd) {
  if (cmd == "btnUpArrow") {
    nextEtchColor();
    return;
  } 
  else if (cmd == "btnDownArrow") {
    prevEtchColor();
    return;
  }

  // --- RPG1 (X axis) ---
  // bounds 0<63
  if (cmd == "rpg1CW") {
    if (x < 63) x++;
  }
  else if (cmd == "rpg1CCW") {
    if (x > 0) x--;
  }

  // --- RPG2 (Y axis) ---
  // bounds 0<63
  if (cmd == "rpg2CW") {
    if (y > 0) y--;
  }
  else if (cmd == "rpg2CCW") {
    if (y < 63) y++;
  }

  // draw the pixel under the cursor location
  display->drawPixel(x, y, drawColor);
}