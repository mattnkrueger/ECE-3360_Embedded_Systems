#include "EtchASketch.h"
#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <Arduino.h>

static int x = 32;
static int y = 32;
static uint16_t drawColor;
static MatrixPanel_I2S_DMA* display;

static bool flashState = true;  // Start with cursor visible
static unsigned long lastFlashTime = 0;
static bool trailPixels[64][64]; // Track where we've drawn

// Variables for thresholding movement
static int rpg1Counter = 0;
static int rpg2Counter = 0;
static const int MOVEMENT_THRESHOLD = 3; // Adjust this value to control sensitivity

// Called when entering Etch-a-Sketch mode
void initEtchASketch(MatrixPanel_I2S_DMA* disp, uint16_t color) {
  display = disp;
  drawColor = color;
  x = 32;
  y = 32;
  
  // Clear screen and reset trail tracking
  display->fillScreen(display->color565(0, 0, 0));
  for (int i = 0; i < 64; i++) {
    for (int j = 0; j < 64; j++) {
      trailPixels[i][j] = false;
    }
  }
  
  // Start with cursor visible
  display->drawPixel(x, y, drawColor);
  flashState = true;
  lastFlashTime = millis();
  
  // Reset counters
  rpg1Counter = 0;
  rpg2Counter = 0;
}

// Handles movement commands from Arduino
void handleEtchCommand(const String& cmd) {
  bool moved = false;
  
  // If we're at a trail location, make sure we leave it visible
  if (trailPixels[x][y]) {
    display->drawPixel(x, y, drawColor);
  }

  // Count rotary encoder movements and only move pixel when threshold is reached
  if (cmd == "rpg1CW") {
    rpg1Counter++;
    if (rpg1Counter >= MOVEMENT_THRESHOLD) {
      if (x < 63) {
        // Mark current position as part of the trail
        trailPixels[x][y] = true;
        display->drawPixel(x, y, drawColor); // Ensure trail is visible
        x++;
        moved = true;
      }
      rpg1Counter = 0; // Reset counter
    }
  } else if (cmd == "rpg1CCW") {
    rpg1Counter++;
    if (rpg1Counter >= MOVEMENT_THRESHOLD) {
      if (x > 0) {
        // Mark current position as part of the trail
        trailPixels[x][y] = true;
        display->drawPixel(x, y, drawColor); // Ensure trail is visible
        x--;
        moved = true;
      }
      rpg1Counter = 0; // Reset counter
    }
  } else if (cmd == "rpg2CW") {
    rpg2Counter++;
    if (rpg2Counter >= MOVEMENT_THRESHOLD) {
      if (y > 0) {
        // Mark current position as part of the trail
        trailPixels[x][y] = true;
        display->drawPixel(x, y, drawColor); // Ensure trail is visible
        y--;
        moved = true;
      }
      rpg2Counter = 0; // Reset counter
    }
  } else if (cmd == "rpg2CCW") {
    rpg2Counter++;
    if (rpg2Counter >= MOVEMENT_THRESHOLD) {
      if (y < 63) {
        // Mark current position as part of the trail
        trailPixels[x][y] = true;
        display->drawPixel(x, y, drawColor); // Ensure trail is visible
        y++;
        moved = true;
      }
      rpg2Counter = 0; // Reset counter
    }
  }
}