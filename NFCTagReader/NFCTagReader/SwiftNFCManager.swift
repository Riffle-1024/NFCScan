//
//  SwiftNFCManager.swift
//  NFCTagReader
//
//  Created by liuyalu on 2021/11/19.
//

import UIKit
import CoreNFC

class SwiftNFCManager: NSObject ,NFCTagReaderSessionDelegate{
    enum NFCSupportsStatus : NSInteger {
        case NFCSupportStatusYes = 0 //支持
        case NFCSupportStatusDeviceNo = 1 //硬件不支持
        case NFCSupportStatusnSystemNo = 2//系统不支持
    }
    typealias  block = (Data,Bool) -> Void
    var completeHandle:block?
    typealias  NFCScanSuccessBlock = (String) -> Void
    typealias  NFCScanErrorBlock = (String) -> Void
    var delegate:NfcProtocol?
    var isReading:Bool?
    var scanSuccessBlock:NFCScanSuccessBlock?
    var scanErrorBlock:NFCScanErrorBlock?
    var tagSession:NFCTagReaderSession?
    var currentTag:NFCISO7816Tag?
    static let shared = SwiftNFCManager()
    
    class func isSupportsNFCReading()->NFCSupportsStatus{
        if #available(iOS 11.0, *){
            if NFCNDEFReaderSession.readingAvailable == true{
                return NFCSupportsStatus.NFCSupportStatusYes
            }else{
                print("该机型不支持NFC功能!")
                return NFCSupportsStatus.NFCSupportStatusDeviceNo
            }
        }else{
            print("当前系统不支持NFC功能!")
            return NFCSupportsStatus.NFCSupportStatusnSystemNo
        }
    }
    class func isSupportsNFCWrite()->NFCSupportsStatus{
        if #available(iOS 13.0, *){
            if NFCNDEFReaderSession.readingAvailable == true{
                return NFCSupportsStatus.NFCSupportStatusYes
            }else{
                print("该机型不支持NFC功能!")
                return NFCSupportsStatus.NFCSupportStatusDeviceNo
            }
        }else{
            print("当前系统不支持NFC写入功能!")
            return NFCSupportsStatus.NFCSupportStatusnSystemNo
        }
    }
    func startScanNFC(successBlock:@escaping NFCScanSuccessBlock,errorBlock:@escaping NFCScanErrorBlock) {
        scanSuccessBlock = successBlock
        scanErrorBlock = errorBlock
        isReading = true
        self.beginScan()
    }
    func beginScan() {
        if #available(iOS 11.0, *){
            tagSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092], delegate: self, queue: nil)
            tagSession?.alertMessage = "Hold your iPhone near an NFC Type 2 tag."
               tagSession?.begin()
        }
    }
    //停止扫描
    func invalidateSession() {
        self.tagSession?.invalidate()
    }
    
    
    //MARK: NFCTagReaderSessionDelegate
     
     func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
         print("tagReaderSessionDidBecomeActive")
     }
     
     func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
         scanErrorBlock!("扫描NFC失败")
         print("error:\(error)")
     }
     
     func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
         
         if tags.count > 1 {
             print("读卡错误")
             scanErrorBlock!("读卡错误")
             session.alertMessage = "More than 1 tags was found. Please present only 1 tag."
             return
         }
         
         
         let Tag7816:NFCTag = tags.first!
         switch Tag7816 {
         case .feliCa(_):
             print("NFCFeliCaTag")
         case let .iso7816(tag):
             // 这里获取到的AID就是第一步中在info.plist中设置的ID （A000000000）这个值一般是卡商提供的，代表卡的应用表示。
             self.tagSession?.connect(to: Tag7816, completionHandler: {[weak self] (error) in
                 if error != nil {
                     print("TconnectToTag:\(String(describing: error))")
                     session.invalidate(errorMessage: "Connection error. Please try again.")
                     self?.delegate?.connectNfcError()
                     return
                 }
                 self?.delegate?.connectNfcSuccess()
                 self?.currentTag = tag
                 self?.tagSession?.alertMessage = "已经识别到NFC"
                 self?.invalidateSession()
             })
         case .iso15693(_):
             print("NFCISO15693Tag")
         case .miFare(_):
             print("NFCMiFareTag")
         @unknown default:
             session.invalidate(errorMessage: "Tag not valid.")
             return
         }

     }
     

     
     func sendApduSingle(apduStr:String,comPlete:block){
         let sendData:Data = self.convertHexStrToData(hexStr: apduStr)
         let cmd:NFCISO7816APDU = NFCISO7816APDU.init(data: sendData)!
         var resultError:NSError?
         var result:Data?
         self.currentTag?.sendCommand(apdu: cmd, completionHandler: { [weak self] (resultData, sw1, sw2, error) in
             print("resultData:\(resultData)\nsw1:\(sw1)\nsw2:\(sw2)\nerror:\(String(describing: error))")
             print("rusultData转16进制:\(String(describing: self?.string(from: resultData)))")

             result = resultData
             resultError = error as NSError?
         })
         
         if resultError == nil{
             comPlete(result ?? Data.init(),true)
         }else{
             comPlete(Data.init(),false)
         }
     }
     
     
     
     //将十六进制字符串转化为 Data
     func convertHexStrToData(hexStr:String) -> Data {
         let bytes = self.bytes(from: hexStr)
 //        let bytes = hexStr.bytes(from: hexStr)
         return Data.init(_:bytes)
     }
     
     // 将16进制字符串转化为 [UInt8]
       // 使用的时候直接初始化出 Data
       // Data(bytes: Array<UInt8>)
     func bytes(from hexStr: String) -> [UInt8] {
         assert(hexStr.count % 2 == 0, "输入字符串格式不对，8位代表一个字符")
         var bytes = [UInt8]()
         var sum = 0
         // 整形的 utf8 编码范围
         let intRange = 48...57
         // 小写 a~f 的 utf8 的编码范围
         let lowercaseRange = 97...102
         // 大写 A~F 的 utf8 的编码范围
         let uppercasedRange = 65...70
         for (index, c) in hexStr.utf8CString.enumerated() {
             var intC = Int(c.byteSwapped)
             if intC == 0 {
                 break
             } else if intRange.contains(intC) {
                 intC -= 48
             } else if lowercaseRange.contains(intC) {
                 intC -= 87
             } else if uppercasedRange.contains(intC) {
                 intC -= 55
             } else {
                 assertionFailure("输入字符串格式不对，每个字符都需要在0~9，a~f，A~F内")
             }
             sum = sum * 16 + intC
             // 每两个十六进制字母代表8位，即一个字节
             if index % 2 != 0 {
                 bytes.append(UInt8(sum))
                 sum = 0
             }
         }
         return bytes
     }
     //讲Data转String
     func string(from data: Data) -> String {
             return String(format: "%@", data as CVarArg)
         }
}


