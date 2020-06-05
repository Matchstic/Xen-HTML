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

#import "XENHHomescreenForegroundViewController.h"
#import "XENHTouchPassThroughView.h"
#import "XENHWidgetController.h"

#import "XENHMetadataOptionsController.h"
#import "XENHConfigJSController.h"
#import "XENHFallbackOnlyOptionsController.h"
#import "XENHResources.h"
#import "XENHWidgetConfiguration.h"

@interface SBRootFolderView : UIView
@property (nonatomic, strong) XENHTouchPassThroughView *_xenhtml_editingPlatter;

- (void)_xenhtml_showVerticalEditingGuide;
- (void)_xenhtml_hideVerticalEditingGuide;
@end

@interface SBIconListView : UIView
- (_Bool)isEmpty;
@end

@interface SBRootFolderController : UIViewController
- (SBRootFolderView*)_xenhtml_contentView;
- (long long)_xenhtml_currentPageIndex;
- (_Bool)setCurrentPageIndex:(long long)arg1 animated:(_Bool)arg2;
- (SBIconListView*)iconListViewAtIndex:(unsigned long long)arg1;
@property(readonly, nonatomic) long long todayViewPageIndex;
@end


@interface XENHWidgetLayerController (Private)
- (void)_setupMultiplexedWidgetsForLocation:(XENHLayerLocation)location;
@end

@interface XENHHomescreenForegroundViewController ()

@property (nonatomic, weak) SBRootFolderController *popoverPresentationController;
@property (nonatomic, readwrite) BOOL isEditing;

@end

@implementation XENHHomescreenForegroundViewController

// Overriden
- (instancetype)initWithLayerLocation:(XENHLayerLocation)location {
    return [super initWithLayerLocation:kLocationSBForeground];
}

// Overriden
- (void)loadView {
    // Allow superclass to setup widgets
    [super loadView];
    
    // Anything else?
}

// Overriden for correct layout
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self _layoutWidgets];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self _layoutWidgets];
}

- (void)_layoutWidgets {
    
    static int lastOrientation = 0;
    
    // Correctly layout widget controllers too!
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        // Get the controller's metadata.
        
        // We assume each the widget hosted by this controller is placed at (0,0), so we can
        // just shift the controller's view's origin as needed.
        
        NSDictionary *metadata = widgetController.widgetMetadata;
        
        CGFloat xOffsetMultipler = 0;
        CGFloat yOffsetMultipler = 0;
        
        BOOL shouldAnimateFrame = lastOrientation != [XENHResources getCurrentOrientation] && lastOrientation != 0;
        lastOrientation = [XENHResources getCurrentOrientation];
        
        if ([XENHResources getCurrentOrientation] == 1 || [XENHResources getCurrentOrientation] == 2) {
            xOffsetMultipler = [[metadata objectForKey:@"xPortrait"] doubleValue];
            yOffsetMultipler = [[metadata objectForKey:@"yPortrait"] doubleValue];
        } else {
            // Use landscape settings if possible, else portrait otherwise
            if ([[metadata allKeys] containsObject:@"xLandscape"]) {
                xOffsetMultipler = [[metadata objectForKey:@"xLandscape"] doubleValue];
                yOffsetMultipler = [[metadata objectForKey:@"yLandscape"] doubleValue];
            } else {
                xOffsetMultipler = [[metadata objectForKey:@"xPortrait"] doubleValue];
                yOffsetMultipler = [[metadata objectForKey:@"yPortrait"] doubleValue];
            }
        }
        
        CGRect rect = CGRectMake(xOffsetMultipler * SCREEN_WIDTH, yOffsetMultipler * SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
        
        if (shouldAnimateFrame) {
            [UIView animateWithDuration:0.15 animations:^{
                widgetController.view.frame = rect;
            }];
        } else {
            widgetController.view.frame = rect;
        }
    }
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Handling of settings changes and user interaction
/////////////////////////////////////////////////////////////////////////////

// Overriden
- (void)noteUserPreferencesDidChange {
    // TODO: Handle preference changes, such as:
    // - Snapping to placement grid
    // - Enabled state
    
    [super noteUserPreferencesDidChange];
    
    // Set editing delegate on any new widgets
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        widgetController.editingDelegate = self;
    }
}

- (void)noteUserDidPressAddWidgetButton {
    // Launch widget picker UI.
    
    NSArray *currentlySelectedWidgets = [self.layerPreferences objectForKey:@"widgetArray"];
    
    XENHHomescreenForegroundPickerController *mc = [[XENHHomescreenForegroundPickerController alloc] initWithDelegate:self andCurrentSelectedArray:currentlySelectedWidgets];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mc];
    if (IS_IPAD) {
        navController.providesPresentationContextTransitionStyle = YES;
        navController.definesPresentationContext = YES;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self.popoverPresentationController presentViewController:navController animated:YES completion:nil];
}

+ (UIViewController*)_widgetSettingsControllerWithURL:(NSString*)widgetURL currentMetadata:(NSDictionary*)currentMetadata showCancel:(BOOL)showCancel andDelegate:(id<XENHHomescreenForegroundPickerDelegate>)delegate {
    
    NSString *path = [widgetURL stringByDeletingLastPathComponent];
    if ([path hasPrefix:@":"]) {
        // Read the string up to the first /, then strip off the : prefix.
        NSRange range = [path rangeOfString:@"/"];
        path = [path substringFromIndex:range.location];
    }
    
    // Check for Options.plist support
    BOOL canActuallyUtiliseOptionsPlist = [XENHWidgetConfiguration shouldAllowOptionsPlist:widgetURL];
    
    NSString *optionsPath = [path stringByAppendingString:@"/Options.plist"];
    BOOL fallbackState = [[currentMetadata objectForKey:@"useFallback"] boolValue];
    
    if (canActuallyUtiliseOptionsPlist && [[NSFileManager defaultManager] fileExistsAtPath:optionsPath]) {
        // We can fire up the Options.plist editor!
        NSDictionary *preexistingSettings = [currentMetadata objectForKey:@"options"];
        
        NSArray *plist = [NSArray arrayWithContentsOfFile:optionsPath];
        
        XENHMetadataOptionsController *_controller = [[XENHMetadataOptionsController alloc] initWithOptions:preexistingSettings fallbackState:fallbackState andPlist:plist];
        _controller.delegate = delegate;
        _controller.widgetURL = widgetURL;
        _controller.showCancel = showCancel;
        
        return _controller;
    }
    
    // If any of the config.js variants exist, use it
    NSArray *configFileVariants = @[@"/config.js", @"/Config.js", @"/options.js", @"/Options.js"];
    for (NSString *variant in configFileVariants) {
        NSString *testingPath = [path stringByAppendingString:variant];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:testingPath]) {
            XENHConfigJSController *_controller = [[XENHConfigJSController alloc] initWithFallbackState:fallbackState];
            _controller.delegate = delegate;
            _controller.widgetURL = widgetURL;
            _controller.showCancel = showCancel;
            
            // Parse the config file
            if ([_controller parseJSONFile:testingPath]) {
                UIAlertController *controller = [UIAlertController alertControllerWithTitle:[XENHResources localisedStringForKey:@"WARNING"] message:[XENHResources localisedStringForKey:@"WIDGET_EDITOR_ERROR_PARSING_CONFIGJS"] preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:[XENHResources localisedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
                
                [controller addAction:okAction];
                
                UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
                [rootController presentViewController:controller animated:YES completion:nil];
            }
            
            return _controller;
        }
    }
    
    // Failsafe, just the fallback controller
    XENHFallbackOnlyOptionsController *_controller = [[XENHFallbackOnlyOptionsController alloc] initWithFallbackState:fallbackState];
    _controller.delegate = delegate;
    _controller.widgetURL = widgetURL;
    _controller.showCancel = showCancel;
    
    return _controller;
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Widget picker delegate
/////////////////////////////////////////////////////////////////////////////

- (void)didChooseWidget:(NSString*)filePath withMetadata:(NSDictionary*)options fallbackState:(BOOL)state {
    // User did choose a widget!
    
    BOOL isNewWidget = ![filePath hasPrefix:@":"];
    
    /*
     * Widget data format:
       widgets: {
         SBForeground: {
            widgetArray: [ widgetUrl, .. ]
            widgetMetadata: {
                widgetUrl: {
                    height (int, pts)
                    options: {} (options coming in here)
                    useFallback: (state coming in here)
                    width (int, pts)
                    x (float, % of screen width portrait)
                    y (float, % of screen height portrait)
                    xLandscape (float, % of screen width landscape)
                    yLandscape (float, % of screen height landscape)
                }
            }
         }
       }
     */
    
    NSMutableDictionary *layerPreferences = [[XENHResources widgetPreferencesForLocation:kLocationSBForeground] mutableCopy];
    
    if (!layerPreferences)
        layerPreferences = [@{} mutableCopy];
    
    NSMutableDictionary *widgetMetadata;
    if (isNewWidget) {
        widgetMetadata = [[[XENHWidgetConfiguration defaultConfigurationForPath:filePath] serialise] mutableCopy];
    } else {
        widgetMetadata = [[[layerPreferences objectForKey:@"widgetMetadata"] objectForKey:filePath] mutableCopy];
    }
    
    if (!widgetMetadata)
        widgetMetadata = [NSMutableDictionary dictionary];
    
    [widgetMetadata setObject:options forKey:@"options"];
    [widgetMetadata setObject:[NSNumber numberWithBool:state] forKey:@"useFallback"];
    
    if (!options || options.allKeys.count == 0) // config.js hack
        [widgetMetadata setObject:[NSDate date] forKey:@"lastConfigChangeWorkaround"];
    
    if (isNewWidget) {
        // Set the default x and y positions for the new widget based on the current page
        
        [widgetMetadata removeObjectForKey:@"x"];
        [widgetMetadata removeObjectForKey:@"y"];
        
        // Convert the origin from the _xenhtml_contentView to our view to auto-handle scroll offsets
        // etc
        
        CGPoint origin = CGPointMake(SCREEN_WIDTH/2 - [[widgetMetadata objectForKey:@"width"] floatValue]/2,
                                     SCREEN_HEIGHT/2 - [[widgetMetadata objectForKey:@"height"] floatValue]/2);
        
        origin = [self.popoverPresentationController._xenhtml_contentView convertPoint:origin toView:self.view];
        
        CGFloat newX = origin.x;
        // Convert to percentages of the display width
        newX /= SCREEN_WIDTH;
        
        CGFloat newY = origin.y;
        // Convert to percentages of the display height
        newY /= SCREEN_HEIGHT;
        
        if (newY < 0)
            newY = 0;
        
        [widgetMetadata setObject:[NSNumber numberWithDouble:newX] forKey:@"xPortrait"];
        [widgetMetadata setObject:[NSNumber numberWithDouble:newY] forKey:@"yPortrait"];
        
        // No default landscape settings -> use portrait by default unless user-set
    }
    
    XENlog(@"New metadata: %@", widgetMetadata);
    
    // Store this new metadata and widget data if new widget
    
    if (isNewWidget) {
        NSMutableArray *widgetArray = [[layerPreferences objectForKey:@"widgetArray"] mutableCopy];
        if (!widgetArray) {
            widgetArray = [NSMutableArray array];
        }
        
        // XXX: If this widget has already been chosen, we need to append :1/..., :2/...
        // to it, to support multiples of the same widget
        
        int count = 0;
        
        for (NSString *location in widgetArray) {
            if ([location containsString:filePath] || [location isEqualToString:filePath])
                count++;
        }
        
        // Add a prefix to differentiate the widget
        NSString *widgetPrefix = [NSString stringWithFormat:@":%d", count];
        filePath = [NSString stringWithFormat:@"%@%@", widgetPrefix, filePath];
        
        // Save the widget into the array
        [widgetArray addObject:filePath];
        [layerPreferences setObject:widgetArray forKey:@"widgetArray"];
    }
    
    // And now for the metadata
    NSMutableDictionary *layerWidgetMetadata = [[layerPreferences objectForKey:@"widgetMetadata"] mutableCopy];
    if (!layerWidgetMetadata) {
        layerWidgetMetadata = [NSMutableDictionary dictionary];
    }
    
    [layerWidgetMetadata setObject:widgetMetadata forKey:filePath];
    
    // Save up.
    [layerPreferences setObject:layerWidgetMetadata forKey:@"widgetMetadata"];
    
    // And now write the layer preferences
    [XENHResources setWidgetPreferences:layerPreferences forLocation:kLocationSBForeground];
    
    // Load new widget
    [self reloadWithNewLayerPreferences:layerPreferences oldPreferences:self.layerPreferences];
    
    // Set editing delegate on any new widgets
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        widgetController.editingDelegate = self;
    }
    
    [self updateEditingModeState:self.isEditing];
    
    // Hide the popup
    [self.popoverPresentationController dismissViewControllerAnimated:YES completion:^{
        // nop.
    }];
}

- (void)cancelShowingPicker {
    [self.popoverPresentationController dismissViewControllerAnimated:YES completion:^{
        // nop.
    }];
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Handle incoming messages from hooked methods
/////////////////////////////////////////////////////////////////////////////

- (void)updatedPageCounts:(int)newCount {
    // TODO: handle change of page counts.
    // i.e., unload any widgets outside the new page counts.
}

- (void)updateEditingModeState:(BOOL)newEditingModeState {
    self.isEditing = newEditingModeState;
    
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        [widgetController setEditing:newEditingModeState];
    }
}

- (void)updatePopoverPresentationController:(id)controller {
    self.popoverPresentationController = controller;
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Editing delegate methods
/////////////////////////////////////////////////////////////////////////////

- (void)reloadWidgets:(BOOL)clearWidgets {
    [super reloadWidgets:clearWidgets];
    
    // Set editing delegate
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        widgetController.editingDelegate = self;
    }
}

- (void)_setupMultiplexedWidgetsForLocation:(XENHLayerLocation)location {
    [super _setupMultiplexedWidgetsForLocation:location];
    
    // Set editing delegate
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        widgetController.editingDelegate = self;
    }
}

- (void)requestRemoveWidget:(NSString*)widgetURL {
    NSMutableDictionary *layerPreferences = [[XENHResources widgetPreferencesForLocation:kLocationSBForeground] mutableCopy];
    if (!layerPreferences)
        layerPreferences = [@{} mutableCopy];
    
    // widgetArray
    NSMutableArray *widgetArray = [[layerPreferences objectForKey:@"widgetArray"] mutableCopy];
    if (!widgetArray) {
        widgetArray = [NSMutableArray array];
    }
    
    [widgetArray removeObject:widgetURL];
    
    [layerPreferences setObject:widgetArray forKey:@"widgetArray"];
    
    // Now, metadata
    NSMutableDictionary *layerWidgetMetadata = [[layerPreferences objectForKey:@"widgetMetadata"] mutableCopy];
    if (!layerWidgetMetadata) {
        layerWidgetMetadata = [NSMutableDictionary dictionary];
    }
    
    [layerWidgetMetadata removeObjectForKey:widgetURL];
    
    // Save up.
    [layerPreferences setObject:layerWidgetMetadata forKey:@"widgetMetadata"];
    
    // And now write the layer preferences
    [XENHResources setWidgetPreferences:layerPreferences forLocation:kLocationSBForeground];
    
    // Animate this widget out, and reload prefs
    XENHWidgetController *widgetController = [self.multiplexedWidgets objectForKey:widgetURL];
    [UIView animateWithDuration:0.15 animations:^{
        widgetController.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        // Reload prefs
        if (finished)
            [self noteUserPreferencesDidChange];
    }];
}

- (void)requestSettingsAdjustmentForWidget:(NSString*)widgetURL {
    NSDictionary *layerPreferences = [XENHResources widgetPreferencesForLocation:kLocationSBForeground];
    
    if (!layerPreferences)
        layerPreferences = @{};
    
    NSMutableDictionary *widgetMetadata = [[layerPreferences objectForKey:@"widgetMetadata"] objectForKey:widgetURL];
    
    UIViewController *mc = [XENHHomescreenForegroundViewController _widgetSettingsControllerWithURL:widgetURL currentMetadata:widgetMetadata showCancel:YES andDelegate:self];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mc];
    if (IS_IPAD) {
        navController.providesPresentationContextTransitionStyle = YES;
        navController.definesPresentationContext = YES;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self.popoverPresentationController presentViewController:navController animated:YES completion:nil];
}

- (void)notifyWidgetPositioningDidBegin:(XENHWidgetController*)widgetController {
    // Put this widget controller onto the editing platter
    UIView *platter = self.popoverPresentationController._xenhtml_contentView._xenhtml_editingPlatter;
    
    // Convert current widget position from scrollview
    CGPoint convertedPosition = [self.view convertPoint:widgetController.view.frame.origin toView:platter];
    
    XENlog(@"Placing at converted position: %@", NSStringFromCGPoint(convertedPosition));
    
    [platter addSubview:widgetController.view];
    widgetController.view.frame = CGRectMake(convertedPosition.x, convertedPosition.y, widgetController.view.frame.size.width, widgetController.view.frame.size.height);
    
    // Show alignment guide
    [self.popoverPresentationController._xenhtml_contentView _xenhtml_showVerticalEditingGuide];
}

- (void)notifyWidgetPositioningDidEnd:(XENHWidgetController*)widgetController {
    // Take this widget controller off the editing platter, making sure to set
    // the current co-ordinates of it into preferences
    
    UIView *platter = self.popoverPresentationController._xenhtml_contentView._xenhtml_editingPlatter;
    
    // Convert current widget position to the scrollview
    CGPoint convertedPosition = [platter convertPoint:widgetController.view.center toView:self.view];
    
    XENlog(@"Dropping at point: %@", NSStringFromCGPoint(convertedPosition));
    
    // Set widget metadata for the next layout
    NSMutableDictionary *metadata = [widgetController.widgetMetadata mutableCopy];
    
    CGPoint convertedFrameOrigin = [platter convertPoint:widgetController.view.frame.origin toView:self.view];
    CGFloat convertedXFrame = convertedFrameOrigin.x;
    
    CGFloat scaledXPosition = convertedXFrame / SCREEN_WIDTH;
    CGFloat scaledYPosition = widgetController.view.frame.origin.y / SCREEN_HEIGHT;
    
    XENlog(@"Scaled position, X: %f, Y: %f", scaledXPosition, scaledYPosition);
    
    BOOL isPortrait = (orient3 == 1 || orient3 == 2);
    if (isPortrait) {
        [metadata setObject:[NSNumber numberWithDouble:scaledXPosition] forKey:@"xPortrait"];
        [metadata setObject:[NSNumber numberWithDouble:scaledYPosition] forKey:@"yPortrait"];
    } else {
        [metadata setObject:[NSNumber numberWithDouble:scaledXPosition] forKey:@"xLandscape"];
        [metadata setObject:[NSNumber numberWithDouble:scaledYPosition] forKey:@"yLandscape"];
    }
    
    widgetController.widgetMetadata = metadata;
    
    // Add as subview
    widgetController.view.center = convertedPosition;
    [self.view addSubview:widgetController.view];
    
    // Save to preferences
    NSMutableDictionary *layerPreferences = [[XENHResources widgetPreferencesForLocation:kLocationSBForeground] mutableCopy];
    
    if (!layerPreferences)
        layerPreferences = [@{} mutableCopy];

    NSMutableDictionary *layerWidgetMetadata = [[layerPreferences objectForKey:@"widgetMetadata"] mutableCopy];
    if (!layerWidgetMetadata) {
        layerWidgetMetadata = [NSMutableDictionary dictionary];
    }
    
    [layerWidgetMetadata setObject:metadata forKey:widgetController._rawWidgetIndexFile];
    
    // Save up.
    [layerPreferences setObject:layerWidgetMetadata forKey:@"widgetMetadata"];
    
    // And now write the layer preferences
    [XENHResources setWidgetPreferences:layerPreferences forLocation:kLocationSBForeground];
    
    // Hide alignment guide
    [self.popoverPresentationController._xenhtml_contentView _xenhtml_hideVerticalEditingGuide];
}

- (void)notifyWidgetHeldOnLeftEdge {
    XENlog(@"Notified of page advancement; left");
    
    long long currentPage = self.popoverPresentationController._xenhtml_currentPageIndex;
    BOOL isIpad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    if ([XENHResources isAtLeastiOSVersion:13 subversion:0] &&
        !isIpad && // Not needed on iPad due to Today page slideover
        self.popoverPresentationController.todayViewPageIndex == currentPage - 1) {
        return;
    }
    
    // Move one page backwards, but don't allow going to the today page
    [self.popoverPresentationController setCurrentPageIndex:currentPage - 1 animated:YES];
}

- (void)notifyWidgetHeldOnRightEdge {
    // Move one page forward
    XENlog(@"Notified of page advancement; right");
    
    long long currentPage = self.popoverPresentationController._xenhtml_currentPageIndex;
    long long nextPage = currentPage + 1;
    
    // Don't add a widget to an empty list view, because it will become inaccessible
    if ([XENHResources isAtLeastiOSVersion:13 subversion:0]) {
        // Convert to array indexing
        BOOL isIpad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;        
        long long nextPageConverted = isIpad ? nextPage - 100 : nextPage - 101;
        
        if ([[self.popoverPresentationController iconListViewAtIndex:nextPageConverted] isEmpty]) return;
    } else {
        if ([[self.popoverPresentationController iconListViewAtIndex:nextPage] isEmpty]) return;
    }
    
    [self.popoverPresentationController setCurrentPageIndex:nextPage animated:YES];
}

@end
