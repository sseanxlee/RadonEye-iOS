//
//  viewMonitorRadon.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import CoreBluetooth

class viewMonitorRadon: UIViewController, IndicatorInfoProvider {
    var itemInfo = IndicatorInfo(title: "Radon")

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
           return itemInfo
    }

    let tag = String("viewMonitorRadon - ")
    var flagView = false
    
    @IBOutlet weak var labSync: UILabel!
    
    @IBOutlet weak var viewRadon: UIView!
    @IBOutlet weak var viewRadonLevel: UIView!
    @IBOutlet weak var labRadonStatus: UILabel!
    @IBOutlet weak var labRadonValue: UILabel!
    @IBOutlet weak var imgVibration: UIImageView!
    @IBOutlet weak var viewMeasTime: UIView!
    @IBOutlet weak var labMeasTime: UILabel!
    @IBOutlet weak var labPeakValue: UILabel!
    @IBOutlet weak var lab1DayValue: UILabel!
    @IBOutlet weak var view30DayValue: UIView!
    @IBOutlet weak var lab30DayValue: UILabel!
    @IBOutlet weak var constraint1dayLeading: NSLayoutConstraint!
    @IBOutlet weak var imgInfo : UIImageView!
    
    var mViewTab              = viewTabTop()
    var timerDisconnect                       : Timer?
    var dtDisconnect = Date()
    var diffMin = 0
    
    //V1.2.0
    var radonLevel : [Float] = [4, 2.7]
    
    override func viewDidLoad() {
        MyUtil.printProcess(inMsg: tag + "viewDidLoad")
        super.viewDidLoad()
        
        labRadonStatus.font = UIFont.boldSystemFont(ofSize: 24)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.viewRadon.layer.addBorder([.top, .bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewMeasTime.layer.addBorder([.top], color: MyStruct.Color.border, width: 0.5)
            self.view30DayValue.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
            
            self.labRadonValue.attributedText = self.textRadonValue(inRadonValue: 0, inUnit: 2)
            self.labMeasTime.attributedText = self.textMeasTime(inTime: 0)
            self.labPeakValue.attributedText = self.textRadonAvgValue(inRadonValue: 0, inUnit: 2)
            self.lab1DayValue.attributedText = self.textRadonAvgValue(inRadonValue: 0, inUnit: 2)
            self.lab30DayValue.attributedText = self.textRadonAvgValue(inRadonValue: 0, inUnit: 2)
        }

        
        imgInfo.isUserInteractionEnabled = true
        imgInfo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickChartInfo)))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillAppear, \(flagView)")
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self,selector: #selector(notificationUpdate),name: NSNotification.Name(MyStruct.notiName.monitorRadonUpdate),object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(notificationDisconnect),name: NSNotification.Name(MyStruct.notiName.monitorDisconnect),object: nil)
        
        //최초 뷰 생성시에는 업데이트 안하고 다른 뷰 이동하고 복귀했을때 바로 업데이트 하려고
        if flagView{
           notificationUpdate()
        }
        else{
            flagView = true
        }
        
        if MyStruct.bleStatus == false{
            labRadonStatus.text = "msg_disconnect".localized
            labRadonStatus.font = UIFont.boldSystemFont(ofSize: 24)
            labRadonStatus.textColor = MyStruct.Color.hexADADAD
            
            if MyStruct.bleDisconnectinoTime == 0{
                labSync.text = "msg_disconnect".localized
            }
            else {
                labSync.text = String.init(format: "Last synced %dmin ago", MyStruct.bleDisconnectinoTime)
            }
         }
    }

    override func viewWillDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillDisappear")
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(MyStruct.notiName.monitorRadonUpdate), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(MyStruct.notiName.monitorDisconnect), object: nil)
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewDidDisappear")
        super.viewDidDisappear(animated)
        
        if timerDisconnect != nil{
            timerDisconnect?.invalidate()
            timerDisconnect = nil
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        MyUtil.printProcess(inMsg: tag + "didReceiveMemoryWarning")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   
    func textRadonValue(inRadonValue: Float, inUnit: UInt8) -> NSMutableAttributedString{
        let valueStr = MyUtil.valueReturnString(inUnit, inRadonValue)
      
        let attributedText = NSMutableAttributedString(string: valueStr, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 43),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060])
        attributedText.append(NSAttributedString(string: BLEData.Config.unitStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 21),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
        
        return attributedText
    }
    
    func textRadonAvgValue(inRadonValue: Float, inUnit: UInt8) -> NSMutableAttributedString{
        let valueStr = MyUtil.valueReturnString(inUnit, inRadonValue)
           
        let attributedText = NSMutableAttributedString(string: valueStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22),NSAttributedString.Key.foregroundColor: UIColor.black])
           attributedText.append(NSAttributedString(string: BLEData.Config.unitStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
           
        return attributedText
    }
    
    func textMeasTime(inTime: UInt32) -> NSMutableAttributedString{
        let ret =  MyUtil.measTimeConvertStringArray(inTime)
        
        let attributedText = NSMutableAttributedString()
        if ret[0] != ""{
            attributedText.append(NSAttributedString(string: ret[0], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22),NSAttributedString.Key.foregroundColor: UIColor.black]))
            attributedText.append(NSAttributedString(string: "d ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
        }
        
        attributedText.append(NSAttributedString(string: ret[1], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22),NSAttributedString.Key.foregroundColor: UIColor.black]))
        attributedText.append(NSAttributedString(string: "h ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
        
        attributedText.append(NSAttributedString(string: ret[2], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22),NSAttributedString.Key.foregroundColor: UIColor.black]))
        attributedText.append(NSAttributedString(string: "m", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))

        return attributedText
    }
    
    @objc func notificationUpdate(){
        //BLEData.Status.measTime = 230
        //BLEData.Meas.radonValue = 1.23
        
        print(tag + "notificationUpdate")
        MyUtil.printProcess(inMsg: tag + "tabRadonUiUpdate")
        labMeasTime.attributedText = textMeasTime(inTime: BLEData.Status.measTime)
        labSync.text = "msg_connect".localized
      
        if BLEData.Status.vibStatus == 0{
            imgVibration.image = #imageLiteral(resourceName: "wave_off")
        }
        else{
            imgVibration.image = #imageLiteral(resourceName: "wave_on")
        }
    
        if BLEData.Status.measTime < 10{
            labRadonValue.attributedText = textRadonValue(inRadonValue: 0, inUnit: 2)
            
            //20211001 측정 데이터가 없어도 단위 변경하게 함
            labPeakValue.attributedText = textRadonAvgValue(inRadonValue: 0, inUnit: 2)
            lab1DayValue.attributedText = textRadonAvgValue(inRadonValue: 0, inUnit: 2)
        }
        else{
            //var radonValue      = BLEData.Meas.radonValue
            //var radonDValue     = BLEData.Meas.radonDValue
            //var radonMValue     = BLEData.Meas.radonMValue
            //var radonPeakValue  = BLEData.Meas.radonPeakValue
            
            //V1.2.0
            var radonValue      = MyUtil.radonValueReturn(MyStruct.v2Mode, BLEData.Meas.radonValue, BLEData.Config.unit)
            var radonDValue     = MyUtil.radonValueReturn(MyStruct.v2Mode, BLEData.Meas.radonDValue, BLEData.Config.unit)
            var radonMValue     = MyUtil.radonValueReturn(MyStruct.v2Mode, BLEData.Meas.radonMValue, BLEData.Config.unit)
            var radonPeakValue  = MyUtil.radonValueReturn(MyStruct.v2Mode, BLEData.Meas.radonPeakValue, BLEData.Config.unit)
            
            //V1.5.0 - 20240723 
            if BLEData.Flag.V3_New && BLEData.Config.unit == 0{
                radonValue = MyUtil.newFwMinValue(inValue: radonValue)
                radonDValue = MyUtil.newFwMinValue(inValue: radonDValue)
                radonMValue = MyUtil.newFwMinValue(inValue: radonMValue)
                radonPeakValue = MyUtil.newFwMinValue(inValue: radonPeakValue)
            }
            
            //V1.2.0
            if BLEData.Config.unit == 1{
                radonLevel[0] = 148
                radonLevel[1] = 100
            }
            else{
                radonLevel[0] = 4
                radonLevel[1] = 2.7
            }
            
            labRadonStatus.font = UIFont.boldSystemFont(ofSize: 33)
            if radonValue >= radonLevel[0]{
                viewRadonLevel.backgroundColor = UiConstants.RadonStatus.color[2]
                labRadonStatus.textColor = UiConstants.RadonStatus.color[2]
                labRadonStatus.text = UiConstants.RadonStatus.title[2]
            }
            else if radonValue >= radonLevel[1]{
                viewRadonLevel.backgroundColor = UiConstants.RadonStatus.color[1]
                labRadonStatus.textColor = UiConstants.RadonStatus.color[1]
                labRadonStatus.text = UiConstants.RadonStatus.title[1]
            }
            else{
                viewRadonLevel.backgroundColor = UiConstants.RadonStatus.color[0]
                labRadonStatus.textColor = UiConstants.RadonStatus.color[0]
                labRadonStatus.text = UiConstants.RadonStatus.title[0]
            }
            labRadonValue.attributedText = textRadonValue(inRadonValue: radonValue, inUnit: BLEData.Config.unit)
          
            //peak value
            if BLEData.Status.measTime >= 60{
                labPeakValue.attributedText = textRadonAvgValue(inRadonValue: radonPeakValue, inUnit: BLEData.Config.unit)
            }
            else{
                labPeakValue.attributedText = textRadonAvgValue(inRadonValue: 0, inUnit: 2)
            }
          
            //30day
            if BLEData.Status.measTime >= 1440 * 30{
                constraint1dayLeading.constant  = 60
                view30DayValue.isHidden = false
                lab30DayValue.attributedText = textRadonAvgValue(inRadonValue: radonMValue, inUnit: BLEData.Config.unit)
                lab1DayValue.attributedText = textRadonAvgValue(inRadonValue: radonDValue, inUnit: BLEData.Config.unit)
            }
            else if BLEData.Status.measTime >= 1440{//1day
                constraint1dayLeading.constant  = 0
                view30DayValue.isHidden = true
                lab1DayValue.attributedText = textRadonAvgValue(inRadonValue: radonDValue, inUnit: BLEData.Config.unit)
            }
            else{//V1.2.0 - 20211001 - 1일이 안되어도 단위는 변경되도록 수정
                lab1DayValue.attributedText = textRadonAvgValue(inRadonValue: 0, inUnit: 2)
            }
        }
    }
    
    @objc func notificationDisconnect(){
        print(tag + "notificationDisconnect")
        viewRadonLevel.backgroundColor = MyStruct.Color.hexADADAD
        labRadonStatus.text = "msg_disconnect".localized
        labRadonStatus.font = UIFont.boldSystemFont(ofSize: 24)
        labRadonStatus.textColor = MyStruct.Color.hexADADAD
        
        labSync.text = "msg_disconnect".localized
        dtDisconnect = Date()
        timerDisconnect = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.disconnectdTime), userInfo: nil, repeats: true)
    }
    
    @objc func disconnectdTime(){
        let nowDt = Date()
        let diff = nowDt.timeIntervalSince1970 - dtDisconnect.timeIntervalSince1970
        diffMin = Int(diff / 60)
        print(tag + "disconnectdTime, nowDt: \(nowDt), ChartUpdate: \(dtDisconnect), diff: \(diff), diffMin: \(diffMin)")
        if diffMin >= 1{
            labSync.text = String.init(format: "Last synced %dmin ago", diffMin)
            MyStruct.bleDisconnectinoTime = diffMin
        }
    }
    
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet var viewRange: UIView!
    @IBOutlet weak var labRangeNowValue: UILabel!
    @IBOutlet weak var labRangValue: UILabel!
    
    @objc func onClickChartInfo(_ sender:UIGestureRecognizer){
        print(tag + "onClickChartInfo")
        //dialogChartInfo()
        NotificationCenter.default.post(name: NSNotification.Name(UiConstants.notiName.popUpView), object: nil)
        let popupVC = PopupRadonLevel()
        popupVC.modalPresentationStyle = .overCurrentContext
        //popupVC.radonRange = 7
        popupVC.radonUnit = Int(BLEData.Config.unit)
        popupVC.radonValue = Double(BLEData.Meas.radonValue)
        present(popupVC, animated: true, completion: nil)
    }
    
    @IBAction func onClickClose(_ sender: Any) {
        viewMain.alpha = 1
        self.navigationController?.navigationBar.alpha = 1
        viewRange.removeFromSuperview()
    }
    
    func dialogChartInfo(){
        print(tag + "dialogChartInfo")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView(gesture:)))
        viewRange.addGestureRecognizer(tapGesture)

        view.addSubview(viewRange)
        viewMain.alpha = 0.3
        self.navigationController?.navigationBar.alpha = 0.3
        //viewRange.frame = CGRect(x: 0, y: 0 , width: view.frame.width * 0.8, height: 200)
        viewRange.layer.cornerRadius = 10
        viewRange.layer.shadowColor = UIColor.black.cgColor
        viewRange.layer.shadowRadius = 5;
        viewRange.layer.shadowOffset = CGSize(width: 2, height: 2)
        viewRange.layer.shadowOpacity = 0.5
        viewRange.center = CGPoint(x: view.frame.width / 2, y: (view.frame.height / 2) - 50)
        
        let radonPeakValue  = MyUtil.radonValueReturn(MyStruct.v2Mode, BLEData.Meas.radonValue, BLEData.Config.unit)
        
        let valueStr = MyUtil.valueReturnString(BLEData.Config.unit, radonPeakValue)
        let attributedText = NSMutableAttributedString(string: valueStr, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 40),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex2C2C2C])
          attributedText.append(NSAttributedString(string: BLEData.Config.unitStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
        
        labRangeNowValue.attributedText = attributedText
        
        let calValue = MyUtil.calculateRadonRange(BLEData.Status.measTime, inUnit: BLEData.Config.unit, radonPeakValue)
        let attributedText2 = NSMutableAttributedString(string: calValue, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex2C2C2C])
        attributedText2.append(NSAttributedString(string: BLEData.Config.unitStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
        
        labRangValue.attributedText = attributedText2
    }
    
    @objc func didTapView(gesture: UITapGestureRecognizer){
        view.endEditing(true)
    }
}
