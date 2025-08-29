//
//  PopupRadonLevel.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2020/05/07.
//  Copyright © 2020 jung sukhwan. All rights reserved.
//

import UIKit

class PopupRadonLevel: UIViewController, UITextViewDelegate {
    let tag = String("PopupRadonLevel - ")
    let viewHieht = CGFloat(500)
    let viewWidth = CGFloat(340)
    
    var radonValue = Double(0)
    var radonUnit = Int(0)
    //var radonRange = Double(0)
    var radonValueStr = String("")
    var radonRangeStr = String("")
    var radonUnitStr = "unit_bq".localized
    
    let ruler = RulerHorizontalView()
    
    // UI elements for popup will be added to popupBox view
    let popupBox: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        self.definesPresentationContext = true
        
        DispatchQueue.main.async {
            self.setupViews()
        }
        
        //V1.2.0
        var raondValue = MyUtil.radonValueReturn(MyStruct.v2Mode, Float(radonValue), UInt8(radonUnit))
        
        //V1.5.0 - 20240723
        if BLEData.Flag.V3_New && BLEData.Config.unit == 0{
            raondValue = MyUtil.newFwMinValue(inValue: raondValue)
        }
        
        radonRangeStr = MyUtil.calculateRadonRange(BLEData.Status.measTime, inUnit: UInt8(radonUnit), Float(raondValue))
        
        if radonUnit == 0{
            radonValueStr = String.init(format: "%.1f", raondValue)
            radonUnitStr = "unit_pico".localized
        }
        else{
            radonValueStr = String.init(format: "%.0f", raondValue)
        }
    }
    
    func setupViews() {
        view.addSubview(popupBox)

     // autolayout constraint for popupBox
        popupBox.heightAnchor.constraint(equalToConstant: viewHieht).isActive = true
        popupBox.widthAnchor.constraint(equalToConstant: viewWidth).isActive = true
        popupBox.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        popupBox.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        popupBox.layer.cornerRadius = 15
        popupBox.layer.shadowColor = UIColor.black.cgColor
        popupBox.layer.shadowOffset = CGSize(width: 2, height: 2)
        popupBox.layer.shadowOpacity = 0.5
        popupBox.layer.shadowRadius = 5
        
        //제목
        let labTitle = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        labTitle.setLabel(inFontSize: 14, inFontBold: true, inText: "Radon Levels Chart", inTextColor: .black, inTextCenter: true)
        labTitle.sizeToFit()
        labTitle.center.x = viewWidth / 2
        labTitle.frame.origin.y = 20
        popupBox.addSubview(labTitle)
        
        let vuewRuler = UILabel(frame: CGRect(x: 0, y: 0, width: viewWidth - 100, height: 50))
        vuewRuler.center.x = viewWidth / 2
        vuewRuler.frame.origin.y = labTitle.frame.maxY + 25
               
        makeRuler(inView: vuewRuler)
        popupBox.addSubview(vuewRuler)

        var lastMaxYValue = CGFloat(0)
        //라돈 상태 설명
        for i in 0..<3{
            let viewStatus = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth - 170, height: 20))
            viewStatus.center.x = viewWidth / 2
            viewStatus.frame.origin.y = vuewRuler.frame.maxY + 15 + CGFloat((i * 22))
            
            let viewStatusBar = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 10))
            viewStatusBar.backgroundColor = UiConstants.RadonStatus.color[i]
            viewStatusBar.center.y = viewStatus.frame.height / 2
            //viewStatusBar.layer.cornerRadius = viewStatusBar.frame.height / 2
                   
            let labStatusTitle = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            labStatusTitle.setLabel(inFontSize: 14, inFontBold: false, inText: UiConstants.RadonStatus.title[i], inTextColor: UiConstants.Color.hex1F2738, inTextCenter: false)
            labStatusTitle.sizeToFit()
            labStatusTitle.frame.origin.x = viewStatusBar.frame.maxX + 20
            viewStatus.addSubview(viewStatusBar)
            viewStatus.addSubview(labStatusTitle)
               
            popupBox.addSubview(viewStatus)
            lastMaxYValue = viewStatus.frame.maxY
        }
        
        //경계선
        lastMaxYValue = lastMaxYValue + 20
        //let viewBorder = UIView(frame: CGRect(x: 0, y: lastMaxYValue, width: viewWidth, height: 1))
        //viewBorder.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.15)
        //popupBox.addSubview(viewBorder)
        
        //제목
        lastMaxYValue = lastMaxYValue + 20
        let labTitle2 = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        labTitle2.setLabel(inFontSize: 14, inFontBold: true, inText: "Radon Level Confidence Interval", inTextColor: .black, inTextCenter: true)
        labTitle2.sizeToFit()
        labTitle2.center.x = viewWidth / 2
        labTitle2.frame.origin.y = lastMaxYValue
        popupBox.addSubview(labTitle2)
       
        
        //현재 라돈 값 view
        lastMaxYValue = lastMaxYValue + 40
        let viewRadonValue = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 40))
        
        let labRadonValue = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        labRadonValue.setLabel(inFontSize: 36, inFontBold: true, inText: radonValueStr, inTextColor: UiConstants.Color.hex1F2738, inTextCenter: true)
        labRadonValue.sizeToFit()
        labRadonValue.center.y = viewRadonValue.frame.height / 2
        
        let labRadonValueUnit = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        labRadonValueUnit.setLabel(inFontSize: 12, inFontBold: false, inText: radonUnitStr, inTextColor: UiConstants.Color.hex4C5260, inTextCenter: true)
        labRadonValueUnit.sizeToFit()
        labRadonValueUnit.center.y = viewRadonValue.frame.height / 2
        labRadonValueUnit.frame.origin.x = labRadonValue.frame.maxX + 15
        labRadonValueUnit.center.y = viewRadonValue.frame.height / 2
        
        viewRadonValue.addSubview(labRadonValue)
        viewRadonValue.addSubview(labRadonValueUnit)
        
        viewRadonValue.frame = CGRect(x: 0, y: 0, width: labRadonValue.frame.width + labRadonValueUnit.frame.width + 15, height: 40)
        viewRadonValue.center.x = viewWidth / 2
        viewRadonValue.frame.origin.y = lastMaxYValue
        viewRadonValue.sizeToFit()
        popupBox.addSubview(viewRadonValue)
    
        //경계선
        lastMaxYValue = viewRadonValue.frame.maxY
        let viewRadonBorder = UIView(frame: CGRect(x: 0, y: lastMaxYValue, width: 130, height: 2))
        viewRadonBorder.center.x = viewWidth / 2
        viewRadonBorder.backgroundColor = UiConstants.Color.tint
        popupBox.addSubview(viewRadonBorder)
        
        //현재 라돈 범위
        lastMaxYValue = lastMaxYValue + 5
        let viewRadonRange = UIView(frame: CGRect(x: 0, y: lastMaxYValue, width: 130, height: 30))
        //viewRadonRange.center.x = viewWidth / 2
        //viewRadonRange.frame.origin.y = lastMaxYValue
      
        let labRadonRange = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        labRadonRange.setLabel(inFontSize: 20, inFontBold: false, inText: radonRangeStr, inTextColor: #colorLiteral(red: 0.1725490196, green: 0.1725490196, blue: 0.1725490196, alpha: 1), inTextCenter: true)
        labRadonRange.sizeToFit()
        labRadonRange.center.y = viewRadonRange.frame.height / 2
      
        let labRadonRangeUnit = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        labRadonRangeUnit.setLabel(inFontSize: 12, inFontBold: false, inText: radonUnitStr, inTextColor: UiConstants.Color.hex4C5260, inTextCenter: true)
        labRadonRangeUnit.sizeToFit()
        labRadonRangeUnit.center.y = viewRadonRange.frame.height / 2
        labRadonRangeUnit.frame.origin.x = labRadonRange.frame.maxX + 15
      
        viewRadonRange.addSubview(labRadonRange)
        viewRadonRange.addSubview(labRadonRangeUnit)
        
        viewRadonRange.frame = CGRect(x: 0, y: 0, width: labRadonRange.frame.width + labRadonRangeUnit.frame.width + 15, height: 40)
        viewRadonRange.center.x = viewWidth / 2
        viewRadonRange.frame.origin.y = lastMaxYValue
        popupBox.addSubview(viewRadonRange)
        
        
        //하단 범위 설명
        let labRangeInfo = UILabel(frame: CGRect(x: 0, y: 0, width: viewWidth - 20, height: 0))
        labRangeInfo.setLabel(inFontSize: 14, inFontBold: false, inText: "radon_range_info".localized, inTextColor: UiConstants.Color.hex1F2738, inTextCenter: true)
        labRangeInfo.numberOfLines = 0
        labRangeInfo.sizeToFit()
        labRangeInfo.center.x = viewWidth / 2
        labRangeInfo.frame.origin.y = viewRadonRange.frame.maxY + 5
        popupBox.addSubview(labRangeInfo)
        
        
        //경계선
        let viewBorder2 = UIView(frame: CGRect(x: 0, y: labRangeInfo.frame.maxY + 20, width: viewWidth, height: 1))
        viewBorder2.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.15)
        popupBox.addSubview(viewBorder2)
        
        
        //Close 버튼
        let btnClose = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        btnClose.setButton(inBackGround: UiConstants.Color.hexD2D4D7, inFontSize: 17, inFontBold: true, inText: "Close", inTextColor: .white)
        btnClose.setTitleColor(UiConstants.Color.tint, for: .normal)
        btnClose.backgroundColor = .white
        btnClose.center.x = viewWidth / 2
        btnClose.frame.origin.y = viewBorder2.frame.maxY + 14
        btnClose.addTarget(self, action: #selector(onResendClick), for: .touchUpInside)
        popupBox.addSubview(btnClose)
    }

    @objc func onResendClick(_ sender:UIButton){
        NotificationCenter.default.post(name: NSNotification.Name(UiConstants.notiName.popUpDismiss), object: nil)
        dismiss(animated: true, completion: nil)
    }
    
    func makeRuler(inView: UIView){
        var denn=0
        //var diem=0
        var x=0.0
        var ik=0.0
        let gv=0
        var scale:CGFloat?
        let c = UIScreen.main.bounds.size.width
        //let c = UIScreen.main.bounds.size.height
        
        scale = UIScreen.main.scale;
        if c < 500{
            x = 3.5
        }
        else if c<600&&c>500{
            x = 4
        }
        else if c<700&&c>600{
            x = 4.7
        }
        else if c<800&&c>700{
            x = 5.5
        }
        else if c==812{
            x = 5.8
        }
        else if c<1030&&c>800{
            if scale==1.0{
                x = 7.9
            }
            else{
                x = 9.7
            }
        }
        else{
            x = 12.9
        }
        
        ik = x
        
      
        ruler.frame = CGRect(x: 0, y: 0, width: inView.frame.size.width, height: inView.frame.height)
        ruler.backgroundColor = .white
        if gv%2==1{
            //diem=2
            denn=1
            ik=x/2.54
        }
        else{
            ik=x
        }
        ruler.den = denn
        ruler.x = ik
        ruler.radonUnit = radonUnit
        //ruler.r = inView.frame.width
        //ruler.c = inView.frame.height
        ruler.r = inView.frame.height
        ruler.c = inView.frame.width
        inView.addSubview(self.ruler)
    }
}

