/*
 *  UARTCom.cpp
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file contains the implementation of the UARTCom class.
 */

#include "communication/UARTCom.h"

void UARTCom::initialize() {
    uint8_t tx_pin = 17; 
    uint8_t rx_pin = 16;
    uint32_t baud = 9600;
    uint32_t config = SERIAL_8E1;
    uart.begin(baud, config, rx_pin, tx_pin);
    Serial.printf("ESP32 UART configuration:\nbaud rate: %lu\nformat: %u\nchannel: 2 (tx=%u, rx=%u)\n", baud, config, tx_pin, rx_pin);
}

String UARTCom::receive() { 
    if (uart.available() > 0) {
        String msg = uart.readStringUntil('\n');
        msg.trim();

        return msg;
    }
    return "";      // default empty
}

void UARTCom::transmit(String msg) {
    uart.println(msg);
}