//
//  ViewController.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit
import CoreBluetooth
import SideMenu

class viewDeviceList: UIViewController, CBCentralManagerDelegate, UITextFieldDelegate {
    let tag = String("viewDeviceList - ")
    
    @IBOutlet var viewMain: UIView!
    @IBOutlet weak var tvDeviceList: UITableView!
    var indicatorView                   = UIView()//progress bar
    
    
    //BLE
    var selectIndex         : Int
    var flagDeviceScan                  = Bool(false)
    var bluetoothManager                : CBCentralManager?
    var delegate                        : NORScannerDelegate?
    var filterDeviceUUID                : CBUUID?
    var filterDFUUUID                   : CBUUID?
    var peripherals                     : [NORScannedPeripheral] = []
    var timer                           : Timer?
    var timerErrorCheck                 : Timer?
    var flagDFU             = Bool(false)
    
    private var discoveredPeripherals   = [BLEControl]()
    private var targetperipheral        : BLEControl?
    var bleController                   : BLEControl?
    
    //var kxMenu                          = KxMenu()
    
    var CBPeripherals                   : [CBPeripheral] = []
    var flagFinish                      = Bool(false)
    var flagScanForDelete               = Bool(false)
    
    @IBOutlet weak var constrainTvListHeight: NSLayoutConstraint!
    
    //MARK:- UI Init
    required init?(coder aDecoder: NSCoder) {
        peripherals = []
        self.selectIndex = 0
        super.init(coder: aDecoder)
    }
    
    func getRSSIImage(RSSI anRSSIValue: Int32) -> UIImage {
        var image: UIImage
        
        if (anRSSIValue < -90) {
            image = UIImage(named: "Signal_0")!
        } else if (anRSSIValue < -70) {
            image = UIImage(named: "Signal_1")!
        } else if (anRSSIValue < -50) {
            image = UIImage(named: "Signal_2")!
        } else {
            image = UIImage(named: "Signal_3")!
        }
        
        return image
    }
    
    @objc func timerDeviceCheck() {
        if peripherals.count > 0 {
            let mHeight = CGFloat(peripherals.count * 60)
            //MyUtil.printProcess(inMsg: tag + "timerDeviceCheck, \(mHeight)")
            constrainTvListHeight.constant = mHeight
            tvDeviceList.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let navi = UINavigationController()
        navi.modalPresentationStyle = .fullScreen
        MyUtil.printProcess(inMsg: tag + "viewDidLoad")
        
        navigationController?.navigationBar.tintColor = MyUtil.uicolorFromHex(rgbValue: 0x000000)//좌측 바 버튼 텍스트 컬러
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        filterDFUUUID      = CBUUID(string: MyStruct.dfuUUIDString);
        filterDeviceUUID   = CBUUID(string: MyStruct.deviceUUIDString);
        
        //table view init
        tvDeviceList.delegate = self
        tvDeviceList.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MyStruct.uiMode = 0
        MyUtil.printProcess(inMsg: tag + "viewWillAppear")
        super.viewWillAppear(animated)
        
        navigationItem.title = "title_device_list".localized
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.barTintColor = UIColor.white
        
        // Add back button to return to welcome screen
        setupBackButton()
        
        //setupSideMenu()
        let mSideMenu = SideMenu()
        mSideMenu.setupSideMenu(inSb: storyboard!, inNavigation: navigationController!.navigationBar, inMainVeiw: view, inSubView: viewMain)

        let centralQueue = DispatchQueue(label: "kr.ftlab.radoneye.RaonEye", attributes: [])
        bluetoothManager = CBCentralManager(delegate: self, queue: centralQueue)
        
        self.peripherals.removeAll()
        CBPeripherals.removeAll()//V1.2.0
        tvDeviceList.reloadData()
    }


    override func viewWillDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillDisappear")
        let success = self.scanForPeripherals(false)
        if !success {
            print("Bluetooth is powered off!")
        }
        navigationItem.title = ""
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
    
    // MARK: - Back Button Setup
    
    private func setupBackButton() {
        // Create custom back button
        let backButton = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = UIColor.black
        
        // Replace the left bar button (menu) with back button
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func backButtonTapped() {
        MyUtil.printProcess(inMsg: tag + "backButtonTapped - returning to welcome")
        
        // Since this is the root of a modal navigation controller, dismiss the entire nav controller
        navigationController?.dismiss(animated: true) { [weak self] in
            MyUtil.printProcess(inMsg: self?.tag ?? "viewDeviceList" + "backButtonTapped - dismiss completed, posting notification")
            // Notify viewLanch that we've returned and need to show welcome screen
            NotificationCenter.default.post(name: NSNotification.Name("returnToWelcome"), object: nil)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goSideMenu" {
            guard let sideMenuNavigationController = segue.destination as? SideMenuNavigationController else { return }
            let mSideMenu = SideMenu()
            sideMenuNavigationController.settings = mSideMenu.makeSettings(inMainVeiw: viewMain)
        }
        else if segue.identifier == "goMonitor" {
            let peripheral = peripherals[selectIndex].peripheral
        
           // UserDefaults.standard.set(peripheral., forKey: MyStruct.Key.lastDeviceName)
             
            let tabController = segue.destination as! viewTabTop
            tabController.flagScanMode = false
            //V1.3.03 - 20220722
            MyStruct.v3Mode = peripherals[selectIndex].V3
            
            self.bleController = BLEControl(withCBCentralManager: bluetoothManager!, withPeripheral: CBPeripherals[selectIndex])
            tabController.bleController = bleController!
            tabController.connectedPeripheral = peripheral
            bleController?.setPeripheral()
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(tag + "centralManagerDidUpdateState")
        
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
        
        let success = self.scanForPeripherals(true)
        if !success {
            print("Bluetooth is powered off!")
        }
    }
    
    func scanForPeripherals(_ enable:Bool) -> Bool {
        guard bluetoothManager?.state == .poweredOn else {
            return false
        }
        
        DispatchQueue.main.async {
            if enable == true {
                let options: NSDictionary = NSDictionary(objects: [NSNumber(value: true as Bool)], forKeys: [CBCentralManagerScanOptionAllowDuplicatesKey as NSCopying])
                
                //self.bluetoothManager?.scanForPeripherals(withServices: [self.filterDeviceUUID!, self.filterDFUUUID!], options: options as? [String : AnyObject])
                //V1.2.0
                self.bluetoothManager?.scanForPeripherals(withServices: nil, options: options as? [String : AnyObject])
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timerDeviceCheck), userInfo: nil, repeats: true)
            } else {
                self.timer?.invalidate()
                self.timer = nil
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
            var viewName = String("")
            
            if localName == nil{
                return
            }
            
            var flagCheck = false;
            var flagV3 = false;//V1.3.0
            
            if localName?.range(of: "FR:R20:") != nil{
                if let checkName = localName{
                    let tempName = String(checkName.replacingOccurrences(of: ".", with: ""))
                    viewName = "RD200/" + String(tempName.dropFirst(7))
                    flagCheck = true;
                }
            }
            
            if localName?.range(of: "DfuTarg") != nil{
                viewName = localName!
                flagCheck = true;
            }
            
            //V1.3.0 - 20220722
            let range = localName?.range(of: "RE")
            if range != nil{
                if let checkName = localName{
                    if checkName.count > 10{//에코트래커와 scan 이름 다름, 라돈아이는 앞에 FR: 붙음
                        let firstIndex = localName?.index(localName!.startIndex, offsetBy: 7)
                        let lastIndex = localName?.index(localName!.startIndex, offsetBy: 9)
                        let findStr = String(localName?[firstIndex!..<lastIndex!] ?? "")
                        
                        if findStr == "RE"{
                            viewName = "RD200/SN" + String(checkName.dropFirst(11))
                            flagV3 = true;
                            flagCheck = true;
                        }
                    }
                }
            }
            
            //V1.2.0
            //if localName?.range(of: "FR:RD2") != nil || localName?.range(of: "FR:RU2") != nil || localName?.range(of: "FR:RE2") != nil{
            if localName?.range(of: "FR:RP2") != nil && !flagCheck{//라돈아이 프로는 검색 안되게 해야함
                return
            }
            
            if localName?.range(of: "FR:R") != nil && !flagCheck{
                if let checkName = localName{
                    if checkName.count >= 12{
                        if checkName[checkName.index(checkName.startIndex, offsetBy: 5)] == "2"{
                            let tempName = String(checkName.replacingOccurrences(of: ".", with: ""))
                            //viewName = "RD200/SN" + String(tempName.dropFirst(12))
                            viewName = "RD200/SN" + String(tempName.dropFirst(12))//TODO
                            flagCheck = true;
                        }
                    }
                }
            }
            
            if(flagCheck){
                var sensor = NORScannedPeripheral(withPeripheral: peripheral, andRSSI: RSSI.int32Value, andIsConnected: false, advertisementData: viewName, inV3: flagV3)
                
                if ((self.peripherals.contains(sensor)) == false) {
                    self.peripherals.append(sensor)
                    self.CBPeripherals.append(peripheral)
                }else{
                    sensor = self.peripherals[self.peripherals.firstIndex(of: sensor)!]
                    sensor.RSSI = RSSI.int32Value
                    sensor.realName = viewName
                }
            }
        })
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
}

extension viewDeviceList: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
           return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if peripherals.count == 0{
            return aCell
        }
        //Update cell content
        let scannedPeripheral = peripherals[indexPath.row]
        aCell.frame.size.height = 60
        aCell.textLabel?.text = scannedPeripheral.realName
        aCell.selectionStyle = .none//선택시 색상 안바뀜
        
        if scannedPeripheral.isConnected == true {
            aCell.imageView!.image = UIImage(named: "Connected")
        } else {
            let RSSIImage = self.getRSSIImage(RSSI: scannedPeripheral.RSSI)
            aCell.imageView!.image = RSSIImage
        }
        
        return aCell
    }
   
    //MARK: - UITableViewDelegate (Cell Select)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bluetoothManager!.stopScan()
           
        self.selectIndex = indexPath.row;
        print(tag + "tableView select: \(selectIndex), name: \(peripherals[self.selectIndex].realName)")
        flagDFU = false
        if peripherals[self.selectIndex].realName == "DfuTarg"{
            performSegue(withIdentifier: "goDFU", sender: nil)
        }
        else{
            performSegue(withIdentifier: "goMonitor", sender: nil)
        }
    }
}

