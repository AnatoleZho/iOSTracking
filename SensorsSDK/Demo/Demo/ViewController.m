//
//  ViewController.m
//  Demo
//
//  Created by AnatoleZhou on 2021/2/18.
//

#import "ViewController.h"

#import "TargetProxy.h"

#import "SensorDataCollectionViewController.h"

#import <SensorsSDK/SensorsSDK.h>

#import "SensorsDataReleaseObject.h"

#import "SensorsDataWKWebViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"首页";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    
    [self testTarget];
}

// 重写必须调用     [super viewDidAppear:animated];否则不会触发 埋点事件
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}
- (IBAction)buttonClick:(UIButton *)sender {
    NSLog(@"%s", __func__);
//    SensorDataCollectionViewController *collectionVC = [[SensorDataCollectionViewController alloc] init];
//    [self.navigationController pushViewController:collectionVC animated:YES];
    [[SensorsAnalyticsSDK sharedInstance] login:@"11111111111"];
    
//    NSArray *arr = @[@"first", @"second"];
//    NSLog(@"%@", arr[2]);
//    
//    SensorsDataReleaseObject *releseObject = [[SensorsDataReleaseObject alloc] init];
//    [releseObject signalCrash];
    
    
}
- (IBAction)switchChange:(UISwitch *)sender {
    NSLog(@"%s", __func__);
}
- (IBAction)slider:(UISlider *)sender {
    NSLog(@"%s", __func__);

}

- (IBAction)segment:(UISegmentedControl *)sender {
    NSLog(@"%s", __func__);
    SensorsDataWKWebViewController *h5VC = [[SensorsDataWKWebViewController alloc]  init];
    [self.navigationController pushViewController:h5VC animated:YES];
}

- (IBAction)stepper:(UIStepper *)sender {
    NSLog(@"%s", __func__);
}

- (IBAction)tap:(UITapGestureRecognizer *)sender {
    NSLog(@"%s", __func__);

}
- (IBAction)longPress:(UILongPressGestureRecognizer *)sender {
    NSLog(@"%s", __func__);

}

- (IBAction)start:(UIButton *)sender {
    [[SensorsAnalyticsSDK sharedInstance] trackTimerStart:@"doSomething"];

}
- (IBAction)pause:(UIButton *)sender {
    [[SensorsAnalyticsSDK sharedInstance] trackTimerPause:@"doSomething"];

}
- (IBAction)resume:(UIButton *)sender {
    [[SensorsAnalyticsSDK sharedInstance] trackTimerResume:@"doSomething"];

}
- (IBAction)end:(UIButton *)sender {
    [[SensorsAnalyticsSDK sharedInstance] trackTimerEnd:@"doSomething" propertird:nil];

}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    cell.textLabel.text = [NSString stringWithFormat:@"点击了 %ld", (long)indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s", __func__);
}

- (void)testTarget {
    NSMutableString *stringM = [NSMutableString string];
    
    NSMutableArray *arrayM = [NSMutableArray array];
    
    // 创建一个委托对象来包装真实对象
    id proxy = [[TargetProxy alloc] initWithObject1:stringM object2:arrayM];
    
    [proxy appendString:@"This "];
    [proxy appendString:@"is "];
    
    [proxy addObject:stringM];
    
    [proxy appendString:@"a "];
    [proxy appendString:@"test!"];
    
    // 使用 valueForKey： 方法获取字符出啊长度
    NSLog(@"The string‘s length is: %@", [proxy valueForKey:@"length"]);
    
    NSLog(@"Count should be 1, it is: %ld", [proxy count]);
    
    if ([[proxy objectAtIndex:0] isEqualToString:@"This is a test!"]) {
        NSLog(@"Appending successfull");
    } else {
        NSLog(@"Appending failed, got: '%@'", proxy);
    }
}

@end
