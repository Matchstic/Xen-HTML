#import "XENBMResources.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

// This is used for arm64e support w/ PAC and MSFindSymbol
#define $_MSFindSymbolCallable(image, name) make_sym_callable(MSFindSymbol(image, name))

@interface WKBrowsingContextController : NSObject
- (void *)_pageRef; // WKPageRef
@end

@interface WKContentView : NSObject
@property (nonatomic, readonly) WKBrowsingContextController *browsingContextController;
@end

@interface WKWebView (XH_Extended)
@property (nonatomic) BOOL _xh_isPaused;
@property (nonatomic) BOOL _xh_requiresProviderUpdate;
@property (nonatomic, strong) NSMutableArray *_xh_pendingJavaScriptCalls;

- (void)_xh_postResume;

- (BOOL)_webProcessIsResponsive; // private API, iOS 10+
@end

@interface XENHWidgetController : UIViewController

// Internal webviews
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIWebView *legacyWebView;

@property (nonatomic, readwrite) BOOL isPaused;

- (void)_setMainThreadPaused:(BOOL)paused;

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView;

@end

@interface XENHResources : NSObject
+ (BOOL)displayState; // YES == on, NO == off
@end

@interface XENDWidgetManager : NSObject
+ (void)initialiseLibrary;
+ (instancetype)sharedInstance;
- (void)notifyWidgetUnpaused:(WKWebView*)webView;
@end

@interface XIWidgetManager : NSObject
+ (instancetype)sharedInstance;
- (void)_updateWidgetWithCachedInformation:(id)widget;
@end

// For setting WebPageProxy activity state
enum class ActivityStateChangeDispatchMode { Deferrable, Immediate };
struct WebCoreActivityState {
    enum Flag {
        WindowIsActive = 1 << 0,
        IsFocused = 1 << 1,
        IsVisible = 1 << 2,
        IsVisibleOrOccluded = 1 << 3,
        IsInWindow = 1 << 4,
        IsVisuallyIdle = 1 << 5,
        IsAudible = 1 << 6,
        IsLoading = 1 << 7,
        IsCapturingMedia = 1 << 8,
    };
};

// Hooks

// void WebPageProxy::activityStateDidChange(unsigned int flags, bool wantsSynchronousReply, ActivityStateChangeDispatchMode dispatchMode)
static void (*WebPageProxy$activityStateDidChange)(void *_this, unsigned int flags, bool wantsSynchronousReply, ActivityStateChangeDispatchMode dispatchMode);
// void WebPageProxy::applicationDidEnterBackground()
static void (*WebPageProxy$applicationDidEnterBackground)(void *_this);
// void WebPageProxy::applicationWillEnterForeground()
static void (*WebPageProxy$applicationWillEnterForeground)(void *_this);
// void WebPageProxy::applicationWillResignActive()
static void (*WebPageProxy$applicationWillResignActive)(void *_this);
// void WebPageProxy::applicationDidBecomeActive()
static void (*WebPageProxy$applicationDidBecomeActive)(void *_this);

%group SpringBoard

static inline bool allowJSExecutionQueue() {
    return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 10, 0, 0 }];
}

static inline void doSetWKWebViewActivityState(WKWebView *webView, bool isPaused, bool wasPausedPreviously) {
    // Update activity state - this relies on the result of [WKWebView _isBackground] in PageClientImpl::isViewVisible()
    WKContentView *contentView = MSHookIvar<WKContentView*>(webView, "_contentView");
    if (!contentView.browsingContextController) {
        XENlog(@"Missing contentView.browsingContextController");
        return;
    }
    
    void *page = MSHookIvar<void*>(contentView.browsingContextController, "_page");
    if (!page) {
        if (!contentView.browsingContextController) XENlog(@"Missing _page");
        return;
    }
    
    // Application state faking - this ensures layers etc in the backing process get frozen
    if (!isPaused && wasPausedPreviously) {
        // Will enter foreground
        XENlog(@"Faking entering foreground app state");
        
        // WebPageProxy$applicationDidBecomeActive(page); // Notifies document listeners of being active, causes some odd visuals
        WebPageProxy$applicationWillEnterForeground(page); // Un-freezes layers
        
        // Notify that the widget is visible for JS execution
        WebPageProxy$activityStateDidChange(page, WebCoreActivityState::Flag::IsVisible, true, ActivityStateChangeDispatchMode::Immediate);
        
        // Request UI update
        [webView setNeedsDisplay];
        
        // Notify widget of restart, but put it to the back of the main queue
        // to ensure that whatever called into here isn't delayed too much
        dispatch_async(dispatch_get_main_queue(), ^(){
            [webView evaluateJavaScript:@"if (window.onresume !== undefined) window.onresume();" completionHandler:^(id, NSError*) {}];
        });
    } else if (isPaused && !wasPausedPreviously) {
        // Did enter background
        
        // Make sure the paused state hasn't changed
        if (webView._xh_isPaused != isPaused) {
            XENlog(@"Not setting background state, widget pause state changed");
            return;
        }
            
        XENlog(@"Faking entering background app state");
        
        WebPageProxy$applicationDidEnterBackground(page); // Freezes layer
        // WebPageProxy$applicationWillResignActive(page); // Notifies document listeners of no longer being active, causes some odd visuals
            
        WebPageProxy$activityStateDidChange(page, WebCoreActivityState::Flag::IsVisible, false, ActivityStateChangeDispatchMode::Immediate);
    }
    
    XENlog(@"Did set webview running state to %@, for URL: %@", isPaused ? @"paused" : @"active", webView.URL);
}

static inline void setWKWebViewActivityState(WKWebView *webView, bool isPaused) {
    if (!webView)
        return;
    
    if (webView._xh_isPaused == isPaused) {
        // Already in the requested state
        return;
    }
    
    BOOL wasPausedPreviously = webView._xh_isPaused;
    webView._xh_isPaused = isPaused;
    
    try {
        doSetWKWebViewActivityState(webView, isPaused, wasPausedPreviously);
        
        if (!isPaused) {
            [webView _xh_postResume];
        }
    } catch (...) {
        XENlog(@"Woah what the heck?");
    }
}


%hook XENHWidgetController

-(void)setPaused:(BOOL)paused animated:(BOOL)animated {
    // Pause as needed, and only if needed
    BOOL needsStateChange = self.webView && self.isPaused != paused;
    
    %orig;
    
    if (needsStateChange) {
        
        // Need to make 100% sure we're on the main thread doing this part.
        if ([NSThread isMainThread]) {
            [self _setMainThreadPaused:paused];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^(void){
                [self _setMainThreadPaused:paused];
            });
        }
        
        // Update activity state
        setWKWebViewActivityState(self.webView, paused);
    }
}

- (void)setPausedAfterTerminationRecovery:(BOOL)paused {
    %orig;
    
    // Update activity states due to the underlying webview getting terminated
    
    // Need to make 100% sure we're on the main thread doing this part.
    if ([NSThread isMainThread]) {
        [self _setMainThreadPaused:paused];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^(void){
            [self _setMainThreadPaused:paused];
        });
    }
    
    // Update activity state
    setWKWebViewActivityState(self.webView, paused);
}

%new
- (void)_setMainThreadPaused:(BOOL)paused {
    // Remove the views from being updated
    self.legacyWebView.hidden = paused ? YES : NO;
    self.webView.hidden = paused ? YES : NO;
}

%end

%hook WKWebView

// Override the result of _isBackground as needed
%property (nonatomic) BOOL _xh_isPaused;
%property (nonatomic) BOOL _xh_requiresProviderUpdate;

// Queue of evaluateJavaScript calls when paused
%property (nonatomic, strong) NSMutableArray *_xh_pendingJavaScriptCalls;

- (id)initWithFrame:(CGRect)arg1 configuration:(id)arg2 {
    WKWebView *orig = %orig;
    
    if (orig) {
        // Reset states
        orig._xh_isPaused = NO;
    }
    
    return orig;
}

- (BOOL)_isBackground {
    if (self._xh_isPaused) {
        return YES;
    } else {
        return %orig;
    }
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *error))completionHandler {
    if (allowJSExecutionQueue() && self._xh_isPaused) {
        
        // If the JavaScript to be executed is from libwidgetinfo, drop it.
        // Otherwise, we can end up in a situation where a large amount of updates are pushed to the widget,
        // potentially leading an unstable state in SpringBoard.
        // This means that when the widget is unpaused, both may need to be notified to "re-seed" the widget
        // with the latest data
        
        BOOL isProviderUpdate = [javaScriptString hasPrefix:@"api._middleware.onInternalNativeMessage"];
        if (!isProviderUpdate) {
            
            // Push to update queue for all other use cases
            if (!self._xh_pendingJavaScriptCalls) {
                self._xh_pendingJavaScriptCalls = [NSMutableArray array];
            }
            
            // Bugfix for XenInfo -- legacy
            if ([javaScriptString hasPrefix:@"mainUpdate"]) {
                javaScriptString = [NSString stringWithFormat:@"if (window.mainUpdate !== undefined) { %@ } ", javaScriptString];
            }
            
            if (javaScriptString) {
                if (![javaScriptString hasSuffix:@";"])
                    javaScriptString = [javaScriptString stringByAppendingString:@";"];
                    
                [self._xh_pendingJavaScriptCalls addObject:javaScriptString];
            }
        } else {
            // Set provider flags
            self._xh_requiresProviderUpdate = [javaScriptString hasPrefix:@"api._middleware.onInternalNativeMessage"];
        }
        
        if (completionHandler)
            completionHandler(nil, nil);
    } else {
        %orig;
    }
}

%new
- (void)_xh_postResume {
    if (!allowJSExecutionQueue()) return;
    
    // Flush any pending JS calls
    if (self._xh_pendingJavaScriptCalls) {
        NSMutableString *combinedExecution = [@"" mutableCopy];
        
        for (NSString *call in self._xh_pendingJavaScriptCalls) {
            [combinedExecution appendString:call];
        }
        
        // Do a combined execution
        dispatch_async(dispatch_get_main_queue(), ^{
            [self evaluateJavaScript:combinedExecution completionHandler:^(id result, NSError *error) {}];
        });
        
        // Then clear state
        [self._xh_pendingJavaScriptCalls removeAllObjects];
    }

    // Finally, reach out to data provider to flush current data
    if (self._xh_requiresProviderUpdate && objc_getClass("XENDWidgetManager")) {
        self._xh_requiresProviderUpdate = NO;
        [[objc_getClass("XENDWidgetManager") sharedInstance] notifyWidgetUnpaused:self];
    }
}

%end

%hook UIApp

- (BOOL)isSuspendedUnderLock {
    return [objc_getClass("XENHResources") displayState] == NO ? NO : %orig;
}

%end

%end

static inline bool _xenhtml_bm_validate(void *pointer, NSString *name) {
    XENlog(@"DEBUG :: %@ is%@ a valid pointer", name, pointer == NULL ? @" NOT" : @"");
    return pointer != NULL;
}

%ctor {
    %init;
    
    BOOL sb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"];
    
    if (sb) {
        
        WebPageProxy$activityStateDidChange = (void (*)(void*, unsigned int, bool, ActivityStateChangeDispatchMode)) $_MSFindSymbolCallable(NULL, "__ZN6WebKit12WebPageProxy22activityStateDidChangeEjbNS0_31ActivityStateChangeDispatchModeE");
        
        if (WebPageProxy$activityStateDidChange == NULL) {
            WebPageProxy$activityStateDidChange = (void (*)(void*, unsigned int, bool, ActivityStateChangeDispatchMode)) $_MSFindSymbolCallable(NULL, "__ZN6WebKit12WebPageProxy22activityStateDidChangeEN3WTF9OptionSetIN7WebCore13ActivityState4FlagEEEbNS0_31ActivityStateChangeDispatchModeE");
        }
        
        // App state stuff
        WebPageProxy$applicationDidEnterBackground = (void (*)(void *_this))$_MSFindSymbolCallable(NULL, "__ZN6WebKit12WebPageProxy29applicationDidEnterBackgroundEv");
        WebPageProxy$applicationWillEnterForeground = (void (*)(void *_this))$_MSFindSymbolCallable(NULL, "__ZN6WebKit12WebPageProxy30applicationWillEnterForegroundEv");
        WebPageProxy$applicationWillResignActive = (void (*)(void *_this))$_MSFindSymbolCallable(NULL, "__ZN6WebKit12WebPageProxy27applicationWillResignActiveEv");
        WebPageProxy$applicationDidBecomeActive = (void (*)(void *_this))$_MSFindSymbolCallable(NULL, "__ZN6WebKit12WebPageProxy26applicationDidBecomeActiveEv");
        
        if (!_xenhtml_bm_validate((void*)WebPageProxy$activityStateDidChange, @"WebPageProxy::activityStateDidChange"))
            return;
        if (!_xenhtml_bm_validate((void*)WebPageProxy$applicationDidEnterBackground, @"WebPageProxy::applicationDidEnterBackground"))
            return;
        if (!_xenhtml_bm_validate((void*)WebPageProxy$applicationWillEnterForeground, @"WebPageProxy::applicationWillEnterForeground"))
            return;
        if (!_xenhtml_bm_validate((void*)WebPageProxy$applicationWillResignActive, @"WebPageProxy::applicationWillResignActive"))
            return;
        if (!_xenhtml_bm_validate((void*)WebPageProxy$applicationDidBecomeActive, @"WebPageProxy::applicationDidBecomeActive"))
            return;

        XENlog(@"DEBUG :: initialising hooks");
        %init(SpringBoard);
    }
}
