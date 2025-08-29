//
//  viewMonitorData.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/05.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//


import UIKit
import DGCharts

class viewSaveLogView: UIViewController {
    let tag = String("viewSaveLogView - ")
    var indicatorView                   = UIView()//progress bar
    
    @IBOutlet weak var viewChart: UIView!
    @IBOutlet weak var imgChartInfo: UIImageView!
    @IBOutlet weak var labChartUnit: UILabel!
    @IBOutlet weak var labChartX: LableLocal!
    @IBOutlet weak var lineChart: LineChartView!
    
    @IBOutlet weak var viewFiileName: UIView!
    @IBOutlet weak var viewSn: UIView!
    @IBOutlet weak var viewDataNo: UIView!
    
    @IBOutlet weak var labFileName: UILabel!
    @IBOutlet weak var labSn: UILabel!
    @IBOutlet weak var labDataNo: UILabel!
    
    var fileName = String("")
    var mUnit = Int(0)
    var mAlarmValue = Double(0)
    var sn = String("")
    var radonValue = [Float]()
    var fileUrl = URL(string: "")
    
    override func viewDidLoad() {
        MyUtil.printProcess(inMsg: tag + "viewDidLoad")
        super.viewDidLoad()
        
        navigationItem.title = "title_saved_log_data".localized
        
        let buttonRight = UIButton(type: .system)
        buttonRight.frame = CGRect(x: 0.0, y: 0.0, width: 10, height: 10)
        buttonRight.tintColor = UIColor.black
        let image = UIImage(systemName: "square.and.arrow.up")
        buttonRight.setImage(image, for: .normal)
        buttonRight.addTarget(self, action: #selector(fileShare), for: .touchUpInside)
        let rightBarButton = UIBarButtonItem(customView: buttonRight)
        self.navigationItem.rightBarButtonItem  = rightBarButton
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.viewChart.layer.addBorder([.top, .bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewFiileName.layer.addBorder([.top, .bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewSn.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
            self.viewDataNo.layer.addBorder([.bottom], color: MyStruct.Color.border, width: 0.5)
        }

        imgChartInfo.isUserInteractionEnabled = true
        imgChartInfo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickChartInfo)))
        
        //labChartX.text = "chart_bottom_text".localized
        
        do{
            let readText = try String(contentsOf: fileUrl!, encoding: .utf8)
            var textArray = readText.split(separator: "\r\n")
            
            if textArray.count < 7{
                textArray = readText.split(separator: "\n")
            }
            
            var add = Int(2)
            if textArray.count >= 7{
                sn = String((textArray[add].split(separator: "\t"))[1]);    add+=1//SN
                let readUnitStr = String((textArray[add].split(separator: "\t"))[1]);    add+=1//Unit
                
                if readUnitStr == "pCi/ℓ"{
                    mUnit = 0
                }
                else if readUnitStr == "pCi/l"{
                    mUnit = 0
                }
                else{
                    mUnit = 1
                }
                
                var unitStr = String("unit_pico".localized)
                if mUnit == 1{
                    unitStr = "unit_bq".localized
                }
                
                
                let readAlarm = textArray[add].split(separator: "\t");   add+=1//
                if readAlarm.count > 3{
                    mAlarmValue = Double(readAlarm[3])!
                }
                
                
                let readDataNo = Int(String((textArray[add].split(separator: "\t"))[1]))!;    add+=1//SN
                print("FileChartViewController load - DataNo : \(readDataNo)");
                
                for _ in 0..<readDataNo{
                    let logValue = Float(String((textArray[add].split(separator: "\t"))[1]));    add+=1
                    radonValue.append(logValue ?? 0)
                }
                
                //initLinePlot()
                labChartX.isHidden = false
                labChartX.text = "chart_bottom_text".localized
                labChartUnit.text = String.init(format: "(%@)", unitStr)
                labFileName.text = fileName
                labSn.text = sn
                labDataNo.text = String.init(format: "%d", readDataNo)
                chartsControl.chartDraw(lineChart, radonValue, mUnit, mUnit, mAlarmValue, false)
            }
        }
        catch{
            print("FileChartViewController load - read error");
        }
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
    
    @objc func fileShare(){
        print(tag + "fileShare")
        let objectsToShare = [fileUrl!]
    
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        //activityVC.popoverPresentationController?.sourceView  = self.view
        activityVC.excludedActivityTypes = [
           UIActivity.ActivityType.print,
           UIActivity.ActivityType.addToReadingList
        ]
        // Check if user is on iPad and present popover
        if UIDevice.current.userInterfaceIdiom == .pad {
           if activityVC.responds(to: #selector(getter: UIViewController.popoverPresentationController)) {
               activityVC.popoverPresentationController?.sourceView = self.view
               activityVC.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
               activityVC.popoverPresentationController?.permittedArrowDirections = []
           }
        }
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @objc func onClickChartInfo(_ sender:UIGestureRecognizer){
        print(tag + "onClickChartInfo")
        dialogChartInfo()
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
    
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet var viewChartInfo: UIView!
    @IBOutlet weak var labChartInfoNo: LableLocal!
    @IBOutlet weak var labAvg: UILabel!
    @IBOutlet weak var labMax: UILabel!
    @IBOutlet weak var labMin: UILabel!
    
    //var checkboxinsDataUpload = CheckboxButton()
    func dialogChartInfo(){
        print(tag + "dialogChartInfo")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView(gesture:)))
        viewChartInfo.addGestureRecognizer(tapGesture)
        //viewChartInfo.frame = CGRect(x: 0, y: 0 , width: view.frame.width * 0.9, height: 220)
        //viewChartInfo.frame = CGRect(x: 0, y: 0 , width: 300, height: view.frame.height * 0.9)

        view.addSubview(viewChartInfo)
        viewMain.alpha = 0.3
        self.navigationController?.navigationBar.alpha = 0.3
        viewChartInfo.layer.shadowColor = UIColor.black.cgColor
        viewChartInfo.layer.shadowRadius = 5
        viewChartInfo.layer.shadowOffset = CGSize(width: 2, height: 2)
        viewChartInfo.layer.shadowOpacity = 0.5
        viewChartInfo.center = CGPoint(x: view.frame.width / 2, y: (view.frame.height / 2) - 50)
        
        labChartInfoNo.text = String.init(format: "%d", radonValue.count)
        
        let maxValue = Float(radonValue.max() ?? 0)
        let minValue = Float(radonValue.min() ?? 0)
        
        let sumValue = radonValue.reduce(0, +)
        let avgValue = sumValue / Float(radonValue.count)
        
        labAvg.attributedText = textRadonValue(inRadonValue: avgValue, inUnit: UInt8(mUnit))
        labMax.attributedText = textRadonValue(inRadonValue: maxValue, inUnit: UInt8(mUnit))
        labMin.attributedText = textRadonValue(inRadonValue: minValue, inUnit: UInt8(mUnit))
    }

    
    @objc func didTapView(gesture: UITapGestureRecognizer){
        view.endEditing(true)
    }
    
    @IBAction func onClickChartInfoClose(_ sender: Any) {
        viewMain.alpha = 1
        self.navigationController?.navigationBar.alpha = 1
        viewChartInfo.removeFromSuperview()
    }
    
    func textRadonValue(inRadonValue: Float, inUnit: UInt8) -> NSMutableAttributedString{
        var unitStr = String("unit_pico".localized)
        if inUnit == 1{
            unitStr = "unit_bq".localized
        }
        
        let valueStr = MyUtil.valueReturnString(inUnit, inRadonValue)
      
        let attributedText = NSMutableAttributedString(string: valueStr, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20),NSAttributedString.Key.foregroundColor: UIColor.black])
        attributedText.append(NSAttributedString(string: unitStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),NSAttributedString.Key.foregroundColor: MyStruct.Color.hex606060]))
        
        return attributedText
    }
}
