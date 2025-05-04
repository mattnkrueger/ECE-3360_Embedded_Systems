#ifndef ETCHASKETCH_H
#define ETCHASKETCH_H

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>

void initEtchASketch(MatrixPanel_I2S_DMA* display, uint16_t color);
void handleEtchCommand(const String& cmd);
void updateEtchFlash();  // <- Add this line

#endif
