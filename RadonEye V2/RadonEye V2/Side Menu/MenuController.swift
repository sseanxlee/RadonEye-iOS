//
//  SideMenuVC.swift
//  RadonEye Pro
//
//  Created by 정석환 on 2019. 2. 26..
//  Copyright © 2019년 ftlab. All rights reserved.
//
import Foundation
import UIKit
import MessageUI

class MenuController: UIViewController{
    let tag = String("MenuController - ")
    var indicatorView                   = UIView()//progress bar
    
    @IBOutlet weak var viewLogo: UIView!
    
    @IBOutlet weak var viewDeviceList: UIView!
    @IBOutlet weak var viewSaveLogData: UIView!
    @IBOutlet weak var viewGetHelp: UIView!
    @IBOutlet weak var viewAboutUs: UIView!
    
    override func viewDidLoad() {
        print("MenuController viewDidLoad")
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.viewDeviceList.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewSaveLogData.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewGetHelp.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewAboutUs.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
        }

        
        viewDeviceList.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goDeviceList)))
        viewSaveLogData.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goFileList)))
        viewGetHelp.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goGetHelp)))
        viewAboutUs.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goAboutUs)))
    }

    
    @objc func goDeviceList(_ sender:UIGestureRecognizer){
        print(tag + "goDeviceList")
        
        if MyStruct.uiMode == 0{//device list
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.deviceList), object: nil)
        }
        else{
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.monitor), object: nil)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc func goFileList(_ sender:UIGestureRecognizer){
        print(tag + "goFileList")
        if MyStruct.uiMode == 1{
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.monitorFileList), object: nil)
        }
        
        self.performSegue(withIdentifier: "goLogDataList", sender: nil)
    }
    
    @objc func goGetHelp(_ sender:UIGestureRecognizer){
        print(tag + "goGetHelp")
        if MyStruct.uiMode == 1{
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.monitorFileList), object: nil)
        }
        performSegue(withIdentifier: "goGetHelp", sender: nil)
    }
    
    @objc func goAboutUs(_ sender:UIGestureRecognizer){
        print(tag + "goAboutUs")
        if MyStruct.uiMode == 1{
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.monitorFileList), object: nil)
        }
        performSegue(withIdentifier: "goAboutUs", sender: nil)
    }
    
    func aleretView(inMsg: String, intButtonStr: String){
        let msg = inMsg.localized
        let buttonStr = intButtonStr.localized
        
        let dialog = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonStr, style: UIAlertAction.Style.default)
        dialog.addAction(action)
        self.present(dialog, animated: true, completion: nil)
    }
    
    func activityIndicator(_ title: String) {
        indicatorView.removeFromSuperview()
        indicatorView = MyUtil.activityIndicator(self.view, title)
        view.addSubview(indicatorView)
    }
    
    func ShowWeb() {
        if let url = URL(string: "https://radoneyepro.com"), !url.absoluteString.isEmpty {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    /*func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "메일을 전송 실패", message: "아이폰 이메일 설정을 확인하고 다시 시도해주세요.", delegate: self, cancelButtonTitle: "확인")
        sendMailErrorAlert.show()
    }*/

}

