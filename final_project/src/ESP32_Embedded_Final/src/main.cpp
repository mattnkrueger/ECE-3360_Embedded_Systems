/**
 * @file main.cpp
 * @author Matt Krueger & Sage Marks
 * @brief Final Project Embedded Systems ESP32 code. 
 * @version 0.1
 * @date 2025-05-02
 * 
 * @copyright Copyright (c) 2025
 * 
 * This sketch handles ESP32 interface to the LED Matrix. Because the ESP32 is a much more powerful device (more ram, clockspeed), we are using it for the following purposes:
 * 1. master device - process messages over UART from the Arduino UNO
 * 2. LED Matrix interface - determines which LEDs light up on the matrix
 * 
 */

#include <HardwareSerial.h>
#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ Matrix Definitions ------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define PANEL_RES_X 64 
#define PANEL_RES_Y 64  
#define PANEL_CHAIN 1    

// board object 
MatrixPanel_I2S_DMA *dma_display = nullptr;                 

///////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ UART Config ------------------------------------------ //
///////////////////////////////////////////////////////////////////////////////////////////////////////
#define ESP_TX_PIN 17  
#define ESP_RX_PIN 16
HardwareSerial MySerial(1); 

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ State Variables ------------------------------------------ //
///////////////////////////////////////////////////////////////////////////////////////////////////////////
volatile uint8_t prevCommand = 0xFF; // volatile strings not allowed, so using this instead

/**
 * @brief initialize UART communication with the Arduino UNO
 * 
 * baud: 115200
 * bits: 8
 * parity: None
 * stop bit: 1
 * 
 * [START][D0][D1][D2][D3][D4][D5][D6][D7][STOP]
 * 
 */
void initializeUART() {
    MySerial.begin(115200, SERIAL_8N1, ESP_RX_PIN, ESP_TX_PIN);
    MySerial.println("TEST!!!!!!");
    Serial.begin(115200);
}

/**
 * @brief processes the Arduino command and maps to wanted action
 * 
 * Command table:

 *                                  | Byte Value | String Value        
 *                                  |------------|--------------------------|
 *                                  | 0x00       | btnUpArrow            
 *                                  | 0x01       | btnDownArrow         
 *                                  | 0x02       | btnHomeClick 
 *                                  | 0x03       | btnHomeHold
 *                                  | 0x04       | btnPowerClick     
 *                                  | 0x05       | btnController1A   
 *                                  | 0x06       | btnController1B   
 *                                  | 0x07       | joystick1UP       
 *                                  | 0x08       | joystick1DOWN     
 *                                  | 0x09       | joystick1LEFT    
 *                                  | 0x0A       | joystick1RIGHT   
 *                                  | 0x0B       | btnController2A  
 *                                  | 0x0C       | btnController2B  
 *                                  | 0x0D       | joystick2UP      
 *                                  | 0x0E       | joystick2DOWN  
 *                                  | 0x0F       | joystick2LEFT  
 *                                  | 0x10       | joystick2RIGHT
 *                                  | 0x11       | rpg1CW        
 *                                  | 0x12       | rpg1CCW       
 *                                  | 0x13       | rpg2CW        
 *                                  | 0x14       | rpg2CCW       
 */
void processCommand() {
    int commandHex = 0xFF;
    while (MySerial.available()) {
        String command = MySerial.readStringUntil('\n');
        command.trim();

        Serial.print("--- ESP32 RECEIVED: ");
        Serial.println(command);

        if (command == "btnUpArrow") {
            commandHex = 0x00;
            // MAP: Up Arrow Pressed
        } else if (command == "btnDownArrow") {
            commandHex = 0x01;
            // MAP: Down Arrow Pressed
        } else if (command == "btnHomeClick") {
            commandHex = 0x02;
            // MAP: Home Click (select)
        } else if (command == "btnHomeHold") {
            commandHex = 0x03;
            // MAP: Home Hold (go back)
        } else if (command == "btnPowerClick") {
            commandHex = 0x04;
            // MAP: Power Button Click
        } else if (command == "btnController1A") {
            commandHex = 0x05;
            // MAP: Controller 1A
        } else if (command == "btnController1B") {
            commandHex = 0x06;
            // MAP: Controller 1B
        } else if (command == "joystick1UP") {
            commandHex = 0x07;
            // MAP: Joystick 1 Up
        } else if (command == "joystick1DOWN") {
            commandHex = 0x08;
            // MAP: Joystick 1 Down
        } else if (command == "joystick1LEFT") {
            commandHex = 0x09;
            // MAP: Joystick 1 Left
        } else if (command == "joystick1RIGHT") {
            commandHex = 0x0A;
            // MAP: Joystick 1 Right
        } else if (command == "btnController2A") {
            commandHex = 0x0B;
            // MAP: Controller 2A
        } else if (command == "btnController2B") {
            commandHex = 0x0C;
            // MAP: Controller 2B
        } else if (command == "joystick2UP") {
            commandHex = 0x0D;
            // MAP: Joystick 2 Up
        } else if (command == "joystick2DOWN") {
            commandHex = 0x0E;
            // MAP: Joystick 2 Down
        } else if (command == "joystick2LEFT") {
            commandHex = 0x0F;
            // MAP: Joystick 2 Left
        } else if (command == "joystick2RIGHT") {
            commandHex = 0x10;
            // MAP: Joystick 2 Right
        } else if (command == "rpg1CW") {
            commandHex = 0x11;
            // MAP: RPG1 Clockwise
        } else if (command == "rpg1CCW") {
            commandHex = 0x12;
            // MAP: RPG1 Counterclockwise
        } else if (command == "rpg2CW") {
            commandHex = 0x13;
            // MAP: RPG2 Clockwise
        } else if (command == "rpg2CCW") {
            commandHex = 0x14;
            // MAP: RPG2 Counterclockwise
        } else {
            Serial.println("Unknown command received.");
        }

        if ((commandHex == 0) && (prevCommand == 0)) {
            Serial.println("ENABLING THE CONTROLLER!!!!");
            MySerial.println("enableController1");
        }

        if ((commandHex == 1) && (prevCommand == 1)) {
            Serial.println("DISABLING THE CONTROLLER!!!!");
            MySerial.println("disableController1");
        }

        // debugging
        Serial.print("Current: ");
        Serial.print(commandHex);
        Serial.print("\n");
        Serial.print("Previous Command: ");
        Serial.print(prevCommand);
        Serial.print("\n");


        // debugging
        Serial.print("Mapped byte: 0x");
        Serial.println(commandHex, HEX);
        Serial.println("\n");

        // update previous 
        prevCommand = commandHex;
    }
}
 
void setup() {
    initializeUART();
}

void loop() {
    processCommand();
}