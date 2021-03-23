//
//  UIGestureRecognizer+SensorsData.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/23.
//

#import "UIGestureRecognizer+SensorsData.h"
#import "NSObject+SASwizzler.h"
#import "SensorsAnalyticsSDK.h"


@implementation UIGestureRecognizer (SensorsData)

+ (void)load {
    [UIGestureRecognizer sensorsData_swizzleMethod:@selector(initWithTarget:action:) withMethod:@selector(sensorsdata_initWithTarget:action:)];
    
    [UIGestureRecognizer sensorsData_swizzleMethod:@selector(addTarget:action:) withMethod:@selector(sendorsdata_addTarget:action:)];
}

- (instancetype)sensorsdata_initWithTarget:(id)target action:(SEL)action {
    // 调用原始的初始化方法进行对象初始化
    [self sensorsdata_initWithTarget:target action:action];
    
    // 调用添加 Target-Action 的方法，添加埋点的 Target-Action
    // 这里 其实调用的是 -sensorsdata_addTarget:action: 的实现方法，因为已经进行了交换
    [self addTarget:target action:action];
    return self;
}

- (void)sendorsdata_addTarget: (id)target action: (SEL)action {
    // 调用原始的方法，添加 Target-Action
    [self sendorsdata_addTarget:target action:action];
    // 新增 Target - Action，用于触发 $AppClick 事件
    [self sendorsdata_addTarget:self action:@selector(sendorsdata_trackTapGestureAction:)];
}

- (void)sendorsdata_trackTapGestureAction: (UITapGestureRecognizer *)sender {
    
    // 手势处于 UIGestureRecognizerStateEnded 状态时，才触发 $AppClcik 事件
    if (sender.state != UIGestureRecognizerStateEnded) {
        return;
    }
    // 获取手势识别器控件
    UIView *view = sender.view;
    // 暂定只采集 UILabel 和 UIImageView
    // 若要增加其他控件可进行扩展
    BOOL isTrackClass = [view isKindOfClass:[UILabel class]] || [view isKindOfClass:[UIImageView class]];
    if (!isTrackClass) {
        return;
    }
    // 触发 $AppClcik 事件
    [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:view properties:nil];
}

@end
