#ifndef ETCH_A_SKETCH_H
#define ETCH_A_SKETCH_H

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <Arduino.h>

// Initialize the Etch-A-Sketch with the display and drawing color
void initEtchASketch(MatrixPanel_I2S_DMA* disp, uint16_t color);

// Handle rotary encoder commands
void handleEtchCommand(const String& cmd);

// Cycle through available colors
void nextEtchColor();
void prevEtchColor();

#endif // ETCH_A_SKETCH_H