//
//  viewMonitorRadon.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit
import Foundation
import XLPagerTabStrip

class viewTabRadon: UIViewController, IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
         return itemInfo
    }
    
    let tag = String("viewTabRadon - ")
    var itemInfo = IndicatorInfo(title: "View")
    
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
    
    var bleController           : BLEControl?
    
    init(itemInfo: IndicatorInfo) {
        self.itemInfo = itemInfo//
        super.init(nibName: "RadonTab", bundle: nil)
        //super.init(nibName: "TabRdon", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        //fatalError("init(coder:) has not been implemented")
    }
    
    //required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
    //}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*labRadonStatus.font = UIFont.boldSystemFont(ofSize: 24)
        viewRadon.layer.addBorder([.top, .bottom], color: MyStruct.Color.border, width: 0.5)
        viewMeasTime.layer.addBorder([.top], color: MyStruct.Color.border, width: 0.5)
        view30DayValue.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
        
        labRadonValue.attributedText = textRadonValue(inRadonValue: 0, inUnit: 2)
        labMeasTime.attributedText = textMeasTime(inTime: 0)
        labPeakValue.attributedText = textRadonAvgValue(inRadonValue: 0, inUnit: 2)
        lab1DayValue.attributedText = textRadonAvgValue(inRadonValue: 0, inUnit: 2)
        lab30DayValue.attributedText = textRadonAvgValue(inRadonValue: 0, inUnit: 2)*/
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
    
    func tabRadonUiDisconnect(){
        labRadonStatus.text = "Disconnected"
    }
    
    func tabRadonUiUpdate(){
        MyUtil.printProcess(inMsg: tag + "tabRadonUiUpdate")
        labMeasTime.attributedText = textMeasTime(inTime: BLEData.Status.measTime)
        
        if BLEData.Status.vibStatus == 0{
            imgVibration.image = #imageLiteral(resourceName: "wave_off")
        }
        else{
            imgVibration.image = #imageLiteral(resourceName: "wave_on")
        }
      
        if BLEData.Status.measTime < 10{
            labRadonValue.attributedText = textRadonValue(inRadonValue: 0, inUnit: 2)
        }
        else{
            var radonValue      = BLEData.Meas.radonValue
            var radonDValue     = BLEData.Meas.radonDValue
            var radonMValue     = BLEData.Meas.radonMValue
            var radonPeakValue  = BLEData.Meas.radonPeakValue

            labRadonStatus.font = UIFont.boldSystemFont(ofSize: 33)
            if radonValue >= 4{
                viewRadonLevel.backgroundColor = MyStruct.Color.statusBad
                labRadonStatus.textColor = MyStruct.Color.statusBad
                labRadonStatus.text = "status_bad".localized
            }
            else if radonValue >= 2{
                viewRadonLevel.backgroundColor = MyStruct.Color.statusWarning
                labRadonStatus.textColor = MyStruct.Color.statusWarning
                labRadonStatus.text = "status_warning".localized
            }
            else if radonValue >= 1{
                viewRadonLevel.backgroundColor = MyStruct.Color.statusNormal
                labRadonStatus.textColor = MyStruct.Color.statusNormal
                labRadonStatus.text = "status_normal".localized
            }
            else{
                viewRadonLevel.backgroundColor = MyStruct.Color.statusGood
                labRadonStatus.textColor = MyStruct.Color.statusGood
                labRadonStatus.text = "status_good".localized
            }

            if BLEData.Config.unit == 1{
                radonValue      = floor(BLEData.Meas.radonValue * 37.0)
                radonDValue     = floor(BLEData.Meas.radonDValue * 37.0)
                radonMValue     = floor(BLEData.Meas.radonMValue * 37.0)
                radonPeakValue  = floor(BLEData.Meas.radonPeakValue * 37.0)
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
        }
    }
    
    
    func textRadonValue(inRadonValue: Float, inUnit: UInt8) -> NSMutableAttributedString{
        let valueStr = MyUtil.valueReturnString(inUnit, inRadonValue)
      
        let attributedText = NSMutableAttributedString(string: valueStr, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 43),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060])
        attributedText.append(NSAttributedString(string: BLEData.Config.unitStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 21),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
        
        return attributedText
    }
    
    func textRadonAvgValue(inRadonValue: Float, inUnit: UInt8) -> NSMutableAttributedString{
        let valueStr = MyUtil.valueReturnString(inUnit, inRadonValue)
           
        let attributedText = NSMutableAttributedString(string: valueStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24),NSAttributedString.Key.foregroundColor: UIColor.black])
           attributedText.append(NSAttributedString(string: BLEData.Config.unitStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
           
        return attributedText
    }
    
    func textMeasTime(inTime: UInt32) -> NSMutableAttributedString{
        let ret =  MyUtil.measTimeConvertStringArray(inTime)
        
        let attributedText = NSMutableAttributedString()
        if ret[0] != ""{
            attributedText.append(NSAttributedString(string: ret[0], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 21),NSAttributedString.Key.foregroundColor: UIColor.black]))
            attributedText.append(NSAttributedString(string: "day ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
        }
        
        attributedText.append(NSAttributedString(string: ret[1], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24),NSAttributedString.Key.foregroundColor: UIColor.black]))
        attributedText.append(NSAttributedString(string: "hr ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
        
        attributedText.append(NSAttributedString(string: ret[2], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24),NSAttributedString.Key.foregroundColor: UIColor.black]))
        attributedText.append(NSAttributedString(string: "m", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))

        return attributedText
    }
}
