//
//  SwiftNFCViewController.swift
//  NFCTagReader
//
//  Created by liuyalu on 2021/11/19.
//

import UIKit

class SwiftNFCViewController: UIViewController,NfcProtocol {

    
    
    var nfcManager:SwiftNFCManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        let scanBtn:UIButton = UIButton.init(type: UIButton.ButtonType.custom)
        scanBtn.frame = CGRect(x: 100, y: 150, width: 120, height: 30)
        scanBtn.setTitle("扫描NFC", for: UIControl.State.normal)
        scanBtn.setTitleColor(UIColor.red, for: UIControl.State.normal)
        scanBtn.layer.cornerRadius = 3
        scanBtn.layer.borderWidth = 1
        scanBtn.layer.borderColor = UIColor.blue.cgColor
        self.view.addSubview(scanBtn)
        scanBtn.addTarget(self, action:#selector(SwiftNFCViewController.scanBtnClick), for: UIControl.Event.touchUpInside)
    }
    @objc func scanBtnClick() {
        
        SwiftNFCManager.shared.startScanNFC { successString in
            print("\(successString)")
        } errorBlock: { errorString in
            print("\(errorString)")
        }
     }

    func connectNfcSuccess() {
        print("连接成功")
        let queue = DispatchQueue(label: "--")
        //发送指令到NFC卡
        queue.async {
            self.nfcManager?.sendApduSingle(apduStr: "00A400000125000", comPlete:{ (resulrData, isSuccess) in
                if isSuccess == false {
                    print("发送数据错误")
                }else{
                    print("发送数据成功resultData:\(self.string(from: resulrData))")
                }
            })
        }
    }
    
    func connectNfcError() {
        print("连接失败")
    }
    
    
    //讲Data转String
    func string(from data: Data) -> String {
            return String(format: "%@", data as CVarArg)
        }

}
