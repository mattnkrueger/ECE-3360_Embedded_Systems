#include "Color_Select_Screen.h"

MatrixPanel_I2S_DMA* dma_display_cs = nullptr;

const char* colorNames[] = { "Red", "Green", "Yellow", "Orange", "Blue", "Purple", "Pink"};
uint16_t colorValues[] = {
  0,  // Red
  0,  // Green
  0,  // Yellow
  0,  // Orange
  0,  //Blue
  0,  //Purple
  0,  //Pink
};
int selectedColorIndex = 0;
const int numColors = sizeof(colorNames) / sizeof(colorNames[0]);

void initColorSelector(MatrixPanel_I2S_DMA* display) {
  dma_display_cs = display;
  colorValues[0] = dma_display_cs->color565(255, 0, 0);       // Red
  colorValues[1] = dma_display_cs->color565(0, 255, 0);       // Green
  colorValues[2] = dma_display_cs->color565(255, 255, 0);     // Yellow
  colorValues[3] = dma_display_cs->color565(255, 165, 0);     // Orange
  colorValues[4] = dma_display_cs->color565(0, 0 , 255);      //Blue
  colorValues[5] = dma_display_cs->color565(128, 0, 128);     //Purple
  colorValues[6] = dma_display_cs->color565(255, 105, 180);   //Pink
}

void drawColorSelector(uint16_t colorValues[]) {
  if (!dma_display_cs) return;
  dma_display_cs->fillScreen(0);
  dma_display_cs->setTextSize(1);
  dma_display_cs->setTextWrap(false);

  // Display "Select Color" at the top
  dma_display_cs->setCursor(8, 0);
  dma_display_cs->setTextColor(0xFFFF);  // White text for the header
  dma_display_cs->print("Color:");

  dma_display_cs->drawLine(0, 8, dma_display_cs->width(), 8, 0xFFFF);  // White line below the title

  // Display the selected color name
  const char* colorName = colorNames[selectedColorIndex];
  int len = strlen(colorName);
  int textWidth = len * 6;
  int startX = (dma_display_cs->width() - textWidth) / 2;

  dma_display_cs->setCursor(startX, 24);
  dma_display_cs->setTextColor(colorValues[selectedColorIndex]);
  dma_display_cs->print(colorName);
}

void nextColor() {
  selectedColorIndex = (selectedColorIndex + 1) % numColors;
  drawColorSelector(colorValues);
}

void prevColor() {
  selectedColorIndex = (selectedColorIndex - 1 + numColors) % numColors;
  drawColorSelector(colorValues);
}

uint16_t getCurrentColor() {
  return colorValues[selectedColorIndex];
}