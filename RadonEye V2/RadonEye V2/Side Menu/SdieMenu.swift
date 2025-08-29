//
//  SdieMenu.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit
import Foundation
import SideMenu

class SideMenu: NSObject{
    
    func setupSideMenu(inSb: UIStoryboard, inNavigation: UINavigationBar, inMainVeiw: UIView, inSubView: UIView) {
        //let sb = UIStoryboard.init(name: "SideMenu", bundle: nil)
        SideMenuManager.default.leftMenuNavigationController = inSb.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? SideMenuNavigationController
                
        SideMenuManager.default.addPanGestureToPresent(toView: inNavigation)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: inSubView, forMenu: .left)
         
        let settings = makeSettings(inMainVeiw: inMainVeiw)
        SideMenuManager.default.leftMenuNavigationController?.settings = settings
        SideMenuManager.default.rightMenuNavigationController?.settings = settings
    }

    func makeSettings(inMainVeiw: UIView) -> SideMenuSettings {
        let modes: [SideMenuPresentationStyle] = [.menuSlideIn, .viewSlideOut, .viewSlideOutMenuIn, .menuDissolveIn]
        let presentationStyle = modes[0]
         //presentationStyle.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "background"))
         //presentationStyle.menuStartAlpha = CGFloat(0.5)
         //presentationStyle.menuScaleFactor = 0
         //presentationStyle.onTopShadowOpacity = 0.5
        presentationStyle.presentingEndAlpha = 0.3

        var settings = SideMenuSettings()
        settings.presentationStyle = presentationStyle
        
        settings.menuWidth = min(inMainVeiw.frame.width, inMainVeiw.frame.height) * CGFloat(0.8)
        let styles:[UIBlurEffect.Style?] = [nil, .dark, .light, .extraLight]
        settings.blurEffectStyle = styles[0]
         
        settings.statusBarEndAlpha = 0
        return settings
    }
}
