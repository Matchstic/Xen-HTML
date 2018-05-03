//
//  XENHWidgetController.m
//  Tweak
//
//  Created by Matt Clarke on 30/04/2018.
//

#import "XENHWidgetController.h"
#import "XENHTouchPassThroughView.h"
#import "XENHResources.h"
#import "PrivateWebKitHeaders.h"

#import <objc/runtime.h>

@interface XENHWidgetController ()

@end

@implementation XENHWidgetController

/////////////////////////////////////////////////////////////////////////////
#pragma mark Initialisation
/////////////////////////////////////////////////////////////////////////////

- (instancetype)init {
    self = [super init];
    
    if (self) {
        // Any initialisation...
    }
    
    return self;
}

- (void)loadView {
    self.view = [[XENHTouchPassThroughView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)dealloc {
    [self unloadWidget];
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
/////////////////////////////////////////////////////////////////////////////

- (void)configureWithWidgetIndexFile:(NSString*)widgetIndexFile andMetadata:(NSDictionary*)metadata {
    // First, unload the existing widget
    [self unloadWidget];
    
    self.widgetIndexFile = widgetIndexFile;
    self.widgetMetadata = metadata;
    
    // TODO: Check fallback state.
    BOOL fallbackIsRequired = NO;
    
    if (fallbackIsRequired) {
        // Load using UIWebView
        XENlog(@"Loading using fallback method to support Cycript etc");
        [self _loadLegacyWebView];
        [self.view addSubview:self.legacyWebView];
    } else {
        XENlog(@"Loading via WKWebView");
        // Load using WKWebView
        [self _loadWebView];
        [self.view addSubview:self.webView];
    }
}

- (void)_loadWebView {
    BOOL isWidgetFullscreen = [[self.widgetMetadata objectForKey:@"isFullscreen"] boolValue];
    BOOL widgetCanScroll = [[self.widgetMetadata objectForKey:@"widgetCanScroll"] boolValue];
    
    CGRect rect = CGRectMake(
                             [[self.widgetMetadata objectForKey:@"x"] floatValue]*SCREEN_WIDTH,
                             [[self.widgetMetadata objectForKey:@"y"] floatValue]*SCREEN_HEIGHT,
                             isWidgetFullscreen ? SCREEN_WIDTH : [[self.widgetMetadata objectForKey:@"width"] floatValue],
                             isWidgetFullscreen ? SCREEN_HEIGHT : [[self.widgetMetadata objectForKey:@"height"] floatValue]
                             );
    
    // Setup configuration for the WKWebView
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    
    // This script is utilised to stop the loupé that iOS creates on long-press
    NSString *source1 = @"var style = document.createElement('style'); \
    style.type = 'text/css'; \
    style.innerText = '*:not(input):not(textarea) { -webkit-user-select: none; -webkit-touch-callout: none; } body { background-color: transparent; }'; \
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
    
    // We also need to inject the settings required by the widget.
    NSMutableString *settingsInjection = [@"" mutableCopy];
    
    NSDictionary *options = [self.widgetMetadata objectForKey:@"options"];
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
    
    // Configure some private settings on WKWebView
    WKPreferences *preferences = [[WKPreferences alloc] init];
    [preferences _setAllowFileAccessFromFileURLs:YES];
    [preferences _setFullScreenEnabled:YES];
    [preferences _setOfflineApplicationCacheIsEnabled:YES]; // Local storage is needed for Lock+ etc.
    [preferences _setStandalone:YES];
    [preferences _setTelephoneNumberDetectionIsEnabled:NO];
    [preferences _setTiledScrollingIndicatorVisible:NO];
    
    config.preferences = preferences;
    
    if (self.webView) {
        [self.webView removeFromSuperview];
        self.webView = nil;
    }
    
    self.webView = [[WKWebView alloc] initWithFrame:rect configuration:config];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.navigationDelegate = self;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    self.webView.scrollView.layer.masksToBounds = NO;
    
    if (!widgetCanScroll) {
        _webView.scrollView.scrollEnabled = NO;
        _webView.scrollView.contentSize = _webView.bounds.size;
    } else {
        _webView.scrollView.scrollEnabled = YES;
    }
    
    _webView.scrollView.bounces = NO;
    _webView.scrollView.scrollsToTop = NO;
    _webView.scrollView.minimumZoomScale = 1.0;
    _webView.scrollView.maximumZoomScale = 1.0;
    _webView.scrollView.multipleTouchEnabled = YES;
    
    NSURL *url = [NSURL fileURLWithPath:self.widgetIndexFile isDirectory:NO];
    if (url && [[NSFileManager defaultManager] fileExistsAtPath:self.widgetIndexFile]) {
        XENlog(@"Loading from URL: %@", url);
        [_webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
    }
}

- (void)_loadLegacyWebView {
    BOOL isWidgetFullscreen = [[self.widgetMetadata objectForKey:@"isFullscreen"] boolValue];
    BOOL widgetCanScroll = [[self.widgetMetadata objectForKey:@"widgetCanScroll"] boolValue];
    
    CGRect rect = CGRectMake(
                             [[self.widgetMetadata objectForKey:@"x"] floatValue]*SCREEN_WIDTH,
                             [[self.widgetMetadata objectForKey:@"y"] floatValue]*SCREEN_HEIGHT,
                             isWidgetFullscreen ? SCREEN_WIDTH : [[self.widgetMetadata objectForKey:@"width"] floatValue],
                             isWidgetFullscreen ? SCREEN_HEIGHT : [[self.widgetMetadata objectForKey:@"height"] floatValue]
                             );
    
    if (self.legacyWebView) {
        [self.legacyWebView removeFromSuperview];
        self.legacyWebView = nil;
    }
    
    self.legacyWebView = [[UIWebView alloc] initWithFrame:rect];
    self.legacyWebView.backgroundColor = [UIColor clearColor];
    self.legacyWebView.opaque = NO;
    self.legacyWebView.tag = 1337;
    
    UIWebDocumentView *document = [self.legacyWebView _documentView];
    WebView *webview = [document webView];
    WebPreferences *preferences = [webview preferences];
    UIScrollView *scroller_;
    
    if ([self.legacyWebView respondsToSelector:@selector(setDataDetectorTypes:)])
        [self.legacyWebView setDataDetectorTypes:0x80000000];
    
    [[self.legacyWebView _documentView] setAutoresizes:YES];
    [self.legacyWebView setBackgroundColor:[UIColor clearColor]];
    if ([[self.legacyWebView _documentView] respondsToSelector:@selector(setDrawsBackground:)])
        [[self.legacyWebView _documentView] setDrawsBackground:NO];
    [[[self.legacyWebView _documentView] webView] setDrawsBackground:NO];
    
    self.legacyWebView.scrollView.userInteractionEnabled = YES;
    self.legacyWebView.userInteractionEnabled = YES;
    self.legacyWebView.scrollView.delegate = nil;
    
    if (!widgetCanScroll) {
        self.legacyWebView.scrollView.contentSize = self.view.bounds.size;
        self.legacyWebView.scrollView.scrollEnabled = NO;
    } else {
        self.legacyWebView.scrollView.scrollEnabled = YES;
    }
    
    self.legacyWebView.scrollView.bounces = NO;
    self.legacyWebView.scrollView.multipleTouchEnabled = YES;
    self.legacyWebView.scrollView.scrollsToTop = NO;
    self.legacyWebView.scrollView.showsHorizontalScrollIndicator = NO;
    self.legacyWebView.scrollView.showsVerticalScrollIndicator = NO;
    self.legacyWebView.scrollView.minimumZoomScale = 1.0;
    self.legacyWebView.scrollView.maximumZoomScale = 1.0;
    self.legacyWebView.scalesPageToFit = NO;
    self.legacyWebView.clipsToBounds = NO;
    self.legacyWebView.scrollView.layer.masksToBounds = NO;
    
    // Nitro
    [preferences setAccelerated2dCanvasEnabled:YES];
    [preferences setAcceleratedCompositingEnabled:YES];
    [preferences setAcceleratedDrawingEnabled:YES];
    
    [document setTileSize:rect.size];
    
    [document setBackgroundColor:[UIColor clearColor]];
    [document setDrawsBackground:NO];
    [document setUpdatesScrollView:NO];
    
    [webview setPreferencesIdentifier:@"WebCycript"];
    
    [preferences _setLayoutInterval:0];
    
    [preferences setCacheModel:0];
    [preferences setJavaScriptCanOpenWindowsAutomatically:YES];
    [preferences setOfflineWebApplicationCacheEnabled:YES];
    
    if ([webview respondsToSelector:@selector(setShouldUpdateWhileOffscreen:)])
        [webview setShouldUpdateWhileOffscreen:NO];
    
    if ([webview respondsToSelector:@selector(_setAllowsMessaging:)])
        [webview _setAllowsMessaging:YES];
    
    [webview setCSSAnimationsSuspended:NO];
    [self.legacyWebView _setWebSelectionEnabled:NO]; // Highly experimental, but works
    
    if ([self.legacyWebView respondsToSelector:@selector(_scrollView)])
        scroller_ = [self.legacyWebView _scrollView];
    
    scroller_.contentSize = self.view.bounds.size;
    
    [self.legacyWebView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.widgetIndexFile]) {
        NSURL *url = [NSURL fileURLWithPath:self.widgetIndexFile isDirectory:NO];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
        
        XENlog(@"Loading request %@", request);
        
        [self.legacyWebView loadRequest:request];
        
        [self.legacyWebView stringByEvaluatingJavaScriptFromString:@"document.body.overflow = 'hidden';"];
        [self.legacyWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.overflow = 'hidden';"];
        [self.legacyWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
        [self.legacyWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserDrag='none';"];
        [self.legacyWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserModify='none';"];
        [self.legacyWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitHighlight='none';"];
        [self.legacyWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTextSizeAdjust='none';"];
        [self.legacyWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    }
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Orientation and layout handling
/////////////////////////////////////////////////////////////////////////////

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    BOOL isWidgetFullscreen = [[self.widgetMetadata objectForKey:@"isFullscreen"] boolValue];
    BOOL widgetCanScroll = [[self.widgetMetadata objectForKey:@"widgetCanScroll"] boolValue];
    
    CGRect rect = CGRectMake(
                            [[self.widgetMetadata objectForKey:@"x"] floatValue]*SCREEN_WIDTH,
                            [[self.widgetMetadata objectForKey:@"y"] floatValue]*SCREEN_HEIGHT,
                            isWidgetFullscreen ? SCREEN_WIDTH : [[self.widgetMetadata objectForKey:@"width"] floatValue],
                            isWidgetFullscreen ? SCREEN_HEIGHT : [[self.widgetMetadata objectForKey:@"height"] floatValue]
                  );
    
    self.webView.frame = rect;
    self.legacyWebView.frame = rect;
    
    if (!widgetCanScroll) {
        self.webView.scrollView.contentSize = self.webView.bounds.size;
        self.legacyWebView.scrollView.contentSize = self.legacyWebView.bounds.size;
    }
}

- (void)rotateToOrientation:(int)orient {
    BOOL isWidgetFullscreen = [[self.widgetMetadata objectForKey:@"isFullscreen"] boolValue];
    BOOL widgetCanScroll = [[self.widgetMetadata objectForKey:@"widgetCanScroll"] boolValue];
    
    CGRect rect = CGRectMake(
                             [[self.widgetMetadata objectForKey:@"x"] floatValue]*SCREEN_WIDTH,
                             [[self.widgetMetadata objectForKey:@"y"] floatValue]*SCREEN_HEIGHT,
                             isWidgetFullscreen ? SCREEN_WIDTH : [[self.widgetMetadata objectForKey:@"width"] floatValue],
                             isWidgetFullscreen ? SCREEN_HEIGHT : [[self.widgetMetadata objectForKey:@"height"] floatValue]
                             );
    
    self.view.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
    
    if (self.usingLegacyWebView) {
        self.legacyWebView.frame = rect;
        
        if (!widgetCanScroll) {
            UIWebDocumentView *document = [self.legacyWebView _documentView];
            
            self.legacyWebView.scrollView.contentSize = rect.size;
            
            [document setTileSize:rect.size];
            
            if ([self.legacyWebView respondsToSelector:@selector(_scrollView)])
                [self.legacyWebView _scrollView].contentSize = rect.size;
        }
    } else {
        self.webView.frame = rect;
        
        if (!widgetCanScroll) {
            self.webView.scrollView.contentSize = self.webView.bounds.size;
        }
    }
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Pause handling
/////////////////////////////////////////////////////////////////////////////

-(void)setPaused:(BOOL)paused {
    [self setPaused:paused animated:NO];
}

-(void)setPaused:(BOOL)paused animated:(BOOL)animated {
    // Need to make 100% sure we're on the main thread doing this part.
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if (self.usingLegacyWebView) {
            self.legacyWebView.hidden = paused;
            self.legacyWebView.alpha = 1.0;
        } else {
            self.webView.hidden = paused;
            self.webView.alpha = 1.0;
        }
    });
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Lifecycle handling
/////////////////////////////////////////////////////////////////////////////

- (void)unloadWidget {
    [self _unloadWebView];
    [self _unloadLegacyWebView];
}

- (void)reloadWidget {
    [self configureWithWidgetIndexFile:self.widgetIndexFile andMetadata:self.widgetMetadata];
}

- (void)_unloadWebView {
    [self.webView stopLoading];
    [self.webView loadHTMLString:@"" baseURL:[NSURL URLWithString:@""]];
    
    self.webView.hidden = YES; // Stop any residual GPU updates.
    [self.webView removeFromSuperview];
}

- (void)_unloadLegacyWebView {
    [self.legacyWebView stopLoading];
    [self.legacyWebView loadHTMLString:@"" baseURL:[NSURL URLWithString:@""]];
    
    self.legacyWebView.hidden = YES;
    [self.legacyWebView removeFromSuperview];
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Touch forwarding
/////////////////////////////////////////////////////////////////////////////

- (id)_webTouchDelegate {
    if (self.usingLegacyWebView) {
        return (UIWebBrowserView*)[self.legacyWebView _browserView];
    } else {
        return [self.webView _currentContentView];
    }
}

- (BOOL)isWidgetTrackingTouch {
    BOOL isTracking = NO;
    
    UIView *view = [self _webTouchDelegate];
    for (UIGestureRecognizer *recog in view.gestureRecognizers) {
        isTracking = [recog _isRecognized];
        
        if (isTracking &&
            ![recog isKindOfClass:objc_getClass("_UIPreviewInteractionTouchObservingGestureRecognizer")]) {
            
            break;
        }
    }
    
    return isTracking;
}

- (void)forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *view = [self _webTouchDelegate];
    NSSet *set = [(UITouchesEvent*)event _allTouches];
    view.tag = 1337;
    
    for (UIGestureRecognizer *recog in view.gestureRecognizers) {
        [recog _touchesBegan:set withEvent:event];
    }
}

- (void)forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *view = [self _webTouchDelegate];
    NSSet *set = [(UITouchesEvent*)event _allTouches];
    view.tag = 1337;
    
    for (UIGestureRecognizer *recog in view.gestureRecognizers) {
        [recog _touchesMoved:set withEvent:event];
    }
}

- (void)forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *view = [self _webTouchDelegate];
    NSSet *set = [(UITouchesEvent*)event _allTouches];
    view.tag = 1337;
    
    for (UIGestureRecognizer *recog in view.gestureRecognizers) {
        [recog _touchesEnded:set withEvent:event];
    }
}

- (void)forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *view = [self _webTouchDelegate];
    NSSet *set = [(UITouchesEvent*)event _allTouches];
    view.tag = 1337;
    
    for (UIGestureRecognizer *recog in view.gestureRecognizers) {
        [recog _touchesCancelled:set withEvent:event];
    }
}

// **************************************************************************
/////////////////////////////////////////////////////////////////////////////
// WebKit Delegates
/////////////////////////////////////////////////////////////////////////////
// **************************************************************************

/////////////////////////////////////////////////////////////////////////////
#pragma mark WKNavigationDelegate
/////////////////////////////////////////////////////////////////////////////

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    XENlog(@"Failed provisional navigation: %@", error);
}
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {}
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    XENlog(@"Failed navigation: %@", error);
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    // WebView process has terminated... Better reload!
    [webView reload];
}

@end
