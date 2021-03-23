//
//  UIScrollView+SensorsData.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/23.
//

#import "UIScrollView+SensorsData.h"
#import <objc/runtime.h>

@implementation UIScrollView (SensorsData)

- (void)setSensorsdata_delegateProxy:(SensorsAnalyticsDelegateProxy *)sensorsdata_delegateProxy {
    if (sensorsdata_delegateProxy) {
        objc_setAssociatedObject(self, @selector(setSensorsdata_delegateProxy:), sensorsdata_delegateProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (SensorsAnalyticsDelegateProxy *)sensorsdata_delegateProxy {
    return objc_getAssociatedObject(self, @selector(sensorsdata_delegateProxy));
}

@end
