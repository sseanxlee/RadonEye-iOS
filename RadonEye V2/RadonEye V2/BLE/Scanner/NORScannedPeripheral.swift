//
//  NORScannedPeripheral.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit
import CoreBluetooth

@objc class NORScannedPeripheral: NSObject {
    
    var peripheral  : CBPeripheral
    var RSSI        : Int32
    var isConnected : Bool
    var realName    : String
    var V3          : Bool//V1.3.0
    
    init(withPeripheral aPeripheral: CBPeripheral, andRSSI anRSSI:Int32 = 0, andIsConnected aConnectionStatus: Bool, advertisementData : String, inV3: Bool) {
        peripheral = aPeripheral
        RSSI = anRSSI
        isConnected = aConnectionStatus
        realName = advertisementData
        V3 = inV3
    }
    
    func name()->String{
        let peripheralName = peripheral.name
        if peripheral.name == nil {
            return "No name"
        }else{
            return peripheralName!
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let otherPeripheral = object as? NORScannedPeripheral {
            return peripheral == otherPeripheral.peripheral
        }
        return false
    }
}


