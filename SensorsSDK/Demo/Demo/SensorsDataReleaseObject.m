//
//  SensorsDataReleaseObject.m
//  Demo
//
//  Created by AnatoleZhou on 2021/2/26.
//

#import "SensorsDataReleaseObject.h"

@implementation SensorsDataReleaseObject

- (void)signalCrash {
    NSMutableArray<NSString *> *array = [NSMutableArray array];
    [array addObject:@"First"];
    [array release];
    
    // 这里会崩溃，因为 array 已经被释放，访问不存在的地址
    NSLog(@"Crash: %@", array.firstObject);
}

@end
