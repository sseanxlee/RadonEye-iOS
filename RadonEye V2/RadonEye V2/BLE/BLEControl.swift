//
//  BLEControl.swift
//  RadonEye Pro
//
//  Created by 정석환 on 2019. 3. 6..
//  Copyright © 2019년 ftlab. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol NORBluetoothManagerDelegate {
    func didConnectPeripheral(deviceName aName : String?)
    func didDisconnectPeripheral()
    func peripheralReady()
    func peripheralNotSupported()
}

protocol MainPageDelegate{
    func dataReturn()
}

protocol MainViewDelegate{
    func mainInitFinish()
    
    func mainMenuTableInfoQuery()
    
    func uiUpdate(type: UInt8)
    func wifiScanInfoResult()
    func wifiScanResult()
    
    func inspectionTableInfoParse(_ rawData: [UInt8])
    func cotinuousModeWiFiDisable()
}

protocol MonitorTabDelegate{
    func dInitFinish()
    func didDisconnectPeripheral()
    func dTabRadonUiUpdate(_ cmd: UInt8)
    func recLogDataStart()
    func rawLogDataReturn(_ inData:[UInt8])
    func DfuFinishProcess()//V1.2.0
}

protocol SettingDelegate {
    func configDataReturn()
    func dataClear()
    
    //V1.2.0
    func rawLogDataReturnForSettingView(_ inData:[UInt8])
    func recLogDataStartSetting()
}

class BLEControl: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate, BLEDataDelegate{
    func bleLogDataSend() {
        bleSendData(cmd: BLECommnad.cmd_EEPROM_LOG_DATA_SEND)
    }
    
    func bleDataUpdate(_ cmd: UInt8) {
        mMonitorTabDelegate?.dTabRadonUiUpdate(cmd)
    }
    
    func bleConfigUpdate() {
        mSettingDelegate?.configDataReturn()
    }
    
    func bleLogDataClear() {
        mSettingDelegate?.dataClear()
    }
    
    let tag                         = String("BLEControl - ")

    fileprivate let deviceUUID  = CBUUID.init(string: "00001523-1212-EFDE-1523-785FEABCD123")
    fileprivate let controlUUID = CBUUID.init(string: "00001524-1212-EFDE-1523-785FEABCD123")
    fileprivate let measUUID    = CBUUID.init(string: "00001525-1212-EFDE-1523-785FEABCD123")
    fileprivate let logUUID    = CBUUID.init(string: "00001526-1212-efde-1523-785feabcd123")
    
    fileprivate let deviceUUIDV2  = CBUUID.init(string: "00001523-0000-1000-8000-00805f9b34fb")
    fileprivate let controlUUIDV2 = CBUUID.init(string: "00001524-0000-1000-8000-00805f9b34fb")
    fileprivate let measUUIDV2    = CBUUID.init(string: "00001525-0000-1000-8000-00805f9b34fb")
    fileprivate let logUUIDV2    = CBUUID.init(string: "00001526-0000-1000-8000-00805f9b34fb")
    
    //MARK: - Delegate Properties
    fileprivate let MTU = 20
    var delegate : NORBluetoothManagerDelegate?
    
    var centralManager              : CBCentralManager
    var bluetoothPeripheral         : CBPeripheral?
    
    fileprivate var controlCharacteristic        : CBCharacteristic?
    fileprivate var measCharacteristic        : CBCharacteristic?
    fileprivate var logCharacteristic        : CBCharacteristic?
    
    fileprivate var connected = false
    var  bleParse                   : BLEParse!
    var  mMainViewDelegate           : MainViewDelegate?
    var  mMonitorTabDelegate          : MonitorTabDelegate?
    var  mSettingDelegate        : SettingDelegate?
    var  mMode                      = UInt8(0)
    
    init(withCBCentralManager aCBCentralManager: CBCentralManager, withPeripheral aPeripheral: CBPeripheral) {
        centralManager = aCBCentralManager
        bluetoothPeripheral = aPeripheral
        super.init()
        bluetoothPeripheral?.delegate = self
        centralManager.delegate = self
        bleParse = BLEParse(delegate: self)
    }
    
    func delegateMainInit(delegate: MainViewDelegate) {
        mMainViewDelegate = delegate
    }
    
    func delegateMonitorTabInit(delegate: MonitorTabDelegate) {
        mMonitorTabDelegate = delegate
    }
    
    func delegateSetting(delegate: SettingDelegate) {
        mSettingDelegate = delegate
    }
   
    //V1.2.0
    func delegateSettingInit() {
        mSettingDelegate = nil
    }
   
    func setPeripheral() {
        print("connecting to setPeripheral")
        BLEData.Init.enable = true
        centralManager.connect(bluetoothPeripheral!, options: nil)
    }
    
    func setPeripheralForAddDevice() {
        print("connecting to setPeripheral")
        centralManager.connect(bluetoothPeripheral!, options: nil)
    }
    
    func setPeripheralForDelete() {
        print("connecting to setPeripheral, setPeripheralForDelete")
        centralManager.connect(bluetoothPeripheral!, options: nil)
    }
    
    /**
     * Connects to the given peripheral.
     *
     * - parameter aPeripheral: target peripheral to connect to
     */
    func connectPeripheral(peripheral aPeripheral : CBPeripheral) {
        bluetoothPeripheral = aPeripheral
        
        // we assign the bluetoothPeripheral property after we establish a connection, in the callback
        if let name = aPeripheral.name {
            MyUtil.printProcess(inMsg: tag + "Connecting to: \(name)...")
        } else {
            MyUtil.printProcess(inMsg: tag + "Connecting to device...")
        }
        MyUtil.printProcess(inMsg: tag + "centralManager.connect(peripheral, options:nil)")
        //centralManager.connect(aPeripheral, options: nil)
    }
    
    func disConnect() {
        if bluetoothPeripheral != nil{
            centralManager.cancelPeripheralConnection(bluetoothPeripheral!)
            bluetoothPeripheral = nil
        }
    }
    
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral) {
        print("centralManagerDidSelectPeripheral 1")//1번째 함수
        
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        //centralManager = aManager
        //centralManager.delegate = self
        
        // The sensor has been selected, connect to it
        bluetoothPeripheral = aPeripheral
        bluetoothPeripheral?.delegate = self
        
        //let options = [CBConnectPeripheralOptionNotifyOnNotificationKey : NSNumber(value: false as Bool)]
        //centralManager.connect(aPeripheral, options: options)
    }
    
    
    /**
     * Disconnects or cancels pending connection.
     * The delegate's didDisconnectPeripheral() method will be called when device got disconnected.
     */
    func cancelPeripheralConnection() {
        guard bluetoothPeripheral != nil else {
            MyUtil.printProcess(inMsg: tag + "Peripheral not set")
            return
        }
        if connected {
            MyUtil.printProcess(inMsg: tag + "Disconnecting...")
        } else {
            MyUtil.printProcess(inMsg: tag + "Cancelling connection...")
        }
        
        MyUtil.printProcess(inMsg: tag + "centralManager.cancelPeripheralConnection(peripheral)")
        //centralManager.cancelPeripheralConnection(bluetoothPeripheral!)
        
        // In case the previous connection attempt failed before establishing a connection
        if !connected {
            bluetoothPeripheral = nil
            delegate?.didDisconnectPeripheral()
        }
    }
    
    
    /**
     * Returns true if the peripheral device is connected, false otherwise
     * - returns: true if device is connected
     */
    func isConnected() -> Bool {
        MyUtil.printProcess(inMsg: tag + "isConnected : \(connected)")
        return connected
    }
    
    //MARK: - CBCentralManagerDelegat
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var state : String
        switch(central.state){
        case .poweredOn:
            state = "Powered ON"
            break
        case .poweredOff:
            state = "Powered OFF"
            break
        case .resetting:
            state = "Resetting"
            break
        case .unauthorized:
            state = "Unautthorized"
            break
        case .unsupported:
            state = "Unsupported"
            break
        case .unknown:
            state = "Unknown"
            break
        @unknown default:
            state = "Unknown"
            break
        }
        
        MyUtil.printProcess(inMsg: tag + "[Callback] Central Manager did update state to: \(state)")
    }
    
    /**
     * Sends the given text to the UART RX characteristic using the given write type.
     * This method does not split the text into parts. If the given write type is withResponse
     * and text is longer than 20-bytes the long write will be used.
     *
     * - parameters:
     *     - aText: text to be sent to the peripheral using Nordic UART Service
     *     - aType: write type to be used
     */
    func send(text aText : String, withType aType : CBCharacteristicWriteType) {
        guard self.controlCharacteristic != nil else {
            MyUtil.printProcess(inMsg: tag + "UART RX Characteristic not found")
            return
        }
        
        let typeAsString = aType == .withoutResponse ? ".withoutResponse" : ".withResponse"
        let data = aText.data(using: String.Encoding.utf8)!
        
        //do some logging
        
        MyUtil.printProcess(inMsg: tag + "Writing to characteristic: \(controlCharacteristic!.uuid.uuidString)")
        MyUtil.printProcess(inMsg: tag + "peripheral.writeValue(0x\(data), for: \(measCharacteristic!.uuid.uuidString), type: \(typeAsString))")
        
        self.bluetoothPeripheral!.writeValue(data, for: self.controlCharacteristic!, type: aType)
        // The transmitted data is not available after the method returns. We have to log the text here.
        // The callback peripheral:didWriteValueForCharacteristic:error: is called only when the Write Request type was used,
        // but even if, the data is not available there.
        
        MyUtil.printProcess(inMsg: tag + "\"\(aText)\" sent")
    }
    

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MyUtil.printProcess(inMsg: tag + "[Callback] Central Manager did connect peripheral")
        
        if let name = peripheral.name {
            MyUtil.printProcess(inMsg: tag + "Connected to: \(name)")
        } else {
            MyUtil.printProcess(inMsg: tag + "Connected to device")
        }
    
        connected = true
        bluetoothPeripheral = peripheral
        bluetoothPeripheral!.delegate = self
        delegate?.didConnectPeripheral(deviceName: peripheral.name)
        MyUtil.printProcess(inMsg: tag + "Discovering services...")
        //peripheral.discoverServices([deviceUUID])
        //peripheral.discoverServices([deviceUUID, deviceUUIDV2])
        peripheral.discoverServices([deviceUUID, deviceUUIDV2])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard error == nil else {
            MyUtil.printProcess(inMsg: tag + "[Callback] Central Manager did disconnect peripheral")//비정상 연결 종료
            connected = false
            mMonitorTabDelegate?.didDisconnectPeripheral()
            bluetoothPeripheral = nil
            return
        }
        MyUtil.printProcess(inMsg: tag + "[Callback] Central Manager did disconnect peripheral successfully")//정상적으로 종료
        
        connected = false
        //mMonitorTabDelegate?.didDisconnectPeripheral()
        bluetoothPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard error == nil else {
            MyUtil.printProcess(inMsg: tag + "[Callback] Central Manager did fail to connect to peripheral")
            connected = false
            mMonitorTabDelegate?.didDisconnectPeripheral()
            
            bluetoothPeripheral!.delegate = nil
            bluetoothPeripheral = nil
            return
        }
        MyUtil.printProcess(inMsg: tag + "[Callback] Central Manager did fail to connect to peripheral without errors")
        
        connected = false
       // mMonitorTabDelegate?.didDisconnectPeripheral()
  
        bluetoothPeripheral!.delegate = nil
        bluetoothPeripheral = nil
    }
    
    //MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            MyUtil.printProcess(inMsg: tag + "Service discovery failed")
            return
        }
        
        MyUtil.printProcess(inMsg: tag + "Services discovered")
        
        for aService: CBService in peripheral.services! {
            if aService.uuid.isEqual(deviceUUID) {
                MyStruct.v2Mode = false
                
                MyUtil.printProcess(inMsg: tag + "Discovering characteristics...")
                MyUtil.printProcess(inMsg: tag + "peripheral.discoverCharacteristics(nil, for: \(aService.uuid.uuidString))")
    
                bluetoothPeripheral!.discoverCharacteristics([controlUUID], for: aService)
                bluetoothPeripheral!.discoverCharacteristics([measUUID], for: aService)
                bluetoothPeripheral!.discoverCharacteristics([logUUID], for: aService)
                return
            }
            else if aService.uuid.isEqual(deviceUUIDV2) {
                MyStruct.v2Mode = true
                
                MyUtil.printProcess(inMsg: tag + "Discovering characteristics... V2")
                MyUtil.printProcess(inMsg: tag + "peripheral.discoverCharacteristics(nil, for: \(aService.uuid.uuidString))")
    
                bluetoothPeripheral!.discoverCharacteristics([controlUUIDV2], for: aService)
                bluetoothPeripheral!.discoverCharacteristics([measUUIDV2], for: aService)
                bluetoothPeripheral!.discoverCharacteristics([logUUIDV2], for: aService)
                return
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            MyUtil.printProcess(inMsg: tag + "Characteristics discovery failed")
            return
        }
        MyUtil.printProcess(inMsg: tag + "Characteristics discovered")
        
        if service.uuid.isEqual(deviceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid.isEqual(controlUUID) {
                    MyUtil.printProcess(inMsg: tag + "controlUUID Characteristic found")
                    controlCharacteristic = aCharacteristic
                }
                else if aCharacteristic.uuid.isEqual(measUUID) {
                    MyUtil.printProcess(inMsg: tag + "measUUID Characteristic found")
                    measCharacteristic = aCharacteristic
                }
                else if aCharacteristic.uuid.isEqual(logUUID) {
                    MyUtil.printProcess(inMsg: tag + "logUUID Characteristic found")
                    logCharacteristic = aCharacteristic
                }
            }
        }
        else if service.uuid.isEqual(deviceUUIDV2) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid.isEqual(controlUUIDV2) {
                    MyUtil.printProcess(inMsg: tag + "controlUUID V2 Characteristic found")
                    controlCharacteristic = aCharacteristic
                }
                else if aCharacteristic.uuid.isEqual(measUUIDV2) {
                    MyUtil.printProcess(inMsg: tag + "measUUID V2 Characteristic found")
                    measCharacteristic = aCharacteristic
                }
                else if aCharacteristic.uuid.isEqual(logUUIDV2 ) {
                    MyUtil.printProcess(inMsg: tag + "logUUID V2 Characteristic found")
                    logCharacteristic = aCharacteristic
                }
            }
        }
        
        if (controlCharacteristic != nil
            && measCharacteristic != nil && (logCharacteristic != nil)) {
            MyUtil.printProcess(inMsg: tag + "controlCharacteristic \(controlCharacteristic!.uuid.uuidString)")
            MyUtil.printProcess(inMsg: tag + "measCharacteristic \(measCharacteristic!.uuid.uuidString)")
            MyUtil.printProcess(inMsg: tag + "logCharacteristic \(logCharacteristic!.uuid.uuidString)")
            
            bluetoothPeripheral!.setNotifyValue(true, for: controlCharacteristic!)
            bluetoothPeripheral!.setNotifyValue(true, for: measCharacteristic!)
            bluetoothPeripheral!.setNotifyValue(true, for: logCharacteristic!)
            
            //Characteristic 3개 모두 정상적으로 사용 가능
            BLEData.dataInit()
            
            let sendByte = MyUtil.nowDateTimeConvertArray()
            bleSendData(cmd: BLECommnad.cmd_BLE_RD200_Date_Time_Set, size: sendByte.count, data: sendByte)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if MyStruct.v2Mode{
                    self.bleSendData(cmd: BLECommnad.cmd_BLEV2_QUERY_ALL)
                }
                else{
                    self.bleSendData(cmd: BLECommnad.cmd_BASIC_INFO_QUERY)
                }
            }
        } else {
            MyUtil.printProcess(inMsg: tag + "UART service does not have required characteristics. Try to turn Bluetooth Off and On again to clear cache.")
            
            //delegate?.peripheralNotSupported()
            //cancelPeripheralConnection()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            MyUtil.printProcess(inMsg: tag + "Writing value to characteristic has failed")
            return
        }
        MyUtil.printProcess(inMsg: tag + "Data written to characteristic: \(characteristic.uuid.uuidString)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            MyUtil.printProcess(inMsg: tag + "Writing value to descriptor has failed")
            return
        }
        MyUtil.printProcess(inMsg: tag + "Data written to descriptor: \(descriptor.uuid.uuidString)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            MyUtil.printProcess(inMsg: tag + "Updating characteristic has failed")
            return
        }
        
        // try to print a friendly string of received bytes if they can be parsed as UTF8
        guard characteristic.value != nil else {
            MyUtil.printProcess(inMsg: tag + "Notification received from: \(characteristic.uuid.uuidString), with empty value")
            MyUtil.printProcess(inMsg: tag + "Empty packet received")
            return
        }
        
        //data부터 복사
        if characteristic.uuid == self.logUUID {
            //로그 중간에 문제 생겨 어플이 다시 실행되는 경우
            if BLEData.Log.recPacketSize >= 20000{
                //self.LogErrorPercent += 1
                if BLEData.Flag.logError == false{
                    //self.progressView("log_down_error_check")
                    BLEData.Flag.logError = true
                    //self.timerForLogError = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerProcessForLogError), userInfo: nil, repeats: true)
                }
                return
            }
                
            //Log data 변수에 담기
            for i in 0..<20{
                BLEData.Log.rawData.append(characteristic.value![i]);
            }
            
            //퍼센트 계산
            //BLEData.Log.recPercent = (Float(BLEData.Log.rawData.count) / Float(BLEData.Log.recPacketSize)) * 100.0
        }
        else if characteristic.uuid == self.logUUIDV2 {
            for i in 4..<characteristic.value!.count{
                //print("BLEControl - log raw data : \(characteristic.value![i])")
                BLEData.Log.rawData.append(characteristic.value![i]);
            }
        }

        DispatchQueue.main.async(execute: {
            if MyStruct.v2Mode{
                if characteristic.uuid == self.measUUIDV2 {
                    var recData = [UInt8]()
                    
                    for i in 0..<characteristic.value!.count{
                        recData.append(characteristic.value![i]);
                    }
                    
                    self.bleParse.recBLEDataParseV2(inData: recData)
                }
                else if characteristic.uuid == self.logUUIDV2 {
                    if BLEData.Log.recPercent == 0{
                        MyUtil.printProcess(inMsg: self.tag + "first BLEData.Log.rawData.count")
                        //self.mMonitorTabDelegate?.recLogDataStart()
                        
                        if self.mSettingDelegate != nil{
                            self.mSettingDelegate?.recLogDataStartSetting()
                        }
                        else{
                            self.mMonitorTabDelegate?.recLogDataStart()
                        }
                    }
                    
                    //퍼센트 계산
                    BLEData.Log.recPercent = (Float(BLEData.Log.rawData.count) / Float(BLEData.Log.recPacketSize)) * 100.0

                    if BLEData.Log.rawData.count >= BLEData.Log.recPacketSize{
                        self.mMonitorTabDelegate?.rawLogDataReturn(BLEData.Log.rawData)
                        
                        //V1.2.0
                        if self.mSettingDelegate != nil{
                            self.mSettingDelegate?.rawLogDataReturnForSettingView(BLEData.Log.rawData)
                        }
                    }
                }
            }
            else{
                if characteristic.uuid == self.measUUID {
                    var recData = [UInt8]()
                    
                    for i in 0..<20{
                        recData.append(characteristic.value![i]);
                    }
                    
                    self.bleParse.recBLEDataParse(inData: recData)
                }
                else if characteristic.uuid == self.logUUID {
                    if BLEData.Log.rawData.count == 20{
                        MyUtil.printProcess(inMsg: self.tag + "first BLEData.Log.rawData.count")
                        //self.mMonitorTabDelegate?.recLogDataStart()
                        
                        if self.mSettingDelegate != nil{
                            self.mSettingDelegate?.recLogDataStartSetting()
                        }
                        else{
                            self.mMonitorTabDelegate?.recLogDataStart()
                        }
                    }
                    
                    //퍼센트 계산
                    BLEData.Log.recPercent = (Float(BLEData.Log.rawData.count) / Float(BLEData.Log.recPacketSize)) * 100.0
                    //MyUtil.printProcess(inMsg: self.tag + "Log percent: \(BLEData.Log.recPercent)")
                    
                    if BLEData.Log.rawData.count >= BLEData.Log.recPacketSize{
                        self.mMonitorTabDelegate?.rawLogDataReturn(BLEData.Log.rawData)
                        
                        //V1.2.0
                        if self.mSettingDelegate != nil{
                            self.mSettingDelegate?.rawLogDataReturnForSettingView(BLEData.Log.rawData)
                        }
                    }
                }
            }
        })
    }
    
    func initFinish() {
        mMonitorTabDelegate?.dInitFinish()
        //mMonitorRadonDelegate?.tabRadonUiUpdate()
    }
   
    //MARK: - BLE Communication
    func bleSendData(cmd: UInt8){
        /*if flagBLEConn == false{
            indicatorView.removeFromSuperview()
            
            self.aleretView(inTitle: "detial_ble_connection_fail_title", inMsg: "detial_ble_connection_fail", intButtonStr: "close_msg")
            return
        }*/

        print(Date(), " bleSendData : \(String(format:"0x%02X", cmd))")
        var bytes : [UInt8] = [cmd]
        
        if !MyStruct.v2Mode{
            bytes.append(0x11)
            for _ in 0..<18{
                bytes.append(0);
            }
        }

        let data = Data(bytes: &bytes, count: bytes.count)
        
        if MyStruct.v2Mode{
            bluetoothPeripheral?.writeValue(data, for: controlCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
        else{
            bluetoothPeripheral?.writeValue(data, for: controlCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func bleSendData(cmd: UInt8, size: Int, data: [UInt8]){
        print(Date(), " bleSendData data : \(String(format:"0x%02X", cmd))")
        var bytes = [UInt8]()
        bytes.append(cmd)
        bytes.append(UInt8(0x11))
        
        var i = (Int)(0)
        for _ in 0..<size{
            bytes.append(data[i]);  i+=1
        }
        
        //let data = Data(bytes:bytes)
        let data = Data(bytes: &bytes, count: bytes.count)
        if MyStruct.v2Mode{
            bluetoothPeripheral?.writeValue(data, for: controlCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
        else{
            bluetoothPeripheral?.writeValue(data, for: controlCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func bleSendDataForSnSet(cmd: UInt8, size: Int, data: [UInt8]){
        var bytes = [UInt8]()
        bytes.append(cmd)
        bytes.append(UInt8(0x11))
        
        var i = (Int)(0)
        for _ in 0..<size{
            bytes.append(data[i]);  i+=1
        }
        
        //let data = Data(bytes:bytes)
        let data = Data(bytes: &bytes, count: bytes.count)
        if MyStruct.v2Mode{
            bluetoothPeripheral?.writeValue(data, for: controlCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
        else{
            bluetoothPeripheral?.writeValue(data, for: controlCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func bleSendData(data: [UInt8]){
        var bytes = [UInt8]()
        
        var i = (Int)(0)
        for _ in 0..<data.count{
            bytes.append(data[i]);  i+=1
        }
        
        //let data = Data(bytes:bytes)
        let data = Data(bytes: &bytes, count: bytes.count)
        if MyStruct.v2Mode{
            bluetoothPeripheral?.writeValue(data, for: controlCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
        else{
            bluetoothPeripheral?.writeValue(data, for: controlCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    //1.2.0
    func bleDataSend(_ inData: [UInt8]) {
        //let data = Data(bytes:bytes)
        let data = Data(bytes: inData, count: inData.count)
        bluetoothPeripheral?.writeValue(data, for: controlCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    func DfuFinish(){
        mMonitorTabDelegate?.DfuFinishProcess()
    }
    
    
    func deviceTimeCheck(_ inByte: [UInt8]) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let nowDt = Date()
        
        let dtStr = String.init(format: "20%d-%d-%d %d:%d:%d", inByte[0], inByte[1], inByte[2], inByte[3], inByte[4], inByte[5])
        
        let dtDateType = dateFormatter.date(from: dtStr)
        
        let interval = nowDt.timeIntervalSince(dtDateType!)
        let calSec = Int(interval)
        
        print("deviceTimeCheck : \(dtStr), nowDt: \(nowDt), calSec: \(calSec)")
        
        if calSec > 120{//2현재시간보다 2분차이나면 시간 세팅
            return false
        }
        else if calSec < -120{
            return false
        }
        else{
            return true
        }
    }
}
