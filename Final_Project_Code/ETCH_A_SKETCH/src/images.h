#ifndef IMAGES_H
#define IMAGES_H

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>

void drawLogo(MatrixPanel_I2S_DMA* display);
int getCurrentImageIndex();
void drawCurrentImage(MatrixPanel_I2S_DMA* display);
void prevImage();
void nextImage();

#endif
