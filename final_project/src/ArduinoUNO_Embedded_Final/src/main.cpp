#include <Arduino.h>
#include <avr/io.h>
#include <avr/interrupt.h>

//////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ HARDWIRED PINS ------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// RPG Definitions 
// const uint8_t RPG2_B = 13;              // PB5      
// const uint8_t RPG2_A = 12;              // PB4
// const uint8_t RPG1_B = 11;              // PB3
// const uint8_t RPG1_A = 10;              // PB2

// System Buttons
// const uint8_t BTN_UP_ARROW   = 4;       // PD4
// const uint8_t BTN_HOME       = 3;       // PD3
// const uint8_t BTN_DOWN_ARROW = 2;       // PD2

// Controller Buttons
const uint8_t BTN_CTRL_1A = 9;          // PB1
const uint8_t BTN_CTRL_1B = 8;          // PB0
const uint8_t BTN_CTRL_2A = 7;          // PD7
const uint8_t BTN_CTRL_2B = 6;          // PD6

// Controller Joysticks (analog)
// const uint8_t JOYSTICK_1X = A0;         // A0
// const uint8_t JOYSTICK_1Y = A1;         // A1
// const uint8_t JOYSTICK_2X = A2;         // A2
// const uint8_t JOYSTICK_2Y = A3;         // A3

// Power Button pins 
// const uint8_t BTN_POWER_1 = A4;         // A4
// const uint8_t BTN_POWER_2 = A5;         // A5

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ Global Variables ------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// store previous pinchanges @ port B & D 
volatile uint8_t prevStateB = 0;
volatile uint8_t prevStateD = 0;

// GLOBAL VARIABLES FOR RPG CHANGES
volatile uint8_t prevRPG1A = 0;
volatile uint8_t prevRPG1B = 0;
volatile uint8_t prevRPG2A = 0;
volatile uint8_t prevRPG2B = 0;

// we are sending data as flags for both B and D pinchanges, these store the current flags. (8 bits as there are only 8 bits in these regs. works out nicely)
volatile uint8_t portB_flags = 0;
volatile bool portB_dirty = false;

// same for D. We do not use C register pin changes (analog joysticks & power button not needed)
volatile uint8_t portD_flags = 0;
volatile bool portD_dirty = false;



/////////////////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------ Button States ------------------------------------------ //
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// debouncing for the buttons
const int DEBOUNCE_MS = 50;
const int HOLD_TIME_MS = 1000;
const int MIN_ON_TIME_MS = 2000;

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

    if ((prevStateB & (1 << PB0)) && !(pinB & (1 << PB0))) {
      isController1BClicked = true;
    }
  }

  // check controller 1 A
  if ((prevStateB & (1 << PB1)) && !(pinB & (1 << PB1))) {
    _delay_ms(DEBOUNCE_MS);
    
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
   uint8_t currRPG2A = (pinB & (1 << PB4)) ? 1 : 0;                                   // We shift left by one to make space for rpg1b.
   uint8_t currRPG2B = (pinB & (1 << PB5)) ? 1 : 0;                                   // Then we combine this with the previous & use codes to determine the rotation.
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
   flags |= isController1BClicked << 0;                                          // b0: controller 1 'B'
   flags |= isController1AClicked << 1;                                          // b1: controller 1 'A'
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
 * PCINT19 (PD3): BTN_HOME
 * PCINT20 (PD4): BTN_UP_ARROW
 * PCINT21 (PD5): none 
 * PCINT22 (PD6): BTN_CTRL_2B
 * PCINT23 (PD7): BTN_CTRL_2A
 * 
 */
ISR(PCINT2_vect) {
  uint8_t pinD = PIND;        // all pins to be masked below...

  // boolean values to build a payload for message
  // bool isDownArrowClicked      = false;
  // bool isHomeClicked           = false;
  // bool isUpArrowClicked        = false;
  bool isController2BClicked   = false;
  bool isController2AClicked   = false;

  // // check down arrow
  // if (!(pinD & (1 << PD2) && (prevStateD & (1 << PD2)))) {
  //   isDownArrowClicked = true;
  // }

  // // check home
  // if (!(pinD & (1 << PD3) && (prevStateD & (1 << PD3)))) {
  //   isHomeClicked = true;
  // }

  // // check down arrow
  // if (!(pinD & (1 << PD4) && (prevStateD & (1 << PD4)))) {
  //   isUpArrowClicked = true;
  // }

  // check controller2 button B
  if ((prevStateD & (1 << PD6)) && !(pinD & (1 << PD6))) {
    _delay_ms(21);
    isController2BClicked = true;
  }

  // check controller2 button A
  if ((prevStateD & (1 << PD7)) && !(pinD & (1 << PD7))) {
    isController2AClicked = true;
  }
  // now, we build the flags to send over UART                                 Flags       
  uint8_t flags = 0;                                                           // b0..1: 0 
  // flags |= isDownArrowClicked << 2;                                            // b2: down arrow clicked
  // flags |= isHomeClicked << 3;                                                 // b3: home clicked
  // flags |= isUpArrowClicked << 4;                                              // b4: up arrow clicked 
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
 * enable PCINT for all buttons
 *
 * PCINTs:
 *    5, 4, 3, 2, 1, 0, 23, 22, 21, 20, 19, 18, 17, 16
 * 
 */
void enableButtonInterrupts() {
  PCICR  |= (1 << PCIE0) | (1 << PCIE1) | (1 << PCIE2);  // turn on pcint for b, c, and d ports
  PCMSK0 |= 0b00111111;                                  // PCINT[0..5] (port b)
  PCMSK1 |= 0x00;                                        // NONE PCINT[8..14]
  PCMSK2 |= 0xFF;                                        // All portd PCINT[16..23] (port d)
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

  // pinMode(RPG1_A, INPUT);
  // pinMode(RPG1_B, INPUT);
  // pinMode(RPG2_A, INPUT);
  // pinMode(RPG2_B, INPUT);
  // pinMode(BTN_UP_ARROW, INPUT_PULLUP);
  // pinMode(BTN_DOWN_ARROW, INPUT_PULLUP);
  pinMode(BTN_CTRL_1A, INPUT_PULLUP);
  pinMode(BTN_CTRL_1B, INPUT_PULLUP);
  // pinMode(BTN_CTRL_2A, INPUT_PULLUP);
  // pinMode(BTN_CTRL_2B, INPUT_PULLUP);
  // pinMode(BTN_POWER_1, INPUT_PULLUP);
  // pinMode(BTN_POWER_2, INPUT_PULLUP);
  // pinMode(JOYSTICK_1X, INPUT);
  // pinMode(JOYSTICK_1Y, INPUT);
  // pinMode(JOYSTICK_2X, INPUT);
  // pinMode(JOYSTICK_2Y, INPUT);

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
 * Additionally, the 
 * 
 */
void loop() {
  if (portB_dirty) {
    Serial.write("\n");
    Serial.write("NEW: \n");

    Serial.write(portB_flags);
    portB_dirty = false;

    // decoding
    Serial.print("controller1B: ");
    Serial.println((portB_flags & (1 << 0)) != 0 ? "1" : "0");

    Serial.print("controller1A: ");
    Serial.println((portB_flags & (1 << 1)) != 0 ? "1" : "0");

    // Serial.print("RPG1Clockwise: ");
    // Serial.println((portB_flags & (1 << 2)) != 0 ? "1" : "0");

    // Serial.print("RPG1CounterClockwise: ");
    // Serial.println((portB_flags & (1 << 3)) != 0 ? "1" : "0");

    // Serial.print("RPG2Clockwise: ");
    // Serial.println((portB_flags & (1 << 4)) != 0 ? "1" : "0");

    // Serial.print("RPG2CounterClockwise: ");
    // Serial.println((portB_flags & (1 << 5)) != 0 ? "1" : "0");

    // Serial.print("Reserved6: ");
    // Serial.println((portB_flags & (1 << 6)) != 0 ? "1" : "0");

    // Serial.print("Reserved7: ");
    // Serial.println((portB_flags & (1 << 7)) != 0 ? "1" : "0");
  }

  // if (portD_dirty) {
  //   Serial.write(portD_flags);
  //   portD_dirty = false;
  
  //   // debugging
  //   Serial.print("DownArrowClicked: ");
  //   Serial.println((portD_flags & (1 << 2)) != 0 ? "1" : "0");

  //   Serial.print("HomeClicked: ");
  //   Serial.println((portD_flags & (1 << 3)) != 0 ? "1" : "0");

  //   Serial.print("UpArrowClicked: ");
  //   Serial.println((portD_flags & (1 << 4)) != 0 ? "1" : "0");

  //   Serial.print("Controller2BClicked: ");
  //   Serial.println((portD_flags & (1 << 6)) != 0 ? "1" : "0");

  //   Serial.print("Controller2AClicked: ");
  //   Serial.println((portD_flags & (1 << 7)) != 0 ? "1" : "0");

  //   Serial.print("Reserved0: ");
  //   Serial.println((portD_flags & (1 << 0)) != 0 ? "1" : "0");

  //   Serial.print("Reserved1: ");
  //   Serial.println((portD_flags & (1 << 1)) != 0 ? "1" : "0");
  // }
}