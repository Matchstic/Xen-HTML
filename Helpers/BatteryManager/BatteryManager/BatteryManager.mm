#line 1 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/BatteryManager/BatteryManager/BatteryManager.xm"
#import "XENBMResources.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>


#define $_MSFindSymbolCallable(image, name) make_sym_callable(MSFindSymbol(image, name))

@interface WKBrowsingContextController : NSObject
- (void *)_pageRef; 
@end

@interface WKContentView : NSObject
@property (nonatomic, readonly) WKBrowsingContextController *browsingContextController;
@end

@interface WKWebView (XH_Extended)
@property (nonatomic) BOOL _xh_isPaused;
@property (nonatomic) BOOL _xh_requiresProviderUpdate;
@property (nonatomic, strong) NSMutableArray *_xh_pendingJavaScriptCalls;

- (void)_xh_postResume;

- (BOOL)_webProcessIsResponsive; 
@end

@interface XENHWidgetController : UIViewController


@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIWebView *legacyWebView;

@property (nonatomic, readwrite) BOOL isPaused;

- (void)_setMainThreadPaused:(BOOL)paused;

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView;

@end

@interface XENHResources : NSObject
+ (BOOL)displayState; 
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




static void (*WebPageProxy$activityStateDidChange)(void *_this, unsigned int flags, bool wantsSynchronousReply, ActivityStateChangeDispatchMode dispatchMode);

static void (*WebPageProxy$applicationDidEnterBackground)(void *_this);

static void (*WebPageProxy$applicationWillEnterForeground)(void *_this);

static void (*WebPageProxy$applicationWillResignActive)(void *_this);

static void (*WebPageProxy$applicationDidBecomeActive)(void *_this);


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class XENHWidgetController; @class UIApp; @class WKWebView; 


#line 85 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/BatteryManager/BatteryManager/BatteryManager.xm"
static void (*_logos_orig$SpringBoard$XENHWidgetController$setPaused$animated$)(_LOGOS_SELF_TYPE_NORMAL XENHWidgetController* _LOGOS_SELF_CONST, SEL, BOOL, BOOL); static void _logos_method$SpringBoard$XENHWidgetController$setPaused$animated$(_LOGOS_SELF_TYPE_NORMAL XENHWidgetController* _LOGOS_SELF_CONST, SEL, BOOL, BOOL); static void (*_logos_orig$SpringBoard$XENHWidgetController$setPausedAfterTerminationRecovery$)(_LOGOS_SELF_TYPE_NORMAL XENHWidgetController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$XENHWidgetController$setPausedAfterTerminationRecovery$(_LOGOS_SELF_TYPE_NORMAL XENHWidgetController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$SpringBoard$XENHWidgetController$_setMainThreadPaused$(_LOGOS_SELF_TYPE_NORMAL XENHWidgetController* _LOGOS_SELF_CONST, SEL, BOOL); static WKWebView* (*_logos_orig$SpringBoard$WKWebView$initWithFrame$configuration$)(_LOGOS_SELF_TYPE_INIT WKWebView*, SEL, CGRect, id) _LOGOS_RETURN_RETAINED; static WKWebView* _logos_method$SpringBoard$WKWebView$initWithFrame$configuration$(_LOGOS_SELF_TYPE_INIT WKWebView*, SEL, CGRect, id) _LOGOS_RETURN_RETAINED; static BOOL (*_logos_orig$SpringBoard$WKWebView$_isBackground)(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$WKWebView$_isBackground(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$SpringBoard$WKWebView$evaluateJavaScript$completionHandler$)(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST, SEL, NSString *, void (^)(id, NSError *error)); static void _logos_method$SpringBoard$WKWebView$evaluateJavaScript$completionHandler$(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST, SEL, NSString *, void (^)(id, NSError *error)); static void _logos_method$SpringBoard$WKWebView$_xh_postResume(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$SpringBoard$UIApp$isSuspendedUnderLock)(_LOGOS_SELF_TYPE_NORMAL UIApp* _LOGOS_SELF_CONST, SEL); static BOOL _logos_method$SpringBoard$UIApp$isSuspendedUnderLock(_LOGOS_SELF_TYPE_NORMAL UIApp* _LOGOS_SELF_CONST, SEL); 

static inline bool allowJSExecutionQueue() {
    return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 10, 0, 0 }];
}

static inline void doSetWKWebViewActivityState(WKWebView *webView, bool isPaused, bool wasPausedPreviously) {
    
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
    
    
    if (!isPaused && wasPausedPreviously) {
        
        XENlog(@"Faking entering foreground app state");
        
        
        WebPageProxy$applicationWillEnterForeground(page); 
        
        
        WebPageProxy$activityStateDidChange(page, WebCoreActivityState::Flag::IsVisible, true, ActivityStateChangeDispatchMode::Immediate);
        
        
        [webView setNeedsDisplay];
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            [webView evaluateJavaScript:@"if (window.onresume !== undefined) window.onresume();" completionHandler:^(id, NSError*) {}];
        });
    } else if (isPaused && !wasPausedPreviously) {
        
        
        
        if (webView._xh_isPaused != isPaused) {
            XENlog(@"Not setting background state, widget pause state changed");
            return;
        }
            
        XENlog(@"Faking entering background app state");
        
        WebPageProxy$applicationDidEnterBackground(page); 
        
            
        WebPageProxy$activityStateDidChange(page, WebCoreActivityState::Flag::IsVisible, false, ActivityStateChangeDispatchMode::Immediate);
    }
    
    XENlog(@"Did set webview running state to %@, for URL: %@", isPaused ? @"paused" : @"active", webView.URL);
}

static inline void setWKWebViewActivityState(WKWebView *webView, bool isPaused) {
    if (!webView)
        return;
    
    if (webView._xh_isPaused == isPaused) {
        
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




static void _logos_method$SpringBoard$XENHWidgetController$setPaused$animated$(_LOGOS_SELF_TYPE_NORMAL XENHWidgetController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL paused, BOOL animated) {
    
    BOOL needsStateChange = self.webView && self.isPaused != paused;
    
    _logos_orig$SpringBoard$XENHWidgetController$setPaused$animated$(self, _cmd, paused, animated);
    
    if (needsStateChange) {
        
        
        if ([NSThread isMainThread]) {
            [self _setMainThreadPaused:paused];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^(void){
                [self _setMainThreadPaused:paused];
            });
        }
        
        
        setWKWebViewActivityState(self.webView, paused);
    }
}

static void _logos_method$SpringBoard$XENHWidgetController$setPausedAfterTerminationRecovery$(_LOGOS_SELF_TYPE_NORMAL XENHWidgetController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL paused) {
    _logos_orig$SpringBoard$XENHWidgetController$setPausedAfterTerminationRecovery$(self, _cmd, paused);
    
    
    
    
    if ([NSThread isMainThread]) {
        [self _setMainThreadPaused:paused];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^(void){
            [self _setMainThreadPaused:paused];
        });
    }
    
    
    setWKWebViewActivityState(self.webView, paused);
}


static void _logos_method$SpringBoard$XENHWidgetController$_setMainThreadPaused$(_LOGOS_SELF_TYPE_NORMAL XENHWidgetController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL paused) {
    
    self.legacyWebView.hidden = paused ? YES : NO;
    self.webView.hidden = paused ? YES : NO;
}






__attribute__((used)) static BOOL _logos_method$SpringBoard$WKWebView$_xh_isPaused(WKWebView * __unused self, SEL __unused _cmd) { NSValue * value = objc_getAssociatedObject(self, (void *)_logos_method$SpringBoard$WKWebView$_xh_isPaused); BOOL rawValue; [value getValue:&rawValue]; return rawValue; }; __attribute__((used)) static void _logos_method$SpringBoard$WKWebView$set_xh_isPaused(WKWebView * __unused self, SEL __unused _cmd, BOOL rawValue) { NSValue * value = [NSValue valueWithBytes:&rawValue objCType:@encode(BOOL)]; objc_setAssociatedObject(self, (void *)_logos_method$SpringBoard$WKWebView$_xh_isPaused, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
__attribute__((used)) static BOOL _logos_method$SpringBoard$WKWebView$_xh_requiresProviderUpdate(WKWebView * __unused self, SEL __unused _cmd) { NSValue * value = objc_getAssociatedObject(self, (void *)_logos_method$SpringBoard$WKWebView$_xh_requiresProviderUpdate); BOOL rawValue; [value getValue:&rawValue]; return rawValue; }; __attribute__((used)) static void _logos_method$SpringBoard$WKWebView$set_xh_requiresProviderUpdate(WKWebView * __unused self, SEL __unused _cmd, BOOL rawValue) { NSValue * value = [NSValue valueWithBytes:&rawValue objCType:@encode(BOOL)]; objc_setAssociatedObject(self, (void *)_logos_method$SpringBoard$WKWebView$_xh_requiresProviderUpdate, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }


__attribute__((used)) static NSMutableArray * _logos_method$SpringBoard$WKWebView$_xh_pendingJavaScriptCalls(WKWebView * __unused self, SEL __unused _cmd) { return (NSMutableArray *)objc_getAssociatedObject(self, (void *)_logos_method$SpringBoard$WKWebView$_xh_pendingJavaScriptCalls); }; __attribute__((used)) static void _logos_method$SpringBoard$WKWebView$set_xh_pendingJavaScriptCalls(WKWebView * __unused self, SEL __unused _cmd, NSMutableArray * rawValue) { objc_setAssociatedObject(self, (void *)_logos_method$SpringBoard$WKWebView$_xh_pendingJavaScriptCalls, rawValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }

static WKWebView* _logos_method$SpringBoard$WKWebView$initWithFrame$configuration$(_LOGOS_SELF_TYPE_INIT WKWebView* __unused self, SEL __unused _cmd, CGRect arg1, id arg2) _LOGOS_RETURN_RETAINED {
    WKWebView *orig = _logos_orig$SpringBoard$WKWebView$initWithFrame$configuration$(self, _cmd, arg1, arg2);
    
    if (orig) {
        
        orig._xh_isPaused = NO;
    }
    
    return orig;
}

static BOOL _logos_method$SpringBoard$WKWebView$_isBackground(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (self._xh_isPaused) {
        return YES;
    } else {
        return _logos_orig$SpringBoard$WKWebView$_isBackground(self, _cmd);
    }
}

static void _logos_method$SpringBoard$WKWebView$evaluateJavaScript$completionHandler$(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * javaScriptString, void (^completionHandler)(id, NSError *error)) {
    if (allowJSExecutionQueue() && self._xh_isPaused) {
        
        
        
        
        
        
        
        BOOL isProviderUpdate = [javaScriptString hasPrefix:@"api._middleware.onInternalNativeMessage"];
        if (!isProviderUpdate) {
            
            
            if (!self._xh_pendingJavaScriptCalls) {
                self._xh_pendingJavaScriptCalls = [NSMutableArray array];
            }
            
            
            if ([javaScriptString hasPrefix:@"mainUpdate"]) {
                javaScriptString = [NSString stringWithFormat:@"if (window.mainUpdate !== undefined) { %@ } ", javaScriptString];
            }
            
            if (javaScriptString) {
                if (![javaScriptString hasSuffix:@";"])
                    javaScriptString = [javaScriptString stringByAppendingString:@";"];
                    
                [self._xh_pendingJavaScriptCalls addObject:javaScriptString];
            }
        } else {
            
            self._xh_requiresProviderUpdate = [javaScriptString hasPrefix:@"api._middleware.onInternalNativeMessage"];
        }
        
        if (completionHandler)
            completionHandler(nil, nil);
    } else {
        _logos_orig$SpringBoard$WKWebView$evaluateJavaScript$completionHandler$(self, _cmd, javaScriptString, completionHandler);
    }
}


static void _logos_method$SpringBoard$WKWebView$_xh_postResume(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (!allowJSExecutionQueue()) return;
    
    
    if (self._xh_pendingJavaScriptCalls) {
        NSMutableString *combinedExecution = [@"" mutableCopy];
        
        for (NSString *call in self._xh_pendingJavaScriptCalls) {
            [combinedExecution appendString:call];
        }
        
        
        [self evaluateJavaScript:combinedExecution completionHandler:^(id result, NSError *error) {}];
        
        
        [self._xh_pendingJavaScriptCalls removeAllObjects];
    }

    
    if (self._xh_requiresProviderUpdate && objc_getClass("XENDWidgetManager")) {
        self._xh_requiresProviderUpdate = NO;
        [[objc_getClass("XENDWidgetManager") sharedInstance] notifyWidgetUnpaused:self];
    }
}





static BOOL _logos_method$SpringBoard$UIApp$isSuspendedUnderLock(_LOGOS_SELF_TYPE_NORMAL UIApp* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    return [objc_getClass("XENHResources") displayState] == NO ? NO : _logos_orig$SpringBoard$UIApp$isSuspendedUnderLock(self, _cmd);
}





static inline bool _xenhtml_bm_validate(void *pointer, NSString *name) {
    XENlog(@"DEBUG :: %@ is%@ a valid pointer", name, pointer == NULL ? @" NOT" : @"");
    return pointer != NULL;
}

static __attribute__((constructor)) void _logosLocalCtor_bc09d24d(int __unused argc, char __unused **argv, char __unused **envp) {
    {}
    
    BOOL sb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"];
    
    if (sb) {
        
        WebPageProxy$activityStateDidChange = (void (*)(void*, unsigned int, bool, ActivityStateChangeDispatchMode)) $_MSFindSymbolCallable(NULL, "__ZN6WebKit12WebPageProxy22activityStateDidChangeEjbNS0_31ActivityStateChangeDispatchModeE");
        
        if (WebPageProxy$activityStateDidChange == NULL) {
            WebPageProxy$activityStateDidChange = (void (*)(void*, unsigned int, bool, ActivityStateChangeDispatchMode)) $_MSFindSymbolCallable(NULL, "__ZN6WebKit12WebPageProxy22activityStateDidChangeEN3WTF9OptionSetIN7WebCore13ActivityState4FlagEEEbNS0_31ActivityStateChangeDispatchModeE");
        }
        
        
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
        {Class _logos_class$SpringBoard$XENHWidgetController = objc_getClass("XENHWidgetController"); MSHookMessageEx(_logos_class$SpringBoard$XENHWidgetController, @selector(setPaused:animated:), (IMP)&_logos_method$SpringBoard$XENHWidgetController$setPaused$animated$, (IMP*)&_logos_orig$SpringBoard$XENHWidgetController$setPaused$animated$);MSHookMessageEx(_logos_class$SpringBoard$XENHWidgetController, @selector(setPausedAfterTerminationRecovery:), (IMP)&_logos_method$SpringBoard$XENHWidgetController$setPausedAfterTerminationRecovery$, (IMP*)&_logos_orig$SpringBoard$XENHWidgetController$setPausedAfterTerminationRecovery$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(BOOL), strlen(@encode(BOOL))); i += strlen(@encode(BOOL)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$XENHWidgetController, @selector(_setMainThreadPaused:), (IMP)&_logos_method$SpringBoard$XENHWidgetController$_setMainThreadPaused$, _typeEncoding); }Class _logos_class$SpringBoard$WKWebView = objc_getClass("WKWebView"); MSHookMessageEx(_logos_class$SpringBoard$WKWebView, @selector(initWithFrame:configuration:), (IMP)&_logos_method$SpringBoard$WKWebView$initWithFrame$configuration$, (IMP*)&_logos_orig$SpringBoard$WKWebView$initWithFrame$configuration$);MSHookMessageEx(_logos_class$SpringBoard$WKWebView, @selector(_isBackground), (IMP)&_logos_method$SpringBoard$WKWebView$_isBackground, (IMP*)&_logos_orig$SpringBoard$WKWebView$_isBackground);MSHookMessageEx(_logos_class$SpringBoard$WKWebView, @selector(evaluateJavaScript:completionHandler:), (IMP)&_logos_method$SpringBoard$WKWebView$evaluateJavaScript$completionHandler$, (IMP*)&_logos_orig$SpringBoard$WKWebView$evaluateJavaScript$completionHandler$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$SpringBoard$WKWebView, @selector(_xh_postResume), (IMP)&_logos_method$SpringBoard$WKWebView$_xh_postResume, _typeEncoding); }{ char _typeEncoding[1024]; sprintf(_typeEncoding, "%s@:", @encode(BOOL)); class_addMethod(_logos_class$SpringBoard$WKWebView, @selector(_xh_isPaused), (IMP)&_logos_method$SpringBoard$WKWebView$_xh_isPaused, _typeEncoding); sprintf(_typeEncoding, "v@:%s", @encode(BOOL)); class_addMethod(_logos_class$SpringBoard$WKWebView, @selector(set_xh_isPaused:), (IMP)&_logos_method$SpringBoard$WKWebView$set_xh_isPaused, _typeEncoding); } { char _typeEncoding[1024]; sprintf(_typeEncoding, "%s@:", @encode(BOOL)); class_addMethod(_logos_class$SpringBoard$WKWebView, @selector(_xh_requiresProviderUpdate), (IMP)&_logos_method$SpringBoard$WKWebView$_xh_requiresProviderUpdate, _typeEncoding); sprintf(_typeEncoding, "v@:%s", @encode(BOOL)); class_addMethod(_logos_class$SpringBoard$WKWebView, @selector(set_xh_requiresProviderUpdate:), (IMP)&_logos_method$SpringBoard$WKWebView$set_xh_requiresProviderUpdate, _typeEncoding); } { char _typeEncoding[1024]; sprintf(_typeEncoding, "%s@:", @encode(NSMutableArray *)); class_addMethod(_logos_class$SpringBoard$WKWebView, @selector(_xh_pendingJavaScriptCalls), (IMP)&_logos_method$SpringBoard$WKWebView$_xh_pendingJavaScriptCalls, _typeEncoding); sprintf(_typeEncoding, "v@:%s", @encode(NSMutableArray *)); class_addMethod(_logos_class$SpringBoard$WKWebView, @selector(set_xh_pendingJavaScriptCalls:), (IMP)&_logos_method$SpringBoard$WKWebView$set_xh_pendingJavaScriptCalls, _typeEncoding); } Class _logos_class$SpringBoard$UIApp = objc_getClass("UIApp"); MSHookMessageEx(_logos_class$SpringBoard$UIApp, @selector(isSuspendedUnderLock), (IMP)&_logos_method$SpringBoard$UIApp$isSuspendedUnderLock, (IMP*)&_logos_orig$SpringBoard$UIApp$isSuspendedUnderLock);}
    }
}
