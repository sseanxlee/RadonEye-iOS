//
//  UILabelExtensions.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2020/05/07.
//  Copyright © 2020 jung sukhwan. All rights reserved.
//

import UIKit

extension UILabel {
    func setLabel(inFontSize: CGFloat, inFontBold: Bool, inText: String, inTextColor: UIColor, inTextCenter: Bool) {
        numberOfLines = 0
        if inTextCenter {
            textAlignment = .center
        } else {
            textAlignment = .left
        }

        if inFontBold {
            font = UIFont.boldSystemFont(ofSize: inFontSize)
        } else {
            font = UIFont.systemFont(ofSize: inFontSize)
        }

        text = inText
        textColor = inTextColor
    }
}
