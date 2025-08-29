//
//  viewMonitorData.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//


import UIKit
import Charts
import XLPagerTabStrip
import DGCharts
class viewMonitorData: UIViewController, UITextFieldDelegate, IndicatorInfoProvider {
    
    var itemInfo = IndicatorInfo(title: "Data")
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
         return itemInfo
    }
    
    let tag = String("viewMonitorData - ")
   
    var indicatorView                   = UIView()//progress bar
    @IBOutlet weak var labSync: UILabel!
    @IBOutlet weak var viewChart: UIView!
    @IBOutlet weak var imgSync: UIImageView!
    
    @IBOutlet weak var labChartUnit: UILabel!
    @IBOutlet weak var labChartX: UILabel!
    @IBOutlet weak var imgChartInfo: UIImageView!
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var labRefresh: LableLocal!
    @IBOutlet weak var btnSave: UIButton!
    var flagChartView = false
    var fileUrl : URL?
    var fileName = String("")
    var dtChartUpdate = Date()
    var mViewTab              = viewTabTop()
    var bleController           : BLEControl?
    
    //1.2.0
    var oldUnit = UInt8(100)
    
    @IBAction func onClickSave(_ sender: Any) {
        if flagChartView == false{
            aleretView(inMsg: "no_data_dataload".localized, intButtonStr: "close".localized)
            return
        }
        
        let titleStr = String("Save Log Data")
        let cancelbuttonStr = String("cancel".localized)
        let buttonStr = String("save".localized)
               
        let dialog  = UIAlertController(title: titleStr, message: "", preferredStyle: .alert)
        dialog.addTextField(configurationHandler: {(textField : UITextField!) -> Void in
            textField.placeholder = MyUtil.logDataFileName()
            textField.delegate = self as UITextFieldDelegate
        })
               
        let cancelButton  = UIAlertAction(title: cancelbuttonStr, style: .default)
        let okButton      = UIAlertAction(title: buttonStr, style: .default){(action: UIAlertAction) -> Void in
            var loginTextField          = dialog.textFields![0].text//사용자가 입력한 값이 있는지 확인
            if loginTextField == ""{//입력한 값이 없으면 기본 값 사용
                loginTextField          = dialog.textFields![0].placeholder! + ".txt"
            }
            else{//입력한 값이 있으면 .txt 확장자 붙여서 사용
                loginTextField          = dialog.textFields![0].text! + ".txt"
            }
            print("logDataSaveAs - \(String(describing: loginTextField))")
            self.logFileSaveProcess(loginTextField!)
        }
               
        dialog.addAction(cancelButton)
        dialog.addAction(okButton)
               
        //self.present(dialog, animated: true, completion: nil)
        present(dialog, animated: true) {
                   
        }
    }

    override func viewDidLoad() {
        MyUtil.printProcess(inMsg: tag + "viewDidLoad")
        super.viewDidLoad()
        
        labSync.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.viewChart.layer.addBorder([.top, .bottom], color: MyStruct.Color.border, width: 0.5)
        }
        
        
        imgSync.isUserInteractionEnabled = true
        imgSync.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickLogDown)))
        imgChartInfo.isUserInteractionEnabled = true
        imgChartInfo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickChartInfo)))
        
        labRefresh.isUserInteractionEnabled = true
        labRefresh.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickRefreshLabel)))
        
        labChartX.text = "chart_bottom_text".localized
        btnSave.setTitle("Save Current Log Data", for: .normal)
        btnSave.layer.cornerRadius = 5
        
        //V1.2.0
        lineChart.isHidden = true
        labRefresh.isHidden = false
        labRefresh.text = "chart_refresh_click".localized
        
        /*if BLEData.Log.dataNo > 0 {
            labRefresh.isHidden = false
            labRefresh.text = "chart_refresh_click".localized
            lineChart.isHidden = true
        }*/
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillAppear")
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self,selector: #selector(notificationChartUpdate),name: NSNotification.Name(MyStruct.notiName.monitorChartUpdate),object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(notificationChartUpdateSync),name: NSNotification.Name(MyStruct.notiName.monitorChartSyncUpdate),object: nil)
        
        if BLEData.Log.dataNo == 0{
            //lineChart.clear()
            chartInitProcess()
        }
        
        //V1.2.0
        if flagChartView{
            //V0.1.5
            let nowDt = Date()
            let diff = nowDt.timeIntervalSince1970 - dtChartUpdate.timeIntervalSince1970
            let diffMin = diff / 60
            if diffMin >= 1{
                labSync.text = String.init(format: "Last synced %.0fmin ago", diffMin)
            }
            
            if oldUnit != BLEData.Config.unit{
                oldUnit = BLEData.Config.unit
                chartUpdateProcess()
            }
        }

        /*for i in 0..<100{
            BLEData.Log.radonValue.append(Float.random(in: 0.50 ..< 4.0))
        }
        
        labRefresh.isHidden = true
        lineChart.isHidden = false
        
        dtChartUpdate = Date()
        flagChartView = true
        imgChartInfo.isHidden = false
        labChartX.isHidden = false
        labSync.isHidden = false
        labChartUnit.text = String.init(format: "(%@)", BLEData.Config.unitStr)
        btnSave.backgroundColor = MyStruct.Color.tilt
        chartsControl.chartDraw(lineChart, BLEData.Log.radonValue, 0, Int(BLEData.Config.unit), 4)//받아온 값은 무조건 pci단위이므로 value unit은 0*/
    }


    override func viewWillDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillDisappear")
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(MyStruct.notiName.monitorChartUpdate), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(MyStruct.notiName.monitorChartSyncUpdate), object: nil)
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
    
    @objc func onClickLogDown(_ sender:UIGestureRecognizer){
        print(tag + "\(Date()) onClickLogDown")
        NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.logDownStart), object: nil)
    }
    
    @objc func onClickChartInfo(_ sender:UIGestureRecognizer){
        print(tag + "onClickChartInfo")
        dialogChartInfo()
    }
    
    @objc func onClickRefreshLabel(_ sender:UIGestureRecognizer){
        print(tag + "onClickRefreshLabel")
        NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.logDownStart), object: nil)
    }
    
    //MARK: - Chart
    func chartInitProcess(){//V1.2.0
        labRefresh.isHidden = false
        lineChart.isHidden = true
        flagChartView = false
        imgChartInfo.isHidden = true
        
        labChartX.isHidden = true
        labSync.isHidden = true
        labChartUnit.text = ""
        
        btnSave.backgroundColor = MyStruct.Color.hexC4C4C4
    }
    
    //1.2.0
    func chartUpdateProcess(){
        labRefresh.isHidden = true
        lineChart.isHidden = false

        flagChartView = true
        imgChartInfo.isHidden = false
        labChartX.isHidden = false
        labSync.isHidden = false
        labChartUnit.text = String.init(format: "(%@)", BLEData.Config.unitStr)
        btnSave.backgroundColor = MyStruct.Color.tilt

        oldUnit = BLEData.Config.unit
        chartsControl.chartDraw(lineChart, BLEData.Log.radonValue, MyUtil.refUnit(inMove: MyStruct.v2Mode), Int(BLEData.Config.unit), Double(BLEData.Config.alarmValue), BLEData.Flag.V3_New)//받아온 값은 무조건 pci단위이므로 value unit은 0
    }
  
    //MARK:- UTIL
    func errorMsgView(inMsg: String){
        indicatorView.removeFromSuperview()
        aleretView(inMsg: inMsg, intButtonStr: "close")
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
        print(tag + "activityIndicator: \(view.frame), self.view.center: \(self.view.center)")
        indicatorView.removeFromSuperview()
        indicatorView = MyUtil.activityIndicator(self.view, title)
        view.addSubview(indicatorView)
        self.view.isUserInteractionEnabled = false
    }
    
    //저장데이터를 텍스트 파일로 변환
    func logFileSaveProcess(_ inFileName: String){
        let result = MyFileManager.logFileSaveProcess(BLEData.Config.barcode, inFileName, BLEData.Log.radonValue, MyUtil.refUnit(inMove: MyStruct.v2Mode), BLEData.Config.unit, BLEData.Config.alarmValue)
 
        if result{
            fileSaveSuccess(inFileName)
        }
        else{
            self.present(MyUtil.aleretView(inTitle: "", inMsg: "log_save_error".localized, intButtonStr: "close".localized), animated: true, completion: nil)
        }
    }
    
    func fileSaveSuccess(_ inFileName: String){
        fileName = inFileName
        
        let cancelbuttonStr = String("no".localized)
        let buttonStr = String("yes".localized)
             
        let dialog  = UIAlertController(title: "radon_data_save_success_title".localized, message: "radon_data_save_success_msg".localized, preferredStyle: .alert)
             
        let cancelButton  = UIAlertAction(title: cancelbuttonStr, style: .default)
        let okButton      = UIAlertAction(title: buttonStr, style: .default){(action: UIAlertAction) -> Void in
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destPath = dir.appendingPathComponent(BLEData.Config.barcode, isDirectory: true)
            self.fileUrl = destPath.appendingPathComponent(inFileName)
          
            print(self.tag + "fileUrl: \(String(describing: self.fileUrl))")
            
            MyStruct.fileUrl = self.fileUrl!
            MyStruct.fileName = self.fileName
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.logDataSave), object: nil)
        }
             
        dialog.addAction(cancelButton)
        dialog.addAction(okButton)
             
        present(dialog, animated: true) {
                 
        }
    }
    
    //MARK: - Chart Info
    
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet var viewChartInfo: UIView!
    @IBOutlet weak var labChartInfoDataNo: LableLocal!
    @IBOutlet weak var labAvg: UILabel!
    @IBOutlet weak var labMax: UILabel!
    @IBOutlet weak var labMin: UILabel!
    @IBAction func onClickChartInfoClose(_ sender: Any) {
        viewMain.alpha = 1
        self.navigationController?.navigationBar.alpha = 1
        viewChartInfo.removeFromSuperview()
    }
    
    //var checkboxinsDataUpload = CheckboxButton()
    func dialogChartInfo(){
        print(tag + "dialogChartInfo")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView(gesture:)))
        viewChartInfo.addGestureRecognizer(tapGesture)

        view.addSubview(viewChartInfo)
        viewMain.alpha = 0.3
        self.navigationController?.navigationBar.alpha = 0.3
        viewChartInfo.layer.shadowColor = UIColor.black.cgColor
        viewChartInfo.layer.shadowRadius = 5;
        viewChartInfo.layer.shadowOffset = CGSize(width: 2, height: 2)
        viewChartInfo.layer.shadowOpacity = 0.5
        viewChartInfo.center = CGPoint(x: view.frame.width / 2, y: (view.frame.height / 2) - 50)
        
        labChartInfoDataNo.text = String.init(format: "%d", BLEData.Log.radonValue.count)
        
        var maxValue = Float(BLEData.Log.radonValue.max() ?? 0)
        var minValue = Float(BLEData.Log.radonValue.min() ?? 0)
        
        let sumValue = BLEData.Log.radonValue.reduce(0, +)
        var avgValue = sumValue / Float(BLEData.Log.radonValue.count)
        
        //V1.5.0 - 20240723
        maxValue = MyUtil.radonValueReturn(MyStruct.v2Mode, maxValue, BLEData.Config.unit)
        minValue = MyUtil.radonValueReturn(MyStruct.v2Mode, minValue, BLEData.Config.unit)
        avgValue = MyUtil.radonValueReturn(MyStruct.v2Mode, avgValue, BLEData.Config.unit)
        
        if BLEData.Flag.V3_New && BLEData.Config.unit == 0{
            maxValue = MyUtil.newFwMinValue(inValue: maxValue)
            minValue = MyUtil.newFwMinValue(inValue: minValue)
            avgValue = MyUtil.newFwMinValue(inValue: avgValue)
        }
        
        labMax.attributedText = textRadonValue(inRadonValue: maxValue, inUnit: BLEData.Config.unit)
        labMin.attributedText = textRadonValue(inRadonValue: minValue, inUnit: BLEData.Config.unit)
        labAvg.attributedText = textRadonValue(inRadonValue: avgValue, inUnit: BLEData.Config.unit)
        
        /*for i in 0..<BLEData.Log.radonValue.count{
            //V1.2.0
            let radonValue = MyUtil.radonValueReturn(MyStruct.v2Mode, BLEData.Log.radonValue[i], BLEData.Config.unit)

            sumValue += radonValue
            
            if maxValue < radonValue
                maxValue = radonValue
            }
            
            if minValue > radonValue{
                minValue = radonValue
            }
        }*/
    }

    @objc func didTapView(gesture: UITapGestureRecognizer){
        view.endEditing(true)
    }
    
    func textRadonValue(inRadonValue: Float, inUnit: UInt8) -> NSMutableAttributedString{
        let valueStr = MyUtil.valueReturnString(inUnit, inRadonValue)
      
        let attributedText = NSMutableAttributedString(string: valueStr, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20),NSAttributedString.Key.foregroundColor: UIColor.black])
        attributedText.append(NSAttributedString(string: BLEData.Config.unitStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
        
        return attributedText
    }
    
    //MARK: - NOTIFICATION
    @objc func notificationChartUpdate(){
        print(tag + "notificationChartUpdate")
        labRefresh.isHidden = true
        lineChart.isHidden = false
        
        dtChartUpdate = Date()
        flagChartView = true
        imgChartInfo.isHidden = false
        labChartX.isHidden = false
        labSync.isHidden = false
        labChartUnit.text = String.init(format: "(%@)", BLEData.Config.unitStr)
        btnSave.backgroundColor = MyStruct.Color.tilt
        
        chartsControl.chartDraw(lineChart, BLEData.Log.radonValue, MyUtil.refUnit(inMove: MyStruct.v2Mode), Int(BLEData.Config.unit), Double(BLEData.Config.alarmValue), BLEData.Flag.V3_New)//받아온 값은 무조건 pci단위이므로 value unit은 0
    }
    
    @objc func notificationChartUpdateSync(){
        print(tag + "notificationChartUpdateSync, flagChartView: \(flagChartView)")
        if flagChartView{
            let nowDt = Date()
            let diff = nowDt.timeIntervalSince1970 - dtChartUpdate.timeIntervalSince1970
            let diffMin = diff / 60
            print(tag + "chartUpdateSync, nowDt: \(nowDt), ChartUpdate: \(dtChartUpdate), diff: \(diff), diffMin: \(diffMin)")
            if diffMin >= 1{
                 labSync.text = String.init(format: "Last synced %.0fmin ago", diffMin)
            }
        }
    }
}
