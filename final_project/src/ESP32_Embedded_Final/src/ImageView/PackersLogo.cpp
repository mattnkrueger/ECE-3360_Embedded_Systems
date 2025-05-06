/**
 * @file PackersLogo.cpp
 * @author Matt Krueger & Sage Marks
 * @brief draws packers logo to LED Matrix
 * @version 0.1
 * @date 2025-05-05
 * 
 * This file draws the Green Bay Packer's logo to the LED Matrix in the center of the screen.
 * 
 * @copyright Copyright (c) 2025
 * 
 */

#include "ImageView/PackersLogo.h"

// Map character to RGB565 color
uint16_t getColorForChar(char c, MatrixPanel_I2S_DMA* display) {
  switch (c) {
    case 'g': return display->color565(0, 255, 0);     // green
    case 'y': return display->color565(255, 255, 0);   // yellow
    case 'w': return display->color565(255, 255, 255); // white
    case 'b': return display->color565(0, 0, 0);       //black
    case 'r': return display->color565(255, 0, 0);     // red
    default:  return display->color565(0, 0, 0);       // default to black (nothing lit up)
  }
}

/**
 * @brief Function that draws an image to the LED matrix
 *
 * This function draws the packers logo to the matrix
 * An initial grid fo 19 x 28 is made using green, white, and yellow pixels
 * This grid is then scaled up and centered on the display
 * 
 * @param display matrix object
 */
void drawLogo(MatrixPanel_I2S_DMA* display) {
  const char* logo_rows[] = {
    "bbbbbbbbyyyyyyyyyyyyybbbbbbb",     // line 1
    "bbbbbbyygggggggggggggyybbbbb",     // line 2
    "bbbbyygggwwwwwwwwwwwgggyybbb",     // line 3
    "bbbygggwwwwwwwwwwwwwwwgggybb",     // line 4
    "bbyggwwwwwwwwwwwwwwwwwwwggyb",     // line 5
    "byggwwwwwwgggggggwwwwwwwwggy",     // line 6
    "yggwwwwwwggggggggggwwwwwwwgy",     // line 7
    "ygwwwwwwgggggggggggggggggggy",     // line 8
    "ygwwwwwwgggggggggggggggggggy",     // line 9
    "ygwwwwwwgggggggggggggggggggy",     // line 10
    "ygwwwwwwgggwwwwwwwwwwwwwwwgy",     // line 11
    "ygwwwwwwggggwwwwwwwwwwwwwwgy",     // line 12
    "bygwwwwwwwggggggggwwwwwwwggy",     // line 13
    "byggwwwwwwwwwwwwwwwwwwwwggyb",     // line 14
    "bbyggwwwwwwwwwwwwwwwwwwggybb",     // line 15
    "bbbygggwwwwwwwwwwwwwwgggybbb",     // line 16
    "bbbbyyggggwwwwwwwwggggyybbbb",     // line 17
    "bbbbbbyyyggggggggggyyybbbbbb",     // line 18
    "bbbbbbbbbyyyyyyyyyybbbbbbbbb"      // line 19
  };

  // calculate the number of rows and the number of columns
  int rowCount = sizeof(logo_rows) / sizeof(logo_rows[0]);
  int colCount = strlen(logo_rows[0]);
  
  // scale factor for doubling the size
  int scaleFactor = 2;
  
  // calculate offsets to center the doubled logo on a 64x64 display
  int xOffset = (64 - (colCount * scaleFactor)) / 2;
  int yOffset = (64 - (rowCount * scaleFactor)) / 2;

  // clear the display first
  display->fillScreen(display->color565(0, 0, 0));
  
  // draw the logo with doubled size
  for (int y = 0; y < rowCount; y++) {
    for (int x = 0; x < colCount; x++) {
      char pixelChar = logo_rows[y][x];
      uint16_t color = getColorForChar(pixelChar, display);
      
      // draw a 2x2 block for each original pixel
      for (int sy = 0; sy < scaleFactor; sy++) {
        for (int sx = 0; sx < scaleFactor; sx++) {
            int displayX = (x * scaleFactor) + sx + xOffset; 
            int displayY = (y * scaleFactor) + sy + yOffset;
            display->drawPixel(displayX, displayY, color);
            }
          }
        }
      }
    }