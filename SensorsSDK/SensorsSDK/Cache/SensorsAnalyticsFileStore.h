//
//  SensorsAnalyticsFileStore.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsFileStore : NSObject

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *allEvents;

// 本地可最大缓存事件条数
@property (nonatomic, assign) NSInteger maxLocalEventCount;

/// 将事件保存到文件中
/// @param event 事件数据
- (void)saveEvent: (NSDictionary *)event;


/// 根据数量删除本地保存的事件数据
/// @param count 需要删除的事件数量
- (void)deleteEventsForCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
