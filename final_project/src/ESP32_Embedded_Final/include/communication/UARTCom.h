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
  * This class simply wraps HarwareSerial for simplified UART. This file class is intended to be used by the ESP32 
  * and uses some user config and hardcoded configuration to aid development. HardwareSerial data reception is input driven.
  * 
  * Constructor
  * - empty
  *
  * Methods:
  * - initialize(): configures UART baudrate, frame format, and pins
  * - receive(): interrupt driven receive
  * - transmit(): send serial data over UART
  */
 class UARTCom {
 public:
    /* @brief initalize serial communication 
     * 
     * Initializes the HardwareSerial object on channel 2.
     *
     * @return void 
     */
    UARTCom() : uart(2) {}


    /* @brief initalize serial communication 
     * 
     * configure uart for esp32. all config is hardcoded in .cpp
     *
     * @param none 
     * @return void 
     */
    void initialize();

    /* @brief receive data at RX (interrupt)
     * 
     * receive data 
     *
     * @param none
     * @return TBD
     */
    String receive();

    /* @brief transmit data at TX
     * 
     * send data
     *
     * @param String
     * @return void
     */
    void transmit(String msg);

  private:
    /*
     * Wrapped HardwareSerial object to do the heavy lifting
     */
    HardwareSerial uart;
 };

 #endif
