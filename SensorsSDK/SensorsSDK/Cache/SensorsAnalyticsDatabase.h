//
//  SensorsAnalyticsDatabase.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/24.
//

#import <Foundation/Foundation.h>

#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsDatabase : NSObject

/// 数据库文件路径
@property (nonatomic, copy, readonly) NSString *filePath;

@property (nonatomic, assign) sqlite3 *database;


/// 本地事件存储条数
@property (nonatomic, assign) NSUInteger eventCount;


/// 初始化方法
/// @param filePath 数据库路径，如果为 nil，使用默认路径
/// return 数据库管理对象
- (instancetype)initWithFilePath:(nullable NSString *)filePath NS_DESIGNATED_INITIALIZER;


/// 同步向数据库中插入数据
/// @param event 事件
- (void)insertEvent:(NSDictionary *)event;


/// 从数据库中获取事件数据
/// @param count 获取事件数据的条数
/// @return 事件数据
- (NSArray<NSString *> *)selectEventsForCount: (NSUInteger)count;


/// 从数据库中删除一定数量的事件数据
/// @param count 需要删除的事件数量
/// @return 是否成功删除数据
-(BOOL)deleteEventsForCount: (NSInteger)count;
@end

NS_ASSUME_NONNULL_END
