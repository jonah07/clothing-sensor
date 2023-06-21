#include <ArduinoBLE.h>
#include <HS300x.h>

BLEService sensorService("7863080E-F4FB-4BA1-8821-E68CC5BC4B4F");  

BLEStringCharacteristic temperatureChar("07565F0D-E201-46A8-A719-69550282265A", BLERead | BLENotify, 25);

void setup() {
  Serial.begin(9600);   
  while (!Serial);

  pinMode(LED_BUILTIN, OUTPUT);

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
  BLEDevice central = BLE.central();  

  if (central) {
    Serial.print("Connected to central MAC: ");
    Serial.println(central.address());
    digitalWrite(LED_BUILTIN, HIGH);

    while (central.connected()){
      Serial.println("Temperature ");
      Serial.println(String(HS300x.readTemperature()));
      temperatureChar.writeValue(String(HS300x.readTemperature()));
      delay(1000);
    } 
    
    digitalWrite(LED_BUILTIN, LOW);
    Serial.print("Disconnected from central MAC: ");
    Serial.println(central.address());
  }
}
