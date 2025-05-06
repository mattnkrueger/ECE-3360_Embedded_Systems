/**
 * @file SketchProgram.cpp
 * @author Matt Krueger & Sage Marks
 * @brief implementation of Sketch program
 * @version 0.1
 * @date 2025-05-05
 * 
 * @copyright Copyright (c) 2025
 * 
 * This sketch implements the Sketch program (extended 'EtchASketch' with colors) for the LED Matrix. 
 */

#include "Sketch/SketchProgram.h"
#include "Sketch/ColorSelectScreen.h"
#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <Arduino.h>

// center the cursor to start drawing (64x64 matrix)
static int x = 32;
static int y = 32;
static uint16_t drawColor;
static MatrixPanel_I2S_DMA* display;

// variables for thresholding movement
static int rpg1Counter = 0;
static int rpg2Counter = 0;
static const int MOVEMENT_THRESHOLD = 1; // adjust this value to control sensitivity of the rpg. 

// track our current color index
static int etchColorIndex = 0; 

/**
 * @brief Functionthat intializes the etch a sketch
 * resets RPG counters and direction
 * sets the location of the cursor to the center
 * 
 * @param disp matrix object to draw on
 * @param color current color in use
 */
void initSketch(MatrixPanel_I2S_DMA* disp, uint16_t color) {
  display = disp;
  drawColor = color;
  
  // Find the index of the initial color
  for (int i = 0; i < numColors; i++) {
    if (colorValues[i] == color) {
      etchColorIndex = i;
      break;
    }
  }
  
  //set the cursor to the middle of the screen
  x = 32;
  y = 32;

  // Clear screen
  display->fillScreen(display->color565(0, 0, 0));

  // Draw current pixel the cursor is on in selected color
  display->drawPixel(x, y, drawColor);
}

/** 
* @brief Function that finds new color you wish to draw with (from up arrow)
* This function increments the color values and has wrap around fucntionality
* Draws your current pixel in this new color
*/
void nextEtchColor() {
  etchColorIndex = (etchColorIndex + 1) % numColors;
  drawColor = colorValues[etchColorIndex];
  
  // Redraw the current cursor position with the new color
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
  
  // Redraw the current cursor position with the new color
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
  if (cmd == "rpg1CW") {
    // limit so that we stay on the matrix
    // clockwise increments the x
    if (x < 63) x++;
  }
  else if (cmd == "rpg1CCW") {
    // CCW decrements the x
    if (x > 0) x--;
  }

  // --- RPG2 (Y axis) ---
  if (cmd == "rpg2CW") {
    // y-axis is inverted so CW results in decremented y
    if (y > 0) y--;
  }
  else if (cmd == "rpg2CCW") {
    // limit so we stay on the matrix
    // y-axis is inverted so CCW results in incremented y
    if (y < 63) y++;
  }
  // leave a trail and draw at new position
  display->drawPixel(x, y, drawColor);
}