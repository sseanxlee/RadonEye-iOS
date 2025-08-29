//
//  ContainerVC.swift
//  RadonEye Pro
//
//  Created by 정석환 on 2019. 2. 26..
//  Copyright © 2019년 ftlab. All rights reserved.
//

import UIKit

class ContainerVC: UIViewController {
    
    @IBOutlet weak var sideMenuContainer: NSLayoutConstraint!
    var sideMenuOpen = false
    @IBOutlet weak var menuWidth: NSLayoutConstraint!
    
    var menuType = Int(0)
    
    override func viewDidLoad() {
        print("sideMenuContainer - viewDidLoad, \(view.frame.width)")
        
        if view.frame.width == 1000{
            menuType = 1
            menuWidth.constant = 800
            sideMenuContainer.constant = -800
        }
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(toggleSideMenu),
                                               name: NSNotification.Name("ToggleSideMenu"),object: nil)
    }
    
    @objc func toggleSideMenu() {
        if sideMenuOpen {
            sideMenuOpen = false
            if menuType == 0{
                sideMenuContainer.constant = -300
            }
            else{
                sideMenuContainer.constant = -800
            }
            
            
        } else {
            sideMenuOpen = true
            sideMenuContainer.constant = 0
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    
}

