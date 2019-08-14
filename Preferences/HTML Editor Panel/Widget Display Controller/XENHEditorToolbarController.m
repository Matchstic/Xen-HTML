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

#import "XENHEditorToolbarController.h"
#import "AYVibrantButton.h"
#import "XENHPResources.h"
#import "XENHTouchPassThroughView.h"

/* Private headers */

@interface _UIBackdropViewSettings : NSObject
+ (id)settingsForStyle:(int)arg1;
+ (id)settingsForPrivateStyle:(int)arg1;
+ (id)settingsForPrivateStyle:(long long)arg1 graphicsQuality:(long long)arg2;
- (void)setColorTint:(id)arg1;
- (void)setColorTintAlpha:(CGFloat)arg1;
@property BOOL enabled;
@end

@interface _UIBackdropView : UIView
@property bool applySettingsAfterLayout;
- (id)initWithFrame:(CGRect)arg1 autosizesToFitSuperview:(BOOL)arg2 settings:(id)arg3;
- (id)initWithPrivateStyle:(int)arg1;
- (id)initWithSettings:(id)arg1;
- (id)initWithStyle:(int)arg1;
- (void)setBlurFilterWithRadius:(CGFloat)arg1 blurQuality:(id)arg2 blurHardEdges:(int)arg3;
- (void)setBlurFilterWithRadius:(CGFloat)arg1 blurQuality:(id)arg2;
- (void)setBlurHardEdges:(int)arg1;
- (void)setBlurQuality:(id)arg1;
- (void)setBlurRadius:(CGFloat)arg1;
- (void)setBlurRadiusSetOnce:(BOOL)arg1;
- (void)setBlursBackground:(BOOL)arg1;
- (void)setBlursWithHardEdges:(BOOL)arg1;
- (void)transitionToSettings:(id)arg1;
-(id)contentView;
@property (nonatomic, strong) _UIBackdropViewSettings *inputSettings;
@end

@interface UIView (iOS11)
@property (nonatomic, readonly) UIEdgeInsets safeAreaInsets;
@end

/* Extra properties not in .h */

@interface XENHEditorToolbarController ()

@property (nonatomic, weak) id<XENHEditorToolbarDelegate> delegate;

@property (nonatomic, strong) UIVisualEffectView *editorBarVisualEffectView;
@property (nonatomic, strong) UIVisualEffectView *editorBarBackdropView;
@property (nonatomic, strong) AYVibrantButton *cancelButton;
//@property (nonatomic, strong) AYVibrantButton *addButton;
@property (nonatomic, strong) AYVibrantButton *acceptButton;
@property (nonatomic, strong) AYVibrantButton *configureButton;

@end

static CGFloat toolbarHeight = 50.0;

@implementation XENHEditorToolbarController

- (CGFloat)effectiveToolbarHeight {
    CGFloat homebarInsetY = 0.0;
    if ([self.view respondsToSelector:@selector(safeAreaInsets)]) {
        homebarInsetY = self.view.safeAreaInsets.bottom;
    }
    
    return toolbarHeight + homebarInsetY;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype)initWithDelegate:(id<XENHEditorToolbarDelegate>)delegate {
    self = [super init];
    
    if (self) {
        self.delegate = delegate;
    }
    
    return self;
}

- (void)loadView {
    self.view = [[XENHTouchPassThroughView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Load buttons.
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    
    // Backdrop
    self.editorBarBackdropView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    [self.view addSubview:self.editorBarBackdropView];
    
    if (IS_IPAD) {
        self.editorBarBackdropView.clipsToBounds = YES;
    }
    
    // Visual effect view
    self.editorBarVisualEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    [self.editorBarBackdropView.contentView addSubview:self.editorBarVisualEffectView];
    
    // Buttons.
    
    // Cancel.
    NSString *crossImagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Editor/Cancel%@", [XENHResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:crossImagePath]) {
        // handle /bootstrap
        crossImagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/Editor/Cancel%@", [XENHResources imageSuffix]];
    }
    
    self.cancelButton = [[AYVibrantButton alloc] initWithFrame:CGRectZero style:AYVibrantButtonStyleTranslucent];
    self.cancelButton.vibrancyEffect = vibrancyEffect;
    self.cancelButton.cornerRadius = 0.0;
    self.cancelButton.icon = [UIImage imageWithContentsOfFile:crossImagePath];
    [self.cancelButton addTarget:self action:@selector(cancelEditingMode:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.contentMode = UIViewContentModeRedraw;
    
    [self.editorBarVisualEffectView.contentView addSubview:self.cancelButton];
    
    // Accept
    NSString *tickImagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Editor/Accept%@", [XENHResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tickImagePath]) {
        // handle /bootstrap
        tickImagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/Editor/Accept%@", [XENHResources imageSuffix]];
    }
    
    self.acceptButton = [[AYVibrantButton alloc] initWithFrame:CGRectZero style:AYVibrantButtonStyleTranslucent];
    self.acceptButton.vibrancyEffect = vibrancyEffect;
    self.acceptButton.cornerRadius = 0.0;
    self.acceptButton.icon = [UIImage imageWithContentsOfFile:tickImagePath];
    [self.acceptButton addTarget:self action:@selector(acceptEditingMode:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.editorBarVisualEffectView.contentView addSubview:self.acceptButton];
    
    // Settings
    
    NSString *gearImagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Editor/Settings%@", [XENHResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:gearImagePath]) {
        // handle /bootstrap
        gearImagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/Editor/Settings%@", [XENHResources imageSuffix]];
    }
    
    self.configureButton = [[AYVibrantButton alloc] initWithFrame:CGRectZero style:AYVibrantButtonStyleTranslucent];
    self.configureButton.vibrancyEffect = vibrancyEffect;
    self.configureButton.cornerRadius = 0.0;
    self.configureButton.icon = [UIImage imageWithContentsOfFile:gearImagePath];
    [self.configureButton addTarget:self action:@selector(configureButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.editorBarVisualEffectView.contentView addSubview:self.configureButton];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Layout buttons.
    
    // TODO: First, get the home bar inset (if needed)
    CGFloat homebarInsetY = 0.0;
    if ([self.view respondsToSelector:@selector(safeAreaInsets)]) {
        homebarInsetY = self.view.safeAreaInsets.bottom;
    }
    
    // Handle the background region
    if (IS_IPAD) {
        // Adjust to a "floating" bar
        CGFloat ipadInset = 20.0;
        
        self.editorBarBackdropView.frame = CGRectMake(self.view.bounds.size.width * 0.2, self.view.bounds.size.height - homebarInsetY - ipadInset - toolbarHeight, self.view.bounds.size.width * 0.6, homebarInsetY + toolbarHeight);
        self.editorBarBackdropView.layer.cornerRadius = 12.5;
    } else {
        self.editorBarBackdropView.frame = CGRectMake(0, self.view.bounds.size.height - homebarInsetY - toolbarHeight, self.view.bounds.size.width, homebarInsetY + toolbarHeight);
    }
    
    self.editorBarVisualEffectView.frame = self.editorBarBackdropView.bounds;
    
    // Buttons
    self.cancelButton.frame = CGRectMake(-1.0, -1, self.editorBarBackdropView.bounds.size.width/3 + 0.5, toolbarHeight+1.5);
    self.configureButton.frame = CGRectMake(self.editorBarBackdropView.bounds.size.width/3 - 1.5, -1, self.editorBarBackdropView.bounds.size.width/3 + 3, toolbarHeight+1.5);
    self.acceptButton.frame = CGRectMake((self.editorBarBackdropView.bounds.size.width/3)*2 + 0.0, -1, self.editorBarBackdropView.bounds.size.width/3 + 1.0, toolbarHeight+1.5);
}

// Button callbacks.

-(void)cancelEditingMode:(id)sender {
    [self.delegate toolbarDidPressButton:kButtonCancel];
}

-(void)acceptEditingMode:(id)sender {
    [self.delegate toolbarDidPressButton:kButtonAccept];
}

-(void)configureButtonClicked:(id)sender {
    [self.delegate toolbarDidPressButton:kButtonSettings];
}

@end
