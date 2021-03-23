//
//  NSObject+SASwizzler.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SASwizzler)

/// 交换两个方法的实现
/// @param originalSEL 原方法名
/// @param alternateSEL 要替换的方法名
+ (BOOL)sensorsData_swizzleMethod: (SEL)originalSEL withMethod: (SEL)alternateSEL;

@end

NS_ASSUME_NONNULL_END
