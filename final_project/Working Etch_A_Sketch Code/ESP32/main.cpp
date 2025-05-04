#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include "packers_logo.h"
#include "Color_Select_Screen.h"
#include "EtchASketch.h"

// Panel config
#define PANEL_WIDTH 64
#define PANEL_HEIGHT 64
#define PANELS_NUMBER 1

#define RXD2 16
#define TXD2 17

bool inEtchMode = false;
uint16_t selectedColor;

// Matrix display object
MatrixPanel_I2S_DMA* dma_display = nullptr;

HardwareSerial mySerial(2);

// Common colors
uint16_t myBLACK;
uint16_t yellow, white, brown, green;

// Menu config
const char* menuItems[] = { "Sketch", "Chess", "Image" };
const int numMenuItems = sizeof(menuItems) / sizeof(menuItems[0]);
int selectedIndex = 0;

// Screen state enum
enum ScreenState { HOME, COLOR_SELECT, EtchASketch, LOGO_DISPLAY };
ScreenState currentScreen = HOME;

// Arrow draw helper - This is the version that will be used
void drawArrow(int y) {
  dma_display->fillRect(0, y, 6, 8, myBLACK); // Clear arrow area first
  dma_display->setCursor(0, y);
  dma_display->setTextColor(green);  // Now properly set to green
  dma_display->print(">");
}

// Redraws the entire home screen with current selection
void drawHomeScreen() {
  dma_display->fillScreen(myBLACK);
  dma_display->setTextSize(1);
  dma_display->setTextWrap(false);

  const char* line1 = "HOME";
  int len1 = strlen(line1);
  int charWidth = 6;
  int startX1 = (dma_display->width() - len1 * charWidth) / 2;
  dma_display->setCursor(startX1, 0);

  for (int i = 0; i < len1; i++) {
    dma_display->setTextColor((i % 2 == 0) ? yellow : white);
    dma_display->print(line1[i]);
  }

  dma_display->drawLine(0, 8, PANEL_WIDTH, 8, white);
  // In drawHomeScreen():
  int startY = 10;
  for (int i = 0; i < numMenuItems; i++) {
    const char* label = menuItems[i];
    int len = strlen(label);
    int charWidth = 6;
    int textWidth = len * charWidth;
    int startX = (dma_display->width() - textWidth) / 2;

    if (i == selectedIndex) {
        // Left arrow - same position as original (-8 pixels from text start)
        dma_display->fillRect(startX - 8, startY, 6, 8, myBLACK); // Clear area
        dma_display->setCursor(startX - 8, startY);
        dma_display->setTextColor(green);
        dma_display->print(">");

        // Right arrow - same position as original (+2 pixels from text end)
        dma_display->fillRect(startX + textWidth + 2, startY, 6, 8, myBLACK); // Clear area
        dma_display->setCursor(startX + textWidth + 2, startY);
        dma_display->setTextColor(green);
        dma_display->print("<");
    }

    // Rest of your text drawing code...
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

void setup() {
  mySerial.begin(115200);

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

void loop() {
  if (mySerial.available()) {
    String cmd = mySerial.readStringUntil('\n');
    cmd.trim();

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
    else if (currentScreen == EtchASketch) {
      if (cmd == "btnHomeHold") {
        currentScreen = HOME;
        inEtchMode = false;
        drawHomeScreen();
      } else {
        handleEtchCommand(cmd);
      }
    }
    else if (currentScreen == LOGO_DISPLAY) {
      if (cmd == "btnHomeHold") {
        currentScreen = HOME;
        drawHomeScreen();
      }
    }
  }
}