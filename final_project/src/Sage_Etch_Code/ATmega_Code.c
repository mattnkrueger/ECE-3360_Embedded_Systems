#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdbool.h>

// Define pins for rotary encoders
#define RPG_1_A PB2
#define RPG_1_B PB3
#define RPG_2_A PB4
#define RPG_2_B PB5

// Define pins for power control
#define BUTTON_PIN   PC5  // Button input (active LOW)
#define POWER_PIN    PC4  // MOSFET control (HIGH = ON)

// Anti-glitch settings
#define DEBOUNCE_MS    50
#define HOLD_TIME_MS   1000
#define MIN_ON_TIME_MS 2000

// USART settings
#define FOSC 16000000                     // Oscillator frequency
#define BAUD 9600                         // BAUD Rate
#define MYUBRR FOSC/16/BAUD-1             // USART register value

// Global variables for rotary encoders
volatile uint8_t prevPINB;                // Previous state of PORTB
volatile uint8_t rpg1_last;               // Last valid state of RPG1
volatile uint8_t rpg2_last;               // Last valid state of RPG2
volatile int threshold;                   // Threshold for rotary encoder changes

// Global variables for power management
volatile bool power_state = true;
volatile uint32_t hold_counter = 0;
volatile bool button_was_pressed = false;

///////////////////////////////////////////////
// USART FUNCTIONS
///////////////////////////////////////////////
void USART0_Init(unsigned int ubrr) {
	UBRR0H = (unsigned char)(ubrr>>8);    // Set the baud rate
	UBRR0L = (unsigned char)ubrr;
	UCSR0B = (1<<RXEN0)|(1<<TXEN0);       // Enable transmitter and receiver
	UCSR0C = (1<<UCSZ01)|(1<<UCSZ00);     // Format for 8 data bits no parity and one stop bit
}

void USART0_Transmit(unsigned char data) {
	while (!(UCSR0A & (1<<UDRE0)));       // Wait for transmit buffer to be empty
	UDR0 = data;                          // Put data into buffer and send
}

unsigned char USART0_Receive(void) {
	while (!(UCSR0A & (1<<RXC0)));        // Read the complete receive flag
	return UDR0;                          // Get data from the buffer
}

void USART0_SendString(const char* str) {
	while (*str) {                        // Loop through each character until null-terminator
		USART0_Transmit(*str++);          // Transmit each character
	}
}

///////////////////////////////////////////
// SETUP FUNCTION
///////////////////////////////////////////
void setup() {
	// Set up rotary encoder pins
	DDRB &= ~((1 << RPG_1_A) | (1 << RPG_1_B) | (1 << RPG_2_A) | (1 << RPG_2_B));  // Set all RPG pins as input
	
	// Set up power control pins
	DDRC |= (1 << POWER_PIN);             // Power pin as output
	PORTC |= (1 << POWER_PIN);            // Start with power ON
	
	DDRC &= ~(1 << BUTTON_PIN);           // Button input
	PORTC |= (1 << BUTTON_PIN);           // Enable pull-up
	
	// Initialize USART
	USART0_Init(MYUBRR);
	USART0_SendString("System Initialized\n");
	
	// Enable Pin Change Interrupts for rotary encoders on PORTB
	PCICR |= (1 << PCIE0);                // Enable PCINT0 interrupt for PORTB
	PCMSK0 |= (1 << RPG_1_A) | (1 << RPG_1_B) | (1 << RPG_2_A) | (1 << RPG_2_B); // Enable mask for RPG pins
	
	prevPINB = PINB;                      // Store initial state
	
	// Initialize last states
	rpg1_last = ((prevPINB >> RPG_1_A) & 0x01) | (((prevPINB >> RPG_1_B) & 0x01) << 1);
	rpg2_last = ((prevPINB >> RPG_2_A) & 0x01) | (((prevPINB >> RPG_2_B) & 0x01) << 1);
	
	threshold = 1;
	
	// Critical stabilization delay
	_delay_ms(500);                       // Wait for power to settle
	
	sei();                                // Enable global interrupts
}

///////////////////////////////////////////
// INTERRUPT SERVICE ROUTINE
///////////////////////////////////////////
// State transition table for clockwise/counter-clockwise rotation
ISR(PCINT0_vect) {
	static const int8_t rpg_table[4][4] = {
		{0, 1, -1, 0},
		{-1, 0, 0, 1},
		{1, 0, 0, -1},
		{0, -1, 1, 0}
	};
	
	uint8_t currPINB = PINB;
	threshold = threshold + 1;
	
	// Check RPG1 - controls left/right
	uint8_t rpg1_current = ((currPINB >> RPG_1_A) & 0x01) | (((currPINB >> RPG_1_B) & 0x01) << 1);
	
	if (rpg1_current != rpg1_last) {
		int8_t result = rpg_table[rpg1_last][rpg1_current];
		if (result == 1 && threshold >= 4) {
			USART0_SendString("l \n");
			threshold = 0;
		}
		else if (result == -1 && threshold >= 4) {
			USART0_SendString("r \n");
			threshold = 0;
		}
		rpg1_last = rpg1_current;
	}
	
	// Check RPG2 - controls up/down
	uint8_t rpg2_current = ((currPINB >> RPG_2_A) & 0x01) | (((currPINB >> RPG_2_B) & 0x01) << 1);
	
	if (rpg2_current != rpg2_last) {
		int8_t result = rpg_table[rpg2_last][rpg2_current];
		
		if (result == 1 && threshold >= 4) {
			USART0_SendString("d \n");
			threshold = 0;
		}
		else if (result == -1 && threshold >= 4) {
			USART0_SendString("u \n");
			threshold = 0;
		}
		rpg2_last = rpg2_current;
	}
	
	prevPINB = currPINB;
}

///////////////////////////////////////////
// POWER MANAGEMENT FUNCTIONS
///////////////////////////////////////////

// Handle power state toggling - safe to call from main loop
void handle_power_toggle(void) {
	// Disable interrupts during critical power operations
	cli();
	
	if (power_state) {
		// Power OFF sequence
		USART0_SendString("Powering off...\n");
		PORTC &= ~(1 << POWER_PIN);
		power_state = false;
		while(1); // Freeze until power dies
		} else {
		// Power ON sequence
		PORTC |= (1 << POWER_PIN);
		power_state = true;
		USART0_SendString("Powering on...\n");
		_delay_ms(MIN_ON_TIME_MS);  // Prevent instant off
		hold_counter = 0;
		
		// Wait for button release with interrupts re-enabled
		sei();
		while (!(PINC & (1 << BUTTON_PIN))) {
			_delay_ms(10);
		}
		return; // Return after handling power on to avoid re-enabling interrupts
	}
	
	// We only reach here if turning off and the while(1) fails
	sei();
}

// Process button press with debouncing
void process_button(void) {
	if (!(PINC & (1 << BUTTON_PIN))) {
		_delay_ms(DEBOUNCE_MS);
		
		// Recheck after debounce delay
		if (!(PINC & (1 << BUTTON_PIN))) {  // Confirmed press
			if (!button_was_pressed) {
				button_was_pressed = true;
				hold_counter = 0;
			}
			
			hold_counter += DEBOUNCE_MS;
			
			// Handle 1-second hold for power control
			if (hold_counter >= HOLD_TIME_MS) {
				handle_power_toggle();
			}
		}
		} else {
		button_was_pressed = false;
	}
}

///////////////////////////////////////////
// MAIN FUNCTION
///////////////////////////////////////////
int main(void) {
	setup();
	
	// Main loop
	while (1) {
		// Handle power button
		process_button();
		
		// Other main loop tasks could go here
		
		_delay_ms(10);  // Reduce CPU load
	}
	
	return 0;  // Never reached
}