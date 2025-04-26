# ArduinoUNO Source Code
The purpose of this code is to process user interaction and send it in a format to be received by the master ESP32 controller. 

Much of the code in the ArduinoUNO portion of the project simply monitors the various buttons and joysticks of the controller. 
All buttons included in the system are connected to the Arduino board; the ESP32 simply receives that data over UART.

# Important Files
- UART.h - uart communication with ESP32
- Controller.h - controller interface
- Dials.h - RPG interface
- SystemIO.h - interface for buttons included on the LED Matrix Case (home, arrows, power)

# Developer Notes
Please note that there are **Doxygen** comments in this repository. If you are unfamiliar with [Doxygen](https://doxygen.nl/), it is similar to JavaDocs for Java and builds an HTML page that can be viewed by opening [./docs/html/index.html](). 