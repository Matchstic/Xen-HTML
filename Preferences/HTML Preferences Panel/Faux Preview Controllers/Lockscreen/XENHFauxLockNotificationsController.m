//
//  XENHFauxLockNotificationsController.m
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 15/03/2018.
//

#import "XENHFauxLockNotificationsController.h"
#import "XENHResources.h"
#import <objc/runtime.h>

@interface SBFLockScreenMetrics : NSObject
+ (CGFloat)dateViewBaselineY;
+ (CGFloat)dateBaselineOffsetFromTime;
+ (UIEdgeInsets)notificationListInsets;
+ (CGFloat)_notificationListTopPadding;
+ (CGFloat)_notificationListSideOffset;
+ (float)dateLabelFontSize;
@end


@interface XENHFauxLockNotificationsController ()

@property (nonatomic, strong) UIView *fullscreenNotificationsView;
@property (nonatomic, strong) UIView *normalNotificationsView;

@end

@implementation XENHFauxLockNotificationsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.userInteractionEnabled = NO;
    
    // Create notifications for height of display (fullscreen notifications), or for normal height notifs
    self.fullscreenNotificationsView = [self createNotificationsForFullscreen:YES];
    self.normalNotificationsView = [self createNotificationsForFullscreen:NO];
    
    [self.view addSubview:self.fullscreenNotificationsView];
    [self.view addSubview:self.normalNotificationsView];
    
    id value = [XENHResources getPreferenceKey:@"LSFullscreenNotifications"];
    BOOL isFullscreen = (value ? [value boolValue] : NO);
    
    self.fullscreenNotificationsView.hidden = !isFullscreen;
    self.normalNotificationsView.hidden = isFullscreen;
}

- (UIView*)createNotificationsForFullscreen:(BOOL)fullscreen {
    CGFloat notificationHeight = 60.0;
    CGFloat notificationGap = 7.0;
    
    // Grab the notification view insets from Apple.
    UIEdgeInsets notificationInsets = [objc_getClass("SBFLockScreenMetrics") notificationListInsets];
    notificationInsets.top += [objc_getClass("SBFLockScreenMetrics") _notificationListTopPadding] + 20.0;
    notificationInsets.left += notificationGap;
    notificationInsets.right += notificationGap;
    
    // Handle for if fullscreen
    if (fullscreen) {
        notificationInsets.top = [UIApplication sharedApplication].statusBarFrame.size.height;
        notificationInsets.bottom = 0.0;
    }
    
    CGFloat availableNotificationHeight = SCREEN_MAX_LENGTH - notificationInsets.top - notificationInsets.bottom;
    int count = ceilf(availableNotificationHeight / notificationHeight);
    
    UIView *notificationSuperview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH)];

    for (int i = 0; i <= count; i++) {
        UIView *notification = [[UIView alloc] initWithFrame:CGRectMake(notificationInsets.left, notificationInsets.top + (i * notificationHeight) + (i * notificationGap) + notificationGap, SCREEN_MIN_LENGTH - notificationInsets.left - notificationInsets.right, notificationHeight)];
        
        notification.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        notification.layer.cornerRadius = 12.5;
        
        [notificationSuperview addSubview:notification];
    }
    
    return notificationSuperview;
}

- (void)reloadForSettingsChange {
    id value = [XENHResources getPreferenceKey:@"LSFullscreenNotifications"];
    BOOL isFullscreen = (value ? [value boolValue] : NO);
    
    self.fullscreenNotificationsView.hidden = !isFullscreen;
    self.normalNotificationsView.hidden = isFullscreen;
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.fullscreenNotificationsView.frame = self.view.bounds;
    self.normalNotificationsView.frame = self.view.bounds;
}

@end
