//
//  UIViewController+SensorsData.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/20.
//

#import "UIViewController+SensorsData.h"

#import "SensorsAnalyticsSDK.h"

#import "NSObject+SASwizzler.h"

static NSString * const kSensorsDataBlackListFileName = @"Sensorsdata_black_list";

@implementation UIViewController (SensorsData)

/*
 A class's +load method is called after all of its superclasses' +load methods.
 A category +load is called after the class's own +load method.
 */
+ (void)load {
    // UIViewController 的子类如果重写了 -viewDidAppear:, 则必需调用 [super viewDidAppear: animated]
    // 因为交换的是 UIViewController 的 -viewDidAppear: 方法
    [[self class] sensorsData_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(sensorsdata_viewDidAppear:)];
}

/*
 方法交换
 -viewDidAppear: 方法调用的是 -sensordata_viewDidAppear: 方法的实现
 -sensordata_viewDidAppear: 方法调用的是 -viewDidAppear: 方法的实现

 之所以这么做是 在 原有 -viewDidAppear: 方法的最后添加触发 $AppViewScreen 事件的逻辑, 而不是完全删除 -viewDidAppear： 方法中的实现逻辑
 */
- (void)sensorsdata_viewDidAppear: (BOOL)animated {
    // 调用原始方法， 即 - viewDidAppear:
    [self sensorsdata_viewDidAppear:animated];
    
    // 不在黑名单中的 类 才触发事件
    if ([self shouldTrackAppViewScreen]) {
        // 触发 $AppViewScreen 事件
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        
        [properties setValue:NSStringFromClass([self class]) forKey:@"$screen_name"];
        // self.title 和 self.navigationItem.title 都可以设置 title，self.navigationItem.title 获取的是显示的
        // 还有一种情况是 navigationItem.titleView 的优先级高于 navigationItem.title
        NSString *title = [self contentFromView:self.navigationItem.titleView];
        if (title.length == 0) {
            title = self.navigationItem.title;
        }
        
        [properties setValue:self.navigationItem.title forKey:@"$title"];
        [[SensorsAnalyticsSDK sharedInstance] track:@"$AppViewScreen" properties:properties];
    }

}


/// 判断当前 UIViewController 是否在 黑名单中
- (BOOL)shouldTrackAppViewScreen {
    static NSSet *blackList = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 获取很名单路径
        NSString *path = [[NSBundle bundleForClass:SensorsAnalyticsSDK.class] pathForResource:kSensorsDataBlackListFileName ofType:@"plist"];
        
        // 读取黑名单中的数组
        NSArray *classNames = [NSArray arrayWithContentsOfFile:path];
        
        NSMutableSet *set = [NSMutableSet setWithCapacity:classNames.count];
        for (NSString *className in classNames) {
            [set addObject:NSClassFromString(className)];
        }
        blackList = [set copy];
    });
    
    for (Class cls in blackList) {
        // 判断但前视图控制器是否在黑名单中
        if ([self isKindOfClass:cls]) {
            return NO;
        }
    }
    return YES;
}


/// 获取 UIView 的文本
/// @param rootView  视图
- (NSString *)contentFromView: (UIView *)rootView {
    if (rootView.isHidden || rootView.alpha == 0) {
        return nil;
    }
    
    NSMutableString *elementContent = [NSMutableString string];
    /// 也可以增加别的控件
    // Button
    if ([rootView isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)rootView;
        NSString *title = button.titleLabel.text;
        if (title.length > 0) {
            [elementContent appendString:title];
        }
    } else if ([rootView isKindOfClass:[UILabel class]]) { // Label
        UILabel *label = (UILabel *)rootView;
        NSString *title = label.text;
        if (title.length > 0) {
            [elementContent appendString:title];
        }
    } else if ([rootView isKindOfClass:[UITextField class]]) { // UITextField
        UITextField *textField = (UITextField *)rootView;
        NSString *title = textField.text;
        if (title.length > 0) {
            [elementContent appendString:title];
        }
    } else {
        NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
        for (UIView *subView in rootView.subviews) {
            NSString *temp = [self contentFromView:subView];
            if (temp.length > 0) {
                [elementContentArray addObject:temp];
            }
        }
        
        if (elementContentArray.count > 0) {
            [elementContent appendString:[elementContentArray componentsJoinedByString:@"-"]];
        }
    }
    return elementContent;
}

@end
