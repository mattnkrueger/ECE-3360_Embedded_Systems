// Example sketch which shows how to display content
// on a 64x64 LED matrix with ESP32
#include <HardwareSerial.h>

#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#define PANEL_RES_X 64 
#define PANEL_RES_Y 64  
#define PANEL_CHAIN 1    

/* ESP32 UART Configuration
 * ESP32 has 3 hardware UART interfaces (0, 1, 2):
 * - UART0: Typically used for programming/debugging via USB
 * - UART1/UART2: Available for your application
 *
 * HardwareSerial(uart_num, rx_buffer_size, tx_buffer_size, uart_queue_size)
 * Default buffer sizes are usually sufficient for most applications
 */
// Using UART1 with non-conflicting pins
#define ESP_TX_PIN 2  // GPIO2 for TX
#define ESP_RX_PIN 4  // GPIO4 for RX
HardwareSerial MySerial(1); // Use UART1

// NOT SURE
MatrixPanel_I2S_DMA *dma_display = nullptr;
uint16_t myBLACK, myWHITE, myRED, myGREEN, myBLUE;

// Input a value 0 to 255 to get a color value.
// The colours are a transition r - g - b - back to r.
// From: https://gist.github.com/davidegironi/3144efdc6d67e5df55438cc3cba613c8
uint16_t colorWheel(uint8_t pos) {
  if(pos < 85) {
    return dma_display->color565(pos * 3, 255 - pos * 3, 0);
  } else if(pos < 170) {
    pos -= 85;
    return dma_display->color565(255 - pos * 3, 0, pos * 3);
  } else {
    pos -= 170;
    return dma_display->color565(0, pos * 3, 255 - pos * 3);
  }
}

void drawText(int colorWheelOffset)
{
  // Clear the screen before drawing new text
  dma_display->fillScreen(myBLACK);
  
  // draw text with a rotating colour
  dma_display->setTextSize(1);     // size 1 == 8 pixels high
  dma_display->setTextWrap(false); // Don't wrap at end of line - will do ourselves

  dma_display->setCursor(5, 5);    // start at top left, with 5 pixel of spacing
  uint8_t w = 0;
  const char *str = "ESP32 DMA";
  for (w=0; w<strlen(str); w++) {
    dma_display->setTextColor(colorWheel((w*32)+colorWheelOffset));
    dma_display->print(str[w]);
  }

  dma_display->setCursor(5, 15);
  for (w=0; w<9; w++) {
    dma_display->setTextColor(colorWheel((w*32)+colorWheelOffset));
    dma_display->print("*");
  }
  
  dma_display->setCursor(5, 25);
  dma_display->setTextColor(dma_display->color444(15,15,15));
  dma_display->println("LED MATRIX!");

  // print each letter with a fixed rainbow color
  dma_display->setCursor(5, 35);
  dma_display->setTextColor(dma_display->color444(0,8,15));
  dma_display->print('6');
  dma_display->setTextColor(dma_display->color444(15,4,0));
  dma_display->print('4');
  dma_display->setTextColor(dma_display->color444(15,15,0));
  dma_display->print('x');
  dma_display->setTextColor(dma_display->color444(8,15,0));
  dma_display->print('6');
  dma_display->setTextColor(dma_display->color444(8,0,15));
  dma_display->print('4');

  // Jump a half character
  dma_display->setCursor(5, 45);
  dma_display->setTextColor(dma_display->color444(0,15,15));
  dma_display->print("*");
  dma_display->setTextColor(dma_display->color444(15,0,0));
  dma_display->print('R');
  dma_display->setTextColor(dma_display->color444(0,15,0));
  dma_display->print('G');
  dma_display->setTextColor(dma_display->color444(0,0,15));
  dma_display->print("B");
  dma_display->setTextColor(dma_display->color444(15,0,8));
  dma_display->println("*");
}

void setup() {
  // Initialize default Serial for debugging via USB (UART0)
  Serial.begin(115200);
  Serial.println("ESP32 LED Matrix Demo starting...");
  
  /* UART Configuration explanation:
   * begin(baud_rate, data_config, rx_pin, tx_pin, invert)
   * - baud_rate: Communication speed (115200 is standard)
   * - data_config: Format of each data unit
   *   SERIAL_8N1 = 8 data bits, No parity, 1 stop bit
   * - rx_pin: GPIO pin number for receiving data
   * - tx_pin: GPIO pin number for transmitting data
   */
  MySerial.begin(115200, SERIAL_8N1, ESP_RX_PIN, ESP_TX_PIN);
  Serial.printf("UART1 initialized on pins TX:%d RX:%d\n", ESP_TX_PIN, ESP_RX_PIN);
  
  // Test UART by sending a message
  MySerial.println("UART1 test message");
  Serial.println("Test message sent to UART1");

  delay(1000);

  // Module configuration
  HUB75_I2S_CFG mxconfig(
    PANEL_RES_X,   // module width
    PANEL_RES_Y,   // module height
    PANEL_CHAIN    // Chain length
  );

  // ESP32 DEVKITV1 HUB75E
  // hub75e -> gpi0 pinout
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

  mxconfig.gpio.r1  = 25;     // R1
  mxconfig.gpio.g1  = 26;     // G1
  mxconfig.gpio.b1  = 27;     // B1
  mxconfig.gpio.r2  = 14;     // R2
  mxconfig.gpio.g2  = 12;     // G2
  mxconfig.gpio.b2  = 13;     // B2
  mxconfig.gpio.e   = 32;     // E
  mxconfig.gpio.a   = 23;     // A
  mxconfig.gpio.b   = 22;     // B
  mxconfig.gpio.c   = 5;      // C
  mxconfig.gpio.d   = 2;      // D
  mxconfig.gpio.clk = 33;     // CLK
  mxconfig.gpio.lat = 4;      // LAT
  mxconfig.gpio.oe  = 15;     // OE

  // Potentially need to adjust these for 64x64 panels
  mxconfig.clkphase = false;
  mxconfig.driver = HUB75_I2S_CFG::FM6126A;

  // Display Setup
  dma_display = new MatrixPanel_I2S_DMA(mxconfig);
  
  // Initialize the display
  if (not dma_display->begin()) {
    Serial.println("****** ERROR: Panel could not be initialized ******");
  }
  
  Serial.println("Panel initialized successfully");
  
  dma_display->setBrightness8(90); //0-255
  dma_display->clearScreen();

  // Define colors
  myBLACK = dma_display->color565(0, 0, 0);
  myWHITE = dma_display->color565(255, 255, 255);
  myRED = dma_display->color565(255, 0, 0);
  myGREEN = dma_display->color565(0, 255, 0);
  myBLUE = dma_display->color565(0, 0, 255);
  
  // Startup sequence
  dma_display->fillScreen(myBLACK);
  delay(500);
  
  // draw a box in yellow
  dma_display->drawRect(0, 0, dma_display->width(), dma_display->height(), dma_display->color444(15, 15, 0));
  delay(500);

  // draw an 'X' in red
  dma_display->drawLine(0, 0, dma_display->width()-1, dma_display->height()-1, dma_display->color444(15, 0, 0));
  dma_display->drawLine(dma_display->width()-1, 0, 0, dma_display->height()-1, dma_display->color444(15, 0, 0));
  delay(500);

  // draw a blue circle
  dma_display->drawCircle(32, 32, 20, dma_display->color444(0, 0, 15));
  delay(500);

  // fill a violet circle
  dma_display->fillCircle(32, 32, 10, dma_display->color444(15, 0, 15));
  delay(500);

  // fill the screen with 'black'
  dma_display->fillScreen(myBLACK);
}

// Function to test UART communication
void testUART() {
  // Send a message over UART1
  MySerial.println("LED Matrix UART1 Test");
  
  // Debug message to default Serial
  Serial.println("Message sent to UART1");
}

uint8_t wheelval = 0;
void loop() {
  dma_display->fillScreen(myBLACK);
  for (int y = 0; y < 64; y += 8) {
    for (int x = 0; x < 64; x += 8) {
      if ((x/8 + y/8) % 2 == 0) {
        dma_display->fillRect(x, y, 8, 8, colorWheel((x+y) % 255));
      }
    }
  }
  
  // Test UART periodically
  testUART();
  
  delay(500);
}