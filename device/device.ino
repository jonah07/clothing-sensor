#include <ArduinoBLE.h>
#include <HS300x.h>

static const char* greeting = "Hello World!";

BLEService sensorService("7863080E-F4FB-4BA1-8821-E68CC5BC4B4F");  // User defined service

BLEStringCharacteristic temperatureChar("07565F0D-E201-46A8-A719-69550282265A", BLERead | BLENotify, 25); // remote clients will only be able to read this

void setup() {
  Serial.begin(9600);    // initialize serial communication
  while (!Serial);

  pinMode(LED_BUILTIN, OUTPUT); // initialize the built-in LED pin

  HS300x.begin();
  if (!BLE.begin()) {   // initialize BLE
    Serial.println("starting BLE failed!");
    while (1);
  }

  BLE.setLocalName("Kleidungssensor");  // Set name for connection
  sensorService.addCharacteristic(temperatureChar); // Add characteristic to service
  BLE.addService(sensorService); // Add service
  BLE.setAdvertisedService(sensorService); // Advertise service

  BLE.advertise();  // Start advertising

  Serial.print("Peripheral device MAC: ");
  Serial.println(BLE.address());
  Serial.println("Waiting for connections...");
}

void loop() {
  BLEDevice central = BLE.central();  // Wait for a BLE central to connect

  // if a central is connected to the peripheral:
  if (central) {
    Serial.print("Connected to central MAC: ");
    // print the central's BT address:
    Serial.println(central.address());
    // turn on the LED to indicate the connection:
    digitalWrite(LED_BUILTIN, HIGH);

    while (central.connected()){
      Serial.println("Temperature ");
      Serial.println(String(HS300x.readTemperature()));
      temperatureChar.writeValue(String(HS300x.readTemperature()));
      delay(1000);
    } // keep looping while connected

    // when the central disconnects, turn off the LED:
    digitalWrite(LED_BUILTIN, LOW);
    Serial.print("Disconnected from central MAC: ");
    Serial.println(central.address());
  }
}
