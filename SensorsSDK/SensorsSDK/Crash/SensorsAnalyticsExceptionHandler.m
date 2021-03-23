//
//  SensorsAnalyticsExceptionHandler.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/25.
//

#import "SensorsAnalyticsExceptionHandler.h"

#import "SensorsAnalyticsSDK.h"

static NSString * const SensorDataSignalExceptionHandlerName = @"SignalExceptionHandler";
static NSString * const SensorDataSignalExceptionHandlerUserInfo = @"SignalExceptionhandlerUserInfo";

@interface SensorsAnalyticsExceptionHandler ()

/// 保存之前已设置的全局函数
@property (nonatomic, assign) NSUncaughtExceptionHandler *previousExceptionHandler;

@end


@implementation SensorsAnalyticsExceptionHandler

+ (instancetype)sharedInstance {
    static SensorsAnalyticsExceptionHandler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SensorsAnalyticsExceptionHandler alloc]  init];
    });
    return instance;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _previousExceptionHandler = NSGetUncaughtExceptionHandler();
        // 通过 NSSetUncaughtExceptionHandler 函数全局设置异常处理函数
        NSSetUncaughtExceptionHandler(&sensorsdata_uncaught_exception_handler);
        
        // 定义信号集结构体
        struct sigaction sig;
        // 将信号集初始化为空
        sigemptyset(&sig.sa_mask);
        // 在处理函数中传入 __siginfo 参数
        sig.sa_flags = SA_SIGINFO;
        // 设置信号集处理函数
        sig.sa_sigaction = &sensorsdata_signal_exceptin_handler;
        // 定义需要采集的信号类型
        int signals[] = {SIGILL, SIGABRT, SIGBUS, SIGFPE, SIGSEGV};
        for (int i = 0; i < sizeof(signals) / sizeof(int); i ++) {
            // 注册信号处理
            int err = sigaction(signals[i], &sig, NULL);
            if (err) {
                NSLog(@"Errored while trying to set up sigactin for signal %d", signals[i]);
            }
        }
    }
    return self;
}

// 全局函数，采集异常相关的信息
static void sensorsdata_uncaught_exception_handler(NSException *exception) {
    // 采集 $AppCrashed 事件
    [[SensorsAnalyticsExceptionHandler sharedInstance] trackAppCrashedWithException:exception];
    
    // 调用之前已设置的异常处理函数
    // 通过这样的处理，即可把所有的异常处理函数形成链条，确保之前设置的异常处理函数的 SDK 也能采集到的异常信息。不过如果后面设置的异常处理函数的 SDK 没有有效地传递信息，可能也会导致无法采集到异常信息
    NSUncaughtExceptionHandler *handler = [SensorsAnalyticsExceptionHandler sharedInstance].previousExceptionHandler;
    if (handler) {
        handler(exception);
    }
    
}

- (void)trackAppCrashedWithException:(NSException *)exception {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 异常名称
    NSString *name = [exception name];
    // 出错原因
    NSString *reason = [exception reason];
    // 异常堆栈信息
    NSArray *stacks = [exception callStackSymbols];
//    // 异常 userInfo
//    NSDictionary *userInfo = [exception userInfo];
//    NSArray *callStackReturnAddresses = [exception callStackReturnAddresses];
    
    // 将异常信息
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception name:%@\nException reason:%@\nException stacks:%@", name, reason, stacks];
    // 设置 app_crashed_reason 属性
    properties[@"$app_crashed_reason"] = exceptionInfo;
    
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppCrashed" properties:properties];
    
    // 采集 $AppEnd 回调 block
    dispatch_block_t trackAppEndBlock = ^{
        // 判断应用是否处于运行状态
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            // 触发事件
            [[SensorsAnalyticsSDK sharedInstance] track:@"$AppEnd" properties:nil];
        }
    };
    
    // 获取主线程
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // 判断当前线程是否为主线程
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(mainQueue)) == 0) {
        // 如果当前线程是主线程，直接调用 block
        trackAppEndBlock();
    } else {
        // 如果当前线程不是主线程，同步调用 block
        dispatch_sync(mainQueue, trackAppEndBlock);
    }
    
    // 获取 SensorsAnalyticsSDK 中的 serialQueue
    dispatch_queue_t serialQueue = [[SensorsAnalyticsSDK sharedInstance] valueForKeyPath:@"serialQueue"];
    // 阻塞当前线程， 让 serialQueue 执行完成
    dispatch_sync(serialQueue, ^{});
    
    // 获取数据存储时的线程
    dispatch_queue_t databaseQueue = [[SensorsAnalyticsSDK sharedInstance] valueForKeyPath:@"database.queue"];
    // 阻塞当前线程，让$AppCrashed 事件完成入库
    dispatch_sync(databaseQueue, ^{});
    
    NSSetUncaughtExceptionHandler(NULL);
    
    int signals[] = {SIGILL, SIGABRT, SIGBUS, SIGFPE, SIGSEGV};
    for (int i = 0; i < sizeof(signals) / sizeof(int); i ++) {
        signal(signals[i], SIG_DFL);
    }
}


static void sensorsdata_signal_exceptin_handler(int sig, struct __siginfo *info, void *context) {
    NSDictionary *userInfo = @{SensorDataSignalExceptionHandlerUserInfo: @(sig)};
    NSString *reason = [NSString stringWithFormat:@"Signal %d was raised.", sig];
    // 创建一个异常对象，用于采集异常信息
    NSException *exception = [NSException exceptionWithName:SensorDataSignalExceptionHandlerName reason:reason userInfo:userInfo];
    SensorsAnalyticsExceptionHandler *handler = [SensorsAnalyticsExceptionHandler sharedInstance];
    [handler trackAppCrashedWithException:exception];
}

@end
