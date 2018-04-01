//
//  XENHLockscreenPreviewCell.m
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 26/01/2018.
//

#import "XENHLockscreenPreviewCell.h"
#import "XENHPreviewScaledController.h"

#import "XENHWallpaperViewController.h"
#import "XENHFauxLockViewController.h"
#import "XENHFauxLockNotificationsController.h"
#import "XENHEditorWebViewController.h"

static NSMutableArray *viewControllers;

static NSString *oldForegroundLocation = @"";
static NSDictionary *oldForegroundWidgetPrefs = nil;
static NSString *oldBackgroundLocation = @"";
static NSDictionary *oldBackgroundWidgetPrefs = nil;

@implementation XENHLockscreenPreviewCell

- (NSArray*)viewControllersToDisplay {
    if (!viewControllers) {
        viewControllers = [NSMutableArray array];
        
        CGFloat cellHeight = [self preferredHeightForWidth:0.0] - 80.0;
        
        // First controller - wallpaper
        XENHPreviewScaledController *controller1 = [[XENHPreviewScaledController alloc] init];
        
        UIViewController *wallpaperController = [[XENHWallpaperViewController alloc] initWithVariant:[self variant]];
        wallpaperController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        wallpaperController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [controller1 setContainedViewController:wallpaperController previewHeight:cellHeight];
        [controller1 fitToSize];
        
        [viewControllers addObject:controller1];
        
        // Second controller, background LS
        XENHPreviewScaledController *controller2 = [[XENHPreviewScaledController alloc] init];
        
        XENHEditorWebViewController *backgroundController = [[XENHEditorWebViewController alloc] initWithVariant:0 showNoHTMLLabel:NO];
        
        oldBackgroundLocation = [self indexHTMLFileForVariant:0];
        oldBackgroundWidgetPrefs = [[XENHResources widgetPrefs] objectForKey:@"LSBackground"];
        
        [backgroundController reloadWebViewToPath:oldBackgroundLocation updateMetadata:YES ignorePreexistingMetadata:NO];
        backgroundController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        backgroundController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        backgroundController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [controller2 setContainedViewController:backgroundController previewHeight:cellHeight];
        [controller2 fitToSize];
        
        [viewControllers addObject:controller2];
        
        // Third controller, faux date
        XENHPreviewScaledController *controller3 = [[XENHPreviewScaledController alloc] init];
        
        UIViewController *fauxDateController = [[XENHFauxLockViewController alloc] init];
        fauxDateController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        fauxDateController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        fauxDateController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [controller3 setContainedViewController:fauxDateController previewHeight:cellHeight];
        [controller3 fitToSize];
        
        [viewControllers addObject:controller3];
        
        // Fourth controller, foreground LS
        XENHPreviewScaledController *controller4 = [[XENHPreviewScaledController alloc] init];
        
        XENHEditorWebViewController *foregroundController = [[XENHEditorWebViewController alloc] initWithVariant:1 showNoHTMLLabel:NO];
        
        oldForegroundLocation = [self indexHTMLFileForVariant:1];
        oldForegroundWidgetPrefs = [[XENHResources widgetPrefs] objectForKey:@"LSForeground"];
        
        [foregroundController reloadWebViewToPath:oldForegroundLocation updateMetadata:YES ignorePreexistingMetadata:NO];
        foregroundController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        foregroundController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        foregroundController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [controller4 setContainedViewController:foregroundController previewHeight:cellHeight];
        [controller4 fitToSize];
        
        [viewControllers addObject:controller4];
        
        // Notifications
        XENHPreviewScaledController *controller5 = [[XENHPreviewScaledController alloc] init];
        
        XENHFauxLockNotificationsController *fauxNotificationsController = [[XENHFauxLockNotificationsController alloc] init];
        fauxNotificationsController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        fauxNotificationsController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        fauxNotificationsController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [controller5 setContainedViewController:fauxNotificationsController previewHeight:cellHeight];
        [controller5 fitToSize];
        
        [viewControllers addObject:controller5];
    }
    
    return viewControllers;
}

- (int)variant {
    return 0;
}

-(NSString*)indexHTMLFileForVariant:(int)variant {
    NSString *fileString = @"";
    
    [XENHResources reloadSettings];
    
    switch (variant) {
        case 0:
            fileString = [XENHResources backgroundLocation];
            break;
        case 1:
            fileString = [XENHResources foregroundLocation];
            break;
        case 2:
            fileString = [XENHResources SBLocation];
            break;
    }
    
    return fileString;
}

// Request webview controllers to reload based upon settings change

- (void)didRecieveSettingsChange {
    BOOL didChangeBackground = ![[self indexHTMLFileForVariant:0] isEqualToString:oldBackgroundLocation];
    BOOL didChangeForeground = ![[self indexHTMLFileForVariant:1] isEqualToString:oldForegroundLocation];
    
    NSDictionary *newForegroundWidgetPrefs = [[XENHResources widgetPrefs] objectForKey:@"LSForeground"];
    NSDictionary *newBackgroundWidgetPrefs = [[XENHResources widgetPrefs] objectForKey:@"LSBackground"];
    
    didChangeBackground = didChangeBackground || ![newBackgroundWidgetPrefs isEqual:oldBackgroundWidgetPrefs];
    didChangeForeground = didChangeForeground || ![newForegroundWidgetPrefs isEqual:oldForegroundWidgetPrefs];

    
    if (didChangeForeground) {
        oldForegroundLocation = [self indexHTMLFileForVariant:1];
        oldForegroundWidgetPrefs = newForegroundWidgetPrefs;
    }
                                 
    if (didChangeBackground) {
        oldBackgroundLocation = [self indexHTMLFileForVariant:0];
        oldBackgroundWidgetPrefs = newBackgroundWidgetPrefs;
    }
    
    for (XENHPreviewScaledController *controller in viewControllers) {
        if ([controller.containedViewController respondsToSelector:@selector(reloadWebViewToPath:updateMetadata:ignorePreexistingMetadata:)]) {
           
            if (!didChangeBackground && !didChangeForeground) {
                // No need to update for this change
                continue;
            }
            
            XENHEditorWebViewController *webController = (XENHEditorWebViewController*)controller.containedViewController;
            
            int variant = webController.webviewVariant;
            if ((variant == 0 && didChangeBackground) || (variant == 1 && didChangeForeground)) {
                [webController reloadWebViewToPath:[self indexHTMLFileForVariant:variant] updateMetadata:YES ignorePreexistingMetadata:NO];
            }
            
            NSLog(@"Reloading... %d", variant);
        } else if ([controller.containedViewController respondsToSelector:@selector(reloadForSettingsChange)]) {
            // Doesn't matter which type!
            XENHFauxLockNotificationsController *fauxController = (XENHFauxLockNotificationsController*)[controller containedViewController];
            
            [fauxController reloadForSettingsChange];
        }
    }
}

@end
