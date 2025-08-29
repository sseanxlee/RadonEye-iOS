//
//  UiConstants.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2020/05/07.
//  Copyright © 2020 jung sukhwan. All rights reserved.
//

import Foundation
import UIKit

struct UiConstants {
    private init() { }

    static let barButtonTextSize = CGFloat(17)
    static let dtFormatMMddyy: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()

    struct RadonStatus{
        //static let range = [37, 98, 148]
        static let title = ["No Action Required", "Some Concern", "Action Required"]
        static let color = [#colorLiteral(red: 0.01960784314, green: 0.7882352941, blue: 0.09803921569, alpha: 1), #colorLiteral(red: 0.9725490196, green: 0.7333333333, blue: 0.07843137255, alpha: 1), #colorLiteral(red: 0.737254902, green: 0.1843137255, blue: 0.1568627451, alpha: 1)]
    }

    struct Color {
        static let border = #colorLiteral(red: 0.8588235294, green: 0.8588235294, blue: 0.8588235294, alpha: 1)
        static let normalBorder = #colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 1)

        static let hexC3C3C3 = #colorLiteral(red: 0.7647058824, green: 0.7647058824, blue: 0.7647058824, alpha: 1)
        static let hexADADAD = #colorLiteral(red: 0.7336427569, green: 0.7336601615, blue: 0.733650744, alpha: 1)
        static let hex606060 = #colorLiteral(red: 0.3764705882, green: 0.3764705882, blue: 0.3764705882, alpha: 1)
        static let hex5B5B5B = #colorLiteral(red: 0.3568627451, green: 0.3568627451, blue: 0.3568627451, alpha: 1)
        static let hex616161 = #colorLiteral(red: 0.3803921569, green: 0.3803921569, blue: 0.3803921569, alpha: 1)
        static let hexF5F5F5 = #colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1)
        static let hex979797 = #colorLiteral(red: 0.5921568627, green: 0.5921568627, blue: 0.5921568627, alpha: 1)
        static let hexBlackHalf = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5044084821)
        static let hexD2D4D7 = #colorLiteral(red: 0.8235294118, green: 0.831372549, blue: 0.8431372549, alpha: 1)
        static let hex1F2738 = #colorLiteral(red: 0.1215686275, green: 0.1529411765, blue: 0.2196078431, alpha: 1)
        static let hex4C5260 = #colorLiteral(red: 0.2980392157, green: 0.3215686275, blue: 0.3764705882, alpha: 1)
        static let hexF3F5FB = #colorLiteral(red: 0.9529411765, green: 0.9607843137, blue: 0.9843137255, alpha: 1)


        static let landingBackGround = #colorLiteral(red: 0.1215686275, green: 0.1529411765, blue: 0.2196078431, alpha: 1)
        static let barButtonDisable = #colorLiteral(red: 0.5607843137, green: 0.5764705882, blue: 0.6117647059, alpha: 1)
        static let tint = #colorLiteral(red: 0.1568627451, green: 0.4588235294, blue: 0.737254902, alpha: 1)
        static let background = #colorLiteral(red: 0.9764705882, green: 0.9843137255, blue: 0.9960784314, alpha: 1)

        static let aboutUsbackground = #colorLiteral(red: 0.8941176471, green: 0.9294117647, blue: 0.9568627451, alpha: 1)

        static let dataTitle = #colorLiteral(red: 0.262745098, green: 0.2509803922, blue: 0.2509803922, alpha: 1)
    }
    
    struct notiName {
        static let wifiConnect = String("wifiConnect")
        static let dataSort = String("dataSort")
        static let dataFilter = String("dataFilter")

        static let exportDataSelectDate = String("exportDataSelectDate")

        static let deviceNameSet = String("deviceNameSet")

        static let refreshRadonChartLatest = String("refreshRadonChartLatest")
        static let getRadonDataBetween = String("getRadonDataBetween")
        static let popUpView = String("popUpView")
        static let popUpDismiss = String("popUpDismiss")

        static let selectDates = String("selectDates")
        
        static let signOut = String("signOut")
    }
}
