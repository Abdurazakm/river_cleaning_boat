// Motor pins
const int ENA = 5; // PWM speed control motor A
const int IN1 = 6; // Motor A direction
const int IN2 = 7;

const int ENB = 10; // PWM speed control motor B
const int IN3 = 8;  // Motor B direction
const int IN4 = 9;

const int conveyorPin = 4; // Conveyor motor control

int motorSpeed = 200;       // Default PWM speed (max 255)
const int MAX_SPEED = 230;  // Safe max speed
bool conveyorState = false; // Conveyor state

void setup() {
  Serial.begin(9600);

  // Motor pins as outputs
  pinMode(ENA, OUTPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);

  pinMode(ENB, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  // Conveyor
  pinMode(conveyorPin, OUTPUT);
  digitalWrite(conveyorPin, LOW);

  // Stop motors initially
  stopMotors();
  Serial.println("Boat ready! Commands: F,B,L,R,S,C,D,E,SPEED<number>");
}

void loop() {
  if (Serial.available()) {
    String input = Serial.readStringUntil('\n');
    input.trim(); // remove whitespace
    input.toUpperCase(); // make case-insensitive

    if (input.startsWith("SPEED")) {
      int speed = input.substring(5).toInt();
      if (speed > MAX_SPEED) speed = MAX_SPEED;
      if (speed < 0) speed = 0;
      motorSpeed = speed;
      analogWrite(ENA, motorSpeed);
      analogWrite(ENB, motorSpeed);
      Serial.print("Motor speed set to: "); Serial.println(motorSpeed);
    }
    else if (input == "F") { moveForward(); Serial.println("Moving Forward"); }
    else if (input == "B") { moveBackward(); Serial.println("Moving Backward"); }
    else if (input == "L") { turnLeft(); Serial.println("Turning Left"); }
    else if (input == "R") { turnRight(); Serial.println("Turning Right"); }
    else if (input == "S") { stopMotors(); Serial.println("Motors Stopped"); }
    else if (input == "E") { stopMotors(); conveyorState = false; digitalWrite(conveyorPin, LOW); Serial.println("EMERGENCY STOP!"); }
    else if (input == "C") { conveyorState = true; digitalWrite(conveyorPin, HIGH); Serial.println("Conveyor ON"); }
    else if (input == "D") { conveyorState = false; digitalWrite(conveyorPin, LOW); Serial.println("Conveyor OFF"); }
    else {
      Serial.print("Unknown command: "); Serial.println(input);
    }
  }
}

// ================== Motor Functions ==================
void moveForward() {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  analogWrite(ENA, motorSpeed);
  analogWrite(ENB, motorSpeed);
}

void moveBackward() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
  analogWrite(ENA, motorSpeed);
  analogWrite(ENB, motorSpeed);
}

void turnLeft() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
  analogWrite(ENA, motorSpeed);
  analogWrite(ENB, motorSpeed);
}

void turnRight() {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
  analogWrite(ENA, motorSpeed);
  analogWrite(ENB, motorSpeed);
}

void stopMotors() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
  analogWrite(ENA, 0);
  analogWrite(ENB, 0);
}
