//
//  UIView+SensorData.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/21.
//

#import "UIView+SensorData.h"

@implementation UIView (SensorData)

- (NSString *)sensordata_elementType {
    return NSStringFromClass([self class]);
}

- (NSString *)sensordata_elementContent {
    // 如果是隐藏控件，不获取控件内容
    if (self.isHidden || self.alpha == 0) {
        return nil;
    }
    // 初始化数组，用于保存子控件内容
    NSMutableArray *contentArrM = [NSMutableArray array];
    for (UIView *view in self.subviews) {
        // 获取子控件的内容
        // 如果子控件有内容，例如 UILabel ，获取到 就是 text 属性
        // 如果子控件没有内容，就递归该方法，获取其子控件的内容
        NSString *content = view.sensordata_elementContent;
        if (content.length > 0) {
            // 该子控件由内容，保存在数组中
            [contentArrM addObject:content];
        }
    }
    // 未获取到 子控件内容时，返回 nil。如果获得多个子控件内容时，使用 ’-‘ 拼接
    return contentArrM.count == 0 ? nil : [contentArrM componentsJoinedByString:@"-"];
}

- (UIViewController *)sensordata_viewController {
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    // 如果没有找到， 返回 nil
    return nil;
    
}


@end

@implementation UILabel (SensorData)

- (NSString *)sensordata_elementContent {
    return self.text ?: super.sensordata_elementContent;
}

@end

@implementation UIButton (SensorData)

- (NSString *)sensordata_elementContent {
    return self.currentTitle ?: super.sensordata_elementContent;
}

@end


@implementation UISwitch (SensorData)

- (NSString *)sensordata_elementContent {

    return self.isOn ? @"checked" : @"unchecked";
}

@end


@implementation UISlider (SensorData)

- (NSString *)sensordata_elementContent {

    return [NSString stringWithFormat:@"%.2f", self.value];
}


@end


@implementation UISegmentedControl (SensorData)

- (NSString *)sensordata_elementContent {

    return [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

@end


@implementation UIStepper (SensorData)

- (NSString *)sensordata_elementContent {

    return [NSString stringWithFormat:@"%g", self.value];
}

@end
