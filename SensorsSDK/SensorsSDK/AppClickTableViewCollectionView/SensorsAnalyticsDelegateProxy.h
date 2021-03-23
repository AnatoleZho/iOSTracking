//
//  SensorsAnalyticsDelegateProxy.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorsAnalyticsDelegateProxy : NSProxy<UITableViewDelegate>

+ (instancetype)proxyWithTableViewDelegate: (id<UITableViewDelegate>)delegate;

+ (instancetype)proxyWithCollectionViewDelegate: (id<UICollectionViewDelegate>)delegate;


@end

NS_ASSUME_NONNULL_END
