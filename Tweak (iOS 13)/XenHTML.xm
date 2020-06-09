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

#import "XENHTouchForwardingRecognizer.h"
#import "XENSetupWindow.h"
#import "PrivateHeaders.h"
#import <objc/runtime.h>

#pragma mark Simulator support

// %config(generator=internal);

/*
 Other steps to compile for actual device again:
 1. Make CydiaSubstrate linking required?
 2. Change build target
 
 Note: the simulator *really* doesn't like MSHookIvar.
 */

#pragma mark Function definitions

static void hideForegroundIfNeeded();
static void showForegroundIfNeeded();

void resetIdleTimer();
void cancelIdleTimer();

static XENHSetupWindow *setupWindow;

#pragma mark Start hooks

%group SpringBoard

static XENHWidgetLayerController *backgroundViewController = nil;
static XENHWidgetLayerController *foregroundViewController = nil;
static XENHWidgetLayerController *sbhtmlViewController = nil;
static XENHHomescreenForegroundViewController *sbhtmlForegroundViewController = nil;

static NSMutableArray *foregroundHiddenRequesters;
static XENHTouchForwardingRecognizer *lsBackgroundForwarder;
static XENHTouchForwardingRecognizer *sbhtmlForwardingGesture;
static XENDashBoardWebViewController *lockscreenForegroundWrapperController;

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

#pragma mark Layout LS web views (iOS 13+)

%hook CSCoverSheetView

-(void)layoutSubviews {
    // Update orientation if needed.
    BOOL canRotate = [[[[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenEnvironment] rootViewController] shouldAutorotate];
    
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

- (void)viewControllerWillAppear {
    %orig;
    
    // On iOS 11, this is called whenever Dashboard is shown.
    // i.e., on lock and on NC display.
    
    // Alright; add background and foreground webviews to the LS!
    if ([XENHResources lsenabled]) {
        BOOL isLocked = [(SpringBoard*)[UIApplication sharedApplication] isLocked];
        
        // Make sure we initialise our UI with the right orientation.
        CSCoverSheetViewController *cont = (CSCoverSheetViewController *)[[[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenEnvironment] rootViewController];
        BOOL canRotate = [cont shouldAutorotate];
        
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
            
            if (!lockscreenForegroundWrapperController) {
                lockscreenForegroundWrapperController = [[objc_getClass("XENDashBoardWebViewController") alloc] init];
            }
            
            [lockscreenForegroundWrapperController setWebView:foregroundViewController.view];
            
            [dashBoardMainPageContentViewController presentContentViewController:lockscreenForegroundWrapperController animated:NO];
            
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
                   
        // Force a relayout, since the background controller lives on another view
        [self setNeedsLayout];
    }
}

#pragma mark Fix background controller being hidden when going to the camera (iOS 13+)

- (void)setWallpaperEffectView:(UIView*)wallpaperEffectView {
    %orig;
    
    if ([XENHResources lsenabled]) {
        if (wallpaperEffectView) {
            [self.slideableContentView insertSubview:backgroundViewController.view aboveSubview:wallpaperEffectView];
        } else {
            [self.slideableContentView insertSubview:backgroundViewController.view atIndex:0];
        }
    }
}

#pragma mark Destroy UI on unlock (iOS 13+)

- (void)viewControllerDidDisappear {
    %orig;
    
    // On iOS 11, this is called whenever dashboard is hidden.
    if ([XENHResources lsenabled]) {
        
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
        
        if (lockscreenForegroundWrapperController) {
            
            [[(UIViewController*)lockscreenForegroundWrapperController view] removeFromSuperview];
            [(UIViewController*)lockscreenForegroundWrapperController removeFromParentViewController];
            
            lockscreenForegroundWrapperController = nil;
        }
        
        lsBackgroundForwarder = nil;
    }
}

%end

#pragma mark Fix touch through to the LS notifications gesture. (iOS 13+)

%hook CSMainPageView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (![XENHResources lsenabled]) {
        return %orig;
    }
    
    UIView *orig = %orig;
    
    if (!foregroundViewController) {
        return orig;
    }
    
    UIView *outview = orig;
    
    if ([(UIView*)orig class] == objc_getClass("NCNotificationListView")) {
        // We allow scrolling/touching the widget in the lower 20% of the display if the user
        // has toggled ON Prioritise Touch in Widget, else prevent swiping to old notifications.
        
        if (![XENHResources LSWidgetScrollPriority] && point.y >= SCREEN_HEIGHT*0.81) {
            outview = orig;
        } else {
            outview = [lockscreenForegroundWrapperController.view hitTest:point withEvent:event];
        
            if (!outview)
                outview = orig;
        }
    }
    
    return outview;
    
    // _UIDragAutoScrollGestureRecognizer is what handles the pull-up gesture for notifications.
}

%end

#pragma mark Backing view controller for LS foreground webview. (iOS 13+)

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
 * We were defining a CSRegion. However, it appears Apple check whether any overlap,
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

- (BOOL)_canShowWhileLocked{
        return YES;
}

%end

%hook CSMainPageContentViewController

-(id)init {
    id orig = %orig;
    
    dashBoardMainPageContentViewController = orig;
    
    return orig;
}

%end

#pragma mark Hide clock (iOS 13+)

%hook CSMainPageContentViewController

- (void)aggregateAppearance:(CSAppearance*)arg1 {
    %orig;
    
    CSComponent *dateView = nil;
    
    for (CSComponent *component in arg1.components) {
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

#pragma mark Hide Torch and Camera (iOS 13+)

%hook CSQuickActionsViewController

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

#pragma mark Handle orientation (iOS 13+)

%hook CSCoverSheetViewController

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

#pragma mark Prevent touches cancelling when scrolling on-widget (iOS 10+)

%hook SBHorizontalScrollFailureRecognizer

- (_Bool)_isOutOfBounds:(struct CGPoint)arg1 forAngle:(double)arg2 {
    return foregroundViewController != nil ? NO : %orig;
}

%end

%hook CSScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    BOOL orig = %orig;
    
    if ([XENHResources lsenabled] && foregroundViewController) {
        // Either touches will be "stolen" more by the scroll view, or by the widget.
        if ([XENHResources LSWidgetScrollPriority]) {
            CSCoverSheetViewController *cont = (CSCoverSheetViewController *)[[[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenEnvironment] rootViewController];
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

#pragma mark Hide clock (iOS 13+)

%hook SBFLockScreenDateView

-(void)layoutSubviews {
    self.hidden = NO;
    
    %orig;

    if ([XENHResources lsenabled] && [XENHResources _hideClock10] == 2) {
        self.hidden = YES;
    }
}

-(void)setHidden:(BOOL)hidden {
    if ([XENHResources lsenabled] && [XENHResources _hideClock10] == 2) {
        %orig(YES);
    } else {
        %orig;
    }
}

%end

#pragma mark Same sized status bar (iOS 13+)

%hook CSCoverSheetViewController

- (long long)statusBarStyle {
    return [XENHResources lsenabled] && [XENHResources useSameSizedStatusBar] ? 0 : %orig;
}

%end

#pragma mark Hide LS status bar (iOS 13+)

%hook CSPageViewController

-(void)aggregateAppearance:(CSAppearance*)arg1 {
    %orig;
    
    // Slide statusBar with the lockscreen when presenting page. (needs confirmation)
    if ([XENHResources lsenabled] && [XENHResources hideStatusBar]) {
        CSComponent *statusBar = [[objc_getClass("CSComponent") statusBar] hidden:YES];
        [arg1 addComponent:statusBar];
    }
}

%end

#pragma mark Clock in status bar (iOS 13+)

%hook CSCoverSheetViewController

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

#pragma mark Clock in status bar (iOS 13+)

/*
 * The status bar time is *always* enabled except for the case of the Lockscreen, where DashBoard overrides it.
 */
%hook SBMainStatusBarStateProvider

- (void)setTimeCloaked:(_Bool)arg1 {
    if ([XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled]) {
        %orig(NO);
    } else {
        %orig(arg1);
    }
}

- (void)enableTime:(_Bool)arg1 crossfade:(_Bool)arg2 crossfadeDuration:(double)arg3 {
    if ([XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled]) {
        %orig(YES, arg2, arg3);
    } else {
        %orig(arg1, arg2, arg3);
    }
}

- (void)enableTime:(_Bool)arg1 {
    if ([XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled]) {
        %orig(YES);
    } else {
        %orig(arg1);
    }
}

- (_Bool)isTimeEnabled {
    if ([XENHResources LSShowClockInStatusBar] && [XENHResources lsenabled]) {
        return YES;
    } else {
        return %orig;
    }
}

%end

#pragma mark Ensure to always reset idle timer when we see touches in the LS (iOS 13+)

void resetIdleTimer() {
    // Idle timer handling has changed in iOS 11 (really?!)
    [(SBIdleTimerGlobalCoordinator*)[objc_getClass("SBIdleTimerGlobalCoordinator") sharedInstance] resetIdleTimer];
}

void cancelIdleTimer() {
    // Since cancelling the idle timer no longer is easy on iOS 11, we just reset it since user interaction won't
    // take a tremendous amount of time!
    resetIdleTimer();
}

// iOS 13
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

#pragma mark Hide STU view if necessary (iOS 13) and...
#pragma mark Hide Home Bar (iOS 13 + D22) and...
#pragma mark Hide D22 Control Centre grabber (iOS 13 + D22)

%hook CSTeachableMomentsContainerView

- (void)layoutSubviews {
    %orig;
    
#if TARGET_IPHONE_SIMULATOR==0
    UIView *calltoaction = MSHookIvar<UIView*>(self, "_callToActionLabelContainerView");
    calltoaction.hidden = [XENHResources lsenabled] && [XENHResources hideSTU];
    
    UIView *homebar = MSHookIvar<UIView*>(self, "_homeAffordanceContainerView");
    homebar.hidden = [XENHResources lsenabled] && [XENHResources LSHideHomeBar];
    
    UIView *grabber = MSHookIvar<UIView*>(self, "_controlCenterGrabberView");
    grabber.hidden = [XENHResources lsenabled] && [XENHResources LSHideD22CCGrabber];
#endif
}

%end

#pragma mark Hide Face ID padlock (iOS 13 + D22)

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

#pragma mark Hide Handoff grabber (iOS 13+)

%hook CSMainPageView

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

#pragma mark Hide page control dots (iOS 13+)

%hook CSFixedFooterView

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

#pragma mark Lockscreen dim duration adjustments (iOS 13+)

%hook SBIdleTimerGlobalStateMonitor

-(CGFloat)minimumLockscreenIdleTime {
    if ([XENHResources lsenabled]) {
        return [XENHResources lockScreenIdleTime];
    }
    
    if (setupWindow || ![XENHResources hasDisplayedSetupUI]) {
        return 120;
    }

    return %orig;
}

%end

#pragma mark Hide SBHTML when locked.

%hook SBLockScreenManager

- (void)_setUILocked:(_Bool)arg1 {
    %orig;
    
    // Don't run on first lock
    if (![XENHResources hasSeenFirstUnlock]) return;

    if (sbhtmlViewController)
        [sbhtmlViewController setPaused:arg1];
    if (sbhtmlForegroundViewController)
        [sbhtmlForegroundViewController setPaused:arg1];
}

%end

#pragma mark Hide SBHTML when in-app

%hook SBMainWorkspace

- (void)applicationProcessDidExit:(FBApplicationProcess*)arg1 withContext:(id)arg2 {
    // Here, handle when an app crashes, or closes.
    // Furthermore, it can be assumed that SBHTML will be visible already if quit from the switcher.
    
    %orig;
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        SBApplication *frontmost = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
                   
        // Compare frontmost bundleID to arg1's.
        // If match, then the frontmost just exited and we're at the Homescreen
        
        if (!frontmost || [frontmost.bundleIdentifier isEqualToString:arg1.bundleIdentifier]) {
             XENlog(@"Showing SBHTML due to application exit onto the homescreen");
            
            [sbhtmlViewController setPaused:NO];
            [sbhtmlForegroundViewController setPaused:NO];
            
            [sbhtmlViewController doJITWidgetLoadIfNecessary];
            [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
        }
    });
}

- (void)process:(FBApplicationProcess*)arg1 stateDidChangeFromState:(FBProcessState*)arg2 toState:(FBProcessState*)arg3 {
    // When changed to state visibility Foreground, we can hide SBHTML.
    // In addition, we also do vice-versa to handle any potential issues as a failsafe.
    
    XENlog(@"Process %@ state did change to %@", arg1, arg3);
    
    %orig;
    
    // ONLY show SBHTML again if we're actually heading to SpringBoard
    dispatch_async(dispatch_get_main_queue(), ^(){
    
        // Ignore going to foreground if SpringBoard is frontmost
        BOOL isSpringBoardForeground = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication] == nil;
        
        // First, handle background -> foreground.
        if (![arg2 isForeground] && [arg3 isForeground] && !isSpringBoardForeground) {
            
            // CHECKME: When launching an app, this functions but causes the widget to disappear BEFORE the application zoom-up is done.
            // CHECMKE: When launching an app thats backgrounded, this doesn't cause the widget to disappear...
            
            XENlog(@"Hiding SBHTML due to an application becoming foreground (failsafe).");
            [sbhtmlViewController setPaused:YES animated:YES];
            [sbhtmlForegroundViewController setPaused:YES animated:YES];
                       
        // And now, handle the reverse as a failsafe.
        } else if ([arg2 isForeground] && ![arg3 isForeground] && isSpringBoardForeground) {
            XENlog(@"Showing SBHTML due to an application leaving foregound (failsafe).");
            [sbhtmlViewController setPaused:NO];
            [sbhtmlForegroundViewController setPaused:NO];
            
            [sbhtmlViewController doJITWidgetLoadIfNecessary];
            [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
        }
    
    });
}

%end

%hook SBMainWorkspace

// NOTE: Accessing layoutState here interferes with the ability to open apps
// from notifications
- (_Bool)_preflightTransitionRequest:(SBMainWorkspaceTransitionRequest*)arg1 {
    
    // We don't want to do anything when locked.
    if ([[objc_getClass("SBLockScreenManager") sharedInstance] isUILocked]) {
        return %orig;
    }
    
    if ([arg1.eventLabel isEqualToString:@"ActivateSpringBoard"] ||
        [arg1.eventLabel hasPrefix:@"ActivateSwitcher"] ) {
        
        XENlog(@"Showing SBHTML due to transition (SBMainWorkspace)");
        [sbhtmlViewController setPaused:NO];
        [sbhtmlForegroundViewController setPaused:NO];
        
        [sbhtmlViewController doJITWidgetLoadIfNecessary];
        [sbhtmlForegroundViewController doJITWidgetLoadIfNecessary];
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

#pragma mark Hide LockHTML when the display is off. (iOS 13)

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
    
    if ([XENHResources lsenabled]) {
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

#pragma mark SBHTML (iOS 13+)

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recievedSBHTMLUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlUpdate"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recievedSBHTMLUpdateForGesture:) name:@"com.matchstic.xenhtml/sbhtmlUpdateGesture" object:nil];
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

#pragma mark Handle SBHTML touches (iOS 13+)

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

#pragma mark Hide dock blur (iOS 13+)

%hook SBDockView

-(id)initWithDockListView:(id)arg1 forSnapshot:(BOOL)arg2 {
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

#pragma mark Hide dock blur (iOS 13 + iPad)

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

#pragma mark Hide folder icon blur (iOS 13+)

%hook SBFolderIconImageView

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
        #if TARGET_IPHONE_SIMULATOR==0
            [MSHookIvar<UIView*>(self, "_backgroundView") setHidden:YES];
            [MSHookIvar<UIView*>(self, "_solidColorBackgroundView") setHidden:YES];
        #endif
    }
}

%new
-(void)recievedSBHTMLUpdate:(id)sender {
    if ([XENHResources SBEnabled]) {
        #if TARGET_IPHONE_SIMULATOR==0
            [MSHookIvar<UIView*>(self, "_backgroundView") setHidden:[XENHResources hideBlurredFolderBG]];
            [MSHookIvar<UIView*>(self, "_solidColorBackgroundView") setHidden:[XENHResources hideBlurredFolderBG]];
        #endif
    }
}

%end

#pragma mark Hide icon labels (iOS 13+)

%hook SBIconView

-(id)initWithFrame:(CGRect)arg1 {
    id orig = %orig;
    [orig _xenhtml_registerNotification];
    return orig;
}

-(id)initWithConfigurationOptions:(unsigned long long)arg1 {
    id orig = %orig;
    [orig _xenhtml_registerNotification];
    return orig;
}

-(id)initWithConfigurationOptions:(unsigned long long)arg1 listLayoutProvider:(id)arg2 {
    id orig = %orig;
    [orig _xenhtml_registerNotification];
    return orig;
}

%new
- (void)_xenhtml_registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recievedSBHTMLUpdate:)
                                                 name:@"com.matchstic.xenhtml/sbhtmlIconLabelsUpdate"
                                               object:nil];
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

#pragma mark Hide SB page dots (iOS 13+)

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
            XENlog(@"Caught exception in SBRootFolderView -layoutSubviews, assuming non-fatal.");
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
    
    if ([XENHResources SBEnabled] && [XENHResources SBHidePageDots] && ![XENHResources isPageBarAvailable]) {
#if TARGET_IPHONE_SIMULATOR==0
        SBIconListPageControl *pageControl = MSHookIvar<SBIconListPageControl*>(self, "_pageControl");
        pageControl._xenhtml_hidden = YES;
        pageControl.hidden = YES;
#endif
    }
    
#pragma mark Layout foreground SBHTML add button and editing view (iOS 13+)
    
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

#pragma mark Foreground SBHTML init (iOS 13+)

%hook SBRootFolderController

- (id)initWithFolder:(id)arg1 orientation:(long long)arg2 viewMap:(id)arg3 context:(id)arg4 {
    // Set orientation?
    [XENHResources setCurrentOrientation:(int)arg2];
    
    return %orig;
}

- (void)loadView {
    %orig;
    
    XENlog(@"SBRootFolderController loadView");
    
    // Set first to allow proper layout of views
    self.contentView.scrollView._xenhtml_isForegroundWidgetHoster = YES;
    
    if ([XENHResources SBEnabled]) {
        // Add view to root scroll view, and set that scrollview to be the hoster
        sbhtmlForegroundViewController = (XENHHomescreenForegroundViewController*)[XENHResources widgetLayerControllerForLocation:kLocationSBForeground];
        [sbhtmlForegroundViewController updatePopoverPresentationController:self];
        
        [self.contentView.scrollView addSubview:sbhtmlForegroundViewController.view];
        
        XENlog(@"Added foreground SBHTML widgets view to %@", self.contentView.scrollView);
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

#pragma mark Foreground SBHTML layout (iOS 13+)

%hook SBIconScrollView

%property (nonatomic) BOOL _xenhtml_isForegroundWidgetHoster;

- (void)layoutSubviews {
    %orig;
    
    // Layout if needed
    if (self._xenhtml_isForegroundWidgetHoster) {
        
        // If the today page is hidden, then we layout by -SCREEN_WIDTH as the x origin.
        // This is to allow all existing logic inside the view controller to not need changing!
        
        // When today is hidden, the first icon list is at offset 0. Otherwise, SCREEN_WIDTH
        
        BOOL noTodayPage = NO;
        
        // There is no specific today page on iPad now
        BOOL isIpad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        if (!isIpad) {
            for (UIView *view in self.subviews) {
                // First iconlist subview
                if ([[view class] isEqual:objc_getClass("SBIconListView")]) {
                    noTodayPage = view.frame.origin.x == 0;
                    
                    break;
                }
            }
        } else {
            noTodayPage = YES;
        }
        
        sbhtmlForegroundViewController.view.frame = CGRectMake(noTodayPage ? -SCREEN_WIDTH : 0, 0, self.contentSize.width, SCREEN_HEIGHT);
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

#pragma mark Touch corrections for Per Page HTML mode (iOS 13+)

%hook SBIconListView

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([XENHResources SBEnabled] && [XENHResources SBPerPageHTMLWidgetMode]) {
        
        BOOL isDraggingIcon = [[[objc_getClass("SBIconController") sharedInstance] iconDragManager] isTrackingUserActiveIconDrags];
        
        // Allow any "overhanging" views to respond
        if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
            for (UIView *subview in self.subviews.reverseObjectEnumerator) {
                CGPoint subPoint = [subview convertPoint:point fromView:self];
                UIView *result = [subview hitTest:subPoint withEvent:event];
                if (result != nil) {
                    XENlog(@"SBIconListView hitTest (overhang) %@", result);
                    return result;
                }
            }
        }
        
        // Ignore self as a valid view when not editing
        UIView *view = %orig;
        if ([view isEqual:self] && !isDraggingIcon) {
            XENlog(@"SBIconListView hitTest set view to nil");
            view = nil;
        }
        
        return view;
    } else {
        return %orig;
    }
}

%end

#pragma mark Dock position for PerPageHTML mode (iOS 13+)

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

#pragma mark Display Homescreen foreground add button when editing (iOS 13+)

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

- (instancetype)initWithConfiguration:(id)configuration {
    if (_xenhtml_isPreviewGeneration) {
        return %orig;
    }
    
    SBRootFolderView *orig = %orig;
    
    if (orig) {
        [orig _xenhtml_initialise];
    }
    
    return orig;
}

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
    
    if (_xenhtml_inEditingMode == arg1) {
        // Already in this editing mode, not doing anything
        return;
    }
    
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
            if (finished) {
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
        if ([[view class] isEqual:objc_getClass("SBIconListView")]) {
            lowestOffset = view.frame.origin.x;
            
            break;
        }
    }
    
    BOOL isIpad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    CGFloat effectiveXOffset = lowestOffset - self.scrollView.contentOffset.x;
    if (effectiveXOffset < 0) effectiveXOffset = 0;
        
    // Due to how the Today page functions on iPad, also go to scrollview's offset
    if (isIpad) effectiveXOffset = 0;
        
    CGFloat scrollViewHeight = self.scrollView.frame.size.height;
    if ([XENHResources isHarbour2Available])
        scrollViewHeight -= 115.0; // Harbour 2 height and padding
    else if (isIpad)
        scrollViewHeight -= self.dockHeight + 20; // guesstimate
    
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

#pragma mark Ensure icons always can be tapped through the SBHTML foreground widgets view (iOS 13+)

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
        if ([[hittested class] isEqual:objc_getClass("SBIconListView")]) {
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

#pragma mark Stop jumping up bug (iOS 13+)

%hook WKWebView

- (BOOL)_shouldUpdateKeyboardWithInfo:(NSDictionary *)keyboardInfo {
    return NO;
}

%end

#pragma mark Stop white area bug (iOS 13+)

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

#pragma mark Stop magnification loupe bug (iOS 13+)

%hook UIWKTextLoupeInteraction

-(void)loupeGesture:(id)arg1 {
    return;
}

%end

#pragma mark Properly handle widget hiding on lockscreen (iOS 13)

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

#pragma mark Properly handle media controls and notification on lockscreen (iOS 13+)

// Notifications visibility
%hook CSCombinedListViewController

- (void)_setListHasContent:(_Bool)arg1 {
    %orig;
    
    BOOL shouldHide = [XENHResources LSFadeForegroundForNotifications];
    
    if (shouldHide) {
        if (arg1) {
            addForegroundHiddenRequester(@"com.matchstic.xenhtml.notifications");
        } else {
            removeForegroundHiddenRequester(@"com.matchstic.xenhtml.notifications");
        }
    }
}

%end

#pragma mark Adjust notification view positioning as required (iOS 13+)

%hook CSCombinedListViewController

- (UIEdgeInsets)_listViewDefaultContentInsets {
    UIEdgeInsets orig = %orig;
    
    if ([XENHResources lsenabled] && [XENHResources LSFullscreenNotifications]) {
        orig.top = [[UIApplication sharedApplication] statusBarFrame].size.height;
    }
    
    return orig;
}

- (void)viewWillAppear:(_Bool)arg1 {
    %orig;
    
    // Force-update listview insets for us
    [self _updateListViewContentInset];
}

%end

#pragma mark Used to forward touches to other views via a view tag. (iOS 13+)

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

%hook SBBacklightController

- (void)_lockScreenDimTimerFired {
    if (setupWindow) {
        return;
    }
    
    %orig;
}

%end

static BOOL launchCydiaForSource = NO;

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    
    // Do initial settings loading
    [XENHResources reloadSettings];
    
    // Show setup UI if needed
    if (![XENHResources hasDisplayedSetupUI]) {
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

#pragma mark Hooks for overriding WebKit behaviour

// DeviceOrientationOrMotionPermissionState WebDeviceOrientationAndMotionAccessController::cachedDeviceOrientationPermission(const SecurityOriginData& origin) const
// Override to always return DeviceOrientationOrMotionPermissionState::Granted

// See: https://github.com/WebKit/webkit/blob/master/Source/WebKit/UIProcess/WebsiteData/WebDeviceOrientationAndMotionAccessController.cpp
// Also: https://github.com/WebKit/webkit/blob/master/Source/WebCore/dom/DeviceOrientationOrMotionPermissionState.h
enum class DeviceOrientationOrMotionPermissionState : uint8_t { Granted, Denied, Prompt };
%hookf(DeviceOrientationOrMotionPermissionState, "__ZNK6WebKit45WebDeviceOrientationAndMotionAccessController33cachedDeviceOrientationPermissionERKN7WebCore18SecurityOriginDataE", void *_this, void *originData) {
    return DeviceOrientationOrMotionPermissionState::Granted;
}

// Prevent double tap to scroll

%hook WKContentView

/*- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tapRecogniser = (UITapGestureRecognizer*)gestureRecognizer;

        // check if it is a 1-finger double-tap, and ignore if so
        if (tapRecogniser.numberOfTapsRequired == 2 && tapRecogniser.numberOfTouchesRequired == 1) {
            XENlog(@"DEBUG :: Blocking %@", gestureRecognizer);
            return NO;
        }
    }
    
    return %orig;
}*/

%end

#pragma mark Initialisation and Settings callbacks

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
        
        if (objc_getClass("CSCoverSheetViewControllerBase")) {
            Class $XENDashBoardWebViewController = objc_allocateClassPair(objc_getClass("CSCoverSheetViewControllerBase"), "XENDashBoardWebViewController", 0);
            objc_registerClassPair($XENDashBoardWebViewController);
        }
        
        %init(SpringBoard);
#pragma clang diagnostic pop
        
        // Do initial settings loading
        [XENHResources reloadSettings];
        
        CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(r, NULL, XENHSettingsChanged, CFSTR("com.matchstic.xenhtml/settingschanged"), NULL, 0);
        CFNotificationCenterAddObserver(r, NULL, XENHDidModifyConfig, CFSTR("com.matchstic.xenhtml/sbconfigchanged"), NULL, 0);
        CFNotificationCenterAddObserver(r, NULL, XENHDidRequestRespring, CFSTR("com.matchstic.xenhtml/wantsrespring"), NULL, 0);
        CFNotificationCenterAddObserver(r, NULL, XENHDidModifyConfig, CFSTR("com.matchstic.xenhtml/jsconfigchanged"), NULL, 0);
    }
}
