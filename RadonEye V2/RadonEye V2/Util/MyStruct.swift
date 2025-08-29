//
//  MyStruct.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import Foundation
import UIKit

class MyStruct: NSObject {
    struct Color{
        static let border = #colorLiteral(red: 0.7647058824, green: 0.7647058824, blue: 0.7647058824, alpha: 1)
        static let hexC3C3C3 = #colorLiteral(red: 0.7647058824, green: 0.7647058824, blue: 0.7647058824, alpha: 1)
        static let hexADADAD = #colorLiteral(red: 0.7336427569, green: 0.7336601615, blue: 0.733650744, alpha: 1)
        static let hex606060 = #colorLiteral(red: 0.3764705882, green: 0.3764705882, blue: 0.3764705882, alpha: 1)
        static let hex5B5B5B = #colorLiteral(red: 0.3568627451, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
        static let hex2C2C2C = #colorLiteral(red: 0.1725490196, green: 0.1725490196, blue: 0.1725490196, alpha: 1)
        static let hexBlackHalf = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5044084821)
        static let hexC4C4C4 = #colorLiteral(red: 0.768627451, green: 0.768627451, blue: 0.768627451, alpha: 1)
        
        //static let statusBad = #colorLiteral(red: 0.737254902, green: 0.1568627451, blue: 0.1803921569, alpha: 1)
        //static let statusWarning = #colorLiteral(red: 1, green: 0.7803921569, blue: 0.003921568627, alpha: 1)
        //static let statusNormal = #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        //static let statusGood = #colorLiteral(red: 0.1568627451, green: 0.4588235294, blue: 0.737254902, alpha: 1)
        
        static let tilt = #colorLiteral(red: 0.1568627451, green: 0.4588235294, blue: 0.737254902, alpha: 1)
        static let background = #colorLiteral(red: 0.9764705882, green: 0.9843137255, blue: 0.9960784314, alpha: 1)
        
        static let aboutUsbackground = #colorLiteral(red: 0.8941176471, green: 0.9294117647, blue: 0.9568627451, alpha: 1)
    }
    
    static var uiMode           = Int(0)
    static var refFW           = Int(103)
    static var bleStatus        = Bool(false)
    static var bleDisconnectinoTime       = Int(0)
    
    static let dfuUUIDString        = "00001530-1212-efde-1523-785feabcd123"
    
    static let deviceUUIDString     = "00001523-1212-efde-1523-785feabcd123"
    static let controlUUIDString    = "00001524-1212-efde-1523-785feabcd123"
    static let measUUIDString       = "00001525-1212-efde-1523-785feabcd123"
    static let logUUIDString        = "00001526-1212-efde-1523-785feabcd123"
    
    static let fwUpdateMin          = UInt8(120)
    static let fwUpdateMax          = UInt8(123)
    
    //static var iPhoneType           = UInt8(0)
    
    static let dateFromat           = "yyyy-MM-dd HH:mm:ss"
    //static let dateFromatUSA        = "dd/MMM/yyy"
    static let dateFromatUSA        = "MM/dd/yyyy"
    static let dateFromatUsaMin     = "MM/dd/yyyy HH:mm"
    static let dateFromatUsaAll     = "MM/dd/yyyy HH:mm:ss"
    
    static var fileName           = String("")
    static var fileUrl           =  URL(fileURLWithPath: "")
    
    
    //V1.2.0
    static var v2Mode = Bool(false)
    
    //V1.3.0
    static var v3Mode = Bool(false)
    
    static let deviceUUIDStringV2 = "00001523-0000-1000-8000-00805f9b34fb"
    static let controlUUIDStringV2 = "00001524-0000-1000-8000-00805f9b34fb"
    static let measUUIDStringV2 = "00001525-0000-1000-8000-00805f9b34fb"
    static let logUUIDStringV2 = "00001526-1212-efde-1523-785feabcd123"

    class Key{
        static let lastDeviceName    = String("peripheralName")
    }
    
    class notiName{
        static let deviceList    = String("deviceList")
        static let monitor    = String("monitor")
        static let monitorFileList    = String("monitorFileList")
        
        static let logDownStart    = String("logDownStart")
        static let logDataSave    = String("logDataSave")
        
        static let monitorDisconnect    = String("monitorDisconnect")
        static let monitorRadonUpdate    = String("monitorRadonUpdate")
        
        static let monitorChartUpdate    = String("monitorChartUpdate")
        static let monitorChartSyncUpdate    = String("monitorChartSyncUpdate")
    }
    
    //V1.2.0 - 2024722
    static var refV3NewFw           = Int(302)
}
