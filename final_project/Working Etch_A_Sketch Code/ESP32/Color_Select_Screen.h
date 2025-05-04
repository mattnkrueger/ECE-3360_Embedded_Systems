#ifndef COLOR_SELECT_SCREEN_H
#define COLOR_SELECT_SCREEN_H

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>

extern MatrixPanel_I2S_DMA* dma_display_cs;
extern const char* colorNames[];
extern uint16_t colorValues[];
extern int selectedColorIndex;
extern const int numColors;

void initColorSelector(MatrixPanel_I2S_DMA* display);
void drawColorSelector(uint16_t colorValues[]);
void nextColor();
void prevColor();
uint16_t getCurrentColor();  // <-- ADD THIS


#endif