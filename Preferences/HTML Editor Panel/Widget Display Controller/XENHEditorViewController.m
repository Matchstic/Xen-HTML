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

#import "XENHEditorViewController.h"
#import "XENHWallpaperViewController.h"
#import "XENHEditorExistingWidgetsController.h"
#import "XENHEditorWebViewController.h"
#import "XENHEditorToolbarController.h"
#import "XENHEditorDragDropController.h"
#import "XENHEditorPositioningController.h"
#import "XENHPResources.h"
#import "XENHMetadataOptionsController.h"
#import "XENHConfigJSController.h"
#import "XENHWidgetConfiguration.h"
#import "../../../Shared/Configuration/XENDWidgetConfigurationPageController.h"

#import <Preferences/PSSplitViewController.h>

@interface PSSplitViewController (UISplitViewController)
@property(nonatomic) UISplitViewControllerDisplayMode preferredDisplayMode;
@end

@interface XENHEditorViewController ()

@property (nonatomic, readwrite) XENHEditorVariant variant;
@property (nonatomic, readwrite) UIStatusBarStyle _temp_statusBarStyle;

// Constituent controllers of UI.
@property (nonatomic, strong) XENHWallpaperViewController *wallpaperController;
@property (nonatomic, strong) XENHEditorExistingWidgetsController *existingWidgetsController;
@property (nonatomic, strong) XENHEditorWebViewController *webViewController;
@property (nonatomic, strong) XENHEditorPositioningController *positioningController;
@property (nonatomic, strong) XENHEditorDragDropController *dragDropController;
@property (nonatomic, strong) XENHEditorToolbarController *toolbarController;

// Widget settings
@property (nonatomic, strong) XENHMetadataOptionsController *metadataOptions;
@property (nonatomic, strong) XENHConfigJSController *configOptions;

// Modern widget settings
@property (nonatomic, strong) NSMutableDictionary *modernConfigWidgetValues;

@end

@implementation XENHEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // We need a cached PNG of the wallpaper to render in the widget picker previewer
    [self.wallpaperController cacheWallpaperImageToFilesystem];
    
    // Update status bar style as needed
    [self.navigationController setNeedsStatusBarAppearanceUpdate];
    
    if (IS_IPAD) {
        // Hide master of the master-detail panes
        [self setRootSplitViewMasterHidden:YES];
    }
}

// Hide navigation bar
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    self._temp_statusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle]];
}

-(void)setRootSplitViewMasterHidden:(BOOL)hidden {
    PSSplitViewController *split = (PSSplitViewController*)self.navigationController.parentViewController;
    
    [UIView animateWithDuration:0.3 animations:^{
        [split setPreferredDisplayMode:hidden ? 1 : 2];
    }];
}

// Show navigation bar
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:self._temp_statusBarStyle];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    if (IS_IPAD) {
        // Show master of the master-detail panes
        [self setRootSplitViewMasterHidden:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype)initWithVariant:(XENHEditorVariant)variant widgetURL:(NSString*)widgetURL delegate:(id<XENHEditorDelegate>)delegate isNewWidget:(BOOL)isNewWidget {
    self = [super init];
    
    if (self) {
        self.variant = variant;
        self.delegate = delegate;
        self.widgetURL = widgetURL;
        self.isNewWidget = isNewWidget;
    }
    
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [self.wallpaperController isWallpaperImageDark] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark View controller loading

- (void)loadView {
    [super loadView];
    
    self.view.userInteractionEnabled = YES;
    self.view.opaque = YES;
    
    /*
     We require the following in heirarchal order:
     1. Wallpaper
     2. Existing widgets (when multiplexing)
     3. Webview
     4. Positioning
     5. Drag and drop
     6. Toolbar
     */
    
    // 1. Backing wallpaper
    self.wallpaperController = [[XENHWallpaperViewController alloc] initWithVariant:self.variant != kVariantHomescreenBackground ? 0 : 1];
    
    [self addChildViewController:self.wallpaperController];
    [self.view addSubview:self.wallpaperController.view];
    
    // 2. Any existing widgets
    self.existingWidgetsController = [[XENHEditorExistingWidgetsController alloc] initWithVariant:(int)self.variant andCurrentWidget:self.isNewWidget ? @"" :  self.widgetURL];
    
    [self addChildViewController:self.existingWidgetsController];
    [self.view addSubview:self.existingWidgetsController.view];
    
    // 3. Webview
    self.webViewController = [[XENHEditorWebViewController alloc] initWithVariant:(int)self.variant showNoHTMLLabel:NO];
    [self.webViewController reloadWebViewToPath:self.widgetURL updateMetadata:YES ignorePreexistingMetadata:NO];
    
    [self addChildViewController:self.webViewController];
    [self.view addSubview:self.webViewController.view];
    
    // 4. Positioning.
    id guideValue = (self.variant != kVariantHomescreenBackground ? [XENHResources getPreferenceKey:@"LSPickerSnapToYAxis"] : [XENHResources getPreferenceKey:@"SBPickerSnapToYAxis"]);
    BOOL snapToGuides = guideValue ? [guideValue boolValue] : YES;
    
    self.positioningController = [[XENHEditorPositioningController alloc] initWithDelegate:self shouldSnapToGuides:snapToGuides andPositioningView:self.webViewController.webView];
    
    [self addChildViewController:self.positioningController];
    [self.view addSubview:self.positioningController.view];
    
    // 5. Drag and drop
    self.dragDropController = [[XENHEditorDragDropController alloc] init];
    
    [self addChildViewController:self.dragDropController];
    [self.view addSubview:self.dragDropController.view];
    
    // 6. Toolbar
    self.toolbarController = [[XENHEditorToolbarController alloc] initWithDelegate:self];
    
    [self addChildViewController:self.toolbarController];
    [self.view addSubview:self.toolbarController.view];
    
    // That's all, folks! Nice and easy
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Update frames for our controllers.
    self.wallpaperController.view.frame = self.view.bounds;
    self.existingWidgetsController.view.frame = self.view.bounds;
    self.webViewController.view.frame = self.view.bounds;
    self.positioningController.view.frame = self.view.bounds;
    self.dragDropController.view.frame = self.view.bounds;
    self.toolbarController.view.frame = self.view.bounds;
}

#pragma mark Toolbar delegate

- (void)toolbarDidPressButton:(XENHEditorToolbarButton)button {
    switch (button) {
        case kButtonCancel:
            [self _handleCancelButtonPressed];
            break;
        
        case kButtonAccept:
            [self _handleAcceptButtonPressed];
            break;
            
        case kButtonSettings:
            [self _handleSettingsButtonPressed];
            break;
        case kButtonOverwrite:
            [self _handleOverwriteButtonPressed];
            break;;
            
        default:
            break;
    }
}

#pragma mark Handling accept and cancel buttons

- (void)_handleCancelButtonPressed {
    if (self.configOptions) {
        // Undo any changes to the config.
        [self.configOptions undoChanges];
    }
    
    // Pop this view controller off the stack
    [self _popSelfOffNavigationalStack];
}

- (void)_handleAcceptButtonPressed {
    // Save changes, then pop controller off stack
    
    [self _saveData];
    [self _popSelfOffNavigationalStack];
}

-(void)_saveData {
    // We need to save out the new metadata we have initialised in here FIRST.
    
    // XXX: Before saving, we need to ensure that the user-supplied values are sanitised.
    NSMutableDictionary *mutableMetadata = [[self.webViewController getMetadata] mutableCopy];
    if (!mutableMetadata) {
        mutableMetadata = [NSMutableDictionary dictionary];
    }
    
    CGFloat x = [[mutableMetadata objectForKey:@"x"] floatValue];
    CGFloat y = [[mutableMetadata objectForKey:@"y"] floatValue];
    
    if (x*SCREEN_WIDTH == NAN) {
        [mutableMetadata setObject:[NSNumber numberWithFloat:0] forKey:@"x"];
    } else if (x > 1.0 || x < -1.0) {
        [mutableMetadata setObject:[NSNumber numberWithFloat:0] forKey:@"x"];
    }
    
    if (y*SCREEN_HEIGHT == NAN) {
        [mutableMetadata setObject:[NSNumber numberWithFloat:0] forKey:@"y"];
    } else if (y > 1.0 || y < -1.0) {
        [mutableMetadata setObject:[NSNumber numberWithFloat:0] forKey:@"y"];
    }
    
    // Get the current URL.
    NSString *currentURL = self.widgetURL;
    
    if (!currentURL) {
        currentURL = @"";
    }
    
    [self.delegate didAcceptChanges:currentURL withMetadata:mutableMetadata isNewWidget:self.isNewWidget];
}

- (void)_popSelfOffNavigationalStack {
    // Pop self off the navigational stack
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Handling widget settings button

-(void)_handleSettingsButtonPressed {
    // Show a settings configuration UI for this widget.
    
    NSString *filepath = [self.webViewController getCurrentWidgetURL];
    NSString *path = [filepath stringByDeletingLastPathComponent];
    
    // Test against modern config first
    NSString *configJSONPath = [path stringByAppendingString:@"/config.json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:configJSONPath]) {
        NSData *jsonData = [NSData dataWithContentsOfFile:configJSONPath];
        NSError *error;
        NSDictionary *config = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
        
        UIViewController *controller;
        
        if ([config objectForKey:@"options"]) {
            // Setup
            NSMutableDictionary *values = [[[self.webViewController getMetadata] objectForKey:@"options2"] mutableCopy];
            
            if (!values) {
                values = [[XENHWidgetConfiguration defaultConfigurationForPath:filepath].optionsModern mutableCopy];
            }
            
            self.modernConfigWidgetValues = values;
            
            controller = [[XENDWidgetConfigurationPageController alloc] initWithOptions:[config objectForKey:@"options"] delegate:self title:[XENHResources localisedStringForKey:@"WIDGET_SETTINGS_TITLE"]];
        } else if (error) {
            controller = [[XENDWidgetConfigurationPageController alloc] initWithBadConfigError:error delegate:self title:[XENHResources localisedStringForKey:@"WIDGET_SETTINGS_TITLE"]];
        }
        
        if (controller) {
            // Navigation controller to allow paging, and for navigation items
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
            if (IS_IPAD) {
                navController.providesPresentationContextTransitionStyle = YES;
                navController.definesPresentationContext = YES;
                navController.modalPresentationStyle = UIModalPresentationFormSheet;
            }
            
            // Add done button.
            UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"DONE"] style:UIBarButtonItemStyleDone target:self action:@selector(closeModernOptionsModal:)];
            [[controller navigationItem] setRightBarButtonItem:done];
            
            // Show controller.
            [self.navigationController presentViewController:navController animated:YES completion:^{
                navController.presentationController.presentedView.gestureRecognizers[0].enabled = NO;
            }];
            
            return;
        }
    }
    
    
    // Legacy stuff
    // It's a total mess from here on in
    BOOL canActuallyUtiliseOptionsPlist = [XENHWidgetConfiguration shouldAllowOptionsPlist:filepath];
    
    NSString *optionsPath = [path stringByAppendingString:@"/Options.plist"];
    NSString *configJSOne = [path stringByAppendingString:@"/config.js"];
    NSString *configJSTwo = [path stringByAppendingString:@"/Config.js"];
    NSString *configJSThree = [path stringByAppendingString:@"/options.js"];
    NSString *configJSFour = [path stringByAppendingString:@"/Options.js"];
    
    if (canActuallyUtiliseOptionsPlist && [[NSFileManager defaultManager] fileExistsAtPath:optionsPath]) {
        // We can fire up the Options.plist editor!
        NSDictionary *preexistingSettings = [[self.webViewController getMetadata] objectForKey:@"options"];
        
        NSArray *plist = [NSArray arrayWithContentsOfFile:optionsPath];
        
        BOOL fallbackState = [[[self.webViewController getMetadata] objectForKey:@"useFallback"] boolValue];
        
        self.metadataOptions = [[XENHMetadataOptionsController alloc] initWithOptions:preexistingSettings fallbackState:fallbackState andPlist:plist];
        self.metadataOptions.fallbackDelegate = self;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.metadataOptions];
        if (IS_IPAD) {
            navController.providesPresentationContextTransitionStyle = YES;
            navController.definesPresentationContext = YES;
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        // Add done button.
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"DONE"] style:UIBarButtonItemStyleDone target:self action:@selector(closeMetadataOptionsModal:)];
        [[self.metadataOptions navigationItem] setRightBarButtonItem:cancel];
        
        // Show controller.
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:configJSOne]) {
        // Launch config.js editor!
        [self showConfigOptionsWithFile:configJSOne];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:configJSTwo]) {
        // Launch config.js editor!
        [self showConfigOptionsWithFile:configJSTwo];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:configJSThree]) {
        // Launch config.js editor!
        [self showConfigOptionsWithFile:configJSThree];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:configJSFour]) {
        // Launch config.js editor!
        [self showConfigOptionsWithFile:configJSFour];
    } else {
        // Just display the fallback controller
        
        BOOL fallbackState = [[[self.webViewController getMetadata] objectForKey:@"useFallback"] boolValue];
        
        XENHFallbackOnlyOptionsController *fallbackController = [[XENHFallbackOnlyOptionsController alloc] initWithFallbackState:fallbackState];
        fallbackController.fallbackDelegate = self;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:fallbackController];
        if (IS_IPAD) {
            navController.providesPresentationContextTransitionStyle = YES;
            navController.definesPresentationContext = YES;
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        // Add done button.
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"DONE"] style:UIBarButtonItemStyleDone target:self action:@selector(cancelConfigOptionsModal:)];
        [[fallbackController navigationItem] setRightBarButtonItem:cancel];
        
        // Show controller.
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
}

-(void)showConfigOptionsWithFile:(NSString*)file {
    BOOL fallbackState = [[[self.webViewController getMetadata] objectForKey:@"useFallback"] boolValue];
    
    if (!self.configOptions) {
        self.configOptions = [[XENHConfigJSController alloc] initWithFallbackState:fallbackState];
        self.configOptions.fallbackDelegate = self;
    }
    
    BOOL parseError = [self.configOptions parseJSONFile:file];
    
    if (parseError) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:[XENHResources localisedStringForKey:@"WARNING"] message:[XENHResources localisedStringForKey:@"WIDGET_EDITOR_ERROR_PARSING_CONFIGJS"] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
        
        [controller addAction:okAction];
        
        [self.navigationController presentViewController:controller animated:YES completion:nil];
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.configOptions];
    if (IS_IPAD) {
        navController.providesPresentationContextTransitionStyle = YES;
        navController.definesPresentationContext = YES;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"CANCEL"] style:UIBarButtonItemStyleDone target:self action:@selector(cancelConfigOptionsModal:)];
    [[self.configOptions navigationItem] setLeftBarButtonItem:cancel];
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"WIDGET_EDITOR_SAVE"] style:UIBarButtonItemStyleDone target:self action:@selector(saveConfigOptionsModel:)];
    [[self.configOptions navigationItem] setRightBarButtonItem:save];
    
    // Show controller.
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

-(void)closeMetadataOptionsModal:(id)sender {
    NSDictionary *changedOptions = [self.metadataOptions currentOptions];
    
    // Use current metadata (i.e. positioning) and modify that.
    NSMutableDictionary *mutableMetadata = [[self.webViewController getMetadata] mutableCopy];
    if (!mutableMetadata) {
        mutableMetadata = [NSMutableDictionary dictionary];
    }
    
    [mutableMetadata setObject:changedOptions forKey:@"options"];
    
    [self.webViewController setMetadata:mutableMetadata reloadingWebView:YES];
    [self.positioningController updatePositioningView:self.webViewController.webView];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        // Hide the modal and update SBHTML if needed
        [self _notifyHomescreenOfChangeIfNeeded];
    }];
}

- (void)closeModernOptionsModal:(id)sender {
    NSDictionary *changedOptions = self.modernConfigWidgetValues;
    
    // Use current metadata (i.e. positioning) and modify that.
    NSMutableDictionary *mutableMetadata = [[self.webViewController getMetadata] mutableCopy];
    if (!mutableMetadata) {
        mutableMetadata = [NSMutableDictionary dictionary];
    }
    
    [mutableMetadata setObject:changedOptions forKey:@"options2"];
    
    [self.webViewController setMetadata:mutableMetadata reloadingWebView:YES];
    [self.positioningController updatePositioningView:self.webViewController.webView];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        // Hide the modal and update SBHTML if needed
        [self _notifyHomescreenOfChangeIfNeeded];
    }];
}

-(void)cancelConfigOptionsModal:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        // Hide the modal
    }];
}

-(void)saveConfigOptionsModel:(id)sender {
    [self.configOptions saveData];
    [self.webViewController reloadWebViewToPath:[self.webViewController getCurrentWidgetURL] updateMetadata:NO ignorePreexistingMetadata:NO];
    
    [self.positioningController updatePositioningView:self.webViewController.webView];
    
    NSMutableDictionary *mutableMetadata = [[self.webViewController getMetadata] mutableCopy];
    if (!mutableMetadata) {
        mutableMetadata = [NSMutableDictionary dictionary];
    }
    
    [mutableMetadata setObject:[NSDate date] forKey:@"lastConfigChangeWorkaround"];
    [self.webViewController setMetadata:mutableMetadata reloadingWebView:NO];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        // Hide the modal and update SBHTML if needed
        [self _notifyHomescreenOfChangeIfNeeded];
        //[[UIApplication sharedApplication] setStatusBarHidden:NO];
    }];
}

- (void)_notifyHomescreenOfChangeIfNeeded {
    if (self.variant == kVariantHomescreenBackground) {
        CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xenhtml/sbconfigchanged";
        if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

#pragma mark Positioning delegate

- (void)didUpdatePositioningWithX:(CGFloat)x andY:(CGFloat)y {
    // User has repositioned the webview, so for now update our metadata.
    NSMutableDictionary *newMetadata = [[self.webViewController getMetadata] mutableCopy];
    [newMetadata setObject:[NSNumber numberWithFloat:x] forKey:@"x"];
    [newMetadata setObject:[NSNumber numberWithFloat:y] forKey:@"y"];
    
    [self.webViewController setMetadata:newMetadata reloadingWebView:NO];
}

- (void)didStartPositioning {
    // Animate away the toolbar
    [UIView animateWithDuration:0.15 animations:^{
        self.toolbarController.view.frame = CGRectMake(0,
                                                       [self.toolbarController effectiveToolbarHeight],
                                                       self.toolbarController.view.frame.size.width,
                                                       self.toolbarController.view.frame.size.height);
    }];
    
    [self.toolbarController notifyHiddenState:YES];
}

- (void)didEndPositioning {
    // Animate in the toolbar
    [UIView animateWithDuration:0.15 animations:^{
        self.toolbarController.view.frame = CGRectMake(0,
                                                       0,
                                                       self.toolbarController.view.frame.size.width,
                                                       self.toolbarController.view.frame.size.height);
    }];
    
    [self.toolbarController notifyHiddenState:NO];
}

#pragma mark Fallback delegate

- (void)fallbackStateDidChange:(BOOL)state {
    NSMutableDictionary *mutableMetadata = [[self.webViewController getMetadata] mutableCopy];
    if (!mutableMetadata) {
        mutableMetadata = [NSMutableDictionary dictionary];
    }
    
    [mutableMetadata setObject:[NSNumber numberWithBool:state] forKey:@"useFallback"];
    
    [self.webViewController setMetadata:mutableMetadata reloadingWebView:NO];
    //[self.delegate didAcceptChanges:[self.webViewController getCurrentWidgetURL] withMetadata:mutableMetadata];
}

#pragma mark Modern widget configuration delegate

- (NSDictionary*)currentValues {
    return self.modernConfigWidgetValues;
}

- (void)onUpdateConfiguration:(NSString*)key value:(id)value {
    if (!value) {
        NSLog(@"ERROR :: Cannot set nil value to widget configuration");
        return;
    }
    
    [self.modernConfigWidgetValues setObject:value forKey:key];
}

#pragma mark Overwrite mode

- (void)_handleOverwriteButtonPressed {
    // Check if this is a config.json widget
    BOOL valid = NO;
    
    NSString *filepath = [self.webViewController getCurrentWidgetURL];
    NSString *path = [filepath stringByDeletingLastPathComponent];
    
    NSString *configJSONPath = [path stringByAppendingString:@"/config.json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:configJSONPath]) {
        NSData *jsonData = [NSData dataWithContentsOfFile:configJSONPath];
        NSError *error;
        NSDictionary *config = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
        
        valid = config && [config objectForKey:@"options"];
    }
    
    NSString *title   = [XENHResources localisedStringForKey:@"OVERWRITE_MODE_BUTTON_TITLE"];
    NSString *warning = [XENHResources localisedStringForKey:@"OVERWRITE_MODE_WARNING"];
    NSString *unavailable = [XENHResources localisedStringForKey:@"OVERWRITE_MODE_NOT_AVAILABLE"];
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title
                                                                        message:valid ? warning : unavailable
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        BOOL success = [self applyOverwrites];
        [self handleOverwriteFinishState:success];
    }];
    
    if (valid) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"CANCEL"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [controller addAction:cancelAction];
    }
    
    [controller addAction:okAction];
    
    UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
    [rootController presentViewController:controller animated:YES completion:nil];
}

- (BOOL)applyOverwrites {
    NSDictionary *keypairs = self.modernConfigWidgetValues;
    
    // Load from filesystem
    NSString *filepath = [self.webViewController getCurrentWidgetURL];
    NSString *path = [filepath stringByDeletingLastPathComponent];
    
    NSString *configJSONPath = [path stringByAppendingString:@"/config.json"];

    NSData *jsonData = [NSData dataWithContentsOfFile:configJSONPath];
    NSError *error;
    NSMutableDictionary *config = [[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error] mutableCopy];
    
    if (error || !config) return NO;
    
    // Mutate options
    NSMutableArray *mutableOptions = [[config objectForKey:@"options"] mutableCopy];
    
    for (NSDictionary *optionRow in [mutableOptions copy]) {
        NSInteger index = [mutableOptions indexOfObject:optionRow];
        
        if (![optionRow objectForKey:@"default"]) continue;
        
        NSString *key = [optionRow objectForKey:@"key"];
        if (!key) continue;
        
        id newValue = [keypairs objectForKey:key];
        
        if (!newValue) continue;
        
        NSMutableDictionary *mutableOptionRow = [optionRow mutableCopy];
        [mutableOptionRow setObject:newValue forKey:@"default"];
        
        [mutableOptions replaceObjectAtIndex:index withObject:mutableOptionRow];
    }
    
    [config setObject:mutableOptions forKey:@"options"];
    
    // Save to disk
    NSError *errorJSONGeneration;
    NSData *generatedJSON = [NSJSONSerialization dataWithJSONObject:config
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&errorJSONGeneration];
    
    if (errorJSONGeneration || !generatedJSON) return NO;
    if (![generatedJSON writeToFile:configJSONPath atomically:NO]) return NO;
    
    return YES;
}

- (void)handleOverwriteFinishState:(BOOL)state {
    NSString *title   = [XENHResources localisedStringForKey:@"OVERWRITE_MODE_BUTTON_TITLE"];
    NSString *success = [XENHResources localisedStringForKey:@"OVERWRITE_MODE_SUCCESS"];
    NSString *failed  = [XENHResources localisedStringForKey:@"OVERWRITE_MODE_FAILED"];
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title
                                                                        message:state ? success : failed
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    
    [controller addAction:okAction];
    
    UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
    [rootController presentViewController:controller animated:YES completion:nil];
}

@end
