//
//  viewLanch.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/06.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import Foundation
import CoreBluetooth
import UserNotifications
import SideMenu
import XLPagerTabStrip

class viewTabTop: ButtonBarPagerTabStripViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    let tag = String("viewTabTop - ")
    
    var flagScanMode            = Bool(false)//마지막 이력이 있으면 자동으로 스캔해서 장비 연결
    var savedDeviceName         = String("")
    var indicatorView               = UIView()
    var bleCheckCount           = Int(0)
    var bleQueryCount = Bool(false)
    
    //MARK: - BLE
    var bluetoothManager        : CBCentralManager?
    var connectedPeripheral     : CBPeripheral?
    var bleController           : BLEControl?
    private var blePeripheral : BLEControl!
    
    var timerScan                   : Timer?
    var timer                       : Timer?
    var timerCount                  = Int(0)
    var timerForLog                 : Timer?
    var timerForLogError            : Timer?
    var flagMoveSetting     = Bool(false)
    
    var fileUrl : URL?
    var fileName = String("")
    var flagBleConnect = Bool(false)
    
    //MARK: - UIViewControllerDelegate
    var files                           : NSArray?
    var flagLogClick = Bool(false)
    
    override func viewDidLoad() {
        print(tag + "viewDidLoad, flagScanMode: \(flagScanMode)")
        navigationItem.title = "app_name".localized
        
        MyStruct.bleStatus = true
        MyStruct.bleDisconnectinoTime = 0
        
        // change selected bar color
        settings.style.buttonBarBackgroundColor = UIColor.white
        settings.style.buttonBarItemBackgroundColor = UIColor.white
        settings.style.selectedBarBackgroundColor = MyStruct.Color.tilt
        settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 18)
        settings.style.selectedBarHeight = 3.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = .black
        settings.style.buttonBarItemsShouldFillAvailableWidth = true

        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = MyStruct.Color.hexC3C3C3
            newCell?.label.textColor = .black
        }
        
        navigationItem.title = "app_name".localized
        
        //bar item
        let buttonLeft = UIButton(type: .system)
        buttonLeft.frame = CGRect(x: 0.0, y: 0.0, width: 10, height: 10)
        buttonLeft.tintColor = UIColor.black
        buttonLeft.setImage(#imageLiteral(resourceName: " menu-left"), for: .normal)
        buttonLeft.addTarget(self, action: #selector(sideMenuClick), for: .touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: buttonLeft)
        self.navigationItem.leftBarButtonItem  = leftBarButton
        
        let buttonRight = UIButton(type: .system)
        buttonRight.frame = CGRect(x: 0.0, y: 0.0, width: 10, height: 10)
        buttonRight.tintColor = UIColor.black
        buttonRight.setImage(#imageLiteral(resourceName: " settings"), for: .normal)
        buttonRight.addTarget(self, action: #selector(deviceSettingClick), for: .touchUpInside)
        let rightBarButton = UIBarButtonItem(customView: buttonRight)
        self.navigationItem.rightBarButtonItem  = rightBarButton
        
       /* let buttonDFU = UIButton(type: .system)
        buttonDFU.frame = CGRect(x: 0.0, y: 0.0, width: 10, height: 10)
        buttonDFU.tintColor = UIColor.black
        buttonDFU.setTitle("DFU", for: .normal)
        buttonDFU.addTarget(self, action: #selector(dfuAlret), for: .touchUpInside)
        let rightBarButtonDFU = UIBarButtonItem(customView: buttonDFU)
        self.navigationItem.rightBarButtonItems  = [rightBarButton, rightBarButtonDFU]*/
        
        //progressbar
        indicatorView("msg_connecting".localized)
        
        self.timerScan = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.timerDeviceCheck), userInfo: nil, repeats: false)

        let centralQueue = DispatchQueue(label: "kr.ftlab.radoneye.RaonEye", attributes: [])
        bluetoothManager = CBCentralManager(delegate: self, queue: centralQueue)
        
        super.viewDidLoad()
    }
    
    @objc func sideMenuClick(){
        print(tag + "sideMenuClick")
        self.performSegue(withIdentifier: "goSideMenu", sender: nil)
    }
    
    @objc func deviceSettingClick(){
        print(tag + "deviceSettingClick")
        
       if flagBleConnect{
            flagMoveSetting = true
            self.performSegue(withIdentifier: "goSetting", sender: nil)
        }
        else{
            alertViewDisconnect()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print(tag + "viewWillAppear, \(flagMoveSetting)")
        
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.barTintColor = UIColor.white
        
        if flagMoveSetting{
            timerStart()
            navigationItem.title = BLEData.Config.barcode
        }
        
        flagMoveSetting = false
        MyStruct.uiMode = 1
        if bleController != nil{
            bleController?.delegateMonitorTabInit(delegate: self)
        }
    
        let mSideMenu = SideMenu()
        mSideMenu.setupSideMenu(inSb: storyboard!, inNavigation: navigationController!.navigationBar, inMainVeiw: view, inSubView: view)
        
        NotificationCenter.default.addObserver(self,selector: #selector(notificationLogDownStart),name: NSNotification.Name(MyStruct.notiName.logDownStart),object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(notificationLogDataSave),name: NSNotification.Name(MyStruct.notiName.logDataSave),object: nil)
            
        NotificationCenter.default.addObserver(self,selector: #selector(notificationSidMenu),name: NSNotification.Name(MyStruct.notiName.monitor),object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(notificationGoFileList),name: NSNotification.Name(MyStruct.notiName.monitorFileList),object: nil)
        
        NotificationCenter.default.addObserver(self,selector: #selector(popUpView),name: NSNotification.Name(UiConstants.notiName.popUpView),object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(popUpDismiss),name: NSNotification.Name(UiConstants.notiName.popUpDismiss),object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print(tag + "viewWillDisappear, \(flagMoveSetting)")
        timerStop()
        
        navigationItem.title = ""
        
        if !flagMoveSetting{
            bleController?.disConnect()
        }
        
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(MyStruct.notiName.monitor), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(MyStruct.notiName.monitorFileList), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(MyStruct.notiName.logDownStart), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(MyStruct.notiName.logDataSave), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(UiConstants.notiName.popUpView), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(UiConstants.notiName.popUpDismiss),object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goSideMenu" {
            guard let sideMenuNavigationController = segue.destination as? SideMenuNavigationController else { return }
            let mSideMenu = SideMenu()
            sideMenuNavigationController.settings = mSideMenu.makeSettings(inMainVeiw: view)
        }
        else if segue.identifier == "goSetting" {
            let settingController = segue.destination as! viewSetting
            settingController.bleController = bleController!
        }//
        else if segue.identifier == "goLogDataView" {
            let logViewController = segue.destination as! viewSaveLogView
            logViewController.fileUrl = fileUrl
            logViewController.fileName = fileName
        }
    }
    
    // MARK: - PagerTabStripDataSource
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let child_1 = storyboard.instantiateViewController(withIdentifier: "viewTabRadon") as! viewMonitorRadon
        let child_2 = storyboard.instantiateViewController(withIdentifier: "viewTabData") as! viewMonitorData
        return [child_1, child_2]
    }

    //MARK: - NOTIFICATION
    @objc func notificationLogDownStart(){
        print(tag + "\(Date()) notificationLogDownStart,  flagBleConnect: \(flagBleConnect)")
        if flagBleConnect{//ble연결이 정상일때만 실행
            if flagLogClick == false{
                
                //V1.2.0
                BLEData.Log.recPercent = 0
                BLEData.Log.rawData.removeAll()
                if MyStruct.v2Mode{//뉴모델은 실시간 로그 데이터 넘버 동기화 가능
                    if BLEData.Log.dataNo == 0{
                        aleretView(inTitle: "Notice", inMsg: "log_data_no_data".localized, intButtonStr: "close".localized)
                    }
                    else{
                        flagLogClick = true
                        DispatchQueue.main.async {
                            self.indicatorView("log_waiting".localized)
                        }
                        bleDataSendProcess(cmd: BLECommnad.cmd_BLEV2_LOG_SEND)
                    }
                }
                else{
                    flagLogClick = true
                    DispatchQueue.main.async {
                        self.indicatorView("log_waiting".localized)
                    }
                    
                    bleDataSendProcess(cmd: BLECommnad.cmd_EEPROM_LOG_INFO_QUERY)
                }
                
                if flagLogClick{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10){
                        //if BLEData.Log.recPercent == 0{
                        if BLEData.Log.recPercent == 0 && BLEData.Log.dataNo > 0{//V1.2.0
                            self.flagLogClick = false
                            self.indicatorView.removeFromSuperview()
                            self.aleretView(inTitle: "Error", inMsg: "log_waiting_error".localized, intButtonStr: "Close")
                        }
                    }
                }
            }
        }
        else{
            alertViewDisconnect()
        }
    }
    
    @objc func notificationLogDataSave(){
        print(tag + "notificationLogDataSave")
        print(tag + "goLogFileVew, inFileUrl: \(MyStruct.fileUrl), inFIleName: \(MyStruct.fileName)")
        flagMoveSetting = true
        
        fileUrl = MyStruct.fileUrl
        fileName = MyStruct.fileName
        performSegue(withIdentifier: "goLogDataView", sender: nil)
    }
    
    @objc func notificationSidMenu(){
        print(tag + "notificationSidMenu")
        timerStop()
        bleController?.disConnect()
        
        UserDefaults.standard.removeObject(forKey: MyStruct.Key.lastDeviceName)
        self.performSegue(withIdentifier: "goDeviceList", sender: nil)
    }
       
    @objc func notificationGoFileList(){
        print(tag + "notificationGoFileList")
        timerStop()
        flagMoveSetting = true
    }
       
    //MARK: - CBCentralManagerDelegate
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MyUtil.printProcess(inMsg: tag + "centralManager 2")//필수
           
        let deviceUUID      = CBUUID(string: MyStruct.deviceUUIDString)
        connectedPeripheral = peripheral
        peripheral.discoverServices([deviceUUID])
    }
       
       func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
           // Scanner uses other queue to send events. We must edit UI in the main queue
           MyUtil.printProcess(inMsg: tag + "centralManager didFailToConnect")
           DispatchQueue.main.async(execute: {
               self.aleretView(inTitle: "detial_ble_connection_fail_title", inMsg: "detial_ble_connection_fail", intButtonStr: "close_msg")
               self.connectedPeripheral = nil
           })
       }
       
       func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
           MyUtil.printProcess(inMsg: tag + "centralManager disconnect")//연결 실패 시
           timerStop()
           // Scanner uses othecentralManagerr queue to send events. We must edit UI in the main queue
           DispatchQueue.main.async(execute: {
               NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
               NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
               
               if self.connectedPeripheral != nil{
                   self.connectedPeripheral = nil
                   self.aleretView(inTitle: "ble_disconnection_title".localized, inMsg: "ble_disconnection".localized, intButtonStr: "close".localized)
               }
           })
       }
       
       
       //MARK: - Timer
       func timerStart(){
           print(tag + "timerStart")
           timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(bleDataQueryProcess), userInfo: nil, repeats: true)
       }
       
       func timerStop(){
           timer?.invalidate()
           timer = nil
       }
  
       
       //MARK:- UTIL
       func errorMsgView(inMsg: String){
           indicatorView.removeFromSuperview()
           aleretView(inTitle: "", inMsg: inMsg, intButtonStr: "close".localized)
       }
       
       func indicatorView(_ title: String) {
           //let str = MyUtil.stringLocal(title)
           print(tag + "indicatorView: \(view.frame), self.view.center: \(self.view.center)")
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
      
    @objc func bleDataQueryProcess(){
        if MyStruct.v2Mode{
            bleController?.bleSendData(cmd: BLECommnad.cmd_BLEV2_QUERY_ALL)
        }
        else{
            bleQueryCount = !bleQueryCount

            if bleQueryCount{
                bleController?.bleSendData(cmd: BLECommnad.cmd_MEAS_QUERY)
            }
            else {
                bleController?.bleSendData(cmd: BLECommnad.cmd_BLE_STATUS_QUERY)
            }
        }
    }
       
    func goLogFileVew(inFileUrl: URL, inFIleName: String){
       print(tag + "goLogFileVew, inFileUrl: \(inFileUrl), inFIleName: \(inFIleName)")
       flagMoveSetting = true
       
       fileUrl = inFileUrl
       fileName = inFIleName
       performSegue(withIdentifier: "goLogDataView", sender: nil)
    }

    func keepBleConnection(inFlag: Bool){
       print(tag + "keepBleConnection: \(inFlag)")
       flagMoveSetting = inFlag
    }

    //MARK:- BLE Send
    func bleDataSendProcess(cmd: UInt8){
       print(tag + "bleDataSendProcess: \(cmd)")
       timerStop()
       
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           self.bleController?.bleSendData(cmd: cmd)
       }
    }
       
    //MARK:- BLE SCAN
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(tag + "centralManagerDidUpdateState, \(flagScanMode)")
           
        guard central.state == .poweredOn else {
            DispatchQueue.main.async {
                let title = "ble_off_title".localized
                let msg = "ble_off_msg".localized
                let buttonStr = "close".localized
                
                let dialog = UIAlertController(title: title, message: msg, preferredStyle: .alert)
                let action = UIAlertAction(title: buttonStr, style: UIAlertAction.Style.default)
                dialog.addAction(action)
                self.present(dialog, animated: true, completion: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.indicatorView.removeFromSuperview()
                }
            }
            return
        }
        
        //device list에서 왔을떄 실행 안함
        if flagScanMode{
            flagScanMode = false
            let success = self.scanForPeripherals(true)
            if !success {
                print("Bluetooth is off!")
            }
        }
    }
       
    func scanForPeripherals(_ enable:Bool) -> Bool {
        guard bluetoothManager?.state == .poweredOn else {
            return false
        }
              
        DispatchQueue.main.async {
            if enable == true {
                print(self.tag + "scanForPeripherals")
                let options: NSDictionary = NSDictionary(objects: [NSNumber(value: true as Bool)], forKeys: [CBCentralManagerScanOptionAllowDuplicatesKey as NSCopying])
                      
                //self.bluetoothManager?.scanForPeripherals(withServices: [ CBUUID(string: MyStruct.deviceUUIDString), CBUUID(string: MyStruct.dfuUUIDString)], options: options as? [String : AnyObject])
                //V1.2.0
                self.bluetoothManager?.scanForPeripherals(withServices: nil, options: options as? [String : AnyObject])
            }
            else {
                self.timerScan?.invalidate()
                self.timerScan = nil
                    self.bluetoothManager?.stopScan()
            }
        }
        return true
    }
       
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
           
        //local 이름 변경
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String

        DispatchQueue.main.async(execute: {
            if localName == nil{
                return
            }
               
            var flagCheck = false;
            let range = localName?.range(of: self.savedDeviceName)
               
            if range != nil{
                if localName != nil{
                    flagCheck = true
                }
            }
               
            if(flagCheck){
                MyStruct.v3Mode = false
                
                let firstIndex = localName?.index(localName!.startIndex, offsetBy: 7)
                let lastIndex = localName?.index(localName!.startIndex, offsetBy: 9)
                let findStr = String(localName?[firstIndex!..<lastIndex!] ?? "")
 
                print(self.tag + "centralManager flagCheck")
                self.timerScan?.invalidate()
                self.timerScan = nil
                self.bluetoothManager!.stopScan()
                
                if findStr == "RE"{
                    MyStruct.v3Mode = true
                }
                   
                BLEData.Init.enable = true
                self.connectedPeripheral = peripheral
                self.bleController = BLEControl(withCBCentralManager: self.bluetoothManager!, withPeripheral: peripheral)
                self.bleController?.delegateMonitorTabInit(delegate: self)
                self.bleController?.setPeripheral()
            }
        })
    }
       
    @objc func timerDeviceCheck() {
        print(tag + "timerDeviceCheck")
        bluetoothManager!.stopScan()
        MyStruct.bleStatus = false
        
        DispatchQueue.main.async {
            self.indicatorView.removeFromSuperview()
            self.alertViewDisconnect()
        }
    }
       
    //MARK: - Log Data download
    var timerLodDownload : Timer?
    var indicatorLabel                  = UILabel()
       
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
           
        print("OperationController - activityIndicator")
    }
    
    //MARK: - DFU
    func aleretViewForDUF(){
        let title = "dfu_title".localized
        let msg = "dfu_frist_msg".localized
        let buttonStr = "update".localized
        let cancelbuttonStr = "cancel".localized
        
        let dialog        = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let cancelButton  = UIAlertAction(title: cancelbuttonStr, style: .default)
        let okButton      = UIAlertAction(title: buttonStr, style: .destructive){(action: UIAlertAction) -> Void in
            self.aleretViewForDUF_Info()
        }
        
        dialog.addAction(cancelButton)
        dialog.addAction(okButton)
       
        self.present(dialog, animated: true, completion: nil)
    }
    
    func aleretViewForDUF_Info(){
        let title = "dfu_title".localized
        let msg = "dfu_enable".localized
        let buttonStr = "update".localized
        let cancelbuttonStr = "cancel".localized
        
        let dialog        = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let messageText = NSMutableAttributedString(
            string: msg,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13),
                NSAttributedString.Key.foregroundColor : UIColor.black
            ]
        )

        dialog.setValue(messageText, forKey: "attributedMessage")
        
        let cancelButton  = UIAlertAction(title: cancelbuttonStr, style: .default)
        let okButton      = UIAlertAction(title: buttonStr, style: .destructive){(action: UIAlertAction) -> Void in
            
            self.flagMoveSetting = true
            self.bleController?.bleSendData(cmd: 0xFF)
            
            self.performSegue(withIdentifier: "goDFU", sender: nil)
        }
        
        dialog.addAction(cancelButton)
        dialog.addAction(okButton)
       
        
        self.present(dialog, animated: true, completion: nil)
    }
    
    func alertViewDisconnect(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.timerStop()
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.monitorDisconnect), object: nil)
            
            self.indicatorView.removeFromSuperview()
            let cancelbuttonStr = String("no".localized)
            let buttonStr = String("yes".localized)
                   
            let dialog  = UIAlertController(title: "home_connection_fail_title".localized, message: "home_connection_fail_msg".localized, preferredStyle: .alert)
            let cancelButton    = UIAlertAction(title: cancelbuttonStr, style: .default){(action: UIAlertAction) -> Void in
            }
            let okButton      = UIAlertAction(title: buttonStr, style: .default){(action: UIAlertAction) -> Void in
                self.performSegue(withIdentifier: "goDeviceList", sender: nil)
            }
                   
            dialog.addAction(cancelButton)
            dialog.addAction(okButton)
                   
            self.present(dialog, animated: true) {
            }
        }
    }
    
    @objc func popUpView(){
        view.alpha = 0.3
    }
     
     @objc func popUpDismiss(){
        view.alpha = 1
    }
    
    //MARK: - V2 DFU
    @objc func dfuAlret(){
        let cancelbuttonStr = String("cancel".localized)
        let buttonStr = String("DFU".localized)
               
        let dialog  = UIAlertController(title: "DFU", message: "RadonEye V3 DFU", preferredStyle: .alert)
        let cancelButton    = UIAlertAction(title: cancelbuttonStr, style: .default){(action: UIAlertAction) -> Void in
        }
        let okButton      = UIAlertAction(title: buttonStr, style: .default){(action: UIAlertAction) -> Void in
            self.dfuFileLoad()
        }
               
        dialog.addAction(cancelButton)
        dialog.addAction(okButton)
               
        self.present(dialog, animated: true) {
        }
    }
    
    func dfuDataLoadProcess(inType: Int){
        var fName = "RadonEyeV3"
        if inType == 0{
            fName = "RadonEyeV3"
        }
        
        BLEData.OTA.sendData.removeAll()
        let stream:InputStream = InputStream(fileAtPath: Bundle.main.path(forResource: fName, ofType: "bin") ?? "")!//4
        
        var buf:[UInt8] = [UInt8](repeating: 0, count: 16)
        stream.open()
        while true {
            let len = stream.read(&buf, maxLength: buf.count)
            for i in 0..<len {
                BLEData.OTA.sendData.append(buf[i])
            }
            if len < buf.count {
                break
            }
        }
        stream.close()
        
        BLEData.OTA.totalPacket = BLEData.OTA.sendData.count / 500//1번 전송 시 최대 500바이트 전송
        //500바이트 = 1패킷,    보낼테이터가 2001바이트 일 경우 = 5패킷
        
        if (BLEData.OTA.sendData.count % 500) != 0{//500으로 나누었을때 나머지가 있으면 패킷 추가
            BLEData.OTA.totalPacket += 1
        }
        print(tag + "BLEData.OTA.totalPacket: \(BLEData.OTA.totalPacket), BLEData.OTA.sendData: \(BLEData.OTA.sendData.count)")
        
    }
    
    func dfuFileLoad(){
        timerStop()
        
        dfuDataLoadProcess(inType: 0)
        BLEData.OTA.sendAddress = 0
        
        indicatorView.removeFromSuperview()
        activityIndicatorForLog("Ready")
        timerLodDownload = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(dfuPercentView), userInfo: nil, repeats: true)
        
        var sData = [UInt8]()
        
        let data = MyUtil.uint32ConverByteArray(inValue: UInt32(BLEData.OTA.sendData.count))
        sData.append(data[0])
        sData.append(data[1])
        sData.append(data[2])
        sData.append(data[3])
        
        let data2 = MyUtil.uint16ConverByteArray(inValue: UInt16(BLEData.OTA.totalPacket))
        sData.append(data2[0])
        sData.append(data2[1])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.bleController?.bleSendData(cmd: BLECommnad.cmd_DFU_START, size: sData.count, data: sData)
        }
    }
    
    @objc func dfuPercentView(){
        if BLEData.OTA.sendSize < BLEData.OTA.sendData.count{
            let getPercent = (Float(BLEData.OTA.sendAddress) / Float(BLEData.OTA.sendData.count)) * 100
            indicatorLabel.text = String.init(format: "%.0f%@",getPercent, "%")
        }
    }
}

 //MARK:- MonitorTabDelegate
extension viewTabTop: MonitorTabDelegate {
    func didDisconnectPeripheral() {
        print(tag + "monitorTabDelegate, didDisconnectPeripheral")
        MyStruct.bleStatus = false
        flagBleConnect = false
        alertViewDisconnect()
    }
    
    func dInitFinish() {
        self.timerScan?.invalidate()
        self.timerScan = nil
        
        flagLogClick = false
        MyStruct.bleStatus = true
        UserDefaults.standard.set(connectedPeripheral?.name, forKey: MyStruct.Key.lastDeviceName)
           
        print(tag + "monitorTabDelegate, initFinish")
        BLEData.Flag.V3_New = false
        
        if !MyStruct.v2Mode{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.bleController?.bleSendData(cmd: BLECommnad.cmd_BLE_VERSION_QUERY)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.bleController?.bleSendData(cmd: BLECommnad.cmd_SN_TYPE_QUERY)
            }
        }
        //V1.5.0 - 20240723
        else{
            var versionStr = String("")
            versionStr = BLEData.Config.version.replacingOccurrences(of: "V", with: "")
            versionStr = versionStr.replacingOccurrences(of: ".", with: "")
            
            BLEData.Config.versionInt = UInt16(versionStr)!
            
            if BLEData.Config.versionInt >= MyStruct.refV3NewFw{
                BLEData.Flag.V3_New = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print(self.tag + "monitorTabDelegate, initFinishL flagBleConnect")
            self.flagBleConnect = true //BLE 연결 성공
            self.indicatorView.removeFromSuperview()
            self.navigationItem.title = BLEData.Config.barcode
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.monitorRadonUpdate), object: nil)
            self.timerStart()
            
            if BLEData.Flag.fwUpdate{
                self.aleretViewForDUF()
            }
        }

    }
    
    func dTabRadonUiUpdate(_ cmd: UInt8){
        MyStruct.bleStatus = true
        print(tag + "MonitorTabDelegate, dTabRadonUiUpdate: \(cmd)")
       
        switch(cmd){
        case BLECommnad.cmd_EEPROM_LOG_DATA_SEND:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.indicatorView.removeFromSuperview()
                if BLEData.Log.dataNo == 0{
                    self.aleretView(inTitle: "Notice", inMsg: "log_data_no_data".localized, intButtonStr: "close".localized)
                }
                else if BLEData.Log.dataNo == 1{
                    self.aleretView(inTitle: "Notice", inMsg: "log_data_1hour".localized, intButtonStr: "close".localized)
                }
            }
            break;
            
        default:
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.monitorRadonUpdate), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.monitorChartSyncUpdate), object: nil)
            break;
        }
    }
    
    func recLogDataStart(){
        timerLogDownloadStart()
    }
    
    func rawLogDataReturn(_ inData: [UInt8]) {
        BLEData.Log.radonValue.removeAll()
        var inB         = [UInt8]()
        var add         = Int(0)
        
        for _ in 0..<BLEData.Log.dataNo{
            inB.removeAll()
            
            var array = [UInt8]()
            for _ in 0..<2{
                array.append(inData[add]); add += 1
            }
            
            //V1.2.0
            var logValue = Float(MyUtil.byteConvertUInt16(inArrayData: array))
            if !MyStruct.v2Mode{
                logValue = logValue / 100.0
                
                if logValue >= 99.9{
                    logValue = 99.9
                }
            }
            
            BLEData.Log.radonValue.append(logValue)
        }
        
        flagLogClick = false
        BLEData.Flag.chartDraw = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.timerLogDownloadStop()
            self.indicatorView.removeFromSuperview()
            NotificationCenter.default.post(name: NSNotification.Name(MyStruct.notiName.monitorChartUpdate), object: nil)
            self.timerStart()
        }
    }
    
    //V1.2.0
    func DfuFinishProcess(){
        print(tag + "DfuFinishProcess")
        timerStop()
        bleController?.disConnect()
        
        UserDefaults.standard.removeObject(forKey: MyStruct.Key.lastDeviceName)
        timerLogDownloadStop()
        
        activityIndicatorForLog("Initializing..")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.indicatorView.removeFromSuperview()
            self.performSegue(withIdentifier: "goDeviceList", sender: nil)
        }
    }
}
