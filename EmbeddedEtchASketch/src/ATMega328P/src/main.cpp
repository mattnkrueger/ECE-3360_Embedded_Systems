/**
 * @file main.cpp
 * @author Matt Krueger & Sage Marks
 * @brief Arduino Sketch for Embedded Systems Final Project
 * @version 0.2
 * @date 2025-05-03
 * 
 * @copyright Copyright (c) 2025
 * 
 * Included in this file is all I/O Pin definitions, methods, ISRs, and UART communication with the ESP32.
 * The functionality of the Arduino is simply a dummy terminal - converting actions made by the user (button click, rpg turn, joystick flick, etc) 
 * into a command that can be mapped to a function. This is sent over the UART channel to the ESP32 for processing.
 * 
 * This file is very long, however, it is necessary that the ISR & UART communication (the main functionality of the Arduino device) be on the main.cpp 
 * to avoid any issues.
 * 
 * No internal libraries were included and no external libraries were used. All functionality extended from Arduino AVR C built-in libraries
 * 
 */

 #include <Arduino.h>
 #include <avr/io.h>
 #include <avr/interrupt.h>
 
 //////////////////////////////////////////////////////////////////////////////////////////////////////////
 // ------------------------------------------ HARDWIRED PINS ------------------------------------------ //
 //////////////////////////////////////////////////////////////////////////////////////////////////////////
 // RPG Definitions 
 const uint8_t RPG2_B = 13;              // PB5      
 const uint8_t RPG2_A = 12;              // PB4
 const uint8_t RPG1_B = 11;              // PB3
 const uint8_t RPG1_A = 10;              // PB2
 
 // System Buttons
 const uint8_t BTN_UP_ARROW   = 4;       // PD4
 const uint8_t BTN_HOME       = 3;       // PD3
 const uint8_t BTN_DOWN_ARROW = 2;       // PD2
 
 // Controller Buttons
 const uint8_t BTN_CTRL_1A = 9;          // PB1
 const uint8_t BTN_CTRL_1B = 8;          // PB0
 const uint8_t BTN_CTRL_2A = 7;          // PD7
 const uint8_t BTN_CTRL_2B = 6;          // PD6
 
 // Controller Joysticks (analog)
 const uint8_t JOYSTICK_1X = A0;         // A0
 const uint8_t JOYSTICK_1Y = A1;         // A1
 const uint8_t JOYSTICK_2X = A2;         // A2
 const uint8_t JOYSTICK_2Y = A3;         // A3
 
 // Power Button pins 
 const uint8_t POWER_PIN  = A4;          // PC4 (A4)
 const uint8_t BTN_POWER = A5;           // PC5 (A5)
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////
 // ------------------------------------------ Global Variables ------------------------------------------ //
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////
 // store previous pinchanges 
 volatile uint8_t prevStateB = 0;
 volatile uint8_t prevStateC = 0;
 volatile uint8_t prevStateD = 0;
 
 // rpg changes
 volatile uint8_t prevRPG1A = 0;
 volatile uint8_t prevRPG1B = 0;
 volatile uint8_t prevRPG2A = 0;
 volatile uint8_t prevRPG2B = 0;
 
 // dirty and data flags 
 volatile uint8_t portB_flags = 0;
 volatile bool portB_dirty = false;
 volatile uint8_t portD_flags = 0;
 volatile bool portD_dirty = false;
 
 // status of the system
 volatile bool powerON = true;
 
 volatile bool prevHomeBTN = false;
 
 // status of controllers. This is depending on the current context of the system. Controllers enabled for Chess
 volatile bool controller1Enabled = false;
 volatile bool controller2Enabled = false;
 
 bool prevHomeState = HIGH;
 unsigned long homeStartPress = 0;
 
 /////////////////////////////////////////////////////////////////////////////////////////////////////////
 // ------------------------------------------ Button Timing ------------------------------------------ //
 /////////////////////////////////////////////////////////////////////////////////////////////////////////
 // debouncing for the buttons
 const int DEBOUNCE_MS = 50;
 const int HOLD_TIME_MS = 1000;                // hold timing timing for power & home button
 const int MIN_ON_TIME_MS = 2000; 
 
 // Global variables for power management
 volatile bool power_state = true;
 volatile uint32_t hold_counter = 0;
 volatile bool button_was_pressed = false;
 volatile unsigned long power_button_press_start = 0;
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 // ------------------------------------------ Interrupts Service Routines ------------------------------------------ //
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 /**
  * @brief Construct a new ISR object for PCINT[0..7] (port b)
  * 
  * PCINT0 (PB0): BTN_CONTROLLER_1B
  * PCINT1 (PB1): BTN_CONTROLLER_1A
  * PCINT2 (PB2): RPG_1A
  * PCINT3 (PB3): RPG_1B
  * PCINT4 (PB4): RPG_2A
  * PCINT5 (PB5): RPG_2B
  * PCINT6: none
  * PCINT7: none
  * 
  * Because these are pin changes and we have buttons, the interrupt will be called twice for all buttons - which is not ideal.
  * To combat this, we track the previous state of the pins and mask each button.
  * If there is a change then we update the current state to reflect this.
  * The entire current state of pin is then sent over UART
  * 
  * Yes, this is not a 'short' ISR, but as we have all GPIO pins attached it is necessary that the ISR is more involved
  * 
  */
 ISR(PCINT0_vect) {
   uint8_t pinB                = PINB;         // all pins to be masked below...
 
   bool isController1BClicked  = false;
   bool isController1AClicked  = false;
   bool isRPG1Clockwise        = false;
   bool isRPG1CounterClockwise = false;
   bool isRPG2Clockwise        = false;
   bool isRPG2CounterClockwise = false;
 
   // check controller 1 B
   if ((prevStateB & (1 << PB0)) && !(pinB & (1 << PB0))) {
     _delay_ms(DEBOUNCE_MS);
 
     pinB = PINB;
     if ((prevStateB & (1 << PB0)) && !(pinB & (1 << PB0))) {
       isController1BClicked = true;
     }
   }
 
   // check controller 1 A
   if ((prevStateB & (1 << PB1)) && !(pinB & (1 << PB1))) {
     _delay_ms(DEBOUNCE_MS);
     
     pinB = PINB;
     if ((prevStateB & (1 << PB1)) && !(pinB & (1 << PB1))) {
       isController1AClicked = true;
     }
   }
 
    // check RPG 1                                                                        here we perform a similar process to our Lab5, combining both A and B.
    uint8_t currRPG1A = (pinB & (1 << PB2)) ? 1 : 0;                                   // We shift left by one to make space for rpg1b.
    uint8_t currRPG1B = (pinB & (1 << PB3)) ? 1 : 0;                                   // Then we combine this with the previous & use codes to determine the rotation.
    uint8_t currRPG1       = (currRPG1A << 1) | currRPG1B;                             // now a 2 bit AB 00, 01, 10, 11 value
    uint8_t transitionRPG1 = (prevRPG1A << 3) | (prevRPG1B << 2) | (currRPG1);         // now a 4 bit ABAB value, with cases below
  
    switch (transitionRPG1) {
      case 0b0001: case 0b0111: case 0b1110: case 0b1000:
        // Clockwise
        isRPG1Clockwise = true;
        break;
      case 0b0010: case 0b0100: case 0b1101: case 0b1011:
        // Counter-clockwise
        isRPG1CounterClockwise = true;
        break;
      default:
        // on detent; ignore
        break;
    }
 
    prevRPG1A = currRPG1A; 
    prevRPG1B = currRPG1B;
 
    // check RPG 2                                                                        here we perform a similar process to our Lab5, combining both A and B.
    uint8_t currRPG2A = (pinB & (1 << PB5)) ? 1 : 0;                                   // We shift left by one to make space for rpg1b.
    uint8_t currRPG2B = (pinB & (1 << PB4)) ? 1 : 0;                                   // Then we combine this with the previous & use codes to determine the rotation.
    uint8_t currRPG2       = (currRPG2A << 1) | currRPG2B;                             // now a 2 bit AB 00, 01, 10, 11 value
    uint8_t transitionRPG2 = (prevRPG2A << 3) | (prevRPG2B << 2) | (currRPG2);         // now a 4 bit ABAB value, with cases below
  
    switch (transitionRPG2) {
      case 0b0001: case 0b0111: case 0b1110: case 0b1000:
        // Clockwise
        isRPG2Clockwise = true;
        break;
      case 0b0010: case 0b0100: case 0b1101: case 0b1011:
        // Counter-clockwise
        isRPG2CounterClockwise = true;
        break;
      default:
        // on detent; ignore
        break;
    }
 
    prevRPG2A = currRPG2A; 
    prevRPG2B = currRPG2B;
 
    // now, we build the flags to send over UART                                 Flags       
    uint8_t flags = 0;                                                         
    flags |= isController1BClicked << 0;                                       // b0: controller 1 'B'
    flags |= isController1AClicked << 1;                                       // b1: controller 1 'A'
    flags |= isRPG1Clockwise << 2;                                             // b2: RPG1 cw
    flags |= isRPG1CounterClockwise << 3;                                      // b3: RPG1 ccw (these are mutually exclusive)
    flags |= isRPG2Clockwise << 4;                                             // b4: RPG2 cw
    flags |= isRPG2CounterClockwise << 5;                                      // b5: RPG2 ccw (again, these are mutually exclusive)
    flags |= (0 << 6) | ( 0 << 7);                                             // b6,7: 0
 
    // update flags and set dirty if there was an action
    if (flags != 0) { 
     portB_flags = flags;
     portB_dirty = true;
    }
 
    prevStateB = pinB;
 }
 
 /**
  * @brief Construct a new ISR object for PCINT[16..23] (port d)
  * 
  * PCINT16 (PD0): none (uart rx)
  * PCINT17 (PD1): none (uart tx)
  * PCINT18 (PD2): BTN_DOWN_ARROW
  * PCINT19 (PD3): none
  * PCINT20 (PD4): BTN_UP_ARROW
  * PCINT21 (PD5): none 
  * PCINT22 (PD6): BTN_CTRL_2B
  * PCINT23 (PD7): BTN_CTRL_2A
  * 
  */
 ISR(PCINT2_vect) {
   uint8_t pinD = PIND;        // all pins to be masked below...
 
   // boolean values to build a payload for message
   bool isDownArrowClicked      = false;
   bool isUpArrowClicked        = false;
   bool isController2BClicked   = false;
   bool isController2AClicked   = false;
 
   // check down arrow
   if ((prevStateD & (1 << PD2)) && !(pinD & (1 << PD2))) {
     _delay_ms(DEBOUNCE_MS);
 
     pinD = PIND;
     if ((prevStateD & (1 << PD2)) && !(pinD & (1 << PD2))) {
       isDownArrowClicked = true;
     }
   }
 
   // check up arrow 
   if ((prevStateD & (1 << PD4)) && !(pinD & (1 << PD4))) {
     _delay_ms(DEBOUNCE_MS);
 
     pinD = PIND;
     if ((prevStateD & (1 << PD4)) && !(pinD & (1 << PD4))) {
       isUpArrowClicked = true;
     }
   }
 
   // check controller 2 B
   if ((prevStateD & (1 << PD6)) && !(pinD & (1 << PD6))) {
     _delay_ms(DEBOUNCE_MS);
 
     pinD = PIND;
     if ((prevStateD & (1 << PD6)) && !(pinD & (1 << PD6))) {
       isController2BClicked = true;
     }
   }
 
   // check controller 2 A
   if ((prevStateD & (1 << PD7)) && !(pinD & (1 << PD7))) {
     _delay_ms(DEBOUNCE_MS);
 
     pinD = PIND;
     if ((prevStateD & (1 << PD7)) && !(pinD & (1 << PD7))) {
       isController2AClicked = true;
     }
   }
 
   // now, we build the flags to send over UART                                 Flags       
   uint8_t flags = 0;                                                           // b0: none 
   flags |= (0 << 0) | (0 << 1);                                                // b1: none
   flags |= isDownArrowClicked << 2;                                            // b2: down arrow clicked
   flags |= (0 << 3);                                                           // b3: home clicked
   flags |= isUpArrowClicked << 4;                                              // b4: up arrow clicked 
   flags |= (0 << 5);                                                           // b5: none
   flags |= isController2BClicked << 6;                                         // b6: controller 'B' clicked
   flags |= isController2AClicked << 7;                                         // b7: controller 'A' clicked
 
   // update flags and set dirty if there was an action
   if (flags != 0) {
     portD_flags = flags;
     portD_dirty = true;
   }
 
   prevStateD = pinD;
 }
 
 /**
  * @brief enable pin change interrupts
  * 
  * enable PCINT for ALL buttons connected to the Arduino
  * 
  */
 void enableButtonInterrupts() {
   PCICR  |= (1 << PCIE0) | (1 << PCIE1) | (1 << PCIE2);  // turn on pcint for b, c, and d ports
   PCMSK0 |= 0b00111111;                                  // PCINT[0..5] (port b)
   PCMSK1 |= 0x00;                                        // NONE of pinchange 1 (port C)
   PCMSK2 |= 0xFF;                                        // ALL portd PCINT[16..23] (port d)
 }
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////
 // ------------------------------------------ Power Button ------------------------------------------ //
 ////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 /**
  * @brief handle safe power toggling
  * 
  * We are limited to using polling for multifunctionality buttons as we cannot check for a press and hold inside of interrupt.
  *
  * programmed for two signals: 
  * 1. press > 1 second ---> turn off
  * 2. press < 1 second ---> turn on 
  * 
  */

  /**
  * @brief handle power button
  * 
  * Implements power control logic from the second code sample
  * Uses debouncing, hold detection, and power state management
  */
 void checkPowerBTN(void) {
  // Read button state (active LOW)
  bool buttonPressed = (digitalRead(BTN_POWER) == LOW);
  
  if (buttonPressed) {
    // Debounce
    delay(DEBOUNCE_MS);
    buttonPressed = (digitalRead(BTN_POWER) == LOW);
    
    if (buttonPressed) {
      // Confirmed press
      if (!button_was_pressed) {
        button_was_pressed = true;
        power_button_press_start = millis();
      }
      
      // Calculate hold time
      unsigned long hold_time = millis() - power_button_press_start;
      
      // Check if hold time exceeds threshold
      if (hold_time >= HOLD_TIME_MS) {
        if (power_state) {
          // Power OFF sequence
          Serial.println("powerOFF"); // Notify ESP32 about power off
          digitalWrite(POWER_PIN, LOW);
          power_state = false;
          
          // Wait for button release before proceeding
          while (digitalRead(BTN_POWER) == LOW) {
            delay(10);
          }
        } else {
          // Power ON sequence
          digitalWrite(POWER_PIN, HIGH);
          power_state = true;
          Serial.println("powerON"); // Notify ESP32 about power on
          
          // Prevent instant turn-off
          delay(MIN_ON_TIME_MS);
          
          // Wait for button release
          while (digitalRead(BTN_POWER) == LOW) {
            delay(10);
          }
        }
      }
    }
  } else {
    // Button released
    button_was_pressed = false;
  }
}

 void handle_power_toggle(void) {
   // Implementation moved to checkPowerBTN for simplicity
   checkPowerBTN();
 }
 
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////
 // ------------------------------------------ Home Button ------------------------------------------ //
 ///////////////////////////////////////////////////////////////////////////////////////////////////////
 
 /**
  * @brief handle home button click  
  * 
  * We are limited to using polling for multifunctionality buttons as we cannot check for a press and hold inside of interrupt. Maybe you can? we struggled to 
  * 
  * programmed for two signals: 
  * 1. press > 1 second
  * 2. press < 1 second
  * 
  * These commands are processed by the ESP32, completely abstracted away from the Arduino. 
  * The functionality of the command is dependent on the current context displayed on the LED Matrix
  * 
  */
 void checkHomeBTN(void) {
   cli();
   bool currHomeState = digitalRead(BTN_HOME);
 
   // press detected. start 'stopwatch'
   if (prevHomeState == HIGH && currHomeState == LOW) {
     _delay_ms(DEBOUNCE_MS);
     if (digitalRead(BTN_HOME) == LOW) {
       homeStartPress = millis();
     }
   }
 
   // release detected, end 'stopwatch'
   if (prevHomeState == LOW && currHomeState == HIGH) {
     _delay_ms(DEBOUNCE_MS);
     if (digitalRead(BTN_HOME) == HIGH) {
       unsigned long duration = millis() - homeStartPress;
       if (duration < 1000) {
         // Serial.write(0x02);             // short press: select
         Serial.println("btnHomeClick");
       } else {
         // Serial.write(0x03);             // long press: exit
         Serial.println("btnHomeHold");
       }
     }
   }
 
   prevHomeState = currHomeState;
   sei(); 
 }
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////
 // ------------------------------------------ Joystick Modules ------------------------------------------ //
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 /**
  * @brief read the controller deadzone
  * 
  * both controllers have same circuit, so we read and pass a deadzone to reduce noisy incorrect movements
  * 
  * @param controllerNumber 
  * @param deadzone 
  */
 void checkControllerJoystick(int controllerNumber, int deadzone) {
   // pick the right pins
   int xPin = (controllerNumber == 1) ? JOYSTICK_1X : JOYSTICK_2X;
   int yPin = (controllerNumber == 1) ? JOYSTICK_1Y : JOYSTICK_2Y;
 
   int x = analogRead(xPin);
   int y = analogRead(yPin);
 
   // threshholds for deadzone
   int lowThreshold  = deadzone;       
   int highThreshold = 1023 - deadzone; 
 
   String direction;
 
   if (x < lowThreshold)              direction = "right";
   else if (x > highThreshold)        direction = "left";
   else if (y < lowThreshold)         direction = "up";
   else if (y > highThreshold)        direction = "down";
 
   // MAP TO MESSAGE 
   // uint8_t code = 0xFF;
   String code = "NONE";
   if (controllerNumber == 1) {
     if (direction == "up") {
         // code = 0x07; 
         code = "joystick1UP";
     } else if (direction == "down") {
         // code = 0x08;  
         code = "joystick1DOWN";
     } else if (direction == "left") {
         // code = 0x09;  
         code = "joystick1LEFT";
     } else if (direction == "right") {
         // code = 0x0A; 
         code = "joystick1RIGHT";
     }
   } else {  // controller 2
     if (direction == "up") {
         // code = 0x0D; 
         code = "joystick2UP";
     } else if (direction == "down") {
         // code = 0x0E; 
         code = "joystick2DOWN";
     } else if (direction == "left") {
         // code = 0x0F;
         code = "joystick2LEFT";
     } else if (direction == "right") {
         // code = 0x10;  
         code = "joystick2RIGHT";
     }
   }
 
 // only send if actual movement
 // if (code != 0xFF) {
 //   Serial.write(code);
 // }
 if (code != "NONE") {
   Serial.println(code);
 }
 }
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////
 // ------------------------------------------ UART Processing ------------------------------------------ //
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 /**
  * @brief handle incoming messages from the ESP32
  * 
  * checks for messages to enable or disable the controllers
  * 
  * *** SEE README FOR COMMANDS ***
  * 
  */
 void processESP32Message() {
   while (Serial.available()) {
     String command = Serial.readStringUntil('\n');
     command.trim();  // remove whitespace + newline characters
 
     if (command == "enableController1") {
       controller1Enabled = true;
     } 
     else if (command == "enableController2") {
       controller2Enabled = true;
     } else {
       // debugging
       Serial.print("CURRENT STATE: ");
       Serial.print(command);
     }
   }
 }
 
 /**
  * @brief send pinchange results to ESP32
  * 
  * @param flags 
  * @param port 
  */
 void sendCommandFromFlags(uint8_t flags, char port) {
   if (port == 'B') {
     if (flags & (1 << 0)) {     // isController1BClicked
       // Serial.write(0x06);  
       Serial.println("controller1B");
     }
     if (flags & (1 << 1)) {     // isController1AClicked
       // Serial.write(0x05);  
       Serial.println("controller1A");
     }
     if (flags & (1 << 2)) {     // isRPG1Clockwise
       // Serial.write(0x11);  
       Serial.println("rpg1CW");
     }
     if (flags & (1 << 3)) {      // isRPG1CounterClockwise
       // Serial.write(0x12);  
       Serial.println("rpg1CCW");
     }
     if (flags & (1 << 4)) {      // isRPG2Clockwise
       // Serial.write(0x13);  
       Serial.println("rpg2CW");
     }
     if (flags & (1 << 5)) {      // isRPG2CounterClockwise
       // Serial.write(0x14);  
       Serial.println("rpg2CCW");
     }
   } 
   else if (port == 'D') {
     if (flags & (1 << 2)) {     // isDownArrowClicked
       // Serial.write(0x01);  
       Serial.println("btnDownArrow"); 
     }
     if (flags & (1 << 4)) {     // isUpArrowClicked
       // Serial.write(0x00);  
       Serial.println("btnUpArrow");
     }
     if (flags & (1 << 6)) {     // isController2BClicked
       // Serial.write(0x0C);  
       Serial.println("controller2B");
     }
     if (flags & (1 << 7)) {     // isController2AClicked
       // Serial.write(0x0B);  
       Serial.println("controller2A");
     }
   }
 }
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////
 // ------------------------------------------ Main Program ------------------------------------------ //
 ////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 /**
  * @brief initialize pin modes for all I/O peripherals
  * 
  * Initializes RPG 1 & 2
  * Initializes Button inputs
  * Initializes Joystick inputs 
  * Initializes Power Circuit inputs
  * 
  * Additionally, the serial communication with the ESP32 is setup here.
  */
 void setup() {
   Serial.begin(115200);
 
   // inputs (rpgs, buttons, joysticks)
   pinMode(RPG1_A, INPUT);
   pinMode(RPG1_B, INPUT);
   pinMode(RPG2_A, INPUT);
   pinMode(RPG2_B, INPUT);
   pinMode(BTN_UP_ARROW, INPUT_PULLUP);
   pinMode(BTN_DOWN_ARROW, INPUT_PULLUP);
   pinMode(BTN_HOME, INPUT_PULLUP);
   pinMode(BTN_CTRL_1A, INPUT_PULLUP);
   pinMode(BTN_CTRL_1B, INPUT_PULLUP);
   pinMode(BTN_CTRL_2A, INPUT_PULLUP);
   pinMode(BTN_CTRL_2B, INPUT_PULLUP);
   pinMode(BTN_POWER, INPUT_PULLUP);
   pinMode(JOYSTICK_1X, INPUT);
   pinMode(JOYSTICK_1Y, INPUT);
   pinMode(JOYSTICK_2X, INPUT);
   pinMode(JOYSTICK_2Y, INPUT);
 
   // output (voltage for power circuit)
   pinMode(POWER_PIN, OUTPUT);
   digitalWrite(POWER_PIN, HIGH);  // Start with power ON
 
   // Critical stabilization delay
   delay(500);  // Wait for power to settle
 
   enableButtonInterrupts();
   sei();
 }
 
 /**
  * @brief main loop for Arduino Program
  * 
  * Interrupt driven, listens for change at inputs which alter diry flags
  * If a dirty flag is set, then the pinchange flags (see ISR as pinchange edge trigger cannot be specified)
  * are sent over UART to the ESP32
  * 
  * For the power and the home button, these have different functions depending on the duration of the press. 
  * This makes interrupts not an option for these, so this loop polls them. Additionally, the joysticks are polled 
  * if the current context requires joysticks. 
  * 
  */
 void loop() {
   // POLL BUTTONS
   handle_power_toggle();
   checkHomeBTN();
 
   // CHECK FOR ENABLE/DISABLE MSGs
   processESP32Message();
   
   // READ joysticks if enabled
   if (controller1Enabled) {
     checkControllerJoystick(1, 30);
   }
 
   if (controller2Enabled) {
     checkControllerJoystick(2, 30);
   }
 
   // CHECK PINCHANGE
   if (portB_dirty) {
     sendCommandFromFlags(portB_flags, 'B');
     portB_dirty = false;
   }
 
   if (portD_dirty) {
     sendCommandFromFlags(portD_flags, 'D');
     portD_dirty = false;
   }
 }