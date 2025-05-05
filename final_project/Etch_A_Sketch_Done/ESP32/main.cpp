/*
*Main library for communication with the LED Matrix is the ESP32-HUB75-MATRIXPANEL
*Separate different functionality into separate cpp files and respective headers
*/
#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include "packers_logo.h"
#include "Color_Select_Screen.h"
#include "EtchASketch.h"

//Panel configurations
#define PANEL_WIDTH 64
#define PANEL_HEIGHT 64
#define PANELS_NUMBER 1

//UART communication pins (with Arduino)
#define RXD2 16
#define TXD2 17

//Set variable for sketch mode to false intiially
bool inEtchMode = false;
uint16_t selectedColor;

//Matrix display object
MatrixPanel_I2S_DMA* dma_display = nullptr;

//Using Serial communication channel 2 on ESP32
HardwareSerial mySerial(2);

//Initialize common colors for menu
uint16_t myBLACK;
uint16_t yellow, white, brown, green;

//Configure Menu Options
//Array of pointer characters
const char* menuItems[] = { "Sketch", "Games", "Image" };
const int numMenuItems = 3;
int selectedIndex = 0;

//Screen state enumeration
//Initial state is home screen
//Lists the possible states the screen may be in
enum ScreenState { HOME, COLOR_SELECT, EtchASketch, LOGO_DISPLAY };
ScreenState currentScreen = HOME;

//Create arrows that are used for selection
//Clear arrow area first
//Set cursor at specific y coordiante on matrix
//Set color and print the character
void drawArrow(int y) {
  dma_display->fillRect(0, y, 6, 8, myBLACK); 
  dma_display->setCursor(0, y);
  dma_display->setTextColor(green);  
  dma_display->print(">");
}

/* 
* @brief function that draws the homescreen
* Draws home, a white line and then the menu options
* Each menu option is formatted for a specific color or color pattern
*/
void drawHomeScreen() {
  dma_display->fillScreen(myBLACK);
  dma_display->setTextSize(1);
  dma_display->setTextWrap(false);
  
  //Draw HOME at the top of the screen
  //All characters have a width of 6 pixels
  //Center the text
  const char* line1 = "HOME";
  int len1 = strlen(line1);
  int charWidth = 6;
  int startX1 = (dma_display->width() - len1 * charWidth) / 2;
  dma_display->setCursor(startX1, 0);

  //Alternate between white and yellow for HOME
  for (int i = 0; i < len1; i++) {
    dma_display->setTextColor((i % 2 == 0) ? yellow : white);
    dma_display->print(line1[i]);
  }

  //Draw white line below Home
  dma_display->drawLine(0, 8, PANEL_WIDTH, 8, white);

  //Set Y value for menu options
  //Options are once again centered 
  int startY = 10;
  for (int i = 0; i < numMenuItems; i++) {
    const char* label = menuItems[i];
    int len = strlen(label);
    int charWidth = 6;
    int textWidth = len * charWidth;
    int startX = (dma_display->width() - textWidth) / 2;

    //Draw the arroes on the selected index in green at the correct pixels
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
    //Compare strings to figure out how to format each menu option
    //Sketch is formatted in rainbow
    //Games is brown and white alternating
    //Image is yellow
    //Each text is 10 pixels away from the previous
    dma_display->setCursor(startX, startY);
    for (int j = 0; j < len; j++) {
        uint16_t color;
        if (strcmp(label, "Sketch") == 0) {
            uint16_t rainbowColors[] = {
                dma_display->color565(255, 0, 0),     //red
                dma_display->color565(255, 165, 0),   //orange
                dma_display->color565(255, 255, 0),   //yellow
                dma_display->color565(0, 255, 0),     //green
                dma_display->color565(0, 0, 255),     //blue
                dma_display->color565(75, 0, 130),    //indigo
                dma_display->color565(148, 0, 211)    //violet
            };
            color = rainbowColors[j % 7];
        } else if (strcmp(label, "Games") == 0) {
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

/* 
* @brief ESP32 Communication setup
* Utilizing code from the Matrix library we configure pins of the ESP32
* Initialize the matrix
*
*/

void setup() {
  //Set baud rate for serial communication
  mySerial.begin(115200);

  //Matrix configuration
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

    //If we are on the home screen
    if (currentScreen == HOME) {
      //Up arrow decreases menu index
      if (cmd == "btnUpArrow") {
        selectedIndex--;
        //Wrap around
        if (selectedIndex < 0) selectedIndex = numMenuItems - 1;
        //Redraw the home screen
        drawHomeScreen();
      }
      //Down arrow increases menu index
      else if (cmd == "btnDownArrow") {
        selectedIndex++;
        //Wrap around
        if (selectedIndex >= numMenuItems) selectedIndex = 0;
        //Redraw the home screen
        drawHomeScreen();
      }
      //A home button click on a menu item opens a new window
      else if (cmd == "btnHomeClick") {
        //button click on Sketch takes you to the color select window
        if (strcmp(menuItems[selectedIndex], "Sketch") == 0) {
          //current screen update
          currentScreen = COLOR_SELECT;
          //Draw the first colorValue
          drawColorSelector(colorValues);
        }
        //Home button click on the Image window
        else if (strcmp(menuItems[selectedIndex], "Image") == 0) {
          //current screen update
          currentScreen = LOGO_DISPLAY;
          //Draw the logo by passing the matrix object
          drawLogo(dma_display);
        }
      }
    }
    //If screen is color select
    //Arrows with rotate through possible colors to draw with
    else if (currentScreen == COLOR_SELECT) {
      if (cmd == "btnUpArrow") {
        prevColor();
      } 
      else if (cmd == "btnDownArrow") {
        nextColor();
      } 
      //Home button click selects that color and you are drawing
      //Initialize the etch a sketch with matrix object and the selected color
      else if (cmd == "btnHomeClick") {
        selectedColor = getCurrentColor();
        currentScreen = EtchASketch;
        inEtchMode = true;
        initEtchASketch(dma_display, selectedColor);
      } 
      //Holding the home button takes you back to the home screen
      else if (cmd == "btnHomeHold") {
        currentScreen = HOME;
        drawHomeScreen();
      }
    }
    //Inside the etch a sketch mode
    else if (currentScreen == EtchASketch) {
      //Home button hold takes you to the home screen
      if (cmd == "btnHomeHold") {
        currentScreen = HOME;
        inEtchMode = false;
        drawHomeScreen();
      } else if (cmd == "btnUpArrow") {
        // Pass arrow key commands to the Etch-A-Sketch handler
        handleEtchCommand(cmd);
      } else if (cmd == "btnDownArrow") {
        // Pass arrow key commands to the Etch-A-Sketch handler
        handleEtchCommand(cmd);
      } else {
        handleEtchCommand(cmd);
      }
    }
    //Home button hold on the logo display screen takes you back to home page
    else if (currentScreen == LOGO_DISPLAY) {
      if (cmd == "btnHomeHold") {
        currentScreen = HOME;
        drawHomeScreen();
      }
    }
  }
}