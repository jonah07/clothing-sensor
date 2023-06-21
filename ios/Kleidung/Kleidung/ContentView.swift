//
//  ContentView.swift
//  Kleidung
//
//  Created by Jonah Kurdoglu on 16.06.23.
//

import SwiftUI
import CoreBluetooth
import Combine
import EasyStash
import Charts

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if(bluetoothManager.loading) {
                    HStack (alignment: .center, spacing: 10) {
                        ProgressView().progressViewStyle(.circular)
                        Text("Verbindung zum Sensor wird hergestellt...")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
                
                if(bluetoothManager.loading) {
                    Rectangle()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .foregroundColor(.gray.opacity(0.1))
                        .cornerRadius(15)
                } else {
                    Chart {
                        ForEach(bluetoothManager.receivedData) { item in
                            LineMark(
                                x: .value("Zeit", item.date),
                                y: .value("Temp", item.temperature)
                            )
                        }
                    }
                    .frame(height: 300)
                    .chartYScale(domain: 27...38)
                }
                Spacer()
            }
            .padding(.all, 20)
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Kleidung")
        }

    }
}

struct SensorData: Identifiable {
    let id = UUID()
    let date: Date
    let temperature: Double
    
    init(timeInterval: Int, temperature: Double) {
        self.date = Date(timeIntervalSince1970: TimeInterval(timeInterval))
        self.temperature = temperature
    }
}


class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // Create a CBCentralManager instance
    private var centralManager: CBCentralManager!
    // Create a CBPeripheral instance
    private var peripheral: CBPeripheral!
    // Create a property to store the received data
    @Published var receivedData: [SensorData] = []
    @Published var loading = false
    private var storage: Storage? = try? Storage(options: Options())
    
    override init() {
        super.init()
        // Initialize the centralManager with a delegate
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - CBCentralManagerDelegate methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Scan for peripherals that have the specified service UUID
            let scanOptions: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "7863080E-F4FB-4BA1-8821-E68CC5BC4B4F")], options: scanOptions)
        } else {
            print("Bluetooth is not available.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Stop scanning once the peripheral is found
        centralManager.stopScan()
        
        // Connect to the peripheral
        self.peripheral = peripheral
        self.peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Discover the services of the peripheral
        print("1208")
        peripheral.discoverServices([CBUUID(string: "7863080E-F4FB-4BA1-8821-E68CC5BC4B4F")])
    }
    
    // MARK: - CBPeripheralDelegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            // Discover the characteristics of the service
            print("1209")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            peripheral.setNotifyValue(true, for: characteristic)
            self.loading = false
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("HI")
        if let value = characteristic.value {
            // Convert the received data to a string
            let receivedString = String(data: value, encoding: .utf8) ?? ""
            
            // Update the published property
            DispatchQueue.main.async {
                self.receivedData.append(SensorData(timeInterval: Int(Date().timeIntervalSince1970), temperature: Double(receivedString)!))
                
                 
                 let url = URL(string: "https://clothing-backend.fourfps.workers.dev")!
                 let parameters: [String: Any] = [
                     "bucket": "temperature",
                     "value": Double(receivedString)!,
                     "time": Int(Date().timeIntervalSince1970)
                 ]

                 // Convert parameters to JSON data
                 let jsonData = try! JSONSerialization.data(withJSONObject: parameters)

                 // Create the request
                 var request = URLRequest(url: url)
                 request.httpMethod = "POST"
                 request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                 request.httpBody = jsonData

                 // Create the URLSession and send the request
                 let session = URLSession.shared
                 let task = session.dataTask(with: request) { (data, response, error) in
                     if let error = error {
                         print("Error: \(error)")
                         return
                     }
                     
                     // Handle the response
                     if let httpResponse = response as? HTTPURLResponse {
                         print("Status code: \(httpResponse.statusCode)")
                         
                         if let data = data {
                             // Handle the response data if needed
                             let responseString = String(data: data, encoding: .utf8)
                             print("Response: \(responseString ?? "")")
                         }
                     }
                 }

                 task.resume()
                 
            }
        }
    }
}
