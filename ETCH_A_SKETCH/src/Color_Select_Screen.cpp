#include "Color_Select_Screen.h"

//Pointer (dma_display_cs to the MatrixPanel_I2S_DMA object initialized
MatrixPanel_I2S_DMA* dma_display_cs = nullptr;

//Make an array of pointers for all possible drawing colors
const char* colorNames[] = { "Red", "Green", "Yellow", "Orange", "Blue", "Purple", "Pink"};

//initialize Color values to be 0
uint16_t colorValues[] = {
  0,  // Red
  0,  // Green
  0,  // Yellow
  0,  // Orange
  0,  //Blue
  0,  //Purple
  0,  //Pink
};

//initialize color index to 0 and number of colors to 7
int selectedColorIndex = 0;
const int numColors = 7;

/*
* @brief This function intializes color values for the LED matrix
* Each element of the color values array is set to a specific color
* This is done using the color565
*/
void initColorSelector(MatrixPanel_I2S_DMA* display) {
  //pointer to the matrix object 
  //color565 converts the color to a 16 bit number to be read
  dma_display_cs = display;
  colorValues[0] = dma_display_cs->color565(255, 0, 0);       // Red
  colorValues[1] = dma_display_cs->color565(0, 255, 0);       // Green
  colorValues[2] = dma_display_cs->color565(255, 255, 0);     // Yellow
  colorValues[3] = dma_display_cs->color565(255, 165, 0);     // Orange
  colorValues[4] = dma_display_cs->color565(0, 0 , 255);      //Blue
  colorValues[5] = dma_display_cs->color565(128, 0, 128);     //Purple
  colorValues[6] = dma_display_cs->color565(255, 105, 180);   //Pink
}

/*
* @brief This function draws the current selected color to the LED matrix
* The top of the screen says color: in white followed by a horizontal white line
* Then the color you are going to start drawing in is displayed below
*/
void drawColorSelector(uint16_t colorValues[]) {
  //If invalid return
  if (!dma_display_cs) return;
  dma_display_cs->fillScreen(0);
  dma_display_cs->setTextSize(1);
  dma_display_cs->setTextWrap(false);

  // Display "Select Color" at the top
  dma_display_cs->setCursor(8, 0);
  // White text for the header
  dma_display_cs->setTextColor(0xFFFF);  
  dma_display_cs->print("Color:");

  // White line below the title
  dma_display_cs->drawLine(0, 8, dma_display_cs->width(), 8, 0xFFFF);

  // Display the selected color name
  // Centered and once again with width of 6 pixels
  const char* colorName = colorNames[selectedColorIndex];
  int len = strlen(colorName);
  int textWidth = len * 6;
  int startX = (dma_display_cs->width() - textWidth) / 2;

  //print the color name in that specific color pixel
  dma_display_cs->setCursor(startX, 24);
  dma_display_cs->setTextColor(colorValues[selectedColorIndex]);
  dma_display_cs->print(colorName);
}

/*
* @brief Function that draws the next color in the color array
* This color is displayed on the color select screen
*/
void nextColor() {
  selectedColorIndex = (selectedColorIndex + 1) % numColors;
  drawColorSelector(colorValues);
}

/*
* @brief Function that gives you the previous color in the color array
* This color is displayed on the color select screen
*/
void prevColor() {
  //indexing with wrap around from 0 to numColors-1
  //modulo is for wrapping
  selectedColorIndex = (selectedColorIndex - 1 + numColors) % numColors;
  drawColorSelector(colorValues);
}

/*
*@brief Function that returns the current color value from the array at your index
*/
uint16_t getCurrentColor() {
  return colorValues[selectedColorIndex];
}