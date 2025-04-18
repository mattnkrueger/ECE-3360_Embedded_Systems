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

const int SEND_LED_PIN = 2;         
const int RECEIVE_LED_PIN = 21;
const int BUTTON_PIN = 34;

// UART PINS & Mode 
HardwareSerial SerialPort(2);
const int TX_PIN = 17;
const int RX_PIN = 16;

// initial state
int buttonState = HIGH;

void setup() {
  SerialPort.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN);           // set to 9600 for Uno coms
  pinMode(SEND_LED_PIN, OUTPUT);
  pinMode(RECEIVE_LED_PIN, OUTPUT);  // Configure the receive LED pin
  pinMode(BUTTON_PIN, INPUT);
  digitalWrite(SEND_LED_PIN, LOW);
  digitalWrite(RECEIVE_LED_PIN, LOW);  // Initialize the receive LED as off
}

void loop() {
  buttonState = digitalRead(BUTTON_PIN);
  
  if (buttonState == LOW) {  
    digitalWrite(SEND_LED_PIN, HIGH);
    SerialPort.println("ESP32 TX");  
    delay(1000);
  } else {
    digitalWrite(SEND_LED_PIN, LOW);
  }
  
  // Check for incoming message
  if (SerialPort.available() > 0) {
    String incomingMessage = SerialPort.readStringUntil('\n');
    incomingMessage.trim();  // Remove any whitespace
    
    if (incomingMessage == "arduino tx") {
      digitalWrite(RECEIVE_LED_PIN, HIGH);
      delay(1000); 
      digitalWrite(RECEIVE_LED_PIN, LOW);
    }
  }
}