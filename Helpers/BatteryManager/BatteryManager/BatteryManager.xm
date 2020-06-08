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

/**
 * The goal with this helper is to apply battery management to widgets, so that they do not cause
 * severe drainage on the user's device.
 *
 * It follows the principle of 'management strategies'; users can choose how invasive the management
 * strategy should be, with each providing differing degrees of battery usage improvements.
 *
 * The following strategies are available:
 * - Low :: just pauses GPU updates on the widget
 * - Moderate :: same as above, but also notifies WebKit of application lifecycle events per widget
 * - High :: completely unloads the widget and removes it from the view hierarchy
 */

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
@property (nonatomic) int _xh_currentPauseStrategy;
@property (nonatomic, strong) NSMutableArray *_xh_pendingJavaScriptCalls;

- (void)_xh_postResume;

- (BOOL)_webProcessIsResponsive; // private API, iOS 10+
@end

@interface XENHWidgetController : UIViewController

// Internal webviews
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIWebView *legacyWebView;
@property (nonatomic, strong) UIImageView *snapshotWebView;
@property (nonatomic, strong) UIView *editingBackground;
@property (nonatomic, strong) NSString *widgetIndexFile;
@property (nonatomic) BOOL pendingHighStrategyLoad;
@property (nonatomic, readwrite) BOOL pendingWidgetJITLoad;
@property (nonatomic, readwrite) BOOL isPaused;

- (void)_setInternalHidden:(BOOL)paused;
- (void)_setInternalPaused:(BOOL)paused;

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView;
- (void)snapshotWidget:(void (^)(UIImage *))completion;
- (void)_unloadWebView;
- (void)_loadWebView;
- (CGRect)widgetFrame;

@end

@interface XENHResources : NSObject
+ (BOOL)displayState; // YES == on, NO == off
+ (int)currentPauseStrategy;
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

typedef enum : NSUInteger {
    kLow = 0,
    kModerate,
    kHigh,
} XENDPauseStrategy;

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

static BOOL isModerateStrategyPossible = YES;

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
        if (isModerateStrategyPossible) {
            // Do not attempt this state change if symbols are not found
            doSetWKWebViewActivityState(webView, isPaused, wasPausedPreviously);
        } else {
            XENlog(@"DEBUG :: Moderate strategy requested but is not available");
        }
        
        if (!isPaused) {
            [webView _xh_postResume];
        }
    } catch (...) {
        XENlog(@"Woah what the heck?");
    }
}

%hook XENHWidgetController

%property (nonatomic, strong) UIImageView *snapshotWebView;
%property (nonatomic) BOOL pendingHighStrategyLoad;

-(void)setPaused:(BOOL)paused animated:(BOOL)animated {
    // Pause as needed, and only if needed
    BOOL needsStateChange = self.webView && self.isPaused != paused;
    
    %orig;
    
    if (needsStateChange) {
        [self _setInternalPaused:paused];
    }
}

%new
- (void)_setInternalPaused:(BOOL)paused {
    // If setting to be not paused, then check what the strategy used previously
    // was so that we can effectively undo it
    int defaultStrategy = [objc_getClass("XENHResources") currentPauseStrategy];
    int strategy = !paused ? self.webView._xh_currentPauseStrategy : defaultStrategy;
    
    switch (strategy) {
        /*
         The 'Low' strategy involves just pausing GPU updates on the widget.
         This means that JavaScript execution is untouched, and therefore
         interferes the least with widget lifecycles.
         */
        case kLow:
            if ([NSThread isMainThread]) {
                [self _setInternalHidden:paused];
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^(void){
                    [self _setInternalHidden:paused];
                });
            }
            
            break;
        /*
         The 'High' strategy involves unloading the entire widget when it is paused.
         As a result, this incurs a slight delay during 'unpause' for the widget to reload.
        */
        case kHigh:
            // Un/Re-load the entire widget
            if (paused) {
                // Ignore if pending a JIT load
                if (self.pendingWidgetJITLoad) return;
                
                // Get a snapshot for this widget, then unload it
                [self snapshotWidget:^(UIImage *snapshot) {
                    // Load snapshot
                    if (self.snapshotWebView) {
                        [self.snapshotWebView removeFromSuperview];
                        self.snapshotWebView = nil;
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // If the pause state has toggled again, don't do anything
                        if (!self.isPaused) return;
                        
                        self.snapshotWebView = [[UIImageView alloc] initWithImage:snapshot];
                        [self.view addSubview:self.snapshotWebView];

                        // Direct the webview to about:blank
                        NSURL *url = [NSURL URLWithString:@"about:blank"];
                        NSURLRequest *request = [NSURLRequest requestWithURL:url];
                        [self.webView loadRequest:request];

                        // Hide the webview
                        self.webView.hidden = YES;

                        // Request layout for the snapshot
                        [self.view setNeedsLayout];
                        [self.view setNeedsDisplay];
                    });
                }];
            } else {
                // Load the widget, then remove snapshot in didFinishNavigation
                self.pendingHighStrategyLoad = YES;
                
                // Restore URL
                NSURL *url = [NSURL fileURLWithPath:self.widgetIndexFile isDirectory:NO];
                if (url && [[NSFileManager defaultManager] fileExistsAtPath:self.widgetIndexFile]) {
                    [self.webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
                }
                
                // Add failsafe for clearing the snapshot
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                   if (self.snapshotWebView) {
                       [self.snapshotWebView removeFromSuperview];
                       self.snapshotWebView = nil;
                                  
                       self.webView.hidden = NO;
                   }
                });
            }
            
            break;
            
        /*
         The 'Moderate' strategy involves pausing GPU updates, and notifying WebKit of
         application events. This is done by faking 'app backgrounded' and 'app resumed' events
         per widget.
         
         This strategy is the most prone to breakages from iOS major updates. If it is detected
         that the required WebKit symbols have changed, then this strategy will gracefully degrade
         to the 'Low' variant.
        */
        case kModerate:
        default: {
            if ([NSThread isMainThread]) {
                [self _setInternalHidden:paused];
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^(void){
                    [self _setInternalHidden:paused];
                });
            }
            
            // Update activity state
            setWKWebViewActivityState(self.webView, paused);
        }
    }
    
    // Store the strategy for later re-use
    if (paused)
        self.webView._xh_currentPauseStrategy = strategy;
}

- (void)setPausedAfterTerminationRecovery:(BOOL)paused {
    %orig;
    
    // Update activity states due to the underlying webview getting terminated
    if (paused) {
        // Ignore for the 'high' strategy
        if (self.webView._xh_currentPauseStrategy == kHigh)
            return;
        
        [self _setInternalPaused:paused];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    // Give it a retry if in high strategy
    
    int defaultStrategy = [objc_getClass("XENHResources") currentPauseStrategy];
    if (defaultStrategy == kHigh) {
        NSURL *url = [NSURL fileURLWithPath:self.widgetIndexFile isDirectory:NO];
        if (url && [[NSFileManager defaultManager] fileExistsAtPath:self.widgetIndexFile]) {
            [webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
        }
    }
    
    %orig;
}

- (void)_unloadWebView {
    %orig;
    
    if (self.snapshotWebView) {
        self.pendingHighStrategyLoad = NO;
        
        // Ensure the snapshot gets removed
        [self.snapshotWebView removeFromSuperview];
        self.snapshotWebView = nil;
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    %orig;
    
    if (self.pendingHighStrategyLoad &&
        ![[webView.URL absoluteString] isEqualToString:@"about:blank"]) {
        self.pendingHighStrategyLoad = NO;
        
        // Show the webview
        dispatch_async(dispatch_get_main_queue(), ^{
           self.webView.hidden = NO;
           self.webView.alpha = 0.0;
           
           // Transition in the webview
           [UIView animateWithDuration:0.15 animations:^{
               self.webView.alpha = 1.0;
               self.snapshotWebView.alpha = 0.0;
           } completion:^(BOOL finished) {
               if (finished) {
                   // Remove the snapshot
                   [self.snapshotWebView removeFromSuperview];
                   self.snapshotWebView = nil;
               }
           }];
        });
    }
}

- (void)viewDidLayoutSubviews {
    %orig;
    
    if (self.snapshotWebView) {
        self.snapshotWebView.frame = [self widgetFrame];
    }
}

%new
- (void)_setInternalHidden:(BOOL)paused {
    // Remove the views from being updated
    self.legacyWebView.hidden = paused ? YES : NO;
    self.webView.hidden = paused ? YES : NO;
}

%end

%hook WKWebView

// Override the result of _isBackground as needed
%property (nonatomic) BOOL _xh_isPaused;
%property (nonatomic) BOOL _xh_requiresProviderUpdate;
%property (nonatomic) int  _xh_currentPauseStrategy;

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
        
        // If any of the required symbols are missing, the moderate strategy needs to degrade
        // gracefully to the low strategy
        if (!_xenhtml_bm_validate((void*)WebPageProxy$activityStateDidChange, @"WebPageProxy::activityStateDidChange"))
            isModerateStrategyPossible = NO;
        if (!_xenhtml_bm_validate((void*)WebPageProxy$applicationDidEnterBackground, @"WebPageProxy::applicationDidEnterBackground"))
            isModerateStrategyPossible = NO;
        if (!_xenhtml_bm_validate((void*)WebPageProxy$applicationWillEnterForeground, @"WebPageProxy::applicationWillEnterForeground"))
            isModerateStrategyPossible = NO;
        if (!_xenhtml_bm_validate((void*)WebPageProxy$applicationWillResignActive, @"WebPageProxy::applicationWillResignActive"))
            isModerateStrategyPossible = NO;
        if (!_xenhtml_bm_validate((void*)WebPageProxy$applicationDidBecomeActive, @"WebPageProxy::applicationDidBecomeActive"))
            isModerateStrategyPossible = NO;

        XENlog(@"DEBUG :: initialising hooks");
        %init(SpringBoard);
    }
}
