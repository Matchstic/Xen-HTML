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
#import "XENHEditorWebViewController.h"
#import "XENHEditorToolbarController.h"
#import "XENHEditorDragDropController.h"
#import "XENHEditorPositioningController.h"
#import "XENHResources.h"
#import "XENHMetadataOptionsController.h"
#import "XENHConfigJSController.h"

#import <Preferences/PSSplitViewController.h>

@interface PSSplitViewController (UISplitViewController)
@property(nonatomic) UISplitViewControllerDisplayMode preferredDisplayMode;
@end

@interface XENHEditorViewController ()

@property (nonatomic, readwrite) XENHEditorVariant variant;

// Constituent controllers of UI.
@property (nonatomic, strong) XENHWallpaperViewController *wallpaperController;
@property (nonatomic, strong) XENHEditorWebViewController *webViewController;
@property (nonatomic, strong) XENHEditorPositioningController *positioningController;
@property (nonatomic, strong) XENHEditorDragDropController *dragDropController;
@property (nonatomic, strong) XENHEditorToolbarController *toolbarController;

// Widget settings
@property (nonatomic, strong) XENHMetadataOptionsController *metadataOptions;
@property (nonatomic, strong) XENHConfigJSController *configOptions;

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
    //[[UIApplication sharedApplication] setStatusBarHidden:NO];
    //[[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle]];
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
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    //[[UIApplication sharedApplication] setStatusBarStyle:[self.navigationController preferredStatusBarStyle]];
    
    if (IS_IPAD) {
        // Show master of the master-detail panes
        [self setRootSplitViewMasterHidden:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype)initWithVariant:(XENHEditorVariant)variant {
    self = [super init];
    
    if (self) {
        self.variant = variant;
    }
    
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [self.wallpaperController isWallpaperImageDark] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
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
     2. Webview
     3. Positioning
     4. Drag and drop
     5. Toolbar
     */
    
    // 1. Backing wallpaper
    self.wallpaperController = [[XENHWallpaperViewController alloc] initWithVariant:self.variant != kVariantHomescreenBackground ? 0 : 1];
    
    [self addChildViewController:self.wallpaperController];
    [self.view addSubview:self.wallpaperController.view];
    
    // 2. Webview
    self.webViewController = [[XENHEditorWebViewController alloc] initWithVariant:self.variant showNoHTMLLabel:YES];
    [self.webViewController reloadWebViewToPath:[self indexHTMLFileForCurrentVariant] updateMetadata:YES ignorePreexistingMetadata:NO];
    
    [self addChildViewController:self.webViewController];
    [self.view addSubview:self.webViewController.view];
    
    // 3. Positioning.
    id guideValue = (self.variant != kVariantHomescreenBackground ? [XENHResources getPreferenceKey:@"LSPickerSnapToYAxis"] : [XENHResources getPreferenceKey:@"SBPickerSnapToYAxis"]);
    BOOL snapToGuides = guideValue ? [guideValue boolValue] : YES;
    
    self.positioningController = [[XENHEditorPositioningController alloc] initWithDelegate:self shouldSnapToGuides:snapToGuides andPositioningView:self.webViewController.webView];
    
    [self addChildViewController:self.positioningController];
    [self.view addSubview:self.positioningController.view];
    
    // 4. Drag and drop
    self.dragDropController = [[XENHEditorDragDropController alloc] init];
    
    [self addChildViewController:self.dragDropController];
    [self.view addSubview:self.dragDropController.view];
    
    // 5. Toolbar
    self.toolbarController = [[XENHEditorToolbarController alloc] initWithDelegate:self];
    
    [self addChildViewController:self.toolbarController];
    [self.view addSubview:self.toolbarController.view];
    
    // That's all, folks! Nice and easy
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Update frames for our controllers.
    self.wallpaperController.view.frame = self.view.bounds;
    self.webViewController.view.frame = self.view.bounds;
    self.positioningController.view.frame = self.view.bounds;
    self.dragDropController.view.frame = self.view.bounds;
    self.toolbarController.view.frame = self.view.bounds;
}

#pragma mark Assorted junk from the trunk

-(NSString*)indexHTMLFileForCurrentVariant {
    NSString *fileString = @"";
    
    [XENHResources reloadSettings];
    
    switch (self.variant) {
        case kVariantLockscreenBackground:
            fileString = [XENHResources backgroundLocation];
            break;
        case kVariantLockscreenForeground:
            fileString = [XENHResources foregroundLocation];
            break;
        case kVariantHomescreenBackground:
            fileString = [XENHResources SBLocation];
            break;
    }
    
    return fileString;
}

#pragma mark Toolbar delegate

- (void)toolbarDidPressButton:(XENHEditorToolbarButton)button {
    switch (button) {
        case kButtonCancel:
            [self _handleCancelButtonPressed];
            break;
            
        case kButtonModify:
            [self _handleModifyButtonPressed];
            break;
        
        case kButtonAccept:
            [self _handleAcceptButtonPressed];
            break;
            
        case kButtonSettings:
            [self _handleSettingsButtonPressed];
            break;
            
        default:
            break;
    }
}

- (void)_handleModifyButtonPressed {
    // Launch widget picker UI.
    
    XENHPickerController2 *mc = [[XENHPickerController2 alloc] initWithVariant:self.variant != kVariantHomescreenBackground ? 0 : 2 andDelegate:self andCurrentSelected:[self.webViewController getCurrentWidgetURL]];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mc];
    if (IS_IPAD) {
        navController.providesPresentationContextTransitionStyle = YES;
        navController.definesPresentationContext = YES;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

#pragma mark Handling accept and cancel buttons

- (void)_handleCancelButtonPressed {
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
    NSString *key = @"";
    switch (_variant) {
        case 0:
            key = @"LSBackground";
            break;
        case 1:
            key = @"LSForeground";
            break;
        case 2:
            key = @"SBBackground";
            break;
            
        default:
            break;
    }
    
    NSMutableDictionary *dict = [[XENHResources getPreferenceKey:@"widgetPrefs"] mutableCopy];
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
    }
    
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
    
    [dict setObject:mutableMetadata forKey:key];
    
    [XENHResources setPreferenceKey:@"widgetPrefs" withValue:dict];
    
    // Get the current URL.
    NSString *currentURL = [self.webViewController getCurrentWidgetURL];
    
    if (!currentURL) {
        currentURL = @"";
    }
    
    // Update prefs
    switch (self.variant) {
        case kVariantLockscreenBackground:
            [XENHResources setPreferenceKey:@"backgroundLocation" withValue:currentURL];
            break;
        case kVariantLockscreenForeground:
            [XENHResources setPreferenceKey:@"foregroundLocation" withValue:currentURL];
            break;
        case kVariantHomescreenBackground:
            [XENHResources setPreferenceKey:@"SBLocation" withValue:currentURL];
            break;
    }
    
    if (_variant == 2) {
        // Failsafe to reload SBHTML on metadata-only changes.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/sbconfigchanged" object:nil];
        
        CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xenhtml/sbconfigchanged";
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
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
    NSString *lastPathComponent = [filepath lastPathComponent];
    
    BOOL canActuallyUtiliseOptionsPlist = NO;
    
    NSString *widgetInfoPlistPath = [path stringByAppendingString:@"/WidgetInfo.plist"];
    if ([lastPathComponent isEqualToString:@"Widget.html"] || [[NSFileManager defaultManager] fileExistsAtPath:widgetInfoPlistPath]) {
        canActuallyUtiliseOptionsPlist = YES;
    }
    
    NSString *optionsPath = [path stringByAppendingString:@"/Options.plist"];
    NSString *configJSOne = [path stringByAppendingString:@"/config.js"];
    NSString *configJSTwo = [path stringByAppendingString:@"/Config.js"];
    NSString *configJSThree = [path stringByAppendingString:@"/options.js"];
    NSString *configJSFour = [path stringByAppendingString:@"/Options.js"];
    
    if (canActuallyUtiliseOptionsPlist && [[NSFileManager defaultManager] fileExistsAtPath:optionsPath]) {
        // We can fire up the Options.plist editor!
        NSDictionary *preexistingSettings = [[self.webViewController getMetadata] objectForKey:@"options"];
        
        NSArray *plist = [NSArray arrayWithContentsOfFile:optionsPath];
        
        self.metadataOptions = [[XENHMetadataOptionsController alloc] initWithOptions:preexistingSettings andPlist:plist];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.metadataOptions];
        if (IS_IPAD) {
            navController.providesPresentationContextTransitionStyle = YES;
            navController.definesPresentationContext = YES;
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        // Add done button.
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"Done" value:@"Done"] style:UIBarButtonItemStyleDone target:self action:@selector(closeMetadataOptionsModal:)];
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
        // Cannot find settings!
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:[XENHResources localisedStringForKey:@"Error" value:@"Error"]
                                                     message:[XENHResources localisedStringForKey:@"Could not find a settings file for this widget" value:@"Could not find a settings file for this widget"]
                                                    delegate:nil
                                           cancelButtonTitle:[XENHResources localisedStringForKey:@"OK" value:@"OK"]
                                           otherButtonTitles:nil];
        [av show];
    }
}

-(void)showConfigOptionsWithFile:(NSString*)file {
    self.configOptions = [[XENHConfigJSController alloc] initWithStyle:UITableViewStyleGrouped];
    BOOL parseError = [self.configOptions parseJSONFile:file];
    
    if (parseError) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:[XENHResources localisedStringForKey:@"Warning" value:@"Warning"]
                                                     message:[XENHResources localisedStringForKey:@"There was an error parsing the settings file; some options may be missing" value:@"There was an error parsing the settings file; some options may be missing"]
                                                    delegate:nil
                                           cancelButtonTitle:[XENHResources localisedStringForKey:@"OK" value:@"OK"]
                                           otherButtonTitles:nil];
        [av show];
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.configOptions];
    if (IS_IPAD) {
        navController.providesPresentationContextTransitionStyle = YES;
        navController.definesPresentationContext = YES;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"Cancel" value:@"Cancel"] style:UIBarButtonItemStyleDone target:self action:@selector(cancelConfigOptionsModal:)];
    [[self.configOptions navigationItem] setLeftBarButtonItem:cancel];
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"Save" value:@"Save"] style:UIBarButtonItemStyleDone target:self action:@selector(saveConfigOptionsModel:)];
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
        //[[UIApplication sharedApplication] setStatusBarHidden:NO];
    }];
}

-(void)cancelConfigOptionsModal:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        // Hide the modal
        //[[UIApplication sharedApplication] setStatusBarHidden:NO];
    }];
}

-(void)saveConfigOptionsModel:(id)sender {
    [self.configOptions saveData];
    [self.webViewController reloadWebViewToPath:[self.webViewController getCurrentWidgetURL] updateMetadata:YES ignorePreexistingMetadata:NO];
    
    [self.positioningController updatePositioningView:self.webViewController.webView];
    
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

#pragma mark Widget Picker delegate

-(void)didChooseWidget:(NSString *)filePath {
    // User chose a new widget to render, so let's go for it!
    [self.webViewController reloadWebViewToPath:filePath updateMetadata:YES ignorePreexistingMetadata:YES];
    
    // Eh
    [self.positioningController updatePositioningView:self.webViewController.webView];
    
    // Show hint for drag and drop
    if (![filePath isEqualToString:@""])
        [self.dragDropController showDragAndDropHint];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        //[[UIApplication sharedApplication] setStatusBarHidden:NO];
    }];
}

-(void)cancelShowingPicker {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        //[[UIApplication sharedApplication] setStatusBarHidden:NO];
    }];
}

@end
