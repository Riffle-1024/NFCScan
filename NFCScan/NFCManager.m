//
//  NFCManager.m
//  NFCScan
//
//  Created by Riffle on 2021/11/18.
//

#import "NFCManager.h"


@interface NFCManager()<NFCNDEFReaderSessionDelegate>{
    BOOL isReading;
}

@property (strong, nonatomic) NFCNDEFReaderSession *session;

@property (strong, nonatomic) NFCNDEFMessage *message;

@end
@implementation NFCManager

#pragma mark - 单例方法
+(NFCManager *)sharedInstance{
    static dispatch_once_t onceToken;
    static NFCManager * sSharedInstance;
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[NFCManager alloc] init];
    });
    return sSharedInstance;
}

+(NFCSupportsStatus)isSupportsNFCReading{
    if (@available(iOS 11.0,*)) {
        if (NFCNDEFReaderSession.readingAvailable == YES) {
            return NFCSupportStatusYes;
        }
        else{
            NSLog(@"%@",@"该机型不支持NFC功能!");
            return NFCSupportStatusDeviceNo;
        }
    }
    else {
        NSLog(@"%@",@"当前系统不支持NFC功能!");
        return NFCSupportStatusnSystemNo;
    }
}


-(void)scanTagWithSuccessBlock:(NFCScanSuccessBlock)scanSuccessBlock andErrorBlock:(NFCScanErrorBlock)scanErrorBlock{
    self.scanSuccessBlock=scanSuccessBlock;
    self.scanErrorBlock=scanErrorBlock;
    isReading=YES;
    [self beginScan];
}


-(void)beginScan{
    if (@available(iOS 11.0, *)) {
        self.session = [[NFCNDEFReaderSession alloc]initWithDelegate:self queue:nil invalidateAfterFirstRead:NO];
        self.session.alertMessage = @"准备扫描，请将卡片贴近手机";
        [self.session beginSession];
    }
}

//停止扫描
-(void)invalidateSession{
        [self.session invalidateSession];

}

#pragma mark - NFCNDEFReaderSessionDelegate
//读取失败回调-读取成功后还是会回调这个方法
- (void)readerSession:(NFCNDEFReaderSession *)session didInvalidateWithError:(NSError *)error API_AVAILABLE(ios(11.0)){
    NSLog(@"%@",error);
    if (error.code == 201) {
        NSLog(@"扫描超时");
    }
    if (error.code == 200) {
        NSLog(@"取消扫描");
    }
}

//读取成功回调iOS11-iOS12
- (void)readerSession:(NFCNDEFReaderSession *)session didDetectNDEFs:(NSArray*)messages
API_AVAILABLE(ios(11.0)){
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->isReading) {
            if (@available(iOS 11.0, *)) {
                for (NFCNDEFMessage *message in messages) {
                    session.alertMessage = @"读取成功";
                    [self invalidateSession];
                    if (self.scanSuccessBlock) {
                        self.scanSuccessBlock(message);
                    }
                }
            }
        }
        else{
            //ios11-ios12下没有写入功能返回失败
            session.alertMessage = @"读取失败";
            [self invalidateSession];
        }
        
    });
}

//读取成功回调iOS13
- (void)readerSession:(NFCNDEFReaderSession *)session didDetectTags:(NSArray<__kindof id<NFCNDEFTag>> *)tags API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(watchos, macos, tvos){
    dispatch_async(dispatch_get_main_queue(), ^{
        if (tags.count>1) {
            session.alertMessage=@"存在多个标签";
            [session restartPolling];
            return;
        }
        id  tag=tags.firstObject;
        [session connectToTag:tag completionHandler:^(NSError * _Nullable error) {
            if (error) {
                session.alertMessage = @"连接NFC标签失败";
                [self invalidateSession];
                return;
            }
            [tag queryNDEFStatusWithCompletionHandler:^(NFCNDEFStatus status, NSUInteger capacity, NSError * _Nullable error) {
                if (error) {
                    session.alertMessage = @"查询NFC标签状态失败";
                    [self invalidateSession];
                    return;
                }
                if (status == NFCNDEFStatusNotSupported) {
                    session.alertMessage = @"标签不是NDEF格式";
                    [self invalidateSession];
                    return;
                }
                if (self->isReading) {
                    //读
                    [tag readNDEFWithCompletionHandler:^(NFCNDEFMessage * _Nullable message, NSError * _Nullable error) {
                        if (error) {
                            session.alertMessage = @"读取NFC标签失败";
                            [self invalidateSession];
                        }
                        else if (message==nil) {
                            session.alertMessage = @"NFC标签为空";
                            [self invalidateSession];
                            return;
                        }
                        else {
                            session.alertMessage = @"读取成功";
                            [self invalidateSession];
                            if (self.scanSuccessBlock) {
                                self.scanSuccessBlock(message);
                            }
                        }
                    }];
                }
                else{
                    //写数据
                    [tag writeNDEF:self.message completionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            session.alertMessage = @"写入失败";
                            if (self.writErrorBlock) {
                                self.writErrorBlock(error);
                            }
                        }
                        else {
                            session.alertMessage = @"写入成功";
                            if (self.writeSuccessBlock) {
                                self.writeSuccessBlock();
                            }
                        }
                        [self invalidateSession];
                    }];
                }
            }];
        }];
    });
}

- (void)readerSessionDidBecomeActive:(NFCNDEFReaderSession *)session API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(watchos, macos, tvos){
    
}
@end
