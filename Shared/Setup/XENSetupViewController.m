//
//  XENSetupViewController.m
//  Tweak (Shared)
//
//  Created by Matt Clarke on 22/02/2020.
//

#import "XENSetupViewController.h"
#import "XENHResources.h"
#import "XENSetupWindow.h"

@interface XENSetupViewController ()

@end

@implementation XENSetupViewController

- (BOOL)_canShowWhileLocked {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self _loadSetupUI];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return IS_IPAD ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return IS_IPAD;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Set frame and scroll bounds
    if (IS_IPAD) {
        CGFloat width = 0.0;
        CGFloat height = 0.0;
        CGFloat bottomInset = 20;
        
        if (orient3 == UIInterfaceOrientationPortrait ||
            orient3 == UIInterfaceOrientationPortraitUpsideDown) {
            width = SCREEN_WIDTH * 0.9;
            height = SCREEN_HEIGHT * 0.6;
        } else {
            width = SCREEN_WIDTH * 0.7;
            height = SCREEN_HEIGHT * 0.7;
        }
        
        self.webView.frame = CGRectMake((SCREEN_WIDTH/2) - (width/2), SCREEN_HEIGHT - height - bottomInset, width, height);
    } else {
        CGFloat topInset = [UIApplication sharedApplication].statusBarFrame.size.height + 20;
        CGFloat sideInset = 0;
        self.webView.frame = CGRectMake(sideInset, topInset, SCREEN_WIDTH - (sideInset*2), SCREEN_HEIGHT - topInset - sideInset);
    }
    
    self.webView.scrollView.contentSize = self.webView.bounds.size;
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Create webview if possible
    if ([self _setupUIPresent]) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        [userContentController addScriptMessageHandler:self name:@"xenhtml"];
        
        config.userContentController = userContentController;
        config.requiresUserActionForMediaPlayback = NO;
        
        self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        
        self.webView.translatesAutoresizingMaskIntoConstraints = NO;
        self.webView.backgroundColor = [UIColor clearColor];
        self.webView.opaque = NO;
        
        self.webView.layer.cornerRadius = 12.5;
        self.webView.clipsToBounds = YES;
        
        // Override scroll behaviour
        self.webView.scrollView.scrollEnabled = NO;
        self.webView.scrollView.bounces = NO;
        self.webView.scrollView.scrollsToTop = NO;
        self.webView.scrollView.minimumZoomScale = 1.0;
        self.webView.scrollView.maximumZoomScale = 1.0;
        self.webView.scrollView.multipleTouchEnabled = YES;
        
        [self.view addSubview:self.webView];
    } else {
        
    }
}

- (BOOL)_setupUIPresent {
    NSString *path = [self _setupUIPath];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (NSString*)_setupUIPath {
#if TARGET_IPHONE_SIMULATOR
    return @"/<redacted>/index.html";
#else
    return @"/Library/Application Support/Xen HTML/Setup UI/index.html";
#endif
}

- (void)_loadSetupUI {
    if (![self _setupUIPresent]) return;
    
    NSString *path = [self _setupUIPath];
    
    NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO];
    
    if (url) {
        XENlog(@"Loading setup UI from: %@", url);
        [self.webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"xenhtml"] && [message.body isEqualToString:@"finish"]) {
        [XENHSetupWindow finishSetupMode];
    }
}

@end
