//
//  viewAboutUs.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/13.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit
import MessageUI

class viewGetHelp: UIViewController, MFMailComposeViewControllerDelegate {
    let tag = String("viewGetHelp - ")
    
    @IBOutlet weak var btnHomepage: UIButton!
    @IBOutlet weak var btnEmail: UIButton!
    
    @IBOutlet weak var labPrivacy: LableLocal!
    @IBOutlet weak var labTerms: LableLocal!
    @IBOutlet weak var labFooter: LableLocal!
    @IBOutlet weak var labCompany: UILabel!
    
    @IBOutlet weak var labFAQ: LableLocal!
    @IBOutlet weak var labQuickGuide: LableLocal!
    
    @IBOutlet weak var labWebsite: LableLocal!
    @IBOutlet weak var labEmail: LableLocal!
    
    @IBOutlet weak var textViewWebSite: UITextView!
    @IBOutlet weak var textViewEmail: UITextView!
    @IBOutlet weak var textViewEurope: UITextView!
    @IBOutlet weak var textViewOther: UITextView!
    
    @IBOutlet weak var labOutSide: LableLocal!
    @IBOutlet weak var labOutSide2: LableLocal!
    @IBOutlet weak var labEuropeTitle: LableLocal!
    @IBOutlet weak var labEuropeContent: LableLocal!
    @IBOutlet weak var labOtherTitle: LableLocal!
    @IBOutlet weak var labOtherContent: LableLocal!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let action = UIImage(systemName: "multiply")
         
        navigationItem.title = "title_get_help".localized
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
        
        labFooter.text = "support_homepage".localized
        labFooter.isUserInteractionEnabled = true
        labFooter.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickFooterLabel)))
        
        labPrivacy.isUserInteractionEnabled = true
        labPrivacy.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickPrivacy)))
        
        labTerms.isUserInteractionEnabled = true
        labTerms.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickTerms)))
        
        //V1.6.0 - 20241010
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let dateValue = formatter.string(from: NSDate() as Date)
        labCompany.text = String.init(format: "support_menu_copy1".localized, dateValue)
        
        //V1.5.1 - 20250522
        makeLabGuide()
        makeLabFaq()
        makeLabWebSite()
        makeLabEmail()
        
        labOutSide.text = "• "
        labOutSide2.text = "get_help_canada_title".localized
        
        labEuropeTitle.text = "get_help_europe_title".localized
        makeLabEurope()
        labOtherTitle.text = "get_help_other_title".localized
        makeLabOther()
    }
    
    func makeLabGuide(){
        //Guide
        labQuickGuide.textColor = UIColor(red: 0.21, green: 0.49, blue: 0.75, alpha: 1.0) // #357DC
        labQuickGuide.isUserInteractionEnabled = true
        let text = "help_quick_guide".localized
        let attributedString = NSMutableAttributedString(string: text)
        if let range = text.range(of: "RadonEye Quick Guide") {
            let nsRange = NSRange(range, in: text)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0.21, green: 0.49, blue: 0.75, alpha: 1.0), range: nsRange)
        }
        labQuickGuide.attributedText = attributedString
        
        // 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(guideLabelTapped))
        labQuickGuide.addGestureRecognizer(tapGesture)
    }
    
    func makeLabFaq(){
        //FAQ
        labFAQ.textColor = UIColor(red: 0.21, green: 0.49, blue: 0.75, alpha: 1.0) // #357DC
        labFAQ.isUserInteractionEnabled = true
        let text = "help_faq".localized
        let attributedString = NSMutableAttributedString(string: text)
        if let range = text.range(of: "Frequently Asked Questions") {
            let nsRange = NSRange(range, in: text)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0.21, green: 0.49, blue: 0.75, alpha: 1.0), range: nsRange)
        }
        labFAQ.attributedText = attributedString
        
        // 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(faqLabelTapped))
        labFAQ.addGestureRecognizer(tapGesture)
    }
    
    func makeLabWebSite(){
        textViewWebSite.isEditable = false
        textViewWebSite.isScrollEnabled = false
        textViewWebSite.dataDetectorTypes = []
        textViewWebSite.isUserInteractionEnabled = true
        textViewWebSite.backgroundColor = .clear
        textViewWebSite.textContainerInset = .zero
        textViewWebSite.textContainer.lineFragmentPadding = 0
        let fullText = "• Website: ecosense.io"
        let attributedString = NSMutableAttributedString(string: fullText)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: NSMakeRange(0, fullText.count))
        if let range = fullText.range(of: "ecosense.io") {
            let nsRange = NSRange(range, in: fullText)
            attributedString.addAttribute(.link, value: "https://ecosense.io", range: nsRange)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0.21, green: 0.49, blue: 0.75, alpha: 1.0), range: nsRange) // #357DC0
            //attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            //attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0.21, green: 0.49, blue: 0.75, alpha: 1.0), range: nsRange) // #357DC0
        }
        // 나머지 텍스트는 검정색으로 지정
        attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: NSMakeRange(0, fullText.count))
        
        
        textViewWebSite.attributedText = attributedString
        textViewWebSite.delegate = self
        // 전체 UILabel에 탭 제스처 추가
        //let tapGesture = UITapGestureRecognizer(target: self, action: #selector(websiteTapped))
        //labWebsite.addGestureRecognizer(tapGesture)
    }
    
    func makeLabEmail(){
        textViewEmail.isEditable = false
        textViewEmail.isScrollEnabled = false
        textViewEmail.dataDetectorTypes = []
        textViewEmail.isUserInteractionEnabled = true
        textViewEmail.backgroundColor = .clear
        textViewEmail.textContainerInset = .zero
        textViewEmail.textContainer.lineFragmentPadding = 0
        let fullText = "• Email: support@ecosense.io"
        let attributedString = NSMutableAttributedString(string: fullText)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: NSMakeRange(0, fullText.count))
        if let range = fullText.range(of: "support@ecosense.io") {
            let nsRange = NSRange(range, in: fullText)
            attributedString.addAttribute(.link, value: "action://openEmail", range: nsRange)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0.21, green: 0.49, blue: 0.75, alpha: 1.0), range: nsRange) // #357DC0
            //attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            //attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0.21, green: 0.49, blue: 0.75, alpha: 1.0), range: nsRange) // #357DC0
        }
        // 나머지 텍스트는 검정색으로 지정
        attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: NSMakeRange(0, fullText.count))
        
        textViewEmail.attributedText = attributedString
        textViewEmail.delegate = self
    }
    
    func makeLabEurope(){
        textViewEurope.isEditable = false
        textViewEurope.isScrollEnabled = false
        textViewEurope.dataDetectorTypes = []
        textViewEurope.isUserInteractionEnabled = true
        textViewEurope.backgroundColor = .clear
        textViewEurope.textContainerInset = .zero
        textViewEurope.textContainer.lineFragmentPadding = 0
        let fullText = "get_help_europe_content".localized
        let attributedString = NSMutableAttributedString(string: fullText)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, fullText.count))
        
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: NSMakeRange(0, fullText.count))
        if let range = fullText.range(of: "support@ecosense.io") {
            let nsRange = NSRange(range, in: fullText)
            attributedString.addAttribute(.link, value: "action://openEmail", range: nsRange)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: nsRange)
                
        }
        
        if let range2 = fullText.range(of: "support@radontec.de") {
            let nsRange = NSRange(range2, in: fullText)
            attributedString.addAttribute(.link, value: "action://openEmail2", range: nsRange)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: nsRange)
        }
    
        // 나머지 텍스트는 검정색으로 지정
        attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: NSMakeRange(0, fullText.count))
        
        textViewEurope.linkTextAttributes = [
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        textViewEurope.attributedText = attributedString
        textViewEurope.delegate = self
    }
    
    func makeLabOther(){
        textViewOther.isEditable = false
        textViewOther.isScrollEnabled = false
        textViewOther.dataDetectorTypes = []
        textViewOther.isUserInteractionEnabled = true
        textViewOther.backgroundColor = .clear
        textViewOther.textContainerInset = .zero
        textViewOther.textContainer.lineFragmentPadding = 0
        let fullText = "get_help_other_content".localized
        let attributedString = NSMutableAttributedString(string: fullText)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, fullText.count))
        
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: NSMakeRange(0, fullText.count))
        if let range = fullText.range(of: "support@ecosense.io") {
            let nsRange = NSRange(range, in: fullText)
            attributedString.addAttribute(.link, value: "action://openEmail", range: nsRange)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: nsRange)
        }
        
        // 나머지 텍스트는 검정색으로 지정
        attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: NSMakeRange(0, fullText.count))
        
        textViewOther.linkTextAttributes = [
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        textViewOther.attributedText = attributedString
        textViewOther.delegate = self
    }
    
    @objc func guideLabelTapped() {
        UIApplication.shared.open((URL(string: "https://link.ecosense.io/rd200-guide"))!)
     }
    
    @objc func faqLabelTapped() {
        UIApplication.shared.open((URL(string: "https://ecosense.io/pages/rd200-faq-en"))!)
    }
    
    @objc func websiteTapped() {
        UIApplication.shared.open((URL(string: "https://ecosense.io"))!)
    }
    
    @objc func emailTapped() {
        sendEmail()
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
    }
    
    //MARK: - Click event
    @IBAction func onClickQuickGuide(_ sender: Any) {
        //performSegue(withIdentifier: "goPDF", sender: nil)
        UIApplication.shared.open((URL(string: "https://link.ecosense.io/rd200-guide"))!)
    }
       
    @IBAction func onClickFaq(_ sender: Any) {
        UIApplication.shared.open((URL(string: "https://ecosense.io/pages/rd200-faq-en"))!)
    }
       
    @IBAction func onClickHomePage(_ sender: Any) {
         UIApplication.shared.open((URL(string: "https://ecosense.io/pages/about-us-1"))!)
    }
    
    @IBAction func onClickEmail(_ sender: Any) {
        print(tag + "onClicEmail")
               sendEmail()
    }
    
    @objc func onClickFooterLabel(_ sender:UIGestureRecognizer){
        print(tag + "onClickFooterLabel")
        UIApplication.shared.open((URL(string: "about_us_link".localized))!)
    }

    //MARK: - Send Email
    func sendEmail(){
        let msg = "help_email_alert_msg".localized + " " + "support_menu_email".localized
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
    
    func sendEmail2(){
        let msg = "help_email_alert_msg".localized + " " + "support@radontec.de"
        let dialog = UIAlertController(title: "help_email_alert_title".localized, message: msg, preferredStyle: .alert)
        
        let actionYes = UIAlertAction(title: "Send", style: .default){(action: UIAlertAction) -> Void in
            let mailComposeViewController = self.configuredMailComposeViewController2()
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
        mailComposerVC.setToRecipients(["support_menu_email".localized])
           
        return mailComposerVC
    }
    
    func configuredMailComposeViewController2() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients(["support@radontec.de"])
           
        return mailComposerVC
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

extension viewGetHelp: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        
        if URL.absoluteString == "action://openEmail" {
            sendEmail()
            return false // 기본 링크 열기 막기
        }
        else if URL.absoluteString == "action://openEmail2" {
            sendEmail2()
            return false // 기본 링크 열기 막기
        }
        else {
            UIApplication.shared.open(URL)
            return false // 기본 동작 차단하고 커스텀 처리
        }
    }
}
