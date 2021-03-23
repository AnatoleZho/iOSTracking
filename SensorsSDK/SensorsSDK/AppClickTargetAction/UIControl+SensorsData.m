//
//  UIControl+SensorsData.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/21.
//

#import "UIControl+SensorsData.h"

#import "NSObject+SASwizzler.h"

#import "SensorsAnalyticsSDK.h"

@implementation UIControl (SensorsData)

+ (void)load {
    [UIControl sensorsData_swizzleMethod:@selector(didMoveToSuperview) withMethod:@selector(sensorsdata_didMoveToSuperview)];
}

- (void)sensorsdata_didMoveToSuperview {
    // 调用交换前的原始方法实现
    [self sensorsdata_didMoveToSuperview];
    
    if ([self isKindOfClass:UISwitch.class] || [self isKindOfClass:UISegmentedControl.class] || [self isKindOfClass:UIStepper.class] || [self isKindOfClass:UISlider.class]) {
        // 添加类型为 UIControlEventTouchDown 的 一组 Target-Action
        [self addTarget:self action:@selector(sensorsdata_valueChangeAction:event:) forControlEvents:UIControlEventValueChanged];

    } else {
        // 添加类型为 UIControlEventTouchDown 的 一组 Target-Action
        [self addTarget:self action:@selector(sensorsdata_touchDownAction:event:) forControlEvents:UIControlEventTouchDown];
    }
}

- (void)sensorsdata_touchDownAction: (UIControl *)sender event: (UIEvent *)event {
    if ([self sensorsdata_isAddMultipleTargetActionsWithDefaultControlEvent: UIControlEventTouchDown]) {
        // 触发 $AppClick 事件
        [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:sender properties:nil];
    }
}

- (void)sensorsdata_valueChangeAction: (UIControl *)sender event: (UIEvent *)event {
    
    // 保证 UISlider 只有手抬起时才触发 触发 $AppClick 事件
    if ([self isKindOfClass:UISlider.class] && event.allTouches.anyObject.phase != UITouchPhaseEnded ) {
        return;
    }
    
    if ([self sensorsdata_isAddMultipleTargetActionsWithDefaultControlEvent: UIControlEventValueChanged]) {
        // 触发 $AppClick 事件
        [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:sender properties:nil];
    }
}


- (BOOL)sensorsdata_isAddMultipleTargetActionsWithDefaultControlEvent: (UIControlEvents)defaultControlEvent {
    // 如果有多个 Target, 说明除了添加的 Target，还有其他
    if (self.allTargets.count >= 1) {
        return YES;
    }
    
    // 如果控件本身为 Target，并且添加了不是 UIControlEventTouchDown 类型的 Action
    // 说明开发者以控件本身为 Target，并且已添加 Action
    // 那么返回 YES, 触发 $AppClick 事件
    if ((self.allControlEvents & UIControlEventAllTouchEvents) != defaultControlEvent) {
        return YES;
    }
    
    // 如果控件本身为 Target，并且添加了两个以上的 UIControlEventTouchDown 类型的 Action
    // 说明开发者自行添加了 Action
    // 那么返回 YES, 触发 $AppClick 事件
    if ([self actionsForTarget:self forControlEvent:defaultControlEvent].count >= 2) {
        return YES;
    }
    
    return NO;
}

@end
