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

@interface SBRootFolderView : UIView
@property (nonatomic, strong) XENHTouchPassThroughView *_xenhtml_editingPlatter;
@end

@interface SBIconListView : UIView
- (_Bool)isEmpty;
@end

@interface SBRootFolderController : UIViewController
- (SBRootFolderView*)rootFolderView;
- (_Bool)setCurrentPageIndex:(long long)arg1 animated:(_Bool)arg2;
- (SBIconListView*)iconListViewAtIndex:(unsigned long long)arg1;
@end


@interface XENHWidgetLayerController (Private)
- (void)_setupMultiplexedWidgetsForLocation:(XENHLayerLocation)location;
@end

@interface XENHHomescreenForegroundViewController ()

@property (nonatomic, weak) SBRootFolderController *popoverPresentationController;
@property (nonatomic, readwrite) CGPoint currentPageContentOffset;
@property (nonatomic, readwrite) int currentPage;
@property (nonatomic, readwrite) BOOL isEditing;

@end

@implementation XENHHomescreenForegroundViewController

// Overriden
- (instancetype)initWithLayerLocation:(XENHLayerLocation)location {
    return [super initWithLayerLocation:kLocationSBForeground];
}

// Overriden
- (void)loadView {
    // We don't need touch forwarding when being foreground!
    [super loadView];
    
    // After loading, we can assume we're going to page 1 once the user does a first unlock.
    [self updatedPageContentOffset:CGPointMake(SCREEN_WIDTH, 0) page:1];
}

// Overriden for correct layout
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self _layoutWidgets];
}

- (void)viewWillLayoutSubviews {
    [super viewDidLayoutSubviews];
    
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
            xOffsetMultipler = [[metadata objectForKey:@"xPortrait"] floatValue];
            yOffsetMultipler = [[metadata objectForKey:@"yPortrait"] floatValue];
        } else {
            // Use landscape settings if possible, else portrait otherwise
            if ([[metadata allKeys] containsObject:@"xLandscape"]) {
                xOffsetMultipler = [[metadata objectForKey:@"xLandscape"] floatValue];
                yOffsetMultipler = [[metadata objectForKey:@"yLandscape"] floatValue];
            } else {
                xOffsetMultipler = [[metadata objectForKey:@"xPortrait"] floatValue];
                yOffsetMultipler = [[metadata objectForKey:@"yPortrait"] floatValue];
            }
        }
        
        if (shouldAnimateFrame) {
            [UIView animateWithDuration:0.15 animations:^{
                widgetController.view.frame = CGRectMake(xOffsetMultipler * SCREEN_WIDTH, yOffsetMultipler * SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
            }];
        } else {
            widgetController.view.frame = CGRectMake(xOffsetMultipler * SCREEN_WIDTH, yOffsetMultipler * SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
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
    
    NSString *lastPathComponent = [widgetURL lastPathComponent];
    
    // Check for Options.plist support
    BOOL canActuallyUtiliseOptionsPlist = NO;
    
    NSString *widgetInfoPlistPath = [path stringByAppendingString:@"/WidgetInfo.plist"];
    if ([lastPathComponent isEqualToString:@"Widget.html"] || [[NSFileManager defaultManager] fileExistsAtPath:widgetInfoPlistPath]) {
        canActuallyUtiliseOptionsPlist = YES;
    }
    
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
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:[XENHResources localisedStringForKey:@"WARNING"]
                                                             message:[XENHResources localisedStringForKey:@"WIDGET_EDITOR_ERROR_PARSING_CONFIGJS"]
                                                            delegate:nil
                                                   cancelButtonTitle:[XENHResources localisedStringForKey:@"OK"]
                                                   otherButtonTitles:nil];
                [av show];
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
        widgetMetadata = [[XENHResources rawMetadataForHTMLFile:filePath] mutableCopy];
    } else {
        widgetMetadata = [[[layerPreferences objectForKey:@"widgetMetadata"] objectForKey:filePath] mutableCopy];
    }
    
    if (!widgetMetadata)
        widgetMetadata = [NSMutableDictionary dictionary];
    
    [widgetMetadata setObject:options forKey:@"options"];
    
    if (isNewWidget) {
        // Set the default x and y positions for the new widget based on the current page
        
        [widgetMetadata removeObjectForKey:@"x"];
        [widgetMetadata removeObjectForKey:@"y"];
        
        CGFloat newX = (self.currentPage * SCREEN_MIN_LENGTH) + SCREEN_MIN_LENGTH/2 - [[widgetMetadata objectForKey:@"width"] floatValue]/2;
        // Convert to percentages of the display width
        newX /= SCREEN_MIN_LENGTH;
        
        CGFloat newY = SCREEN_MAX_LENGTH/2 - [[widgetMetadata objectForKey:@"height"] floatValue]/2;
        // Convert to percentages of the display height
        
        if (newY < [UIApplication sharedApplication].statusBarFrame.size.height)
            newY = [UIApplication sharedApplication].statusBarFrame.size.height;
        
        newY /= SCREEN_MAX_LENGTH;
        
        if (newY < 0)
            newY = 0;
        
        [widgetMetadata setObject:[NSNumber numberWithFloat:newX] forKey:@"xPortrait"];
        [widgetMetadata setObject:[NSNumber numberWithFloat:newY] forKey:@"yPortrait"];
        
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
    [self noteUserPreferencesDidChange];
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

- (void)updatedPageContentOffset:(CGPoint)pageContentOffset page:(int)page {
    self.currentPageContentOffset = pageContentOffset;
    self.currentPage = page;
    
    // TODO: Change paused state of widgets not visible?
}

- (void)updatedPageCounts:(int)newCount {
    // TODO: handle change of page counts.
    // i.e., unload any widgets outside the new page counts.
}

- (void)updateEditingModeState:(BOOL)newEditingModeState {
    // TODO: Change editing state:
    // - Add/remove close and option boxes on widgets.
    
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
    UIView *platter = self.popoverPresentationController.rootFolderView._xenhtml_editingPlatter;
    
    // Convert current widget position from scrollview
    CGFloat currentX = widgetController.view.frame.origin.x;
    CGFloat convertedX = currentX - (self.currentPage * SCREEN_WIDTH);
    CGPoint convertedPosition = CGPointMake(convertedX, widgetController.view.frame.origin.y);
    
    XENlog(@"Placing at converted position: %@", NSStringFromCGPoint(convertedPosition));
    
    [platter addSubview:widgetController.view];
    widgetController.view.frame = CGRectMake(convertedPosition.x, convertedPosition.y, widgetController.view.frame.size.width, widgetController.view.frame.size.height);
}

- (void)notifyWidgetPositioningDidEnd:(XENHWidgetController*)widgetController {
    // Take this widget controller off the editing platter, making sure to set
    // the current co-ordinates of it into preferences
    
    // Convert current widget position to the scrollview
    CGFloat currentX = widgetController.view.center.x;
    CGFloat convertedX = currentX + (SCREEN_WIDTH * self.currentPage);
    CGPoint convertedPosition = CGPointMake(convertedX, widgetController.view.center.y);
    
    XENlog(@"Dropping at point: %@", NSStringFromCGPoint(convertedPosition));
    
    // Set widget metadata for the next layout
    NSMutableDictionary *metadata = [widgetController.widgetMetadata mutableCopy];
    
    CGFloat currentXFrame = widgetController.view.frame.origin.x;
    CGFloat convertedXFrame = currentXFrame + (SCREEN_WIDTH * self.currentPage);
    
    CGFloat scaledXPosition = convertedXFrame / SCREEN_WIDTH;
    CGFloat scaledYPosition = widgetController.view.frame.origin.y / SCREEN_HEIGHT;
    
    XENlog(@"Scaled position, X: %f, Y: %f", scaledXPosition, scaledYPosition);
    
    BOOL isPortrait = (orient3 == 1 || orient3 == 2);
    if (isPortrait) {
        [metadata setObject:[NSNumber numberWithFloat:scaledXPosition] forKey:@"xPortrait"];
        [metadata setObject:[NSNumber numberWithFloat:scaledYPosition] forKey:@"yPortrait"];
    } else {
        [metadata setObject:[NSNumber numberWithFloat:scaledXPosition] forKey:@"xLandscape"];
        [metadata setObject:[NSNumber numberWithFloat:scaledYPosition] forKey:@"yLandscape"];
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
}

- (void)notifyWidgetHeldOnLeftEdge {
    XENlog(@"Notified of page advancement; left");
    if (self.currentPage > 1) {
        // Move one page backwards, but don't allow going to the today page
        int nextIndex = (self.currentPage - 1)-1;
        [self.popoverPresentationController setCurrentPageIndex:nextIndex animated:YES];
    }
}

- (void)notifyWidgetHeldOnRightEdge {
    // Move one page forward
    XENlog(@"Notified of page advancement; right");
    
    int nextIndex = self.currentPage; // Counting in icon list views, not scrollview offset
    
    if ([[self.popoverPresentationController iconListViewAtIndex:nextIndex] isEmpty])
        return; // Don't add a widget to an empty list view, because it will become inaccessible
    
    [self.popoverPresentationController setCurrentPageIndex:nextIndex animated:YES];
}

@end
