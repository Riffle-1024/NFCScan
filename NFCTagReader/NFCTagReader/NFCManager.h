//
//  NFCManager.h
//  NFCTagReader
//
//  Created by liuyalu on 2021/11/19.
//

#import <Foundation/Foundation.h>
#import <CoreNFC/CoreNFC.h>


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NFCSupportsStatus) {
    NFCSupportStatusYes,//支持
    NFCSupportStatusDeviceNo,//硬件不支持
    NFCSupportStatusnSystemNo,//系统不支持
};

API_AVAILABLE(ios(11.0))
typedef void(^NFCScanSuccessBlock)(NFCNDEFMessage *message);
typedef void(^NFCScanErrorBlock)(NSError *error);
typedef void(^NFCWriteSuccessBlock)(void);
typedef void(^NFCWritErrorBlock)(NSError *error);

API_AVAILABLE(ios(11.0))
@interface NFCManager : NSObject
@property(nonatomic,copy)NFCScanSuccessBlock scanSuccessBlock;
@property(nonatomic,copy)NFCScanErrorBlock scanErrorBlock;
@property(nonatomic,copy)NFCWriteSuccessBlock writeSuccessBlock;
@property(nonatomic,copy)NFCWritErrorBlock writErrorBlock;
@property(nonatomic,assign) BOOL moreTag;//多标签识别




+(NFCManager *)sharedInstance;
-(void)scanTagWithSuccessBlock:(NFCScanSuccessBlock)scanSuccessBlock andErrorBlock:(NFCScanErrorBlock)scanErrorBlock;
-(void)writeMessage:(NFCNDEFMessage *)message ToTagWithSuccessBlock:(NFCWriteSuccessBlock)writeSuccessBlock andErrorBlock:(NFCWritErrorBlock)writErrorBlock;
//判断是否支持读写功能
+(NFCSupportsStatus)isSupportsNFCReading;
+(NFCSupportsStatus)isSupportsNFCWrite;

@end

NS_ASSUME_NONNULL_END
