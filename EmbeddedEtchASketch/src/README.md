# Final Project - Embedded Systems
Code is split into two subprojects:
1. ATMega328P: source code for Arduino
2. ESP32: source code for ESP32

## Build System
We used Platformio to aid in the building process of our project. This made juggling the libraries and using two microcontrollers that have different frameworks very simple. To flash our project, you must first create a Platformio project (ensure that the platformio.ini file is inside - this is what builds the library dependencies).
To run:
```
$ pio run -v 
```

It is easier to use VSCode's GUI arrow to build - which by default runs the above command. 

## Documentaion
This project uses Doxygen to generate a local html file that can be viewed. Inside of this file is all documentation for the project. To view the file (macos/linux):
```
$ cd path_to_this_src_dir/doxygenDocs/
$ open html/index.html
```

## Libraries:
These are the ESP32 libraries that made our specific LED matrix work

### Adafruit BusIO
- [GitHub Repository](https://github.com/adafruit/Adafruit_BusIO)

### Adafruit GFX Library
- [GitHub Repository](https://github.com/adafruit/Adafruit-GFX-Library)

### ESP32 HUB75 MatrixPanel DMA
- [GitHub Repository](https://github.com/mrcodetastic/ESP32-HUB75-MatrixPanel-DMA/tree/master)

### FastLED
- [GitHub Repository](https://github.com/FastLED/FastLED)

