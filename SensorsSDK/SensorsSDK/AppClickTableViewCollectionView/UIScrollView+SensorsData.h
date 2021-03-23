//
//  UIScrollView+SensorsData.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/23.
//

#import <UIKit/UIKit.h>
#import "SensorsAnalyticsDelegateProxy.h"


NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (SensorsData)

@property (nonatomic, strong) SensorsAnalyticsDelegateProxy * sensorsdata_delegateProxy;

@end

NS_ASSUME_NONNULL_END
