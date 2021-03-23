//
//  SensorsAnaluticsExtensionManager.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/3/17.
//

#import "SensorsAnaluticsExtensionManager.h"

static NSString * const KsenforsExtensionFileName = @"senfors_analytics_extension_events.plist";

@implementation SensorsAnaluticsExtensionManager

+ (instancetype)sharedInstance {
    static SensorsAnaluticsExtensionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SensorsAnaluticsExtensionManager alloc] init];
    });
    return manager;
}

- (NSURL *)fileURLForApplicationGroupIdentifier:(NSString *)identifier {
    return [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:identifier] URLByAppendingPathComponent:KsenforsExtensionFileName];
}


/// 把所有事件数据写入到文件中保存
/// @param events 所有事件的数据
/// @param url  事件数据写入文件地址
- (void)writeEvents:(NSArray<NSDictionary *> *)events toURL: (NSURL *)url {
    // json 解析错误信息
    NSError *error = nil;
    // 将字典数据解析成 JSON 数据
    NSData *data = [NSJSONSerialization dataWithJSONObject:events options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return NSLog(@"The json object's serialization error: %@", error);
    }
    // 将数据写入文件
    [data writeToURL:url atomically:YES];
}


/// 从路径中获取所有事件数据
/// @param url 获取所有事件数据的文件
- (NSMutableArray<NSDictionary *> *)allEventsForURL: (NSURL *)url {
    // 从文件中初始化 NSData 对象
    NSData *data = [NSData dataWithContentsOfURL:url];
    // 当本地文件中没有 data 时，直接返回空数组
    if (data.length == 0) {
        return [NSMutableArray array];
    }
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary<NSString *,id> *)properties applicationGroupIdentifier:(NSString *)identifier {
    
}

@end
