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

@property (nonatomic, strong) UIView *fallbackContainerView;
@property (nonatomic, strong) UILabel *fallbackLabelView;
@property (nonatomic, strong) UIButton *fallbackButton;

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
    
    CGFloat width       = 0.0;
    CGFloat height      = 0.0;
    CGFloat topInset    = 0.0;
    CGFloat bottomInset = 0.0;
    
    CGFloat fallbackPaddingY = 20;
    
    // Set frame and scroll bounds
    if (IS_IPAD) {
        bottomInset = 20;
        
        if (orient3 == UIInterfaceOrientationPortrait ||
            orient3 == UIInterfaceOrientationPortraitUpsideDown) {
            width = SCREEN_WIDTH * 0.9;
            height = SCREEN_HEIGHT * 0.6;
        } else {
            width = SCREEN_WIDTH * 0.7;
            height = SCREEN_HEIGHT * 0.7;
        }
    } else {
        topInset = [UIApplication sharedApplication].statusBarFrame.size.height + 20;
        
        height = SCREEN_HEIGHT - topInset;
        width = SCREEN_WIDTH;
    }
        
    self.webView.frame = CGRectMake((SCREEN_WIDTH/2) - (width/2), SCREEN_HEIGHT - height - bottomInset, width, height);
        
    if (self.fallbackContainerView) {
        CGRect labelRect = [XENHResources boundedRectForFont:self.fallbackLabelView.font andText:self.fallbackLabelView.text width:width * 0.8];
        
        self.fallbackLabelView.frame = CGRectMake(width * 0.1, fallbackPaddingY, width * 0.8, labelRect.size.height);
        
        [self.fallbackButton sizeToFit];
        
        self.fallbackButton.frame = CGRectMake((width / 2) - (self.fallbackButton.frame.size.width / 2), labelRect.size.height + fallbackPaddingY + fallbackPaddingY, self.fallbackButton.frame.size.width, self.fallbackButton.frame.size.height);
        
        CGFloat height = (fallbackPaddingY * 3) + labelRect.size.height + self.fallbackButton.frame.size.height;
        
        self.fallbackContainerView.frame = CGRectMake((SCREEN_WIDTH/2) - (width/2), SCREEN_HEIGHT - height - bottomInset, width, height);
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
        self.fallbackContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        self.fallbackContainerView.layer.cornerRadius = 12.5;
        self.fallbackContainerView.clipsToBounds = YES;
        
        if (@available(iOS 13.0, *)) {
            self.fallbackContainerView.backgroundColor = [UIColor systemGroupedBackgroundColor];
        } else {
            self.fallbackContainerView.backgroundColor = [UIColor whiteColor];
        }
        
        [self.view addSubview:self.fallbackContainerView];
        
        self.fallbackLabelView = [[UILabel alloc] initWithFrame:CGRectZero];
        self.fallbackLabelView.text = @"Failed to load Setup UI for Xen HTML";
        if (@available(iOS 13.0, *)) {
            self.fallbackLabelView.textColor = [UIColor labelColor];
        } else {
            self.fallbackLabelView.textColor = [UIColor darkTextColor];
        }
        
        self.fallbackLabelView.textAlignment = NSTextAlignmentCenter;
        
        [self.fallbackContainerView addSubview:self.fallbackLabelView];
        
        self.fallbackButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.fallbackButton.titleLabel.textColor = self.view.tintColor;
        [self.fallbackButton setTitle:@"Dismiss" forState:UIControlStateNormal];
        [self.fallbackButton addTarget:self action:@selector(_fallbackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.fallbackContainerView addSubview:self.fallbackButton];
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
        [self.webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
    }
}

- (void)_fallbackButtonPressed:(id)sender {
    [XENHSetupWindow finishSetupMode];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"xenhtml"] && [message.body isEqualToString:@"finish"]) {
        [XENHSetupWindow finishSetupMode];
    } else if ([message.name isEqualToString:@"xenhtml"] && [message.body isEqualToString:@"error"]) {
        [XENHSetupWindow finishSetupMode];
    }
}

@end
