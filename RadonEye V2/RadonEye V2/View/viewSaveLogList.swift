//
//  viewSaveLogList.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2019/12/10.
//  Copyright © 2019 jung sukhwan. All rights reserved.
//

import UIKit

class viewSaveLogList: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tag = String("viewSaveLogList - ")
    
    @IBOutlet weak var viewMain: UIView!
    // Define the array to be used in Section.
    var sections = [String]()
    var fileList = Array<Any>()
    var selectFileName = String("")
    var fileUrl : URL?
    let headerHieht = Int(60)
    let itemRowHeight = Int(50)
    
    lazy var tableView: UITableView = { // Get the height of the Status Bar.
        let barHeight = self.viewMain.frame.origin.y
        // Get the height and width of the View.
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.viewMain.frame.height
        let tableView: UITableView = UITableView(frame: CGRect(x: 0, y: 0, width: displayWidth, height: displayHeight - barHeight))
        
        // Register the Cell name.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "sectionTableViewCell")
        // Set the DataSource.
        tableView.dataSource = self
        // Set Delegate.
        tableView.delegate = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.separatorInset.left = 0
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false
        tableView.isScrollEnabled = true
        return tableView
    }()

    
    override func viewDidLoad() {
        MyUtil.printProcess(inMsg: tag + "viewDidLoad")
        super.viewDidLoad()
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.fileOpenProcess()
            self.tableView.backgroundColor = MyStruct.Color.background
            self.viewMain.addSubview(self.tableView)
        }
    }
    
    func fileOpenProcess(){
        sections.removeAll()
        fileList.removeAll()
        let readSections = listFilesFromDocumentsFolder() ?? [""]
        var itemHeight = Int(0)
        
        if readSections.count > 0{
            for i in 0..<readSections.count{
                var readFile = [String]()
                readFile = listFilesFromDocumentsFolder(inSn: readSections[i])!
                if readFile.count > 0{//해당 폴더에 파일이 있을때만 추가
                    sections.append(readSections[i])
                    fileList.append(readFile)
                }
                MyUtil.printProcess(inMsg: tag + "viewDidLoad, itemHeight: \(itemHeight), readFile!.count: \(readFile.count)")
                itemHeight += readFile.count * itemRowHeight
            }
            //let mHeight = CGFloat((sections.count * headerHieht) + itemHeight)
            //tableView.frame.size.height = mHeight
            tableView.frame.size.height = self.viewMain.frame.height
        }
    }
   
    override func viewWillAppear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillAppear")
        super.viewWillAppear(animated)
        
        navigationItem.title = "title_saved_log_data".localized
    }


    override func viewWillDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewWillDisappear")
        super.viewWillDisappear(animated)
        
        navigationItem.title = ""
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        MyUtil.printProcess(inMsg: tag + "viewDidDisappear")
        super.viewDidDisappear(animated)
    }
    
    
    override func didReceiveMemoryWarning() {
        MyUtil.printProcess(inMsg: tag + "didReceiveMemoryWarning")
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - File load
    func listFilesFromDocumentsFolder() -> [String]?
    {
        //let fileMngr = FileManager.default;
        // Full path to documents directory
        //let docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        //return try? fileMngr.contentsOfDirectory(atPath:docs)
        
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        return try? FileManager.default.contentsOfDirectory(atPath:directory)
    }
    
    func listFilesFromDocumentsFolder(inSn: String) -> [String]?
    {
          //let fileMngr = FileManager.default;
          // Full path to documents directory
          //let docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].path
          //return try? fileMngr.contentsOfDirectory(atPath:docs)
          
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destPath = dir.appendingPathComponent(inSn, isDirectory: true)
        var ret = try? FileManager.default.contentsOfDirectory(atPath:destPath.relativePath)
        if ret == nil{
            ret = [""]
        }
        return ret
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goLogDataView" {
            let tabController = segue.destination as! viewSaveLogView
            tabController.fileUrl = self.fileUrl
            tabController.fileName = self.selectFileName
        }
    }
    
    //MARK: - TableView
   //Returns the number of sections.
   func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    // Returns the title of the section.
    /*func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return sections[section]
    }*/
    
    // Called when Cell is selected.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {//goLogDataView
        let readData = fileList[indexPath.section] as! [String]
        selectFileName = readData[indexPath.row]
        print("Value: \(readData[indexPath.row])")
        
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destPath = dir.appendingPathComponent(sections[indexPath.section], isDirectory: true)
        fileUrl = destPath.appendingPathComponent(selectFileName)
        
        print(tag + "fileUrl: \(String(describing: fileUrl))")
        performSegue(withIdentifier: "goLogDataView", sender: nil)
    }
    
    //header height
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(headerHieht)
    }
    
    //header font
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = MyStruct.Color.background

        let headerLabel = UILabel(frame: CGRect(x: 20, y: 30, width: tableView.bounds.size.width, height: 30))
        headerLabel.font = UIFont.systemFont(ofSize: 16)
        headerLabel.textColor = MyStruct.Color.hexBlackHalf
        
        headerLabel.text = sections[section]
       
        headerLabel.sizeToFit()
        headerView.addSubview(headerLabel)

        return headerView
    }

    // Returns the total number of arrays to display in the table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let readData = fileList[section] as! [String]
        return readData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(itemRowHeight)
    }
    
    // Set a value in Cell.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sectionTableViewCell", for: indexPath)
        
        //cell.layer.frame.width = tableView.bounds.size.width
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20)
        cell.textLabel?.textColor = UIColor.black
        cell.selectionStyle = .none//선택시 색상 안바뀜
        
        if indexPath.row == 0{
            cell.layer.addBorderLarge([.top, .bottom], color: MyStruct.Color.border, width: 0.5)
        }
        else{
            cell.layer.addBorderLarge([.bottom], color: MyStruct.Color.border, width: 0.5)
        }
        
        let readData = fileList[indexPath.section] as! [String]
        //cell.textLabel?.frame.size.height = 40
        cell.textLabel?.text = "\(readData[indexPath.row])"
        print(tag + "tableView item name : \(readData[indexPath.row])")
        return cell
    }

    /*func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     // When deleting.
        
        
        
        if editingStyle == UITableViewCell.EditingStyle.delete {
            print(tag + "Delete")
         
            // Delete the object of the specified cell from items.
            //items.remove(at: indexPath.row)
         
            // Reload the TableView.
            tableView.reloadData()
        }
    }*/
    
   func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            success(true)
            self.dialogDelete(inSectionIdx: indexPath.section, inItemIdx: indexPath.row)
        })
        deleteAction.image = #imageLiteral(resourceName: " trash")
        return UISwipeActionsConfiguration(actions:[deleteAction])
    }
    
    func dialogDelete(inSectionIdx: Int, inItemIdx: Int){
        let mFileList = fileList[inSectionIdx] as! [String]
        let fileName = mFileList[inItemIdx]
        print(tag + "dialogDelete, sn \(sections[inSectionIdx]), file name: \(fileName)")
        
        let cancelbuttonStr = String("no".localized)
        let buttonStr = String("yes".localized)
             
        let dialog  = UIAlertController(title: "", message: "file_delete_msg".localized, preferredStyle: .alert)
        let cancelButton    = UIAlertAction(title: cancelbuttonStr, style: .default){(action: UIAlertAction) -> Void in
            
        }
        let okButton      = UIAlertAction(title: buttonStr, style: .destructive){(action: UIAlertAction) -> Void in
            self.fileDeleteProcess(inSn: self.sections[inSectionIdx], inFileName: fileName)
        }
             
        dialog.addAction(cancelButton)
        dialog.addAction(okButton)
             
        present(dialog, animated: true) {
                 
        }
    }
    
    func fileDeleteProcess(inSn: String, inFileName: String){
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destPath = dir.appendingPathComponent(inSn, isDirectory: true)
        let documentsPath1 = destPath.path
        
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: "\(documentsPath1)")
            print("all files in cache: \(fileNames)")
            for fileName in fileNames {
                if fileName == inFileName{
                    let filePathName = "\(documentsPath1)/\(fileName)"
                    try FileManager.default.removeItem(atPath: filePathName)
                }
            }
            print(tag + "delete success: \(inFileName)")
            fileOpenProcess()
            self.tableView.reloadData()

        } catch {
            print(tag + "delete faile: \(error)")
        }
    }
}
