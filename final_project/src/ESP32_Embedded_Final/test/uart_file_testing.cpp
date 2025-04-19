// /*
//  *  main.cpp
//  * 
//  *  Project: Embedded Systems Final Project
//  *  Authors: Matt Krueger and Sage Marks
//  * 
//  *  This file is flashed to the ESP32 to enable communication with the Arduino board. 
//  *  Per Embedded Systems specifications, we are limiting the functionality of the ESP32 to 
//  *  only include the following:
//  * 
//  *      1. Communication:
//  *          - parser for incoming json message from Arduino via UART
//  *          - serializer for outgoing json message to Arduino via UART
//  *  
//  *      2. Layout Manager:
//  *          - parameterized layout functions for the Matrix
//  *  
//  *      3. Mode Manager:
//  *          - manages the current mode, or 'page', displayed on the Matrix
//  *          - there are 4 modes supported:
//  *              a) Home: displays a home page with a list of options
//  *              b) Development Mode: displays user input cleanly on the matrix
//  *              c) Game Mode: select a game to play on the matrix 
//  *              d) Settings: allows user to configure other settings of the matrix
//  * 
//  */

// #include <Arduino.h>
// #include "communication/UARTCom.h"

// UARTCom uart;            // create uart wrapper obj for esp32

// // TESTING
// const int SEND_LED_PIN = 2;         
// const int RECEIVE_LED_PIN = 21;
// const int BUTTON_PIN = 34;

// int buttonState = HIGH;


// void setup() {
//     uart.initialize();      
//     pinMode(SEND_LED_PIN, OUTPUT);
//     pinMode(RECEIVE_LED_PIN, OUTPUT);
//     pinMode(BUTTON_PIN, INPUT);
    
//     // initially off
//     digitalWrite(SEND_LED_PIN, LOW);
//     digitalWrite(RECEIVE_LED_PIN, LOW);  
// }

// void loop() {
//     // testing... move this to another file for abstraction
//     buttonState = digitalRead(BUTTON_PIN);
//     if (buttonState == LOW) {  
//         digitalWrite(SEND_LED_PIN, HIGH);
//         uart.transmit("ESP32 tx");
//         delay(1000);
//     } else {
//         digitalWrite(SEND_LED_PIN, LOW);
//     }

//     // check for new messages
//     String msg = uart.receive();
//     if (!msg.isEmpty()) {
//         digitalWrite(RECEIVE_LED_PIN, HIGH);
//         delay(1);
//     } else {
//         digitalWrite(RECEIVE_LED_PIN, LOW);
//     }
// }