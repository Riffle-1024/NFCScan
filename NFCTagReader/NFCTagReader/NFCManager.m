//
//  NFCManager.m
//  NFCTagReader
//
//  Created by liuyalu on 2021/11/19.
//

#import "NFCManager.h"

@interface NFCManager ()<NFCTagReaderSessionDelegate>{
    BOOL isReading;
}

@property (strong, nonatomic) NFCTagReaderSession *tagReaderSession;

@property (strong, nonatomic) NFCNDEFMessage *message;

@property(nonatomic,weak)id<NFCISO7816Tag> currentTag;

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

-(void)scanTagWithSuccessBlock:(NFCScanSuccessBlock)scanSuccessBlock andErrorBlock:(NFCScanErrorBlock)scanErrorBlock{
    self.scanSuccessBlock=scanSuccessBlock;
    self.scanErrorBlock=scanErrorBlock;
    isReading=YES;
    [self beginScan];
}

-(void)writeMessage:(NFCNDEFMessage *)message ToTagWithSuccessBlock:(NFCWriteSuccessBlock)writeSuccessBlock andErrorBlock:(NFCWritErrorBlock)writErrorBlock{
    self.message=message;
    self.writeSuccessBlock=writeSuccessBlock;
    self.writErrorBlock=writErrorBlock;
    isReading=NO;
    [self beginScan];
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
+(NFCSupportsStatus)isSupportsNFCWrite{
    if (@available(iOS 13.0,*)) {
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
-(void)beginScan{
    if (@available(iOS 11.0, *)) {
        self.tagReaderSession = [[NFCTagReaderSession alloc]initWithPollingOption:NFCPollingISO14443 delegate:self queue:dispatch_queue_create("beckhams",DISPATCH_QUEUE_SERIAL)];
        self.tagReaderSession.alertMessage = @"message";
            [self.tagReaderSession beginSession];
        
    }
}


-(NFCNDEFMessage*)createAMessage{
    NSString* type = @"U";
    NSData* typeData = [type dataUsingEncoding:NSUTF8StringEncoding];
    NSString* identifier = @"12345678";
    NSData* identifierData = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    NSString* payload1 = @"ahttps://www.baidu.com";
    NSData* payloadData1 = [payload1 dataUsingEncoding:NSUTF8StringEncoding];
    if (@available(iOS 13.0, *)) {
        NFCNDEFPayload *NDEFPayload1=[[NFCNDEFPayload alloc]initWithFormat:NFCTypeNameFormatNFCWellKnown type:typeData identifier:identifierData payload:payloadData1];
        NFCNDEFMessage* message = [[NFCNDEFMessage alloc]initWithNDEFRecords:@[NDEFPayload1]];
        return message;
    } else {
        return nil;
    }
}

//停止扫描
-(void)invalidateSession{
    [self.tagReaderSession invalidateSession];
}




- (void)tagReaderSession:(NFCTagReaderSession *)session didDetectTags:(NSArray<__kindof id<NFCTag>> *)tags API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(watchos, macos, tvos){
    if (tags.count > 1){
        NSLog(@"读卡错误");
        return;
    }
    
    
    id<NFCISO7816Tag> Tag7816 = [tags.firstObject asNFCISO7816Tag];
    //这里的Tag7816实例是用于后面发送指令的对象。
    if (Tag7816 == nil){
        NSLog(@"读取到的非7816卡片");
        return;
    }
    // 这里获取到的AID就是第一步中在info.plist中设置的ID （A000000000）这个值一般是卡商提供的，代表卡的应用表示。
    NSLog(@"Tag7816.initialSelectedAID:%@",Tag7816.initialSelectedAID);
    __weak typeof(self) weakSelf = self;
    [self.tagReaderSession connectToTag:Tag7816 completionHandler:^(NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error){
            NSLog(@"TconnectToTag:%@",error);
            return;
        }
        self.currentTag = Tag7816;
        self.tagReaderSession.alertMessage = @"已识别到NFC";
        // 这里就可以开始执行指令和cpu卡交互了。
        [self sendApduSingle:@"00A400000112501"];//16进制指令

        
    }];
}
// 发送指令的示例代码：
-(void)sendApduSingle:(NSString *)apduStr{
    //  apduStr 是发送的指令字符串，比如 00A5030004B000000033434561
    NSData *apduData = [self convertHexStrToData:apduStr]; // 把指令转成data格式
    NFCISO7816APDU *cmd = [[NFCISO7816APDU alloc]initWithData:apduData];  // 初始化 NFCISO7816APDU。
    
    __block NSData *recvData = nil;
    __block NSError *lerror = nil;
    __block BOOL bRecv = NO;
    __block int lsw = 0;
    NSLog(@"send data => %@", apduData);
    
    // 这里的Tag7816就是上面协议中拿到的tag
    [self.currentTag sendCommandAPDU:cmd completionHandler:^(NSData * _Nonnull responseData, uint8_t sw1, uint8_t sw2, NSError * _Nullable error) {
        NSLog(@"------resp:%@ sw:%02x%02x  error:%@", responseData, sw1, sw2, error);
        NSLog(@"responseData十六进制：%@", [self convertApduListDataToHexStr:responseData]);
        lerror = error;
        lsw = sw1;
        lsw = (lsw << 8) | sw2;
        if (responseData) {
            recvData = [[NSData alloc]initWithData:responseData];
        }
        // 拿到返回的数据了，根据具体的业务需求去写代码。。。。
        [self invalidateSession];
    }];
}


//将字符串转NSData
- (NSData *)convertHexStrToData:(NSString *)str {
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}


//NSData转字符串
-(NSString *)convertApduListDataToHexStr:(NSData *)data{
        if (!data || [data length] == 0) {
            return @"";
        }
        NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
        [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
            unsigned char *dataBytes = (unsigned char*)bytes;
            for (NSInteger i = 0; i < byteRange.length; i++) {
                NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
                if ([hexStr length] == 2) {
                        [string appendString:hexStr];
                } else {
                    [string appendFormat:@"0%@", hexStr];
                }
            }
        }];
        return [string uppercaseString];
}

- (void)tagReaderSession:(NFCTagReaderSession *)session didInvalidateWithError:(NSError *)error API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(watchos, macos, tvos){
    NSLog(@"%@",error);
}


@end
