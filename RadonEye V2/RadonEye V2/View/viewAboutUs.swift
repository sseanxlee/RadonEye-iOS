//
//  viewAboutUs.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/13.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit
import MessageUI

class viewAboutUs: UIViewController, MFMailComposeViewControllerDelegate {
    let tag = String("viewAboutUs - ")
    var savedDeviceName = String("")
    
    @IBOutlet weak var mScrollView: UIScrollView!
    @IBOutlet weak var btnHomePage: UIButton!
    @IBOutlet weak var btnEmail: UIButton!
    
    @IBOutlet weak var lmgFaceBook: UIImageView!
    @IBOutlet weak var imgYoutube: UIImageView!
    
    
    @IBOutlet weak var labPrivacy: LableLocal!
    @IBOutlet weak var labTerms: LableLocal!
    
    @IBOutlet weak var labCompany: UILabel!
    @IBOutlet weak var labInfo: LableLocal!
    
    var sendEmail = String("")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let action = UIImage(systemName: "multiply")
         
        navigationItem.title = "title_about_us".localized
        navigationItem.hidesBackButton = true
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.barTintColor  = MyStruct.Color.aboutUsbackground
        
        let buttonRight = UIButton(type: .system)
        buttonRight.frame = CGRect(x: 0.0, y: 0.0, width: 10, height: 10)
        buttonRight.tintColor = UIColor.black
        buttonRight.setImage(action, for: .normal)//
        buttonRight.addTarget(self, action: #selector(viewCloseClick), for: .touchUpInside)
        let rightBarButton = UIBarButtonItem(customView: buttonRight)
        self.navigationItem.rightBarButtonItem  = rightBarButton
        
        btnHomePage.setTitleColor(MyStruct.Color.tilt, for: .normal)
        btnEmail.setTitleColor(MyStruct.Color.tilt, for: .normal)
              
        btnHomePage.setTitle("support_homepage".localized, for: .normal)
        btnEmail.setTitle("support_menu_email".localized, for: .normal)
        
        lmgFaceBook.isUserInteractionEnabled = true
        lmgFaceBook.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickFaceBook)))
        
        imgYoutube.isUserInteractionEnabled = true
        imgYoutube.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickYoutube)))
        
        labPrivacy.isUserInteractionEnabled = true
        labPrivacy.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickPrivacy)))
        
        labTerms.isUserInteractionEnabled = true
        labTerms.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickTerms)))
        
        mScrollView.isScrollEnabled = true
    
        let attrString = NSMutableAttributedString(string: labInfo.text!)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attrString.length))
        labInfo.attributedText = attrString
        
        //V1.6.0 - 20241010
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let dateValue = formatter.string(from: NSDate() as Date)
        labCompany.text = String.init(format: "support_menu_copy1".localized, dateValue)
    }
    
    
    @objc func viewCloseClick(){
        print(tag + "viewCloseClick")
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillAppear")
        super.viewWillAppear(animated)
    }


    override func viewWillDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillDisappear")
        super.viewWillDisappear(animated)
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewDidDisappear")
        super.viewDidDisappear(animated)
    }
    
    
    override func didReceiveMemoryWarning() {
        MyUtil.printProcess(inMsg: tag + "didReceiveMemoryWarning")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClickHomePage(_ sender: Any) {
        UIApplication.shared.open((URL(string: "about_us_link".localized))!)
    }
    
    @IBAction func onClickEmail(_ sender: Any) {
        sendEmail(inEmail: "support_menu_email".localized)
    }
    
    @IBAction func onClickMarketingEmail(_ sender: Any) {
        sendEmail(inEmail: "support_menu_email_marmketting".localized)
    }
    
    //MARK: - Send Email
    func sendEmail(inEmail: String){
        sendEmail = inEmail
        let msg = "help_email_alert_msg".localized + " " + inEmail
        let dialog = UIAlertController(title: "help_email_alert_title".localized, message: msg, preferredStyle: .alert)
        
        let actionYes = UIAlertAction(title: "Send", style: .default){(action: UIAlertAction) -> Void in
            let mailComposeViewController = self.configuredMailComposeViewController()
            if MFMailComposeViewController.canSendMail() {
                self.present(mailComposeViewController, animated: true, completion: nil)
                print("can send mail")
            } else {
                print("can send mail err")
            }
        }
        
        let actionNo = UIAlertAction(title: "Close", style: .default){(action: UIAlertAction) -> Void in
           
        }
        
        dialog.addAction(actionNo)
        dialog.addAction(actionYes)
        
        self.present(dialog, animated: true, completion: nil)
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients([sendEmail])
           
        return mailComposerVC
    }

    @objc func onClickFaceBook(_ sender:UIGestureRecognizer){
         print(tag + "onClickFooterLabel")
         UIApplication.shared.open((URL(string: "https://www.facebook.com/ecosense.io/"))!)
     }

    
    @objc func onClickYoutube(_ sender:UIGestureRecognizer){
         print(tag + "onClickFooterLabel")
         UIApplication.shared.open((URL(string: "https://youtu.be/jzhCfKRLVNI"))!)
     }

    @objc func onClickPrivacy(_ sender:UIGestureRecognizer){
        print(tag + "onClickPrivacy")
        UIApplication.shared.open((URL(string: "https://ecosense.io/policies/privacy-policy"))!)
    }
    
    @objc func onClickTerms(_ sender:UIGestureRecognizer){
        print(tag + "onClickTerms")
        UIApplication.shared.open((URL(string: "https://ecosense.io/policies/terms-of-service"))!)
    }
    
}

