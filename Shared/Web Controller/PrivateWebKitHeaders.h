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

#ifndef PrivateWebKitHeaders_h
#define PrivateWebKitHeaders_h

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

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
- (void)_setMediaDevicesEnabled:(bool)arg1;
- (void)_setPageVisibilityBasedProcessSuppressionEnabled:(bool)arg1;
- (void)_setOfflineApplicationCacheIsEnabled:(BOOL)arg1;
- (void)_setSimpleLineLayoutDebugBordersEnabled:(BOOL)arg1;
- (void)_setStandalone:(BOOL)arg1;
- (void)_setStorageBlockingPolicy:(int)arg1;
- (void)_setTelephoneNumberDetectionIsEnabled:(BOOL)arg1;
- (void)_setTiledScrollingIndicatorVisible:(BOOL)arg1;
- (void)_setVisibleDebugOverlayRegions:(unsigned int)arg1;

- (void)_setMediaCaptureRequiresSecureConnection:(bool)arg1;
- (void)_setResourceUsageOverlayVisible:(bool)arg1 ;
@end

@interface WKWebViewConfiguration (Private)
- (void)_setWaitsForPaintAfterViewDidMoveToWindow:(bool)arg1 NS_AVAILABLE_IOS(10_3);
- (void)_setAlwaysRunsAtForegroundPriority:(BOOL)arg1;
- (void)_setCanShowWhileLocked:(BOOL)value;
@end

@interface WKContentView : UIView
- (void)_webTouchEventsRecognized:(id)gestureRecognizer;
- (void)_singleTapCommited:(UITapGestureRecognizer *)gestureRecognizer;
@end

@interface WKWebView (IOS9)
- (id)loadFileURL:(id)arg1 allowingReadAccessToURL:(id)arg2;
- (void)_killWebContentProcessAndResetState;
- (WKContentView*)_currentContentView;
-(void)_close;
@property (nonatomic, readonly) pid_t _webProcessIdentifier;
@property (nonatomic, readonly) BOOL _webProcessIsResponsive; // iOS 10.
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

// Up to iOS 12.4 (?)
- (void)_updateGestureWithEvent:(id)arg1 buttonEvent:(id)arg2;

// Definitely iOS 13
- (void)_updateGestureForActiveEvents;
- (void)_delayTouchesForEventIfNeeded:(id)arg1;

- (void)_clearDelayedTouches;
- (void)_resetGestureRecognizer;
@end

@interface UITouch (Private2)
- (CGPoint)_locationInSceneReferenceSpace;
@end

@protocol WKUIDelegatePrivate <WKUIDelegate>

@optional
-(void)_webView:(id)arg1 requestUserMediaAuthorizationForDevices:(unsigned long long)arg2 url:(id)arg3 mainFrameURL:(id)arg4 decisionHandler:(/*^block*/id)arg5;
-(void)_webView:(id)arg1 checkUserMediaPermissionForURL:(id)arg2 mainFrameURL:(id)arg3 frameIdentifier:(unsigned long long)arg4 decisionHandler:(void (^)(NSString*, BOOL))arg5;
-(void)_webView:(id)arg1 requestGeolocationPermissionForFrame:(id)arg2 decisionHandler:(/*^block*/id)arg3;
-(void)_webView:(id)arg1 didNotHandleTapAsClickAtPoint:(CGPoint)arg2;
-(void)_webView:(id)arg1 requestGeolocationAuthorizationForURL:(id)arg2 frame:(id)arg3 decisionHandler:(void (^)(BOOL))arg4;
@end

#endif /* PrivateWebKitHeaders_h */
