#include <Arduino.h>

const int SEND_LED_PIN = 3;         
const int RECEIVE_LED_PIN = 4;
const int BUTTON_PIN = 2;

// initial state
int buttonState = HIGH;

void setup() {
  Serial.begin(9600);          
  pinMode(SEND_LED_PIN, OUTPUT);
  pinMode(RECEIVE_LED_PIN, OUTPUT);  
  pinMode(BUTTON_PIN, INPUT);
  digitalWrite(SEND_LED_PIN, LOW);
  digitalWrite(RECEIVE_LED_PIN, LOW);  
}

void loop() {
  buttonState = digitalRead(BUTTON_PIN);
  
  if (buttonState == LOW) {  
    digitalWrite(SEND_LED_PIN, HIGH);
    Serial.println("arduino tx");  
    delay(1000);
    digitalWrite(SEND_LED_PIN, LOW);
  } else {
    digitalWrite(SEND_LED_PIN, LOW);
  }
  
  // Check for incoming message
  if (Serial.available() > 0) {
    String incomingMessage = Serial.readStringUntil('\n');
    incomingMessage.trim();  // Remove any whitespace
    
    if (incomingMessage == "ESP32 TX") {
      digitalWrite(RECEIVE_LED_PIN, HIGH);
      delay(1000); 
      digitalWrite(RECEIVE_LED_PIN, LOW);
    }
  }
}