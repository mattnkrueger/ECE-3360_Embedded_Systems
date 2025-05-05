/**
 * @file main.cpp
 * @author Matt Krueger & Sage Marks
 * @brief ESP32 driver code
 * @version 0.1
 * @date 2025-05-04
 * 
 * @copyright Copyright (c) 2025
 * 
 * This sketch serves as the state machine for the system, reading in new actions from the user over UART connected to IO of Arduino 
 * to perform an action on the current program selected. This is a proof of concept for our system as we developed this as part of 
 * ECE-3360 Embedded Systems course at the University of Iowa. Because of this, our code is not designed all too well. 
 * 
 * Currently Programmed: 
 * - EtchASketch: draw in colors using rotary dials like the original EtchASketch
 * - TicTacToe: uses controllers connected to system 
 * - Logo: shows packers logo
 * 
 * Further iterations will improve the modularity to more easily extend the system to whatever we want to display.
 * 
 */
#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include "packers_logo.h"
#include "Color_Select_Screen.h"
#include "EtchASketch.h"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ Panel Configuration ------------------------------------------ //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define PANEL_WIDTH 64
#define PANEL_HEIGHT 64
#define PANELS_NUMBER 1

// Matrix display object
MatrixPanel_I2S_DMA* dma_display = nullptr;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ UART Configuration ------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define RXD2 16
#define TXD2 17

// Serial equivalent for ESP32. There are multiple uart channes. We use channel 2 as it is easiest to use in with the HUB75E
HardwareSerial mySerial(2);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ Global Variables ------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool inEtchMode = false;
uint16_t selectedColor;

// Common colors
uint16_t myBLACK;
uint16_t yellow, white, brown, green;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ State Machine ------------------------------------------ //
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Menu config
const char* menuItems[] = { "Sketch", "Tic-Tac-Toe", "Image", "Chess (not implemented)" };
const int numMenuItems = sizeof(menuItems) / sizeof(menuItems[0]);
int selectedIndex = 0;

// Screen state enum
enum ScreenState { HOME, COLOR_SELECT, EtchASketch, TicTacToe, LOGO_DISPLAY };
ScreenState currentScreen = HOME;

/**
 * @brief drwas arrow for menu selection
 * 
 * @param y 
 */
void drawArrow(int y) {
  dma_display->fillRect(0, y, 6, 8, myBLACK); // Clear arrow area first
  dma_display->setCursor(0, y);
  dma_display->setTextColor(green);  
  dma_display->print(">");
}

/**
 * @brief draws the current home screen 
 * 
 * Redraws with current selection
 * 
 */
void drawHomeScreen() {
  dma_display->fillScreen(myBLACK);
  dma_display->setTextSize(1);
  dma_display->setTextWrap(false);

  const char* line1 = "HOME";
  int len1 = strlen(line1);
  int charWidth = 6;
  int startX1 = (dma_display->width() - len1 * charWidth) / 2;
  dma_display->setCursor(startX1, 0);

  // draw "Home" in alternating yellow,white text
  for (int i = 0; i < len1; i++) {
    dma_display->setTextColor((i % 2 == 0) ? yellow : white);
    dma_display->print(line1[i]);
  }

  // draw border below "Home" text
  dma_display->drawLine(0, 8, PANEL_WIDTH, 8, white);

  // draw menu 
  int startY = 10;
  for (int i = 0; i < numMenuItems; i++) {
    const char* label = menuItems[i];
    int len = strlen(label);
    int charWidth = 6;
    int textWidth = len * charWidth;
    int startX = (dma_display->width() - textWidth) / 2;

    if (i == selectedIndex) {
        // left arrow - same position as original (-8 pixels from text start)
        dma_display->fillRect(startX - 8, startY, 6, 8, myBLACK); // Clear area
        dma_display->setCursor(startX - 8, startY);
        dma_display->setTextColor(green);
        dma_display->print(">");

        // right arrow - same position as original (+2 pixels from text end)
        dma_display->fillRect(startX + textWidth + 2, startY, 6, 8, myBLACK); // Clear area
        dma_display->setCursor(startX + textWidth + 2, startY);
        dma_display->setTextColor(green);
        dma_display->print("<");
    }

    // styling for specific text
    dma_display->setCursor(startX, startY);
    for (int j = 0; j < len; j++) {
        uint16_t color;
        if (strcmp(label, "Sketch") == 0) {
            uint16_t rainbowColors[] = {
                dma_display->color565(255, 0, 0),
                dma_display->color565(255, 165, 0),
                dma_display->color565(255, 255, 0),
                dma_display->color565(0, 255, 0),
                dma_display->color565(0, 0, 255),
                dma_display->color565(75, 0, 130),
                dma_display->color565(148, 0, 211)
            };
            color = rainbowColors[j % 7];
        } else if (strcmp(label, "Chess") == 0) {
            color = (j % 2 == 0) ? brown : white;
        } else {
            color = yellow;
        }
        dma_display->setTextColor(color);
        dma_display->print(label[j]);
    }
    startY += 10;
}
}

/**
 * @brief initialize the ESP32 system
 * 
 * Configure:
 * - uart
 * - led matrix
 * - display the home screen
 * 
 */
void setup() {
  mySerial.begin(115200);

  // ESP32 DEVKITV1 -> HUB75E 
  //
  //             +----------+-----------+
  // r1:         | R1 (25)  | G1  (26)  |
  //             +----------+-----------+
  // r2:         | B1 (27)  | GND (gnd) |
  //             +----------+-----------+
  // r3:         | R2 (14)  | G2  (12)  |
  //             +----------+-----------+
  // r4:         | B2 (13)  | E   (32)  |
  //             +----------+-----------+
  // r5:         | A (23)   | B   (22   |
  //             +----------+-----------+
  // r6:         |  C (05)  | D   (02)  |
  //             +----------+-----------+
  // r7:         | CLK (33) | LAT (04)  |
  //             +----------+-----------+
  // r8:         | OE (15)  | GND (gnd) |
  //             +----------+-----------+
  //
  // note: no ground connection needed in software.
  HUB75_I2S_CFG mxconfig(PANEL_WIDTH, PANEL_HEIGHT, PANELS_NUMBER);
  mxconfig.gpio.r1 = 25;
  mxconfig.gpio.g1 = 26;
  mxconfig.gpio.b1 = 27;
  mxconfig.gpio.r2 = 14;
  mxconfig.gpio.g2 = 12;
  mxconfig.gpio.b2 = 13;
  mxconfig.gpio.a  = 23;
  mxconfig.gpio.b  = 22;
  mxconfig.gpio.c  = 5;
  mxconfig.gpio.d  = 2;
  mxconfig.gpio.e  = 32;
  mxconfig.gpio.lat = 4;
  mxconfig.gpio.oe  = 15;
  mxconfig.gpio.clk = 33;
  
  // broken clone board uses different matrix driver. Waveshare board uses the ICN2038S
  //mxconfig.driver = HUB75_I2S_CFG::FM6126A;
  mxconfig.driver = HUB75_I2S_CFG::ICN2038S;
  mxconfig.clkphase = false;

  dma_display = new MatrixPanel_I2S_DMA(mxconfig);
  if (!dma_display->begin()) {
    mySerial.println("Matrix init failed!");
    while (true);
  }

  dma_display->setBrightness8(90);
  myBLACK = dma_display->color565(0, 0, 0);
  white = dma_display->color565(220, 220, 220);
  yellow  = dma_display->color565(255, 255, 0);
  brown   = dma_display->color565(139, 69, 19);
  green   = dma_display->color565(0, 255, 0);

  initColorSelector(dma_display);
  drawHomeScreen();
}

/**
 * @brief ESP32 program loop
 * 
 * Checks for the current state and maps to desired program
 * 
 */
void loop() {
  // incoming action from Arduino I/O
  if (mySerial.available()) {
    String cmd = mySerial.readStringUntil('\n');
    cmd.trim();

    // home screen
    if (currentScreen == HOME) {
      if (cmd == "btnUpArrow") {
        selectedIndex--;
        if (selectedIndex < 0) selectedIndex = numMenuItems - 1;
        drawHomeScreen();
      }
      else if (cmd == "btnDownArrow") {
        selectedIndex++;
        if (selectedIndex >= numMenuItems) selectedIndex = 0;
        drawHomeScreen();
      }
      else if (cmd == "btnHomeClick") {
        if (strcmp(menuItems[selectedIndex], "Sketch") == 0) {
          currentScreen = COLOR_SELECT;
          drawColorSelector(colorValues);
        }
        else if (strcmp(menuItems[selectedIndex], "Image") == 0) {
          currentScreen = LOGO_DISPLAY;
          drawLogo(dma_display);
        }
      }
    }
    
    // color select for EtchASketch
    else if (currentScreen == COLOR_SELECT) {
      if (cmd == "btnUpArrow") {
        prevColor();
      } 
      else if (cmd == "btnDownArrow") {
        nextColor();
      } 
      else if (cmd == "btnHomeClick") {
        selectedColor = getCurrentColor();
        currentScreen = EtchASketch;
        inEtchMode = true;
        initEtchASketch(dma_display, selectedColor);
      } 
      else if (cmd == "btnHomeHold") {
        currentScreen = HOME;
        drawHomeScreen();
      }
    }

    // EtchASketch Program
    else if (currentScreen == EtchASketch) {
      if (cmd == "btnHomeHold") {
        currentScreen = HOME;
        inEtchMode = false;
        drawHomeScreen();
      } else {
        handleEtchCommand(cmd);
      }
    }

    // Logo Display program
    else if (currentScreen == LOGO_DISPLAY) {
      if (cmd == "btnHomeHold") {
        currentScreen = HOME;
        drawHomeScreen();
      }
    }
  }
}