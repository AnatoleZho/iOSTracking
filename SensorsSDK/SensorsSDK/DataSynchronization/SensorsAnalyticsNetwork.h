//
//  SensorsAnalyticsNetwork.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsNetwork : NSObject

@property (nonatomic, strong) NSURL *serverURL;


/// 指定初始化方法
/// @param serverURL 服务器URL地址
- (instancetype)initWithServerURL: (NSURL *)serverURL NS_DESIGNATED_INITIALIZER;


/// 禁止直接使用 -init 方法初始化
- (instancetype)init NS_UNAVAILABLE;


/// 同步数据
/// @param events 事件数组
/// @return 同步结果
- (BOOL)flushEvents:(NSArray<NSString *> *)events;


@end

NS_ASSUME_NONNULL_END
