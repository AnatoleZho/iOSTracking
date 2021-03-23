//
//  UIView+SensorData.h
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SensorData)
// 视图类型
@property (nonatomic, copy, readonly) NSString *sensordata_elementType;

// 视图显示文本
@property (nonatomic, copy, readonly) NSString *sensordata_elementContent;

// 视图所属页面
@property (nonatomic, strong, readonly) UIViewController *sensordata_viewController;

@end

@interface UILabel (SensorsData)

@end

@interface UIButton (SensorsData)

@end

@interface UISwitch (SensorsData)

@end

@interface UISlider (SensorsData)

@end

@interface UISegmentedControl (SensorsData)

@end

@interface UIStepper (SensorsData)

@end


NS_ASSUME_NONNULL_END

