/*
 *  main.cpp
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file is flashed to the ESP32 to enable communication with the Arduino board. 
 *  Per Embedded Systems specifications, we are limiting the functionality of the ESP32 to 
 *  only include the following:
 * 
 *      1. Communication:
 *          - parser for incoming json message from Arduino via UART
 *          - serializer for outgoing json message to Arduino via UART
 *  
 *      2. Layout Manager:
 *          - parameterized layout functions for the Matrix
 *  
 *      3. Mode Manager:
 *          - manages the current mode, or 'page', displayed on the Matrix
 *          - there are 4 modes supported:
 *              a) Home: displays a home page with a list of options
 *              b) Development Mode: displays user input cleanly on the matrix
 *              c) Game Mode: select a game to play on the matrix 
 *              d) Settings: allows user to configure other settings of the matrix
 * 
 */

#include <Arduino.h>
#include "communication/UARTCom.h"

/*
TODO - 
this file should combine much of the classes used above. It is the entry point hence the setup() and loop()

Potential Workflow:
- interrupt from UART
- map interrupt to wanted function
- we are a bit limited on how we can use the esp, so the bulk of this will be mapping the RX signal to corresponding 

- JSON should be able to be used for UART as it is a serial data structure
- json is a really user friendly data structure:

json_example = {
    message1 : "this is valid",
    message2 : 12376, 
    message3 : [serializable object]
}

- Basically, we can have a json being sent from the user on the arduino on -every- interaction. We can then treat these as control signals/logic to map wanted outcome
*/

/*
 * microcontroller setup (Arduino Style C++)
 */
void setup() {
    /*
    TODO -
    1. call led matrix initializer of the Matrix class
    2. blocking function for uart initialization. Some sort of handshake should be implemented here
    3. starting sequence: 
        a) loading screen (display during blocking function) 
        b) loading screen animation -> home screen
        c) land at home screen 
        d) enable listening for the UART signals
    4. exit setup
    */
}

/*
 * main loop (Arduino Style C++)
 */
void loop() {
    /*
    TODO - INTERRUPT DRIVEN
    1. blocking function for UART
    2. map to wanted function
    3. update the screen
    */
}
