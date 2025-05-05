#include "packers_logo.h"

// Map character to RGB565 color
uint16_t getColorForChar(char c, MatrixPanel_I2S_DMA* display) {
  switch (c) {
    case 'g': return display->color565(0, 255, 0);   // green
    case 'y': return display->color565(255, 255, 0); // yellow
    case 'w': return display->color565(255, 255, 255); // white
    case 'b': return display->color565(0, 0, 0);    //black
    case 'r': return display->color565(255, 0, 0);   // red
    default:  return display->color565(0, 0, 0);     // default to black
  }
}

void drawLogo(MatrixPanel_I2S_DMA* display) {
  // Logo data: 19 rows, each 28 pixels wide
  const char* logo_rows[] = {
    "bbbbbbbbyyyyyyyyyyyyybbbbbbb",            //line 1
    "bbbbbbyygggggggggggggyybbbbb",          //line 2
    "bbbbyygggwwwwwwwwwwwgggyybbb",        //line 3
    "bbbygggwwwwwwwwwwwwwwwgggybb",    //line 4
    "bbyggwwwwwwwwwwwwwwwwwwwggyb",     //line 5
    "byggwwwwwwgggggggwwwwwwwwggy",    //line 6
    "yggwwwwwwggggggggggwwwwwwwgy",    //line 7
    "ygwwwwwwgggggggggggggggggggy",     //line 8
    "ygwwwwwwgggggggggggggggggggy",     //line 9
    "ygwwwwwwgggggggggggggggggggy",     //line 10
    "ygwwwwwwgggwwwwwwwwwwwwwwwgy",      //line 11
    "ygwwwwwwggggwwwwwwwwwwwwwwgy",     //line 12
    "bygwwwwwwwggggggggwwwwwwwggy", //line 13
    "byggwwwwwwwwwwwwwwwwwwwwggyb",  //line 14
    "bbyggwwwwwwwwwwwwwwwwwwggybb",   //line 15
    "bbbygggwwwwwwwwwwwwwwgggybbb",    //line 16
    "bbbbyyggggwwwwwwwwggggyybbbb",     //line 17
    "bbbbbbyyyggggggggggyyybbbbbb",       //line 18
    "bbbbbbbbbyyyyyyyyyybbbbbbbbb"           //line 19
  };

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
          
          // Only draw pixels that are within bounds
          if (displayX >= 0 && displayX < 64 && displayY >= 0 && displayY < 64) {
            // Special handling for white pixels in the bottom half
            if (pixelChar == 'w' && displayY >= 32) {
              // Try forcing full white for bottom half
              display->drawPixel(displayX, displayY, display->color565(255, 255, 255));
              
              // Alternative approach for white pixels
              display->drawPixelRGB888(displayX, displayY, 255, 255, 255);
            } else {
              display->drawPixel(displayX, displayY, color);
            }
          }
        }
      }
    }
  }
}