//
//  NSObject+SASwizzler.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/20.
//

#import "NSObject+SASwizzler.h"

#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (SASwizzler)

+ (BOOL)sensorsData_swizzleMethod:(SEL)originalSEL withMethod:(SEL)alternateSEL {
    // 获取原始方法
    Method originalMethod = class_getInstanceMethod(self, originalSEL);
    if (!originalMethod) {
        return NO;
    }
    
    // 获取要交换的方法
    Method alternateMethod = class_getInstanceMethod(self, alternateSEL);
    if (!alternateMethod) {
        return NO;
    }
    
    // 获取 originalSEL 方法的实现
    IMP originalIMP = method_getImplementation(originalMethod);
    // 获取 originalSEL 方法的类型
    const char * originalMethodType = method_getTypeEncoding(originalMethod);
    
    // 往类中添加 originalSEL 方法，如果已经存在，则添加失败，并返回 NO
    if (class_addMethod(self, originalSEL, originalIMP, originalMethodType)) {
        // 如果添加成功，重新获取 originalSEL 实例方法
        originalMethod = class_getInstanceMethod(self, originalSEL);
    }
    
    // 获取 alternateSEL 方法的实现
    IMP alternateIMP = method_getImplementation(alternateMethod);
    // 获取 alternateSEL 方法的类型
    const char * alternateMethodType = method_getTypeEncoding(alternateMethod);
    
    // 往类中添加 alternateSEL 方法，如果已经存在，则添加失败，并返回 NO
    if (class_addMethod(self, alternateSEL, alternateIMP, alternateMethodType)) {
        // 如果添加成功，从新获取 alternateSEL 实例方法
        alternateMethod = class_getInstanceMethod(self, alternateSEL);
    }
    
    // 交换两个方法
    method_exchangeImplementations(originalMethod, alternateMethod);
    return YES;
}

@end
