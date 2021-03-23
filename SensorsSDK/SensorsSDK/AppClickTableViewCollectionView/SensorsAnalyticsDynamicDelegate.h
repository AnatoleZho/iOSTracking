//
//  SensorsAnalyticsDynamicDelegate.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsDynamicDelegate : NSObject

+ (void)proxyWithTableViewDelegate: (id<UITableViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
