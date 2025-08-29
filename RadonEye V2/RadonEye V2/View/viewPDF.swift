//
//  viewPDF.swift
//  RadonEye V2
//
//  Created by jung sukhwan on 2020/01/08.
//  Copyright © 2020 jung sukhwan. All rights reserved.
//

import UIKit
import WebKit

class viewPDF: UIViewController{
    let tag                             = String("viewPDF - ")

    @IBOutlet weak var pdfView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(tag + "viewDidLoad")
        
        self.navigationItem.title = "Quick Manual"
        
        DispatchQueue.main.async {
            self.pdfView.load(URLRequest(url: URL(fileURLWithPath: Bundle.main.path(forResource: "RadonEye_Quick_Guide", ofType: "pdf")!)))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(tag + "viewWillAppear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(tag + "viewWillDisappear")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print(tag + "didReceiveMemoryWarning")
    }
    
}
