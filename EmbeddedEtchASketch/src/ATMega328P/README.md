# ATMega328P Firmware for Embedded Etch-A-Sketch

## Overview
This firmware serves as an interface between user input devices and the ESP32, working as a dummy terminal. It captures physical inputs (buttons, rotary encoders, joysticks) and converts them into commands sent via UART to the ESP32 for processing.

## Hardware Components
- **Rotary Encoders**: Two RPGs (rotary pulse generators) for precise input
- **System Buttons**: Up/Down arrows and Home button
- **Controller Buttons**: Two controllers, each with A & B buttons
- **Joysticks**: Two analog joysticks (X & Y for each)
- **Power Button**: For system power control

## Communication
The ATMega328P communicates with the ESP32 via UART at 115200 baud.

## Key Features
- Interrupt-driven input detection for buttons and rotary encoders
- Debouncing for all button inputs
- Power management with press-and-hold functionality
- Home button with different actions for short and long press
- Joystick control with deadzone handling
- Controller enable/disable functionality based on system context

## PlatformIO Configuration
This is a PlatformIO project. The configuration file (`platformio.ini`) contains:

```
; PlatformIO Project Configuration File
;
;   Build options: build flags, source filter
;   Upload options: custom upload port, speed and extra flags
;   Library options: dependencies, extra library storages
;   Advanced options: extra scripting
;
; Please visit documentation for the other options and examples
; https://docs.platformio.org/page/projectconf.html

[env:ATmega328P]
platform = atmelavr
board = ATmega328P
framework = arduino

monitor_speed = 115200
```

## How to Run
1. Install [PlatformIO](https://platformio.org/) (available as extension for VS Code or standalone CLI)
2. Open the project folder
3. Build the project with `platformio run`
4. Upload to your ATMega328P with `platformio run --target upload`
5. Monitor serial output with `platformio device monitor`

Alternatively, you can use the simple Platformio interface to flash ("PlatformIO: Build")

<p align="center">
  <img src="../../img/PlatformIO_bar.png" alt="PlatformIO Interface">
</p>

## Documentation

To view the [Doxygen](https://doxygen.nl/) generated documentation:

### Windows
1. Navigate to the `doxygenDocs/html` folder
2. Double-click `index.html` to open in your default web browser

### Mac
1. Navigate to the `doxygenDocs/html` folder
2. Double-click `index.html` to open in your default web browser
   ```bash
   open doxygenDocs/html/index.html
   ```

## Authors  

<div style="display: flex; justify-content: center; gap: 60px;">
  <div align="center">
    <img src="../../img/smarks.jpeg" alt="Sage Marks" style="width: 100px; height: 100px; border-radius: 50%; margin-bottom: 10px;">
    <div style="display: flex; align-items: center; justify-content: center;">
      Sage Marks
    </div>
    <div>
      <a href="mailto:sage-marks@uiowa.edu">Email</a> | <a href="https://www.linkedin.com/in/sage-marks-71a044293/">LinkedIn</a>
    </div>
  </div>

  <div align="center">
    <img src="../../img/mkrueger.png" alt="Matt Krueger" style="width: 100px; height: 100px; border-radius: 50%; margin-bottom: 10px;">
    <div style="display: flex; align-items: center; justify-content: center;">
      Matt Krueger
    </div>
    <div>
      <a href="mailto:matthew-krueger@uiowa.edu">Email</a> | <a href="https://www.linkedin.com/in/mattnkrueger/">LinkedIn</a>
    </div>
  </div>
</div>              
    
