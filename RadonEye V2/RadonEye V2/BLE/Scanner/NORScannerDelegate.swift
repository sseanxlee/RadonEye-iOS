//
//  NORScannerDelegate.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc protocol NORScannerDelegate {
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral)
}

