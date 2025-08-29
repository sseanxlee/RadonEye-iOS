//
//  BLEParse.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import Foundation

protocol BLEDataDelegate{
    func initFinish()
    func bleDataUpdate(_ cmd: UInt8)
    func bleLogDataSend()
    func bleConfigUpdate()
    func bleLogDataClear()
    
    //V1.2.0
    func bleDataSend(_ inData: [UInt8])
    func DfuFinish()
}

class BLEParse: NSObject {
    var bleDelegate: BLEDataDelegate!
    
    init(delegate: BLEDataDelegate) {
        super.init()
        print("BLEParse is initialized")
        
        bleDelegate = delegate
    }

    func recBLEDataParse(inData: [UInt8]){
        BLEData.CMD = inData[0]
        BLEData.Size = inData[1]
        
        print("BLEParse : \(BLEData.CMD) size : \(BLEData.Size)")
        
        var add = Int(0)
        var inB = [UInt8]()
        var i = Int(2)
        BLEData.recData.removeAll()
        for _ in 0..<BLEData.Size{
            BLEData.recData.append(inData[i]);  i+=1
        }
        
        switch BLEData.CMD {
            case BLECommnad.cmd_SN_QUERY://rec1
                BLEData.Config.snDate = MyUtil.arrayConvertString(startIdx: 0, endIdx: 8, inData: BLEData.recData)
                BLEData.Config.snNo = MyUtil.arrayConvertString(startIdx: 8, endIdx: 14, inData: BLEData.recData)
                
                BLEData.Config.snNoInt = UInt32(BLEData.Config.snDate)!
                
                BLEData.Config.barcode = "RD2" + BLEData.Config.snDate.dropFirst(2) + BLEData.Config.snNo.dropFirst(2)
                print("BLEParse cmd_SN_QUERY : \(BLEData.Config.snDate)-\(BLEData.Config.snNo),  int : \(BLEData.Config.snNoInt)")
                break
            
            
            case BLECommnad.cmd_MODEL_NAME_RETURN://rec2
                BLEData.Config.modelName = MyUtil.arrayConvertString(startIdx: 1, endIdx: BLEData.Size, inData: BLEData.recData)
                
                print("BLEParse cmd_MODEL_NAME_RETURN : \(BLEData.Config.modelName)")
                break
            
            
            case BLECommnad.cmd_CONFIG_QUERY://rec3
                //unit
                BLEData.Config.unit         = BLEData.recData[add]; add+=1
                if BLEData.Config.unit == 0{
                    BLEData.Config.unitStr = "pCi/ℓ"
                }
                else{
                    BLEData.Config.unitStr = "Bq/m³"
                }
                
                //Alarm
                BLEData.Config.alarmStatus  = BLEData.recData[add]; add+=1
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Config.alarmValue = MyUtil.byteConvertFloat(inArrayData: inB)
                BLEData.Config.alarmInterval = BLEData.recData[add]; add+=1
                
                print("BLEParse cmd_CONFIG_QUERY - unit : \(BLEData.Config.unit), alarmStatus : \(BLEData.Config.alarmStatus), alarmValue : \(BLEData.Config.alarmValue), alarmInterval : \(BLEData.Config.alarmInterval)")
                
                if BLEData.Init.enable == false{
                    BLEData.Flag.recConfig = true
                    bleDelegate.bleConfigUpdate()
                }
                break
            
            
            case BLECommnad.cmd_MEAS_QUERY://rec4
                //s pCi
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Meas.radonValue = MyUtil.byteConvertFloat(inArrayData: inB)
                
                //m pCi
                inB.removeAll()
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Meas.radonDValue = MyUtil.byteConvertFloat(inArrayData: inB)
                
                //l pCi
                inB.removeAll()
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Meas.radonMValue = MyUtil.byteConvertFloat(inArrayData: inB)
                
                //pulse count
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Meas.count = MyUtil.byteConvertUInt16(inArrayData: inB)
                
                //pulse count 10min
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                
                BLEData.Meas.count10min = MyUtil.byteConvertUInt16(inArrayData: inB)
                print("BLEParse cmd_MEAS_QUERY - pCi : \(BLEData.Meas.radonValue), day pCi : \(BLEData.Meas.radonDValue), month pCi : \(BLEData.Meas.radonMValue), count : \(BLEData.Meas.count), count10min : \(BLEData.Meas.count10min)")
                
                if BLEData.Init.enable == false{
                    bleDelegate.bleDataUpdate(BLEData.CMD)
                }
                break
            
            
            case BLECommnad.cmd_BLE_STATUS_QUERY://rec5
                BLEData.Status.deviceStatus = BLEData.recData[add]; add+=1
                BLEData.Status.vibStatus    = BLEData.recData[add]; add+=1
                
                //measTime
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Status.measTime = MyUtil.byteConvertUInt32(inArrayData: inB)
                
                inB.removeAll()
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Status.dcValue = MyUtil.byteConvertUInt32(inArrayData: inB)
                
                if BLEData.recData.count >= 14{
                    inB.removeAll()
                    for _ in 0..<4{
                       inB.append(BLEData.recData[add]);   add+=1
                    }
                    let peakValue = MyUtil.byteConvertFloat(inArrayData: inB)
                    BLEData.Meas.radonPeakValue = floor(peakValue * 100) / 100
                }
                
                print("BLEParse cmd_BLE_STATUS_QUERY - deviceStatus : \(BLEData.Status.deviceStatus), vibStatus : \(BLEData.Status.vibStatus), measTime : \(BLEData.Status.measTime), dcValue : \(BLEData.Status.dcValue), radonPeakValue : \(BLEData.Meas.radonPeakValue)")
                
                if BLEData.Init.enable == false{
                    /*if BLEData.Flag.newVersion == true{
                        inB.removeAll()
                        for _ in 0..<4{
                            inB.append(BLEData.recData[add]);   add+=1
                        }
                        BLEData.Meas.radonPeakValue = MyUtil.byteConvertFloat(inArrayData: inB)
                          print("BLEParse cmd_BLE_STATUS_QUERY - radonPeakValue : \(BLEData.Meas.radonPeakValue)")
                    }
                    bleDelegate.bleDataUpdate(BLEData.CMD)*/
                }
                break
            
            
            case BLECommnad.cmd_EEPROM_LOG_INFO_QUERY://rec6
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Log.dataNo = MyUtil.byteConvertUInt16(inArrayData: inB)
                BLEData.Log.recCheckSum = BLEData.recData[add]; add+=1
                
                print(Date(), "BLEParse cmd_EEPROM_LOG_INFO_QUERY - dataNo : \(BLEData.Log.dataNo), recByteSize : \(BLEData.Log.recByteSize), recPacketSize : \(BLEData.Log.recPacketSize), recCheckSum : \(BLEData.Log.recCheckSum)")
                
                if BLEData.Init.enable{
                    BLEData.Init.enable = false
                    bleDelegate.initFinish()
                    //bleDelegate.bleDataUpdate(BLECommnad.cmd_MEAS_QUERY)
                }
                else{
                    if BLEData.Log.dataNo == 0{
                        if BLEData.Flag.dataClear{
                            BLEData.Flag.dataClear = false
                            bleDelegate.bleLogDataClear()
                        }
                        else{
                            bleDelegate.bleDataUpdate(BLECommnad.cmd_EEPROM_LOG_DATA_SEND)
                        }
                    }
                    else{
                        //초기화 아닐때만 계산..
                        BLEData.Log.recByteSize = BLEData.Log.dataNo * 2
                        BLEData.Log.recPacketSize = BLEData.Log.recByteSize

                        let calData = Int(BLEData.Log.recByteSize % 20)

                        if calData != 0 {
                            let plustData = Int(20 - calData)
                            BLEData.Log.recPacketSize += UInt16(plustData)
                        }

                        BLEData.Log.rawData.removeAll()
                        bleDelegate.bleLogDataSend()
                    }
                }
                break
            
            
            case BLECommnad.cmd_MOD_CONIFG_QUERY:
                BLEData.Module.type = BLEData.recData[add]; add+=1
                
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Module.snDate = MyUtil.arrayConvertString(endIdx: 4, inData: inB)
                
                inB.removeAll()
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Module.snNo = MyUtil.arrayConvertString(endIdx: 4, inData: inB)
                
                inB.removeAll()
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Module.factor = MyUtil.byteConvertFloat(inArrayData: inB)
                print("BLEParse cmd_MOD_CONIFG_QUERY - type : \(BLEData.Module.type), snDate : \(BLEData.Module.snDate), snNo : \(BLEData.Module.snNo), factor : \(BLEData.Module.factor)")
                break
            
            
            case BLECommnad.cmd_BLE_VERSION_QUERY:
                for _ in 0..<6{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                
                BLEData.Config.fwStatus = 0
                
                if(BLEData.Size>=7){
                    BLEData.Config.fwStatus = BLEData.recData[add];
                }
                
                BLEData.Config.version = MyUtil.arrayConvertString(endIdx: 6, inData: inB)
                BLEData.Flag.recVersion = true
                
                
                var versionStr = String("")
                versionStr = BLEData.Config.version.replacingOccurrences(of: "V", with: "")
                versionStr = versionStr.replacingOccurrences(of: ".", with: "")
                
                BLEData.Config.versionInt = UInt16(versionStr)!
                
                //펌웨어 업그레이드 유무
                if BLEData.Config.versionInt <= MyStruct.fwUpdateMax &&
                    BLEData.Config.versionInt >= MyStruct.fwUpdateMin{
                    BLEData.Flag.fwUpdate = true
                }
                
                //V1.1.0
                if BLEData.Config.versionInt == 900{
                    BLEData.Flag.fwUpdate = true
                }
                
                if(BLEData.Config.snNoInt>=20180621 && BLEData.Config.snNoInt<=20180627){
                    if(BLEData.Config.fwStatus != 10){
                        BLEData.Flag.fwUpdate = true
                    }
                }
                
                print("BLEParse cmd_BLE_VERSION_QUERY - \(BLEData.Config.version),  status : \(BLEData.Config.fwStatus)")
                break
            
            
            case BLECommnad.cmd_OLED_QUERY:
                BLEData.Config.oledValue = BLEData.recData[add]; add+=1
                print("BLEParse cmd_OLED_QUERY - \(BLEData.Config.oledValue)")
                break
            
            
            case BLECommnad.cmd_SN_TYPE_QUERY:
                for _ in 0..<3{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Config.snType = MyUtil.arrayConvertString(endIdx: 3, inData: inB)
                BLEData.Config.barcode = BLEData.Config.snType + BLEData.Config.snDate.dropFirst(2) + BLEData.Config.snNo.dropFirst(2)
                print("BLEParse cmd_SN_TYPE_QUERY - \(BLEData.Config.snType), barcode : \(BLEData.Config.barcode)")
                break
            
            
            case BLECommnad.cmd_DISPLAY_CAL_FACTOR_QUERY:
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Config.dFactor = MyUtil.byteConvertFloat(inArrayData: inB)
                print("BLEParse cmd_DISPLAY_CAL_FACTOR_QUERY - \(BLEData.Config.dFactor)")
                break
            
            default:
                break
        }
    }
    
    func recBLEDataParseV2(inData: [UInt8]){
        BLEData.CMD = inData[0]
        BLEData.Size = inData[1]
        
        print("BLEParse : \(BLEData.CMD) size : \(BLEData.Size), V3: \(MyStruct.v3Mode)")
        
        var add = Int(0)
        var inB = [UInt8]()
        var i = Int(2)
        BLEData.recData.removeAll()
        for _ in 0..<BLEData.Size{
            BLEData.recData.append(inData[i]);  i+=1
        }
        
        switch BLEData.CMD {
            case BLECommnad.cmd_BLEV2_QUERY_ALL://rec1
                if MyStruct.v3Mode{
                    BLEData.Config.barcode = MyUtil.arrayConvertString(startIdx: 0, endIdx: 12, inData: BLEData.recData)
                    add = 12
                }
                else{
                    BLEData.Config.snDate = MyUtil.arrayConvertString(startIdx: 0, endIdx: 6, inData: BLEData.recData)
                    BLEData.Config.snType = MyUtil.arrayConvertString(startIdx: 6, endIdx: 9, inData: BLEData.recData)
                    BLEData.Config.snNo = MyUtil.arrayConvertString(startIdx: 9, endIdx: 13, inData: BLEData.recData)
                    
                    BLEData.Config.barcode = BLEData.Config.snType + BLEData.Config.snDate + BLEData.Config.snNo
                    add = 13
                }
                
                //ModelName
                let modelNameLen = BLEData.recData[add]
                add+=1
                BLEData.Config.modelName = MyUtil.arrayConvertString(startIdx: 13, endIdx: 13 + modelNameLen, inData: BLEData.recData)
                add += Int(modelNameLen)
                
                //Versoon
                for _ in 0..<6{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Config.fwStatus = 0
                BLEData.Config.version = MyUtil.arrayConvertString(endIdx: 6, inData: inB)
                print("BLEParse cmd_BLEV2_QUERY_ALL - sn : \(BLEData.Config.barcode), version : \(BLEData.Config.version), modelName : \(BLEData.Config.modelName)")
                
                //Unit
                BLEData.Config.unit = BLEData.recData[add]; add+=1
                if BLEData.Config.unit == 0{
                    BLEData.Config.unitStr = "pCi/ℓ"
                }
                else{
                    BLEData.Config.unitStr = "Bq/m³"
                }
                
                //Alarm
                BLEData.Config.alarmStatus  = BLEData.recData[add]; add+=1
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Config.alarmValue = MyUtil.byteConvertUInt16(inArrayData: inB)
                BLEData.Config.alarmInterval = BLEData.recData[add]; add+=1
                print("BLEParse cmd_BLEV2_QUERY_ALL - unit : \(BLEData.Config.unit), alarmStatus : \(BLEData.Config.alarmStatus), alarmValue : \(BLEData.Config.alarmValue), alarmInterval : \(BLEData.Config.alarmInterval)")
                
                //s pCi
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Meas.radonValue = MyUtil.byteConvertUInt16(inArrayData: inB)
                
                //m pCi
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Meas.radonDValue = MyUtil.byteConvertUInt16(inArrayData: inB)
                
                //l pCi
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Meas.radonMValue = MyUtil.byteConvertUInt16(inArrayData: inB)
                
                //pulse count
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Meas.count = MyUtil.byteConvertUInt16(inArrayData: inB)
                
                //pulse count 10min
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                
                BLEData.Meas.count10min = MyUtil.byteConvertUInt16(inArrayData: inB)
                print("BLEParse cmd_BLEV2_QUERY_ALL - pCi : \(BLEData.Meas.radonValue), day pCi : \(BLEData.Meas.radonDValue), month pCi : \(BLEData.Meas.radonMValue), count : \(BLEData.Meas.count), count10min : \(BLEData.Meas.count10min)")
                
                
                //measTime
                inB.removeAll()
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Status.measTime = MyUtil.byteConvertUInt32(inArrayData: inB)
                
                inB.removeAll()
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Status.dcValue = MyUtil.byteConvertUInt32(inArrayData: inB)
                
                inB.removeAll()
                for _ in 0..<2{
                   inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Meas.radonPeakValue = MyUtil.byteConvertUInt16(inArrayData: inB)
                
                BLEData.Status.deviceStatus = BLEData.recData[add]; add+=1
                BLEData.Status.vibStatus    = BLEData.recData[add]; add+=1
                
                //1Hour
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Meas.radonHValue = MyUtil.byteConvertUInt16(inArrayData: inB)
                
                print("BLEParse cmd_BLEV2_QUERY_ALL - measTime : \(BLEData.Status.measTime), dcValue : \(BLEData.Status.dcValue), deviceStatus : \(BLEData.Status.deviceStatus), vibStatus : \(BLEData.Status.vibStatus), radonHValue : \(BLEData.Meas.radonHValue)")
                
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Log.dataNo = MyUtil.byteConvertUInt16(inArrayData: inB)
                BLEData.Log.recCheckSum = BLEData.recData[add]; add+=1
                
                BLEData.Log.recPacketSize = BLEData.Log.dataNo * 2
                
                print(Date(), "BLEParse cmd_BLEV2_QUERY_ALL - dataNo : \(BLEData.Log.dataNo), recByteSize : \(BLEData.Log.recByteSize), recPacketSize : \(BLEData.Log.recPacketSize), recCheckSum : \(BLEData.Log.recCheckSum)")
                
                inB.removeAll()
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Config.modduleFactor = MyUtil.byteConvertFloat(inArrayData: inB)
                
                inB.removeAll()
                for _ in 0..<4{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Config.dFactor = MyUtil.byteConvertFloat(inArrayData: inB)
                
                print(Date(), "BLEParse cmd_BLEV2_QUERY_ALL - modduleFactor : \(BLEData.Config.modduleFactor), dFactor : \(BLEData.Config.dFactor)")
            
                if BLEData.Init.enable{
                    BLEData.Init.enable = false
                    bleDelegate.initFinish()
                }
                else{
                    if BLEData.Flag.dataClear{
                        BLEData.Flag.dataClear = false
                        if BLEData.Log.dataNo == 0{
                            bleDelegate.bleLogDataClear()//LOG
                        }
                    }
                    else {
                        bleDelegate.bleDataUpdate(BLEData.CMD)
                    }
                }
                
                break
            
            
            case BLECommnad.cmd_CONFIG_QUERY:
                //unit
                BLEData.Config.unit         = BLEData.recData[add]; add+=1
                if BLEData.Config.unit == 0{
                    BLEData.Config.unitStr = "pCi/ℓ"
                }
                else{
                    BLEData.Config.unitStr = "Bq/m³"
                }
                
                //Alarm
                BLEData.Config.alarmStatus  = BLEData.recData[add]; add+=1
                inB.removeAll()
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Config.alarmValue = MyUtil.byteConvertUInt16(inArrayData: inB)
                BLEData.Config.alarmInterval = BLEData.recData[add]; add+=1
                
                print("BLEParse cmd_CONFIG_QUERY - unit : \(BLEData.Config.unit), alarmStatus : \(BLEData.Config.alarmStatus), alarmValue : \(BLEData.Config.alarmValue), alarmInterval : \(BLEData.Config.alarmInterval)")
                
                if BLEData.Init.enable == false{
                    BLEData.Flag.recConfig = true
                    bleDelegate.bleConfigUpdate()
                }
                break
    
            
            case BLECommnad.cmd_EEPROM_LOG_INFO_QUERY://rec6
                for _ in 0..<2{
                    inB.append(BLEData.recData[add]);   add+=1
                }
                BLEData.Log.dataNo = MyUtil.byteConvertUInt16(inArrayData: inB)
                BLEData.Log.recCheckSum = BLEData.recData[add]; add+=1
                
                print(Date(), "BLEParse cmd_EEPROM_LOG_INFO_QUERY - dataNo : \(BLEData.Log.dataNo), recByteSize : \(BLEData.Log.recByteSize), recPacketSize : \(BLEData.Log.recPacketSize), recCheckSum : \(BLEData.Log.recCheckSum)")
                
                if BLEData.Init.enable{
                    BLEData.Init.enable = false
                    bleDelegate.initFinish()
                    //bleDelegate.bleDataUpdate(BLECommnad.cmd_MEAS_QUERY)
                }
                else{
                    if BLEData.Log.dataNo == 0{
                        if BLEData.Flag.dataClear{
                            BLEData.Flag.dataClear = false
                            bleDelegate.bleLogDataClear()
                        }
                        else{
                            bleDelegate.bleDataUpdate(BLECommnad.cmd_EEPROM_LOG_DATA_SEND)
                        }
                    }
                    else{
                        //초기화 아닐때만 계산..
                        BLEData.Log.recByteSize = BLEData.Log.dataNo * 2
                        BLEData.Log.recPacketSize = BLEData.Log.recByteSize

                        let calData = Int(BLEData.Log.recByteSize % 20)

                        if calData != 0 {
                            let plustData = Int(20 - calData)
                            BLEData.Log.recPacketSize += UInt16(plustData)
                        }

                        BLEData.Log.rawData.removeAll()
                        bleDelegate.bleLogDataSend()
                    }
                }
                break
            
            case BLECommnad.cmd_DFU_READY...BLECommnad.cmd_DFU_OK:
                if BLEData.OTA.sendAddress >= BLEData.OTA.sendData.count{
                    print(Date(), "cmd_DFU_READY return")
                    return
                }
            
                var sData = [UInt8]()
                sData.append(BLECommnad.cmd_DFU_SEND)
                
                var rawData = [UInt8]()
                for _ in 0..<500{
                    rawData.append(BLEData.OTA.sendData[BLEData.OTA.sendAddress])
                    BLEData.OTA.sendAddress += 1
            
                    if BLEData.OTA.sendAddress >= BLEData.OTA.sendData.count{
                        break
                    }
                }

                //BLEData.OTA.percent = (Float)BLEData.OTA.sendData / (Float)BLEData.OTA.sendAddress
                print(Date(), "cmd_DFU_READY, Data count: \(BLEData.OTA.sendData.count), sendAddress : \(BLEData.OTA.sendAddress), rawData count: \(rawData.count)")
                
                //Data Size
                sData.append(UInt8(rawData.count % 256))
                sData.append(UInt8(rawData.count / 256))
                
                for i in 0..<rawData.count{
                    sData.append(rawData[i])
                }
                
                bleDelegate.bleDataSend(sData)
                break
                
            case BLECommnad.cmd_DFU_DONE:
                print(Date(), "cmd_DFU_DONE")
                bleDelegate.DfuFinish()
                break
            
            default:
                break
        }
    }
    
    /*func recBLELogData(inData: [UInt8]){
        BLEData.Log.rawData.append(inData, length: inData.count)
        BLEData.Log.recByteSize += 20
        print("recBLELogData - raw data length : \(BLEData.Log.rawData.length),  recByte : \(BLEData.Log.recByteSize)")
    }*/

}
