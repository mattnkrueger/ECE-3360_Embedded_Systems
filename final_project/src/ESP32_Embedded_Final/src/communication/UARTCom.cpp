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

JsonDocument UARTCom::receive() { 
    JsonDocument doc;
    char msg_rx[256];                   // using instead of string as char on stack. better for mem
    uint8_t i = 0; 
    while (uart.available() > 0) {
        if (i < 255) {
            msg_rx[i] = uart.read();
            i++;
        } else {        // if 255 -> add \0
            msg_rx[i];
            Serial.printf("msg_rx filled!, i: %u", i);
        }
    }

    if (msg_rx > 0) {
        Serial.println("RECEIVED!!");
        Serial.println("message:\n|_ msg = %s");
        Serial.println("parsing...");
        deserializeJson(doc, msg_rx);
        Serial.println("JSON:");

        // testing unpack
        char* origin  = doc["origin"];
        char* mode    = doc["mode"];
        char* command = doc["command"];
        char* status  = doc["status"];

        Serial.println(origin);
        Serial.println(mode);
        Serial.println(command);
        Serial.println(status);
    }

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