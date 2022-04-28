//
//  TestWebViewController.m
//  TestWebView
//
//  Created by Flow on 4/28/22.
//

#import "TestWebViewController.h"
#import <WebKit/WebKit.h>

@interface TestWebViewController ()
@property(nonatomic, strong) WKWebView *webView;
@end

@implementation TestWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.4];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
//    self.webView.backgroundColor = UIColor.clearColor;
    self.webView.opaque = NO;
    [self.view addSubview:self.webView];
    
    NSURL *url = [NSURL fileURLWithPath:[NSBundle.mainBundle pathForResource:@"test" ofType:@"html"]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"close" forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    btn.frame = CGRectMake(250, 150, 60, 40);
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
}

- (void)btnClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
