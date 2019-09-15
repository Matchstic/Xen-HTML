//
//  ViewController.m
//  Testbed
//
//  Created by Matt Clarke on 12/08/2019.
//  Copyright © 2019 Matt Clarke. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@interface WKWebView (libwidgetinfo)
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration injectWidgetData:(BOOL)injectWidgetData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupWebView];
    
    // Load the webview
    NSString *testWidget = @"/opt/simject/var/mobile/Library/iWidgets/Xperia Clock DEBUG/Widget.html";
    NSURL *url = [NSURL fileURLWithPath:testWidget];
    
    [self.webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
}

- (void)setupWebView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    
    // This script is utilised to stop the loupé that iOS creates on long-press
    NSString *source1 = @"var style = document.createElement('style'); \
    style.type = 'text/css'; \
    style.innerText = '* { -webkit-user-select: none; -webkit-touch-callout: none; } body { background-color: transparent; }'; \
    var head = document.getElementsByTagName('head')[0];\
    head.appendChild(style);";
    WKUserScript *stopCallouts = [[WKUserScript alloc] initWithSource:source1 injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    
    // Prevents scaling of the viewport
    NSString *source2 = @"var doc = document.documentElement; \
    var meta = document.createElement('meta'); \
    meta.name = 'viewport'; \
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, shrink-to-fit=no'; \
    var head = document.head; \
    if (!head) { head = document.createElement('head'); doc.appendChild(head); } \
    head.appendChild(meta);";
    
    WKUserScript *stopScaling = [[WKUserScript alloc] initWithSource:source2 injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    
    [userContentController addUserScript:stopCallouts];
    [userContentController addUserScript:stopScaling];
    
    config.userContentController = userContentController;
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config injectWidgetData:YES];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    self.webView.scrollView.layer.masksToBounds = NO;
    
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.scrollView.contentSize = self.webView.bounds.size;
    
    self.webView.scrollView.bounces = NO;
    self.webView.scrollView.scrollsToTop = NO;
    self.webView.scrollView.minimumZoomScale = 1.0;
    self.webView.scrollView.maximumZoomScale = 1.0;
    self.webView.scrollView.multipleTouchEnabled = YES;
    
    self.webView.allowsLinkPreview = NO;
    
    [self.view addSubview:self.webView];
}

- (void)viewDidLayoutSubviews {
    self.webView.frame = CGRectMake(20, 20, self.view.frame.size.width - 40, self.view.frame.size.height - 40);
}

@end
