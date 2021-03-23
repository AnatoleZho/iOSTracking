//
//  SensorsAnalyticsNetwork.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/25.
//

#import "SensorsAnalyticsNetwork.h"

/// 网络请求结束处理回调类型
typedef void(^SAURLSessionTaskCompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);

@interface SensorsAnalyticsNetwork ()<NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation SensorsAnalyticsNetwork

- (instancetype)initWithServerURL:(NSURL *)serverURL {
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        // 创建默认的 session 配置对象
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 设置单个主机连接数
        configuration.HTTPMaximumConnectionsPerHost = 5;
        // 设置请求超时时间
        configuration.timeoutIntervalForRequest = 30;
        // 允许使用蜂窝连接
        configuration.allowsCellularAccess = YES;
        
        // 创建一个网络请求回调和完成操作的线程池
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        // 设置同步进行的最大操作数 为1 即 FIFO
        queue.maxConcurrentOperationCount = 1;
        
        // 通过配置对象创建一个session
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
    }
    return self;
}

/// 将事件数组转化为字符串
- (NSString *)buildJSONStringWithEvents: (NSArray<NSString *> *)events {
    return [NSString stringWithFormat:@"[\n%@\n]", [events componentsJoinedByString:@"\n"]];
}

// 根据 serverurl 和 json字符串 创建 NSURLRequest 请求
- (NSURLRequest *)buildRequestWithJSONString: (NSString *)jsonString {
    // 通过服务器 URL创建请求
    NSMutableURLRequest *requst = [NSMutableURLRequest requestWithURL:self.serverURL];
    
    // 设置请求 body
    requst.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

    requst.HTTPMethod = @"POST";
    
    return requst;
}


-(BOOL)flushEvents:(NSArray<NSString *> *)events {
    // 将事件数组组装成JSON字符串
    NSString *jsonString = [self buildJSONStringWithEvents:events];
    // 创建请求对象
    NSURLRequest *request = [self buildRequestWithJSONString:jsonString];
    // 数据上传结果
    __block BOOL flushSuccess = NO;
    // 使用 GCD 中的信号量，实现线程锁
    dispatch_semaphore_t flushSemaphore = dispatch_semaphore_create(0);
    SAURLSessionTaskCompletionHandler handler = ^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error) {
            // 当请求发生错误时，打印信息错误
            NSLog(@"Flush events error: %@", error);
            dispatch_semaphore_signal(flushSemaphore);
            return;;
        }
        // 创建 请求结束返回的状态码
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        // 当状态码是 2XX时表示事件发送成功
        if (statusCode >= 200 && statusCode < 300) {
            // 打印上传成功的数据
            NSLog(@"Flush events success: %@", jsonString);
            // 数据上传成功
            flushSuccess = YES;
        } else {
            // 事件信息发送失败
            NSString *desc = [NSString stringWithFormat:@"Flush events error, statusCode: %d, events: %@", (int)statusCode,jsonString];
            NSLog(@"%@",desc);
        }
        dispatch_semaphore_signal(flushSemaphore);
    };
    
    // 通过 request 创建 task
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
    // 执行任务
    [task resume];
    
    // 等待请求完成
    dispatch_semaphore_wait(flushSemaphore, DISPATCH_TIME_FOREVER);
    // 返回数据上传结果
    return flushSuccess;
}


@end
