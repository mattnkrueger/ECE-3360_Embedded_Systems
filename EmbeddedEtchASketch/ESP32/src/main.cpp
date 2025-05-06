/**
 * @file main.cpp
 * @author Matt Krueger & Sage Marks
 * @brief ESP32 driver code
 * @version 0.1
 * @date May 7th, 2025
 * 
 * @copyright Copyright (c) 2025
 * 
 * This sketch serves as the state machine for the system, reading in new actions from the user over UART connected to IO of Arduino 
 * to perform an action on the current program selected. This is a proof of concept for our system as we developed this as part of 
 * ECE-3360 Embedded Systems course at the University of Iowa. Because of this, our code is not designed all too well. 
 * 
 * Currently Programmed: 
 * - EtchASketch: draw in colors using rotary dials like the original EtchASketch
 * - Pixel Art: displays slideshow of pixel art images
 * 
 * Further iterations will improve the modularity to more easily extend the system to whatever we want to display.
 * 
 */

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include "PixelArt/PixelArt.h"
#include "EtchASketch/ColorSelectScreen.h"
#include "EtchASketch/EtchASketch.h"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ Panel Configuration ------------------------------------------ //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define PANEL_WIDTH 64
#define PANEL_HEIGHT 64
#define PANELS_NUMBER 1

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ UART Configuration ------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define RXD2 16
#define TXD2 17

// IMPORTANT: using serial communication channel 2 on ESP32. This is easiest to use with the HUB75E interface
HardwareSerial mySerial(2);


////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ Global Variables ------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// matrix object
MatrixPanel_I2S_DMA* dma_display = nullptr;


// colors similar to example code in ESP32 HUB75... library examples. These are later defined for modular usage
uint16_t myBLACK;
uint16_t yellow, white, brown, green;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ State Machine ------------------------------------------ //
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// starting state
bool inEtchMode = false;
uint16_t selectedColor;

// currently supported menu items
const char* menuItems[] = { "Sketch", "Images" };
const int numMenuItems = 2;
int selectedIndex = 0;

// supported pages
enum ScreenState { HOME, COLOR_SELECT, EtchASketch, LOGO_DISPLAY };
ScreenState currentScreen = HOME;

/**
 * @brief draws arrow for menu selection
 * 
 * @param y column location to start the arrow
 */
void drawArrow(int y) {
  dma_display->fillRect(0, y, 6, 8, myBLACK); 
  dma_display->setCursor(0, y);
  dma_display->setTextColor(green);  
  dma_display->print(">");
}

/**
 * @brief draws the current home screen 
 * 
 * Redraws with current selection. Arrows depict the currently selected menu item.
 * 
 */
void drawHomeScreen() {
  dma_display->fillScreen(myBLACK);
  dma_display->setTextSize(1);
  dma_display->setTextWrap(false);
  

  // Navbar: 'Home'
  const char* line1 = "HOME";
  int len1 = strlen(line1);
  int charWidth = 6;
  int startX1 = (dma_display->width() - len1 * charWidth) / 2;
  dma_display->setCursor(startX1, 0);

  // alternating styling of home text
  for (int i = 0; i < len1; i++) {
    dma_display->setTextColor((i % 2 == 0) ? yellow : white);
    dma_display->print(line1[i]);
  }

  // navbar border
  dma_display->drawLine(0, 8, PANEL_WIDTH, 8, white);

  // options menu
  int startY = 10;
  for (int i = 0; i < numMenuItems; i++) {
    const char* label = menuItems[i];
    int len = strlen(label);
    int charWidth = 6;
    int textWidth = len * charWidth;
    int startX = (dma_display->width() - textWidth) / 2;

    // draw arrows with some padding. this is how we are depicting the item to be selected with the next click of 'Home'
    if (i == selectedIndex) {
        dma_display->fillRect(startX - 8, startY, 6, 8, myBLACK); // left arrow
        dma_display->setCursor(startX - 8, startY);
        dma_display->setTextColor(green);
        dma_display->print(">");

        dma_display->fillRect(startX + textWidth + 2, startY, 6, 8, myBLACK); // right arrow 
        dma_display->setCursor(startX + textWidth + 2, startY);
        dma_display->setTextColor(green);
        dma_display->print("<");
    }

    // draw the code with styling:
    // "Sketch" is rainbow
    // "Image" is yellow
    dma_display->setCursor(startX, startY);
    for (int j = 0; j < len; j++) {
        uint16_t color;
        if (strcmp(label, "Sketch") == 0) {
            uint16_t rainbowColors[] = {
                dma_display->color565(255, 0, 0),     // red
                dma_display->color565(255, 165, 0),   // orange
                dma_display->color565(255, 255, 0),   // yellow
                dma_display->color565(0, 255, 0),     // green
                dma_display->color565(0, 0, 255),     // blue
                dma_display->color565(75, 0, 130),    // indigo
                dma_display->color565(148, 0, 211)    // violet
            };
            color = rainbowColors[j % 7];
        } 
        else {
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

  
  // VERY IMPORTANT: matrix configuration
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
  // this is used for our ESP32 DEVKITV1 -> HUB75E interface
  HUB75_I2S_CFG mxconfig(PANEL_WIDTH, PANEL_HEIGHT, PANELS_NUMBER);
  mxconfig.gpio.r1  = 25;
  mxconfig.gpio.g1  = 26;
  mxconfig.gpio.b1  = 27;
  mxconfig.gpio.r2  = 14;
  mxconfig.gpio.g2  = 12;
  mxconfig.gpio.b2  = 13;
  mxconfig.gpio.a   = 23;
  mxconfig.gpio.b   = 22;
  mxconfig.gpio.c   = 5;
  mxconfig.gpio.d   = 2;
  mxconfig.gpio.e   = 32;
  mxconfig.gpio.lat = 4;
  mxconfig.gpio.oe  = 15;
  mxconfig.gpio.clk = 33;

  //Set the matrix driver and correct clock phase
  mxconfig.driver = HUB75_I2S_CFG::ICN2038S;
  mxconfig.clkphase = false;

  //Check if matrix was correctly initialized
  dma_display = new MatrixPanel_I2S_DMA(mxconfig);
  if (!dma_display->begin()) {
    mySerial.println("Matrix init failed!");
    while (true);
  }

  //Set matrix brightness and common colors
  dma_display->setBrightness8(90);
  myBLACK = dma_display->color565(0, 0, 0);
  white = dma_display->color565(220, 220, 220);
  yellow  = dma_display->color565(255, 255, 0);
  brown   = dma_display->color565(139, 69, 19);
  green   = dma_display->color565(0, 255, 0);

  //Initialize color selector by passing dma_display object
  //Draw the home screen
  initColorSelector(dma_display);
  drawHomeScreen();
}

/*
* @brief Main loop for ESP32 and Matrix communication
* Reads serial commands from the arduino 
* Uses specific functionality with commands and the window that is open to do tasks
*/
void loop() {
  //Check if serial is open and read serial commands from arduino
  if (mySerial.available()) {
    String cmd = mySerial.readStringUntil('\n');
    cmd.trim();

    /////////////////////////////////////////
    // ----------- HOME SCREEN ----------- //     
    /////////////////////////////////////////
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
        else if (strcmp(menuItems[selectedIndex], "Images") == 0) {
          currentScreen = LOGO_DISPLAY;
          drawCurrentImage(dma_display);
        }
      }
    }

    /////////////////////////////////////////
    // ----------- COLOR SELECT ---------- //     this is part of etchasketch program... user can select the color here before entering the program
    /////////////////////////////////////////
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
    
    /////////////////////////////////////////
    // ----------- ETCHASKETCH ----------- //
    /////////////////////////////////////////
    else if (currentScreen == EtchASketch) {
      if (cmd == "btnHomeHold") {
        currentScreen = HOME;
        inEtchMode = false;
        drawHomeScreen();
      } else if (cmd == "btnUpArrow") {
        handleEtchCommand(cmd);
      } else if (cmd == "btnDownArrow") {
        handleEtchCommand(cmd);
      } else {
        handleEtchCommand(cmd);
      }
    }
    
    /////////////////////////////////////////
    // ------------ PIXEL ART ------------ //
    /////////////////////////////////////////
    else if (currentScreen == LOGO_DISPLAY) {
      if (cmd == "btnHomeHold") {
        currentScreen = HOME;
        drawHomeScreen();
      }
      else if (cmd == "btnUpArrow") {
        prevImage();
        drawCurrentImage(dma_display);
      }
      else if (cmd == "btnDownArrow") {
        nextImage();
        drawCurrentImage(dma_display);
      }
      else if (cmd == "btnHomeClick") {
        drawCurrentImage(dma_display);
      }
    }
  }
}