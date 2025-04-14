#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include <avr/io.h>

// Function to initialize ADC
void ADC_init() {
    // external capacitor
    ADMUX = (1<<REFS0);  // Use 1.1 Volt reference 

    // Set ADC prescaler to 64 (for 16 MHz clock)
    ADCSRA |= (1 << ADPS2) | (1 << ADPS1);  // Prescaler 64
                                            // For stable ADC conversions 250Khz

    // Enable the ADC
    ADCSRA |= (1 << ADEN);
}

// Function to read ADC value from the specified channel
float read_ADC() {

    // Start the conversion
    ADCSRA |= (1 << ADSC);  // Start conversion

    // Wait for the conversion to finish
    while (ADCSRA & (1 << ADSC));  // Wait for the ADSC flag to be cleared (conversion complete)

    // Read the ADC value (low and high byte)
    uint16_t adc_Value = ADC;  // Combine ADCL and ADCH (ADC is 10-bit)
    float voltage = adc_Value * (5 / 1023.0);  

    return voltage;  // Return the ADC value
}

void setup() {
    // Initialize Serial communication (Arduino-style)
    Serial.begin(9600);

    // Wait for Serial Monitor to open
    while (!Serial);

    // Initialize ADC
    ADC_init();
}

void loop() {
    // Check if data is available to read from the Serial Monitor
    if (Serial.available() > 0) {
        char receivedChar = Serial.read();  // Read the received character

        if (receivedChar == 'G') {  // If the character is 'G'
            // Read the analog value from the potentiometer (using ADC channel 0)
            float voltage = read_ADC();

            // Send the voltage back to the Serial Monitor
            Serial.print("Potentiometer Voltage: ");
            Serial.print(voltage, 2);  // Print voltage with 2 decimal places
            Serial.println(" V");
        }
    }
}
