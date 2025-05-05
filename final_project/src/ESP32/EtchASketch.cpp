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
static const int MOVEMENT_THRESHOLD = 1; // Adjust this value to control sensitivity

// Direction tracking: -1 for CCW/down, +1 for CW/up
static int lastRPG1Dir = 0;
static int lastRPG2Dir = 0;

void drawCursor() {
  // Optional: call this periodically (e.g. in loop) to blink the cursor
  display->drawPixel(x, y, flashState ? drawColor : display->color565(0, 0, 0));
}

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

  // Reset direction
  lastRPG1Dir = 0;
  lastRPG2Dir = 0;
}

void handleEtchCommand(const String& cmd) {
  // --- RPG1 (X axis) ---
  if (cmd == "rpg1CW" || cmd == "rpg1CCW") {
    int newDir = (cmd == "rpg1CW") ? 1 : -1;
    if (lastRPG1Dir != newDir) {
      rpg1Counter = 0;
      lastRPG1Dir = newDir;
    }
    rpg1Counter++;
  }

  // --- RPG2 (Y axis) ---
  if (cmd == "rpg2CW" || cmd == "rpg2CCW") {
    int newDir = (cmd == "rpg2CW") ? -1 : 1; // Note: Y axis is inverted
    if (lastRPG2Dir != newDir) {
      rpg2Counter = 0;
      lastRPG2Dir = newDir;
    }
    rpg2Counter++;
  }

  // Execute movements if thresholds are met
  if (rpg1Counter >= MOVEMENT_THRESHOLD) {
    int newX = x + lastRPG1Dir;
    if (newX >= 0 && newX < 64) {
      trailPixels[x][y] = true;
      display->drawPixel(x, y, drawColor); // Leave a trail
      x = newX;
    }
    rpg1Counter = 0;
  }

  if (rpg2Counter >= MOVEMENT_THRESHOLD) {
    int newY = y + lastRPG2Dir;
    if (newY >= 0 && newY < 64) {
      trailPixels[x][y] = true;
      display->drawPixel(x, y, drawColor); // Leave a trail
      y = newY;
    }
    rpg2Counter = 0;
  }

  // Draw cursor at new position
  display->drawPixel(x, y, drawColor);
}
