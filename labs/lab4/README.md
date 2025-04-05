# Lab 4: Pulse Width Modulation Fan 

[Home](../../README.md)

## Directions
This lab explores PWM using the ATmega328P microcontroller. Included in the project is a PWM Fan controlled by input via a Rotary Pulse Generator. The current duty cycle of the fan is displayed by the LCD.

## Circuit
<div align="center">
    <img width="100%" src="./KiCAD/lab4_schematic.png">
</div>
<div align="center">
    KiCAD Schematic of Lab 4
</div>

## Components List
<div align="center">

| Component | Quantity |
|:-----------:|:----------:|
| Atmega328P µC | 1 |
| Enable Low Push Button | 1 |
| Rotary Pulse Generator | 1 |
| 16x2 LCD Display | 1 |
| PWM Fan | 1 |
| 100KΩ Resistor | 1 |
| 10KΩ Resistor | 4 |
| 1KΩ Resistor | 1 |
| 330Ω Resistor | 1 |
| 0.1µF Capacitor | 4 |

</div>

## Functionality
The fan monitoring system is interrupt driven via the pushbutton and rotary pulse generator encoder. 

Button: 
Control fan on/off
- If the PWM fan is on and the button is clicked, the previous PWM value is saved and then the current PWM is set to 0 - Off.
- If the PWM fan is off and the button is clicked, the previous PWM value is loaded as the current PWM value - ON. 

Rotary Pulse Generator:
Control PWM duty cycle
- A clockwise turn increases the PWM value, and a counterclockwise turn decreases the PWM value. 


## References 
- [main.asm](../lab4/asm/main.asm): assembly code for lab
- [Lab Report](../lab4/lab_report/es_lab_report_4.pdf): detailed lab report
