//
//  BLEData.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import Foundation

class BLEData: NSObject{
    static func dataInit() {
        Meas.radonValue         = 0
        Meas.radonDValue        = 0
        Meas.radonMValue        = 0
        Meas.radonPeakValue     = 0
        Meas.count              = 0
        Meas.count10min         = 0
        
        Config.version          = ""
        Config.versionInt       = 0
        Config.newVersion       = false
        
        Flag.recVersion         = false
        //Flag.newVersion         = false
        Flag.recConfig          = false
        Flag.logError           = false
        Flag.chartDraw          = false
        Flag.fwUpdate           = false
    }
    
    
    static var CMD      = UInt8(0)
    static var Size     = UInt8(0)
    static var recData  = [UInt8]()
    
    struct Init {
        static var status       = Int(0)
        static var enable      = Bool(false)
    }
    
    struct Meas {
        static var radonValue       = Float(0)
        static var radonDValue      = Float(0)
        static var radonMValue      = Float(0)
        static var radonPeakValue   = Float(0)
        static var radonHValue   = Float(0)
        
        static var count            = UInt16(0)
        static var count10min       = UInt16(0)
    }
    
    struct Status {
        static var deviceStatus     = UInt8(0)
        static var vibStatus        = UInt8(0)
        static var measTime         = UInt32(0)
        static var dcValue          = UInt32(0)
    }
    
    struct Config {
        static var unit             = UInt8(0)
        static var unitStr          = String("")
        static var alarmStatus      = UInt8(0)
        static var alarmValue       = Float(0)
        static var alarmInterval    = UInt8(0)
        
        static var unitSet             = UInt8(0)
        static var alarmStatusSet     = UInt8(0)
        static var alarmValueSet       = Float(0)
        static var alarmIntervalSet    = UInt8(0)
        
        static var snNoInt          = UInt32(0)
        static var snType           = String("")
        static var snNo             = String("")
        static var snDate           = String("")
        static var barcode          = String("")
        static var modelName        = String("")
        
        static var version          = String("")
        static var versionInt       = UInt16(0)
        static var newVersion       = Bool(false)
        static var fwStatus         = UInt8(0)
        
        static var oledValue        = UInt8(0)
        static var modduleFactor          = Float(0)
        static var dFactor          = Float(0)
        
        static var settingItem      = UInt8(0)//유닛 세팅(0)인지 알람세팅(1)인지 알기위해..
    }
    
    struct Log {
        static var dataNo           = UInt16(0)
        static var radonValue       = [Float]()
        static var recByteSize      = UInt16(0)
        static var recPacketSize    = UInt16(20000)
        static var recCheckSum      = UInt8(0)
        static var recPercent       = Float(0)
        static var rawData          = [UInt8]()
    }
    
    struct Module {
        static var type             = UInt8(0)
        static var snNo             = String("")
        static var snDate           = String("")
        static var factor           = Float(0)
    }
    
    struct Flag {
        static var recVersion       = Bool(false)
        //static var newVersion       = Bool(false)//V1.2.2이상.. SN Type추가 된 버전
        static var recConfig        = Bool(false)
        static var logError         = Bool(false)//로그 다운로드 중에 어플이 종료되거나 연결이 끊어졌을때..
        static var chartDraw        = Bool(false)//차트를 한번이라도 표시 유무. 유닛 변경시 그래프 변경을 위해
        static var fwUpdate         = Bool(false)//V1.2.0 ~ V1.2.2 펌웨어 업데이트 가능한 제품..
        static var dataClear       = Bool(false)
        
        //V1.2.0
        static var onlyDataReset       = Bool(false) 
        
        //V1.5.0
        static var V3_New = Bool(false)
    }
    
    //V1.2.0
    struct OTA {
        static var sendData = [UInt8]()
        static var sendSize = Int(0)
        static var sendAddress = Int(0)
        static var totalPacket = Int(0)
        static var percent = Int(0)
    }
}
