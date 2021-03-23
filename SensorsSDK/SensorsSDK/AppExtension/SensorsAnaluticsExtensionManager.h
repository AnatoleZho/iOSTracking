//
//  SensorsAnaluticsExtensionManager.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/3/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnaluticsExtensionManager : NSObject

+ (instancetype)sharedInstance;


/// 根据 APP Group Identifier 获取文件存储路径
/// @param identifier  APP group identifier
/// return 路径
- (NSURL *)fileURLForApplicationGroupIdentifier: (NSString *)identifier;


/// 触发事件，采集事件名以及相关属性
/// @param event 事件名
/// @param properties 事件属性
/// @param identifier app group identifier
- (void)track: (NSString *)event properties: (NSDictionary<NSString *, id> *)properties applicationGroupIdentifier: (NSString *)identifier;
@end

NS_ASSUME_NONNULL_END
