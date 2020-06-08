/*
 Copyright (C) 2018  Matt Clarke
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#import "XENHEditorWebViewController.h"
#import "XENHPResources.h"
#import "XENHWidgetConfiguration.h"

@interface WKPreferences (Private)
- (void)_setAllowFileAccessFromFileURLs:(BOOL)arg1;
- (void)_setAntialiasedFontDilationEnabled:(BOOL)arg1;
- (void)_setCompositingBordersVisible:(BOOL)arg1;
- (void)_setCompositingRepaintCountersVisible:(BOOL)arg1;
- (void)_setDeveloperExtrasEnabled:(BOOL)arg1;
- (void)_setDiagnosticLoggingEnabled:(BOOL)arg1;
- (void)_setFullScreenEnabled:(BOOL)arg1;
- (void)_setJavaScriptRuntimeFlags:(unsigned int)arg1;
- (void)_setLogsPageMessagesToSystemConsoleEnabled:(BOOL)arg1;
- (void)_setOfflineApplicationCacheIsEnabled:(BOOL)arg1;
- (void)_setSimpleLineLayoutDebugBordersEnabled:(BOOL)arg1;
- (void)_setStandalone:(BOOL)arg1;
- (void)_setStorageBlockingPolicy:(int)arg1;
- (void)_setTelephoneNumberDetectionIsEnabled:(BOOL)arg1;
- (void)_setTiledScrollingIndicatorVisible:(BOOL)arg1;
- (void)_setVisibleDebugOverlayRegions:(unsigned int)arg1;
@end

@interface WKWebView (IOS9)
- (id)loadFileURL:(id)arg1 allowingReadAccessToURL:(id)arg2;
- (void)_killWebContentProcessAndResetState;
- (void)_close;
@end

@interface WKWebView (WidgetInfo)
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration injectWidgetData:(BOOL)injectWidgetData;
@end

@interface UIScrollView (iOS11)
@property(nonatomic) int contentInsetAdjustmentBehavior;
@end

@interface XENHEditorWebViewController ()

@property (nonatomic, strong) UILabel *noHTMLLabel;
@property (nonatomic, readwrite) BOOL enableShowNoHTML;
@property (nonatomic, strong) NSString *currentURL;
@property (nonatomic, strong) NSString *_unmodifiedCurrentURL;

@property (nonatomic, readwrite) BOOL isFullscreen;
@property (nonatomic, strong) NSDictionary *metadata;

@end

@implementation XENHEditorWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
    
}

- (instancetype)initWithVariant:(XENHEditorWebViewVariant)webViewVariant showNoHTMLLabel:(BOOL)enableShowNoHTML {
    self = [super init];
    
    if (self) {
        // Setup
        self.webviewVariant = webViewVariant;
        self.enableShowNoHTML = enableShowNoHTML;
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.view.userInteractionEnabled = NO;
    
    // If enabled, show a label stating "No Widget Selected" as appropriate.
    if (self.enableShowNoHTML) {
        self.noHTMLLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.noHTMLLabel.text = [XENHResources localisedStringForKey:@"WIDGET_EDITOR_NONE_SELECTED"];
        self.noHTMLLabel.textColor = [UIColor whiteColor];
        self.noHTMLLabel.textAlignment = NSTextAlignmentCenter;
        self.noHTMLLabel.font = [UIFont systemFontOfSize:18];
        self.noHTMLLabel.hidden = NO;
        self.noHTMLLabel.userInteractionEnabled = NO;
    
        [self.view addSubview:self.noHTMLLabel];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Update WebView frame.
    self.webView.frame = CGRectMake(
                                    [[self.metadata objectForKey:@"x"] floatValue]*self.view.bounds.size.width,
                                    [[self.metadata objectForKey:@"y"] floatValue]*self.view.bounds.size.height,
                                    self.isFullscreen ? self.view.bounds.size.width : [[self.metadata objectForKey:@"width"] floatValue],
                                    self.isFullscreen ? self.view.bounds.size.height : [[self.metadata objectForKey:@"height"] floatValue]);
    
    // Update no HTML label.
    self.noHTMLLabel.frame = self.view.bounds;
}

#pragma mark Utility methods

- (void)reloadWebViewToPath:(NSString*)path updateMetadata:(BOOL)shouldSetMetadata ignorePreexistingMetadata:(BOOL)ignorePreexistingMetadata {
    
    self._unmodifiedCurrentURL = path;
    
    // XXX: To support multiple instances of the same widget, sometimes widgetIndexFile will be
    // prefixed by :1/var/mobile/Library/..., :2/var/mobile/Library/..., etc.
    // Therefore, we need to check if this is the case BEFORE updating our internal property
    // holding this location.
    
    if ([path hasPrefix:@":"]) {
        // Read the string up to the first /, then strip off the : prefix.
        NSRange range = [path rangeOfString:@"/"];
        
        path = [path substringFromIndex:range.location];
        
        NSLog(@"Handling multiple instances for this widget! Substring: %@", path);
    }
    
    self.currentURL = path;
    
    NSURL *url = [NSURL fileURLWithPath:self.currentURL isDirectory:NO];
    
    // If this URL exists, load it. Else, don't bother to.
    if (url && [[NSFileManager defaultManager] fileExistsAtPath:self.currentURL]) {
        NSLog(@"XenHTMLPrefs :: Loading from URL: %@", url);
        
        if (shouldSetMetadata) {
            self.metadata = [self rawMetadataForHTMLFile:self._unmodifiedCurrentURL ignorePreexistingMetadata:ignorePreexistingMetadata];
            
            // Update isFullscreen.
            self.isFullscreen = [[self.metadata objectForKey:@"isFullscreen"] boolValue];
        }
        
        [self unloadWebview];
        
        self.webView = [self loadWKWebView:self.currentURL];
        self.webView.frame = CGRectMake(
                                        [[self.metadata objectForKey:@"x"] floatValue]*self.view.bounds.size.width,
                                        [[self.metadata objectForKey:@"y"] floatValue]*self.view.bounds.size.height,
                                        self.isFullscreen ? self.view.bounds.size.width : [[self.metadata objectForKey:@"width"] floatValue],
                                        self.isFullscreen ? self.view.bounds.size.height : [[self.metadata objectForKey:@"height"] floatValue]);
        [self.view addSubview:self.webView];

        // Hide "No Widget Selected"
        self.noHTMLLabel.hidden = YES;
    } else {
        // Show "No Widget Selected"
        self.noHTMLLabel.hidden = NO;
        
        [self.webView loadHTMLString:@"" baseURL:url];
    }
}

- (BOOL)hasHTML {
    return ![self.currentURL isEqualToString:@""] && [[NSFileManager defaultManager] fileExistsAtPath:self.currentURL];
}

- (NSDictionary*)getMetadata {
    return self.metadata;
}

- (void)setMetadata:(NSDictionary*)metadata reloadingWebView:(BOOL)reloadWebView {
    self.metadata = metadata;
    
    // Update isFullscreen.
    self.isFullscreen = [[self.metadata objectForKey:@"isFullscreen"] boolValue];
    
    // And reload widget if wanted.
    if (reloadWebView) {
        [self reloadWebViewToPath:self.currentURL updateMetadata:NO ignorePreexistingMetadata:NO];
    }
}

- (NSString*)getCurrentWidgetURL {
    return self.currentURL;
}

#pragma mark WebView loading

-(WKWebView*)loadWKWebView:(NSString*)baseString {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    
    NSString *source1 = @"var style = document.createElement('style'); \
    style.type = 'text/css'; \
    style.innerText = '*:not(input):not(textarea) { -webkit-user-select: none; -webkit-touch-callout: none; } body { background-color: transparent; }'; \
    var head = document.getElementsByTagName('head')[0];\
    head.appendChild(style);";
    WKUserScript *stopCallouts = [[WKUserScript alloc] initWithSource:source1 injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    
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
    
    // We also need to inject the settings required by the widget
    NSMutableString *settingsInjection = [@"" mutableCopy];
    
    NSDictionary *options = [self.metadata objectForKey:@"options"];
    for (NSString *key in [options allKeys]) {
        if (!key || [key isEqualToString:@""]) {
            continue;
        }
        
        id value = [options objectForKey:key];
        if (!value) {
            value = @"0";
        }
        
        BOOL isNumber = [[value class] isSubclassOfClass:[NSNumber class]];
        
        NSString *valueOut = isNumber ? [NSString stringWithFormat:@"%@", value] : [NSString stringWithFormat:@"\"%@\"", value];
        
        [settingsInjection appendFormat:@"var %@ = %@;", key, valueOut];
    }
    
    WKUserScript *settingsInjector = [[WKUserScript alloc] initWithSource:settingsInjection injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [userContentController addUserScript:settingsInjector];
    
    config.userContentController = userContentController;
    config.requiresUserActionForMediaPlayback = YES;
    
    WKPreferences *preferences = [[WKPreferences alloc] init];
    [preferences _setAllowFileAccessFromFileURLs:YES];
    [preferences _setFullScreenEnabled:YES];
    [preferences _setOfflineApplicationCacheIsEnabled:YES]; // Local storage is needed for Lock+ etc.
    [preferences _setStandalone:YES];
    [preferences _setTelephoneNumberDetectionIsEnabled:NO];
    [preferences _setTiledScrollingIndicatorVisible:NO];
    
    config.preferences = preferences;
    
    // Load for widget info, if available
    id _webview = [WKWebView alloc];
    WKWebView *webView = nil;
    
    if ([_webview respondsToSelector:@selector(initWithFrame:configuration:injectWidgetData:)]) {
        NSLog(@"Initialising with widgetinfo injection");
        webView = [_webview initWithFrame:CGRectZero configuration:config injectWidgetData:YES];
    } else
        webView = [_webview initWithFrame:CGRectZero configuration:config];
    
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.navigationDelegate = self;
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    webView.scrollView.scrollEnabled = NO;
    webView.userInteractionEnabled = NO;
    webView.scrollView.layer.masksToBounds = NO;
    
    if (@available(iOS 11.0, *)) {
        webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    NSURL *url = [NSURL fileURLWithPath:baseString isDirectory:NO];
    if (url && [[NSFileManager defaultManager] fileExistsAtPath:baseString]) {
        NSLog(@"*** [Xen HTML Prefs] :: Loading from URL: %@", url);
        [webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
    }
    
    return webView;
}

-(void)unloadWebview {
    if (self.webView) {
        self.webView.hidden = YES; // Stop any residual GPU updates.
        
        [self.webView stopLoading];
        [self.webView _close];
        
        self.webView.navigationDelegate = nil;
        self.webView.scrollView.delegate = nil;
        
        [self.webView removeFromSuperview];
        self.webView = nil;
    }
}

-(NSDictionary*)rawMetadataForHTMLFile:(NSString*)filePath ignorePreexistingMetadata:(BOOL)ignorePreexistingMetadata {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    NSString *key = @"";
    switch (self.webviewVariant) {
        case kVariantLockscreenBackground:
            key = @"LSBackground";
            break;
        case kVariantLockscreenForeground:
            key = @"LSForeground";
            break;
        case kVariantHomescreenBackground:
            key = @"SBBackground";
            break;
            
        default:
            break;
    }
    
    // Load up the preexisting metadata for this widget
    NSDictionary *widgetsForLocation = [[XENHResources getPreferenceKey:@"widgets"] objectForKey:key];
    NSDictionary *widgetMetadata = [widgetsForLocation objectForKey:@"widgetMetadata"];
    NSMutableDictionary *preexisting = [[widgetMetadata objectForKey:filePath] mutableCopy];
    
    if (!ignorePreexistingMetadata && preexisting) {
        // Verify values for the metadata. If it's something ridiculous, reset it back to 0.
        // Primarily, we check the position values.
        
        CGFloat x = [[preexisting objectForKey:@"x"] floatValue];
        CGFloat y = [[preexisting objectForKey:@"y"] floatValue];
        
        if (x*SCREEN_WIDTH == NAN) {
            [preexisting setObject:[NSNumber numberWithFloat:0] forKey:@"x"];
        }
        
        if (y*SCREEN_HEIGHT == NAN) {
            [preexisting setObject:[NSNumber numberWithFloat:0] forKey:@"y"];
        }
        
        return preexisting;
    } else {
        return [[XENHWidgetConfiguration defaultConfigurationForPath:filePath] serialise];
    }
}

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"XenHTMLPrefs :: Failed provisional navigation: %@", error);
    
}
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {}
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"XenHTMLPrefs :: Failed navigation: %@", error);
}

/*- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    // Well, crap. WebView process has terminated. :( Better reload!
    NSLog(@"********* CONTENT PROCESS TERMINATED. RELOADING.");
    
    NSURL *url = [NSURL fileURLWithPath:self.currentURL isDirectory:NO];
    
    if (url && [[NSFileManager defaultManager] fileExistsAtPath:self.currentURL]) {
        NSLog(@"XenHTMLPrefs :: Loading from URL: %@", url);
        self.metadata = [self rawMetadataForHTMLFile:self._unmodifiedCurrentURL ignorePreexistingMetadata:NO];
        
        [self unloadWebview];
        
        self.webView = [self loadWKWebView:self.currentURL];
        self.webView.frame = CGRectMake(
                                        [[self.metadata objectForKey:@"x"] floatValue]*SCREEN_WIDTH,
                                        [[self.metadata objectForKey:@"y"] floatValue]*SCREEN_HEIGHT,
                                        self.isFullscreen ? SCREEN_WIDTH : [[self.metadata objectForKey:@"width"] floatValue],
                                        self.isFullscreen ? SCREEN_HEIGHT : [[self.metadata objectForKey:@"height"] floatValue]);
        
        [self.view addSubview:self.webView];
    } else {
        [self.webView loadHTMLString:@"" baseURL:nil];
    }
}*/

@end
