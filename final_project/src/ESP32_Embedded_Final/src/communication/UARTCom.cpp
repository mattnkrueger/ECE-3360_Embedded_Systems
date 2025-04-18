/*
 *  UARTCom.cpp
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file contains the implementation of the UARTCom class.
 */

#include "communication/UARTCom.h"

UARTCom::UARTCom(int channel) : uart(channel) {
    Serial.print("ESP32 UARTCom-\nChannel: ");
    Serial.println(channel);
}

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
        default:
            tx_pin = 17;
            rx_pin = 16;
            break;
    }

    uart.begin(baud, config, rx_pin, tx_pin);           // other params defaulted. See HardwareSerial.h
    Serial.printf("ESP32 UART configuration:\nbaud rate: %lu\nformat: %u\nchannel: %u (tx=%u, rx=%u)\n", baud, config, channel, tx_pin, rx_pin);
}

String UARTCom::receive() { 
    char msg_rx[256];                   // using instead of string as char on stack. better for mem
    uint8_t i = 0; 
    while (uart.available() > 0) {
        if (i < 255) {
            msg_rx[i] = uart.read();
            i++;
        } else {        // if 255 -> add \0
            msg_rx[i] = '\0';
            break;
        }
    }

    if (i > 0) {
        msg_rx[i] = '\0'; // ensure null terminated
        Serial.println("RECEIVED!!");
        Serial.printf("message:\n|_ msg = %s", msg_rx);
    }

    return String(msg_rx);
}

void UARTCom::transmit() {
    //TODO-
    // send a message. 
}