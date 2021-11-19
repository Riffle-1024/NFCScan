//
//  NFCManager.swift
//  SwiftNFCScan
//
//  Created by liuyalu on 2021/11/18.
//

import UIKit
import CoreNFC



class NFCManager: NSObject, NFCNDEFReaderSessionDelegate {
    enum NFCSupportsStatus : NSInteger {
        case NFCSupportStatusYes = 0 //支持
        case NFCSupportStatusDeviceNo = 1 //硬件不支持
        case NFCSupportStatusnSystemNo = 2//系统不支持
    }
    
    typealias  NFCScanSuccessBlock = (NFCNDEFMessage) -> Void
    typealias  NFCScanErrorBlock = (Error) -> Void
    var isReading:Bool?
    var scanSuccessBlock:NFCScanSuccessBlock?
    var scanErrorBlock:NFCScanErrorBlock?
    var session:NFCNDEFReaderSession?
    static let shared = NFCManager()
    
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
    
    func startScanNFC(successBlock:@escaping NFCScanSuccessBlock,errorBlock:@escaping NFCScanErrorBlock) {
        scanSuccessBlock = successBlock
        scanErrorBlock = errorBlock
        isReading = true
        self.beginScan()
    }
    
    
    func beginScan() {
        if #available(iOS 11.0, *){
            session = NFCNDEFReaderSession.init(delegate: self, queue: nil, invalidateAfterFirstRead: true)
            session?.alertMessage = "Hold your iPhone near an NFC Type 2 tag."
            session?.begin()
        }
    }
    //停止扫描
    func invalidateSession() {
        session?.invalidate()
    }
    
    //MARK: NFCNDEFReaderSessionDelegate
    //读取失败回调-读取成功后还是会回调这个方法
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    print("\(error)")
        if let readerError = error as? NFCReaderError {
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead) && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
        }
    }
    }
    //读取成功
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            session.alertMessage = "读取成功"
            if scanSuccessBlock != nil {
                scanSuccessBlock!(message)
            }
        }
    }
    /// - Tag: writeToTag
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected, please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
    }
}
