/*
 Copyright (C) 2019 Matt Clarke
 
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

#import "XENHWidgetLayerController.h"
#import "XENHHomescreenForegroundViewController.h"
#import "XENHResources.h"
#import "XENHTouchPassThroughView.h"
#import "XENHButton.h"

#include "WebCycript.h"
#include <dlfcn.h>
#include <JavaScriptCore/JSContextRef.h> // For debug support
#import "XENHTouchForwardingRecognizer.h"
#import "XENSetupWindow.h"
#import <objc/runtime.h>

#pragma mark Simulator support

// %config(generator=internal);

/*
 Other steps to compile for actual device again:
 1. Make CydiaSubstrate linking required?
 2. Change build target
 
 Note: the simulator *really* doesn't like MSHookIvar.
 */

#pragma mark Private headers

///////////////////////////////////////////////////////////////////
// Sorry about this, too lazy to resolve before open-sourcing
///////////////////////////////////////////////////////////////////

@interface WebScriptObject : NSObject
@end

@interface WebFrame : NSObject
- (id)dataSource;
- (OpaqueJSContext*)globalContext;
@end

@interface WebView : NSObject
-(void)setPreferencesIdentifier:(id)arg1;
-(void)_setAllowsMessaging:(BOOL)arg1;
-(void)setScriptDebugDelegate:(id)delegate;
@end

@class WebView;
@class WebScriptCallFrame;

@interface WebScriptCallFrame
- (NSString *)functionName;
@end

@interface UIWebDocumentView : UIView
-(WebView*)webView;
@end

@interface UIWebView (Apple)
- (void)webView:(WebView *)view addMessageToConsole:(NSDictionary *)message;
- (void)webView:(WebView *)webview didClearWindowObject:(WebScriptObject *)window forFrame:(id)frame;
-(UIWebDocumentView*)_documentView;
@end

@interface SBLockScreenScrollView : UIView
@end

@interface SBLockScreenNotificationListController : NSObject
-(NSArray*)_xenhtml_listItems;
@end

@interface SBLockScreenNotificationListView : UIView
@property(assign, nonatomic) SBLockScreenNotificationListController *delegate;
@end

@interface PHContainerView : UIView
@property (readonly) NSString* selectedAppID;
@end

@interface SBHomeScreenViewController : UIViewController
-(void)_xenhtml_addTouchRecogniser;
@end

@interface SBHomeScreenView : UIView
@end

@interface FBProcessState : NSObject <NSCopying>

- (int)effectiveVisibility;
- (BOOL)isForeground;
- (BOOL)isRunning;
- (int)pid;
- (int)taskState;
- (int)visibility;

@end

@interface FBSystemService : NSObject
+ (id)sharedInstance;
- (void)exitAndRelaunch:(bool)arg1;
- (void)shutdownAndReboot:(bool)arg1;
@end

@interface SBBacklightController : NSObject
+(id)sharedInstance;
-(void)resetLockScreenIdleTimer;
-(void)cancelLockScreenIdleTimer;
@property(readonly, nonatomic) _Bool screenIsOn;
@end

@interface SBIdleTimerGlobalCoordinator : NSObject
+ (id)sharedInstance;
- (void)resetIdleTimer;
@end

@interface SBRootIconListView : UIView
@end

@interface UITapGestureRecognizer (Private)
@property (nonatomic, readonly) NSArray *touches;
@end

@interface SBLockScreenManager : NSObject
+(instancetype)sharedInstance;
- (void)setBioUnlockingDisabled:(BOOL)disabled forRequester:(id)requester;
- (id)lockScreenViewController;
@property(readonly) _Bool isUILocked;
@end

@interface SpringBoard : UIApplication
-(void)_relaunchSpringBoardNow;
- (id)_accessibilityFrontMostApplication;
- (_Bool)isLocked;
@end

@interface SBFLockScreenDateView : UIView
@end

@interface SBLockScreenView : UIView
- (void)_layoutBottomLeftGrabberView;
- (void)_layoutCameraGrabberView;
- (void)_layoutGrabberView:(UIView*)view atTop:(BOOL)top;
- (void)_xenhtml_addBackgroundTouchIfNeeded:(UIView*)view;
@end

@interface SBDashBoardView : UIView
@property(strong, nonatomic) UIView *backgroundView;
@property(strong, nonatomic) UIView *wallpaperEffectView;
@property(readonly, nonatomic) UIView *slideableContentView;
@end

@interface SBUIProudLockIconView : UIView
- (NSInteger)state;
@end

@interface SBDashBoardProudLockViewController : UIViewController
- (void)_setIconVisible:(_Bool)arg1 animated:(_Bool)arg2;
@end

@interface _NowPlayingArtView : UIView
@end

@interface SBTelephonyManager : NSObject
+ (id)sharedTelephonyManager;
- (_Bool)inCall;
@end

@interface SBConferenceManager : NSObject
+ (id)sharedInstance;
- (_Bool)inFaceTime;
@end

// iOS 10 additions.
@interface SBDashBoardBehavior : NSObject
+ (id)behaviorForProvider:(id)arg1;
+ (id)behavior;
@property(nonatomic) unsigned int restrictedCapabilities;
@property(nonatomic) int notificationBehavior;
@property(nonatomic) int scrollingMode;
@property(nonatomic) int idleWarnMode;
@property(nonatomic) int idleTimerMode;
@property(nonatomic) int idleTimerDuration;
@end

@interface SBLockScreenManager (iOS10)
- (void)setBiometricAutoUnlockingDisabled:(_Bool)arg1 forReason:(id)arg2;

@end

@interface SBDashBoardPageViewController : UIViewController
- (void)aggregateBehavior:(id)arg1;
- (void)aggregateAppearance:(id)arg1;
@end

@interface SBDashBoardAppearance : NSObject
- (void)addComponent:(id)arg1;
- (void)unionAppearance:(id)arg1;
@property(copy, nonatomic) NSSet *components;
- (void)removeComponent:(id)arg1;
@end

@interface SBDashBoardComponent : NSObject
+ (id)tinting;
+ (id)wallpaper;
+ (id)slideableContent;
+ (id)pageContent;
+ (id)pageControl;
+ (id)statusBar;
+ (id)dateView;
@property(nonatomic) CGPoint offset;
@property(nonatomic) long long type;
@property(nonatomic, getter=isHidden) _Bool hidden;
- (id)offset:(CGPoint)arg1;
- (id)legibilitySettings:(id)arg1;
- (id)view:(id)arg1;
- (id)value:(id)arg1;
- (id)string:(id)arg1;
- (id)flag:(long long)arg1;
- (id)hidden:(_Bool)arg1;
- (id)identifier:(id)arg1;
- (id)priority:(long long)arg1;
@end

@interface SBDashBoardViewControllerBase : UIViewController
- (void)registerView:(id)arg1 forRole:(long long)arg2;
- (void)unregisterView:(id)arg1;
@end

@interface SBDashBoardNotificationAdjunctListViewController : SBDashBoardViewControllerBase
@property(readonly, nonatomic, getter=isShowingMediaControls) _Bool showingMediaControls;
@end

@interface XENDashBoardWebViewController : SBDashBoardViewControllerBase
-(void)setWebView:(UIView*)view;
@end

@interface SBDashBoardPresentationViewController : SBDashBoardViewControllerBase
- (void)dismissContentViewController:(id)arg1 animated:(_Bool)arg2;
- (void)presentContentViewController:(id)arg1 animated:(_Bool)arg2;
@end

@interface SBDashBoardNotificationListViewController : SBDashBoardViewControllerBase
@property(readonly, nonatomic) _Bool hasContent;
@end

@interface SBDashBoardMainPageContentViewController : SBDashBoardPresentationViewController
@property(readonly, nonatomic, getter=isShowingMediaControls) _Bool showingMediaControls;
@property(readonly, nonatomic) SBDashBoardNotificationListViewController *notificationListViewController;
@property(readonly, copy, nonatomic) SBDashBoardBehavior *activeBehavior;
@end

@interface SBDashBoardMainPageViewController : SBDashBoardPageViewController
@property(readonly, nonatomic) SBDashBoardMainPageContentViewController *contentViewController;
@end

@interface SBDashBoardViewController : UIViewController
@property(nonatomic) unsigned long long lastSettledPageIndex;
-(unsigned long long)_indexOfMainPage;
@end

@interface UIGestureRecognizer (touch)
- (void)_touchesBegan:(NSSet*)touches withEvent:(UIEvent *)event;
- (void)_touchesMoved:(NSSet*)touches withEvent:(UIEvent *)event;
- (void)_touchesEnded:(NSSet*)touches withEvent:(UIEvent *)event;
- (void)_touchesCancelled:(NSSet*)touches withEvent:(UIEvent *)event;
@end

@interface UITouch (touch)
- (void)setView:(id)arg1;
- (void)set_xh_forwardingView:(id)view;
- (id)_xh_forwardingView;
@end

@interface SBFolderIconBackgroundView : UIView
@end

@interface SBIconLegibilityLabelView : UIView
@end

@interface SBMainDisplayLayoutState : NSObject
@property(readonly, nonatomic) long long unlockedEnvironmentMode;
@end

@interface SBWorkspaceApplicationSceneTransitionContext : NSObject
@property(readonly, nonatomic) SBMainDisplayLayoutState *layoutState;
@end

@interface SBMainWorkspaceTransitionRequest : NSObject
@property(copy, nonatomic) NSString *eventLabel;
@property(retain, nonatomic) SBWorkspaceApplicationSceneTransitionContext *applicationContext;
@end

@interface SBDashBoardCombinedListViewController : SBDashBoardViewControllerBase
@property(nonatomic, getter=isNotificationContentHidden) _Bool notificationContentHidden;
- (void)_updateListViewContentInset;
- (UIView*)notificationListScrollView;
@end

@interface SBIconScrollView : UIScrollView
@property (nonatomic) BOOL _xenhtml_isForegroundWidgetHoster;
-(void)_xenhtml_recievedSettingsUpdate;
@end

@interface SBIconListPageControl : UIPageControl
@property (nonatomic) BOOL _xenhtml_hidden;
@end

@interface SBRootFolderView : UIView
- (SBIconScrollView*)scrollView;
@property (nonatomic, strong) XENHButton *_xenhtml_addButton;
@property (nonatomic, strong) XENHTouchPassThroughView *_xenhtml_editingPlatter;
@property (nonatomic, strong) UIView *_xenhtml_editingVerticalIndicator;
@property(retain, nonatomic) UIView *pageControl;
-(CGRect)effectivePageControlFrame;

- (void)_xenhtml_layoutAddWidgetButton;
- (void)_xenhtml_layoutEditingPlatter;

- (void)_xenhtml_showVerticalEditingGuide;
- (void)_xenhtml_hideVerticalEditingGuide;

- (void)_xenhtml_recievedSettingsUpdate;
- (void)_xenhtml_setDockPositionIfNeeded;
- (void)_xenhtml_initialise;
- (id)dockView;
@end

@interface SBRootFolderController : UIViewController
@property (nonatomic,retain,readonly) SBRootFolderView *contentView;
@property(readonly, nonatomic) long long currentPageIndex;
@end

// iOS 11
@interface SBIconDragManager : NSObject
-(BOOL)isTrackingUserActiveIconDrags;
@end

@interface SBIconController : UIViewController
+ (instancetype)sharedInstance;
-(SBRootFolderController*)_rootFolderController;
-(id)rootIconListAtIndex:(long long)arg1;
-(BOOL)scrollToIconListAtIndex:(long long)arg1 animate:(BOOL)arg2;

@property(readonly, nonatomic) SBIconDragManager *iconDragManager; // iOS 11
- (id)grabbedIcon; // iOS 10
@end

@interface SBDockView : UIView
@end

static void hideForegroundForLSNotifIfNeeded();
static void showForegroundForLSNotifIfNeeded();

static void hideForegroundIfNeeded();
static void showForegroundIfNeeded();

void resetIdleTimer();
void cancelIdleTimer();

static XENHSetupWindow *setupWindow;

%group SpringBoard

static XENHWidgetLayerController *backgroundViewController = nil;
static XENHWidgetLayerController *foregroundViewController = nil;
static XENHWidgetLayerController *sbhtmlViewController = nil;
static XENHHomescreenForegroundViewController *sbhtmlForegroundViewController = nil;

static PHContainerView * __weak phContainerView;
static NSMutableArray *foregroundHiddenRequesters;
static XENHTouchForwardingRecognizer *lsBackgroundForwarder;
static XENHTouchForwardingRecognizer *sbhtmlForwardingGesture;
static BOOL iOS10ForegroundAddAttempted = NO;
static XENDashBoardWebViewController *iOS10ForegroundWrapperController;

static id dashBoardMainPageViewController;
static id dashBoardMainPageContentViewController;

static BOOL refuseToLoadDueToRehosting = NO;

#pragma mark Memory pressure handling

%hook SpringBoard

- (void)didReceiveMemoryWarning {
    // Notify widget layer managers of memory pressure
    [backgroundViewController didReceiveMemoryWarningExternal];
    [foregroundViewController didReceiveMemoryWarningExternal];
    [sbhtmlViewController didReceiveMemoryWarningExternal];
    [sbhtmlForegroundViewController didReceiveMemoryWarningExternal];
}

%end

#pragma mark Layout LS web views (iOS 9)

%hook SBLockScreenView

-(void)layoutSubviews {
    %orig;
    
    if ([XENHResources lsenabled]) {
        backgroundViewController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        foregroundViewController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    }
}

-(id)initWithFrame:(CGRect)frame {
    BOOL canRotate = [[[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenViewController] shouldAutorotate];
    
    int orientation = canRotate ? (int)[UIApplication sharedApplication].statusBarOrientation : 1;
    [XENHResources setCurrentOrientation:orientation];
    
    UIView *orig = %orig;
    
    if ([XENHResources lsenabled]) {
        // Add bottommost webview.
        if ([XENHResources widgetLayerHasContentForLocation:kLocationLSBackground]) {
            if (!backgroundViewController)
                backgroundViewController = [XENHResources widgetLayerControllerForLocation:kLocationLSBackground];
            else if (![XENHResources LSPersistentWidgets])
                [backgroundViewController reloadWidgets:NO];
            
            [orig insertSubview:backgroundViewController.view atIndex:0];
        }
    
        if ([XENHResources widgetLayerHasContentForLocation:kLocationLSForeground]) {
            if (!foregroundViewController)
                foregroundViewController = [XENHResources widgetLayerControllerForLocation:kLocationLSForeground];
            else if (![XENHResources LSPersistentWidgets])
                [foregroundViewController reloadWidgets:NO];
            
#if TARGET_IPHONE_SIMULATOR==0
            [MSHookIvar<UIView*>(orig, "_foregroundLockContentView") addSubview:foregroundViewController.view];
#endif
        }
    }
    
    return (SBLockScreenView*)orig;
}

%end

#pragma mark Layout LS web views (iOS 10+)

%hook SBDashBoardView

// This is called *every* lock event on iOS 10, and once per respring on iOS 11.
- (id)initWithFrame:(CGRect)arg1 {
    BOOL isiOS10 = [XENHResources isBelowiOSVersion:11 subversion:0] && [XENHResources isAtLeastiOSVersion:10 subversion:0];
    
    if (isiOS10) {
        // Make sure we initialise our UI with the right orientation.
        BOOL canRotate = [[[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenViewController] shouldAutorotate];
        
        int orientation = canRotate ? (int)[UIApplication sharedApplication].statusBarOrientation : 1;
        [XENHResources setCurrentOrientation:orientation];
    }
    
    SBDashBoardView *orig = %orig;
    
    XENlog(@"SBDashBoardView -initWithFrame:");
    
    if (isiOS10 && [XENHResources lsenabled]) {
        
        // Add bottommost webview.
        if ([XENHResources widgetLayerHasContentForLocation:kLocationLSBackground]) {
            if (!backgroundViewController)
                backgroundViewController = [XENHResources widgetLayerControllerForLocation:kLocationLSBackground];
            else if (![XENHResources LSPersistentWidgets])
                [backgroundViewController reloadWidgets:NO];
            
            [orig.backgroundView insertSubview:backgroundViewController.view atIndex:0];
        }
    }
    
    return (SBDashBoardView*)orig;
}

-(void)layoutSubviews {
    // Update orientation if needed.
    BOOL canRotate = [[[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenViewController] shouldAutorotate];
    
    int orientation = canRotate ? (int)[UIApplication sharedApplication].statusBarOrientation : 1;
    [XENHResources setCurrentOrientation:orientation];
    
    %orig;
    
    if ([XENHResources lsenabled]) {
        backgroundViewController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        foregroundViewController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        
        if (self.wallpaperEffectView) {
            // Check if we *really* need to insert the subview.
            int wallpaperIndex = (int)[self.slideableContentView.subviews indexOfObject:self.wallpaperEffectView];
            int backgroundControllerExpectedIndex = wallpaperIndex + 1;
            
            if (![[self.slideableContentView.subviews objectAtIndex:backgroundControllerExpectedIndex] isEqual:backgroundViewController.view])
                [self.slideableContentView insertSubview:backgroundViewController.view aboveSubview:self.wallpaperEffectView];
        } else if (![[self.slideableContentView.subviews objectAtIndex:0] isEqual:backgroundViewController.view]) {
            [self.slideableContentView insertSubview:backgroundViewController.view atIndex:0];
        }
    }
}

-(void)setMainPageView:(UIView*)view {
    %orig;
    
    BOOL isiOS10 = [XENHResources isBelowiOSVersion:11 subversion:0] && [XENHResources isAtLeastiOSVersion:10 subversion:0];
    
    // We ONLY want this to run on iOS 10.
    if (isiOS10) {
        if (!iOS10ForegroundAddAttempted && [XENHResources lsenabled]) {
            
            if ([XENHResources widgetLayerHasContentForLocation:kLocationLSForeground]) {
                if (!foregroundViewController)
                    foregroundViewController = [XENHResources widgetLayerControllerForLocation:kLocationLSForeground];
                else if (![XENHResources LSPersistentWidgets])
                    [foregroundViewController reloadWidgets:NO];
                
                // We now have the foreground view. We should add it to an instance of XENDashBoardWebViewController
                // and then feed that to the isolating controller to present.
                
                iOS10ForegroundWrapperController = [[objc_getClass("XENDashBoardWebViewController") alloc] init];
                [iOS10ForegroundWrapperController setWebView:foregroundViewController.view];
                
                // Feed to the isolating controller.
                if (dashBoardMainPageViewController) {
                    // iOS 10
                    [[(SBDashBoardMainPageViewController*)dashBoardMainPageViewController contentViewController] presentContentViewController:iOS10ForegroundWrapperController animated:NO];
                }
                
                hideForegroundForLSNotifIfNeeded();
            }
            
            iOS10ForegroundAddAttempted = YES;
        }
    }
}

- (void)viewControllerWillAppear {
    %orig;
    
    // On iOS 11, this is called whenever Dashboard is shown.
    // i.e., on lock and on NC display.
    
    // Alright; add background and foreground webviews to the LS!
    if ([XENHResources isAtLeastiOSVersion:11 subversion:0] && [XENHResources lsenabled]) {
        BOOL isLocked = [(SpringBoard*)[UIApplication sharedApplication] isLocked];
        
        // Make sure we initialise our UI with the right orientation.
        BOOL canRotate = [[[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenViewController] shouldAutorotate];
        
        int orientation = canRotate ? (int)[UIApplication sharedApplication].statusBarOrientation : 1;
        [XENHResources setCurrentOrientation:orientation];
        
        XENlog(@"Adding webviews to Dashboard if needed...");
        
        // Foreground HTML -> SBDashBoardMainPageContentViewController approach
        if ([XENHResources widgetLayerHasContentForLocation:kLocationLSForeground]) {
            if (!foregroundViewController)
                foregroundViewController = [XENHResources widgetLayerControllerForLocation:kLocationLSForeground];
            else if (![XENHResources LSPersistentWidgets])
                [foregroundViewController reloadWidgets:NO];
            else if ([XENHResources LSPersistentWidgets] && !isLocked) {
                [foregroundViewController setPaused:NO];
            }
            
            // We now have the foreground view. We should add it to an instance of XENDashBoardWebViewController
            // and then feed that to the isolating controller to present.
            
            if (!iOS10ForegroundWrapperController) {
                iOS10ForegroundWrapperController = [[objc_getClass("XENDashBoardWebViewController") alloc] init];
            }
            
            [iOS10ForegroundWrapperController setWebView:foregroundViewController.view];
            
            [dashBoardMainPageContentViewController presentContentViewController:iOS10ForegroundWrapperController animated:NO];
            
            BOOL canHideForeground = foregroundHiddenRequesters.count > 0;
            if (canHideForeground) {
                XENlog(@"Should hide foreground on LS webview init");
                hideForegroundIfNeeded();
            } else {
                XENlog(@"Should show foreground on LS webview init");
                showForegroundIfNeeded();
            }
        }
        
        // Now for the background.
        if ([XENHResources widgetLayerHasContentForLocation:kLocationLSBackground]) {
            if (!backgroundViewController)
                backgroundViewController = [XENHResources widgetLayerControllerForLocation:kLocationLSBackground];
            else if (![XENHResources LSPersistentWidgets])
                [backgroundViewController reloadWidgets:NO];
            else if ([XENHResources LSPersistentWidgets] && !isLocked) {
                [backgroundViewController setPaused:NO];
            }
            
            // Not using self.backgroundView now as that goes weird when swiping to the camera
            [self.slideableContentView insertSubview:backgroundViewController.view atIndex:0];
        }
    }
}

#pragma mark Fix background controller being hidden when going to the camera (iOS 11)

- (void)setWallpaperEffectView:(UIView*)wallpaperEffectView {
    %orig;
    
    if ([XENHResources isAtLeastiOSVersion:11 subversion:0] && [XENHResources lsenabled]) {
        if (wallpaperEffectView) {
            [self.slideableContentView insertSubview:backgroundViewController.view aboveSubview:wallpaperEffectView];
        } else {
            [self.slideableContentView insertSubview:backgroundViewController.view atIndex:0];
        }
    }
}

#pragma mark Destroy UI on unlock (iOS 11)

- (void)viewControllerDidDisappear {
    %orig;
    
    // On iOS 11, this is called whenever dashboard is hidden.
    if ([XENHResources isAtLeastiOSVersion:11 subversion:0] && [XENHResources lsenabled]) {
        
        if (![XENHResources LSPersistentWidgets]) {
            XENlog(@"Unloading background HTML if present...");
            [backgroundViewController unloadWidgets];
            [backgroundViewController.view removeFromSuperview];
            backgroundViewController = nil;
            
            XENlog(@"Unloading foreground HTML if present...");
            
            [foregroundViewController unloadWidgets];
            [foregroundViewController.view removeFromSuperview];
            foregroundViewController = nil;
        } else {
            XENlog(@"Unloading background HTML for persistent mode");
            [backgroundViewController.view removeFromSuperview];
            [backgroundViewController setPaused:YES];
            
            XENlog(@"Unloading foreground HTML for persistent mode");
            [foregroundViewController.view removeFromSuperview];
            [foregroundViewController setPaused:YES];
        }
        
        [XENHResources setHasSeenFirstUnlock:YES];
        
        if (iOS10ForegroundWrapperController) {
            
            [[(UIViewController*)iOS10ForegroundWrapperController view] removeFromSuperview];
            [(UIViewController*)iOS10ForegroundWrapperController removeFromParentViewController];
            
            iOS10ForegroundWrapperController = nil;
        }
        
        
        // Don't reset the hidden requesters on iOS 12 for weirdness reasons
        if ([XENHResources isBelowiOSVersion:11 subversion:0]) {
            [foregroundHiddenRequesters removeAllObjects];
            foregroundHiddenRequesters = nil;
        }
        
        lsBackgroundForwarder = nil;
    }
}

%end

#pragma mark Fix touch through to the LS notifications gesture. (iOS 11)

%hook SBDashBoardMainPageView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // This class is also in iOS 10.
    if ([XENHResources isBelowiOSVersion:11 subversion:0] || ![XENHResources lsenabled]) {
        return %orig;
    }
    
    UIView *orig = %orig;
    
    if (!foregroundViewController) {
        return orig;
    }
    
    UIView *outview = orig;
    
    if ([(UIView*)orig class] == objc_getClass("NCNotificationListCollectionView")) {
        // We allow scrolling/touching the widget in the lower 20% of the display if the user
        // has toggled ON Prioritise Touch in Widget, else prevent swiping to old notifications.
        
        if (![XENHResources LSWidgetScrollPriority] && point.y >= SCREEN_HEIGHT*0.81) {
            outview = orig;
        } else {
            outview = [iOS10ForegroundWrapperController.view hitTest:point withEvent:event];
        
            if (!outview)
                outview = orig;
        }
    }
    
    return outview;
    
    // _UIDragAutoScrollGestureRecognizer is what handles the pull-up gesture for notifications.
}

%end

#pragma mark Backing view controller for LS foreground webview. (iOS 10+)

%hook XENDashBoardWebViewController

- (long long)presentationTransition {
    return 1;
}

- (long long)presentationPriority {
    return 1; // notifications are 4, artwork is 2. Higher is greater priority.
}

- (long long)presentationType {
    // artwork is 2, notifications is 1. Fullscreen or not? Blur or not?
    return 1;
}

- (long long)scrollingStrategy {
    return 1; // Not sure, but this is what artwork uses.
}

/*
 * We were defining an SBDashBoardRegion. However, it appears Apple check whether any overlap,
 * and if any do, the higher priority one is the only one displayed.
 */

%new
-(void)setWebView:(UIView*)view {
    [self.view insertSubview:view atIndex:0];
    
    //[self registerView:self.webview forRole:1];
}

-(void)viewDidLayoutSubviews {
    %orig;
    
    for (UIView *view in self.view.subviews) {
        view.frame = self.view.bounds;
    }
}

%end

%hook SBDashBoardMainPageContentViewController

-(id)init {
    id orig = %orig;
    
    dashBoardMainPageContentViewController = orig;
    
    return orig;
}

%end

// Doesn't exist in iOS 11!
%hook SBDashBoardMainPageViewController

-(id)init {
    id orig = %orig;
    
    dashBoardMainPageViewController = orig;
    
    return orig;
}

#pragma mark Hide clock (iOS 10)

- (void)aggregateAppearance:(SBDashBoardAppearance*)arg1 {
    %orig;
    
    if ([XENHResources lsenabled] && [XENHResources _hideClock10] == 1) {
        SBDashBoardComponent *dateView = [[objc_getClass("SBDashBoardComponent") dateView] hidden:YES];
        [arg1 addComponent:dateView];
    }
}

%end

#pragma mark Hide clock (iOS 11+)

%hook SBDashBoardMainPageContentViewController

- (void)aggregateAppearance:(SBDashBoardAppearance*)arg1 {
    %orig;
    
    // This class is also in iOS 10.
    if ([XENHResources isBelowiOSVersion:11 subversion:0]) {
        return;
    }
    
    SBDashBoardComponent *dateView = nil;
    
    for (SBDashBoardComponent *component in arg1.components) {
        if (component.type == 1) {
            dateView = component;
            break;
        }
    }
    
    if ([XENHResources lsenabled] && [XENHResources _hideClock10] == 1) {
        dateView.hidden = YES;
    } else if (![XENHResources lsenabled] || [XENHResources _hideClock10] != 1) {
        dateView.hidden = NO;
    }
}

%end

#pragma Hide Torch and Camera (iOS 11+)

%hook SBDashBoardQuickActionsViewController

- (_Bool)hasCamera {
    if ([XENHResources lsenabled] && [XENHResources LSHideTorchAndCamera]) {
        return NO;
    }
    
    return %orig;
}

- (_Bool)hasFlashlight {
    if ([XENHResources lsenabled] && [XENHResources LSHideTorchAndCamera]) {
        return NO;
    }
    
    return %orig;
}

%end

#pragma mark Destroy UI on unlock (iOS 9)

%hook SBLockScreenViewController

-(void)_releaseLockScreenView {
    // Moved %orig; to the bottom, in an attempt to resolve a crash occuring when the user unlocks, and
    // iOS runs -[SBLockScreenNotificationListController _updateModelForRemovalOfItem:updateView:].
    // This was leading to a crash -> an object referenced there was deallocated without being set to nil,
    // giving some pretty odd crashes when calling setAlpha: on it.
    
    if ([XENHResources lsenabled]) {
        if (![XENHResources LSPersistentWidgets]) {
            XENlog(@"Unloading background HTML");
            [backgroundViewController unloadWidgets];
            [backgroundViewController.view removeFromSuperview];
            backgroundViewController = nil;
            
             XENlog(@"Unloading foreground HTML");
            [foregroundViewController unloadWidgets];
            [foregroundViewController.view removeFromSuperview];
            foregroundViewController = nil;
        } else {
            XENlog(@"Unloading background HTML for persistent mode");
            [backgroundViewController.view removeFromSuperview];
            [backgroundViewController setPaused:YES];
            
            XENlog(@"Unloading foreground HTML for persistent mode");
            [foregroundViewController.view removeFromSuperview];
            [foregroundViewController setPaused:YES];
        }
        
        [foregroundHiddenRequesters removeAllObjects];
        foregroundHiddenRequesters = nil;
        
        lsBackgroundForwarder = nil;
        
        [XENHResources setHasSeenFirstUnlock:YES];
    }
    
    %orig;
}

%end

#pragma mark Destroy UI on unlock (iOS 10)

/*
 * We were destroying the UI in -deactivate, but the problem with this approach is that this is called
 * when things like the power down UI are shown, and thus is not suitable for this.
 *
 * In addition, we need to be unloading our resources AFTER the containing SBAlertWindow has fully 
 * deallocated. Otherwise, when -resignFirstResponder is called to the underlying WKContentView,
 * we will hit a SIGSEGV due to its _webView iVar being undefined.
 */

%hook SBDashBoardViewController

- (void)displayDidDisappear {
    BOOL isiOS10 = [XENHResources isBelowiOSVersion:11 subversion:0] && [XENHResources isAtLeastiOSVersion:10 subversion:0];
    
    if (isiOS10 && [XENHResources lsenabled]) {
        if (![XENHResources LSPersistentWidgets]) {
            XENlog(@"Unloading background HTML");
            [backgroundViewController unloadWidgets];
            [backgroundViewController.view removeFromSuperview];
            backgroundViewController = nil;
        } else {
            XENlog(@"Unloading background HTML for persistent mode");
            [backgroundViewController.view removeFromSuperview];
            [backgroundViewController setPaused:YES];
        }
        
        if (iOS10ForegroundWrapperController) {
            [[(SBDashBoardMainPageViewController*)dashBoardMainPageViewController contentViewController] dismissContentViewController:iOS10ForegroundWrapperController animated:NO];
            
            [[(UIViewController*)iOS10ForegroundWrapperController view] removeFromSuperview];
            [(UIViewController*)iOS10ForegroundWrapperController removeFromParentViewController];
            
            iOS10ForegroundWrapperController = nil;
        }
        
        if (![XENHResources LSPersistentWidgets]) {
            XENlog(@"Unloading foreground HTML");
            [foregroundViewController unloadWidgets];
            [foregroundViewController.view removeFromSuperview];
            foregroundViewController = nil;
        } else {
            XENlog(@"Unloading foreground HTML for persistent mode");
            [foregroundViewController.view removeFromSuperview];
            [foregroundViewController setPaused:YES];
        }
        
        [foregroundHiddenRequesters removeAllObjects];
        foregroundHiddenRequesters = nil;
        
        lsBackgroundForwarder = nil;
        
        iOS10ForegroundAddAttempted = NO;
        
        [XENHResources setHasSeenFirstUnlock:YES];
    }
    
    %orig;
}

%end

#pragma mark Handle orientation (iOS 9)

%hook SBLockScreenViewController

- (void)willRotateToInterfaceOrientation:(int)interfaceOrientation duration:(double)duration {
    %orig;
    
    if ([XENHResources lsenabled]) {
        [XENHResources setCurrentOrientation:interfaceOrientation];
    
        [UIView animateWithDuration:duration animations:^{
            [backgroundViewController rotateToOrientation:interfaceOrientation];
            [foregroundViewController rotateToOrientation:interfaceOrientation];
        }];
    }
}

%end

#pragma mark Handle orientation (iOS 10+)

%hook SBDashBoardViewController

- (void)viewWillTransitionToSize:(CGSize)arg1 withTransitionCoordinator:(id)arg2 {
    %orig;
    
    [arg2 animateAlongsideTransition:^(id  _Nonnull context) {
        
        if ([XENHResources lsenabled]) {
            // In reality, our UI only cares if it is landscape or portrait. The type for each doesn't
            // matter. Therefore, we can do:
            
            int orientation = 1; // Portrait.
            if (arg1.width == SCREEN_MAX_LENGTH) {
                orientation = 3;
            }
            
            [XENHResources setCurrentOrientation:orientation];
            
            [backgroundViewController rotateToOrientation:orientation];
            [foregroundViewController rotateToOrientation:orientation];
            
            backgroundViewController.view.frame = CGRectMake(0, 0, arg1.width, arg1.height);
            foregroundViewController.view.frame = CGRectMake(0, 0, arg1.width, arg1.height);
        }
        
    } completion:^(id  _Nonnull context) {

    }];
}

%end

#pragma mark Handle issues with notifications list view (iOS 9)

%hook SBLockScreenNotificationListController

%new
-(NSArray*)_xenhtml_listItems {
#if TARGET_IPHONE_SIMULATOR==0
    return MSHookIvar<NSMutableArray*>(self, "_listItems");
#else
    return nil;
#endif
}

%end

static BOOL allowNotificationViewTouchForIsGrouped() {
    // if Xen/Priority Hub installed, allow touch when notifs present due to being minimised.
    // Return YES for grouping doesn't exist or isn't minimised
    // Return NO is currently minimised
    
    // Priority Hub handles itself
    
    if ([XENHResources xenInstalledAndGroupingIsMinimised]) {
        return NO;
    }
    
    return YES;
}

%hook SBLockScreenNotificationListView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *orig = %orig;
    
    if (![XENHResources lsenabled]) {
        return orig;
    }
    
    if ([self.delegate _xenhtml_listItems].count > 0) {
        return (allowNotificationViewTouchForIsGrouped() ? orig : nil);
    } else {
        return nil;
    }
}

%end

#pragma mark Prevent touches cancelling when scrolling on-widget (iOS 10+)

%hook SBHorizontalScrollFailureRecognizer

- (_Bool)_isOutOfBounds:(struct CGPoint)arg1 forAngle:(double)arg2 {
    return foregroundViewController != nil ? NO : %orig;
}

%end

%hook SBPagedScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    BOOL orig = %orig;
    
    if ([XENHResources lsenabled] && foregroundViewController) {
        // Either touches will be "stolen" more by the scroll view, or by the widget.
        if ([XENHResources LSWidgetScrollPriority]) {
            SBDashBoardViewController *cont = [[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenViewController];
            BOOL onMainPage = cont.lastSettledPageIndex == [cont _indexOfMainPage];
        
            if (onMainPage) {
                return NO;
            }
        } else {
            // Here, we should check whether the foreground LS widget is handling a touch. If so, no cancelling is
            // allowed.
            
            if ([foregroundViewController isAnyWidgetTrackingTouch]) {
                return NO;
            }
        }
    }
    
    return orig;
}

%end

#pragma mark Hide clock (iOS 9+)

%hook SBFLockScreenDateView

-(void)layoutSubviews {
    %orig;
    
    if ([XENHResources isAtLeastiOSVersion:10 subversion:0]) {
        if ([XENHResources lsenabled] && [XENHResources _hideClock10] == 2) {
            self.hidden = YES;
        }
        return;
    }
    
    if ([XENHResources lsenabled] && [XENHResources hideClock]) {
        self.hidden = YES;
    }
}

-(void)setHidden:(BOOL)hidden {
    if ([XENHResources isAtLeastiOSVersion:10 subversion:0]) {
        ([XENHResources lsenabled] && [XENHResources _hideClock10] == 2 ? %orig(YES) : %orig);
    } else {
        ([XENHResources lsenabled] && [XENHResources hideClock] ? %orig(YES) : %orig);
    }
}

%end

// Not needed on iOS 10.

%hook SBLockScreenViewController
 
-(BOOL)_shouldShowChargingText {
    if ([XENHResources lsenabled] && [XENHResources hideClock]) {
        return NO;
    } else {
        return %orig;
    }
}
 
%end

/*
 * On iOS 10, some behaviour has changed on the lockscreen. For example:
 * - The media player will never be off-screen if added at any point
 * - Notifications are not transparent
 * - There are no CC/NC/Camera grabbers any longer
 *
 * Thus, some settings need to be axed to compensate.
 */

#pragma mark Same sized status bar (iOS 9)

%hook SBLockScreenViewController

-(int)statusBarStyle {
    return [XENHResources lsenabled] && [XENHResources useSameSizedStatusBar] ? 0 : %orig;
}

#pragma mark Hide LS status bar (iOS 9)

- (_Bool)showsSpringBoardStatusBar {
    return [XENHResources lsenabled] && [XENHResources hideStatusBar] ? NO : %orig;
}

- (CGFloat)_effectiveVisibleStatusBarAlpha {
    return [XENHResources lsenabled] && [XENHResources hideStatusBar] ? 0.0 : %orig;
}

%end

#pragma mark Same sized status bar (iOS 10+)

%hook SBDashBoardViewController

- (long long)statusBarStyle {
    return [XENHResources lsenabled] && [XENHResources useSameSizedStatusBar] ? 0 : %orig;
}

%end

#pragma mark Hide LS status bar (iOS 10+)

%hook SBDashBoardPageViewController

-(void)aggregateAppearance:(SBDashBoardAppearance*)arg1 {
    %orig;
    
    // Slide statusBar with the lockscreen when presenting page. (needs confirmation)
    if ([XENHResources lsenabled] && [XENHResources hideStatusBar]) {
        SBDashBoardComponent *statusBar = [[objc_getClass("SBDashBoardComponent") statusBar] hidden:YES];
        [arg1 addComponent:statusBar];
    }
}

%end

#pragma mark Clock in status bar (iOS 9)

%hook SBLockScreenViewController

- (_Bool)wantsToShowStatusBarTime {
    return [XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled] ? YES : %orig;
}

- (_Bool)shouldShowLockStatusBarTime {
    return [XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled] ? YES : %orig;
}

%end

#pragma mark Clock in status bar (iOS 10+)

%hook SBDashBoardViewController

- (_Bool)wantsTimeInStatusBar {
    BOOL onMainPage = self.lastSettledPageIndex == [self _indexOfMainPage];
    if ([XENHResources lsenabled] && [XENHResources _hideClock10] == 1 && ![XENHResources LSShowClockInStatusBar] && onMainPage) {
        return NO;
    }
    
    return [XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled] ? YES : %orig;
}

- (_Bool)shouldShowLockStatusBarTime {
    BOOL onMainPage = self.lastSettledPageIndex == [self _indexOfMainPage];
    if ([XENHResources lsenabled] && [XENHResources _hideClock10] == 1 && ![XENHResources LSShowClockInStatusBar] && onMainPage) {
        return NO;
    }
    
    return [XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled] ? YES : %orig;
}

%end

#pragma mark Clock in status bar (iOS 11 fixes)

/*
 * The status bar time is *always* enabled except for the case of the Lockscreen, where DashBoard overrides it.
 * For whatever reason, our Dashboard overrides are not working as expected. Therefore, we override here for iOS 11.
 */
%hook SBMainStatusBarStateProvider

- (void)setTimeCloaked:(_Bool)arg1 {
    if ([XENHResources isBelowiOSVersion:11 subversion:0]) {
        %orig(arg1);
        return;
    }
    
    if ([XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled]) {
        %orig(NO);
    } else {
        %orig(arg1);
    }
}

- (void)enableTime:(_Bool)arg1 crossfade:(_Bool)arg2 crossfadeDuration:(double)arg3 {
    if ([XENHResources isBelowiOSVersion:11 subversion:0]) {
        %orig(arg1, arg2, arg3);
        return;
    }
    
    if ([XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled]) {
        %orig(YES, arg2, arg3);
    } else {
        %orig(arg1, arg2, arg3);
    }
}

- (void)enableTime:(_Bool)arg1 {
    if ([XENHResources isBelowiOSVersion:11 subversion:0]) {
        %orig(arg1);
        return;
    }
    
    if ([XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled]) {
        %orig(YES);
    } else {
        %orig(arg1);
    }
}

- (_Bool)isTimeEnabled {
    if ([XENHResources isBelowiOSVersion:11 subversion:0]) {
        return %orig;
    }
    
    if ([XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled]) {
        return YES;
    } else {
        return %orig;
    }
}

%end

#pragma mark Ensure to always reset idle timer when we see touches in the LS (iOS 9+)

void resetIdleTimer() {
    if ([XENHResources isBelowiOSVersion:11 subversion:0]) {
        [(SBBacklightController*)[objc_getClass("SBBacklightController") sharedInstance] resetLockScreenIdleTimer];
    } else {
        // Idle timer handling has changed in iOS 11 (really?!)
        [(SBIdleTimerGlobalCoordinator*)[objc_getClass("SBIdleTimerGlobalCoordinator") sharedInstance] resetIdleTimer];
    }
}

void cancelIdleTimer() {
    if ([XENHResources isBelowiOSVersion:11 subversion:0]) {
        [(SBBacklightController*)[objc_getClass("SBBacklightController") sharedInstance] cancelLockScreenIdleTimer];
    } else {
        // Since cancelling the idle timer no longer is easy on iOS 11, we just reset it since user interaction won't
        // take a tremendous amount of time!
        resetIdleTimer();
    }
}

// iOS 9 and 10
%hook SBAlertWindow

- (void)sendEvent:(UIEvent *)event {
    // Don't run on iOS 11
    if ([XENHResources isAtLeastiOSVersion:11 subversion:0]) {
        %orig;
        return;
    }
    
    // Handle the screen idle timer when locked upon user interaction.
    if ([[objc_getClass("SBLockScreenManager") sharedInstance] isUILocked]) {
        UITouch *touch = [event.allTouches anyObject];
        if (touch.phase == UITouchPhaseBegan) {
            cancelIdleTimer();
        } else if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
            resetIdleTimer();
        }
    }
    
    %orig;
}

%end

// iOS 11
%hook SBCoverSheetWindow

- (void)sendEvent:(UIEvent *)event {
    
    // Handle the screen idle timer when locked upon user interaction.
    if ([[objc_getClass("SBLockScreenManager") sharedInstance] isUILocked]) {
        UITouch *touch = [event.allTouches anyObject];
        if (touch.phase == UITouchPhaseBegan) {
            cancelIdleTimer();
        } else if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
            resetIdleTimer();
        }
    }
    
    %orig;
}

%end

#pragma mark Hide STU view if necessary (iOS 9)

%hook SBLockScreenView

-(void)_layoutSlideToUnlockView {
    if ([XENHResources lsenabled] && [XENHResources hideSTU]) {
        return;
    }
    
    %orig;
}

%end

#pragma mark Hide STU view if necessary (iOS 10)

%hook SBUICallToActionLabel

- (void)setText:(id)arg1 forLanguage:(id)arg2 animated:(BOOL)arg3 {
    if ([XENHResources lsenabled] && [XENHResources hideSTU]) {
        %orig(@"", arg2, arg3);
    } else {
        %orig;
    }
}

%end

#pragma mark Hide STU view if necessary (iOS 11) and...
#pragma mark Hide Home Bar (iOS 11 + iPhone X) and...
#pragma mark Hide D22 Control Centre grabber (iOS 11 + iPhone X)

%hook SBDashBoardTeachableMomentsContainerView

- (void)layoutSubviews {
    %orig;
    
#if TARGET_IPHONE_SIMULATOR==0
    UIView *calltoaction = MSHookIvar<UIView*>(self, "_callToActionLabelContainerView");
    calltoaction.hidden = [XENHResources lsenabled] && [XENHResources hideSTU];
    
    UIView *homebar = MSHookIvar<UIView*>(self, "_homeAffordanceContainerView");
    homebar.hidden = [XENHResources lsenabled] && [XENHResources LSHideHomeBar];
    
    if ([XENHResources isAtLeastiOSVersion:11 subversion:2]) {
        UIView *grabber = MSHookIvar<UIView*>(self, "_controlCenterGrabberView");
        grabber.hidden = [XENHResources lsenabled] && [XENHResources LSHideD22CCGrabber];
    }
#endif
}

%end

#pragma mark Hide Face ID padlock (iOS 11 + iPhone X)

%hook SBUIProudLockIconView

- (void)setState:(NSInteger)state animated:(BOOL)animated options:(NSInteger)options completion:(id)completion {
    %orig;
    
    // States
    // 0 - locked with screen off
    // 1 - locked with screen on
    // 2 - Unlocked
    // 5 - animating!
    
    switch ([self state]) {
        case 5:
            self.hidden = NO;
            break;
        default:
            self.hidden = [XENHResources lsenabled] && [XENHResources LSHideFaceIDPadlock];
            break;
    }
}

- (void)layoutSubviews {
    %orig;
    
    switch ([self state]) {
        case 0:
        case 1:
        case 2:
            self.hidden = [XENHResources lsenabled] && [XENHResources LSHideFaceIDPadlock];
            break;
        default:
            self.hidden = NO;
    }
}

%end

#pragma mark Fix "bounce" when tapping (iOS 9.0 - 9.3)

%hook SBLockScreenViewController

- (BOOL)isBounceEnabledForPresentingController:(id)fp8 locationInWindow:(CGPoint)fp12 {
    return ([XENHResources lsenabled] ? NO : %orig);
}

%end

%hook SBLockScreenBounceAnimator

- (void)_handleTapGesture:(id)arg1 {
    //Do not handle tap gesture
    if (![XENHResources lsenabled]) {
        %orig;
    }
}

%end

#pragma mark Disable camera (iOS 9.0 - 9.3)

%hook SBLockScreenViewController

-(void)_addCameraGrabberIfNecessary {
    if ([XENHResources lsenabled] && [XENHResources disableCameraGrabber]) {
        return;
    }
    
    %orig;
}

%end

#pragma mark Hide camera (and Handoff) grabbers (iOS 9)

%hook SBLockScreenView

- (void)_layoutBottomLeftGrabberView {
    %orig;
    
    if ([XENHResources lsenabled] && [XENHResources hideCameraGrabber]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *grabber = MSHookIvar<UIView*>(self, "_bottomLeftGrabberView");
        grabber.hidden = YES;
        grabber.userInteractionEnabled = YES;
#endif
    }
}

- (void)_layoutCameraGrabberView {
    %orig;
    
    if ([XENHResources lsenabled] && [XENHResources hideCameraGrabber]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *grabber = MSHookIvar<UIView*>(self, "_cameraGrabberView");
        grabber.hidden = YES;
        grabber.userInteractionEnabled = YES;
#endif
    }
}

%end

#pragma mark Hide Handoff grabber (iOS 10)

%hook SBDashBoardMainPageView

- (void)_layoutSlideUpAppGrabberView {
    %orig;
    
    if ([XENHResources lsenabled] && [XENHResources hideCameraGrabber]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *grabber = MSHookIvar<UIView*>(self, "_slideUpAppGrabberView");
        grabber.hidden = YES;
        grabber.userInteractionEnabled = YES;
#endif
    } else {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *grabber = MSHookIvar<UIView*>(self, "_slideUpAppGrabberView");
        grabber.hidden = NO;
        grabber.userInteractionEnabled = YES;
#endif
    }
}

%end

#pragma mark Hide page control dots (iOS 11)

%hook SBDashBoardFixedFooterView

- (void)_layoutPageControl {
    %orig;
    
    if ([XENHResources lsenabled] && [XENHResources hidePageControlDots]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *control = MSHookIvar<UIView*>(self, "_pageControl");
        control.hidden = YES;
        control.userInteractionEnabled = NO;
#endif
    } else {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *control = MSHookIvar<UIView*>(self, "_pageControl");
        control.hidden = NO;
        control.userInteractionEnabled = NO;
#endif
    }
}

%end

#pragma mark Hide page control dots (iOS 10)

%hook SBDashBoardView

- (void)_layoutPageControl {
    %orig;
    
    if ([XENHResources lsenabled] && [XENHResources hidePageControlDots]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *control = MSHookIvar<UIView*>(self, "_pageControl");
        control.hidden = YES;
        control.userInteractionEnabled = NO;
#endif
    }
}

%end

#pragma mark Hide top/bottom grabbers (iOS 9.0 - 9.3)

%hook SBLockScreenView

- (void)_layoutGrabberView:(UIView*)view atTop:(BOOL)top {
    if (!top && [XENHResources lsenabled] && [XENHResources hideBottomGrabber]) {
        view.hidden = YES;
        view.alpha = 0.0;
    } else if (top && [XENHResources lsenabled] && [XENHResources hideTopGrabber]) {
        view.hidden = YES;
        view.alpha = 0.0;
    } else {
        %orig;
    }
}

%end

#pragma mark Fix being unable to tap things like notifications (9.3 only)

%hook SBLockScreenViewController

-(void)_addDeviceInformationTextView {
    %orig;
    
    // Disable touches goddamit.
#if TARGET_IPHONE_SIMULATOR==0
    UIViewController *infoViewController = MSHookIvar<UIViewController*>(self, "_deviceInformationTextViewController");
    infoViewController.view.userInteractionEnabled = NO;
#endif
}

%end

#pragma mark Lockscreen dim duration adjustments (iOS 9)

%hook SBBacklightController

- (double)defaultLockScreenDimInterval {
    return ([XENHResources lsenabled] ? [XENHResources lockScreenIdleTime] : %orig);
}

- (double)defaultLockScreenDimIntervalWhenNotificationsPresent {
    return ([XENHResources lsenabled] ? [XENHResources lockScreenIdleTime] : %orig);
}

%end

#pragma mark Lockscreen dim duration adjustments (iOS 10)

%hook SBManualIdleTimer

- (id)initWithInterval:(double)arg1 userEventInterface:(id)arg2 {
    if ([XENHResources lsenabled]) {
        arg1 = [XENHResources lockScreenIdleTime];
    }
    
    if (setupWindow || ![XENHResources hasDisplayedSetupUI]) {
        arg1 = 1000;
    }
    
    return %orig(arg1, arg2);
}

%end

#pragma mark Lockscreen dim duration adjustments (iOS 11+)

%hook SBIdleTimerDefaults

- (void)_bindAndRegisterDefaults {
    %orig;
    
    /*
     * Now this was an interesting one to figure out.
     *
     * As part of the implementation of this method, Apple goes and binds
     * a default value to the various properties this class presents.
     *
     * When hooking minimumLockscreenIdleTime directly, this binding
     * has the effect of overwriting the newly hooked method with a singular
     * value, but only with Substrate. Substitute happily ignores this, and still
     * ensures any call to minimumLockscreenIdleTime is handled by the hooked version.
     *
     * To get around this, I'm using some ObjC swizzling to point at my "hooked" function
     * when the binding is done with at runtime.
     */
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clazz = objc_getClass("SBIdleTimerDefaults");
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        SEL originalSelector = @selector(minimumLockscreenIdleTime);
        SEL swizzledSelector = @selector(_xenhtml_minimumLockscreenIdleTime);
#pragma clang diagnostic pop
        
        Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(clazz, swizzledSelector);
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

%new
-(CGFloat)_xenhtml_minimumLockscreenIdleTime {
    // This is iOS 11 onwards
    if ([XENHResources isBelowiOSVersion:11 subversion:0]) {
        return 0;
    }
    
    if ([XENHResources lsenabled]) {
        return [XENHResources lockScreenIdleTime];
    }
    
    if (setupWindow || ![XENHResources hasDisplayedSetupUI]) {
        return 1000;
    }
    
    return 0;
}

%end

#pragma mark Hide SBHTML when locked.

%hook SBLockScreenManager

- (void)_setUILocked:(_Bool)arg1 {
    %orig;

    if (sbhtmlViewController)
        [sbhtmlViewController setPaused:arg1];
    if (sbhtmlForegroundViewController)
        [sbhtmlForegroundViewController setPaused:arg1];
}

%end

#pragma mark Hide SBHTML when in-app

%hook SBMainWorkspace

- (void)applicationProcessDidExit:(id)arg1 withContext:(id)arg2 {
    // Here, we will handle when an app crashes, or closes. We will assume going back to the homescreen.
    // Furthermore, it can be assumed that SBHTML will be visible already if quit from the switcher.
    
    XENlog(@"Showing SBHTML due to application exit, and the assumption that we will progress to the homescreen");
    [sbhtmlViewController setPaused:NO];
    [sbhtmlForegroundViewController setPaused:NO];
    
    [sbhtmlViewController doJITWidgetLoadIfNecessary];
    [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
    
    %orig;
}

- (void)process:(id)arg1 stateDidChangeFromState:(FBProcessState*)arg2 toState:(FBProcessState*)arg3 {
    // When changed to state visibility Foreground, we can hide SBHTML.
    // In addition, we also do vice-versa to handle any potential issues as a failsafe.
    
    // First, handle background -> foreground.
    if (![arg2 isForeground] && [arg3 isForeground]) {
        
        // CHECKME: When launching an app, this functions but causes the widget to disappear BEFORE the application zoom-up is done.
        // CHECMKE: When launching an app thats backgrounded, this doesn't cause the widget to disappear...
        
        XENlog(@"Hiding SBHTML due to an application becoming foreground (failsafe).");
        [sbhtmlViewController setPaused:YES animated:YES];
        [sbhtmlForegroundViewController setPaused:YES animated:YES];
    // And now, handle the reverse as a failsafe.
    } else if ([arg2 isForeground] && ![arg3 isForeground]) {
        
        // ONLY show SBHTML again if we're actually heading to SpringBoard
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            BOOL isSpringBoardForeground = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication] == nil;
            
            if (isSpringBoardForeground) {
                XENlog(@"Showing SBHTML due to an application leaving foregound (failsafe).");
                [sbhtmlViewController setPaused:NO];
                [sbhtmlForegroundViewController setPaused:NO];
                
                [sbhtmlViewController doJITWidgetLoadIfNecessary];
                [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
            }
        });
    }
    
    %orig;
}

%end

// Next, handle precisely the moment the home button is clicked when in-app and not locked.
%hook SBApplication

// CHECKME: This is missing on iOS 10.
- (void)willAnimateDeactivation:(_Bool)arg1 {
    XENlog(@"Showing SBHTML due to an application animating deactivation");
    [sbhtmlViewController setPaused:NO];
    [sbhtmlForegroundViewController setPaused:NO];
    
    [sbhtmlViewController doJITWidgetLoadIfNecessary];
    [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
    
    %orig;
}

%end

// Also, we need to hook the opening of the switcher. If we switch to another application, we can catch that in SBMainWorkspace.

%hook SBUIController // This is for < 9.2

-(void)_activateSwitcher {
    XENlog(@"Showing SBHTML due to opening the Application Switcher");
    [sbhtmlViewController setPaused:NO];
    [sbhtmlForegroundViewController setPaused:NO];
    
    [sbhtmlViewController doJITWidgetLoadIfNecessary];
    [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
    
    %orig;
}

%end

%hook SBMainSwitcherViewController

- (void)performPresentationAnimationForTransitionRequest:(id)arg1 withCompletion:(id)arg2 {
    XENlog(@"Showing SBHTML due to opening the Application Switcher");
    [sbhtmlViewController setPaused:NO];
    [sbhtmlForegroundViewController setPaused:NO];
    
    [sbhtmlViewController doJITWidgetLoadIfNecessary];
    [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
    
    %orig;
}

%end

// iOS 11

%hook SBMainWorkspace

- (_Bool)_preflightTransitionRequest:(SBMainWorkspaceTransitionRequest*)arg1 {
    
    // We use the unlockedEnvironmentMode to define what to do!
    // There is: home-screen, app-switcher, and application
    
    // This class is also in iOS 10, and we don't want to do anything when locked.
    if ([XENHResources isBelowiOSVersion:11 subversion:0] || [[objc_getClass("SBLockScreenManager") sharedInstance] isUILocked]) {
        return %orig;
    }
    
    long long environmentMode = arg1.applicationContext.layoutState.unlockedEnvironmentMode;
    
    // 1 - homescreen
    // 2 - switcher
    // 3 - app
    
    switch (environmentMode) {
        case 1:
            XENlog(@"Showing SBHTML due to transitioning to the Homescreen (SBMainWorkspace)");
            
            [sbhtmlViewController setPaused:NO];
            [sbhtmlForegroundViewController setPaused:NO];
            
            [sbhtmlViewController doJITWidgetLoadIfNecessary];
            [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
            
            break;
        case 2:
            XENlog(@"Showing SBHTML due to opening the Application Switcher (SBMainWorkspace)");
            
            [sbhtmlViewController setPaused:NO];
            [sbhtmlForegroundViewController setPaused:NO];
            
            [sbhtmlViewController doJITWidgetLoadIfNecessary];
            [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
            
            break;
    }
    
    return %orig;
}

%end

// Handle the home bar of d22 and friends
// We only need to hook when a gesture starts, as our failsafe for hiding in SBMainWorkspace
// will kick in as expected once an application starts

%hook SBFluidSwitcherGestureWorkspaceTransaction

- (void)_beginWithGesture:(id)arg1 {
    XENlog(@"Showing SBHTML due to starting a fluid gesture");
    [sbhtmlViewController setPaused:NO];
    [sbhtmlForegroundViewController setPaused:NO];
    
    [sbhtmlViewController doJITWidgetLoadIfNecessary];
    [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
    
    %orig;
}

%end

#pragma mark Hide LockHTML when the display is off. (iOS 9)

%hook SBLockScreenViewController

-(void)_handleDisplayTurnedOff {
    %orig;
    
    // In a phone call, this code *is* run.
    // Now, with the function below in conjunction, we end up with a problem.
    // Therefore, don't run this when in a phone call or FaceTime.
    BOOL inCall = [[objc_getClass("SBTelephonyManager") sharedTelephonyManager] inCall];
    BOOL inFaceTime = [[objc_getClass("SBConferenceManager") sharedInstance] inFaceTime];
    if ([XENHResources LSUseBatteryManagement] && !inCall && !inFaceTime) {
        XENlog(@"Hiding Lockscreen HTML due to display turning off.");
        
        [foregroundViewController setPaused:YES];
        [backgroundViewController setPaused:YES];
        
        [XENHResources setDisplayState:NO]; // OFF
    }
}

// When in a phone call, this code is not run.
- (void)_handleDisplayTurnedOnWhileUILocked:(id)locked {
    if ([XENHResources LSUseBatteryManagement]) {
        XENlog(@"Showing Lockscreen HTML due to display turning on.");
        
        [foregroundViewController setPaused:NO];
        [backgroundViewController setPaused:NO];
        
        [XENHResources setDisplayState:YES]; // ON
    }
    
    [foregroundViewController doJITWidgetLoadIfNecessary];
    [backgroundViewController doJITWidgetLoadIfNecessary];
    
    %orig;
}

%end

#pragma mark Hide LockHTML when the display is off. (iOS 10)

%hook SBLockScreenManager

- (void)_handleBacklightLevelChanged:(NSNotification*)arg1 {
    %orig;
    
    if ([XENHResources isAtLeastiOSVersion:10 subversion:0] && [XENHResources lsenabled]) {
        NSDictionary *userInfo = arg1.userInfo;
        
        CGFloat newBacklight = [[userInfo objectForKey:@"SBBacklightNewFactorKey"] floatValue];
        CGFloat oldBacklight = [[userInfo objectForKey:@"SBBacklightOldFactorKey"] floatValue];
        
        XENlog(@"CHANGING BACKLIGHT! New %f, old %f", newBacklight, oldBacklight);
        
        if (newBacklight == 0.0) {
            // In a phone call, this code *is* run.
            // Now, with the function below in conjunction, we end up with a problem.
            // Therefore, don't run this when in a phone call or FaceTime.
            BOOL inCall = [[objc_getClass("SBTelephonyManager") sharedTelephonyManager] inCall];
            BOOL inFaceTime = [[objc_getClass("SBConferenceManager") sharedInstance] inFaceTime];
            if ([XENHResources LSUseBatteryManagement] && !inCall && !inFaceTime) {
                
                // This is needed since we have this hook called BEFORE the display finishes animating off.
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    // Only call if we are still actually off right now.
                    if (![[objc_getClass("SBBacklightController") sharedInstance] screenIsOn]) {
                        XENlog(@"Hiding Lockscreen HTML due to display turning off.");
                        
                        [foregroundViewController setPaused:YES];
                        [backgroundViewController setPaused:YES];
                        
                        [XENHResources setDisplayState:NO]; // OFF
                    }
                });
            }
        } else if (oldBacklight == 0.0 && newBacklight > 0.0) {
            if ([XENHResources LSUseBatteryManagement]) {
                XENlog(@"Showing Lockscreen HTML due to display turning on.");
                
                [foregroundViewController setPaused:NO];
                [backgroundViewController setPaused:NO];
                
                [XENHResources setDisplayState:YES]; // ON
            }
            
            [foregroundViewController doJITWidgetLoadIfNecessary];
            [backgroundViewController doJITWidgetLoadIfNecessary];
        }
    }
}

%end

#pragma mark Hide LockHTML when the display is off. (iOS 11)

%hook SBScreenWakeAnimationController

- (void)_handleAnimationCompletionIfNecessaryForWaking:(_Bool)wokeLS {
    if (!wokeLS && [XENHResources LSUseBatteryManagement]) {
        // User just slept the device
        XENlog(@"Hiding Lockscreen HTML due to display turning off.");
        
        [foregroundViewController setPaused:YES];
        [backgroundViewController setPaused:YES];
        
        [XENHResources setDisplayState:NO]; // OFF
    }
    
    %orig;
}

- (void)_startWakeAnimationsForWaking:(_Bool)arg1 animationSettings:(id)arg2 {
    if (arg1 && [XENHResources LSUseBatteryManagement]) {
        XENlog(@"Showing Lockscreen HTML due to display turning on.");
        
        [foregroundViewController setPaused:NO];
        [backgroundViewController setPaused:NO];
        
        [XENHResources setDisplayState:YES]; // ON
    }
    
    [foregroundViewController doJITWidgetLoadIfNecessary];
    [backgroundViewController doJITWidgetLoadIfNecessary];
    
    %orig;
}

%end

%hook SBLockScreenManager

// Handle the case where the device turns on e.g. for a phone call or Hey Siri
- (void)_handleBacklightLevelWillChange:(NSNotification*)arg1 {
    %orig;
    
    if ([XENHResources isAtLeastiOSVersion:11 subversion:0] && [XENHResources lsenabled]) {
        NSDictionary *userInfo = arg1.userInfo;
        
        CGFloat newBacklight = [[userInfo objectForKey:@"SBBacklightNewFactorKey"] floatValue];
        CGFloat oldBacklight = [[userInfo objectForKey:@"SBBacklightOldFactorKey"] floatValue];
        
        if (oldBacklight == 0.0 && newBacklight > 0.0) {
            if ([XENHResources LSUseBatteryManagement]) {
                XENlog(@"Showing Lockscreen HTML due to display turning on (failsafe).");
                
                [foregroundViewController setPaused:NO];
                [backgroundViewController setPaused:NO];
                
                [XENHResources setDisplayState:YES]; // ON
            }
            
            [foregroundViewController doJITWidgetLoadIfNecessary];
            [backgroundViewController doJITWidgetLoadIfNecessary];
        }
    }
}

%end

#pragma mark Handle LockHTML battery management with regards to calls (iOS 9+)

// We should hide foreground when in call, and reshow it afer leaving.
// When in call, above screen on code will not run.
// Need to hide when going into a call, and show afterwards.

%hook SBLockScreenManager

- (void)_relockUIForButtonPress:(_Bool)arg1 afterCall:(_Bool)arg2 {
    %orig;
    
    if ([XENHResources LSUseBatteryManagement] && arg2) {
        XENlog(@"Re-showing Lockscreen HTML since the UI is being relocked.");
        [foregroundViewController setPaused:NO];
        [backgroundViewController setPaused:NO];
        
        [XENHResources setDisplayState:YES]; // ON
    }
    
    [foregroundViewController doJITWidgetLoadIfNecessary];
    [backgroundViewController doJITWidgetLoadIfNecessary];
}

%end

#pragma mark Injection of Cycript into UIWebViews (iOS 9+)

%hook UIWebView

-(id)initWithFrame:(CGRect)frame {
    UIWebView *original = %orig;
    
    UIWebDocumentView *document = [original _documentView];
    WebView *webview = [document webView];
    
    [webview setPreferencesIdentifier:@"WebCycript"];
    
    if ([webview respondsToSelector:@selector(_setAllowsMessaging:)])
        [webview _setAllowsMessaging:YES];
    
    // TODO: We may need to prevent other tweaks messing with the frame delegate of WebView
    // since that prevents Cycript from being injected.
    
    return original;
}

- (void)webView:(WebView *)webview didClearWindowObject:(WebScriptObject *)window forFrame:(WebFrame *)frame {
    //[webview setScriptDebugDelegate:self]; // Debugging support
    
    %orig;
    
    // XXX: Inject settings into the webview, if available.
    NSString *href = [[[[frame dataSource] request] URL] absoluteString];
    href = [href stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    href = [href stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
    
    if (href) {
        NSDictionary *metadata = [XENHResources widgetMetadataForHTMLFile:href];
    
        for (NSString *key in [[metadata objectForKey:@"options"] allKeys]) {
            id value = [[metadata objectForKey:@"options"] valueForKey:key];
            [window setValue:value forKey:key];
        }
    }
}

%end

#pragma mark SBHTML (iOS 9+)

@interface UIViewController (Private)
- (id)_screen;
@end

%hook SBHomeScreenViewController

-(void)loadView {
    %orig;
    
    // Load up view.
    UIView<UIGestureRecognizerDelegate> *mainView = (id)self.view;
    
    XENlog(@"Injecting into homescreen");
    [XENHResources reloadSettings];
    
    if ([XENHResources SBEnabled] && [XENHResources widgetLayerHasContentForLocation:kLocationSBBackground]) {
        // This is an attempt to avoid oddness alongside CarPlay. It looks as if SBHomeScreenViewController
        // gets instantiated again when connected to CarPlay, resulting in SBHTML going odd.
        
        BOOL isOnMainScreen = [[self _screen] isEqual:[UIScreen mainScreen]];
        
        if (isOnMainScreen) {
            sbhtmlViewController = [XENHResources widgetLayerControllerForLocation:kLocationSBBackground];
            [mainView insertSubview:sbhtmlViewController.view atIndex:0];
            
            sbhtmlForwardingGesture.widgetController = sbhtmlViewController;
        }
    }
    
    [self _xenhtml_addTouchRecogniser];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recievedSBHTMLUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlUpdate"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recievedSBHTMLUpdateForGesture:) name:@"com.matchstic.xenhtml/sbhtmlUpdateGesture" object:nil];
#pragma clang diagnostic pop
}

- (void)_animateTransitionToSize:(CGSize)size andInterfaceOrientation:(int)orientation withTransitionContext:(id)transitionContext {
    %orig;
    
    // Rotate if possible
    if ([XENHResources SBEnabled] && [self shouldAutorotate]) {
        [XENHResources setCurrentOrientation:orientation];
        
        [sbhtmlViewController rotateToOrientation:orientation];
        [sbhtmlForegroundViewController rotateToOrientation:orientation];
    }
}

%new
-(void)_xenhtml_addTouchRecogniser {
    UIView<UIGestureRecognizerDelegate> *mainView = (id)self.view;
    
    if (mainView && [XENHResources SBAllowTouch]) {
        
        // Need to whitelist some views on which touch forwarding should never prevent
        // Just here as a stub now
        NSArray *ignoredViews = @[];
        
        sbhtmlForwardingGesture = [[XENHTouchForwardingRecognizer alloc] initWithWidgetController:sbhtmlViewController andIgnoredViewClasses:ignoredViews];
        
        CGFloat inset = 30.0;
        sbhtmlForwardingGesture.safeAreaInsets = UIEdgeInsetsMake([UIApplication sharedApplication].statusBarFrame.size.height + inset, inset, inset, inset);
        
        // Add the gesture!
        [mainView addGestureRecognizer:sbhtmlForwardingGesture];
    }
}

%new
-(void)recievedSBHTMLUpdateForGesture:(id)sender {
    // Also, handle the touch gesture recongizer!
    if ([XENHResources SBEnabled] && [XENHResources SBAllowTouch]) {
        // Add gesture if not present
        if (!sbhtmlForwardingGesture) {
            [self _xenhtml_addTouchRecogniser];
        }
    } else {
        // Remove gesture
        UIView<UIGestureRecognizerDelegate> *mainView = (id)self.view;
        [mainView removeGestureRecognizer:sbhtmlForwardingGesture];
        
        sbhtmlForwardingGesture = nil;
    }
}

// Will need to reload SBHTML if settings change.
%new
-(void)recievedSBHTMLUpdate:(id)sender {
    if ([XENHResources SBEnabled] && [XENHResources widgetLayerHasContentForLocation:kLocationSBBackground]) {
        if (sbhtmlViewController) {
            [sbhtmlViewController noteUserPreferencesDidChange];
        } else {
            UIView *mainView = self.view;
        
            if ([XENHResources widgetLayerHasContentForLocation:kLocationSBBackground]) {
                XENlog(@"Loading SBHTML view");
                // This is an attempt to avoid oddness alongside CarPlay. It looks as if SBHomeScreenViewController
                // gets instantiated again when connected to CarPlay, resulting in SBHTML going odd.
                
                BOOL isOnMainScreen = [[self _screen] isEqual:[UIScreen mainScreen]];
                
                if (isOnMainScreen) {
                    sbhtmlViewController = [XENHResources widgetLayerControllerForLocation:kLocationSBBackground];
                    [mainView insertSubview:sbhtmlViewController.view atIndex:0];
                    
                    sbhtmlForwardingGesture.widgetController = sbhtmlViewController;
                }
            }
        }
    } else if (sbhtmlViewController) {
        [sbhtmlViewController unloadWidgets];
        [sbhtmlViewController.view removeFromSuperview];
        sbhtmlViewController = nil;
    }
}

#pragma mark Handle SBHTML touches (iOS 9+)

%new
- (BOOL)shouldIgnoreWebTouch {
    return NO;
}

%new
- (BOOL)isAnyTouchOverActiveArea:(NSSet *)touches {
    return YES;
}

%end

%hook SBHomeScreenView

-(void)layoutSubviews {
    %orig;
    
    if ([XENHResources SBEnabled] && sbhtmlViewController) {
        sbhtmlViewController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    }
}

- (void)insertSubview:(UIView*)view atIndex:(int)index {
    %orig;
    
    // Ensure that we're at the bottom at all times!
    if ([XENHResources SBEnabled] && sbhtmlViewController && [[view class] isEqual:objc_getClass("SBIconContentView")]) {
        [self insertSubview:sbhtmlViewController.view atIndex:0];
    }
}

-(void)setHidden:(BOOL)hidden {
    %orig;
    
    if ([XENHResources SBEnabled] && sbhtmlViewController) {
        sbhtmlViewController.view.hidden = hidden;
    }
}

%end

#pragma mark Hide dock blur (iOS 9+)

%hook SBDockView

-(id)initWithDockListView:(id)arg1 forSnapshot:(BOOL)arg2 {
    id orig = %orig;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [[NSNotificationCenter defaultCenter] addObserver:orig
                                             selector:@selector(recievedSBHTMLUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlDockUpdate"
                                               object:nil];
#pragma clang diagnostic pop
    
    return orig;
}

-(void)layoutSubviews {
    %orig;
    
    if ([XENHResources SBEnabled] && [XENHResources hideBlurredDockBG]) {
#if TARGET_IPHONE_SIMULATOR==0
        [MSHookIvar<UIView*>(self, "_backgroundView") setHidden:YES];
        [MSHookIvar<UIView*>(self, "_backgroundImageView") setHidden:YES];
        [MSHookIvar<UIView*>(self, "_accessibilityBackgroundView") setHidden:YES];
#endif
    }
}

- (void)_backgroundContrastDidChange:(id)arg1 {
    %orig;
    
    if ([XENHResources SBEnabled] && [XENHResources hideBlurredDockBG]) {
#if TARGET_IPHONE_SIMULATOR==0
        [MSHookIvar<UIView*>(self, "_backgroundView") setHidden:YES];
        [MSHookIvar<UIView*>(self, "_backgroundImageView") setHidden:YES];
        [MSHookIvar<UIView*>(self, "_accessibilityBackgroundView") setHidden:YES];
#endif
    }
}

%new
-(void)recievedSBHTMLUpdate:(id)sender {
    if ([XENHResources SBEnabled]) {
#if TARGET_IPHONE_SIMULATOR==0
        [MSHookIvar<UIView*>(self, "_backgroundView") setHidden:[XENHResources hideBlurredDockBG]];
        [MSHookIvar<UIView*>(self, "_backgroundImageView") setHidden:[XENHResources hideBlurredDockBG]];
        [MSHookIvar<UIView*>(self, "_accessibilityBackgroundView") setHidden:[XENHResources hideBlurredDockBG]];
#endif
    }
}

%end

#pragma mark Hide dock blur (iOS 11 + iPad)

%hook SBFloatingDockPlatterView

- (id)initWithReferenceHeight:(double)arg1 maximumContinuousCornerRadius:(double)arg2 {
    id orig = %orig;
    
    [[NSNotificationCenter defaultCenter] addObserver:orig
                                             selector:@selector(recievedSBHTMLUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlDockUpdate"
                                               object:nil];
    
    return orig;
}

-(void)layoutSubviews {
    %orig;
    
    if ([XENHResources SBEnabled] && [XENHResources hideBlurredDockBG]) {
#if TARGET_IPHONE_SIMULATOR==0
        [MSHookIvar<UIView*>(self, "_backgroundView") setHidden:YES];
#endif
    }
}

%new
-(void)recievedSBHTMLUpdate:(id)sender {
    if ([XENHResources SBEnabled]) {
#if TARGET_IPHONE_SIMULATOR==0
        [MSHookIvar<UIView*>(self, "_backgroundView") setHidden:[XENHResources hideBlurredDockBG]];
#endif
    }
}

%end

#pragma mark Hide folder icon blur (iOS 9+)

%hook SBFolderIconBackgroundView

-(id)initWithDefaultSize {
    id orig = %orig;
    
    [[NSNotificationCenter defaultCenter] addObserver:orig
                                             selector:@selector(recievedSBHTMLUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlFolderUpdate"
                                               object:nil];
    
    return orig;
}

-(id)initWithFrame:(CGRect)arg1 {
    id orig = %orig;
    
    [[NSNotificationCenter defaultCenter] addObserver:orig
                                             selector:@selector(recievedSBHTMLUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlFolderUpdate"
                                               object:nil];
    
    return orig;
}

-(void)layoutSubviews {
    %orig;
    
    if ([XENHResources SBEnabled] && [XENHResources hideBlurredFolderBG]) {
        [self setHidden:YES];
    }
}

%new
-(void)recievedSBHTMLUpdate:(id)sender {
    if ([XENHResources SBEnabled]) {
        [self setHidden:[XENHResources hideBlurredFolderBG]];
    }
}

%end

#pragma mark Hide icon labels (iOS 9+)

%hook SBIconView

-(id)initWithContentType:(unsigned long long)arg1 {
    id orig = %orig;
    
    [[NSNotificationCenter defaultCenter] addObserver:orig
                                             selector:@selector(recievedSBHTMLUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlIconLabelsUpdate"
                                               object:nil];
    
    return orig;
}

-(void)layoutSubviews {
    %orig;
    
    if ([XENHResources SBEnabled] && [XENHResources SBHideIconLabels]) {
#if TARGET_IPHONE_SIMULATOR==0
        [MSHookIvar<UIView*>(self, "_labelView") setHidden:YES];
#endif
    }
}

%new
-(void)recievedSBHTMLUpdate:(id)sender {
    if ([XENHResources SBEnabled]) {
#if TARGET_IPHONE_SIMULATOR==0
        [MSHookIvar<UIView*>(self, "_labelView") setHidden:[XENHResources SBHideIconLabels]];
#endif
    }
}

%end

#pragma mark Hide SB page dots (iOS 9+)

%hook SBIconListPageControl

%property (nonatomic) BOOL _xenhtml_hidden;

- (void)setHidden:(BOOL)hidden {
    if (!hidden && self._xenhtml_hidden && ![XENHResources isPageBarAvailable])
        return;
    
    %orig;
}

%end

%hook SBRootFolderView

- (void)layoutSubviews {
    if ([XENHResources isPageBarAvailable]) {
        // For some reason, there is a crash orignating from Pagebar when running simultaneously
        // See: https://github.com/Matchstic/Xen-HTML/issues/122
        // I assume this is probably going to be non-fatal
        
        @try {
            %orig;
        } @catch (NSException *e) {
            XENlog(@"Caught exception from Pagebar, assuming non-fatal.");
        }
    } else {
        %orig;
    }
    
    // This ideally should be called in init. However, this does not function correctly on iOS 10.3.3
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(recievedSBHTMLUpdate:)
                                                     name:@"com.matchstic.xenhtml/sbhtmlPageDotsUpdate"
                                                   object:nil];
    });
    
    // This is nasty, but works around an iOS 10.3 issue when this class gets instaniated
    // handle _xenhtml_isPreviewGeneration ?
    if (!self._xenhtml_addButton) {
        [self _xenhtml_initialise];
    }
    
    if ([XENHResources SBEnabled] && [XENHResources SBHidePageDots] && ![XENHResources isPageBarAvailable]) {
#if TARGET_IPHONE_SIMULATOR==0
        SBIconListPageControl *pageControl = MSHookIvar<SBIconListPageControl*>(self, "_pageControl");
        pageControl._xenhtml_hidden = YES;
        pageControl.hidden = YES;
#endif
    }
    
#pragma mark Layout foreground SBHTML add button and editing view (iOS 9+)
    
    // Layout the add button at the very bottom of the scrollview
    [self _xenhtml_layoutAddWidgetButton];
    [self _xenhtml_layoutEditingPlatter];
}

%new
-(void)recievedSBHTMLUpdate:(id)sender {
#if TARGET_IPHONE_SIMULATOR==0
    SBIconListPageControl *pageControl = MSHookIvar<SBIconListPageControl*>(self, "_pageControl");
    
    // Compatibility
    if ([XENHResources isPageBarAvailable])
        return;
    
    if ([XENHResources SBEnabled]) {
        pageControl._xenhtml_hidden = [XENHResources SBHidePageDots];
        pageControl.hidden = [XENHResources SBHidePageDots];
    } else {
        // Make sure to un-hide the dots
        pageControl._xenhtml_hidden = NO;
        pageControl.hidden = NO;
    }
#endif
}

%end

#pragma mark Foreground SBHTML init (iOS 9)

%hook SBIconController

- (void)loadView {
    %orig;
    
    // iOS verison guard
    if ([XENHResources isAtLeastiOSVersion:10 subversion:0])
        return;
    
    XENlog(@"SBIconController loadView");
    
    if ([XENHResources SBEnabled]) {
        // Add view to root scroll view, and set that scrollview to be the hoster
        sbhtmlForegroundViewController = (XENHHomescreenForegroundViewController*)[XENHResources widgetLayerControllerForLocation:kLocationSBForeground];
        [sbhtmlForegroundViewController updatePopoverPresentationController:self];
        
        XENlog(@"Created foreground SBHTML widgets view, pending presentation");
    }
    
    // Register for settings updates
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recievedSBHTMLUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlUpdate"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recievedSBHTMLPerPageUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlPerPageUpdate"
                                               object:nil];
    
    // Update dock position if necessary
    SBRootFolderView *rootFolderView = [self _rootFolderController].contentView;
    [rootFolderView _xenhtml_setDockPositionIfNeeded];
}

// Patched in to support SBRootFolderController signature

%new
- (id)_xenhtml_contentView {
    return [self _rootFolderController].contentView;
}

%new
- (long long)_xenhtml_currentPageIndex {
    return [self _rootFolderController].currentPageIndex;
}

%new
- (id)iconListViewAtIndex:(long long)index {
    return [self rootIconListAtIndex:index];
}

%new
- (_Bool)setCurrentPageIndex:(long long)arg1 animated:(_Bool)arg2 {
    return [self scrollToIconListAtIndex:arg1 animate:arg2];
}

// Will need to reload SBHTML if settings change.
%new
-(void)recievedSBHTMLUpdate:(id)sender {
    if ([XENHResources SBEnabled]) {
        if (sbhtmlForegroundViewController) {
            [sbhtmlForegroundViewController noteUserPreferencesDidChange];
        } else {
            XENlog(@"Loading foreground SBHTML widgets view");
            
            BOOL isOnMainScreen = [[self _screen] isEqual:[UIScreen mainScreen]];
            
            if (isOnMainScreen) {
                sbhtmlForegroundViewController = (XENHHomescreenForegroundViewController*)[XENHResources widgetLayerControllerForLocation:kLocationSBForeground];
                [sbhtmlForegroundViewController updatePopoverPresentationController:self];
                
                SBRootFolderView *rootFolderView = [self _rootFolderController].contentView;
                rootFolderView.scrollView._xenhtml_isForegroundWidgetHoster = YES;
                [rootFolderView.scrollView addSubview:sbhtmlForegroundViewController.view];
                
                XENlog(@"Added foreground SBHTML widgets view");
            }
        }
    } else if (sbhtmlForegroundViewController) {
        [sbhtmlForegroundViewController unloadWidgets];
        [sbhtmlForegroundViewController.view removeFromSuperview];
        sbhtmlForegroundViewController = nil;
    }
    
    // Notify the scrollview amd contentView of changes
    SBRootFolderView *rootFolderView = [self _rootFolderController].contentView;
    [rootFolderView _xenhtml_recievedSettingsUpdate];
    [rootFolderView.scrollView _xenhtml_recievedSettingsUpdate];
}

%new
-(void)recievedSBHTMLPerPageUpdate:(id)sender {
    // Notify the contentView of changes
    SBRootFolderView *rootFolderView = [self _rootFolderController].contentView;
    [rootFolderView _xenhtml_recievedSettingsUpdate];
    [rootFolderView.scrollView _xenhtml_recievedSettingsUpdate];
}

%end

#pragma mark Foreground SBHTML init (iOS 10+)

%hook SBRootFolderController

- (void)loadView {
    %orig;
    
    // iOS verison guard
    if ([XENHResources isBelowiOSVersion:10 subversion:0])
        return;
    
    XENlog(@"SBRootFolderController loadView");
    
    
    
    // Set first to allow proper layout of views
    self.contentView.scrollView._xenhtml_isForegroundWidgetHoster = YES;
    
    if ([XENHResources SBEnabled]) {
        // Add view to root scroll view, and set that scrollview to be the hoster
        sbhtmlForegroundViewController = (XENHHomescreenForegroundViewController*)[XENHResources widgetLayerControllerForLocation:kLocationSBForeground];
        [sbhtmlForegroundViewController updatePopoverPresentationController:self];
        
        [self.contentView.scrollView addSubview:sbhtmlForegroundViewController.view];
        
        XENlog(@"Added foreground SBHTML widgets view");
    }
    
    // Register for settings updates
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recievedSBHTMLUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlUpdate"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recievedSBHTMLPerPageUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlPerPageUpdate"
                                               object:nil];
    
    // Update dock position if necessary
    [self.contentView _xenhtml_setDockPositionIfNeeded];
}

// Will need to reload SBHTML if settings change.
%new
-(void)recievedSBHTMLUpdate:(id)sender {
    if ([XENHResources SBEnabled]) {
        if (sbhtmlForegroundViewController) {
            [sbhtmlForegroundViewController noteUserPreferencesDidChange];
        } else {
            XENlog(@"Loading foreground SBHTML widgets view");
            
            BOOL isOnMainScreen = [[self _screen] isEqual:[UIScreen mainScreen]];
            
            if (isOnMainScreen) {
                sbhtmlForegroundViewController = (XENHHomescreenForegroundViewController*)[XENHResources widgetLayerControllerForLocation:kLocationSBForeground];
                [sbhtmlForegroundViewController updatePopoverPresentationController:self];
                
                // Set first to allow proper layout of views
                self.contentView.scrollView._xenhtml_isForegroundWidgetHoster = YES;
                [self.contentView.scrollView addSubview:sbhtmlForegroundViewController.view];
            }
        }
    } else if (sbhtmlForegroundViewController) {
        [sbhtmlForegroundViewController unloadWidgets];
        [sbhtmlForegroundViewController.view removeFromSuperview];
        sbhtmlForegroundViewController = nil;
    }
    
    // Notify the scrollview and contentView of changes
    [self.contentView _xenhtml_recievedSettingsUpdate];
    [self.contentView.scrollView _xenhtml_recievedSettingsUpdate];
}

%new
-(void)recievedSBHTMLPerPageUpdate:(id)sender {
    // Notify the contentView of changes
    [self.contentView _xenhtml_recievedSettingsUpdate];
    [self.contentView.scrollView _xenhtml_recievedSettingsUpdate];
}

%new
- (id)_xenhtml_contentView {
    return self.contentView;
}

%new
- (long long)_xenhtml_currentPageIndex {
    return self.currentPageIndex;
}

%end

#pragma mark Foreground SBHTML layout (iOS 9+)

%hook SBIconScrollView

%property (nonatomic) BOOL _xenhtml_isForegroundWidgetHoster;

- (void)layoutSubviews {
    %orig;
    
    // Layout if needed
    if (self._xenhtml_isForegroundWidgetHoster) {
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        
        // If the today page is hidden, then we layout by -SCREEN_WIDTH as the x origin.
        // This is to allow all existing logic inside the view controller to not need changing!
        
        // When today is hidden, the first icon list is at offset 0. Otherwise, SCREEN_WIDTH
        
        BOOL noTodayPage = NO;
        
        for (UIView *view in self.subviews) {
            // First iconlist subview
            if ([[view class] isEqual:objc_getClass("SBRootIconListView")]) {
                noTodayPage = view.frame.origin.x == 0;
                
                break;
            }
        }
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 13.0) {
            sbhtmlForegroundViewController.view.frame = CGRectMake(noTodayPage ? -SCREEN_WIDTH : 0, 0, self.contentSize.width, SCREEN_HEIGHT);
        } else {
            sbhtmlForegroundViewController.view.frame = CGRectMake(noTodayPage ? -SCREEN_WIDTH : 0, -statusBarHeight, self.contentSize.width, SCREEN_HEIGHT);
        }
    }
}

// Might need to relayout views on settings change
%new
-(void)_xenhtml_recievedSettingsUpdate {
    if ([XENHResources SBEnabled] && sbhtmlForegroundViewController && self._xenhtml_isForegroundWidgetHoster) {
        if ([XENHResources SBPerPageHTMLWidgetMode]) {
            // Send to back
            [self sendSubviewToBack:sbhtmlForegroundViewController.view];
        } else {
            // Send to front
            [self bringSubviewToFront:sbhtmlForegroundViewController.view];
        }
    }
}

- (void)addSubview:(id)arg1 {
    %orig;
    
    if (self._xenhtml_isForegroundWidgetHoster && sbhtmlForegroundViewController) {
        if ([XENHResources SBPerPageHTMLWidgetMode]) {
            // Send to back
            [self sendSubviewToBack:sbhtmlForegroundViewController.view];
        } else {
            // Send to front
            [self bringSubviewToFront:sbhtmlForegroundViewController.view];
        }
    }
}

- (void)insertSubview:(id)arg1 atIndex:(int)arg2 {
    %orig;
    
    if (self._xenhtml_isForegroundWidgetHoster && sbhtmlForegroundViewController) {
        if ([XENHResources SBPerPageHTMLWidgetMode]) {
            // Send to back
            [self sendSubviewToBack:sbhtmlForegroundViewController.view];
        } else {
            // Send to front
            [self bringSubviewToFront:sbhtmlForegroundViewController.view];
        }
    }
}

%end

#pragma mark Touch corrections for Per Page HTML mode (iOS 9+)

%hook SBRootIconListView

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([XENHResources SBEnabled] && [XENHResources SBPerPageHTMLWidgetMode]) {
        BOOL isDraggingIcon = NO;
        
        if ([XENHResources isAtLeastiOSVersion:11 subversion:0]) {
            isDraggingIcon = [[[objc_getClass("SBIconController") sharedInstance] iconDragManager] isTrackingUserActiveIconDrags];
        } else {
            isDraggingIcon = [[objc_getClass("SBIconController") sharedInstance] grabbedIcon] != nil;
        }
        
        // Allow any "overhanging" views to respond
        if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
            for (UIView *subview in self.subviews.reverseObjectEnumerator) {
                CGPoint subPoint = [subview convertPoint:point fromView:self];
                UIView *result = [subview hitTest:subPoint withEvent:event];
                if (result != nil) {
                    return result;
                }
            }
        }
        
        // Ignore self as a valid view when not editing
        UIView *view = %orig;
        if ([view isEqual:self] && !isDraggingIcon) {
            view = nil;
        }
        
        return view;
    } else {
        return %orig;
    }
}

%end

#pragma mark Dock position for PerPageHTML mode (iOS 9+)

%hook SBRootFolderView

- (void)_updateDockViewZOrdering {
    %orig;
    
    // Override as needed
    [self _xenhtml_setDockPositionIfNeeded];
}

%new
- (void)_xenhtml_setDockPositionIfNeeded {
    UIView *dockView = [self dockView];
    UIView *dockParent = [dockView superview];
    
    if ([XENHResources SBEnabled] && sbhtmlForegroundViewController) {
        
        if ([XENHResources SBPerPageHTMLWidgetMode]) {
            // Send dock to front for PerPageHTML mode
            [dockParent bringSubviewToFront:dockView];
            
            XENlog(@"*** Bringing dock to the front");
        } else {
            // Send to back (default position)
            [dockParent sendSubviewToBack:dockView];
            
            XENlog(@"*** Sending dock to the back");
        }
    }
}

%new
-(void)_xenhtml_recievedSettingsUpdate {
    [self _xenhtml_setDockPositionIfNeeded];
}

%end

#pragma mark Display Homescreen foreground add button when editing (iOS 9+)

static BOOL _xenhtml_inEditingMode = NO;
static BOOL _xenhtml_isPreviewGeneration = NO;

// Don't try to render widgets when generating a snapshot preview image
%hook SBHomeScreenPreviewView

- (id)initWithFrame:(CGRect)arg1 iconController:(id)arg2 {
    _xenhtml_isPreviewGeneration = YES;
    
    id orig = %orig;
    
    _xenhtml_isPreviewGeneration = NO;
    
    return orig;
}

%end

%hook SBRootFolderView

%property (nonatomic, strong) XENHButton *_xenhtml_addButton;
%property (nonatomic, strong) XENHTouchPassThroughView *_xenhtml_editingPlatter;
%property (nonatomic, strong) UIView *_xenhtml_editingVerticalIndicator;

%new
- (void)_xenhtml_initialise {
    self._xenhtml_addButton = [[XENHButton alloc] initWithTitle:[XENHResources localisedStringForKey:@"WIDGETS_ADD_NEW"]];
    [self._xenhtml_addButton addTarget:self
            action:@selector(_xenhtml_addWidgetButtonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
    
    // Hide until UI is in editing UI
    self._xenhtml_addButton.hidden = YES;
    
    [self addSubview:self._xenhtml_addButton];
    
    // and the editing platter
    self._xenhtml_editingPlatter = [[XENHTouchPassThroughView alloc] initWithFrame:CGRectZero];
    self._xenhtml_editingPlatter.hidden = YES;
    
    [self addSubview:self._xenhtml_editingPlatter];
    
    self._xenhtml_editingVerticalIndicator = [[UIView alloc] initWithFrame:CGRectZero];
    self._xenhtml_editingVerticalIndicator.userInteractionEnabled = NO;
    self._xenhtml_editingVerticalIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    self._xenhtml_editingVerticalIndicator.hidden = YES;
    self._xenhtml_editingVerticalIndicator.alpha = 0.0;
    
    [self insertSubview:self._xenhtml_editingVerticalIndicator belowSubview:self._xenhtml_editingPlatter];
}

- (void)setEditing:(_Bool)arg1 animated:(_Bool)arg2 {
    %orig;
    
    _xenhtml_inEditingMode = arg1;
    
    // If the SB is not enabled, then don't go any further than this
    if (![XENHResources SBEnabled])
        return;

    [sbhtmlForegroundViewController updateEditingModeState:arg1];
    
    static CGFloat animationDuration = 0.15;
    
    // Display the add button, and hide the page dots
    if (arg1) {
        self._xenhtml_addButton.hidden = NO;
        self._xenhtml_editingPlatter.hidden = NO;
        
        if (![XENHResources hidePageControlDots] && ![XENHResources isPageBarAvailable]) {
            // Handle differences for iOS 9
            if (![self respondsToSelector:@selector(pageControl)]) {
#if TARGET_IPHONE_SIMULATOR==0
                [MSHookIvar<UIView*>(self, "_pageControl") setHidden:YES];
#endif
            } else {
                self.pageControl.hidden = YES;
            }
        } // Otherwise, already hidden
        
        self._xenhtml_addButton.alpha = 0.0;
        self._xenhtml_addButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
        
        [UIView animateWithDuration:animationDuration animations:^{
            self._xenhtml_addButton.alpha = 1.0;
            self._xenhtml_addButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }];
    } else {
        
        if (![XENHResources hidePageControlDots] && ![XENHResources isPageBarAvailable]) {
            // Handle differences for iOS 9
            if (![self respondsToSelector:@selector(pageControl)]) {
#if TARGET_IPHONE_SIMULATOR==0
                [MSHookIvar<UIView*>(self, "_pageControl") setHidden:NO];
#endif
            } else {
                self.pageControl.hidden = NO;
            }
        }
        
        [UIView animateWithDuration:animationDuration animations:^{
            self._xenhtml_addButton.alpha = 0.0;
            self._xenhtml_addButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
        } completion:^(BOOL finished) {
            if (finished && self) {
                self._xenhtml_addButton.hidden = YES;
                self._xenhtml_editingPlatter.hidden = YES;
            }
        }];
    }
}

-(void)scrollViewDidScroll:(id)arg1 {
    %orig;
    
    // Relayout with the new content offset for scrolling to the today page
    [self _xenhtml_layoutAddWidgetButton];
}

- (void)addSubview:(id)arg1 {
    %orig;
    
    // Bring our views forward again
    [self bringSubviewToFront:self._xenhtml_addButton];
    [self bringSubviewToFront:self._xenhtml_editingPlatter];
    
    // Set dock position if needed
    [self _xenhtml_setDockPositionIfNeeded];
}

- (void)insertSubview:(id)arg1 atIndex:(int)arg2 {
    %orig;
    
    // Bring our views forward again
    [self bringSubviewToFront:self._xenhtml_addButton];
    [self bringSubviewToFront:self._xenhtml_editingPlatter];
    
    // Set dock position if needed
    [self _xenhtml_setDockPositionIfNeeded];
    
}

%new
- (void)_xenhtml_addWidgetButtonTapped:(id)sender {
    [sbhtmlForegroundViewController noteUserDidPressAddWidgetButton];
}

%new
- (void)_xenhtml_layoutAddWidgetButton {
    // calculate offset needed to apply
    
    CGFloat lowestOffset = SCREEN_WIDTH;
    
    for (UIView *view in self.scrollView.subviews) {
        // First iconlist subview
        if ([[view class] isEqual:objc_getClass("SBRootIconListView")]) {
            lowestOffset = view.frame.origin.x;
            
            break;
        }
    }
    
    CGFloat effectiveXOffset = lowestOffset - self.scrollView.contentOffset.x;
    if (effectiveXOffset < 0) effectiveXOffset = 0;
        
    CGFloat scrollViewHeight = self.scrollView.frame.size.height;
    if ([XENHResources isHarbour2Available])
        scrollViewHeight -= 115.0; // Harbour 2 height and padding
    
    self._xenhtml_addButton.center = CGPointMake(effectiveXOffset + SCREEN_WIDTH/2.0,
                                                 scrollViewHeight
                                                 + self.scrollView.frame.origin.y
                                                 - self._xenhtml_addButton.bounds.size.height/4.0);
}

%new
- (void)_xenhtml_layoutEditingPlatter {
    self._xenhtml_editingPlatter.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self._xenhtml_editingVerticalIndicator.frame = CGRectMake(self.bounds.size.width/2 - 0.5, 0, 1, self.bounds.size.height);
}

%new
- (void)_xenhtml_showVerticalEditingGuide {
    self._xenhtml_editingVerticalIndicator.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self._xenhtml_editingVerticalIndicator.alpha = 1.0;
    }];
}

%new
- (void)_xenhtml_hideVerticalEditingGuide {
    [UIView animateWithDuration:0.3 animations:^{
        self._xenhtml_editingVerticalIndicator.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished)
            self._xenhtml_editingVerticalIndicator.hidden = YES;
    }];
}

%end

#pragma mark Ensure icons always can be tapped through the SBHTML foreground widgets view (iOS 9+)
%hook SBIconScrollView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (![XENHResources SBEnabled] || !self._xenhtml_isForegroundWidgetHoster) {
        return %orig;
    }
    
    UIView *result = nil;
    for (UIView *view in [self.subviews reverseObjectEnumerator]) {
        CGPoint subPoint = [view convertPoint:point fromView:self];
        UIView *hittested = [view hitTest:subPoint withEvent:event];
        
        if (hittested == nil)
            continue;
        
        // If in editing mode, prefer to move widgets around over icons
        if (_xenhtml_inEditingMode) {
            return hittested;
        }
        
        // If in OPW mode, prefer widget touches
        if ([XENHResources SBOnePageWidgetMode])
            return hittested;
        
        if ([[hittested class] isEqual:objc_getClass("SBIconView")] ||
            [[hittested class] isEqual:objc_getClass("SBFolderIconView")] ||
            [hittested isKindOfClass:objc_getClass("SBIconView")]) {
            // Favour icons where possible
            return hittested;
        }
        
        // Lowest subview gets a special case
        if ([[hittested class] isEqual:objc_getClass("SBRootIconListView")]) {
            if (!result) {
                // Only set if we don't have anything caught beforehand
                result = hittested;
            }
        } else {
            result = hittested;
        }
    }
    
    return result != nil ? result : %orig;
}

%end

// Make sure to allow touches back to the widget if it's behind icons
%hook SBDockView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (![XENHResources SBEnabled] || ![XENHResources SBPerPageHTMLWidgetMode]) {
        return %orig;
    }
    
    UIView *result = nil;
    for (UIView *view in [self.subviews reverseObjectEnumerator]) {
        CGPoint subPoint = [view convertPoint:point fromView:self];
        UIView *hittested = [view hitTest:subPoint withEvent:event];
        
        // Want the highest subview that didn't return nil
        if (result == nil && hittested != nil)
            result = hittested;
    }
    
    // Don't return self, hence why result starts off as nil
    return result;
}

%end

// Always allow icon touches of the dock
%hook SBRootFolderView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // Only needed for the mode of widgets above icons
    if (![XENHResources SBEnabled] || [XENHResources SBPerPageHTMLWidgetMode]) {
        return %orig;
    }
    
    CGPoint dockSubPoint = [[self dockView] convertPoint:point fromView:self];
    UIView *dockResult = [[self dockView] hitTest:dockSubPoint withEvent:event];
    
    // Favouring dock icons over anything else
    if (dockResult &&
        ![[dockResult class] isEqual:objc_getClass("SBRootFolderDockIconListView")] &&
        ![[dockResult class] isEqual:objc_getClass("SBDockIconListView")]) {
        return dockResult;
    } else {
        return %orig;
    }
}

%end

#pragma mark Stop jumping up bug (iOS 9+)

%hook WKWebView

- (BOOL)_shouldUpdateKeyboardWithInfo:(NSDictionary *)keyboardInfo {
    return NO;
}

%end

#pragma mark Stop white area bug (iOS 9+)

@interface _UIPlatterView : UIView
@end

%hook _UIPlatterView

- (void)didMoveToSuperview {
    %orig;
    
    if ([[self.superview.superview class] isEqual:objc_getClass("WKScrollView")] ||
        [[self.superview class] isEqual:objc_getClass("UIWebBrowserView")]) {
        [self removeFromSuperview];
    }
}

%end

#pragma mark Stop magnification loupe bug (iOS 11+)

%hook UIWKTextLoupeInteraction

-(void)loupeGesture:(id)arg1 {
    return;
}

%end

#pragma mark Add proper debugging capabilities to UIWebView (iOS 9+)

%hook UIWebView

- (void)webView:(WebView *)webView exceptionWasRaised:(WebScriptCallFrame *)frame sourceId:(int)sid line:(int)line forWebFrame:(WebFrame *)webFrame {
    NSString *url = [self.request.URL absoluteString];
    NSString *errorString = [NSString stringWithFormat: @"Exception at %@, in function: %@ line: %@", url , [frame functionName], [NSNumber numberWithInt: line]];
    
    XENlog(errorString);
    
    %orig;
}

- (void)webView:(WebView *)webView failedToParseSource:(NSString *)source baseLineNumber:(unsigned)line fromURL:(NSURL *)url withError:(NSError *)error forWebFrame:(WebFrame *)webFrame {
    NSString *urlstr = [url absoluteString];
    NSString *errorString = [NSString stringWithFormat: @"Failed to parse source at %@, line: %@\n\n%@", urlstr, [NSNumber numberWithInt:line], error];
    
    XENlog(errorString);
    
    %orig;
}

%end

#pragma mark Hooks into Xen to improve compatibility (iOS 9+)

%hook XENResources

+(BOOL)hideClock {
    // Xen will return NO always if the LS is running in XenHTML, so we can control this option here.
    return [XENHResources lsenabled] ? NO : %orig;
}

+(BOOL)hideNCGrabber {
    // Xen will return NO always if the LS is running in XenHTML, so we can control this option here.
    return [XENHResources lsenabled] ? NO : %orig;
}

%end

#pragma mark Properly handle media controls on lockscreen (iOS 9)

static void hideForegroundIfNeeded() {
    
    BOOL canHideForeground = foregroundHiddenRequesters.count > 0;
    
    if (canHideForeground && foregroundViewController && foregroundViewController.view.alpha != [XENHResources LSWidgetFadeOpacity]) {
        [UIView animateWithDuration:0.15 animations:^{
            foregroundViewController.view.alpha = [XENHResources LSWidgetFadeOpacity];
        } completion:^(BOOL finished) {
            //foregroundViewController.view.hidden = YES;
        }];
    }
}

static void showForegroundIfNeeded() {
    
    BOOL canShowForeground = foregroundHiddenRequesters.count == 0;
    
    if (canShowForeground && foregroundViewController && foregroundViewController.view.alpha != 1.0) {
        //foregroundViewController.view.hidden = NO;
        
        [UIView animateWithDuration:0.15 animations:^{
            foregroundViewController.view.alpha = 1.0;
        }];
    }
}

static void addForegroundHiddenRequester(NSString* requester) {
    
    if (!foregroundHiddenRequesters) {
        foregroundHiddenRequesters = [NSMutableArray array];
    }
    
    if (![foregroundHiddenRequesters containsObject:requester]) {
        [foregroundHiddenRequesters addObject:requester];
    }
    
    hideForegroundIfNeeded();
}

static void removeForegroundHiddenRequester(NSString* requester) {
    
    [foregroundHiddenRequesters removeObject:requester];
    
    showForegroundIfNeeded();
}

%hook SBLockScreenViewController

- (void)_setMediaControlsVisible:(BOOL)visible {
    %orig;
    
    if (foregroundViewController && [XENHResources LSFadeForegroundForMedia]) {
        // If showing controls, fade the foreground ONLY if set to.
        
#if TARGET_IPHONE_SIMULATOR==0
        BOOL actuallyHasControls = YES;
        
        UIViewController *mpu = MSHookIvar<UIViewController*>(self, "_mediaControlsViewController");
        if (!mpu) {
            actuallyHasControls = NO;
        } else if (!mpu.view.superview) {
            actuallyHasControls = NO;
        } else if (mpu.view.alpha == 0.0) {
            actuallyHasControls = NO;
        }
        
        if (visible && actuallyHasControls) {
            addForegroundHiddenRequester(@"com.matchstic.xenhtml.mediacontrols");
        } else {
            removeForegroundHiddenRequester(@"com.matchstic.xenhtml.mediacontrols");
        }
#endif
    }
}

%end

%hook _NowPlayingArtView

-(void)setAlpha:(CGFloat)alpha {
    if ([XENHResources LSFadeForegroundForArtwork]) {
        if (alpha == 0.0) {
            removeForegroundHiddenRequester(@"com.matchstic.xenhtml.artwork");
        } else {
            addForegroundHiddenRequester(@"com.matchstic.xenhtml.artwork");
        }
    }
    
    %orig;
}

-(void)setArtworkView:(UIView *)arg1 {
    
    // Monitor this view for hidden changes too.
    if ([XENHResources LSFadeForegroundForArtwork]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView *existing = MSHookIvar<UIView*>(self, "_artworkView");
        
        if (arg1 && !existing) {
            [arg1 addObserver:self forKeyPath:@"hidden" options:0 context:NULL];
        } else if (arg1 && existing) {
            [existing removeObserver:self forKeyPath:@"hidden"];
            
            [arg1 addObserver:self forKeyPath:@"hidden" options:0 context:NULL];
        } else if (!arg1) {
            [existing removeObserver:self forKeyPath:@"hidden"];
        }
#endif
    }
    
    %orig;
}

-(void)layoutSubviews {
    %orig;
    
    //We hide if there is a foreground controller, and we're set to
    BOOL shouldHide = [XENHResources lsenabled] && foregroundViewController && [XENHResources LSHideArtwork];
    
    if (shouldHide) {
        self.hidden = YES;
    }
}

- (void)removeFromSuperview {
    // Release observer.
    
    if ([XENHResources LSFadeForegroundForArtwork]) {
#if TARGET_IPHONE_SIMULATOR==0
        UIView* viewToObserve = MSHookIvar<UIView*>(self, "_artworkView");
        if (viewToObserve) {
            @try {
                [viewToObserve removeObserver:self forKeyPath:@"hidden"];
            } @catch (NSException *e) {
                // Probably weren't observing this then
            }
        }
#endif
    }
    
    %orig;
}

%new
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
#if TARGET_IPHONE_SIMULATOR==0
    UIView* viewToObserve = MSHookIvar<UIView*>(self, "_artworkView");
    
    if ([object isEqual:viewToObserve]) {
        if ([keyPath isEqualToString:@"hidden"]) {
            // react to state change
            if (viewToObserve.hidden == YES) {
                removeForegroundHiddenRequester(@"com.matchstic.xenhtml.artwork");
            } else {
                addForegroundHiddenRequester(@"com.matchstic.xenhtml.artwork");
            }
        }
    }
#endif
}

%end

#pragma mark Properly handle media controls and notification on lockscreen (iOS 10)

// SBDashBoardMediaArtworkViewController, presented to SBDashBoardMainPageContentViewController

%hook SBDashBoardMainPageContentViewController

- (void)dismissContentViewControllers:(NSArray*)arg1 animated:(_Bool)arg2 completion:(id)arg3 {
    // We will check for notifications being hidden.
    
    for (id obj in arg1) {
        if ([obj isKindOfClass:objc_getClass("SBDashBoardNotificationListViewController")]) {
            showForegroundForLSNotifIfNeeded();
        }
    }
    
    %orig;
}

- (void)presentContentViewControllers:(NSArray*)arg1 animated:(_Bool)arg2 completion:(id)arg3 {
    // Along with hiding the artwork here, we will also check for notifications being presented.
    
    for (id obj in arg1) {
        if ([obj isKindOfClass:objc_getClass("SBDashBoardNotificationListViewController")]) {
            hideForegroundForLSNotifIfNeeded();
        }
    }
    
    BOOL shouldHideArtwork = [XENHResources lsenabled] && foregroundViewController && [XENHResources LSHideArtwork];
    
    NSMutableArray *newArray = [NSMutableArray array];
    
    if (shouldHideArtwork) {
        for (id obj in arg1) {
            if (![obj isKindOfClass:objc_getClass("SBDashBoardMediaArtworkViewController")]) {
                [newArray addObject:obj];
            }
        }
        
        %orig(newArray, arg2, arg3);
    } else {
        %orig;
    }
}

- (void)_updateMediaControlsVisibility {
    %orig;
    
    BOOL showing = self.showingMediaControls;
    BOOL shouldHide = foregroundViewController && [XENHResources LSFadeForegroundForMedia];
    
    if (shouldHide) {
        if (showing) {
            addForegroundHiddenRequester(@"com.matchstic.xenhtml.mediacontrols");
        } else {
            removeForegroundHiddenRequester(@"com.matchstic.xenhtml.mediacontrols");
        }
    }
}

%end

%hook SBDashBoardMediaArtworkViewController

- (long long)presentationType {
    return [XENHResources lsenabled] ? 1 : %orig;
}

%end

#pragma mark Hide widget for notifications if needed. (iOS 9)

static void hideForegroundForLSNotifIfNeeded() {
    if ([XENHResources LSFadeForegroundForNotifications] && ![XENHResources LSInStateNotificationsHidden]) {
        addForegroundHiddenRequester(@"com.matchstic.xenhtml.notifications");
    }
}

static void showForegroundForLSNotifIfNeeded() {
    if ([XENHResources LSFadeForegroundForNotifications] && [XENHResources LSInStateNotificationsHidden]) {
        removeForegroundHiddenRequester(@"com.matchstic.xenhtml.notifications");
    }
}

%hook SBLockScreenNotificationListController

- (id)initWithNibName:(id)arg1 bundle:(id)arg2 {
    id orig = %orig;
    
    if (orig) {
        [XENHResources cacheNotificationListController:orig];
    }
    
    return orig;
}

- (void)_updateModelAndViewForRemovalOfItem:(id)arg1 {
    %orig;
    
    showForegroundForLSNotifIfNeeded();
}

- (void)_updateModelForRemovalOfItem:(id)arg1 updateView:(_Bool)arg2 {
    %orig;
    
    showForegroundForLSNotifIfNeeded();
}

- (void)_updateModelAndViewForAdditionOfItem:(id)arg1 {
    %orig;
    
    hideForegroundForLSNotifIfNeeded();
}

%end

// Priority Hub
%hook PHContainerView

- (void)selectAppID:(NSString*)appID newNotification:(BOOL)newNotif {
    %orig;
    
    // Hide/show as needed.
    if ([self.selectedAppID isEqualToString:appID]) {
        [XENHResources cachePriorityHubVisibility:YES];
        hideForegroundForLSNotifIfNeeded();
    } else {
        [XENHResources cachePriorityHubVisibility:NO];
        showForegroundForLSNotifIfNeeded();
    }
}

%end

// Xen grouping
%hook XENNotificationsCollectionViewController

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    
    [XENHResources cacheXenGroupingVisibility:NO];
    hideForegroundForLSNotifIfNeeded();
}

-(void)removeFullscreenNotification:(id)sender {
    %orig;
    
    [XENHResources cacheXenGroupingVisibility:YES];
    showForegroundForLSNotifIfNeeded();
}

%end

#pragma mark Properly handle media controls and notification on lockscreen (iOS 11+)

// Media control visibility
%hook SBDashBoardNotificationAdjunctListViewController

- (void)_updateMediaControlsVisibilityAnimated:(BOOL)arg1 {
    %orig;
    
    // iOS 12+ treats the media controls as notification content.
    BOOL isiOS11 = [XENHResources isBelowiOSVersion:12 subversion:0] && [XENHResources isAtLeastiOSVersion:11 subversion:0];
    if (!isiOS11)
        return;
    
    BOOL showing = self.showingMediaControls;
    BOOL shouldHide = foregroundViewController && [XENHResources LSFadeForegroundForMedia];
    
    if (shouldHide) {
        if (showing) {
            addForegroundHiddenRequester(@"com.matchstic.xenhtml.mediacontrols");
        } else {
            removeForegroundHiddenRequester(@"com.matchstic.xenhtml.mediacontrols");
        }
    }
}

%end

// Notifications visibility
%hook SBDashBoardCombinedListViewController

- (void)_setListHasContent:(_Bool)arg1 {
    %orig;
    
    BOOL shouldHide = NO;
    
    if ([XENHResources isBelowiOSVersion:12 subversion:0])
        shouldHide = foregroundViewController && [XENHResources LSFadeForegroundForNotifications];
    else
        shouldHide = [XENHResources LSFadeForegroundForNotifications];
    
    if (shouldHide) {
        if (arg1) {
            addForegroundHiddenRequester(@"com.matchstic.xenhtml.notifications");
        } else {
            removeForegroundHiddenRequester(@"com.matchstic.xenhtml.notifications");
        }
    }
}

%end

#pragma mark Adjust notification view positioning as required (iOS 9)

%hook SBFLockScreenMetrics

+ (UIEdgeInsets)notificationListInsets {
    UIEdgeInsets orig = %orig;
    
    if ([XENHResources lsenabled] && [XENHResources LSFullscreenNotifications]) {
        orig.top = [[UIApplication sharedApplication] statusBarFrame].size.height;
        orig.bottom = 0;
    }
    
    return orig;
}

%end

#pragma mark Adjust notification view positioning as required (iOS 10)

%hook SBDashBoardNotificationListViewController

- (CGRect)_suggestedListViewFrame {
    CGRect orig = %orig;
    
    if ([XENHResources lsenabled] && [XENHResources LSFullscreenNotifications]) {
        orig.origin.y = [[UIApplication sharedApplication] statusBarFrame].size.height;
        orig.size.height = SCREEN_HEIGHT - [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
    
    return orig;
}

%end

#pragma mark Adjust notification view positioning as required (iOS 11)

%hook SBDashBoardCombinedListViewController

- (UIEdgeInsets)_listViewDefaultContentInsets {
    UIEdgeInsets orig = %orig;
    
    if ([XENHResources lsenabled] && [XENHResources LSFullscreenNotifications]) {
        orig.top = [[UIApplication sharedApplication] statusBarFrame].size.height;
    }/* else if ([XENHResources lsenabled] && [XENHResources LSUseCustomNotificationsPosition]) {
        // Custom notification position: force insets to be 0 due to custom view sizing.
        orig.top = 0.0;
    }*/
    
    return orig;
}

- (void)viewWillAppear:(_Bool)arg1 {
    %orig;
    
    // Force-update listview insets for us
    [self _updateListViewContentInset];
}

/*- (void)_layoutListView {
    %orig;
    
    if ([XENHResources lsenabled] && [XENHResources LSUseCustomNotificationsPosition]) {
        // Custom notification position: sort out frame.
        UIView *notificationScrollView = [self notificationListScrollView];
        CGRect frame = notificationScrollView.frame;
        
        CGFloat topOffset = 0.5;
        CGFloat bottomOffset = 0.0;
        
        frame.origin.y = SCREEN_HEIGHT * topOffset;
        frame.size.height = (SCREEN_HEIGHT * bottomOffset) - (SCREEN_HEIGHT * topOffset);
        
        // Set frame
        notificationScrollView.frame = frame;
        
        // Ensure we clip on bounds.
        notificationScrollView.clipsToBounds = YES;
    }
}*/

%end

#pragma mark Used to forward touches to other views via a view tag. (iOS 9+)

%hook UITouchesEvent

- (NSSet*)touchesForGestureRecognizer:(UIGestureRecognizer*)arg1 {
    if (arg1.view.tag == 1337 && ([[arg1.view class] isEqual:objc_getClass("WKContentView")] || [[arg1.view class] isEqual:objc_getClass("UIWebBrowserView")])) {
        return [self _allTouches];
    } else {
        return %orig;
    }
}

- (NSSet*)touchesForView:(UIView*)arg1 {
    if (arg1.tag == 1337 && ([[arg1 class] isKindOfClass:objc_getClass("UIScrollView")] || [[arg1 class] isEqual:objc_getClass("UIWebOverflowScrollView")])) {
        NSSet *set = [self _allTouches];
        
        for (UITouch *touch in set) {
            [touch set_xh_forwardingView:arg1];
        }
        
        return set;
    } else {
        return %orig;
    }
}

%end

%hook UITouch

%property (nonatomic, assign) id _xh_forwardingView;

- (id)view {
    return [self _xh_forwardingView] != nil ? [self _xh_forwardingView] : %orig;
}

%end

%end

#pragma mark Setup UI stuff
// Annoyingly, this must all be ungrouped for when Xen HTML does not load.

%group Setup

%hook SpringBoard

%new
- (void)_xenhtml_relaunchSpringBoardAfterSetup {
    [XENHResources setPreferenceKey:@"hasDisplayedSetupUI" withValue:@YES andPost:YES];
    
    // Relaunch SpringBoard
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(_relaunchSpringBoardNow)]) {
        [(SpringBoard*)[UIApplication sharedApplication] _relaunchSpringBoardNow];
    } else if (objc_getClass("FBSystemService") && [[objc_getClass("FBSystemService") sharedInstance] respondsToSelector:@selector(exitAndRelaunch:)]) {
        [[objc_getClass("FBSystemService") sharedInstance] exitAndRelaunch:YES];
    }
}

%end

// TODO: Not valid for iOS 10 and 11
%hook SBLockScreenViewController

-(BOOL)suppressesSiri {
    return ([XENHResources lsenabled] && setupWindow) ? YES : %orig;
}

%end

%hook SBBacklightController

- (void)_lockScreenDimTimerFired {
    if (setupWindow) {
        return;
    }
    
    %orig;
}

%end

@interface SBLockScreenManager (Rehosting)
- (_Bool)unlockUIFromSource:(int)arg1 withOptions:(id)arg2;
@end

static BOOL launchCydiaForSource = NO;

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    
    /*
     * I can't believe I have to do this. There exists outdated versions of Xen HTML on pirate repos,
     * that cause serious issues for users on installation.
     *
     * This is to ensure that Xen HTML will only run when installed from:
     * - http://xenpublic.incendo.ws
     * - BigBoss
     * - Manual installation
     *
     * This will unfortunately break for users not using Cydia; sorry about that.
     */
    if (refuseToLoadDueToRehosting) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Xen HTML"
                                                                       message:@"This tweak has not been installed from the official repository. For your safety, it will not function until installed officially.\n\nTap below to add the official repository to Cydia."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        UIAlertAction* repoAction = [UIAlertAction actionWithTitle:@"Add Repository" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            
            launchCydiaForSource = YES;
            [[objc_getClass("SBLockScreenManager") sharedInstance] unlockUIFromSource:17 withOptions:nil];
        }];
        
        [alert addAction:repoAction];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    } else {
        // Do initial settings loading
        [XENHResources reloadSettings];
        
        // Show setup UI if needed - ignore on iOS 9 due to missing ES5/CSS support
        NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
        if (![XENHResources hasDisplayedSetupUI] && version.majorVersion > 9) {
            setupWindow = [XENHSetupWindow sharedInstance];
            
            setupWindow.hidden = NO;
            [setupWindow makeKeyAndVisible];
            setupWindow.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
            
            @try {
                SBLockScreenManager *man = [objc_getClass("SBLockScreenManager") sharedInstance];
                
                if ([man respondsToSelector:@selector(setBioUnlockingDisabled:forRequester:)]) {
                    [man setBioUnlockingDisabled:YES forRequester:@"com.matchstic.xenhtml.setup"];
                } else if ([man respondsToSelector:@selector(setBiometricAutoUnlockingDisabled:forReason:)]) {
                    [man setBiometricAutoUnlockingDisabled:YES forReason:@"com.matchstic.xenhtml.setup"];
                }
            } @catch (NSException *e) {
                // wut.
            }
        }
    }
    
    /*
     * Notify widgets that they are now free to do their first load
     *
     * This is to ensure WebKit related processes don't spin up until SpringBoard
     * is fully initialised.
     */
    
    [XENHResources setHasSeenSpringBoardLaunch:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/seenSpringBoardLaunch" object:nil];
}

%end

@interface SBHomeScreenWindow : UIWindow
@end

%hook SBHomeScreenWindow

- (void)becomeKeyWindow {
    // Hooking here to do things just after the device is unlocked
    
    %orig;
    
    // Launch Cydia to install from the official source
    if (launchCydiaForSource) {
        launchCydiaForSource = NO;
        
        NSURL *url = [NSURL URLWithString:@"cydia://url/https://cydia.saurik.com/api/share#?source=http://xenpublic.incendo.ws/"];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

%end

%end

%group iOS9

%hook SBRootFolderController

-(id)initWithFolder:(id)arg1 orientation:(long long)arg2 viewMap:(id)arg3 {
    // Set orientation
    [XENHResources setCurrentOrientation:arg2];
    
    SBRootFolderController *orig = %orig;
        
    if (orig) {
        
        orig.contentView.scrollView._xenhtml_isForegroundWidgetHoster = YES;
        
        if ([XENHResources SBEnabled]) {
            [orig.contentView.scrollView addSubview:sbhtmlForegroundViewController.view];
            
            XENlog(@"Presented foreground SBHTML");
        }
    }
    
    return orig;
}

%end

%end

#pragma mark - WebKit overrides

// Prevent double tap to scroll

%hook WKContentView

/*- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tapRecogniser = (UITapGestureRecognizer*)gestureRecognizer;

        // check if it is a 1-finger double-tap, and ignore if so
        if (tapRecogniser.numberOfTapsRequired == 2 && tapRecogniser.numberOfTouchesRequired == 1) {
            return NO;
        }
    }
    
    return %orig;
}*/

%end

static void XENHSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    
    NSDictionary *oldSBHTML = [XENHResources widgetPreferencesForLocation:kLocationSBBackground];
    BOOL oldSBHTMLEnabled = [XENHResources SBEnabled];
    BOOL oldDock = [XENHResources hideBlurredDockBG];
    BOOL oldFolder = [XENHResources hideBlurredFolderBG];
    BOOL oldIconLabels = [XENHResources SBHideIconLabels];
    BOOL oldSBTouch = [XENHResources SBAllowTouch];
    BOOL oldSBLegacy = [XENHResources SBUseLegacyMode];
    BOOL oldSBPageDots = [XENHResources SBHidePageDots];
    BOOL oldSBPerPageHTML = [XENHResources SBPerPageHTMLWidgetMode];
    
    [XENHResources reloadSettings];
    
    // Handle changes for LS - only triggered if in the persistent mode.
    if (foregroundViewController) {
        [foregroundViewController noteUserPreferencesDidChange];
    }
    
    if (backgroundViewController) {
        [backgroundViewController noteUserPreferencesDidChange];
    }
    
    // Handle SBHTML changes
    
    NSDictionary *newSBHTML = [XENHResources widgetPreferencesForLocation:kLocationSBBackground];
    BOOL newSBHTMLEnabled = [XENHResources SBEnabled];
    BOOL newDock = [XENHResources hideBlurredDockBG];
    BOOL newFolder = [XENHResources hideBlurredFolderBG];
    BOOL newIconLabels = [XENHResources SBHideIconLabels];
    BOOL newSBTouch = [XENHResources SBAllowTouch];
    BOOL newSBLegacy = [XENHResources SBUseLegacyMode];
    BOOL newSBPageDots = [XENHResources SBHidePageDots];
    BOOL newSBPerPageHTML = [XENHResources SBPerPageHTMLWidgetMode];
    
    if (![oldSBHTML isEqual:newSBHTML] ||
        newSBHTMLEnabled != oldSBHTMLEnabled ||
        newSBLegacy != oldSBLegacy) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/sbhtmlUpdate" object:nil];
    }
    
    if (oldDock != newDock) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/sbhtmlDockUpdate" object:nil];
    }
    
    if (oldFolder != newFolder) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/sbhtmlFolderUpdate" object:nil];
    }
    
    if (oldIconLabels != newIconLabels) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/sbhtmlIconLabelsUpdate" object:nil];
    }
    
    if (oldSBTouch != newSBTouch) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/sbhtmlUpdateGesture" object:nil];
    }
    
    if (oldSBPageDots != newSBPageDots) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/sbhtmlPageDotsUpdate" object:nil];
    }
    
    if (oldSBPerPageHTML != newSBPerPageHTML) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/sbhtmlPerPageUpdate" object:nil];
    }
}

static void XENHDidModifyConfig(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/sbhtmlUpdate" object:nil];
}

static void XENHDidRequestRespring (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(_relaunchSpringBoardNow)]) {
        [(SpringBoard*)[UIApplication sharedApplication] _relaunchSpringBoardNow];
    } else if (objc_getClass("FBSystemService") && [[objc_getClass("FBSystemService") sharedInstance] respondsToSelector:@selector(exitAndRelaunch:)]) {
        [[objc_getClass("FBSystemService") sharedInstance] exitAndRelaunch:YES];
    }
}

#pragma mark Constructor

%ctor {
    XENlog(@"******* Injecting Xen HTML");
    
    %init;
    
    BOOL sb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"];
    
    if (sb) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        // We need the setup UI to always be accessible.
        %init(Setup);
        
        // Make sure we're loading from the official repo. Outdated versions may break user devices.
        refuseToLoadDueToRehosting = ![XENHResources isInstalledFromOfficialRepository];
        
        if (refuseToLoadDueToRehosting) {
            XENlog(@"*** Not loading hooks due to not being installed from the official repo");
            return;
        }
        
        if (objc_getClass("SBDashBoardViewControllerBase")) {
            Class $XENDashBoardWebViewController = objc_allocateClassPair(objc_getClass("SBDashBoardViewControllerBase"), "XENDashBoardWebViewController", 0);
            objc_registerClassPair($XENDashBoardWebViewController);
        }
                
        // XXX: Load up Xen Lockscreen before we do, as this allows to ensure better compatibility between the two.
        // i.e., Xen HTML is in control of everything.
        dlopen("/Library/MobileSubstrate/DynamicLibraries/Xen.dylib", RTLD_NOW);
        
        // XXX: Load Priority Hub too.
        dlopen("/Library/MobileSubstrate/DynamicLibraries/PriorityHub.dylib", RTLD_NOW);
        
        // XXX: Also load up the NowPlaying artwork code, so that we can hook it correctly later on.
        dlopen("/System/Library/SpringBoardPlugins/NowPlayingArtLockScreen.lockbundle/NowPlayingArtLockScreen", RTLD_NOW);
        
        %init(SpringBoard);

        
        // iOS 9 only stuff
        NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
        if (version.majorVersion == 9) {
            %init(iOS9);
        }
#pragma clang diagnostic pop
        
        CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(r, NULL, XENHSettingsChanged, CFSTR("com.matchstic.xenhtml/settingschanged"), NULL, 0);
        CFNotificationCenterAddObserver(r, NULL, XENHDidModifyConfig, CFSTR("com.matchstic.xenhtml/sbconfigchanged"), NULL, 0);
        CFNotificationCenterAddObserver(r, NULL, XENHDidRequestRespring, CFSTR("com.matchstic.xenhtml/wantsrespring"), NULL, 0);
        CFNotificationCenterAddObserver(r, NULL, XENHDidModifyConfig, CFSTR("com.matchstic.xenhtml/jsconfigchanged"), NULL, 0);
    }
}
