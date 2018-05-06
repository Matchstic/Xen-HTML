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

#import "XENHLockscreenPreviewCell.h"
#import "XENHPreviewScaledController.h"

#import "XENHWallpaperViewController.h"
#import "XENHFauxLockViewController.h"
#import "XENHFauxLockNotificationsController.h"
#import "XENHEditorWebViewController.h"

@implementation XENHLockscreenPreviewCell

- (NSArray*)viewControllersToDisplay {
    if (!self.viewControllers) {
        self.viewControllers = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_requestedToCacheWallpaper) name:@"com.matchstic.xenhtml/cacheLockscreenWallpaper" object:nil];
        
        CGFloat cellHeight = [self preferredHeightForWidth:0.0] - 80.0;
        
        // First controller - wallpaper
        XENHPreviewScaledController *controller1 = [[XENHPreviewScaledController alloc] init];
        
        UIViewController *wallpaperController = [[XENHWallpaperViewController alloc] initWithVariant:[self variant]];
        wallpaperController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        wallpaperController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [controller1 setContainedViewController:wallpaperController previewHeight:cellHeight];
        [controller1 fitToSize];
        
        [self.viewControllers addObject:controller1];
        
        // Second controller, background LS
        XENHPreviewScaledController *controller2 = [[XENHPreviewScaledController alloc] init];
        
        self.oldBackgroundLocations = [self widgetLocationsForVariant:0];
        self.oldBackgroundWidgetMetadata = [self widgetMetadataForVariant:0];
        
        UIViewController *backgroundMultiplexedController = [[UIViewController alloc] init];
        backgroundMultiplexedController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        backgroundMultiplexedController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        backgroundMultiplexedController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        backgroundMultiplexedController.view.tag = 1337;
        
        [self _loadWidgetsForMultiplexedController:backgroundMultiplexedController andVariant:0];
        
        [controller2 setContainedViewController:backgroundMultiplexedController previewHeight:cellHeight];
        [controller2 fitToSize];
        
        [self.viewControllers addObject:controller2];
        
        // Third controller, faux date
        XENHPreviewScaledController *controller3 = [[XENHPreviewScaledController alloc] init];
        
        UIViewController *fauxDateController = [[XENHFauxLockViewController alloc] init];
        fauxDateController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        fauxDateController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        fauxDateController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [controller3 setContainedViewController:fauxDateController previewHeight:cellHeight];
        [controller3 fitToSize];
        
        [self.viewControllers addObject:controller3];
        
        // Fourth controller, foreground LS
        XENHPreviewScaledController *controller4 = [[XENHPreviewScaledController alloc] init];
        
        self.oldForegroundLocations = [self widgetLocationsForVariant:1];
        self.oldForegroundWidgetMetadata = [self widgetMetadataForVariant:1];
        
        UIViewController *foregroundMultiplexedController = [[UIViewController alloc] init];
        foregroundMultiplexedController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        foregroundMultiplexedController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        foregroundMultiplexedController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        foregroundMultiplexedController.view.tag = 1337;
        
        [self _loadWidgetsForMultiplexedController:foregroundMultiplexedController andVariant:1];
        
        [controller4 setContainedViewController:foregroundMultiplexedController previewHeight:cellHeight];
        [controller4 fitToSize];
        
        [self.viewControllers addObject:controller4];
        
        // Notifications
        XENHPreviewScaledController *controller5 = [[XENHPreviewScaledController alloc] init];
        
        XENHFauxLockNotificationsController *fauxNotificationsController = [[XENHFauxLockNotificationsController alloc] init];
        fauxNotificationsController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        fauxNotificationsController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        fauxNotificationsController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [controller5 setContainedViewController:fauxNotificationsController previewHeight:cellHeight];
        [controller5 fitToSize];
        
        [self.viewControllers addObject:controller5];
    }
    
    return self.viewControllers;
}

- (int)variant {
    return 0;
}

-(NSArray*)widgetLocationsForVariant:(int)variant {
    [XENHResources reloadSettings];
    
    NSString *layerPreferenceKey = @"";
    
    switch (variant) {
        case 0:
            layerPreferenceKey = @"LSBackground";
            break;
        case 1:
            layerPreferenceKey = @"LSForeground";
            break;
            
        default:
            break;
    }
    
    return [[[XENHResources getPreferenceKey:@"widgets"] objectForKey:layerPreferenceKey] objectForKey:@"widgetArray"];
}

- (NSDictionary*)widgetMetadataForVariant:(int)variant {
    [XENHResources reloadSettings];
    
    NSString *layerPreferenceKey = @"";
    
    switch (variant) {
        case 0:
            layerPreferenceKey = @"LSBackground";
            break;
        case 1:
            layerPreferenceKey = @"LSForeground";
            break;
        case 2:
            
        default:
            break;
    }
    
    return [[[XENHResources getPreferenceKey:@"widgets"] objectForKey:layerPreferenceKey] objectForKey:@"widgetMetadata"];
}

// Request webview controllers to reload based upon settings change

- (void)didRecieveSettingsChange {
    BOOL didChangeBackground = ![[self widgetLocationsForVariant:0] isEqual:self.oldBackgroundLocations];
    BOOL didChangeForeground = ![[self widgetLocationsForVariant:1] isEqual:self.oldForegroundLocations];
    
    NSDictionary *newForegroundWidgetPrefs = [self widgetMetadataForVariant:0];
    NSDictionary *newBackgroundWidgetPrefs = [self widgetMetadataForVariant:1];
    
    didChangeBackground = didChangeBackground || ![newBackgroundWidgetPrefs isEqual:self.oldBackgroundWidgetMetadata];
    didChangeForeground = didChangeForeground || ![newForegroundWidgetPrefs isEqual:self.oldForegroundWidgetMetadata];
    
    if (didChangeForeground) {
        self.oldForegroundLocations = [self widgetLocationsForVariant:1];
        self.oldForegroundWidgetMetadata = newForegroundWidgetPrefs;
    }
                                 
    if (didChangeBackground) {
        self.oldBackgroundLocations = [self widgetLocationsForVariant:0];
        self.oldBackgroundWidgetMetadata = newBackgroundWidgetPrefs;
    }
    
    // Iterate and reload
    for (int i = 0; i < self.viewControllers.count; i++) {
        XENHPreviewScaledController *controller = [self.viewControllers objectAtIndex:i];
        
        if (i == 1 && didChangeBackground) {
            // Background LS
            [self _loadWidgetsForMultiplexedController:controller.containedViewController andVariant:0];
        } else if (i == 3 && didChangeForeground) {
            [self _loadWidgetsForMultiplexedController:controller.containedViewController andVariant:1];
        } else if ([controller.containedViewController respondsToSelector:@selector(reloadForSettingsChange)]) {
            [(XENHFauxLockNotificationsController*)controller.containedViewController reloadForSettingsChange];
        }
    }
}

- (void)_requestedToCacheWallpaper {
   XENHWallpaperViewController *wallpaperController = (XENHWallpaperViewController *)[[self.viewControllers objectAtIndex:0] containedViewController];
    [wallpaperController cacheWallpaperImageToFilesystem];
}

- (void)_loadWidgetsForMultiplexedController:(UIViewController*)multiplexController andVariant:(int)variant {
    NSArray *widgetArray = variant == 0 ? self.oldBackgroundLocations : self.oldForegroundLocations;
    
    // Remove existing widgets
    for (UIViewController *childController in multiplexController.childViewControllers) {
        [childController removeFromParentViewController];
        [childController.view removeFromSuperview];
    }
    
    for (NSString *location in widgetArray) {
        XENHEditorWebViewController *webController = [[XENHEditorWebViewController alloc] initWithVariant:variant showNoHTMLLabel:NO];
        
        [webController reloadWebViewToPath:location updateMetadata:YES ignorePreexistingMetadata:NO];
        webController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        webController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [multiplexController addChildViewController:webController];
        [multiplexController.view addSubview:webController.view];
    }
}

- (void)_reloadWallpaper {
    // Reload the wallpaper controller!
    [super _reloadWallpaper];
    
    XENHWallpaperViewController *wallpaperController = (XENHWallpaperViewController *)[[self.viewControllers objectAtIndex:0] containedViewController];
    [wallpaperController reloadWallpaper];
}

@end
