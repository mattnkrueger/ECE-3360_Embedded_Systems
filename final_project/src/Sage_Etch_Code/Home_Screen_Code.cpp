#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>

// Panel config
#define PANEL_WIDTH 64
#define PANEL_HEIGHT 64
#define PANELS_NUMBER 1

// Matrix display object
MatrixPanel_I2S_DMA* dma_display = nullptr;

// Common colors
uint16_t myBLACK;
uint16_t yellow, white, brown, green;

// Menu config
const char* menuItems[] = { "Sketch", "Chess", "Image" };
const int numMenuItems = sizeof(menuItems) / sizeof(menuItems[0]);
int selectedIndex = 0;  // Which item the arrow points to

// Arrow draw helper
void drawArrow(int y) {
  dma_display->setCursor(0, y);
  dma_display->setTextColor(white);
  dma_display->print(">");
}

// Redraws the entire home screen with current selection
void drawHomeScreen() {
  dma_display->fillScreen(myBLACK);
  dma_display->setTextSize(1);
  dma_display->setTextWrap(false);

  // Line 1: "HOME"
  const char* line1 = "HOME";
  int len1 = strlen(line1);
  int charWidth = 6;
  int startX1 = (dma_display->width() - len1 * charWidth) / 2;
  dma_display->setCursor(startX1, 0);

  for (int i = 0; i < len1; i++) {
    dma_display->setTextColor((i % 2 == 0) ? yellow : white);
    dma_display->print(line1[i]);
  }

  dma_display->drawLine(0, 8, PANEL_WIDTH, 8, white);  // Underline

  // Menu Items with double arrow for selected item
  int startY = 10;
  for (int i = 0; i < numMenuItems; i++) {
    const char* label = menuItems[i];
    int len = strlen(label);
    int charWidth = 6;
    int textWidth = len * charWidth;
    int startX = (dma_display->width() - textWidth) / 2;

    if (i == selectedIndex) {
      // Left arrow
      dma_display->setCursor(startX - 8, startY);
      dma_display->setTextColor(white);
      dma_display->print(">");

      // Right arrow
      dma_display->setCursor(startX + textWidth + 2, startY);
      dma_display->setTextColor(white);
      dma_display->print("<");
    }

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
        color = (j % 2 == 0) ? green : yellow;
      }
      dma_display->setTextColor(color);
      dma_display->print(label[j]);
    }

    startY += 10;
  }
}


void setup() {
  Serial.begin(115200);

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
  mxconfig.driver = HUB75_I2S_CFG::FM6126A;
  mxconfig.clkphase = true;

  dma_display = new MatrixPanel_I2S_DMA(mxconfig);
  if (!dma_display->begin()) {
    Serial.println("Matrix init failed!");
    while (true);
  }

  dma_display->setBrightness8(90);
  myBLACK = dma_display->color565(0, 0, 0);
  white   = dma_display->color565(255, 255, 255);
  yellow  = dma_display->color565(255, 255, 0);
  brown   = dma_display->color565(139, 69, 19);
  green   = dma_display->color565(0, 255, 0);

  drawHomeScreen();
}

void loop() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();

    if (cmd == "up") {
      selectedIndex--;
      if (selectedIndex < 0) selectedIndex = numMenuItems - 1;
      drawHomeScreen();
    } else if (cmd == "down") {
      selectedIndex++;
      if (selectedIndex >= numMenuItems) selectedIndex = 0;
      drawHomeScreen();
    }
  }
}
