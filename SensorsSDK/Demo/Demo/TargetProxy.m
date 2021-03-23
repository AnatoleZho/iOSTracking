//
//  TargetProxy.m
//  SensorsSDK
//
//  Created by AnatoleZhou on 2021/2/23.
//

#import "TargetProxy.h"

@interface TargetProxy ()
{
    // 保存需要将消息转发到的第一个真实对象
    // 第一个真实对象的方法调用优先级会比第二个真实对象的方法调用优先级高
    id _realObject1;
    // 保存需要将消息转发到的第二个真实对象
    id _realObject2;
    
    
}

@end

@implementation TargetProxy

- (instancetype)initWithObject1:(id)object1 object2:(id)object2 {
    _realObject1 = object1;
    _realObject2 = object2;
    
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    // 获取 _realObject1 中 sel 的方法签名
    NSMethodSignature *signature = [_realObject1 methodSignatureForSelector:sel];
    
    // 如果 _realObject1 中有该方法，那么返回该方法签名
    // 如果没有，则查看 _realObjct2
    if (signature) {
        return signature;
    }
    
    // 如果 _realObject2 中有该方法，那么返回该方法签名

    signature = [_realObject2 methodSignatureForSelector:sel];
    return signature;
    
}

-(void)forwardInvocation:(NSInvocation *)invocation {
    // 获取拥有该方法的真实对象
    id target = [_realObject1 methodSignatureForSelector:[invocation selector]] ? _realObject1 : _realObject2;
    
    // 执行方法
    [invocation invokeWithTarget:target];
}


@end
