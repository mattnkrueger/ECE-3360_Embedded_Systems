/*
 * Portions of this code are adapted from Aurora: https://github.com/pixelmatix/aurora
 * Copyright (c) 2014 Jason Coon
 *
 * Portions of this code are adapted from LedEffects Plasma by Robert Atkins: https://bitbucket.org/ratkins/ledeffects/src/26ed3c51912af6fac5f1304629c7b4ab7ac8ca4b/Plasma.cpp?at=default
 * Copyright (c) 2013 Robert Atkins
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
 
/*  Default library pin configuration for the reference
  you can redefine only ones you need later on object creation

#define R1 25
#define G1 26
#define BL1 27
#define R2 14
#define G2 12
#define BL2 13
#define CH_A 23
#define CH_B 19
#define CH_C 5
#define CH_D 17
#define CH_E -1 // assign to any available pin if using two panels or 64x64 panels with 1/32 scan
#define CLK 16
#define LAT 4
#define OE 15

*/


#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <FastLED.h>

#define PANEL_WIDTH 64
#define PANEL_HEIGHT 64 
#define PANELS_NUMBER 1
#define PIN_E 32
#define PANE_WIDTH PANEL_WIDTH * PANELS_NUMBER
#define PANE_HEIGHT PANEL_HEIGHT

// placeholder for the matrix object
MatrixPanel_I2S_DMA *dma_display = nullptr;

// Variables for the plasma effect
uint16_t time_counter = 0, cycles = 0, fps = 0;
unsigned long fps_timer;

// Variables for the plasma effect
CRGB currentColor;
CRGBPalette16 palettes[] = {HeatColors_p, LavaColors_p, RainbowColors_p, RainbowStripeColors_p, CloudColors_p};
CRGBPalette16 currentPalette = palettes[0];


CRGB ColorFromCurrentPalette(uint8_t index = 0, uint8_t brightness = 255, TBlendType blendType = LINEARBLEND) {
  return ColorFromPalette(currentPalette, index, brightness, blendType);
}

/*
 * Setup
*/
void setup() {
  
  Serial.begin(115200);
  
  Serial.println(F("*****************************************************"));
  Serial.println(F("*        ESP32-HUB75-MatrixPanel-I2S-DMA DEMO       *"));
  Serial.println(F("*****************************************************"));

  // Module configuration
  HUB75_I2S_CFG mxconfig(
    PANEL_WIDTH,   // module width
    PANEL_HEIGHT,   // module height
    PANELS_NUMBER    // Chain length
  );

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
  mxconfig.clkphase = true;
  mxconfig.driver = HUB75_I2S_CFG::FM6126A;


  // OK, now we can create our matrix object
  dma_display = new MatrixPanel_I2S_DMA(mxconfig);

  // let's adjust default brightness to about 75%
  dma_display->setBrightness8(200);    

  // Allocate memory and start DMA display
  if( not dma_display->begin() )
      Serial.println("****** !KABOOM! I2S memory allocation failed ***********");
 
  // well, hope we are OK, let's draw some colors first :)
  Serial.println("Fill screen: RED");
  dma_display->fillScreenRGB888(255, 0, 0);
  delay(1000);

  Serial.println("Fill screen: GREEN");
  dma_display->fillScreenRGB888(0, 255, 0);
  delay(1000);

  Serial.println("Fill screen: BLUE");
  dma_display->fillScreenRGB888(0, 0, 255);
  delay(1000);

  Serial.println("Fill screen: Neutral White");
  dma_display->fillScreenRGB888(64, 64, 64);
  delay(1000);

  Serial.println("Fill screen: black");
  dma_display->fillScreenRGB888(0, 0, 0);
  delay(1000);


  // Set current FastLED palette
  currentPalette = RainbowColors_p;
  Serial.println("Starting plasma effect...");
  fps_timer = millis();
}

void loop() {
  
    for (int x = 0; x < PANE_WIDTH; x++) {
            for (int y = 0; y <  PANE_HEIGHT; y++) {
                int16_t v = 128;
                uint8_t wibble = sin8(time_counter);
                v += sin16(x * wibble * 3 + time_counter);
                v += cos16(y * (128 - wibble)  + time_counter);
                v += sin16(y * x * cos8(-time_counter) / 8);

                currentColor = ColorFromPalette(currentPalette, (v >> 8)); //, brightness, currentBlendType);
                dma_display->drawPixelRGB888(x, y, currentColor.r, currentColor.g, currentColor.b);
            }
    }

    ++time_counter;
    ++cycles;
    ++fps;

    if (cycles >= 1024) {
        time_counter = 0;
        cycles = 0;
        currentPalette = palettes[random(0,sizeof(palettes)/sizeof(palettes[0]))];
    }

    // print FPS rate every 5 seconds
    // Note: this is NOT a matrix refresh rate, it's the number of data frames being drawn to the DMA buffer per second
    if (fps_timer + 5000 < millis()){
      Serial.printf_P(PSTR("Effect fps: %d\n"), fps/5);
      fps_timer = millis();
      fps = 0;
    }
} // end loop