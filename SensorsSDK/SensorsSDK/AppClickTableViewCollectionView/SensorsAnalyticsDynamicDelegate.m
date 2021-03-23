//
//  SensorsAnalyticsDynamicDelegate.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/22.
//

#import "SensorsAnalyticsDynamicDelegate.h"

#import "SensorsAnalyticsSDK.h"
#import <objc/runtime.h>


// delegate 对象的子类前缀
static NSString *const kSensorsDelegatePrefix = @"cn.SensorsData.";

// tableView:didSelectRowAtIndexPath: 方法指针类型
typedef void (*SensorsDidSelectImplementation)(id, SEL, UITableView *, NSIndexPath *);


@implementation SensorsAnalyticsDynamicDelegate

+ (void)proxyWithTableViewDelegate:(id<UITableViewDelegate>)delegate {
    SEL originalSelector = NSSelectorFromString(@"tableView:didSelectRowAtIndexPath:");
    
    // 当 delegate 对象中没有实现 tableView:didSelectRowAtIndexPath: 方法时，直接返回
    if (![delegate respondsToSelector:originalSelector]) {
        return;
    }
    
    // 动态创建一个新类
    Class originalClass = object_getClass(delegate);
    NSString *originalClassName = NSStringFromClass(originalClass);
    
    // 当 delegate 对象已经是一个动态生成的类时，无法重复设置，直接返回
    if ([originalClassName hasPrefix:kSensorsDelegatePrefix]) {
        return;
    }
    
    NSString *subClassName = [kSensorsDelegatePrefix stringByAppendingString:originalClassName];
    Class subClass = NSClassFromString(subClassName);
    
    if (!subClass) {
        // 注册一个新的子类，其父类为 originalClass
        subClass = objc_allocateClassPair(originalClass, subClassName.UTF8String, 0);
        
        // 获取 SensorsAnalyticsDynamicDelegate 中 tableView:didSelectRowAtIndexPath: 方法指针
        Method method = class_getInstanceMethod(self, originalSelector);
        // 获取方法实现
        IMP methodImp = method_getImplementation(method);
        // 获取方法的类型编码
        const char * methodTypes = method_getTypeEncoding(method);
        
        // 在子类中添加 tableView:didSelectRowAtIndexPath:  方法
        if (!class_addMethod(subClass, originalSelector, methodImp, methodTypes)) {
            NSLog(@"Cannot copy method to destination selector %@ as it already exists", NSStringFromSelector(originalSelector));
        }
        
        // 获取 SensorsAnalyticsDynamicDelegate 中 sensorsdata_class 方法指针
        SEL classSel = @selector(sensorsdata_class);
        Method classMethod = class_getInstanceMethod(self, classSel);
        // 获取方法实现
        IMP classImp = method_getImplementation(classMethod);
        // 获取方法的类型编码
        const char * classMethodTypes = method_getTypeEncoding(classMethod);
        
        // 在 subclass 中添加 class 方法
        if (class_addMethod(subClass, @selector(class), classImp, classMethodTypes)) {
            NSLog(@"Cannot copy method to destination selector -(void)class as it already exists");
        }

        // 子类和原始类的大小必然相同，不能有更多的成员变量（ivars）或者属性
        if (class_getInstanceSize(originalClass) != class_getInstanceSize(subClass)) {
            NSLog(@"Cannot create subClass of Delegate, because the created subclass is not the same size. %@", NSStringFromClass(originalClass));
            
            NSAssert(NO, @"Classes must be the same size to swizzle isa");
            return;
        }
        
        objc_registerClassPair(subClass);
        
    }
    
    // 将 delegate 对象设置成新创建的子类对象
    if (object_setClass(delegate, subClass)) {
        NSLog(@"Successfully created Delegate Proxy automatically");
    }
}

//
- (Class)sensorsdata_class {
    // 获取对象的 类
    Class class = object_getClass(self);
    // 将类前缀 替换成 空字符串，获取原始类名
    NSString *className = [NSStringFromClass(class) stringByReplacingOccurrencesOfString:kSensorsDelegatePrefix withString:@""];
    // 返回类名
    return objc_getClass([className UTF8String]);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 第一步： 获取原始类
    Class cla = object_getClass(tableView);
    NSString *className = [NSStringFromClass(cla) stringByReplacingOccurrencesOfString:kSensorsDelegatePrefix withString:@""];
    Class originalClass = objc_getClass([className UTF8String]);
    
    // 第二步： 调用开发者自己实现的方法
    SEL originalSelector = NSSelectorFromString(@"tableView:didSelectRowAtIndexPath:");
    Method originalMethod = class_getClassMethod(originalClass, originalSelector);
    IMP originalImplementation = method_getImplementation(originalMethod);
    
    if (originalImplementation) {
        ((SensorsDidSelectImplementation)originalImplementation)(tableView.delegate, originalSelector, tableView, indexPath);
    }
    
    // 第三步：埋点
    // 触发 $AppClick 事件
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithTableView:tableView didSelectRowAtIndexPath:indexPath properties:nil];
}

@end
