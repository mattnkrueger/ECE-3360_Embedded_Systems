/*
 *  UARTCom.cpp
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file contains the implementation of the UARTCom class.
 */

#include "communication/UARTCom.h"

// constructor
UARTCom::UARTCom(int channel) : uart(channel) {
    Serial.print("Selected Channel: ");
    Serial.println(channel);
}

// initialize
void UARTCom::initialize(unsigned long baud, SerialConfig config, uint8_t channel) {
    uint8_t tx_pin;
    uint8_t rx_pin;

    switch (channel) {
        case 0:
            tx_pin = 1;
            rx_pin = 3;
        break;
        case 1:
            tx_pin = 10;
            rx_pin = 9;
        break;
        case 2:
            tx_pin = 17;
            rx_pin = 16;
        break;
    }

    uart.begin(baud, config, rx_pin, tx_pin);           // other params defaulted. See HardwareSerial.h
    Serial.printf("ESP32 UART configuration:\nbaud rate: %u\nformat: %u\nchannel: %u (tx=%u, rx=%u)\n", baud, config, channel, tx_pin, rx_pin);
}

// receive (interrupt driven in HardwareSerial)
String UARTCom::receive() { 
    // TODO-
    // complete
}

// transmit
void UARTCom::transmit(String origin, String mode, String command, bool status) {
    // TODO-
    // complete
}