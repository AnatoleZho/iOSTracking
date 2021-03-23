//
//  TargetProxy.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TargetProxy : NSProxy

- (instancetype)initWithObject1: (id)object1 object2: (id)object2;

@end

NS_ASSUME_NONNULL_END
