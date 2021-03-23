//
//  SensorsAnalyticsSDK.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/18.
//

#import "SensorsAnalyticsSDK.h"
#include <sys/sysctl.h>

#import "UIView+SensorData.h"

#import "SensorsAnalyticsKeychainItem.h"

#import "SensorsAnalyticsFileStore.h"

#import "SensorsAnalyticsDatabase.h"

#import "SensorsAnalyticsNetwork.h"

#import "SensorsAnalyticsExceptionHandler.h"

#import <WebKit/WebKit.h>

static NSString * const SensorsAnalyticsVersion = @"1.0.0";

static NSString * const SensorsAnalyticsAnonymousId = @"cn.sensorsdata.anonymous_id";

static NSString * const SensorsAnalyticsKeychainService = @"cn.sensorsdata.SensorsAnalytics.id";

static NSString * const SensorsAnalyticsLoginId = @"cn.sensorsdata.login_id";

static NSString * const SensorsAnalyticsEventBeginKey = @"event_begin";

static NSString * const SensorsAnalyticsEventDurationKey = @"event_duration";

static NSString * const SensorsAnalyticsEventIsPauseKey = @"is_pause";

static NSUInteger const SensorsAnalyticsDefaultFlushEventCount = 50;



@interface SensorsAnalyticsSDK ()
{
    NSString *_anonymousId;
}

/// 由 SDK 默认自动采集的事件属性即为预置属性
/**
 操作系统类型，操作系统版本号，运营商信息，应用程序版本号，生产厂商等
 */
@property (nonatomic, strong) NSDictionary<NSString *, id> *automaticProperties;

/// 标记是否为 被动启动
@property (nonatomic, assign, getter=isLaunchedPassively) BOOL launchedPassively;

/// 事件开始发生的时间戳
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *trackTimer;

/// 保存进入后台时未暂停的事件名称
@property (nonatomic, strong) NSMutableArray<NSString *> *enterBackgroundTrackTimerEvents;

/// 文件缓存事件数据对象
@property (nonatomic, strong) SensorsAnalyticsFileStore *fileStore;

/// 数据库缓存事件数据对象
@property (nonatomic, strong) SensorsAnalyticsDatabase *database;

/// 发送网络请求对象
@property (nonatomic, strong) SensorsAnalyticsNetwork *netowork;

/// 标记应用程序是否收到 UIApplicationWillResignActiveNotification
@property (nonatomic, assign) BOOL applicationWillResignActive;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, strong) NSTimer *flushTimer; // 策略二

/// 由于 WKWebview 获取 UserAgent 是异步的，为了在获取过程中创建的 WKWebview 对象不被销毁，需要保存创建的临时对象
@property (nonatomic, strong) WKWebView *wevView;

@end

@implementation SensorsAnalyticsSDK

//+ (SensorsAnalyticsSDK *)sharedInstance {
//    static dispatch_once_t onceToken;
//    static SensorsAnalyticsSDK *instance = nil;
//    dispatch_once(&onceToken, ^{
//        instance = [[SensorsAnalyticsSDK alloc] init];
//    });
//
//    return instance;
//}

static SensorsAnalyticsSDK *instance = nil;

+ (SensorsAnalyticsSDK *)sharedInstance {
    return instance;
}

+ (void)startWithServerURL:(NSString *)serverURLStr {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SensorsAnalyticsSDK alloc] initWithServerURL:serverURLStr];
    });
}

- (instancetype)initWithServerURL:(NSString *)serverURLStr {
    self = [super init];
    if (self) {
        _automaticProperties = [self collectAutomaticProperties];
        
        // 设置是否被动启动标记
        /*
         UIApplication 的 backgroundTimeRemaining 属性，当 引用程序进入前台运行时， backgroundTimeRemaining 会被设置为 UIApplicationBackgroundFetchIntervalNever
         */
        _launchedPassively = UIApplication.sharedApplication.backgroundTimeRemaining != UIApplicationBackgroundFetchIntervalNever;
        
        _loginId = [[NSUserDefaults standardUserDefaults] objectForKey:SensorsAnalyticsLoginId];
        
        _trackTimer = [NSMutableDictionary dictionary];
        
        _enterBackgroundTrackTimerEvents = [NSMutableArray array];
        
        _fileStore = [[SensorsAnalyticsFileStore alloc] init];
        
        // 初始化 SensorsAnalyticsDatabase 类的的对象，使用默认路径
        _database = [[SensorsAnalyticsDatabase alloc] init];
        
        // 配置一个可用的 ServerURL
        _netowork = [[SensorsAnalyticsNetwork alloc] initWithServerURL:[NSURL URLWithString:@""]];
        
        NSString *queueLabel = [NSString stringWithFormat:@"cn.sensorsdata.%@.%p", self.class, self];
        _serialQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        
        _flushBulkSize = 100;
        _flushInterval = 15;

        [self startFlushTimer];
        
        // 调用异常处理单例对象，进行初始化
        [SensorsAnalyticsExceptionHandler sharedInstance];
        
        
        // 添加应用程序状态监听
        [self setupListeners];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)login:(NSString *)loginId {
    self.loginId = loginId;
    
    // 保存到本地
    [[NSUserDefaults standardUserDefaults] setObject:loginId forKey:SensorsAnalyticsLoginId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        // 默认一次向服务器发送50条
        [self flushByEventCount:SensorsAnalyticsDefaultFlushEventCount background:NO];
    });
}

- (void)flushByEventCount: (NSUInteger)count background: (BOOL)background {
    if (background) {
        __block BOOL isContinue = YES;
        dispatch_sync(dispatch_get_main_queue(), ^{
           // 当运行时间 大于 请求超时时间时，为保证数据库删除时应用不被枪杀，不再继续上传
            isContinue = UIApplication.sharedApplication.backgroundTimeRemaining >= 30;
        });
        if (!isContinue) {
            return;
        }
    }
    // 获取本地数据
    NSArray<NSString *> *events = [self.database selectEventsForCount:count];
    // 当本地存储数据为 0 或者上传失败时，直接返回，退出递归调用
    if (events.count == 0 || ![self.netowork flushEvents:events]) {
        return;
    }
    
    // 当删除失败时，直接返回，退出递归调用，防止死循环
    if (![self.database deleteEventsForCount:count]) {
        return;
    }
    // 继续上传本地的其他数据
    [self flushByEventCount:count background:background];
}

-(void)setAnonymousId:(NSString *)anonymousId {
    _anonymousId = anonymousId;
    [self saveAnonymousId:anonymousId];
}

- (NSString *)anonymousId {
    if (_anonymousId) {
        return _anonymousId;
    }
    _anonymousId = [[[SensorsAnalyticsKeychainItem alloc] initWithService:SensorsAnalyticsKeychainService key:SensorsAnalyticsAnonymousId] value];
    if (_anonymousId) {
        return _anonymousId;
    }
    // 从 NSUserDefaults 中获取设备 ID
    _anonymousId = [[NSUserDefaults standardUserDefaults] objectForKey:SensorsAnalyticsAnonymousId];
    if (_anonymousId) {
        return _anonymousId;
    }
    
    // 获取 IDFA
    Class cls = NSClassFromString(@"ASIdentifierManager");
    if (cls) {
#pragma clang diagnostic push
#pragma clang diagnotic ignored "-Wundeclared-selector"
        // 获取 ASIdentifierManager 的单例对象
        id manager = [cls performSelector:@selector(sharedManager)];
        SEL selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL (*isAdvertisingTrackingEnabled)(id, SEL) = (BOOL (*) (id, SEL))[manager methodForSelector:selector];
        if (isAdvertisingTrackingEnabled) {
            // 使用 IDFA 作为设备 ID
            _anonymousId = [(NSUUID *)[manager performSelector:@selector(advertisingIdentifier)] UUIDString];
        }
#pragma clang diagnostic pop
    }
    
    if (!_anonymousId) {
        // 使用 IDFV 作为设备 ID
        _anonymousId = UIDevice.currentDevice.identifierForVendor.UUIDString;
    }
    
    if (!_anonymousId) {
        // 使用 UUID 作为设备 ID
        _anonymousId = NSUUID.UUID.UUIDString;
    }
    
    // 保存设备 ID
    [self saveAnonymousId:_anonymousId];
    return _anonymousId;
}

- (void)saveAnonymousId:(NSString *)anonymousId {
    // 保存设备ID
    [[NSUserDefaults standardUserDefaults] setObject:anonymousId forKey:SensorsAnalyticsAnonymousId];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    SensorsAnalyticsKeychainItem *item = [[SensorsAnalyticsKeychainItem alloc] initWithService:SensorsAnalyticsKeychainService key:SensorsAnalyticsAnonymousId];
    if (anonymousId) {
        [item update:anonymousId];
    } else {
        [item remove];
    }
}



#pragma mark - properties

+ (double)currentTime {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

- (NSDictionary<NSString *, id> *)collectAutomaticProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 操作系统类型
    properties[@"$os"] = @"iOS";
    
    // SDK 平台类型
    properties[@"$lib"] = @"iOS";
    
    // 设备制造商
    properties[@"$manufacturer"] = @"Apple";
    
    // SDk 版本号
    properties[@"$lib_version"] = SensorsAnalyticsVersion;
    
    // 操作系统版本号
    properties[@"$os_version"] = UIDevice.currentDevice.systemVersion;
    
    // 手机型号
    properties[@"$model"] = [self deviceModel];
    
    // 应用程序版本号
    properties[@"$app_version"] = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    
    return  [properties copy];
}

// 获取手机型号
- (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    
    NSString *results = @(answer);
    
    return results;
}

- (void)printEvent: (NSDictionary *)event {
#if DEBUG
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        return NSLog(@"JSON Serialized Error: %@", error);
    }
    
    NSString *json = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog(@"[Evemt]: %@", json);
#endif
}


#pragma mark - Application lifecycle
- (void)setupListeners {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    // 监听 UIApplicationDidEnterBackgroundNotification
    // 应用程序进入后台，调用通知方法
    [center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // 监听 UIApplicationDidEnterBackgroundNotification
    [center addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // 监听 UIApplicationWillResignActiveNotification
    [center addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    // 监听 UIApplicationDidFinishLaunchingNotification
    [center addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    
}

- (void)applicationDidEnterBackground: (NSNotification *)notification {
    NSLog(@"Application did enter background.");
    
    // 还原标记位
    /*
     单击 Home 键进入后台，在进入前台，会先调用 UIApplicationWillResignActiveNotification， 再调用 UIApplicationDidEnterBackgroundNotification，再调用 UIApplicationDidEnterBackgroundNotification， 因此 要将标记位还原
     */
    self.applicationWillResignActive = NO;
    // 触发 $AppEnd 事件
//    [self track:@"$AppEnd" properties:nil];
    [self trackTimerEnd:@"$AppEnd" propertird:nil];
    
    UIApplication *application = [UIApplication sharedApplication];
    // 初始化标识符
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    // 结束后台任务
    void (^endBackgroundTask)(void) = ^(){
        [application endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    };
    // 标记长时间运行的后台任务
    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        endBackgroundTask();
    }];
    
    dispatch_async(self.serialQueue, ^{
       // 发送数据
        [self flushByEventCount:SensorsAnalyticsDefaultFlushEventCount background:YES];
        // 结束后台任务
        endBackgroundTask();
    });
    
    
    ///
    // 暂停所有事件时长统计
    [self.trackTimer enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
            if (![obj[SensorsAnalyticsEventIsPauseKey] boolValue]) {
                [self.enterBackgroundTrackTimerEvents addObject:key];
                [self trackTimerPause:key];
            }
    }];
    
    // 停止计时器 策略二
    [self stopFlushTimer];
}

- (void)applicationDidBecomeActive: (NSNotification *)notification {
    NSLog(@"Application did become active.");
    
    // 还原标记
    /*
     通知栏下拉并上滑、上滑控制中心并下拉、双击 Home 键至切换应用程序页面又选择当前应用， 都会先触发 UIApplicationWillResignActiveNotification 再触发 UIApplicationDidBecomeActiveNotification ，因此要做标记并过滤掉
     */
    if (self.applicationWillResignActive) {
        self.applicationWillResignActive = NO;
        return;
    }
    // 将被动启动标记为 NO，正常记录事件
    self.launchedPassively = NO;
    
    // 触发 $AppEnd 事件
    [self track:@"$AppStart" properties:nil];
    
    // 恢复所有事件时长统计
    for (NSString *event in self.enterBackgroundTrackTimerEvents) {
        [self trackTimerResume:event];
    }
    [self.enterBackgroundTrackTimerEvents removeAllObjects];
    
    // 开始 $AppEnd 事件计时
    [self trackTimerStart:@"$AppEnd"];
    
    // 开启上传计时器 策略二
    [self startFlushTimer];
}

- (void)applicationWillResignActive: (NSNotification *)notification {
    NSLog(@"Application will resign active.");
    
    // 标记已收到 UIApplicationDidEnterBackgroundNotification 通知
    self.applicationWillResignActive = YES;
}

- (void)applicationDidFinishLaunching: (NSNotification *)notification {
    NSLog(@"Application did finish launching.");
    

    // 触发 $AppStartPassicely 被动启动事件
    /*
     Backround Modes 会触发 被动启动事件
     Backround Modes 会拉起应用程序，并同时让其进入后台运行时，应用程序第一个页面也会被加载 问题
     
     冷启动也会触发该事件，因此不合理，需要处理
     */
    // 当应用程序在后台运行时， 触发被动启动事件
    if (self.isLaunchedPassively) {
        [self track:@"$AppStartPassicely" properties:nil];
    }
    
}


#pragma mark - FlushTimer
/// 开启上传数据的计时器
- (void)startFlushTimer {
    if (self.flushTimer) {
        return;
    }
    NSTimeInterval interval = self.flushInterval < 5 ? 5 : self.flushInterval;
    self.flushTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(flush) userInfo:nil repeats:YES];
    
    [NSRunLoop.currentRunLoop addTimer:self.flushTimer forMode:NSRunLoopCommonModes];
}

/// 停止上传数据的计时器
- (void)stopFlushTimer {
    [self.flushTimer invalidate];
    self.flushTimer = nil;
}

/// 修改 flushInterval 值时，需要先将本地已缓存的所有事件数据上传，然后重置计时器（先暂停，再开启）
-(void)setFlushInterval:(NSUInteger)flushInterval {
    if (_flushInterval != flushInterval) {
        _flushInterval = flushInterval;
        
        // 上传本地缓存的所有事件数据
        [self flush];
        // 先暂停计时器
        [self stopFlushTimer];
        // 重新开启计时器
        [self startFlushTimer];
    }
}

@end


#pragma mark - SensorsAnalyticsSDK (Track)

@implementation SensorsAnalyticsSDK (Track)

- (void)track:(NSString *)eventName properties:(NSDictionary<NSString *,id> *)properties {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    
    // 设置事件的 distinct_id 字段，用于唯一标识一个用户
    event[@"distinct_id"] = self.loginId ?: self.anonymousId;
    
    // 设置事件名称
    event[@"event"] = eventName;
    
    // 时间戳 精确到毫秒
    event[@"time"] = [NSNumber numberWithLong:NSDate.date.timeIntervalSince1970 * 1000];
    
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    // 添加预置属性
    [eventProperties addEntriesFromDictionary:self.automaticProperties];
    
    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    
    // 判断是否是为被动启动状态
    if (self.isLaunchedPassively) {
        // 添加应用程序状态属性
        eventProperties[@"$app_state"] = @"background";
    }
    
    // 设置事件属性
    event[@"properties"] = eventProperties;
    
    // 输出日志
    
    [self printEvent:event];
    [self.fileStore saveEvent:event];
    dispatch_async(self.serialQueue, ^{
        [self.database insertEvent:event];
    });
    
    // 实现策略一
    if (self.database.eventCount >= self.flushBulkSize) {
        [self flush];
    }
}

- (void)trackAppClickWithView:(UIView *)view properties:(NSDictionary<NSString *,id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    // 获取控件类型
    eventProperties[@"$element_type"] = view.sensordata_elementType;
    // 获取控件显示文本
    eventProperties[@"$element_content"] = view.sensordata_elementContent;
    // 获取控件所在的 UIViewController
    UIViewController *vc = view.sensordata_viewController;
    eventProperties[@"$screen_name"] = NSStringFromClass([vc class]);
    
    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:eventProperties];
}


- (void)trackAppClickWithTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath properties:(NSDictionary<NSString *,id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    eventProperties[@"$element_type"] = tableView.sensordata_elementType;

    // 获取用户点击的 UITableViewCell 控件对象
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    // 设置被用户点击 UITableViewCell 控件上的内容 ($element_content)
    eventProperties[@"$element_content"] = cell.sensordata_elementContent;
    // 设置被用户点击 UITableViewCell 控件所在位置 ($element_position)
    eventProperties[@"$element_position"] = [NSString stringWithFormat:@"%ld:%ld", (long)indexPath.section, (long)indexPath.row];

    // 获取控件所在的 UIViewController
    UIViewController *vc = tableView.sensordata_viewController;
    eventProperties[@"$screen_name"] = NSStringFromClass([vc class]);
    
    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:eventProperties];
}

- (void)trackAppClickWithCollectionView: (UICollectionView *)collectView didSelectItemAtIndexPath: (NSIndexPath *)indexPath properties: (nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    eventProperties[@"$element_type"] = collectView.sensordata_elementType;

    // 获取用户点击的 UITableViewCell 控件对象
    UICollectionViewCell *cell = [collectView cellForItemAtIndexPath:indexPath];
    // 设置被用户点击 UITableViewCell 控件上的内容 ($element_content)
    eventProperties[@"$element_content"] = cell.sensordata_elementContent;
    // 设置被用户点击 UITableViewCell 控件所在位置 ($element_position)
    eventProperties[@"$element_position"] = [NSString stringWithFormat:@"%ld:%ld", (long)indexPath.section, (long)indexPath.row];

    // 获取控件所在的 UIViewController
    UIViewController *vc = collectView.sensordata_viewController;
    eventProperties[@"$screen_name"] = NSStringFromClass([vc class]);
    
    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"$AppClick" properties:eventProperties];
}

@end


@implementation SensorsAnalyticsSDK (Timer)

- (void)trackTimerStart:(NSString *)event {
    // 记录事件开始时间
    self.trackTimer[event] = @{SensorsAnalyticsEventBeginKey: @([SensorsAnalyticsSDK currentTime]), SensorsAnalyticsEventDurationKey: @(0)};
}

-(void)trackTimerEnd:(NSString *)event propertird:(NSDictionary *)properties {
    NSDictionary *eventTimer = self.trackTimer[event];
    
    if (!eventTimer) {
        return [self track:event properties:properties];
    }
    
    NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:properties];
    // 移除
    [self.trackTimer removeObjectForKey:event];
    
    if ([eventTimer[SensorsAnalyticsEventIsPauseKey] boolValue]) {
        // 获取事件时长
        double eventDuration = [eventTimer[SensorsAnalyticsEventDurationKey] doubleValue];
        // 设置事件时长属性
        [p setObject:@([[NSString stringWithFormat:@"%.3lf", eventDuration] floatValue ]) forKey:@"$event_duration"];

    } else {
        // 事件开始时间
        double beginTime = [(NSNumber *)eventTimer[SensorsAnalyticsEventBeginKey] doubleValue];
        // 获取当前时间
        double currentTime = [SensorsAnalyticsSDK currentTime];
        // 计算时长
        double eventDuration = currentTime - beginTime + [eventTimer[SensorsAnalyticsEventDurationKey] doubleValue];
        // 设置时长属性
        [p setObject:@([[NSString stringWithFormat:@"%.3lf", eventDuration] floatValue ]) forKey:@"$event_duration"];
    }

    
    // 触发事件
    [self track:event properties:p];
    
}

- (void)trackTimerPause:(NSString *)event {
    NSMutableDictionary *eventTimer = [self.trackTimer[event] mutableCopy];
    // 如果没有开始直接返回
    if (!eventTimer) {
        return;
    }
    
    // 如果该事件时长统计已被暂停，直接返回，不作任何操作
    if ([eventTimer[SensorsAnalyticsEventIsPauseKey] boolValue]) {
        return;
    }
    
    // 获取当前系统时间
    double systemUpTime = [SensorsAnalyticsSDK currentTime];
    // 获取开始时间
    double beginTime = [eventTimer[SensorsAnalyticsEventBeginKey] doubleValue];
    // 计算暂停前统计的时长
    double duration = [eventTimer[SensorsAnalyticsEventDurationKey] doubleValue] + systemUpTime - beginTime;
    eventTimer[SensorsAnalyticsEventDurationKey] = @(duration);
    
    // 事件处于暂停状态
    eventTimer[SensorsAnalyticsEventIsPauseKey] = @(YES);
    self.trackTimer[event] = eventTimer;
}

- (void)trackTimerResume:(NSString *)event {
    NSMutableDictionary *eventTimer = [self.trackTimer[event] mutableCopy];
    // 如果没有开始直接返回
    if (!eventTimer) {
        return;
    }
    
    // 如果该事件时长统计没有暂停直接返回
    if (![eventTimer[SensorsAnalyticsEventIsPauseKey] boolValue]) {
        return;
    }
    
    // 获取当前系统时间
    double systemUpTime = [SensorsAnalyticsSDK currentTime];
    // 重置事件开始时间
    eventTimer[SensorsAnalyticsEventBeginKey] = @(systemUpTime);
    
    // 将时间暂停标记设置为 NO
    eventTimer[SensorsAnalyticsEventIsPauseKey] = @(NO);
    
    self.trackTimer[event] = eventTimer;
}

@end

static NSString * const SensorsAnalyticsJavaScriptTrackEventScheme = @"sensorsanalytics://trackEvent";

#pragma mark - SensorsAnalyticsSDK (WebView)

@implementation SensorsAnalyticsSDK (WebView)

- (void)loadUserAgent:(void(^)(NSString *))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 创建一个空的WebView，由于 WebView 执行 JS 代码是一个异步的过程，所以需要强引用 WKWebView 对象
        self.wevView = [[WKWebView alloc] initWithFrame:CGRectZero];
        
        // 创建一个弱引用，防止循环引用
        __weak typeof(self) weakSelf = self;
        // 执行 JS 代码 获取 WKWebView 中的 UserAgent
        [self.wevView  evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            // 创建强引用
            __strong typeof(weakSelf) strongSelf = weakSelf;
            // 调用回调，返回获取到的 UserAgent
            completion(result);
            // 释放 WKWebviewView
            strongSelf.wevView = nil;
        }];
        
    });
}

- (void)addWebViewUserAgent:(NSString *)userAgent {
    [self loadUserAgent:^(NSString *oldUserAgent) {
       // 给 UserAgent 添加自己需要的内容
        NSString *newUserAgent = [oldUserAgent stringByAppendingString: userAgent];
        // 将 UserAgent 字典内容注册到 NSUserDefaults 中
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": newUserAgent}];
    }];
}

- (BOOL)shouldTrackWithWebView:(id)webView request:(NSURLRequest *)reequest {
    // 获取请求的完整路径
    NSString *urlString = [reequest URL].absoluteString;
    // 查找在完整路径中是否包含 sensorsanalytics://trackEvent 如果不包含则是普通请求，不处理，返回 NO
    if ([urlString rangeOfString:SensorsAnalyticsJavaScriptTrackEventScheme].location == NSNotFound) {
        return NO;
    }
    
    NSMutableDictionary *queryItems = [NSMutableDictionary dictionary];
    // 请求中的所有 Query,并解析获取数据
    NSArray<NSString *> *allQuery = [reequest.URL.query componentsSeparatedByString:@"&"];
    for (NSString *query in allQuery) {
        NSArray<NSString *> *items = [query componentsSeparatedByString:@"="];
        if (items.count >= 2) {
            queryItems[items.firstObject] = [items.lastObject stringByRemovingPercentEncoding];
        }
    }
    
    // 采集请求中的数据
    [self trackFromH5WithEvent:queryItems[@"event"]];
    return YES;
}

/// 用于对 H5 事件进行二次加工并保存到本地
/// @param jsonString  JSON字符串
- (void)trackFromH5WithEvent: (NSString *)jsonString {
    NSError *error = nil;
    // 将 JSON 字符串转换成 NSData 类型
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 解析 JSON
    NSMutableDictionary *event = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (error || !event) {
        return;
    }
    
    NSMutableDictionary *properties = [event[@"properties"] mutableCopy];
    // 预置属性以 SDK 中采集的属性为主
    [properties addEntriesFromDictionary:self.automaticProperties];
    event[@"properties"] = properties;
    
    // 用于区分事件来源字段，表示是 H5 采集到的数据
    event[@"_hybrid_h5"] = @(YES);
    
    // 设置事件的 distinct_id 用于唯一标识一个用户
    event[@"distinct_id"] = self.loginId ?: self.anonymousId;
    
    // 答应最终的入库数据
    [self printEvent:event];
    
    // 本地保存事件数据
//    [self.fileStore saveEvent:event];
    [self.database insertEvent:event];
//    if (self.fileStore.allEvents.count >= self.flushBulkSize) {
//        [self flush];
//    }
    
    if (self.database.eventCount >= self.flushBulkSize) {
        [self flush];
    }
}

@end
