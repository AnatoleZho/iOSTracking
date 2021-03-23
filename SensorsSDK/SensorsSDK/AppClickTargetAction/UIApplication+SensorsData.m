//
//  UIApplication+SensorsData.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/21.
//

#import "UIApplication+SensorsData.h"
#import "SensorsAnalyticsSDK.h"
#import "NSObject+SASwizzler.h"
#import "UIView+SensorData.h"

@implementation UIApplication (SensorsData)
//
//+ (void)load {
//    [UIApplication sensorsData_swizzleMethod:@selector(sendAction:to:from:forEvent:) withMethod:@selector(sensordata_sendAction:to:from:forEvent:)];
//}

- (BOOL)sensordata_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    
    UIView *view = (UIView *)sender;
    
    // 触发 $AppClick 事件
    // UISwitch 只会触发 UITouchPhaseBegan
    if ([view isKindOfClass:[UISwitch class]] || [view isKindOfClass:[UISegmentedControl class]] || [view isKindOfClass:[UIStepper class]] || event.allTouches.anyObject.phase == UITouchPhaseEnded) {
        [[SensorsAnalyticsSDK sharedInstance] trackAppClickWithView:view properties:nil];
    }

    // 调用原有实现 -sendAction: to: from: forEvent:];
    return [self sensordata_sendAction:action to:target from:sender forEvent:event];
}

@end
