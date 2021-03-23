//
//  UITableView+SensorsData.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/22.
//

#import "UITableView+SensorsData.h"
#import "NSObject+SASwizzler.h"
#import <objc/message.h>

#import "SensorsAnalyticsSDK.h"

#import "SensorsAnalyticsDynamicDelegate.h"

#import "SensorsAnalyticsDelegateProxy.h"
#import "UIScrollView+SensorsData.h"

@implementation UITableView (SensorsData)

+ (void)load {
    [UITableView sensorsData_swizzleMethod:@selector(setDelegate:) withMethod:@selector(sensorsdata_setDelegate:)];
}

- (void)sensorsdata_setDelegate: (id<UITableViewDelegate>)delegate {
    
    // 方案一： 方法交换
//    // 调用原始的设置代理方法
    [self sensorsdata_setDelegate:delegate];
    // 交换 delegate 对象中的 tableView:didSelectRowAtIndexPath: 方法
    [self sensordata_swizzleDidSelectRowAtIndexPathMethodWIthDelegate:delegate];
    
    // 方案二： 动态子类
//    // 调用原始的设置代理方法
//    [self sensorsdata_setDelegate:delegate];
//    //      设置 delegate 对象的动态子类
//    [SensorsAnalyticsDynamicDelegate proxyWithTableViewDelegate:delegate];
    
    // 方案三： NSProxy 消息转发
    self.sensorsdata_delegateProxy = nil;
    if (delegate) {
        SensorsAnalyticsDelegateProxy *proxy = [SensorsAnalyticsDelegateProxy proxyWithTableViewDelegate:delegate];
        // 保存委托对象
        self.sensorsdata_delegateProxy = proxy;
        // 调用原始方法，将代理设置为委托对象
        [self sensorsdata_setDelegate:proxy];
    } else {
        // 调用原始方法，将代理设置为 nil
        [self sensorsdata_setDelegate:nil];
    }

}


static void sensorsdata_tableViewDidSelectRow(id object, SEL selector, UITableView *tableView, NSIndexPath *indexPath) {
    
    SEL destinationSelector = NSSelectorFromString(@"sensorsdata_tableView:didSelectRowActIndexPath:");
    // 通过消息发送，调用原始的 tableView:didSelectRowAtIndexPath: 方法实现
    ((void(*)(id, SEL, id, id))objc_msgSend)(object, destinationSelector, tableView, indexPath);
    
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

// 负责给 delegate 对象添加一个方法并进行交换
- (void)sensordata_swizzleDidSelectRowAtIndexPathMethodWIthDelegate: (id)delegate {
    // 获取delegate 对象的类
    Class delegateClass = [delegate class];
    
    // 方法名
    SEL sourceSelector = @selector(tableView:didSelectRowAtIndexPath:);
    // 当 delegate 对象中没有实现 tableView:didSelectRowAtIndexPath: 方法时，直接返回
    if (![delegate respondsToSelector:sourceSelector]) {
        return;
    }
    
    SEL destinationSelector = NSSelectorFromString(@"sensorsdata_tableView:didSelectRowActIndexPath:");

    // 当 delegate 对象中已存在了 sensorsdata_tableView:didSelectRowActIndexPath: 方法，说明已经进行交换，因此直接返回
    if ([delegate respondsToSelector: destinationSelector]) {
        return;
    }
    
    Method sourceMethod = class_getClassMethod(delegateClass, sourceSelector);
    const char * typeEncoding = method_getTypeEncoding(sourceMethod);
    IMP destinationIMP = (IMP)sensorsdata_tableViewDidSelectRow;
    // 当该类中已经存在相同的方法，则添加方法失败。但是前面已经判断过是否存在，因此一定会添加成功
    if (!class_addMethod(delegateClass, destinationSelector, destinationIMP, typeEncoding)) {
        NSLog(@"Add %@ to %@ error", NSStringFromSelector(sourceSelector), delegateClass);
        return;
    }
    
    // 方法添加成功之后，进行方法交换
    [delegateClass sensorsData_swizzleMethod:sourceSelector withMethod:destinationSelector];
}



@end
