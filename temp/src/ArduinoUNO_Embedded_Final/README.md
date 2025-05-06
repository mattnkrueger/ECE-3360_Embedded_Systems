# ArduinoUNO Source Code
The purpose of this code is to process user interaction and send it in a format to be received by the master ESP32 controller. Because the complexity of the Arduino program is minimal, we decided to structure it in one file, noting the important sections with comments. 

ROTARY PULSE GENERATOR PINS 
rpg_1A - pin 13 (PB5)
rpg_1B - pin 12 (PB4)
rpg_2A - pin 11 (PB3)
rpg_2B - pin 10 (PB2)

BUTTON PINS:
btnUpArrow       - pin 8 (PB0)
btnDownArrow     - pin 7 (PD7)
btnController_1A - pin 6 (PD6)
btnController_1B - pin 5 (PD5)
btnController_2A - pin 4 (PD4)
btnController_2B - pin 3 (PD3)

JOYSTICK PINS:
joystick_1X - (A0)
joystick_1Y - (A1)
joystick_2X - (A2)
joystick_2Y - (A3)

POWER BUTTON:
btnPower is connected to a circuit that connects to A4 and A5

The Arduino is simply an interface for the ESP32, sending bytes over UART. To reduce the bottleneck of a single UART connection (we had looked into parallelizing the system to reduce latency for games that take two controllers... UNO board only has one UART TX/RX pair... a Mega is needed for this optimization), we have the baud rate set to 115200 (8N1), and send only a single byte per user interaction. Additionally, the inputs are interrupt driven. The interactions are mapped below:

FROM ARDUINO

| Byte Value | String Value        |
|------------|--------------------------|
| 0x00       | btnUpArrow              | 
| 0x01       | btnDownArrow            |
| 0x02       | btnHomeClick (select)  |
| 0x03       | btnHomeHold (go back) |
| 0x04       | btnPowerClick                |
| 0x05       | btnController1A        |
| 0x06       | btnController1B        |
| 0x07       | joystick1UP         |
| 0x08       | joystick1DOWN       |
| 0x09       | joystick1LEFT      |
| 0x0A       | joystick1RIGHT      |
| 0x0B       | btnController2A        |
| 0x0C       | btnController2B        |
| 0x0D       | joystick2UP         |
| 0x0E       | joystick2DOWN       |
| 0x0F       | joystick2LEFT       |
| 0x10       | joystick2RIGHT      |
| 0x11       | rpg1CW               |
| 0x12       | rpg1CCW              |
| 0x13       | rpg2CW               |
| 0x14       | rpg2CCW               |

FROM ESP32
| Byte Value | Input Description        |
|------------|--------------------------|
| 0x15       | enable controller 1 |
| 0x16       | enable controller 1 |


# Developer Notes
Please note that there are **Doxygen** comments in this repository. If you are unfamiliar with [Doxygen](https://doxygen.nl/), it is similar to JavaDocs for Java and builds an HTML page that can be viewed by opening [./docs/html/index.html](). 



Debugging the system:
`
  ... 

  if (portB_dirty) {
    Serial.write(portB_flags);
    portB_dirty = false;

    debugging
    Serial.write("\n");
    Serial.write("NEW B: \n");
    Serial.print("controller1B: ");
    Serial.println((portB_flags & (1 << 0)) != 0 ? "1" : "0"
    Serial.print("controller1A: ");
    Serial.println((portB_flags & (1 << 1)) != 0 ? "1" : "0"
    Serial.print("RPG1Clockwise: ");
    Serial.println((portB_flags & (1 << 2)) != 0 ? "1" : "0"
    Serial.print("RPG1CounterClockwise: ");
    Serial.println((portB_flags & (1 << 3)) != 0 ? "1" : "0"
    Serial.print("RPG2Clockwise: ");
    Serial.println((portB_flags & (1 << 4)) != 0 ? "1" : "0"
    Serial.print("RPG2CounterClockwise: ");
    Serial.println((portB_flags & (1 << 5)) != 0 ? "1" : "0");
  }

  if (portD_dirty) {
    Serial.write(portD_flags);
    portD_dirty = false;
  
    // debugging
    Serial.print("DownArrowClicked: ");
    Serial.println((portD_flags & (1 << 2)) != 0 ? "1" : "0"
    Serial.print("UpArrowClicked: ");
    Serial.println((portD_flags & (1 << 4)) != 0 ? "1" : "0"
    Serial.print("Controller2BClicked: ");
    Serial.println((portD_flags & (1 << 6)) != 0 ? "1" : "0"
    Serial.print("Controller2AClicked: ");
    Serial.println((portD_flags & (1 << 7)) != 0 ? "1" : "0");

    ...
  }
`