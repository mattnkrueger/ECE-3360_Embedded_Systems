#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <FastLED.h>

#define PANEL_WIDTH 64
#define PANEL_HEIGHT 64 
#define PANELS_NUMBER 1

// Pins for Serial debug
#define RXD2 16  // UART2 RX pin - connect to Arduino's TX
#define TXD2 17  // UART2 TX pin - connect to Arduino's RX (if bidirectional communication is needed)

MatrixPanel_I2S_DMA *dma_display = nullptr;

int cursorX = 32;
int cursorY = 32;
bool pen_down = true;  // Drawing mode by default
uint16_t current_color = 0xF800; // Red color in RGB565 format

void setup() {
  // Setup both serial ports
  Serial.begin(9600);  // Debug Serial monitor
  Serial2.begin(9600, SERIAL_8N1, RXD2, TXD2); // UART from Arduino 
  
  delay(1000); // Allow serial ports to initialize
  Serial.println("ESP32 Etch-a-Sketch Starting...");

  // Configure matrix display
  HUB75_I2S_CFG mxconfig(PANEL_WIDTH, PANEL_HEIGHT, PANELS_NUMBER);

  mxconfig.gpio.r1  = 25;
  mxconfig.gpio.g1  = 26;
  mxconfig.gpio.b1  = 27;
  mxconfig.gpio.r2  = 14;
  mxconfig.gpio.g2  = 12;
  mxconfig.gpio.b2  = 13;
  mxconfig.gpio.e   = 32;
  mxconfig.gpio.a   = 23;
  mxconfig.gpio.b   = 22;
  mxconfig.gpio.c   = 5;
  mxconfig.gpio.d   = 2;
  mxconfig.gpio.clk = 33;
  mxconfig.gpio.lat = 4;
  mxconfig.gpio.oe  = 15;

  mxconfig.clkphase = true;
  mxconfig.driver = HUB75_I2S_CFG::FM6126A;

  dma_display = new MatrixPanel_I2S_DMA(mxconfig);
  dma_display->setBrightness8(200);

  if (!dma_display->begin()) {
    Serial.println("I2S memory allocation failed");
  } else {
    Serial.println("Display initialized successfully");
  }

  dma_display->fillScreenRGB888(0, 0, 0); // Clear the screen
  dma_display->drawPixelRGB888(cursorX, cursorY, 255, 0, 0); // Start with red pixel
  
  Serial.print("Starting position: (");
  Serial.print(cursorX);
  Serial.print(", ");
  Serial.print(cursorY);
  Serial.println(")");
}

void loop() {
  // Check for commands from Arduino
  if (Serial2.available() > 0) {
    char cmd = Serial2.read();
    
    // Echo received command to Serial Monitor for debugging
    Serial.print("Received command: '");
    Serial.print(cmd);
    Serial.println("'");
    
    // If we're in drawing mode, leave the current pixel colored
    // If not, clear the current pixel before moving
    if (!pen_down) {
      dma_display->drawPixelRGB888(cursorX, cursorY, 0, 0, 0);  // Clear the old pixel
    }
    
    int oldX = cursorX;
    int oldY = cursorY;
    
    // Move cursor based on commands
    switch(cmd) {
      case 'u': // up
        if (cursorY > 0) cursorY--;
        break;
      case 'd': // down
        if (cursorY < PANEL_HEIGHT - 1) cursorY++;
        break;
      case 'l': // left
        if (cursorX > 0) cursorX--;
        break;
      case 'r': // right
        if (cursorX < PANEL_WIDTH - 1) cursorX++;
        break;
      case 'c': // toggle pen color (bonus feature)
        current_color = (current_color == 0xF800) ? 0x07E0 : 0xF800; // Toggle between red and green
        break;
      case 'p': // toggle pen up/down (bonus feature)
        pen_down = !pen_down;
        Serial.print("Pen is now ");
        Serial.println(pen_down ? "DOWN (drawing)" : "UP (moving)");
        break;
      case 'x': // clear screen (bonus feature)
        dma_display->fillScreenRGB888(0, 0, 0);
        break;
      default:
        Serial.print("Unknown command: ");
        Serial.println(cmd);
        break;
    }
    
    // Always draw current cursor position in red (or current color)
    dma_display->drawPixelRGB888(cursorX, cursorY, 
                              (current_color >> 11) * 8,     // Extract R value
                              ((current_color >> 5) & 0x3F) * 4, // Extract G value
                              (current_color & 0x1F) * 8);       // Extract B value

    // Debug: Print the cursor position
    Serial.print("Moved from (");
    Serial.print(oldX);
    Serial.print(", ");
    Serial.print(oldY);
    Serial.print(") to (");
    Serial.print(cursorX);
    Serial.print(", ");
    Serial.print(cursorY);
    Serial.println(")");
  }
  
  // Small delay to avoid excessive polling
  delay(5);
}