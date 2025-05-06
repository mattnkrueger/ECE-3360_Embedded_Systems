# Final Project - Embedded Systems
This project showcases our learning from the Embedded Systems course in which we decided to build a game system. The system includes two microcontrollers communicating using UART:
1. Esp32 - required to address all ~4000 addresses of the LED Matrix (64^2)
2. Arduino Uno R3 - handle user interaction with the system

## Build System
We used Platformio to aid in the building process of our project. This made juggling the libraries and using two microcontrollers that have different frameworks very simple. To flash our project, you must first create a Platformio project (ensure that the platformio.ini file is inside - this is what builds the library dependencies).
To run:
```
$ pio run -v 
```

It is easier to use VSCode's GUI arrow to build - which by default runs the above command. 

## Project Goal

Our project goal was to build something that wont be thrown away - or stripped down to preserve parts - after the class ends. The LED Matrix (and game system) sufficed; it allows for various programs, unique displays, and extendability beyond this course. Because of the ESP32, this system can be iterated on to support user I/O via a web application. However, that would be more of an IoT project than Embedded Systems... just our thinking. As we are roomates, this system is currently being held in our living room. The Hawkeye themed system compliments the room nicely haha.

Currently programmed is an extended 'EtchASketch' program and a pixel art image viewer. The 'EtchASketch' program is controlled by two dials attached to the front of the system. This works identically to the original game and extends it further with the RGB capability of the LED Matrix. To navigate colors, the user can press buttons on the side of the system (similar to a tv) to select wanted color.
The Pixel Art image viewer cycles through meticulously hand drawn pixel art via the user navigation buttons.

To navigate between programs, the home button (has home icon) can be clicked to bring up a navigation screen. 

To power off the system, the power button is held for 5 seconds. After which a simple click will return power to the system.

Overall, our project was - and is - predicated on simplicity and ease of use. As any good hardware and software, the design is built to last. The design is fun and accessible to all, which is a success in our books.

## TODO IMAGE
ADD IMAGE OF FINAL PROJECT

## TODO KiCad
ADD KICAD DESIGN

## Demo
ADD LINK TO DEMO VIDEO 

## Source Code
TODO 

## Documentaion
This project uses Doxygen to generate a local html file that can be viewed. Inside of this file is all documentation for the project. To view the file (macos/linux):
```
$ cd path_to_this_src_dir/doxygenDocs/
$ open html/index.html
```

#### Libraries:
These are the libraries that we utilized for our project

### Adafruit BusIO
- [GitHub Repository](https://github.com/adafruit/Adafruit_BusIO)

### Adafruit GFX Library
- [GitHub Repository](https://github.com/adafruit/Adafruit-GFX-Library)

### ESP32 HUB75 MatrixPanel DMA
- [GitHub Repository](https://github.com/mrcodetastic/ESP32-HUB75-MatrixPanel-DMA/tree/master)

### FastLED
- [GitHub Repository](https://github.com/FastLED/FastLED)

## Parts List
THIS IS NOT AN EXHAUSTIVE LIST OF PARTS REQUIRED
Note this list does not include the cost of wires, adaptors, psu, etc. this is negligible and already on hand.
There are also various electrical components that were provided by the University of Iowa.

Here are the most relevant parts and their purpose, quantity, and cost
| Part | Description | Quantity | Unit Cost |
|------|-------------|----------|------------|
| ESP32 DevKitV1| Microcontroller to interface LED Matrix | 1 | $5 (off-brand)|
| 64x64 RGB LED Matrix Panel | LED Matrix for display| 1 | $29.99 (off-brand)|
| Arduino Uno | Microcontroller to handle user input | 1 | $0 (provided)
| 3D printed parts | Iowa themed, 3d enclosures | many | $20
| magnets | easy access to inside of enclosures | many | $5

total cost: **~$60** 

Additionally, the final product was built using 3D printed parts. All parts were 'hand' made, and the STL files included in this repository.

[3D Models & Cost Breakdown](./3d_models/3d_printing.md)
