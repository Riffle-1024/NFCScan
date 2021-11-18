//
//  NFCManager.h
//  NFCScan
//
//  Created by Riffle on 2021/11/18.
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
API_AVAILABLE(ios(13.0))
typedef void(^NFCWriteSuccessBlock)(void);
typedef void(^NFCWritErrorBlock)(NSError *error);

API_AVAILABLE(ios(11.0))

@interface NFCManager : NSObject

@property(nonatomic,copy)NFCScanSuccessBlock scanSuccessBlock;
@property(nonatomic,copy)NFCScanErrorBlock scanErrorBlock;
@property(nonatomic,copy)NFCWriteSuccessBlock writeSuccessBlock;
@property(nonatomic,copy)NFCWritErrorBlock writErrorBlock;

+(NFCManager *)sharedInstance;

//判断是否支持读写功能
+(NFCSupportsStatus)isSupportsNFCReading;
-(void)scanTagWithSuccessBlock:(NFCScanSuccessBlock)scanSuccessBlock andErrorBlock:(NFCScanErrorBlock)scanErrorBlock;

@end

NS_ASSUME_NONNULL_END
