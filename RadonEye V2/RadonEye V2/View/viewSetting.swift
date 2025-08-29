//
//  viewSetting.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//


import UIKit

class viewSetting: UIViewController, UITextFieldDelegate {
    let tag = String("viewSetting - ")
    
    var bleController                       : BLEControl?
    var indicatorView                   = UIView()//progress bar
    
    
    @IBOutlet var viewMain: UIView!
    @IBOutlet weak var viewResetData: UIView!
    @IBOutlet weak var labUnitPci: LableLocal!
    @IBOutlet weak var imgUnitPci: UIImageView!
    @IBOutlet weak var viewUnitPci: UIView!
    @IBOutlet weak var labUnitBq: LableLocal!
    @IBOutlet weak var imgUnitBq: UIImageView!
    @IBOutlet weak var viewUnitBq: UIView!
  
    
    @IBOutlet weak var viewAlarmStatus: UIView!
    @IBOutlet weak var viewAlarmValue: UIView!
    @IBOutlet weak var swAlarm: UISwitch!
    @IBOutlet weak var teAlarmValue: UITextField!
    @IBOutlet weak var labAlarmValueUnit: UILabel!
    @IBOutlet weak var imgAlarmInterval: UIImageView!
    @IBOutlet weak var sgAlarmInterval: UISegmentedControl!
    
    @IBOutlet weak var constraintFwLabel: NSLayoutConstraint!
    @IBOutlet weak var viewAlarmIntervalTitle: UIView!
    @IBOutlet weak var viewAlarmInterval: UIView!
    
    @IBOutlet weak var viewFw: UIView!
    @IBOutlet weak var labFw: UILabel!
    
    var flagAlarmIntervalClick = Bool(false)
    var timerErrorCheck : Timer?
    var errorMsg = String("")
    var settingType = Int(0)
    
    //V1.2.0
    var settingFlag = [false, false]// Unit, Alram
    var logDataFileName = String("")
    var nowViewAlarmValue = String("")
    
    override func viewDidLoad() {
        //BLEData.Config.alarmValue = 4.0
        //BLEData.Config.version = "V1.2.4"
        
        
        MyUtil.printProcess(inMsg: tag + "viewDidLoad")
        super.viewDidLoad()
        navigationItem.title = "title_settings".localized
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.viewResetData.layer.addBorder([.top, .bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewUnitPci.layer.addBorder([.top, .bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewUnitBq.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
            
            self.teAlarmValue.layer.addBorder([.bottom], color: MyStruct.Color.tilt, width: 2.0)
            self.viewAlarmStatus.layer.addBorder([.top, .bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewAlarmValue.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewAlarmIntervalTitle.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewAlarmInterval.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
            
            self.viewFw.layer.addBorder([.top, .bottom], color: MyStruct.Color.border, width: 0.5)
        }
        
        viewResetData.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickClear)))
        viewUnitPci.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickUnitPci)))
        viewUnitBq.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickUnitBq)))
        
        imgAlarmInterval.isUserInteractionEnabled = true
        imgAlarmInterval.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickAlarmInterval)))
        
        constraintFwLabel.constant = (0 - viewAlarmIntervalTitle.frame.height) + 30
        viewAlarmInterval.isHidden = true
        
        labFw.text = BLEData.Config.version
        settingUiUpdate()
        
        let buttonRight = UIButton(type: .system)
        buttonRight.frame = CGRect(x: 0.0, y: 0.0, width: 10, height: 10)
        buttonRight.tintColor = MyStruct.Color.tilt
        buttonRight.setTitle("Done", for: .normal)
        buttonRight.addTarget(self, action: #selector(onClickDone), for: .touchUpInside)
        let rightBarButton = UIBarButtonItem(customView: buttonRight)
        self.navigationItem.rightBarButtonItem  = rightBarButton
        
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        toolBar.barStyle = UIBarStyle.default
        toolBar.items = [
            UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelPressed)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePressed))
        ]
              
        teAlarmValue.keyboardType = .decimalPad
        teAlarmValue.inputAccessoryView = toolBar
        teAlarmValue.returnKeyType = .done
        teAlarmValue.delegate = self
        
        //V1.2.0 - 최초 현재 설정된 값을 대입
        BLEData.Config.unitSet = BLEData.Config.unit
        BLEData.Config.alarmStatusSet = BLEData.Config.alarmStatus
        BLEData.Config.alarmValueSet = BLEData.Config.alarmValue
        BLEData.Config.alarmIntervalSet = BLEData.Config.alarmInterval
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillAppear")
        super.viewWillAppear(animated)
        bleController?.delegateSetting(delegate: self)
    }


    override func viewWillDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillDisappear")
        super.viewWillDisappear(animated)
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewDidDisappear")
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        //V0.1.2
        bleController?.delegateSettingInit()
    }
    
    
    override func didReceiveMemoryWarning() {
        MyUtil.printProcess(inMsg: tag + "didReceiveMemoryWarning")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Setting Prcoess
    func settingUnilt(){
        print(tag + "settingUnilt")
        settingType = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var sData = [UInt8]()
            sData.append(BLEData.Config.unitSet)
            self.bleController?.bleSendData(cmd: BLECommnad.cmd_BLE_RD200_UNIT_Set, size: sData.count, data: sData)
        }
    }
    
    func settingAlarm(){
        print(tag + "settingAlarm")
        settingType = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var sData = [UInt8]()
            sData.append(BLEData.Config.alarmStatusSet)
            
            //alarm value
            if MyStruct.v2Mode{//ESP32 = Bq
                let data = MyUtil.uint16ConverByteArray(inValue: UInt16(BLEData.Config.alarmValueSet))
                sData.append(data[0])
                sData.append(data[1])
            }
            else{//NORDIC = pCi
                let data = MyUtil.floatConverByteArray(inValue: BLEData.Config.alarmValueSet)
                sData.append(data[0])
                sData.append(data[1])
                sData.append(data[2])
                sData.append(data[3])
            }
            sData.append(BLEData.Config.alarmIntervalSet)
            
            self.bleController?.bleSendData(cmd: BLECommnad.cmd_BLE_WARNING_SET, size: sData.count, data: sData)
        }
    }

    @objc func onClickDone(){
        print(tag + "onClickDone")
        
        var alarValue = Float(self.teAlarmValue.text!)
        if alarValue == nil{
            alarValue = 0
        }
        
        //status
        BLEData.Config.alarmStatusSet = self.swAlarm.isOn ? 1:0
        
        //value
        if BLEData.Config.unitSet == 0{
            if alarValue! < Float(0.1) || alarValue! > Float(100.0){
                self.aleretView(inTitle: "warning".localized, inMsg: "setting_alarm_value_pci".localized, intButtonStr: "close".localized)
                return
            }
        }
        else{
            if alarValue! < Float(1) || alarValue! > Float(3700){
                self.aleretView(inTitle: "warning".localized, inMsg: "setting_alarm_value_bq".localized, intButtonStr: "close".localized)
                return
            }
        }
        
        //1.2.0
        if teAlarmValue.text != nowViewAlarmValue{//단위 변경해서 알람값이 바뀐게 아닌 사람이 직접 바꿨는지 확인하기 위해서
            BLEData.Config.alarmValueSet = MyUtil.alarmValueReturn(MyStruct.v2Mode, alarValue!, BLEData.Config.unitSet)
            if !MyStruct.v2Mode{
                BLEData.Config.alarmValueSet = round(BLEData.Config.alarmValueSet * 10) / 10
            }
        }

        MyUtil.printProcess(inMsg: self.tag + "setValue: \(BLEData.Config.alarmValueSet)")
        
        //inverval
        if self.sgAlarmInterval.selectedSegmentIndex == 0{
            BLEData.Config.alarmIntervalSet = 1
        }
        else if self.sgAlarmInterval.selectedSegmentIndex == 1{
            BLEData.Config.alarmIntervalSet = 6
        }
        else{
            BLEData.Config.alarmIntervalSet = 36
        }
        
        //Unit V1.2.0 - Done 클릭 시, 유닛과 알람 동시에 적용
        if BLEData.Config.unit == BLEData.Config.unitSet{
           settingFlag[0] = false
        }
        else{
            settingFlag[0] = true
        }
        
        //Alarm
        var alarmCheck = Int(0)
        if BLEData.Config.alarmStatus != BLEData.Config.alarmStatusSet{
            alarmCheck += 1
        }
        
        if BLEData.Config.alarmValue != BLEData.Config.alarmValueSet{
            alarmCheck += 1
        }
        
        if BLEData.Config.alarmInterval != BLEData.Config.alarmIntervalSet{
            alarmCheck += 1
        }
        
        if alarmCheck == 0{
            settingFlag[1] = false
        }
        else{
            settingFlag[1] = true
        }
        
        //V2.0.0 알람 설정 변화 없으면 그냥 나감
        if !settingFlag[0] && !settingFlag[1]{
            self.navigationController?.popViewController(animated: true)
        }
        else{
            if settingFlag[0]{//unit
                indicatorView("device_setting".localized)
                errorMsg = "device_setting_fail".localized
                
                timerErrorCheck = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(bleDataErrorCheck), userInfo: nil, repeats: false)
   
                settingUnilt()
            }
            else if settingFlag[1]{
                indicatorView("device_setting".localized)
                errorMsg = "device_setting_fail".localized
                
                timerErrorCheck = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(bleDataErrorCheck), userInfo: nil, repeats: false)
   
                settingAlarm()
            }
        }
    }
    
    
    @objc func onClickUnitPci(_ sender:UIGestureRecognizer){
        print(tag + "onClickUnitPci")
        BLEData.Config.unitSet = 0
        unitViewChange(setUnit: BLEData.Config.unitSet)
    }
    
    @objc func onClickUnitBq(_ sender:UIGestureRecognizer){
        print(tag + "onClickUnitBq")
        BLEData.Config.unitSet = 1
        unitViewChange(setUnit: BLEData.Config.unitSet)
    }
    
    func unitViewChange(setUnit: UInt8){
        if setUnit == 0{
            if MyStruct.v2Mode{
                teAlarmValue.text = String.init(format: "%.1f", Float(BLEData.Config.alarmValue) / 37)//V0.1.4 소수점 한자리
            }
            else{
                teAlarmValue.text = String.init(format: "%.1f", BLEData.Config.alarmValue)//V0.1.4 소수점 한자리
            }
            
            labAlarmValueUnit.text = "unit_pico".localized
            
            labUnitPci.textColor = UIColor.black
            imgUnitPci.isHidden = false
            
            labUnitBq.textColor = MyStruct.Color.hexADADAD
            imgUnitBq.isHidden = true
        }
        else{
            if MyStruct.v2Mode{
                teAlarmValue.text = String.init(format: "%.0f", BLEData.Config.alarmValue)//V0.1.4 소수점 한자리
            }
            else{
                teAlarmValue.text = String.init(format: "%.0f", BLEData.Config.alarmValue * 37)//V0.1.4 소수점 한자리
            }
            
            labAlarmValueUnit.text = "unit_bq".localized
            
            labUnitBq.textColor = UIColor.black
            imgUnitBq.isHidden = false
            
            labUnitPci.textColor = MyStruct.Color.hexADADAD
            imgUnitPci.isHidden = true
        }
        
        nowViewAlarmValue = teAlarmValue.text ?? ""
    }
    
    func settingUiUpdate(){
        let alarmValue = MyUtil.alarmValueViewReturn(MyStruct.v2Mode, BLEData.Config.alarmValue, BLEData.Config.unit)
        
        if BLEData.Config.unit == 0{
            teAlarmValue.text = String.init(format: "%.1f", alarmValue)
            labAlarmValueUnit.text = "unit_pico".localized
            
            labUnitPci.textColor = UIColor.black
            imgUnitPci.isHidden = false
            
            labUnitBq.textColor = MyStruct.Color.hexADADAD
            imgUnitBq.isHidden = true
        }
        else{
            teAlarmValue.text = String.init(format: "%.0f", alarmValue)
            labAlarmValueUnit.text = "unit_bq".localized
            
            labUnitBq.textColor = UIColor.black
            imgUnitBq.isHidden = false
            
            labUnitPci.textColor = MyStruct.Color.hexADADAD
            imgUnitPci.isHidden = true
        }
        
        swAlarm.isOn = (BLEData.Config.alarmStatus != 0)
        if BLEData.Config.alarmInterval == 1{
            sgAlarmInterval.selectedSegmentIndex = 0
        }
        else  if BLEData.Config.alarmInterval == 6{
            sgAlarmInterval.selectedSegmentIndex = 1
        }
        else{
            sgAlarmInterval.selectedSegmentIndex = 2
        }
        
        //V1.2.0
        nowViewAlarmValue = teAlarmValue.text ?? ""
    }

    
    @objc func bleDataErrorCheck(){
        print(tag + "bleDataErrorCheck")
        BLEData.Flag.dataClear = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.indicatorView.removeFromSuperview()
            self.aleretView(inTitle: "Notice", inMsg: self.errorMsg, intButtonStr: "close".localized)
       }
    }
        
    @objc func onClickAlarmInterval(_ sender:UIGestureRecognizer){
        print(tag + "onClickAlarmInterval")
        
        if flagAlarmIntervalClick == false{
            imgAlarmInterval.image = #imageLiteral(resourceName: "navigate-up-arrow")
            constraintFwLabel.constant = (0 - viewAlarmIntervalTitle.frame.height) + 80
            viewAlarmInterval.isHidden = false
        }
        else{
            imgAlarmInterval.image = #imageLiteral(resourceName: "arrow-down-sign-to-navigate (1)")
            constraintFwLabel.constant = (0 - viewAlarmIntervalTitle.frame.height) + 30
            viewAlarmInterval.isHidden = true
        }
        
        flagAlarmIntervalClick = !flagAlarmIntervalClick
    }
    
    //MARK:- Data Reset
    @objc func onClickClear(_ sender:UIGestureRecognizer){
        print(tag + "onClickClear")
    
        if BLEData.Log.dataNo == 0{//데이터가 없으므로 바로 세팅 진행
            BLEData.Flag.onlyDataReset = false

            //V0.1.3
            let dialog = UIAlertController(title: "resetdata_no_data".localized, message: "", preferredStyle: .alert)
            let action = UIAlertAction(title: "Close", style: UIAlertAction.Style.default)
            dialog.addAction(action)

            action.titleTextColor = .red
            self.present(dialog, animated: true, completion: nil)
        }
        else{
            self.alertDataReset()
        }
    }
    
    func resetProcess(){
        BLEData.Flag.dataClear = true
        self.errorMsg = "data_clear_failed".localized
        self.timerErrorCheck = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.bleDataErrorCheck), userInfo: nil, repeats: false)
        self.bleController?.bleSendData(cmd: BLECommnad.cmd_EEPROM_LONG_DATA_CLEAR)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {//자동 리턴이 없으므로 확인해야 함
            if MyStruct.v2Mode{
                self.bleController?.bleSendData(cmd: BLECommnad.cmd_BLEV2_QUERY_ALL)
            }
            else{
                self.bleController?.bleSendData(cmd: BLECommnad.cmd_EEPROM_LOG_INFO_QUERY)
            }
        }
    }
    
    func alertDataReset(){
        let dialog = UIAlertController(title: "clear".localized, message: "data_clear".localized, preferredStyle: .alert)
        
        let actionYes = UIAlertAction(title: "data_clear_yes".localized, style: .default){(action: UIAlertAction) -> Void in
            self.logFileSaveNameInput()
        }
     
        let actionNo = UIAlertAction(title: "data_clear_no".localized, style: .default){(action: UIAlertAction) -> Void in
            self.indicatorView("Clear data..")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.resetProcess()
            }
        }
        let actionCancel = UIAlertAction(title: "cancel".localized, style: .default){(action: UIAlertAction) -> Void in
            BLEData.Flag.onlyDataReset = false
        }
        actionYes.titleTextColor = UIColor.black
        actionNo.titleTextColor = UIColor.black
        actionCancel.titleTextColor = UIColor.red

        dialog.addAction(actionYes)
        dialog.addAction(actionNo)
        dialog.addAction(actionCancel)
        
        self.present(dialog, animated: true, completion: nil)
    }
    
    func logFileSaveNameInput(){
        let titleStr = String("Save Log Data")
        let cancelbuttonStr = String("cancel".localized)
        let buttonStr = String("save".localized)
               
        let dialog  = UIAlertController(title: titleStr, message: "", preferredStyle: .alert)
        dialog.addTextField(configurationHandler: {(textField : UITextField!) -> Void in
            textField.placeholder = MyUtil.logDataFileName()
            textField.delegate = self as UITextFieldDelegate
        })
               
        let cancelButton  = UIAlertAction(title: cancelbuttonStr, style: .default){(action: UIAlertAction) -> Void in
            BLEData.Flag.onlyDataReset = false
        }
        
        let okButton      = UIAlertAction(title: buttonStr, style: .default){(action: UIAlertAction) -> Void in
            let loginTextField          = dialog.textFields![0].text//사용자가 입력한 값이 있는지 확인
            if loginTextField == ""{//입력한 값이 없으면 기본 값 사용
                self.logDataFileName          = dialog.textFields![0].placeholder! + ".txt"
            }
            else{//입력한 값이 있으면 .txt 확장자 붙여서 사용
                self.logDataFileName          = dialog.textFields![0].text! + ".txt"
            }
            print("logDataSaveAs - \(String(describing: self.logDataFileName ))")
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.indicatorView.removeFromSuperview()
                self.indicatorView("log_waiting".localized)
            }
           
            BLEData.Log.rawData.removeAll()//0.1.1
            if MyStruct.v2Mode{
                self.bleController?.bleSendData(cmd: BLECommnad.cmd_BLEV2_LOG_SEND)
            }
            else{
                self.bleController?.bleSendData(cmd: BLECommnad.cmd_EEPROM_LOG_INFO_QUERY)
            }
        }
               
        dialog.addAction(cancelButton)
        dialog.addAction(okButton)
               
        present(dialog, animated: true) {
                   
        }
    }
    
    func logFileSaveProcess(_ inFileName: String){
        let result = MyFileManager.logFileSaveProcess(BLEData.Config.barcode, inFileName, BLEData.Log.radonValue, MyUtil.refUnit(inMove: MyStruct.v2Mode), BLEData.Config.unit, BLEData.Config.alarmValue)
 
        if !result{
            self.present(MyUtil.aleretView(inTitle: "", inMsg: "log_save_error".localized, intButtonStr: "close".localized), animated: true, completion: nil)
        }
    }
    
    
    //MARK:- UTIL
    func indicatorView(_ title: String) {
        //let str = MyUtil.stringLocal(title)
        //print(tag + "indicatorView: \(view.frame), self.view.center: \(self.view.center)")
        indicatorView.removeFromSuperview()
        indicatorView = MyUtil.activityIndicator(self.view, title)
        view.addSubview(indicatorView)
    }
    
    func aleretView(inTitle: String, inMsg: String, intButtonStr: String){
        let dialog = UIAlertController(title: inTitle, message: inMsg, preferredStyle: .alert)
        let action = UIAlertAction(title: intButtonStr, style: UIAlertAction.Style.default)
        dialog.addAction(action)
        self.present(dialog, animated: true, completion: nil)
    }
    
    func timerStop(){
        if timerErrorCheck != nil{
            timerErrorCheck?.invalidate()
            timerErrorCheck = nil
        }
    }
    
    //MARK:- TextField
    @objc func keyboardWillHide(_ sender: Notification) {
        print("viewLoginController keyboardWillHide")
        viewMain.frame.origin.y = 0
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
        print("viewLoginController keyboardWillShow")
        let mSize = viewMain.frame.size.height - viewAlarmValue.frame.origin.y + 50
        
        let userInfo:NSDictionary = sender.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        if mSize < keyboardHeight{
             viewMain.frame.origin.y = -50
        }
    }
    
    @objc func cancelPressed(sender: UIBarButtonItem) {
        teAlarmValue.resignFirstResponder()
    }
       
    @objc func donePressed(sender: UIBarButtonItem) {
        teAlarmValue.resignFirstResponder()
    }
    
    
    //MARK: - Log Download
    var timerLodDownload : Timer?
    var indicatorLabel                  = UILabel()
       
    func timerLogDownloadStartSetting(){
        BLEData.Log.recPercent = 0
        indicatorView.removeFromSuperview()
        activityIndicatorForLog("0%")
        timerLodDownload = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(logdDownloadPercentView), userInfo: nil, repeats: true)
    }
    
    func timerLogDownloadStart(){
        BLEData.Log.recPercent = 0
        indicatorView.removeFromSuperview()
        activityIndicatorForLog("0%")
        timerLodDownload = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(logdDownloadPercentView), userInfo: nil, repeats: true)
    }
    
    func timerLogDownloadStop(){
        indicatorView.removeFromSuperview()
        timerLodDownload?.invalidate()
        timerLodDownload = nil
    }
       
    @objc func logdDownloadPercentView(){
        indicatorLabel.text = String.init(format: "%.0f%@", BLEData.Log.recPercent, "%")
    }
    
    func activityIndicatorForLog(_ title: String) {
        let str = title
           
        var viewHeight = 160
        if str.count <= 20{
            viewHeight = 110
        }
        else if str.count <= 40{
            viewHeight = 130
        }
           
        indicatorLabel.removeFromSuperview()
        indicatorView.removeFromSuperview()
           
        let widthData = self.view.frame.width * 0.6
           
        indicatorView = UIView(frame: CGRect(x: 0, y: 0, width: Int(widthData), height: viewHeight))
           
        let refCenter = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2)
        indicatorView.center = refCenter
        indicatorView.backgroundColor = UIColor.black
        indicatorView.alpha = 0.9
        indicatorView.layer.cornerRadius = 10
           
        // Spin config:
        let activityView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        activityView.color = .white
        activityView.frame = CGRect(x: (widthData / 2) - 25, y: 15, width: 50, height: 50)
        activityView.startAnimating()
           
        // Text config:
        indicatorLabel = UILabel(frame: CGRect(x: 0, y: 40, width: widthData, height: 80))
        indicatorLabel.textColor = UIColor.white
        indicatorLabel.textAlignment = .center
        indicatorLabel.font = UIFont.boldSystemFont(ofSize: 15)
        indicatorLabel.numberOfLines = 0
        indicatorLabel.text = str
           
        // Activate:
        indicatorView.addSubview(activityView)
        indicatorView.addSubview(indicatorLabel)
        view.addSubview(indicatorView)
           
        print("viewSetting - activityIndicator")
    }
}


 //MARK:- MonitorTabDelegate
extension viewSetting: SettingDelegate {
    func dataClear() {
        print(tag + "dataClear")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.indicatorView.removeFromSuperview()
            self.timerStop()
        }
    }
    
    func configDataReturn() {
        print(tag + "configDataReturn, type: \(settingType)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.settingType == 0{//unit setting
                print(self.tag + "configDataReturn, set: \(BLEData.Config.unitSet), read: \(BLEData.Config.unit)")
                if BLEData.Config.unit == BLEData.Config.unitSet{
                    if self.settingFlag[1]{//V1.2.0
                        self.settingAlarm()
                    }
                    else{
                        self.indicatorView.removeFromSuperview()
                        self.timerStop()
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                else{
                    self.aleretView(inTitle: "Notice", inMsg: self.errorMsg, intButtonStr: "close".localized)
                }
            }
            else{
                print(self.tag + "configDataReturn, alram set: \(BLEData.Config.alarmStatusSet), alram read: \(BLEData.Config.alarmStatus), alram value set: \(BLEData.Config.alarmValueSet), alram value read: \(BLEData.Config.alarmValue), alram interval set: \(BLEData.Config.alarmIntervalSet), alram interval read: \(BLEData.Config.alarmInterval)")
                
                var errCount = Int(0)
                
                if BLEData.Config.alarmStatusSet != BLEData.Config.alarmStatus{
                    errCount += 1
                }
                if BLEData.Config.alarmValueSet != BLEData.Config.alarmValue{
                    errCount += 1
                }
                if BLEData.Config.alarmIntervalSet != BLEData.Config.alarmInterval{
                    errCount += 1
                }
                
                self.indicatorView.removeFromSuperview()
                self.timerStop()
                if errCount == 0{
                    self.navigationController?.popViewController(animated: true)
                }
                else{
                    self.aleretView(inTitle: "Notice", inMsg: self.errorMsg, intButtonStr: "close".localized)
                }
            }
        }
    }
    
    //V1.2.0
    func rawLogDataReturnForSettingView(_ inData:[UInt8]){
        print(self.tag + "rawLogDataReturnForSettingView, inData count: \(inData.count)")
        
        self.logFileSaveProcess(logDataFileName)
        self.timerStop()
        self.timerLogDownloadStop()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.resetProcess()
        }
    }
    
    func recLogDataStartSetting(){
        timerLogDownloadStartSetting()
    }
}


extension UIAlertAction {
    var titleTextColor: UIColor? {
        get {
            return self.value(forKey: "titleTextColor") as? UIColor
        } set {
            self.setValue(newValue, forKey: "titleTextColor")
        }
    }
}
