/**
 * @file ColorSelectScreen.cpp
 * @author Matt Krueger & Sage Marks
 * @brief color selection screen first shown when Sketch program is loaded
 * @version 0.1
 * @date 2025-05-05
 * 
 * @copyright Copyright (c) 2025
 * 
 * This gives a screen with the selected color that the sketch program will draw in. It is a simple screen that has colors that can be selected by using the arrow buttons and clicking the home button once
 * 
 */

#include "Sketch/ColorSelectScreen.h"

// matrix object
MatrixPanel_I2S_DMA* dma_display_cs = nullptr;

// possible colors
const char* colorNames[] = { "Red", "Green", "Yellow", "Orange", "Blue", "Purple", "Pink"};

// hold color values in parallel array
uint16_t colorValues[] = {
  0,  // red
  0,  // green
  0,  // yellow
  0,  // orange
  0,  // blue
  0,  // purple
  0,  // pink
};

// initialize color index to 0 and number of colors to 7
int selectedColorIndex = 0;
const int numColors = 7;

/**
 * @brief This function intializes color values for the LED matrix
 * 
 * Each element of the color values array is set to a specific color
 * This is done using the color565
 * 
 * @param display matrix object to draw to 
 */
void initColorSelector(MatrixPanel_I2S_DMA* display) {
  // color565 converts the color to a 16 bit number to be read
  dma_display_cs = display;
  colorValues[0] = dma_display_cs->color565(255, 0, 0);       // red
  colorValues[1] = dma_display_cs->color565(0, 255, 0);       // green
  colorValues[2] = dma_display_cs->color565(255, 255, 0);     // yellow
  colorValues[3] = dma_display_cs->color565(255, 165, 0);     // orange
  colorValues[4] = dma_display_cs->color565(0, 0 , 255);      // blue
  colorValues[5] = dma_display_cs->color565(128, 0, 128);     // purple
  colorValues[6] = dma_display_cs->color565(255, 105, 180);   // pink
}

/**
 * @brief This function draws the current selected color to the LED matrix
 *
 * The top of the screen says color: in white followed by a horizontal white line
 * Then the color you are going to start drawing in is displayed below
 * 
 * @param colorValues 
 */
void drawColorSelector(uint16_t colorValues[]) {
  // if invalid return
  if (!dma_display_cs) return;
  dma_display_cs->fillScreen(0);
  dma_display_cs->setTextSize(1);
  dma_display_cs->setTextWrap(false);

  // display "Select Color" at the top
  dma_display_cs->setCursor(8, 0);
  dma_display_cs->setTextColor(0xFFFF);  // white text for the header
  dma_display_cs->print("Color:");
  dma_display_cs->drawLine(0, 8, dma_display_cs->width(), 8, 0xFFFF); // white line below the title

  // display the selected color name
  // centered and once again with width of 6 pixels
  const char* colorName = colorNames[selectedColorIndex];
  int len = strlen(colorName);
  int textWidth = len * 6;
  int startX = (dma_display_cs->width() - textWidth) / 2;

  // print the color name in that specific color pixel
  dma_display_cs->setCursor(startX, 24);
  dma_display_cs->setTextColor(colorValues[selectedColorIndex]);
  dma_display_cs->print(colorName);
}

/**
 * @brief Function that draws the next color in the color array
 * 
 * This color is displayed on the color select screen
 */
void nextColor() {
  selectedColorIndex = (selectedColorIndex + 1) % numColors;
  drawColorSelector(colorValues);
}

/**
 * @brief Function that gives you the previous color in the color array
 * 
 * This color is displayed on the color select screen
 * 
 */
void prevColor() {
  selectedColorIndex = (selectedColorIndex - 1 + numColors) % numColors;
  drawColorSelector(colorValues);
}

/**
 * @brief Get the Current Color object
 * 
 * @return uint16_t 
 */
uint16_t getCurrentColor() {
  return colorValues[selectedColorIndex];
}