//
//  SensorsAnalyticsSDK.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/18.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsSDK : NSObject

// 设备ID (匿名ID)
@property (nonatomic, copy) NSString *anonymousId;

// 登录 ID
@property (nonatomic, copy) NSString *loginId;

/// 当本地缓存的事件达到最大条数时，上传数据（默认 100 条） 策略一
@property (nonatomic, assign) NSUInteger flushBulkSize;

/// 两次本地缓存的事件事件发送间隔，上传数据（默认 15s） 策略二
@property (nonatomic, assign) NSUInteger flushInterval;

/// 获取 SDK实例
+ (SensorsAnalyticsSDK *)sharedInstance;

- (void)login: (NSString *)loginId;

/// 向服务器同步本地数据
- (void)flush;


/// 禁用 init
- (instancetype)init NS_UNAVAILABLE;


/// 初始化SDK
/// @param serverURLStr 接受数据的服务器 URL
+ (void)startWithServerURL: (NSString *)serverURLStr;

@end


#pragma mark - SensorsAnalyticsSDK (Track)
@interface SensorsAnalyticsSDK (Track)

/// 调用 Track 接口，触发事件
/// @param eventName 事件名称
/// @param properties 时间属性
- (void)track: (NSString *)eventName properties: (nullable NSDictionary<NSString *, id> *)properties;

/// 支持 UIView，触发 $AppClick 事件
/// @param view 触发事件的View
/// @param properties 事件属性
- (void)trackAppClickWithView: (UIView *)view properties: (nullable NSDictionary<NSString *, id> *)properties;


/// 支持 UITableView，触发 $AppClick 事件
/// @param tableView 触发事件的 视图
/// @param indexPath 点击的位置
/// @param properties 事件属性
- (void)trackAppClickWithTableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath properties: (nullable NSDictionary<NSString *, id> *)properties;

/// 支持 UICollectionView，触发 $AppClick 事件
/// @param collectView 触发事件的 视图
/// @param indexPath 点击的位置
/// @param properties 事件属性
- (void)trackAppClickWithCollectionView: (UICollectionView *)collectView didSelectItemAtIndexPath: (NSIndexPath *)indexPath properties: (nullable NSDictionary<NSString *, id> *)properties;

@end

#pragma mark - SensorsAnalyticsSDK (Timer)

@interface SensorsAnalyticsSDK (Timer)

/// 开始统计事件时长
/// 调用这个接口时，并不是真的触发一次事件，只是开始计时
/// @param event 事件名
- (void)trackTimerStart:(NSString *)event;


/// 结束事件时长统计，计算时长
/// 事件发生时长 是 从调用 start 开始，一直到 end 方法结束
/// 如果多次调用 start ，则从最后一次计算
/// 如果没有调用 start ，就直接调用 end 则触发一次普通事件，不带时长属性
/// @param event 事件名
/// @param properties 事件属性
- (void)trackTimerEnd:(NSString *)event propertird: (nullable NSDictionary *)properties;


/// 暂停统计时长
/// 如果该事件未开始，即没有调用 start 则不做任何操作
/// @param event 事件名
- (void)trackTimerPause: (NSString *)event;


/// 恢复统计事件时长
/// 如果该事件并未暂停，既没有调用 pause，则没有影响
/// @param event 事件名
- (void)trackTimerResume: (NSString *)event;

@end

#pragma mark - SensorsAnalyticsSDK (WebView)

@interface SensorsAnalyticsSDK (WebView)

/// 在 WebView  控件中添加自定义的 UserAgent，用于实现打通方案
/// @param userAgent 自定义  usrAgent
- (void)addWebViewUserAgent:(nullable NSString *)userAgent;

/// 判断是否需要拦截
/// @param webView 用于页面展示的 WebView 控件
/// @param reequest WebView 控件中的请求
- (BOOL)shouldTrackWithWebView: (id)webView request:(NSURLRequest *)reequest;

// 方案二：
- (void)trackFromH5WithEvent: (NSString *)jsonString;

@end


NS_ASSUME_NONNULL_END
