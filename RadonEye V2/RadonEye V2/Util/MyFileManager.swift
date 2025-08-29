//
//  FileManager.swift
//  RadonEye Pro
//
//  Created by 정석환 on 2019. 2. 28..
//  Copyright © 2019년 ftlab. All rights reserved.
//

import UIKit

class MyFileManager {
    //V1.2.0 - refUnit 추가
    static func logFileSaveProcess(_ inSN:String, _ inFileName:String, _ inValue:[Float], _ refUnit:Int, _ unit:UInt8, _ inAlarmValue:Float) -> Bool{
        var sText = String("")
        sText = "FTLab Radon Data\r\n"
        sText += "Model Name:\tRadon Eye\r\n"
         
        //S/N
        sText += "S/N:\t" + inSN + "\r\n"
        
        var alarmValue = inAlarmValue
        //Unit
        if unit == 0{
            sText += "Unit:\tpCi/l\r\n"
        }
        else{
            sText += "Unit:\tBq/m3\r\n"
            alarmValue = inAlarmValue * 37
        }
        
        //Time step
        sText += String(format: "Time step:\t1hour\tAlarm Value:\t%.2f", alarmValue) + "\r\n"
        //Data no
        //sText += String(format: "Data No:\t%d", BLEData.Log.dataNo) + "\r\n"
        sText += String(format: "Data No:\t%d", inValue.count) + "\r\n"//V1.2.0
    
        //radon data
        //for i in 0..<BLEData.Log.dataNo{
        for i in 0..<inValue.count{//V1.2.0
            //V1.2.0
            if unit == 0{
                if BLEData.Flag.V3_New{
                    var mValue = MyUtil.radonValueReturn(MyStruct.v2Mode, inValue[Int(i)], unit)
                    mValue = MyUtil.newFwMinValue(inValue: mValue)
                    sText += String(format: "%d)\t%.2f", (i + 1), mValue) + "\r\n"
                }
                else{
                    sText += String(format: "%d)\t%.2f", (i + 1), MyUtil.radonValueReturn(MyStruct.v2Mode, inValue[Int(i)], unit)) + "\r\n"
                }
            }
            else{
                sText += String(format: "%d)\t%.0f", (i + 1), MyUtil.radonValueReturn(MyStruct.v2Mode, inValue[Int(i)], unit)) + "\r\n"
            }
        }
        
        let fileManager = FileManager.default
        let snDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileurl = snDirURL.appendingPathComponent("/" + inSN)
        let destString = fileurl.relativePath
        
        let destPath = snDirURL.appendingPathComponent(inSN, isDirectory: true)
        if (fileManager.fileExists(atPath: destString) == false){
            try! fileManager.createDirectory(at: destPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        ////let fileurl = paths[0]
        let filePath = destString.appending("/" + inFileName)
        
        do {
            // Write contents to file
            try sText.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
            return true
        }
        catch let error as NSError {
            print("An error took place: \(error)")
            return false
        }
    }
}
