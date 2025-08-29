//
//  NORAppUtilities.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit
import UserNotifications

enum NORServiceIds : UInt8 {
    case uart       = 0
    case rsc        = 1
    case proximity  = 2
    case htm        = 3
    case hrm        = 4
    case csc        = 5
    case bpm        = 6
    case bgm        = 7
    case cgm        = 8
    case homekit    = 9
}

class NORAppUtilities: NSObject {
    
    static let iOSDFULibraryVersion = "4.0.2"
    
    static func showBackgroundNotification(message aMessage : String){
        let localNotification = UILocalNotification()
        //let localNotification = UNUserNotificationCenter.current()
        localNotification.alertAction   = "Show"
        localNotification.alertBody     = aMessage
        localNotification.hasAction     = false
        localNotification.fireDate      = Date(timeIntervalSinceNow: 1)
        localNotification.timeZone      = TimeZone.current
        localNotification.soundName     = UILocalNotificationDefaultSoundName
    }
    
    static func isApplicationInactive() -> Bool {
        let appState = UIApplication.shared.applicationState
        return appState != UIApplication.State.active
    }
}

