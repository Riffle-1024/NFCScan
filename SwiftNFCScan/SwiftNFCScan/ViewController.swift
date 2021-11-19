//
//  ViewController.swift
//  SwiftNFCScan
//
//  Created by liuyalu on 2021/11/18.
//

import UIKit
import CoreNFC

class ViewController: UIViewController {

    var nfcManager:NFCManager?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nfcManager = NFCManager.init()
        let scanBtn:UIButton = UIButton.init(type: UIButton.ButtonType.custom)
        scanBtn.frame = CGRect(x: 100, y: 60, width: 120, height: 30)
        scanBtn.setTitle("扫描NFC", for: UIControl.State.normal)
        scanBtn.setTitleColor(UIColor.red, for: UIControl.State.normal)
        scanBtn.layer.cornerRadius = 3
        scanBtn.layer.borderWidth = 1
        scanBtn.layer.borderColor = UIColor.blue.cgColor
        self.view.addSubview(scanBtn)
        scanBtn.addTarget(self, action:#selector(ViewController.scanBtnClick), for: UIControl.Event.touchUpInside)
    }
    @objc func scanBtnClick() {
        self.nfcManager?.startScanNFC(successBlock: { ndefMessage in
            
        }, errorBlock: { error in
            
        })
         
     }


}

