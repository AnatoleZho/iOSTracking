//
//  SensorsDataWKWebViewController.m
//  Demo
//
//  Created by AnatoleZhou on 2021/2/27.
//

#import "SensorsDataWKWebViewController.h"
#import <SensorsSDK/SensorsSDK.h>

#import <WebKit/WebKit.h>

@interface SensorsDataWKWebViewController ()<WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation SensorsDataWKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"sensorsData"];
    
    NSURL *url = [NSBundle.mainBundle.bundleURL URLByAppendingPathComponent:@"sensorsdata.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [_webView loadRequest:request];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([[SensorsAnalyticsSDK sharedInstance] shouldTrackWithWebView:webView request:navigationAction.request]) {
        return decisionHandler(WKNavigationActionPolicyCancel);
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.body[@"command"] isEqual:@"track"]) {
        [[SensorsAnalyticsSDK sharedInstance] trackFromH5WithEvent:message.body[@"event"]];
    }
}
@end
