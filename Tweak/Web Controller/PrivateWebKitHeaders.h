//
//  PrivateWebKitHeaders.h
//  Xen HTML
//
//  Created by Matt Clarke on 30/04/2018.
//

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

- (void)_updateGestureWithEvent:(id)arg1 buttonEvent:(id)arg2;
- (void)_delayTouchesForEventIfNeeded:(id)arg1;

- (void)_clearDelayedTouches;
- (void)_resetGestureRecognizer;
@end

@interface UITouch (Private2)
- (CGPoint)_locationInSceneReferenceSpace;
@end

#endif /* PrivateWebKitHeaders_h */
