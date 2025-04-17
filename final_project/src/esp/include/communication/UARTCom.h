/*
 *  UARTCom.h
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file contains the definition of the UARTCom class.
 *
 */

 #ifndef UARTCom_H
 #define UARTCom_H

 #include <HardwareSerial.h>

 /*
  * Class UARTCom:
  *
  * This class simply wraps HarwareSerial for simplified UART. This file is class is intended to be used by both the Arduino UNO and by the ESP32, 
  * thus it hardcodes necessary communication configurations.
  * 
  * Constructor
  * - UARTcom(): initialize the UART channel. We have our board as 1
  *
  * Methods:
  * - initialize(): configures UART baudrate, frame format, and pins
  * - receive(): interrupt driven receive
  * - transmit(): send serial data over UART
  */
 class UARTCom {
 public:
    /* @brief constructor for wrapper class
     * 
     * Sets the wanted TX/RX channel on the ESP32 board. This is used downstream when using the HardwareSerial object.
     *
     * @param channel: TX/RX channel. ESP32 includes 0, 1, 2 
     */
    UARTCom(int channel);

    /* @brief initalize serial communication 
     * 
     * Initializes the UART Protocol on respective channel pins. Using the user
     * specified channel via the constructor, the ESP32 UART Protol is configured.
     * This is done by wrapping HardwareSerial's begin() method
     *
     * @param baud: baudrate (default 115200 ESP32)
     * @param config: protocol config (default SERIAL_8N1)
     * @param channel: TX/RX channel (default 1) 
     * @return void 
     */
    void initialize(unsigned long baud = 115200, SerialConfig config = SERIAL_8E1, uint8_t channel = 2);

    /* @brief receive data at RX (interrupt)
     * 
     * This interrupt listens for data on the RX line of the UART channel. The message is 
     * JSON serialized, which is then parsed and returned for downstream analysis.
     *
     * @param none
     * @return String: JSON string received at RX port
     */
    String receive();


    /* @brief transmit data at TX
     * 
     * This function formats a user specified command into JSON, then sends it over the UART TX
     * port to be received by the Arduino UNO. Comprehensive use of integers here should speed
     * the overall UART transmission/reception time as char streams require more marks/spaces.
     * 
     * See Commands.md for required format and commands used
     *
     * @param origin: command origin - did this come from user (development mode), player1 or player2 (game mode)
     * @param mode: location to execute command - location to take action. some modes may consist of different commands
     * @param command: executable - action to execute: cursor/general movements, mode specific commands, etc
     * @param status: reception status - did the receiver get the message?
     * @return void
     */
    void transmit(String origin, String mode, String command, bool status);

  private:
    /*
     * Wrapped HardwareSerial object to do the heavy lifting
     */
    HardwareSerial uart;
 };

 #endif
