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
    Serial.print("Selected Channel: ");
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
    }

    uart.begin(baud, config, rx_pin, tx_pin);           // other params defaulted. See HardwareSerial.h
    Serial.printf("ESP32 UART configuration:\nbaud rate: %u\nformat: %u\nchannel: %u (tx=%u, rx=%u)\n", baud, config, channel, tx_pin, rx_pin);
}

JsonDocument UARTCom::receive() { 
    // TODO-
    // receive bytestream from uart
    // this should be of type char* (pointer of chars -- essentially a string.)
    // utilize the HardwareSerial for this so it is interrupt based.
    
    // should look something like this
    const char* msg =  "{\"origin\":\"user\", \"mode\":\"game\", \"command\":\"move cursor right\", \"status\":\"msg\"}";
    JsonDocument doc;
    deserializeJson(doc, msg);
    return doc;
}

void UARTCom::transmit(String origin, String mode, String command, bool status) {
    // build
    JsonDocument doc;
    doc["origin"]  = origin;
    doc["mode"]    = mode;
    doc["command"] = command;
    doc["status"]  = status;

    // serialize
    char msg[256];               
    serializeJson(doc, msg);

    // transmit & test
    uart.write(msg);
    Serial.printf(">> ESP32 TX -> Arduino:\norigin: %s\nmode: %s\ncommand: %s\nstatus: %d", origin, mode, command, status);
}