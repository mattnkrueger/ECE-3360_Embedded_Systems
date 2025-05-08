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

Alternatively, you can use the simple Platformio interface to 

![PlatformIO Interface](../../img/PlatformIO_bar.png)


## Authors
- Matt Krueger
- Sage Marks
