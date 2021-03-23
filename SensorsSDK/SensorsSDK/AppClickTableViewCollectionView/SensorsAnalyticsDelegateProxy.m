//
//  SensorsAnalyticsDelegateProxy.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/23.
//

#import "SensorsAnalyticsDelegateProxy.h"

#import "SensorsAnalyticsSDK.h"

@interface SensorsAnalyticsDelegateProxy ()
// 保存 delegate 对象
@property (nonatomic, weak) id delegate;

@end

@implementation SensorsAnalyticsDelegateProxy

+ (instancetype)proxyWithTableViewDelegate: (id<UITableViewDelegate>)delegate {
    SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy alloc];
    proxy.delegate = delegate;
    return proxy;
}

+ (instancetype)proxyWithCollectionViewDelegate: (id<UICollectionViewDelegate>)delegate {
    SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy alloc];
    proxy.delegate = delegate;
    return proxy;
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    // 返回 delegate 对象中对应的方法签名
    return [(NSObject *)self.delegate methodSignatureForSelector:sel];
}


- (void)forwardInvocation:(NSInvocation *)invocation {
    // 先执行 delegate 对象中的方法
    [invocation invokeWithTarget:self.delegate];
    
    // 判断是否是 cell 的点击事件代理方法
    if (invocation.selector == @selector(tableView:didSelectRowAtIndexPath:)) {
        // 将该方法修改为进行数据采集的方法，基本类中的实例方法，sensorsdata_tableView:didSelectRowAtIndexPath:
        invocation.selector = NSSelectorFromString(@"sensorsdata_tableView:didSelectRowAtIndexPath:");
        // 执行数据采集相关的方法
        [invocation invokeWithTarget:self];
    } else if (invocation.selector == @selector(collectionView:didSelectItemAtIndexPath:)) {
        // 将该方法修改为进行数据采集的方法，基本类中的实例方法，sensorsdata_collectionView:didSelectItemAtIndexPath:
        invocation.selector = NSSelectorFromString(@"sensorsdata_collectionView:didSelectItemAtIndexPath:");
        // 执行数据采集相关的方法
        [invocation invokeWithTarget:self];
    }
}

- (void)sensorsdata_tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

- (void)sensorsdata_collectionView: (UICollectionView *)collectionView didSelectItemAtIndexPath: (NSIndexPath *)indexPath {
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithCollectionView:collectionView didSelectItemAtIndexPath:indexPath properties:nil];
}

@end
