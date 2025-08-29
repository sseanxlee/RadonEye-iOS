//
//  LabelLocal.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit

class LableLocal : UILabel{
    
    @IBInspectable var keyValue: String{
        get{
            return self.text!
        }
        set(value){
            self.text = NSLocalizedString(value, comment: "")
        }
    }
}
