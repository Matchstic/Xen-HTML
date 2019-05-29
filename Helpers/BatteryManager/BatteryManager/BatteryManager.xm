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
@property (nonatomic) BOOL _xh_hasFinishedMainFrameLoad;
@end

@interface XENHWidgetController : UIViewController

// Internal webviews
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIWebView *legacyWebView;

@property (nonatomic, readwrite) BOOL isPaused;

@end

@interface XENHResources : NSObject
+ (BOOL)displayState; // YES == on, NO == off
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

%group SpringBoard


static inline void setWKWebViewActivityState(WKWebView *webView, bool isPaused) {
    if (!webView)
        return;
    
    if (!webView._xh_hasFinishedMainFrameLoad) {
        XENlog(@"Ignoring activity state change because this widget has not yet finished loading the main frame");
        return;
    }
    
    if (webView._xh_isPaused == isPaused) {
        XENlog(@"Ignoring activity state change because this widget is already %@", isPaused ? @"paused" : @"active");
        return;
    }
    
    webView._xh_isPaused = isPaused;
    
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
    
    WebPageProxy$activityStateDidChange(page, WebCoreActivityState::Flag::IsVisible, false, ActivityStateChangeDispatchMode::Immediate);
        
    XENlog(@"Did set webview running state to %@, for URL: %@", isPaused ? @"paused" : @"active", webView.URL);
}


%hook XENHWidgetController

-(void)setPaused:(BOOL)paused animated:(BOOL)animated {
    // Pause as needed, and only if needed
    BOOL needsStateChange = self.webView && self.isPaused != paused;
    
    %orig;
    
    if (needsStateChange) {
        setWKWebViewActivityState(self.webView, paused);
    }
}

%end

%hook WKWebView

// Override the result of _isBackground as needed
%property (nonatomic) BOOL _xh_isPaused;
%property (nonatomic) BOOL _xh_hasFinishedMainFrameLoad;

- (BOOL)_isBackground {
    if (self._xh_isPaused) {
        return YES;
    } else {
        return %orig;
    }
}

- (void)_didCommitLoadForMainFrame {
    %orig;
    
    // Reset states
    self._xh_isPaused = NO;
    self._xh_hasFinishedMainFrameLoad = NO;
}

- (void)_didFinishLoadForMainFrame {
    %orig;
    
    self._xh_hasFinishedMainFrameLoad = YES;
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
        
        if (!_xenhtml_bm_validate((void*)WebPageProxy$activityStateDidChange, @"WebPageProxy::activityStateDidChange"))
            return;

        %init(SpringBoard);
    }
}
