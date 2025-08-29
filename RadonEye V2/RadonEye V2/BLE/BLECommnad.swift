//
//  BLECommnad.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import Foundation

class BLECommnad: NSObject {
    static let cmd_MEAS_QUERY                   = UInt8(0x50);
    static let cmd_BLE_STATUS_QUERY             = UInt8(0x51);
    
    static let cmd_BASIC_INFO_QUERY             = UInt8(0x10);
    
    static let cmd_BLE_RD200_Date_Time_Set      = UInt8(0xA1);
    static let cmd_BLE_RD200_UNIT_Set           = UInt8(0xA2);
    static let cmd_SN_Set                       = UInt8(0xA3);
    static let cmd_SN_QUERY                     = UInt8(0xA4);
    static let cmd_VIB_LEVEL                    = UInt8(0xA6);
    static let cmd_MODEL_NAME_SET               = UInt8(0xA7);
    static let cmd_MODEL_NAME_RETURN            = UInt8(0xA8);
    static let cmd_BLE_BUZZER_SET               = UInt8(0xA9);
    static let cmd_BLE_WARNING_SET              = UInt8(0xAA);
    static let cmd_CONFIG_QUERY                 = UInt8(0xAC);
    
    static let cmd_EEPROM_LONG_DATA_CLEAR       = UInt8(0xE0);
    
    //2015.10.26 add
    static let cmd_EEPROM_LOG_INFO_QUERY        = UInt8(0xE8);
    static let cmd_EEPROM_LOG_DATA_SEND         = UInt8(0xE9);
    
    static let cmd_MOD_CONIFG_SET               = UInt8(0xB0);
    static let cmd_MOD_CONIFG_QUERY             = UInt8(0xB1);
    
    static let cmd_BLE_VERSION_QUERY            = UInt8(0xAF);
    
    //V1.0.0 추가
    static let cmd_OLED_SET                     = UInt8(0xAE);
    static let cmd_OLED_QUERY                   = UInt8(0xAD);
    
    static let cmd_SN_TYPE_SET                  = UInt8(0xA5);//20160102
    static let cmd_SN_TYPE_QUERY                = UInt8(0xA6);//20160102
    
    static let cmd_DISPLAY_CAL_FACTOR_SET       = UInt8(0xBC);//20160102
    static let cmd_DISPLAY_CAL_FACTOR_QUERY     = UInt8(0xBD);//20160102
    
    
    
    //V2 - V1.2.0
    static let cmd_BLEV2_QUERY_ALL            = UInt8(0x40);
    static let cmd_BLEV2_LOG_SEND            = UInt8(0x41)
    
    static let cmd_DFU_START            = UInt8(0x45);
    static let cmd_DFU_READY            = UInt8(0x46);
    static let cmd_DFU_SEND            = UInt8(0x47);
    static let cmd_DFU_OK            = UInt8(0x48);
    static let cmd_DFU_DONE            = UInt8(0x49);
}

