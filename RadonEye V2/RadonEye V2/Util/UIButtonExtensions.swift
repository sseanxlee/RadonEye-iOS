//
//  UIButtonExtensions.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2020/05/07.
//  Copyright © 2020 jung sukhwan. All rights reserved.
//

import UIKit

extension UIButton {
    func setButton(inBackGround: UIColor, inFontSize: CGFloat, inFontBold: Bool, inText: String, inTextColor: UIColor) {
        backgroundColor = inBackGround

        if inFontBold {
            titleLabel?.font = UIFont.boldSystemFont(ofSize: inFontSize)
        } else {
            titleLabel?.font = UIFont.systemFont(ofSize: inFontSize)
        }

        setTitle(inText, for: .normal)
        setTitleColor(inTextColor, for: .normal)
    }
}
