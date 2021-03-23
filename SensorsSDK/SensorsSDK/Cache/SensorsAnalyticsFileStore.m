//
//  SensorsAnalyticsFileStore.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/24.
//

#import "SensorsAnalyticsFileStore.h"



// 默认文件名
static NSString * const SensorsAnalyticsDefaultFileName = @"SensorsAnalyticsData.plist";

@interface SensorsAnalyticsFileStore ()

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *events;

/// 串行队列
@property (nonatomic, strong) dispatch_queue_t queue;


@end

@implementation SensorsAnalyticsFileStore

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 初始化默认路径
        _filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:SensorsAnalyticsDefaultFileName];
        NSLog(@"%@", _filePath);
        
//        // 初始化事件数据，后面会先读取本地保存的事件数据
//        _events = [NSMutableArray array];
        
        // 初始化串行队列的唯一标识
        NSString *label = [NSString stringWithFormat:@"cn.sensorsdata.serialQueue.%p", self];
        // 创建一个 serial 类型的 queue，即 FIFO
        _queue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        
        // 初始化本地最大缓存事件条数
        _maxLocalEventCount = 100;
        
        // 从文件中读取数据
        [self readAllEventsFromFilePath:_filePath];
    }
    return self;
}

-(void)saveEvent:(NSDictionary *)event {
    
//    // 在数组中直接添加事件数据
//    [self.events addObject:event];
//    // 将事件保存在文件中
//    [self writeEventToFile];
    
    // 异步处理
    dispatch_async(self.queue, ^{
        // 如果当前事件条数超过最大值，删除最旧的事件数据
        if (self.events.count >= self.maxLocalEventCount) {
            [self.events removeObjectAtIndex:0];
        }
        // 在数组中直接添加事件数据
        [self.events addObject:event];
        // 将事件保存在文件中
        [self writeEventToFile];
    });
}

- (void)writeEventToFile {
    
    // JSON 解析错误信息
    NSError *error = nil;
    // 将字典数据解析成 JSON 数据
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.events options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return NSLog(@"The json object's serialization error: %@", error);
    }
    
    [data writeToFile:self.filePath atomically:YES];
}

- (void)readAllEventsFromFilePath: (NSString *)filePath {
//    // 从文件路径中读取数据
//    NSData *data = [NSData dataWithContentsOfFile:filePath];
//    if (data) {
//        // 解析在文件中的 JSON 数据
//        NSError *error = nil;
//        NSMutableArray *allEvents = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
//        if (error) {
//            return NSLog(@"The data serialization error: %@", error);
//        }
//        self.events = allEvents ?: [NSMutableArray array];
//    } else {
//        self.events = [NSMutableArray array];
//    }
    
    dispatch_async(self.queue, ^{
        // 从文件路径中读取数据
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (data) {
            // 解析在文件中的 JSON 数据
            NSError *error = nil;
            NSMutableArray *allEvents = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (error) {
                return NSLog(@"The data serialization error: %@", error);
            }
            self.events = allEvents ?: [NSMutableArray array];
        } else {
            self.events = [NSMutableArray array];
        }
    });
}

-(NSArray<NSDictionary *> *)allEvents {
//    return [self.events copy];
    
    __block NSArray<NSDictionary *> *allEvnets = nil;
    dispatch_async(self.queue, ^{
        allEvnets = [self.events copy];
    });
    
    return allEvnets;
}

-(void)deleteEventsForCount:(NSInteger)count {
//    // 删除前 count 条事件数据
//    [self.events removeObjectsInRange:NSMakeRange(0, count)];
//    // 将删除后剩余的数据保存到文件中
//    [self writeEventToFile];
    
    dispatch_async(self.queue, ^{
        // 删除前 count 条事件数据
        [self.events removeObjectsInRange:NSMakeRange(0, count)];
        // 将删除后剩余的数据保存到文件中
        [self writeEventToFile];
    });
}

@end
