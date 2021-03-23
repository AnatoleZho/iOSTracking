//
//  AppDelegate.m
//  Demo
//
//  Created by AnatoleZhou on 2021/2/18.
//

#import "AppDelegate.h"

#import <SensorsSDK/SensorsSDK.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // 初始化SDK
    [SensorsAnalyticsSDK startWithServerURL:@"http://sdk-test.cloud.sensorsdata.cn:8006/sa?project=default&token=95c73ae661f85aa0"];
    // 在系统默认的 UserAgent 中添加默认标记（@“ /sa-sdk-ios”）
    [[SensorsAnalyticsSDK sharedInstance] addWebViewUserAgent:@" /sa-sdk-ios"];
    
    // 触发事件
    [[SensorsAnalyticsSDK sharedInstance] track:@"MyFirstEvent" properties:@{@"testKey": @"testValue"}];
    
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
