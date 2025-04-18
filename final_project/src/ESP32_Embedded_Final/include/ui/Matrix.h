/*
 * Matrix.h
 * 
 *  Project: Embedded Systems Final Project
 *  Authors: Matt Krueger and Sage Marks
 * 
 *  This file contains the definition of the Matrix class.
 *
 */

 /*
  * Class Matrix:
  *
  * This class simply wraps ESP32 HUB75 LED MATRIX PANEL DMA for simplified Matrix development. This file class is intended to be used by the ESP32 
  * and uses some user config and hardcoded configuration to aid development. Adafruit GFX is also utilized in this class to create parameterized displays 
  * 
  * Constructor
  * - Matrix(): initialize the 64x64 Matrix. We have this all hardcoded as our project schematic & components will remain unchanged.
  *
  * Methods:
  * - changeLayout(): changes to user specified layout
  * - changePalette(): changes to user specified color pallete
  * - turnOn(): send serial data over UART
  * - turnOff(): send serial data over UART
  */
class Matrix {

}