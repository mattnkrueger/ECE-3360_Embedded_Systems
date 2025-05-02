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

| Byte Value | Input Description        |
|------------|--------------------------|
| 0x00       | btnUpArrow              |
| 0x01       | btnDownArrow            |
| 0x02       | home-btn                |
| 0x03       | btnPower                |
| 0x04       | btnController_1A        |
| 0x05       | btnController_1B        |
| 0x06       | joystick_1Y-up         |
| 0x07       | joystick_1Y-down       |
| 0x08       | joystick_1X-left       |
| 0x09       | joystick_1X-right      |
| 0x0A       | btnController_2A        |
| 0x0B       | btnController_2B        |
| 0x0C       | joystick_2Y-up         |
| 0x0D       | joystick_2Y-down       |
| 0x0E       | joystick_2X-left       |
| 0x0F       | joystick_2X-right      |
| 0x10       | rpg_1-cw               |
| 0x11       | rpg_1-ccw              |
| 0x12       | rpg_2-cw               |

# Developer Notes
Please note that there are **Doxygen** comments in this repository. If you are unfamiliar with [Doxygen](https://doxygen.nl/), it is similar to JavaDocs for Java and builds an HTML page that can be viewed by opening [./docs/html/index.html](). 
