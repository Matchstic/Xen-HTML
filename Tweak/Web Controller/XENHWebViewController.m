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

#import "XENHWebViewController.h"
#import "XENHResources.h"
#import "XENHTapGestureRecognizer.h"
#import <WebKit/WebKit.h>
#import "XENHTouchPassThroughView.h"
#import <objc/runtime.h>

@interface UIWebDocumentView : NSObject
-(void)setAutoresizes:(BOOL)arg1;
-(void)setDrawsBackground:(BOOL)arg1;
-(id)webView;
-(void)setTileSize:(CGSize)arg1;
-(void)setBackgroundColor:(UIColor*)arg1;
-(void)setUpdatesScrollView:(BOOL)arg1;
@end

@interface UIWebBrowserView : UIView
- (void)_webTouchEventsRecognized:(id)arg1;
@end

@interface WebPreferences : NSObject
-(void)setAccelerated2dCanvasEnabled:(BOOL)arg1;
-(void)setAcceleratedCompositingEnabled:(BOOL)arg1;
-(void)setAcceleratedDrawingEnabled:(BOOL)arg1;
-(void)_setLayoutInterval:(int)arg1;
-(void)setCacheModel:(int)arg1;
-(void)setJavaScriptCanOpenWindowsAutomatically:(BOOL)arg1;
-(void)setOfflineWebApplicationCacheEnabled:(BOOL)arg1;
@end

@interface WebView : NSObject
-(WebPreferences*)preferences;
-(void)setPreferencesIdentifier:(id)arg1;
-(void)setShouldUpdateWhileOffscreen:(BOOL)arg1;
-(void)_setAllowsMessaging:(BOOL)arg1;
-(void)setCSSAnimationsSuspended:(BOOL)arg1;
@end

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

@interface WKContentView : UIView
- (void)_webTouchEventsRecognized:(id)gestureRecognizer;
- (void)_singleTapCommited:(UITapGestureRecognizer *)gestureRecognizer;
@end

@interface WKWebView (IOS9)
- (id)loadFileURL:(id)arg1 allowingReadAccessToURL:(id)arg2;
- (void)_killWebContentProcessAndResetState;
- (WKContentView*)_currentContentView;
@end

@interface UIWebView (Apple)
- (UIWebDocumentView *)_documentView;
- (UIScrollView *)_scrollView;
- (void)webView:(id)view addMessageToConsole:(NSDictionary *)message;
- (void)webView:(id)view didClearWindowObject:(id)window forFrame:(id)frame;
- (void)_setWebSelectionEnabled:(BOOL)arg1;
- (UIWebBrowserView*)_browserView;
@end

@interface UIGestureRecognizer (Private2)
- (void)_touchesBegan:(id)arg1 withEvent:(id)arg2;
- (void)_touchesCancelled:(id)arg1 withEvent:(id)arg2;
- (void)_touchesEnded:(id)arg1 withEvent:(id)arg2;
- (void)_touchesMoved:(id)arg1 withEvent:(id)arg2;
- (bool)_isActive;
- (bool)_isRecognized;
@end

@interface XENHWebViewController () <WKNavigationDelegate> {
    NSString *_baseString;
    BOOL _usingFallback;
    NSDictionary *_metadata;
    BOOL _isFullscreen;
}

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIWebView *fallbackWebView;

@end

@implementation XENHWebViewController

-(instancetype)initWithBaseString:(NSString *)string {
    self = [super init];
    
    if (self) {
        _baseString = string;
    }
    
    return self;
}

-(void)loadView {
    self.view = [[XENHTouchPassThroughView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_baseString isDirectory:NO]) {
        // No point loading a non-existant view.
        return;
    }
    
    [self unloadView];
    
    // To determine whether to use a fallback web view or not, we check for the presence of
    // "text/cycript" in the base HTML file.
    
    _usingFallback = [XENHResources useFallbackForHTMLFile:_baseString];
    
    // Get widget metadata if available.
    _metadata = [XENHResources widgetMetadataForLocation:self.variant];
    _isFullscreen = [[_metadata objectForKey:@"isFullscreen"] boolValue];
    
    XENlog(@"Loading up %@", _baseString);
    XENlog(@"Metadata %@", _metadata);
    
    if (_usingFallback) {
        // Load using UIWebView
        XENlog(@"Loading using fallback method to support Cycript etc");
        [self.view addSubview:[self loadUIWebView]];
    } else {
        XENlog(@"Loading via WKWebView");
        // Load using WKWebView
        [self.view addSubview:[self loadWKWebView]];
    }
    
    [self runHTMLFileSettingsUpdatesIfNecessary];
}

-(void)unloadView {
    [self unloadUIWebView];
    [self unloadWKWebView];
}

-(void)reloadView {
    [self reloadToNewLocation:_baseString];
}

-(void)setPaused:(BOOL)paused {
    [self setPaused:paused animated:NO];
}

-(void)setPaused:(BOOL)paused animated:(BOOL)animated {
    // Need to make 100% sure we're on the main thread doing this part.
    dispatch_async(dispatch_get_main_queue(), ^(void){
        /*if (paused) {
            // Setup for hiding the UI
        } else {
            // Setup for showing.
            if (_usingFallback) {
                _fallbackWebView.hidden = paused;
                _fallbackWebView.alpha = 0.0;
            } else {
                _webView.hidden = paused;
                _webView.alpha = 0.0;
            }
        }*/
        
        if (_usingFallback) {
            _fallbackWebView.hidden = paused;
            _fallbackWebView.alpha = 1.0;
        } else {
            _webView.hidden = paused;
            _webView.alpha = 1.0;
        }
        
        // Is this even necessary?
        //[self.view setNeedsDisplay];
        
        /*[UIView animateWithDuration:animated ? 0.3 : 0.0 animations:^{
            if (_usingFallback) {
                _fallbackWebView.alpha = paused ? 0.0 : 1.0;
            } else {
                _webView.alpha = paused ? 0.0 : 1.0;
            }
        } completion:^(BOOL finished) {
            if (finished ) {
                if (_usingFallback) {
                    _fallbackWebView.hidden = paused;
                    _fallbackWebView.alpha = 1.0;
                } else {
                    _webView.hidden = paused;
                    _webView.alpha = 1.0;
                }
            
                [self.view setNeedsDisplay];
            }
        }];*/
    });
}

-(void)reloadToNewLocation:(NSString*)newLocation {
    _baseString = newLocation;
    
    // Handle switching between fallback or not.
    
    [self unloadView];
    
    _usingFallback = [XENHResources useFallbackForHTMLFile:_baseString];
    
    // Get widget metadata if available.
    _metadata = [XENHResources widgetMetadataForLocation:self.variant];
    _isFullscreen = [[_metadata objectForKey:@"isFullscreen"] boolValue];
    
    if (_usingFallback) {
        // Load using UIWebView
        XENlog(@"Loading using fallback method to support Cycript etc");
        [self.view addSubview:[self loadUIWebView]];
    } else {
        XENlog(@"Loading via WKWebView");
        // Load using WKWebView
        [self.view addSubview:[self loadWKWebView]];
    }
}

-(UIView*)loadUIWebView {
    CGRect rect = CGRectMake([[_metadata objectForKey:@"x"] floatValue]*SCREEN_WIDTH, [[_metadata objectForKey:@"y"] floatValue]*SCREEN_HEIGHT, _isFullscreen ? SCREEN_WIDTH : [[_metadata objectForKey:@"width"] floatValue], _isFullscreen ? SCREEN_HEIGHT : [[_metadata objectForKey:@"height"] floatValue]);
    
    self.fallbackWebView = [[UIWebView alloc] initWithFrame:rect];
    _fallbackWebView.backgroundColor = [UIColor clearColor];
    _fallbackWebView.opaque = NO;
    _fallbackWebView.tag = 1337;
    
    UIWebDocumentView *document = [_fallbackWebView _documentView];
    WebView *webview = [document webView];
    WebPreferences *preferences = [webview preferences];
    UIScrollView *scroller_;
    
    if ([_fallbackWebView respondsToSelector:@selector(setDataDetectorTypes:)])
        [_fallbackWebView setDataDetectorTypes:0x80000000];
    
    [[_fallbackWebView _documentView] setAutoresizes:YES];
    [_fallbackWebView setBackgroundColor:[UIColor clearColor]];
    if ([[_fallbackWebView _documentView] respondsToSelector:@selector(setDrawsBackground:)])
        [[_fallbackWebView _documentView] setDrawsBackground:NO];
    [[[_fallbackWebView _documentView] webView] setDrawsBackground:NO];
    
    _fallbackWebView.scrollView.userInteractionEnabled = YES;
    _fallbackWebView.userInteractionEnabled = YES;
    _fallbackWebView.scrollView.delegate = nil;
    
    if (![[_metadata objectForKey:@"widgetCanScroll"] boolValue]) {
        _fallbackWebView.scrollView.contentSize = self.view.bounds.size;
        _fallbackWebView.scrollView.scrollEnabled = NO;
    } else {
        _fallbackWebView.scrollView.scrollEnabled = YES;
    }
    
    _fallbackWebView.scrollView.bounces = NO;
    _fallbackWebView.scrollView.multipleTouchEnabled = YES;
    _fallbackWebView.scrollView.scrollsToTop = NO;
    _fallbackWebView.scrollView.showsHorizontalScrollIndicator = NO;
    _fallbackWebView.scrollView.showsVerticalScrollIndicator = NO;
    _fallbackWebView.scrollView.minimumZoomScale = 1.0;
    _fallbackWebView.scrollView.maximumZoomScale = 1.0;
    _fallbackWebView.scalesPageToFit = NO;
    _fallbackWebView.clipsToBounds = NO;
    _fallbackWebView.scrollView.layer.masksToBounds = NO;
    
    // Nitro
    [preferences setAccelerated2dCanvasEnabled:YES];
    [preferences setAcceleratedCompositingEnabled:YES];
    [preferences setAcceleratedDrawingEnabled:YES];
    
    [document setTileSize:CGSizeMake(_isFullscreen ? SCREEN_WIDTH : [[_metadata objectForKey:@"width"] floatValue], _isFullscreen ? SCREEN_HEIGHT : [[_metadata objectForKey:@"height"] floatValue])];
    
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
    [_fallbackWebView _setWebSelectionEnabled:NO]; // Highly experimental, but works
    
    if ([_fallbackWebView respondsToSelector:@selector(_scrollView)])
        scroller_ = [_fallbackWebView _scrollView];
    
    scroller_.contentSize = self.view.bounds.size;
    
    [_fallbackWebView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:_baseString]) {
        NSURL *url = [NSURL fileURLWithPath:_baseString isDirectory:NO];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    
        XENlog(@"Loading request %@", request);
    
        [_fallbackWebView loadRequest:request];
    
        [_fallbackWebView stringByEvaluatingJavaScriptFromString:@"document.body.overflow = 'hidden';"];
        [_fallbackWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.overflow = 'hidden';"];
        [_fallbackWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
        [_fallbackWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserDrag='none';"];
        [_fallbackWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserModify='none';"];
        [_fallbackWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitHighlight='none';"];
        [_fallbackWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTextSizeAdjust='none';"];
        [_fallbackWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    }
    
    return _fallbackWebView;
}

-(UIView*)loadWKWebView {
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
    
    // We also need to inject the settings required by the widget. How to do this, you ask? Click here to find out!
    NSMutableString *settingsInjection = [@"" mutableCopy];
    
    NSDictionary *options = [_metadata objectForKey:@"options"];
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
    
    if (_webView) {
        [_webView removeFromSuperview];
        _webView = nil;
    }
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake([[_metadata objectForKey:@"x"] floatValue]*SCREEN_WIDTH, [[_metadata objectForKey:@"y"] floatValue]*SCREEN_HEIGHT, _isFullscreen ? SCREEN_WIDTH : [[_metadata objectForKey:@"width"] floatValue], _isFullscreen ? SCREEN_HEIGHT : [[_metadata objectForKey:@"height"] floatValue]) configuration:config];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _webView.navigationDelegate = self;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    _webView.scrollView.layer.masksToBounds = NO;
    
    if (![[_metadata objectForKey:@"widgetCanScroll"] boolValue]) {
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
    
    NSURL *url = [NSURL fileURLWithPath:_baseString isDirectory:NO];
    if (url && [[NSFileManager defaultManager] fileExistsAtPath:_baseString]) {
        XENlog(@"Loading from URL: %@", url);
        [_webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
    }
    
    return _webView;
}

-(void)runHTMLFileSettingsUpdatesIfNecessary {
    
}

#pragma mark UIWebViewDelegate

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    XENlog(@"Failed load with error: %@", error);
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    XENlog(@"Did finish load");
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    XENlog(@"Did start load");
}

// Also, we need to be able to inject stuff.
// WebFrameLoadDelegate
- (void)webView:(WebView *)webview didClearWindowObject:(id)window forFrame:(id)frame {
    XENlog(@"didClearWindowObject");
}

#pragma mark WKNavigationDelegate

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
    // Well, crap. WebView process has terminated. :( Better reload!
    [webView reload];
}

#pragma mark View related shizzle

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect rect = CGRectMake([[_metadata objectForKey:@"x"] floatValue]*SCREEN_WIDTH, [[_metadata objectForKey:@"y"] floatValue]*SCREEN_HEIGHT, _isFullscreen ? SCREEN_WIDTH : [[_metadata objectForKey:@"width"] floatValue], _isFullscreen ? SCREEN_HEIGHT : [[_metadata objectForKey:@"height"] floatValue]);
    
    _webView.frame = rect;
    _fallbackWebView.frame = rect;
    
    if (![[_metadata objectForKey:@"widgetCanScroll"] boolValue]) {
        _webView.scrollView.contentSize = _webView.bounds.size;
        _fallbackWebView.scrollView.contentSize = _fallbackWebView.bounds.size;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)rotateToOrientation:(int)orient {
    self.view.bounds = CGRectMake(0, 0, _isFullscreen ? SCREEN_WIDTH : [[_metadata objectForKey:@"width"] floatValue], _isFullscreen ? SCREEN_HEIGHT : [[_metadata objectForKey:@"height"] floatValue]);
    
    CGRect rect = CGRectMake([[_metadata objectForKey:@"x"] floatValue]*SCREEN_WIDTH, [[_metadata objectForKey:@"y"] floatValue]*SCREEN_HEIGHT, _isFullscreen ? SCREEN_WIDTH : [[_metadata objectForKey:@"width"] floatValue], _isFullscreen ? SCREEN_HEIGHT : [[_metadata objectForKey:@"height"] floatValue]);
    
    if (_usingFallback) {
        _fallbackWebView.frame = rect;
        
        if (![[_metadata objectForKey:@"widgetCanScroll"] boolValue]) {
            UIWebDocumentView *document = [_fallbackWebView _documentView];
            
            _fallbackWebView.scrollView.contentSize = rect.size;
            
            [document setTileSize:rect.size];
            
            if ([_fallbackWebView respondsToSelector:@selector(_scrollView)])
                [_fallbackWebView _scrollView].contentSize = rect.size;
        }
    } else {
        _webView.frame = rect;
        
        if (![[_metadata objectForKey:@"widgetCanScroll"] boolValue]) {
            _webView.scrollView.contentSize = _webView.bounds.size;
        }
    }
}

#pragma mark Forward touches from a gesture recognizer

-(void)_recieveWebTouchGesture:(XENHTapGestureRecognizer*)sender {
    if (_usingFallback) {
        [(UIWebBrowserView*)[_fallbackWebView _browserView] _webTouchEventsRecognized:sender];
    } else {
        [[_webView _currentContentView] _webTouchEventsRecognized:sender];
    }
}

-(id)_webTouchDelegate {
    if (_usingFallback) {
        return (UIWebBrowserView*)[_fallbackWebView _browserView];
    } else {
        return [_webView _currentContentView];
    }
}

-(CGPoint)currentWebViewPosition {
    if (_usingFallback) {
        return _fallbackWebView.frame.origin;
    } else {
        return _webView.frame.origin;
    }
}

- (void)_forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *view = [self _webTouchDelegate];
    NSSet *set = [(UITouchesEvent*)event _allTouches];
    view.tag = 1337;
    
    //XENlog(@"TOUCH BEGAN WITH %@", set);
    
    for (UIGestureRecognizer *recog in view.gestureRecognizers) {
        [recog _touchesBegan:set withEvent:event];
    }
    
}

- (void)_forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *view = [self _webTouchDelegate];
    NSSet *set = [(UITouchesEvent*)event _allTouches];
    view.tag = 1337;
    
    //XENlog(@"TOUCH MOVED WITH %@", set);
    
    for (UIGestureRecognizer *recog in view.gestureRecognizers) {
        [recog _touchesMoved:set withEvent:event];
    }
}

- (void)_forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *view = [self _webTouchDelegate];
    NSSet *set = [(UITouchesEvent*)event _allTouches];
    view.tag = 1337;
    
    //XENlog(@"TOUCH END WITH %@", set);
    
    for (UIGestureRecognizer *recog in view.gestureRecognizers) {
        [recog _touchesEnded:set withEvent:event];
    }
}

- (void)_forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *view = [self _webTouchDelegate];
    NSSet *set = [(UITouchesEvent*)event _allTouches];
    view.tag = 1337;
    
    //XENlog(@"TOUCH CANCELLED WITH %@", set);
    
    for (UIGestureRecognizer *recog in view.gestureRecognizers) {
        [recog _touchesCancelled:set withEvent:event];
    }
}

-(BOOL)isTrackingTouch {
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

- (void)addGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
    if (_usingFallback) {
        [_fallbackWebView.scrollView addGestureRecognizer:gestureRecognizer];
    } else {
        [_webView.scrollView addGestureRecognizer:gestureRecognizer];
    }
}

- (void)removeGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer {
    if (_usingFallback) {
        [_fallbackWebView.scrollView removeGestureRecognizer:gestureRecognizer];
    } else {
        [_webView.scrollView removeGestureRecognizer:gestureRecognizer];
    }
}

#pragma mark Unloading

-(void)unloadWKWebView {
    [_webView stopLoading];
    [_webView loadHTMLString:@"" baseURL:[NSURL URLWithString:@""]];

    _webView.hidden = YES; // Stop any residual GPU updates.
    [_webView removeFromSuperview];
    
    /*
     * Interestingly, if this is called too early in the sequence of unloading the lockscreen,
     * when -resignFirstResponder is called on WKContentView, it will SIGSEGV due to it's internal
     * _webView iVar that points here being undefined.
     */
}

-(void)unloadUIWebView {
    [_fallbackWebView loadHTMLString:@"" baseURL:[NSURL URLWithString:@""]];
    [_fallbackWebView stopLoading];
    _fallbackWebView.delegate = nil;
    [_fallbackWebView removeFromSuperview];
    _fallbackWebView = nil;
}

-(void)dealloc {
    [self unloadWKWebView];
    [self unloadUIWebView];
    
    _baseString = nil;
}

@end
