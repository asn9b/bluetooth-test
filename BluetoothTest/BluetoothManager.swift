//
//  BluetoothManager.swift
//  BluetoothTest
//
//  Created by Brian Dutton on 8/15/16.
//  Copyright © 2016 Asinine Games. All rights reserved.
//

import Foundation
import CoreBluetooth


class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager?
    var peripheral: CBPeripheral?
    let characteristicUUID = CBUUID(string: "CDEACB81-5235-4C07-8846-93A37EE6B86D")
    var currentCharacteristic: CBCharacteristic! = nil
    var reportData: [UInt8] = []
    var statusText: String = "Scanning..."
    var heartRateText: String = "0 BPM"
    var oxygenText: String = "0%"
    var piText: String = "0.0%"
    var nc = NSNotificationCenter.defaultCenter()
    
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if (central.state == CBCentralManagerState.PoweredOn) {
            let services = [CBUUID(string: "CDEACB80-5235-4C07-8846-93A37EE6B86D")]
            self.centralManager?.scanForPeripheralsWithServices(services, options: nil)
            statusText = "Connect Device"
            updateStatus()
        } else {
            statusText = "Bluetooth not on"
            updateStatus()
        }
    }
    
    
    func startManager() {
        updateReadings()
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
        print("Central Manager started")
    }
    
    
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        self.peripheral = peripheral
        self.centralManager!.connectPeripheral(self.peripheral!, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
        statusText = "Connecting..."
        updateStatus()   
    }
    
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("Connected to \(peripheral)")
        statusText = "Connected"
        updateStatus()
        self.stopScan()
    }
    
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Failed to connect", error)
        statusText = "Failed to connect"
        updateStatus()
    }
    
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        if self.peripheral != nil {
            self.peripheral!.delegate = nil
            self.peripheral = nil
        }
        print("Disconnected", error)
        statusText = "Device Disconnected"
        updateStatus()
    }
    
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        statusText = "Getting Services"
        for service in peripheral.services! {
            let thisService = service as CBService
            peripheral.discoverCharacteristics(nil, forService: thisService)
            print(service.UUID)
        }
    }
    
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        statusText = "Getting Characteristics"
        updateStatus()
        
        for characteristic in service.characteristics! {
            print( characteristic )
            if( service.UUID == CBUUID.init( string:"CDEACB80-5235-4C07-8846-93A37EE6B86D")) {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
                peripheral.readValueForCharacteristic(characteristic as CBCharacteristic)
            }
            print(characteristic.UUID)
        }
        
        if let error = error {
            print("Characteristic Error", error)
        }
    }
    
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        statusText = "Getting Reading"
        if let error = error {
            print("Update Error", error)
        }
        if characteristic.UUID == characteristicUUID {
            let data = characteristic.value
            var reportData = [UInt8](count:data!.length, repeatedValue:0)
            print(data)
            data!.getBytes(&reportData, length: data!.length)
            print(reportData)
            if reportData.count == 4 && reportData[0] == 129 {
                if reportData[1] != 255 {
                    heartRateText = String("\(reportData[1]) BPM")
                }
                if reportData[2] != 127 {
                    oxygenText = String("\(reportData[2])%")
                }
                
                let pindex: Double = Double(reportData[3]) / 10
                piText = String("\(pindex)%")
                updateReadings()
            }
        }
    }

    
    func stopScan() {
        if centralManager != nil {
            self.centralManager!.stopScan()
        }
    }
    
    
    func cancelPeripheralConnection() {
        if centralManager != nil {
            centralManager!.cancelPeripheralConnection(peripheral!)
        }
    }
    
    
    func updateStatus() {
        nc.postNotificationName(statusKey, object:nil, userInfo:["status" : String(statusText)] )
    }
    
    
    func updateReadings() {
        nc.postNotificationName(readingsKey, object:nil, userInfo:["hr" : String(heartRateText), "oxygen" : String(oxygenText), "pi" : String(piText) ] )
    }

    
}