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

#import "XENHWidgetController.h"
#import "XENHResources.h"
#import "PrivateWebKitHeaders.h"

#import <objc/runtime.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

// For WKWebProcess manipulation
#include <spawn.h>
extern char **environ;

@interface UITouch (Private)
- (void)set_xh_forwardingView:(id)view;
- (id)_xh_forwardingView;
@end

@interface UIScrollView (Private2)
- (bool)touchesShouldBegin:(NSSet*)arg1 withEvent:(UIEvent*)arg2 inContentView:(UIView*)arg3;
- (bool)touchesShouldCancelInContentView:(UIView*)arg1;
@end

@interface _UIBackdropView : UIView
- (instancetype)initWithStyle:(int)style;
@end

@interface MTMaterialView : UIView
+ (MTMaterialView*)materialViewWithRecipe:(long long)arg1 options:(unsigned long long)arg2;
@end

@interface WKWebView (WidgetInfo)
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration injectWidgetData:(BOOL)injectWidgetData;
@end

@interface XENHWidgetController ()

// Editing mode
@property (nonatomic, strong) UIView *editingBackground;
@property (nonatomic, strong) UIView *editingPositioningBackground;
@property (nonatomic, strong) XENHButton *editingSettingsButton;
@property (nonatomic, strong) XENHCloseButton *editingRemoveButton;
@property (nonatomic, strong) UIPanGestureRecognizer *editingPanGesture;
@property (nonatomic, strong) NSTimer *editingPageEdgeTimer;
@property (nonatomic, readwrite) CGPoint editingGestureStartPoint;
@property (nonatomic, readwrite) CGPoint editingViewStartCenter;

// State management
@property (nonatomic, readwrite) BOOL isPaused;
@property (nonatomic, readwrite) BOOL isUnloading;
@property (nonatomic, readwrite) BOOL pendingWidgetJITLoad;

@end

static WKProcessPool *sharedProcessPool;
static UIWindow *sharedOffscreenRenderingWindow;

@implementation XENHWidgetController

+ (WKProcessPool*)sharedProcessPool {
    if (!sharedProcessPool) {
        static dispatch_once_t p = 0;
        dispatch_once(&p, ^{
            sharedProcessPool = [[WKProcessPool alloc] init];
        });
    }
    
    return sharedProcessPool;
}

+ (UIWindow*)sharedOffscreenRenderingWindow {
    if (!sharedOffscreenRenderingWindow) {
        static dispatch_once_t p = 0;
        dispatch_once(&p, ^{
            sharedOffscreenRenderingWindow = [[UIWindow alloc] init];
            sharedOffscreenRenderingWindow.frame = CGRectMake(-SCREEN_WIDTH, -SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
            sharedOffscreenRenderingWindow.hidden = NO;
        });
    }
    
    return sharedOffscreenRenderingWindow;
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Initialisation
/////////////////////////////////////////////////////////////////////////////

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.editingDelegate = nil;
        self.isPaused = NO;
        self.pendingWidgetJITLoad = NO;
        self.requiresJITWidgetLoad = NO;
    }
    
    return self;
}

- (void)loadView {
    self.view = [[XENHTouchPassThroughView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 12345;
    
    [(XENHTouchPassThroughView*)self.view setDelegate:self];
    
    // Add the editing background view here, due to usage of insertSubview:aboveSubview:
    // Using a UIView here since it needs to respond to touch hittests for positioning
    self.editingBackground = [[UIView alloc] initWithFrame:CGRectZero];
    self.editingBackground.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    self.editingBackground.hidden = YES;
    self.editingBackground.userInteractionEnabled = YES;
    self.editingBackground.layer.cornerRadius = 12.5;
    self.editingBackground.tag = 1337;
    
    [self.view addSubview:self.editingBackground];
}

- (BOOL)_canShowWhileLocked{
        return YES;
}

- (void)dealloc {
    [self unloadWidget];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<XENHWidgetController: %p; location = '%@'; legacy mode = %d>", self, self.widgetIndexFile, self.usingLegacyWebView];
}

- (void)didReceiveMemoryWarningExternal {
    [self reloadWidget];
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
/////////////////////////////////////////////////////////////////////////////

- (void)configureAfterFirstLaunch:(NSNotification*)notification {
    // Can now reload the widget since SpringBoard has launched
    [self reloadWidget];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureWithWidgetIndexFile:(NSString*)widgetIndexFile andMetadata:(NSDictionary*)metadata {
    // First, unload the existing widget
    [self unloadWidget];
    
    // XXX: To support multiple instances of the same widget, sometimes widgetIndexFile will be
    // prefixed by :1/var/mobile/Library/..., :2/var/mobile/Library/..., etc.
    // Therefore, we need to check if this is the case BEFORE updating our internal property
    // holding this location.
    
    self._rawWidgetIndexFile = widgetIndexFile;
    
    if ([widgetIndexFile hasPrefix:@":"]) {
        // Read the string up to the first /, then strip off the : prefix.
        NSRange range = [widgetIndexFile rangeOfString:@"/"];
        
        widgetIndexFile = [widgetIndexFile substringFromIndex:range.location];
    }
    
    self.widgetIndexFile = widgetIndexFile;
    self.widgetMetadata = metadata;
    
    // Check fallback state.
    self.usingLegacyWebView = [self _widgetIndexFile:widgetIndexFile wantsFallbackForMetadata:metadata];
    
    // Check if SpringBoard has finished launching. If not, then wait until it has
    if (![XENHResources hasSeenSpringBoardLaunch]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureAfterFirstLaunch:) name:@"com.matchstic.xenhtml/seenSpringBoardLaunch" object:nil];
        
        return;
    }
    
    if (self.usingLegacyWebView) {
        // Load using UIWebView
        XENlog(@"Loading using fallback method to support Cycript etc");
        [self _loadLegacyWebView];
        [self.view insertSubview:self.legacyWebView aboveSubview:self.editingBackground];
    } else {
        XENlog(@"Loading via WKWebView");
        // Load using WKWebView
        [self _loadWebView];
        
        // Add the webView to an offscreen view at first to solve loading issues
        [self renderWebViewOffscreen:self.webView];
    }
}

- (BOOL)_widgetIndexFile:(NSString*)widgetIndexFile wantsFallbackForMetadata:(NSDictionary*)metadata {
    if ([XENHResources isAtLeastiOSVersion:13 subversion:0])
        return NO;
    
    BOOL forcedFallback = [XENHResources useFallbackForHTMLFile:widgetIndexFile];
    BOOL metadataFallback = [[metadata objectForKey:@"useFallback"] boolValue];
    
    return forcedFallback || metadataFallback;
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
    
    if (rect.size.height > SCREEN_HEIGHT)
        rect.size.height = self.view.bounds.size.height;
    
    // Setup configuration for the WKWebView
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;
    
    // Ensure WebKit creates remote CAContext as secure
    if ([config respondsToSelector:@selector(_setCanShowWhileLocked:)]) {
        [config _setCanShowWhileLocked:YES];
    }
    
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    
    // This script is utilised to stop the loupé that iOS creates on long-press
    NSString *source1 = @"var style = document.createElement('style'); \
    style.type = 'text/css'; \
    style.innerText = '*:not(input) { -webkit-user-select: none; -webkit-touch-callout: none; } body { background-color: transparent; }'; \
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
    
    // Call to the injection hook
    [self _userContentController_injectionHook:userContentController];
    
    config.userContentController = userContentController;
    config.requiresUserActionForMediaPlayback = NO;
    
    // Configure some private settings on WKWebView
    WKPreferences *preferences = [[WKPreferences alloc] init];
    [preferences _setAllowFileAccessFromFileURLs:YES];
    [preferences _setFullScreenEnabled:NO];
    [preferences _setOfflineApplicationCacheIsEnabled:YES]; // Local storage is needed for Lock+ etc.
    [preferences _setStandalone:NO];
    [preferences _setTelephoneNumberDetectionIsEnabled:NO];
    [preferences _setTiledScrollingIndicatorVisible:NO];
    [preferences _setLogsPageMessagesToSystemConsoleEnabled:YES];
	
	if ([preferences respondsToSelector:@selector(_setMediaCaptureRequiresSecureConnection:)])
		[preferences _setMediaCaptureRequiresSecureConnection:NO];
    
    if ([preferences respondsToSelector:@selector(_setMediaDevicesEnabled:)]) {
        [preferences _setMediaDevicesEnabled:YES];
    }
    
    // Developer tools
    if ([XENHResources developerOptionsEnabled]) {
        // Allow Safari remote debugging - needs get-task-allow though
        [preferences _setDeveloperExtrasEnabled:YES];
        
        [preferences _setResourceUsageOverlayVisible:[XENHResources showResourceUsageInWidgets]];
        [preferences _setCompositingBordersVisible:[XENHResources showCompositingBordersInWidgets]];
    }
    
    config.preferences = preferences;
    
    if ([XENHResources isAtLeastiOSVersion:11 subversion:0]) {
        // Silence compiler warning
        if (@available(iOS 11.0, *)) {
            [config _setWaitsForPaintAfterViewDidMoveToWindow:YES];
        } else {
            // Fallback on earlier versions
        }
    }
    
    if (self.webView) {
        [self.webView removeFromSuperview];
        self.webView = nil;
    }
    
	// Load for widget info, if available
	id webview = [WKWebView alloc];
	if ([webview respondsToSelector:@selector(initWithFrame:configuration:injectWidgetData:)]) {
		XENlog(@"Initialising with widgetinfo injection");
		self.webView = [webview initWithFrame:rect configuration:config injectWidgetData:YES];
	} else
		self.webView = [webview initWithFrame:rect configuration:config];
	
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    self.webView.scrollView.layer.masksToBounds = NO;
    
    if (!widgetCanScroll) {
        self.webView.scrollView.scrollEnabled = NO;
        self.webView.scrollView.contentSize = self.webView.bounds.size;
    } else {
        self.webView.scrollView.scrollEnabled = YES;
    }
    
    self.webView.scrollView.bounces = NO;
    self.webView.scrollView.scrollsToTop = NO;
    self.webView.scrollView.minimumZoomScale = 1.0;
    self.webView.scrollView.maximumZoomScale = 1.0;
    self.webView.scrollView.multipleTouchEnabled = YES;
    
    self.webView.allowsLinkPreview = NO;
    
    if (!self.requiresJITWidgetLoad) {
        NSURL *url = [NSURL fileURLWithPath:self.widgetIndexFile isDirectory:NO];
        if (url && [[NSFileManager defaultManager] fileExistsAtPath:self.widgetIndexFile]) {
            XENlog(@"Loading from URL: %@", url);
            [self.webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
        }
    } else {
        XENlog(@"Requesting a JIT widget load");
        
        // A JIT load is needed to avoid UI issues when loading a widget during the paused state
        self.pendingWidgetJITLoad = YES;
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
    
    if (rect.size.height > SCREEN_HEIGHT)
        rect.size.height = self.view.bounds.size.height;
    
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
    
    self.legacyWebView.allowsLinkPreview = NO;
    
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
    
    [self _legacyMode_injectionHook:self.legacyWebView];
    
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

- (void)_userContentController_injectionHook:(WKUserContentController*)controller {
    // used by other tweaks etc to inject additional user scripts into
    // the underlying WKWebView
}

- (void)_legacyMode_injectionHook:(UIWebView*)webView {
    // used by other tweaks etc to inject additional user scripts into
    // the underlying legacy UIWebView
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Orientation and layout handling
/////////////////////////////////////////////////////////////////////////////

- (CGRect)widgetFrame {
    BOOL isWidgetFullscreen = [[self.widgetMetadata objectForKey:@"isFullscreen"] boolValue];
    
    CGRect rect = CGRectMake(
                            [[self.widgetMetadata objectForKey:@"x"] floatValue]*SCREEN_WIDTH,
                            [[self.widgetMetadata objectForKey:@"y"] floatValue]*SCREEN_HEIGHT,
                            isWidgetFullscreen ? SCREEN_WIDTH : [[self.widgetMetadata objectForKey:@"width"] floatValue],
                            isWidgetFullscreen ? SCREEN_HEIGHT : [[self.widgetMetadata objectForKey:@"height"] floatValue]
                  );
    
    if (rect.size.height > self.view.bounds.size.height)
        rect.size.height = self.view.bounds.size.height;
    
    return rect;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    BOOL widgetCanScroll = [[self.widgetMetadata objectForKey:@"widgetCanScroll"] boolValue];
    CGRect rect = [self widgetFrame];
    
    self.webView.frame = rect;
    self.legacyWebView.frame = rect;
    
    if (!widgetCanScroll) {
        self.webView.scrollView.contentSize = self.webView.bounds.size;
        self.legacyWebView.scrollView.contentSize = self.legacyWebView.bounds.size;
        
        self.webView.scrollView.scrollEnabled = NO;
    }
    
    // Editing buttons
    self.editingRemoveButton.frame = CGRectMake(-12, -12, self.editingRemoveButton.frame.size.width, self.editingRemoveButton.frame.size.height);
    
    CGFloat settingsX = self.editingRemoveButton.frame.origin.x + self.editingRemoveButton.frame.size.width + 8;
    self.editingSettingsButton.frame = CGRectMake(settingsX, -12, self.editingSettingsButton.frame.size.width, self.editingSettingsButton.frame.size.height);
    
    self.editingBackground.frame = rect;
    self.editingPositioningBackground.frame = rect;
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
    if (self.isPaused == paused) // only update if needed
        return;
    
    self.isPaused = paused;
    
    // State management handled by BatteryManager
}

- (void)setPausedAfterTerminationRecovery:(BOOL)paused {
    self.isPaused = paused;
    
    // State management handled by BatteryManager
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Lifecycle handling
/////////////////////////////////////////////////////////////////////////////

- (void)unloadWidget {
    if (self.isUnloading)
        return;
    
    self.isUnloading = YES;
    
    [self _unloadWebView];
    [self _unloadLegacyWebView];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.isUnloading = NO;
}

- (void)reloadWidget {
    [self configureWithWidgetIndexFile:self._rawWidgetIndexFile andMetadata:self.widgetMetadata];
}

- (void)doJITWidgetLoadIfNecessary {
    if (self.webView && self.pendingWidgetJITLoad) {
        self.pendingWidgetJITLoad = NO;
        
        // Do widget loading now
        XENlog(@"Running a JIT widget load");
        
        NSURL *url = [NSURL fileURLWithPath:self.widgetIndexFile isDirectory:NO];
        if (url && [[NSFileManager defaultManager] fileExistsAtPath:self.widgetIndexFile]) {
            XENlog(@"Loading from URL: %@", url);
            [self.webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
        }
    }
    
    // Not adding JIT support to legacy widgets
}

- (void)_unloadWebView {
    if (self.webView) {
        XENlog(@"Unloading webview: %@", self.widgetIndexFile);
        self.webView.hidden = YES;
        
        [self.webView stopLoading];
        [self.webView removeFromSuperview];
        
        self.webView.scrollView.delegate = nil;
        self.webView.navigationDelegate = nil;
        
        [self.webView _close];
        
        // Don't need to do this -> ARC handles for us on dealloc.
        // Furthermore, doing this leads to a nasty segfault on unlock for iOS 10 users,
        // due to the order of deallocation of the LS.
        // self.webView = nil;
    }
}

- (void)_unloadLegacyWebView {
    if (self.legacyWebView) {
        XENlog(@"Unloading webview: %@", self.widgetIndexFile);
        [self.legacyWebView stopLoading];
        
        self.legacyWebView.hidden = YES;
        [self.legacyWebView removeFromSuperview];
        
        // See note above.
        //self.legacyWebView = nil;
    }
}

- (void)viewDidMoveToWindow {
    // Handle bringing webview onscreen if needed.
    if (self.webView
        && self.view.window != nil
        && self._hasMovedWebViewOnscreen == NO
        && [self.webView.superview isEqual:self._offscreenRenderingView]) {
        
        [self.view insertSubview:self.webView aboveSubview:self.editingBackground];
        
        self._hasMovedWebViewOnscreen = YES;
        
        [self cleanUpOffscreenView];
    }
}

- (void)renderWebViewOffscreen:(WKWebView *)webView {
    if (self.view.window) {
        [self.view insertSubview:webView aboveSubview:self.editingBackground];
        return;
    }
    
    if (!self._offscreenRenderingView) {
        self._offscreenRenderingView = [self constructOffscreenView];
    }
    
    // Make sure the offscreen view is on the right keyWindow.
    UIWindow *appWindow = [XENHWidgetController sharedOffscreenRenderingWindow];
    [appWindow addSubview:self._offscreenRenderingView];
    
    [self._offscreenRenderingView addSubview:webView];
    self._hasMovedWebViewOnscreen = NO;
}

- (void)cleanUpOffscreenView {
    if (self._offscreenRenderingView.subviews.count == 0) {
        [self._offscreenRenderingView removeFromSuperview];
        self._offscreenRenderingView = nil;
    }
}

- (UIView *)constructOffscreenView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.clipsToBounds = YES;
    
    return view;
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
    
    // Tracking occurs on scrollViews
    if ([[self._touchForwardedView class] isEqual:[UIScrollView class]] || [[self._touchForwardedView class] isEqual:objc_getClass("UIWebOverflowScrollView")]) {
        
        for (UIGestureRecognizer *recog in self._touchForwardedView.gestureRecognizers) {
            isTracking = [recog _isRecognized];
            
            if (isTracking)
                break;
        }
    }
    
    return isTracking;
}

- (BOOL)_touchForwardedViewIsScroll:(id)view {
    return [[view class] isKindOfClass:[UIScrollView class]] ||
           [[view class] isEqual:objc_getClass("UIWebOverflowScrollView")] ||
           [[view class] isEqual:objc_getClass("WKChildScrollView")];
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer*)arg1 atLocation:(CGPoint)location {
    // only prevent on scrollviews
    
    UIView *view = [self _webTouchDelegate];
    
    UIView *_touchForwardedView = [view hitTest:location withEvent:nil];
    
    if ([self _touchForwardedViewIsScroll:_touchForwardedView]) {
        return YES;
    }
    
    // Base case!
    return NO;
}

- (void)forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self _forwardTouches:touches withEvent:event forType:0];
}

- (void)forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self _forwardTouches:touches withEvent:event forType:1];
}

- (void)forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self _forwardTouches:touches withEvent:event forType:2];
}

- (void)forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self _forwardTouches:touches withEvent:event forType:3];
}

- (void)_forwardTouches:(NSSet*)touches withEvent:(UIEvent*)event forType:(int)type {
    if (self.webView && !self.webView.userInteractionEnabled)
        return;
    if (self.legacyWebView && !self.legacyWebView.userInteractionEnabled)
        return;
    
    // First, forward to the web touch recognisers
    UIView *view = [self _webTouchDelegate];
    NSSet *set = [(UITouchesEvent*)event _allTouches];
    view.tag = 1337;
    
    // Force first responder if needed
    if (![view isFirstResponder])
        [view becomeFirstResponder];
    
    for (UIGestureRecognizer *recog in view.gestureRecognizers) {
        /*if ([recog isKindOfClass:[UITapGestureRecognizer class]]) {
            UITapGestureRecognizer *tapRecogniser = (UITapGestureRecognizer*)recog;

            // check if it is a 1-finger double-tap, and ignore if so
            if (tapRecogniser.numberOfTapsRequired == 2 && tapRecogniser.numberOfTouchesRequired == 1) {
                continue;
            }
        }*/
        
        switch (type) {
            case 0:
                [recog _touchesBegan:set withEvent:event];
                break;
            case 1:
                [recog _touchesMoved:set withEvent:event];
                break;
            case 2:
                [recog _touchesEnded:set withEvent:event];
                break;
            case 3:
                [recog _touchesCancelled:set withEvent:event];
                break;
                
            default:
                break;
        }
    }
    
    // Now, forward to any scrollView in hierarchy, if necessary
    
    if (type == 0) {
        CGPoint hitPoint = [[set anyObject] _locationInSceneReferenceSpace];
        self._touchForwardedView = [view hitTest:hitPoint withEvent:event];
        
        if ([[self._touchForwardedView class] isEqual:objc_getClass("UIWebOverflowContentView")]) {
            self._touchForwardedView = [self._touchForwardedView superview];
        }
    }
    
    if ([self _touchForwardedViewIsScroll:self._touchForwardedView]) {
        // Need to forward to the scrollView also!
        
        // Used for getting touches for gestureRecognizers.
        NSInteger oldTag = self._touchForwardedView.tag;
        self._touchForwardedView.tag = 1337;
        
        // Forward to gestures also
        for (UIGestureRecognizer *recog in self._touchForwardedView.gestureRecognizers) {
            // If the (converted) touch is outside of the bounds of the gesture's view, then don't start
            
            /*if ([recog isKindOfClass:[UITapGestureRecognizer class]]) {
                UITapGestureRecognizer *tapRecogniser = (UITapGestureRecognizer*)recog;

                // check if it is a 1-finger double-tap, and ignore if so
                if (tapRecogniser.numberOfTapsRequired == 2 && tapRecogniser.numberOfTouchesRequired == 1) {
                    continue;
                }
            }*/
            
            switch (type) {
                case 0:
                    [recog _touchesBegan:set withEvent:event];
                    break;
                case 1:
                    if ([recog respondsToSelector:@selector(_updateGestureWithEvent:buttonEvent:)])
                        [recog _updateGestureWithEvent:event buttonEvent:nil];
                    else if ([recog respondsToSelector:@selector(_updateGestureForActiveEvents)])
                        [recog _updateGestureForActiveEvents];
                    
                    [recog _delayTouchesForEventIfNeeded:event];
                    [recog _touchesMoved:set withEvent:event];
                    break;
                case 2:
                    [recog _touchesEnded:set withEvent:event];
                    
                    if ([recog respondsToSelector:@selector(_updateGestureWithEvent:buttonEvent:)])
                        [recog _updateGestureWithEvent:event buttonEvent:nil];
                    else if ([recog respondsToSelector:@selector(_updateGestureForActiveEvents)])
                        [recog _updateGestureForActiveEvents];
                    
                    [recog _clearDelayedTouches];
                    [recog _resetGestureRecognizer];
                    break;
                case 3:
                    [recog _touchesCancelled:set withEvent:event];
                    
                    if ([recog respondsToSelector:@selector(_updateGestureWithEvent:buttonEvent:)])
                        [recog _updateGestureWithEvent:event buttonEvent:nil];
                    else if ([recog respondsToSelector:@selector(_updateGestureForActiveEvents)])
                        [recog _updateGestureForActiveEvents];
                    
                    [recog _clearDelayedTouches];
                    [recog _resetGestureRecognizer];
                    break;
                    
                default:
                    break;
            }
        }
        
        self._touchForwardedView.tag = oldTag;
    }
}

- (UIView*)hitTestForEvent:(UIEvent *)event {
    CGPoint point = [[event.allTouches anyObject] _locationInSceneReferenceSpace];
    return [self.view hitTest:point withEvent:event];
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
    // WebView process has terminated... Better reload?
    if (webView != nil) {
        [self reloadWidget];
        
        // If we are supposed to be paused, re-call ourselves
        [self setPausedAfterTerminationRecovery:self.isPaused];
    }
}

// **************************************************************************
/////////////////////////////////////////////////////////////////////////////
// Widget editing
/////////////////////////////////////////////////////////////////////////////
// **************************************************************************

- (void)setEditingDelegate:(id<XENHWidgetEditingDelegate>)editingDelegate {
    _editingDelegate = editingDelegate;
    
    // Add the editing buttons and pan gesture if needed
    if (editingDelegate) {
        
        if (!self.viewLoaded) {
            XENlog(@"Adding editing buttons before the view is loaded...");
        }
        
        // Settings button
        if (!self.editingSettingsButton) {
            
            self.editingSettingsButton = [[XENHButton alloc] initWithTitle:[XENHResources localisedStringForKey:@"WIDGETS_SETTINGS"]];
            [self.editingSettingsButton addTarget:self
                                           action:@selector(_editingSettingsButtonTapped:)
                                 forControlEvents:UIControlEventTouchUpInside];
            self.editingSettingsButton.hidden = YES;
            
            [self.view addSubview:self.editingSettingsButton];
        }
        
        // Remove button
        if (!self.editingRemoveButton) {
            self.editingRemoveButton = [[XENHCloseButton alloc] initWithTitle:@""];
            [self.editingRemoveButton addTarget:self
                                         action:@selector(_editingRemoveButtonTapped:)
                               forControlEvents:UIControlEventTouchUpInside];
            self.editingRemoveButton.hidden = YES;
            
            [self.view addSubview:self.editingRemoveButton];
        }
        
        // Gesture
        if (!self.editingPanGesture) {
            self.editingPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleEditingPan:)];
            self.editingPanGesture.minimumNumberOfTouches = 1;
            
            [self.editingBackground addGestureRecognizer:self.editingPanGesture];
        }
    }
}

- (void)setEditing:(BOOL)editing {
    // TODO: Animate in the editing buttons
    
    self.isEditing = editing;
    self.editingSettingsButton.hidden = !editing;
    self.editingRemoveButton.hidden = !editing;
    self.editingBackground.hidden = !editing;
    
    // Disable webview touches to allow positioning
    self.webView.userInteractionEnabled = !editing;
    self.legacyWebView.userInteractionEnabled = !editing;
}

- (void)_editingSettingsButtonTapped:(id)sender {
    // Request settings to be re-displayed for this widget
    if (self.editingDelegate)
        [self.editingDelegate requestSettingsAdjustmentForWidget:self._rawWidgetIndexFile];
}

- (void)_editingRemoveButtonTapped:(id)sender {
    // Request this widget to be removed
    if (self.editingDelegate)
        [self.editingDelegate requestRemoveWidget:self._rawWidgetIndexFile];
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark UIPanGestureRecongizer delegate
/////////////////////////////////////////////////////////////////////////////

-(void)handleEditingPan:(UIPanGestureRecognizer*)gesture {
    
    if (!self.editingDelegate)
        return;
    
    static CGFloat pageEdgeDistance = 25; // px
    static BOOL shouldSnapToGuides = YES;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        
        // Notify delegate of positioning start
        [self.editingDelegate notifyWidgetPositioningDidBegin:self];
        
        self.editingGestureStartPoint = [gesture locationInView:self.view.superview];
        self.editingViewStartCenter = self.view.center;
        
        // Add some sweet styling now that this widget is rolling
        [self _addEditingPositioningBackdrop];
        self.editingBackground.backgroundColor = [UIColor clearColor];
        
        // Check user pref for snapping to axis
        shouldSnapToGuides = [XENHResources SBForegroundEditingSnapToYAxis];
        
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        // Cancel page edge timer due to user movement
        if (self.editingPageEdgeTimer)
            [self.editingPageEdgeTimer invalidate];
        
        // Move around on-screen.
        CGPoint currentGesturePoint = [gesture locationInView:self.view.superview];
        
        CGFloat xOffset = currentGesturePoint.x - self.editingGestureStartPoint.x;
        CGFloat yOffset = currentGesturePoint.y - self.editingGestureStartPoint.y;
        
        self.view.center = CGPointMake(self.editingViewStartCenter.x + xOffset, self.editingViewStartCenter.y + yOffset);
        
        if (shouldSnapToGuides) {
            CGFloat center = self.view.superview.bounds.size.width/2;
            
            CGFloat mainViewX = self.editingViewStartCenter.x + xOffset;
            
            // The editing background displayed to the user is on the top-left of the
            // actual view displayed by the controller; it is partially touchable.
            
            // Therefore, we need to counter-act this fact when trying to snap visually to
            // the X axis.
            
            CGFloat adjustment = (self.view.bounds.size.width/2.0) - (self.editingBackground.bounds.size.width/2.0);
            mainViewX -= adjustment;
            
            if (mainViewX > center-10 && mainViewX < center+10) {
                // SNAP!
                XENlog(@"Snapping to X axis");
                self.view.center = CGPointMake(center + adjustment, self.view.center.y);
            }
            
            // We do need to snap to the top edge if possible.
            if (self.view.frame.origin.y < 10 && self.view.frame.origin.y > -10) {
                // SNAP!
                self.view.frame = CGRectMake(self.view.frame.origin.x, 0, self.view.frame.size.width, self.view.frame.size.height);
            }
        }
        
        // Move to next page if needed
        
        // The timer will get invalidated as soon as the user moves the widget again.
        // Repeating it allows keeping the widget on the edge to keep moving along pages
        if (currentGesturePoint.x < pageEdgeDistance) {
            self.editingPageEdgeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self.editingDelegate selector:@selector(notifyWidgetHeldOnLeftEdge) userInfo:nil repeats:YES];
        } else if (currentGesturePoint.x > SCREEN_WIDTH - pageEdgeDistance) {
            self.editingPageEdgeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self.editingDelegate selector:@selector(notifyWidgetHeldOnRightEdge) userInfo:nil repeats:YES];
        }
        
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        // Cancel page edge timer due to user movement ending
        if (self.editingPageEdgeTimer)
            [self.editingPageEdgeTimer invalidate];
        
        // Move around on-screen.
        CGPoint currentGesturePoint = [gesture locationInView:self.view.superview];
        
        CGFloat xOffset = currentGesturePoint.x - self.editingGestureStartPoint.x;
        CGFloat yOffset = currentGesturePoint.y - self.editingGestureStartPoint.y;
        
        self.view.center = CGPointMake(self.editingViewStartCenter.x + xOffset, self.editingViewStartCenter.y + yOffset);
        
        if (shouldSnapToGuides) {
            CGFloat center = self.view.superview.bounds.size.width/2.0;
            
            CGFloat mainViewX = self.editingViewStartCenter.x + xOffset;
            CGFloat adjustment = (self.view.bounds.size.width/2.0) - (self.editingBackground.bounds.size.width/2.0);
            mainViewX -= adjustment;
            
            if (mainViewX > center-10 && mainViewX < center+10) {
                // SNAP!
                self.view.center = CGPointMake(center + adjustment, self.view.center.y);
            }
            
            // We do need to snap to the top edge if possible.
            if (self.view.frame.origin.y < 10 && self.view.frame.origin.y > -10) {
                // SNAP!
                self.view.frame = CGRectMake(self.view.frame.origin.x, 0, self.view.frame.size.width, self.view.frame.size.height);
            }
        }
        
        [self _removeEditingPositioningBackdrop];
        self.editingBackground.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.25];
        
        // Notify delegate of positioning end
        [self.editingDelegate notifyWidgetPositioningDidEnd:self];
    }
}

- (void)_addEditingPositioningBackdrop {
    if (objc_getClass("MTMaterialView") && [objc_getClass("MTMaterialView") respondsToSelector:@selector(materialViewWithRecipe:options:)]) {
        // Fancy times! iOS 11 and up
        self.editingPositioningBackground = [objc_getClass("MTMaterialView") materialViewWithRecipe:1 options:2];
        self.editingPositioningBackground.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.3];
    } else {
        // Fallback to _UIBackdropView
        self.editingPositioningBackground = [(_UIBackdropView*)[objc_getClass("_UIBackdropView") alloc] initWithStyle:2060];
    }
    
    self.editingPositioningBackground.frame = self.editingBackground.frame;
    self.editingPositioningBackground.layer.cornerRadius = 12.5;
    self.editingPositioningBackground.layer.masksToBounds = YES;
    self.editingPositioningBackground.hidden = NO;
    
    [self.view insertSubview:self.editingPositioningBackground atIndex:0];
}

- (void)_removeEditingPositioningBackdrop {
    [self.editingPositioningBackground removeFromSuperview];
    self.editingPositioningBackground = nil;
}

#pragma mark WKUIDelegate

- (void)webView:(WKWebView *)webView
    runJavaScriptAlertPanelWithMessage:(NSString *)message
    initiatedByFrame:(WKFrameInfo *)frame
    completionHandler:(void (^)(void))completionHandler {
    
    NSString *directory = [[frame.request.URL absoluteString] stringByDeletingLastPathComponent];
    NSArray *parts = [directory componentsSeparatedByString:@"/"];
    NSString *widgetName = [[parts lastObject] stringByRemovingPercentEncoding];
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:widgetName message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    
    [controller addAction:okAction];
    
    UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
    [rootController presentViewController:controller animated:YES completion:nil];
    
    // Immediately call completion handler once alert goes up
    completionHandler();
}

- (void)webView:(WKWebView *)webView
    runJavaScriptConfirmPanelWithMessage:(nonnull NSString *)message
    initiatedByFrame:(nonnull WKFrameInfo *)frame
    completionHandler:(nonnull void (^)(BOOL))completionHandler {
    
    NSString *directory = [[frame.request.URL absoluteString] stringByDeletingLastPathComponent];
    NSArray *parts = [directory componentsSeparatedByString:@"/"];
    NSString *widgetName = [[parts lastObject] stringByRemovingPercentEncoding];
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:widgetName message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"CANCEL"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }];
    
    [controller addAction:cancelAction];
    [controller addAction:okAction];
    
    UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
    [rootController presentViewController:controller animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView
    runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(NSString *)defaultText
    initiatedByFrame:(WKFrameInfo *)frame
    completionHandler:(void (^)(NSString *result))completionHandler {
    
    NSString *directory = [[frame.request.URL absoluteString] stringByDeletingLastPathComponent];
    NSArray *parts = [directory componentsSeparatedByString:@"/"];
    NSString *widgetName = [[parts lastObject] stringByRemovingPercentEncoding];
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:widgetName message:prompt preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UITextField *textField = controller.textFields[0];
        completionHandler(textField.text);
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"CANCEL"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(@"");
    }];
    
    [controller addAction:cancelAction];
    [controller addAction:okAction];
    
    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = defaultText;
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
    [rootController presentViewController:controller animated:YES completion:nil];
}

#pragma mark WKUIDelegatePrivate

- (void)_webView:(WKWebView*)arg1 requestGeolocationAuthorizationForURL:(id)arg2 frame:(id)arg3 decisionHandler:(void (^)(BOOL))arg4 {
    // Override requests for location API to true always
    arg4(YES);
}

- (void)_webView:(WKWebView*)arg1 shouldAllowDeviceOrientationAndMotionAccessRequestedByFrame:(id)arg2 decisionHandler:(void (^)(BOOL))arg3 {
    // Override requests for motion API to true always
    arg3(YES);
}

#pragma mark - Snapshots

- (void)snapshotWidget:(void (^)(UIImage *))completion {
    if (@available(iOS 11, *)) {
        // Use WebKit method for snapshot
        WKSnapshotConfiguration *wkSnapshotConfig = [WKSnapshotConfiguration new];
        wkSnapshotConfig.rect = self.webView.bounds;

        [self.webView takeSnapshotWithConfiguration:wkSnapshotConfig completionHandler:^(UIImage * _Nullable snapshotImage, NSError * _Nullable error) {
            
            completion(snapshotImage);
        }];
        
    } else {
        UIGraphicsBeginImageContextWithOptions(self.webView.bounds.size, NO, 0);
        [self.webView drawViewHierarchyInRect:self.webView.bounds afterScreenUpdates:YES];
        UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        completion(snapshotImage);
    }
}

@end
