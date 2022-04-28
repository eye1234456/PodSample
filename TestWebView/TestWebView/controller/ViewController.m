//
//  ViewController.m
//  TestWebView
//
//  Created by Flow on 4/28/22.
//

#import "ViewController.h"
#import "TestWebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.redColor;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"open" forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    btn.frame = CGRectMake(50, 150, 60, 40);
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnClick {
    TestWebViewController *vc = [TestWebViewController new];
    vc.modalPresentationStyle = UIModalPresentationCustom;
    // 直接展示，像alpha变化一样
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    // 重下往上展示
//    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    // 不支持
//    vc.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    // 卡片翻转
//    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:vc animated:YES completion:nil];
}
@end
