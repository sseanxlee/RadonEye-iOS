//
//  MyUtil.swift
//  RadonEye Pro
//
//  Created by 정석환 on 2019. 2. 25..
//  Copyright © 2019년 ftlab. All rights reserved.
//

import Foundation
import UIKit
import CommonCrypto

class MyUtil: NSObject{
    //V1.5.0 - 20240723
    static func newFwMinValue(inValue: Float) -> Float{
        var ret = inValue

        if inValue < 0.2 && inValue > 0{
           ret = 0.2
        }

        return ret
    }
    
    //V1.2.0
    static func refUnit(inMove: Bool) -> Int{
        if inMove{//뉴모델에서는 통신이 베크렐
            return 1
        }
        else{//기존 라돈아이는 피코큐리
            return 0
        }
    }
    
    
    
    static func intConverByteArray(inValue: Int) -> [UInt8]{
        var fValue = inValue
        let data = NSMutableData(bytes: &fValue, length: 4)
        
        var myArray = [UInt8](repeating: 0, count: 4)
        data.getBytes(&myArray, length: 4)
        
        return myArray
    }
    
    static func uint32ConverByteArray(inValue: UInt32) -> [UInt8]{
        var fValue = inValue
        let data = NSMutableData(bytes: &fValue, length: 4)
        
        var myArray = [UInt8](repeating: 0, count: 4)
        data.getBytes(&myArray, length: 4)
        
        return myArray
    }
    
    static func uint16ConverByteArray(inValue: UInt16) -> [UInt8]{
        var fValue = inValue
        let data = NSMutableData(bytes: &fValue, length: 2)
        
        var myArray = [UInt8](repeating: 0, count: 2)
        data.getBytes(&myArray, length: 2)
        
        return myArray
    }
    
    static func floatConverByteArray(inValue: Float) -> [UInt8]{
        var fValue = inValue
        let data = NSMutableData(bytes: &fValue, length: 4)
        
        var myArray = [UInt8](repeating: 0, count: 4)
        data.getBytes(&myArray, length: 4)
        
        return myArray
    }
    
    static func byteConvertFloat(inArrayData: [UInt8]) -> Float {
        var ret = Float(0.0)
        //memccpy(&ret, inArrayData, 4, 4)
        memcpy(&ret, inArrayData, 4)
        return ret
    }
    
    static func byteConvertUInt16(inArrayData: [UInt8]) -> Float {
        var ret = UInt16(0)
        memcpy(&ret, inArrayData, 2)
        
        return Float(ret)
    }
    
    static func byteConvertUInt16(inArrayData: [UInt8]) -> UInt16 {
        var ret = UInt16(0)
        //memccpy(&ret, inArrayData, 2, 2)
        memcpy(&ret, inArrayData, 2)
        return ret
    }
    
    static func byteConvertUInt32(inArrayData: [UInt8]) -> UInt32 {
        var ret = UInt32(0)
        //memccpy(&ret, inArrayData, 4, 4)
        
        memcpy(&ret, inArrayData, 4)
        return ret
    }
    
    static func byteConvertInt(inArrayData: [UInt8]) -> Int {
        var ret = Int(0)
        //memccpy(&ret, inArrayData, 4, 4)
        memcpy(&ret, inArrayData,  4)
        return ret
    }
    
    static func arrayConvertString(endIdx:UInt8, inData: [UInt8]) -> String {
        var arrayData = [UInt8]()
        
        var i = Int(0)
        for _ in 0..<endIdx{
            arrayData.append(inData[i]);   i+=1
        }
        
        let ret = String(bytes: arrayData, encoding: String.Encoding.utf8)
        return ret!
    }
    
    static func arrayConvertString(startIdx:UInt8, endIdx:UInt8, inData: [UInt8]) -> String {
        var arrayData = [UInt8]()
        
        var i = Int(startIdx)
        for _ in startIdx..<endIdx{
            arrayData.append(inData[i]);   i+=1
        }
        
        let ret = String(bytes: arrayData, encoding: String.Encoding.utf8)
        return ret!
    }
    
    static func arrayConvertString(startIdx:Int, endIdx:Int, inData: [UInt8]) -> String {
        var arrayData = [UInt8]()
        
        var i = Int(startIdx)
        for _ in startIdx..<endIdx{
            arrayData.append(inData[i]);   i+=1
        }
        
        let ret = String(bytes: arrayData, encoding: String.Encoding.utf8)
        return ret!
    }
    
    static func arrayConvertString1(startIdx:Int, endIdx:Int, inData: [UInt8]) -> String {
        var arrayData = [UInt8]()
        
        var i = Int(startIdx)
        for _ in startIdx..<endIdx{
            arrayData.append(inData[i]);   i+=1
        }
        
        let ret = String(bytes: arrayData, encoding: String.Encoding.utf8)
        return ret!
    }
    
    static func arrayConvertString2(startIdx:Int, endIdx:Int, inData: [UInt8]) -> String {
        var arrayData = [UInt8]()
        
        var i = Int(startIdx)
        for _ in startIdx..<endIdx{
            arrayData.append(inData[i]);   i+=1
        }
        
        let ret = String(bytes: arrayData, encoding: String.Encoding.utf8)
        return ret!
    }
    
    static func arrayConvertString3(startIdx:Int, endIdx:Int, inData: [UInt8]) -> String {
        var arrayData = [UInt8]()
        
        var i = Int(startIdx)
        for _ in startIdx..<endIdx{
            arrayData.append(inData[i]);   i+=1
        }
        
        let ret = String(bytes: arrayData, encoding: String.Encoding.utf8)
        return ret!
    }
    
    static func arrayConvertString4(startIdx:Int, endIdx:Int, inData: [UInt8]) -> String {
        var arrayData = [UInt8]()
        
        var i = Int(startIdx)
        for _ in startIdx..<endIdx{
            arrayData.append(inData[i]);   i+=1
        }
        
        let ret = String(bytes: arrayData, encoding: String.Encoding.utf8)
        return ret!
    }
    
    static func nowDateTimeConvertArray() -> [UInt8]{
        var ret = [UInt8]()
        
        let nowDT = NSDate()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yy"
        var dateValue = (UInt8)(formatter.string(from: nowDT as Date))
        ret.append(dateValue!)
        
        formatter.dateFormat = "MM"
        dateValue = (UInt8)(formatter.string(from: nowDT as Date))
        ret.append(dateValue!)
        
        formatter.dateFormat = "dd"
        dateValue = (UInt8)(formatter.string(from: nowDT as Date))
        ret.append(dateValue!)
        
        formatter.dateFormat = "HH"
        dateValue = (UInt8)(formatter.string(from: nowDT as Date))
        //ret.append(dateValue!)
        ret.append(1)
        
        formatter.dateFormat = "mm"
        dateValue = (UInt8)(formatter.string(from: nowDT as Date))
        ret.append(dateValue!)
        
        formatter.dateFormat = "ss"
        dateValue = (UInt8)(formatter.string(from: nowDT as Date))
        ret.append(dateValue!)
        
        return ret
    }
    
    static func timeZoneStringReturn() -> String{
        let nowDT = NSDate()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "ZZZ"
        let dateValue = (formatter.string(from: nowDT as Date))
        return dateValue
    }
    
    static func valueReturnString(_ inUnit:UInt8, _ value: Float) -> String{
        if inUnit == 1{
            return String(format: "%.0f ", value)
        }
        else if inUnit == 0{
            if value < 10.0{
                return String(format: "%.2f ", value)
            }
            else if value < 100.0{
                return String(format: "%.1f ", value)
            }
            else{
                return String(format: "%.0f ", value)
            }
        }
        else{
             return "--"
        }
    }
    
    static func valueReturnStringCloud(_ inUnit:UInt8, _ value: Float) -> String{
        if inUnit == 1{
            return String(format: "%.0f Bq/m³", value)
        }
        else{
            if value <= 10.0{
                return String(format: "%.2f pCi/ℓ", value)
            }
            else if value <= 100.0{
                return String(format: "%.1f pCi/ℓ", value)
            }
            else{
                return String(format: "%.0f pCi/ℓ", value)
            }
        }
    }
    
    static func measTimeConvertString(_ value: UInt32) -> String{
        var ret = String("")
        var hh  = UInt8(0)
        var mm  = UInt8(0)
        var dd  = UInt32(0)
        var h = String("")
        var m = String("")
        var d = String("")
        
        dd = value / 1440;
        
        //하루가 안지났으면
        if dd == 0{
            hh = UInt8(value / 60)
            mm = UInt8(value % 60)
        }
        else{//하루 이상이면
            d = String(format : "%d", dd) + "day "
            ret = d
            
            let day = (UInt32)(1440 * dd)
            let temp_value = value - day
            
            hh = UInt8(temp_value / 60)
            mm = UInt8(temp_value % 60)
        }
        
        if hh > 9{
            h = String(format : "%d", hh)
        }
        else{
            h = String(format : "0%d", hh)
        }
        ret += h + ":";
        
        if mm > 9{
            m = String(format : "%d", mm)
        }
        else{
            m = String(format : "0%d", mm)
        }
        ret += m;
        
        return ret
    }
    
    static func measTimeConvertStringArray(_ value: UInt32) -> [String]{
        var hh  = UInt8(0)
        var mm  = UInt8(0)
        var dd  = UInt32(0)
        var h = String("-")
        var m = String("-")
        var d = String("")
        
        dd = value / 1440;
        
        if value == 0{
            return["", "-", "-"]
        }
        
        //하루가 안지났으면
        if dd == 0{
            hh = UInt8(value / 60)
            mm = UInt8(value % 60)
        }
        else{//하루 이상이면
            d = String(format : "%d", dd)
           
            let day = (UInt32)(1440 * dd)
            let temp_value = value - day
            
            hh = UInt8(temp_value / 60)
            mm = UInt8(temp_value % 60)
        }
        
        if hh > 9{
            h = String(format : "%d", hh)
        }
        else{
            h = String(format : "0%d", hh)
        }
       
        if mm > 9{
            m = String(format : "%d", mm)
        }
        else{
            m = String(format : "0%d", mm)
        }
       
        return [d, h, m]
    }
    
    static func logDataFileName() -> String{
        var ret = String("")
        
        let nowDT = NSDate()
        let formatter = DateFormatter()
        
        //formatter.dateFormat = "ddMMMyyy HHmmss"
        formatter.dateFormat = "yyyyMMdd HHmmss"
        let dateValue = formatter.string(from: nowDT as Date)
        
        ret = BLEData.Config.barcode + "_" + dateValue
        
        return ret
    }
    
   /* static func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        //Scanner(string: cString).scanHexInt32(&rgbValue)
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }*/
    
    static func uicolorFromHex(rgbValue:UInt32)->UIColor{
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:1.0)
    }
    
    static func uicolorFromHexArea(rgbValue:UInt32)->UIColor{
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:0.7)
    }
    
    static func tempHumi_u16_to_Temp(inVal:UInt16)->Float{
        var ret = Float(0)
        var val1 = UInt16(0)
        var val2 = UInt16(0)
        
        val1 = (inVal >> 8)
        val2 = ((inVal >> 7) & 0x01)
        
        if val2 == 1 {
            ret = Float(val1) + 0.5
        }
        else {
            ret = Float(val1)
        }
        return ret;
    }
    
    static func tempHumi_u16_to_Humi(inVal:UInt16) -> UInt16{
        var ret = UInt16(0)
        ret = UInt16(inVal % 256)
        
        if ret <= 0 {
            ret=ret+256
        }
        
        ret = ret % 128
        
        return ret
    }
    
    static func deviceTimeCheck(inTime: [UInt8]) -> Bool{
        var ret = Bool(false)
        
        let str = "20" + String(inTime[0]) + "-" + String(inTime[1]) + "-" + String(inTime[2]) + "T" + String(inTime[3]) + ":" + String(inTime[4]) + ":" + String(inTime[5])
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
        let date = dateFormatter.date(from: str)
        let nowDT = Date()
        
        let interval = nowDT.timeIntervalSince(date!)
        
        let calDate = interval
        
        if calDate > 120 || calDate < -120{//2분 차이가 나면 세팅
            ret = false
        }
        else{
            ret = true
        }
        
        return ret
    }
    
    
    static func binaryToData(inTime: UInt32) -> String{
        var ret = [UInt32]()
        let DaysToMonth: [UInt32] = [0,31,59,90,120,151,181,212,243,273,304,334,365]
        
        var year = UInt32(0)
        var month = UInt32(0)
        var day = UInt32(0)
        var hour = UInt32(0)
        var min = UInt32(0)
        var sec = UInt32(0)
        
        var whole_minutes = UInt32(0)
        var whole_hours = UInt32(0)
        var whole_days = UInt32(0)
        var whole_days_since_1968 = UInt32(0)
        var leap_year_periods = UInt32(0)
        var days_since_current_lyear = UInt32(0)
        var whole_years = UInt32(0)
        var days_since_first_of_year = UInt32(0)
        var days_to_month = UInt32(0)
        
        //계산
        whole_minutes = UInt32(inTime) / 60
        sec = (inTime - (60 * whole_minutes)) // leftover seconds
        
        whole_hours = whole_minutes / 60
        min = (whole_minutes - (60 * whole_hours)) // leftover minutes
        
        whole_days = whole_hours / 24
        hour = (whole_hours - (24 * whole_days)) // leftover hours
        
        whole_days_since_1968 = whole_days + 365 + 366
        leap_year_periods = whole_days_since_1968 / ((4 * 365) + 1)
        
        days_since_current_lyear = whole_days_since_1968 % ((4 * 365) + 1)
        
        if (days_since_current_lyear >= (31 + 29))
        {
            leap_year_periods += 1
        }
        
        whole_years = (whole_days_since_1968 - leap_year_periods) / 365
        days_since_first_of_year = whole_days_since_1968 - (whole_years * 365) - leap_year_periods
        
        if (days_since_current_lyear <= 365) && (days_since_current_lyear >= 60)
        {
            days_since_first_of_year += 1
        }
        
        year = (whole_years + 68)
        
        month = 13
        days_to_month = 366
        
        while (days_since_first_of_year < days_to_month)
        {
            month -= 1
            let monthIdx = Int(month - 1)
            days_to_month = UInt32(DaysToMonth[monthIdx])
            
            if ((month > 2) && ((year % 4) == 0))
            {
                days_to_month += 1
            }
        }
        day = (days_since_first_of_year - days_to_month + 1)
        
        ret.append(year+1900)
        ret.append(month)
        ret.append(day)
        ret.append(hour)
        ret.append(min)
        ret.append(sec)
        
        var strM = String(ret[1])
        if ret[1] < 10{
            strM = String(String.init(format: "0%d", ret[1]))
        }
        
        var strD = String(ret[2])
        if ret[2] < 10{
            strD = String(String.init(format: "0%d", ret[2]))
        }
        
        var strH = String(ret[3])
        if ret[3] < 10{
            strH = String(String.init(format: "0%d", ret[3]))
        }
        
        var strMM = String(ret[4])
        if ret[4] < 10{
            strMM = String(String.init(format: "0%d", ret[4]))
        }
        
        var strS = String(ret[5])
        if ret[5] < 10{
            strS = String(String.init(format: "0%d", ret[5]))
        }
        
        let retData = String(ret[0]) + "-" + strM + "-" + strD + "T" + strH + ":" + strMM + ":" + strS
        
        return retData
    }
    
    static func binaryConvertDateType(type:Int, addYear:Int, inTime: UInt32) -> String{
        var ret = [UInt32]()
        let DaysToMonth: [UInt32] = [0,31,59,90,120,151,181,212,243,273,304,334,365]
        
        var year = UInt32(0)
        var month = UInt32(0)
        var day = UInt32(0)
        var hour = UInt32(0)
        var min = UInt32(0)
        var sec = UInt32(0)
        
        var whole_minutes = UInt32(0)
        var whole_hours = UInt32(0)
        var whole_days = UInt32(0)
        var whole_days_since_1968 = UInt32(0)
        var leap_year_periods = UInt32(0)
        var days_since_current_lyear = UInt32(0)
        var whole_years = UInt32(0)
        var days_since_first_of_year = UInt32(0)
        var days_to_month = UInt32(0)
        
        //계산
        whole_minutes = UInt32(inTime) / 60
        sec = (inTime - (60 * whole_minutes)) // leftover seconds
        
        whole_hours = whole_minutes / 60
        min = (whole_minutes - (60 * whole_hours)) // leftover minutes
        
        whole_days = whole_hours / 24
        hour = (whole_hours - (24 * whole_days)) // leftover hours
        
        whole_days_since_1968 = whole_days + 365 + 366
        leap_year_periods = whole_days_since_1968 / ((4 * 365) + 1)
        
        days_since_current_lyear = whole_days_since_1968 % ((4 * 365) + 1)
        
        if (days_since_current_lyear >= (31 + 29))
        {
            leap_year_periods += 1
        }
        
        whole_years = (whole_days_since_1968 - leap_year_periods) / 365
        days_since_first_of_year = whole_days_since_1968 - (whole_years * 365) - leap_year_periods
        
        if (days_since_current_lyear <= 365) && (days_since_current_lyear >= 60)
        {
            days_since_first_of_year += 1
        }
        
        year = (whole_years + 68)
        
        month = 13
        days_to_month = 366
        
        while (days_since_first_of_year < days_to_month)
        {
            month -= 1
            let monthIdx = Int(month - 1)
            days_to_month = UInt32(DaysToMonth[monthIdx])
            
            if ((month > 2) && ((year % 4) == 0))
            {
                days_to_month += 1
            }
        }
        day = (days_since_first_of_year - days_to_month + 1)
        
        ret.append(year+1900)
        ret.append(month)
        ret.append(day)
        ret.append(hour)
        ret.append(min)
        ret.append(sec)
        
        let retData = String(ret[0]) + "-" + String(ret[1]) + "-" + String(ret[2]) + " " + String(ret[3]) + ":" + String(ret[4]) + ":" + String(ret[5])
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = MyStruct.dateFromat
        let rawDt = dateFormatter.date(from: retData)
        let calDt = Calendar.current.date(byAdding: .year, value: addYear, to: rawDt!)
        
    
        let dateFormatterForType = DateFormatter()
        if type == 0{//yyyy-MM-dd HH:mm
            dateFormatterForType.dateFormat = MyStruct.dateFromat
        }
        else if type == 1{//dd/MMM/yyy
            dateFormatterForType.dateFormat = MyStruct.dateFromatUSA
        }
        else{
            //dateFormatterForType.dateFormat = "dd/MMM/yyy HH:mm:ss"
            dateFormatterForType.dateFormat = "MM/dd/yyyy HH:mm:ss"
        }
        
        return dateFormatterForType.string(from: calDt!)
    }
    
    
    /*static func viewBorderSetting(inView: UIView, inColor: String, mTop: Bool, mBotton: Bool, mLeft: Bool, mRight: Bool){
        let border = CALayer()
        let setColor = MyUtil.hexStringToUIColor(hex: inColor)
        
        if mTop{
            border.frame = CGRect(x: 0, y: 0, width: inView.frame.width, height: 1)
            border.backgroundColor = setColor.cgColor
            inView.layer.addSublayer(border)
        }
        
        if mBotton{
            border.frame = CGRect(x: 0, y: inView.frame.size.height - 1, width: inView.frame.width, height: 1)
            border.backgroundColor = setColor.cgColor
            inView.layer.addSublayer(border)
        }
        
        if mLeft{
            border.frame = CGRect(x: 0, y: 0, width: 1, height: inView.frame.height)
            border.backgroundColor = setColor.cgColor
            inView.layer.addSublayer(border)
        }
        
        if mRight{
            border.frame = CGRect(x:inView.frame.width - 1, y: 0, width: 1, height: inView.frame.height)
            border.backgroundColor = setColor.cgColor
            inView.layer.addSublayer(border)
        }
    }
    
    static func viewBorderSetting1(inView: UIView, inColor: String, mTop: Bool, mBotton: Bool, mLeft: Bool, mRight: Bool){
        let border = CALayer()
        let setColor = MyUtil.hexStringToUIColor(hex: inColor)
        
        if mTop{
            border.frame = CGRect(x: 0, y: 0, width: inView.frame.width, height: 1)
            border.backgroundColor = setColor.cgColor
            inView.layer.addSublayer(border)
        }
        
        if mBotton{
            border.frame = CGRect(x: 0, y: inView.frame.size.height - 1, width: inView.frame.width, height: 1)
            border.backgroundColor = setColor.cgColor
            inView.layer.addSublayer(border)
        }
        
        if mLeft{
            border.frame = CGRect(x: 0, y: 0, width: 21, height: inView.frame.height)
            border.backgroundColor = setColor.cgColor
            inView.layer.addSublayer(border)
        }
        
        if mRight{
            border.frame = CGRect(x:inView.frame.width - 1, y: 0, width: 1, height: inView.frame.height)
            border.backgroundColor = setColor.cgColor
            inView.layer.addSublayer(border)
        }
    }*/
    
    static func startDateMake(inDT: Date) ->Date{
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy"
        let yearData = Int(String(dateFormatter.string(from: inDT)))
        
        dateFormatter.dateFormat = "MM"
        let monthData = Int(String(dateFormatter.string(from: inDT)))
        
        dateFormatter.dateFormat = "dd"
        let dayData = Int(String(dateFormatter.string(from: inDT)))
        
        let anotherDate = DateComponents(calendar: .current, year: yearData, month: monthData, day: dayData).date!
        
        return anotherDate
    }
    
    static func endDateMake(inDT: Date) ->Date{
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy"
        let yearData = Int(String(dateFormatter.string(from: inDT)))
        
        dateFormatter.dateFormat = "MM"
        let monthData = Int(String(dateFormatter.string(from: inDT)))
        
        dateFormatter.dateFormat = "dd"
        let dayData = Int(String(dateFormatter.string(from: inDT)))
        
        let anotherDate = DateComponents(calendar: .current, year: yearData, month: monthData, day: dayData, hour: 23, minute: 59, second: 59).date!
        
        return anotherDate
    }
    
    static func subMenuImageResize(inImg: UIImage) -> UIImage{
        let imgWidth = CGFloat(30)
        let imgHeigth = CGFloat(30)
        
        UIGraphicsBeginImageContext(CGSize(width: imgWidth, height: imgHeigth))
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0.0, y: CGFloat(imgHeigth))
        context?.scaleBy(x: 1.0, y: -1.0)
        
        context?.draw(inImg.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: imgWidth, height: imgHeigth))
        
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndPDFContext()
        
        return newImage!
    }
    
    static func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    static func isValidPW(testStr:String) -> Bool{
        //let set = CharacterSet.decimalDigits
        //for us in testStr.unicodeScalars where !set.contains(us) { return false }
        var ret = Bool(false)
        
        var letterCounter = 0, digitCounter = 0
        for scalar in testStr.unicodeScalars {
            let value = scalar.value
            if (value >= 65 && value <= 90) || (value >= 97 && value <= 122) {letterCounter += 1}
            if (value >= 48 && value <= 57) {digitCounter += 1}
        }
        
        if letterCounter > 0 && digitCounter > 0{
            ret = true
        }
        
        return ret
    }

    static func activityIndicator(_ inView: UIView, _ title: String) -> UIView{
        //let str = title.localized
        let refCenter = CGPoint(x: inView.frame.width / 2, y: inView.frame.height / 2)
        let refWidth = inView.frame.width
        
        var viewHeight = 150
        if title.count <= 20{
            viewHeight = 110
        }
        else if title.count <= 40{
            viewHeight = 130
        }
        
        let widthData = refWidth * 0.6
        
        let boxView = UIView(frame: CGRect(x: 0, y: 0, width: Int(widthData), height: viewHeight))
        boxView.center = refCenter
        boxView.backgroundColor = UIColor.black
        boxView.alpha = 0.9
        boxView.layer.cornerRadius = 10
        
        // Spin config:
        let activityView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        activityView.color = .white
        activityView.frame = CGRect(x: (widthData / 2) - 25, y: 15, width: 50, height: 50)
        activityView.startAnimating()
        
        // Text config:
        let textLabel = UILabel(frame: CGRect(x: 3, y: 50, width: widthData * 0.98, height: 80))
        textLabel.textColor = UIColor.white
        textLabel.textAlignment = .center
        textLabel.font = UIFont.boldSystemFont(ofSize: 15)
        textLabel.numberOfLines = 0
        textLabel.text = title
        
        // Activate:
        boxView.addSubview(activityView)
        boxView.addSubview(textLabel)
        //view.addSubview(boxView)
        
        return boxView
    }
    
    static func printProcess(inMsg: String){
        print(inMsg)
    }
    
    static func arrayByteConvertStringDate(_ inData:[UInt8]) -> String{
        var ret = String("20")
        
        for i in 0..<6{
            if inData[i] < 10{
                ret += String.init(format: "0%d", inData[i])
            }
            else{
                ret += String.init(format: "%d", inData[i])
            }
            
            if i < 2{
                ret += "-"
            }
            else if i == 2{
                ret += " "
            }
            else if i == 3{
                ret += ":"
            }
            else if i == 4{
                ret += ":"
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = MyStruct.dateFromat
        let rawDt = dateFormatter.date(from: ret)
        
        let dateFormatterForType = DateFormatter()
        //dateFormatterForType.dateFormat = "dd/MMM/yyy HH:mm"
        dateFormatterForType.dateFormat = MyStruct.dateFromatUsaMin
        
        return dateFormatterForType.string(from: rawDt!)
    }
    
    
    static func aleretView(inTitle: String, inMsg: String, intButtonStr: String) -> UIAlertController{
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        var strMsg = String(inMsg)
        if inTitle != ""{
            strMsg = String.init(format: "\n%@", inMsg)
        }
        
        let messageText = NSMutableAttributedString(
            string: strMsg,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14),
                NSAttributedString.Key.foregroundColor : UIColor.black
            ]
        )
        
        let dialog = UIAlertController(title: inTitle, message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: intButtonStr, style: UIAlertAction.Style.default)
        dialog.setValue(messageText, forKey: "attributedMessage")
        dialog.addAction(action)
    
        return dialog
    }
    
    static func roundButton(_ object:UIButton){
        object.layer.cornerRadius = object.frame.size.height / 2
        object.layer.masksToBounds = true
    }
    
    static func roundButton(_ object:UIButton, _ inRadius: CGFloat){
        object.layer.cornerRadius = inRadius
        object.layer.masksToBounds = true
    }
    
    static func roundTf(_ object:UITextField){
        object.layer.cornerRadius = object.frame.size.height / 2
        object.layer.masksToBounds = true
    }
    
    static func underLineButton(_ object:UIButton, _ fontSize:CGFloat, _ btnText:String){
        let attrs = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.underlineStyle : 1] as [NSAttributedString.Key : Any]
        let attributedString = NSMutableAttributedString(string:"")
        
        let buttonTitleStr = NSMutableAttributedString(string:btnText, attributes:attrs)
        attributedString.append(buttonTitleStr)
        object.setAttributedTitle(attributedString, for: .normal)
    }
    
    static func underLineButtonWithe(_ object:UIButton, _ fontSize:CGFloat, _ btnText:String){
        let attrs = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor : UIColor.white,
            NSAttributedString.Key.underlineStyle : 1] as [NSAttributedString.Key : Any]
        let attributedString = NSMutableAttributedString(string:"")
        
        let buttonTitleStr = NSMutableAttributedString(string:btnText, attributes:attrs)
        attributedString.append(buttonTitleStr)
        object.setAttributedTitle(attributedString, for: .normal)
    }
    
    static func underLineButtonBasic(_ object:UIButton, _ fontSize:CGFloat, _ btnText:String){
        let attrs = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: fontSize),
            //NSAttributedString.Key.foregroundColor : MyStruct.Color.tintColor,
            NSAttributedString.Key.underlineStyle : 1] as [NSAttributedString.Key : Any]
        let attributedString = NSMutableAttributedString(string:"")
        
        let buttonTitleStr = NSMutableAttributedString(string:btnText, attributes:attrs)
        attributedString.append(buttonTitleStr)
        object.setAttributedTitle(attributedString, for: .normal)
    }
    
    
    static func dateDDMMMYYYConvertNormalType(inStr: String) -> String{
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "dd/MMM/yyyy HH:mm"
        dateFormatter.dateFormat = MyStruct.dateFromatUsaMin
        let sDateDateType = dateFormatter.date(from: inStr)
        
        let dateFormatterNew = DateFormatter()
        dateFormatterNew.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return dateFormatterNew.string(from: sDateDateType!)
    }
    
    static func stringLocal(_ inStr:String) -> String{
       return String(format: NSLocalizedString("ble_connection", comment: "ble_connection"))
    }
    
    static func accountStateIdxReturn(_ inType: Int, _ inState: String) -> Int{
        var ret = Int(-1)
        var arrayState = Array<String>()
        if inType == 1{//canada
            if let path = Bundle.main.path(forResource: "CANADA-state", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                    if let jsonResult = jsonResult as? Dictionary<String, AnyObject>{
                        //for (key, value) in jsonResult {
                        for (_, value) in jsonResult {
                            arrayState.append(value as! String)
                        }
                        arrayState.sort()
                        
                        for i in 0..<arrayState.count{
                            if inState == arrayState[i]{
                                ret = i
                            }
                        }
                    }
                } catch {
                    // handle error
                }
            }
        }
        else if inType == 2{//usa
            if let path = Bundle.main.path(forResource: "US-state-and-city", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                    if let jsonResult = jsonResult as? Dictionary<String, AnyObject>{
                        //for (key, value) in jsonResult {
                        for (key, _) in jsonResult {
                            arrayState.append(key)
                        }
                        arrayState.sort()
                        
                        for i in 0..<arrayState.count{
                            if inState == arrayState[i]{
                                ret = i
                            }
                        }
                    }
                } catch {
                    // handle error
                }
            }
        }
        
        return ret
    }
    
    static func accountStateListReturn(_ inType: Int) -> Array<String>{
        var arrayState = Array<String>()
        if inType == 1{//canada
            if let path = Bundle.main.path(forResource: "CANADA-state", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                    if let jsonResult = jsonResult as? Dictionary<String, AnyObject>{
                        //for (key, value) in jsonResult {
                        for (_, value) in jsonResult {
                            arrayState.append(value as! String)
                        }
                        arrayState.sort()
                    }
                } catch {
                    // handle error
                }
            }
        }
        else if inType == 2{//usa
            if let path = Bundle.main.path(forResource: "US-state-and-city", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                    if let jsonResult = jsonResult as? Dictionary<String, AnyObject>{
                        //for (key, value) in jsonResult {
                        for (key, _) in jsonResult {
                            arrayState.append(key)
                        }
                        arrayState.sort()
                    }
                } catch {
                    // handle error
                }
            }
        }
        
        return arrayState
    }
    
    static func normalDateConvertUsaType(_ inType:Int, _ inStrDt: String) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = MyStruct.dateFromat
        let rawDt = dateFormatter.date(from: inStrDt)

        
        let dateFormatterForType = DateFormatter()
        
        if inType == 0{//MM/dd/yyyy HH:mm:ss
            dateFormatterForType.dateFormat = MyStruct.dateFromatUsaAll
        }
        else if inType == 1{//MM/dd/yyyy HH:mm
            dateFormatterForType.dateFormat = MyStruct.dateFromatUsaMin
        }
        else if inType == 2{//MM/dd/yyyy
            dateFormatterForType.dateFormat = MyStruct.dateFromatUSA
        }
        
        return dateFormatterForType.string(from: rawDt!)
    }
    
    static func shareDialogView(){
        switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                 //let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            break
            // It's an iPhone
            case .pad:
            break
            // It's an iPad
            default:
            break
            // Uh, oh! What could it be?
        }
        //let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
    }
    
    static func calculateRadonRange(_ inTime:UInt32, inUnit: UInt8, _ inValue: Float) -> String{
        //let refValue = inValue
        var paraMeter = Float(0.5)
        
        if inUnit == 1{
            paraMeter =  19
        }
       
        let value1 = (Float(inValue) * 0.05) + paraMeter
        let value2 = Float(inValue) * 0.1
        
        var retValue = max(value1, value2)
        
        
        if inTime >= 10{
            if inTime < 20{//10분 ~ 20분 사이
                retValue = retValue * 1.5
            }
            else if inTime < 30{
                retValue = retValue * 1.4
            }
            else if inTime < 40{
                retValue = retValue * 1.3
            }
            else if inTime < 50{
                retValue = retValue * 1.2
            }
            else if inTime < 60{
                retValue = retValue * 1.1
            }
            
            var minValue = inValue - retValue
            if minValue < 0{
                minValue = 0
            }
            
            if inUnit == 0{
                return String.init(format: "%.1f~%.1f ", minValue, inValue + retValue)
            }
            else{
                return String.init(format: "%.0f~%.0f ", minValue, inValue + retValue)
            }
        }

        return ""
    }
    
    //V1.2.0
    static func radonValueReturn(_ inMode: Bool, _ inRadon: Float, _ inUnit:UInt8) -> Float{
        var ret = Float(inRadon)
        
        if inMode{//ESP32
            if inUnit == 0{
                let intValue = Int(inRadon)
                ret = Float(intValue) / 37
            }
        }
        else{//Nordic
            if inUnit == 1{
                ret = floor(inRadon * 37)//소수점 버림
            }
        }
        
        return ret
    }
    
    static func alarmValueViewReturn(_ inMode: Bool, _ inRadon: Float, _ inUnit:UInt8) -> Float{
        var ret = Float(inRadon)
        
        if inMode{//ESP32
            if inUnit == 0{
                let intValue = Int(inRadon)
                ret = Float(intValue) / 37
            }
        }
        else{//Nordic
            if inUnit == 1{
                ret = inRadon * 37
            }
        }
        
        return ret
    }
    
    //V1.2.0
    static func alarmValueReturn(_ inMode: Bool, _ inRadon: Float, _ inUnit:UInt8) -> Float{
        var ret = Float(inRadon)
        
        if inMode{//ESP32
            if inUnit == 0{
                ret = round(inRadon * 37)
            }
        }
        else{//Nordic
            if inUnit == 1{
                let calValue = inRadon / 37
                ret = round(calValue * 10) / 10
            }
        }
        
        return ret
    }
}

extension CALayer {
    func addBorder(_ arr_edge: [UIRectEdge], color: UIColor, width: CGFloat) {
        for edge in arr_edge {
            let border = CALayer()
            switch edge {
            case UIRectEdge.top:
                border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: width)
                break
            case UIRectEdge.bottom:
                border.frame = CGRect.init(x: 0, y: frame.height - width, width: frame.width, height: width)
                break
            case UIRectEdge.left:
                border.frame = CGRect.init(x: 0, y: 0, width: width, height: frame.height)
                break
            case UIRectEdge.right:
                border.frame = CGRect.init(x: frame.width - width, y: 0, width: width, height: frame.height)
                break
            default:
                break
            }
            border.backgroundColor = color.cgColor;
            self.addSublayer(border)
        }
    }
    
    func addBorderLarge(_ arr_edge: [UIRectEdge], color: UIColor, width: CGFloat) {
        for edge in arr_edge {
            let border = CALayer()
            switch edge {
            case UIRectEdge.top:
                border.frame = CGRect.init(x: 0, y: 0, width: frame.width * 2, height: width)
                break
            case UIRectEdge.bottom:
                border.frame = CGRect.init(x: 0, y: frame.height - width, width: frame.width * 2, height: width)
                break
            case UIRectEdge.left:
                border.frame = CGRect.init(x: 0, y: 0, width: width, height: frame.height)
                break
            case UIRectEdge.right:
                border.frame = CGRect.init(x: frame.width - width, y: 0, width: width, height: frame.height)
                break
            default:
                break
            }
            border.backgroundColor = color.cgColor;
            self.addSublayer(border)
        }
    }
}
