#include "hawkeyes_logo.h"

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

/*
* @brief Function that draws an image to the LED matrix
* This function draws the packers logo to the matrix
* An initial grid fo 19 x 28 is made using green, white, and yellow pixels
* This grid is then scaled up and centered on the display
*/
void drawLogo(MatrixPanel_I2S_DMA* display) {
  // Logo data: 19 rows, each 28 pixels wide
  const char* logo_rows[] = {
    "bbbbbbbbbbbbbbbbbbbb" // line 1
    "bbbbbbbbbbbbbbbbbbbb" // line 2   
    "bbbbbbbbbbbbbbbbbbbb" // line 3
    "bbbbbbbbbbbbbbbbbbbb" // line 4

    ///this part has yellow
    "bbbbbyyyyyyyyybbbbbb" // line 5
    "bbbyyyyyyyyyyyyybbbb" // line 6
    "bbyyyyyyyyyyyyyybbbb" // line 7
    "byyyyyyyybyyybyybbbb" // line 8
    "byyyyyybbbyyybbbbybb" // line 9
    "bbyyyybyybbbbbbbyyyb" // line 10
    "byyyyybyyyyyybbyyyyb" // line 11
    "bbyyybbbyyyyybyyyyyb" // line 12
    "byyybbbyyyyybbbbbyyb" // line 13
    "bbybbbyyyyyybbybbbyb" // line 14
    "bbbbbbyyyyybbbyybbbb" // line 15
    "bbbbbbbyybbbbbbbbbbb" // line 16

    "bbbbbbbbbbbbbbbbbbbb" // line 17
    "bbbbbbbbbbbbbbbbbbbb" // line 18
    "bbbbbbbbbbbbbbbbbbbb" // line 19
    "bbbbbbbbbbbbbbbbbbbb" // line 20
  };

  //Calculate the number of rows and the number of columns
  int rowCount = sizeof(logo_rows) / sizeof(logo_rows[0]);
  int colCount = strlen(logo_rows[0]);
  
  // Scale factor for doubling the size
  int scaleFactor = 2;
  
  // Calculate offsets to center the doubled logo on a 64x64 display
  int xOffset = (64 - (colCount * scaleFactor)) / 2;
  int yOffset = (64 - (rowCount * scaleFactor)) / 2;

  // Clear the display first
  display->fillScreen(display->color565(0, 0, 0));
  
  // Draw the logo with doubled size
  for (int y = 0; y < rowCount; y++) {
    for (int x = 0; x < colCount; x++) {
      char pixelChar = logo_rows[y][x];
      uint16_t color = getColorForChar(pixelChar, display);
      
      // Draw a 2x2 block for each original pixel
      for (int sy = 0; sy < scaleFactor; sy++) {
        for (int sx = 0; sx < scaleFactor; sx++) {
            // Apply offsets to center the scaled image
            int displayX = (x * scaleFactor) + sx + xOffset;
            int displayY = (y * scaleFactor) + sy + yOffset;
            //draw the actual pixels
            display->drawPixel(displayX, displayY, color);
            }
          }
        }
      }
    }