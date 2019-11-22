//
//  Headers.h
//  Xen HTML
//
//  Created by Matt Clarke on 03/11/2019.
//

#ifndef Headers_h
#define Headers_h

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

@interface SBIdleTimerGlobalCoordinator : NSObject
+ (id)sharedInstance;
- (void)resetIdleTimer;
@end

@interface SBIdleTimerDefaults : NSObject
- (CGFloat)_xenhtml_minimumLockscreenIdleTime;
@end

@interface SBIconListView : UIView
@end

@interface SBIconView : UIView
- (void)_xenhtml_registerNotification;
@end

@interface UITapGestureRecognizer (Private)
@property (nonatomic, readonly) NSArray *touches;
@end

@protocol SBLockScreenIdleTimerControlling <NSObject>
@property(nonatomic) __weak id  idleTimerCoordinator;

@optional
- (void)removeIdleTimerDisabledAssertionReason:(NSString *)arg1;
- (void)addIdleTimerDisabledAssertionReason:(NSString *)arg1;
- (id)requestIdleTimerBehaviorForReason:(NSString *)arg1;
@end

@protocol SBLockScreenBacklightControlling <NSObject>
@property(nonatomic) double backlightLevel;
- (_Bool)shouldDisableALS;
- (void)startLockScreenFadeInAnimationForSource:(int)arg1;
- (void)setInScreenOffMode:(_Bool)arg1 forAutoUnlock:(_Bool)arg2 fromUnlockSource:(int)arg3;
- (void)setInScreenOffMode:(_Bool)arg1;
- (_Bool)isInScreenOffMode;
@end

@protocol SBIdleTimerProviding <NSObject>
- (id)coordinatorRequestedIdleTimerBehavior:(id)arg1;
@end

@protocol SBLockScreenEnvironment <NSObject>
@property(readonly, nonatomic) id <SBLockScreenIdleTimerControlling> idleTimerController;
@property(readonly, nonatomic) id <SBLockScreenBacklightControlling> backlightController;
@property(readonly, nonatomic) id <SBIdleTimerProviding> idleTimerProvider;
@property(readonly, nonatomic) UIViewController *rootViewController;
@end

@interface SBLockScreenManager : NSObject
+(instancetype)sharedInstance;
- (void)setBioUnlockingDisabled:(BOOL)disabled forRequester:(id)requester;
- (id <SBLockScreenEnvironment>)lockScreenEnvironment;
@property(readonly) _Bool isUILocked;
- (_Bool)unlockUIFromSource:(int)arg1 withOptions:(id)arg2;
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

@interface CSCoverSheetView : UIView
@property(strong, nonatomic) UIView *backgroundView;
@property(strong, nonatomic) UIView *wallpaperEffectView;
@property(readonly, nonatomic) UIView *slideableContentView;
@end

@interface SBUIProudLockIconView : UIView
- (NSInteger)state;
@end

@interface CSProudLockViewController : UIViewController
- (void)_setIconVisible:(_Bool)arg1 animated:(_Bool)arg2;
@end

// iOS 10 additions.
@interface CSBehavior : NSObject
+ (id)behaviorForProvider:(id)arg1;
+ (id)behavior;
@property(nonatomic) unsigned int restrictedCapabilities;
@property(nonatomic) int notificationBehavior;
@property(nonatomic) int scrollingMode;
@property(nonatomic) int idleWarnMode;
@property(nonatomic) int idleTimerMode;
@property(nonatomic) int idleTimerDuration;
@end

@interface CSPageViewController : UIViewController
- (void)aggregateBehavior:(id)arg1;
- (void)aggregateAppearance:(id)arg1;
@end

@interface CSAppearance : NSObject
- (void)addComponent:(id)arg1;
- (void)unionAppearance:(id)arg1;
@property(copy, nonatomic) NSSet *components;
- (void)removeComponent:(id)arg1;
@end

@interface CSComponent : NSObject
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

@interface CSCoverSheetViewControllerBase : UIViewController
- (void)registerView:(id)arg1 forRole:(long long)arg2;
- (void)unregisterView:(id)arg1;
@end

@interface CSNotificationAdjunctListViewController : CSCoverSheetViewControllerBase
@property(readonly, nonatomic, getter=isShowingMediaControls) _Bool showingMediaControls;
@end

@interface XENDashBoardWebViewController : CSCoverSheetViewControllerBase
-(void)setWebView:(UIView*)view;
@end

@interface CSPresentationViewController : CSCoverSheetViewControllerBase
- (void)dismissContentViewController:(id)arg1 animated:(_Bool)arg2;
- (void)presentContentViewController:(id)arg1 animated:(_Bool)arg2;
@end

@interface CSNotificationListViewController : CSCoverSheetViewControllerBase
@property(readonly, nonatomic) _Bool hasContent;
@end

@interface CSMainPageContentViewController : CSPresentationViewController
@property(readonly, nonatomic, getter=isShowingMediaControls) _Bool showingMediaControls;
@property(readonly, copy, nonatomic) CSBehavior *activeBehavior;
@end

@interface CSMainPageViewController : CSPageViewController
@property(readonly, nonatomic) CSMainPageContentViewController *contentViewController;
@end

@interface CSCoverSheetViewController : UIViewController
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

@interface CSCombinedListViewController : CSCoverSheetViewControllerBase
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
@property (nonatomic,readonly) double dockHeight;  // iOS 13
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

@interface SBLockScreenManager (iOS10)
- (void)setBiometricAutoUnlockingDisabled:(_Bool)arg1 forReason:(id)arg2;

@end

@interface FBApplicationProcess : NSObject
@property (nonatomic,copy,readonly) NSString * bundleIdentifier;
@end

@interface SBApplication : NSObject
@property (nonatomic,copy,readonly) NSString * bundleIdentifier;
@end

#endif /* Headers_h */
