//
//  XENHHomescreenPreviewCell.m
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 26/01/2018.
//

#import "XENHHomescreenPreviewCell.h"
#import "XENHPreviewScaledController.h"

#import "XENHWallpaperViewController.h"
#import "XENHFauxIconsViewController.h"
#import "XENHEditorWebViewController.h"

static NSMutableArray *viewControllers;

static NSString *oldBackgroundLocation = @"";
static NSDictionary *oldBackgroundWidgetPrefs = nil;

@implementation XENHHomescreenPreviewCell

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
        
        XENHEditorWebViewController *backgroundController = [[XENHEditorWebViewController alloc] initWithVariant:2 showNoHTMLLabel:NO];
        
        oldBackgroundLocation = [self indexHTMLFileForVariant:2];
        oldBackgroundWidgetPrefs = [[XENHResources widgetPrefs] objectForKey:@"SBBackground"];
        
        [backgroundController reloadWebViewToPath:oldBackgroundLocation updateMetadata:YES ignorePreexistingMetadata:NO];
        backgroundController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.075];
        backgroundController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        backgroundController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [controller2 setContainedViewController:backgroundController previewHeight:cellHeight];
        [controller2 fitToSize];
        
        [viewControllers addObject:controller2];
        
        // Third controller, faux icons
        XENHPreviewScaledController *controller3 = [[XENHPreviewScaledController alloc] init];
        
        UIViewController *fauxDateController = [[XENHFauxIconsViewController alloc] init];
        fauxDateController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.075];
        fauxDateController.view.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        fauxDateController.view.bounds = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        
        [controller3 setContainedViewController:fauxDateController previewHeight:cellHeight];
        [controller3 fitToSize];
        
        [viewControllers addObject:controller3];
    }
    
    return viewControllers;
}

- (int)variant {
    return 1;
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

- (void)didRecieveSettingsChange {
    BOOL didChangeBackground = ![[self indexHTMLFileForVariant:2] isEqualToString:oldBackgroundLocation];
    
    NSDictionary *newBackgroundWidgetPrefs = [[XENHResources widgetPrefs] objectForKey:@"SBBackground"];
    
    didChangeBackground = didChangeBackground || ![oldBackgroundWidgetPrefs isEqual:newBackgroundWidgetPrefs];
    
    if (!didChangeBackground) {
        // No need to update for this change
        return;
    }
    
    if (didChangeBackground) {
        oldBackgroundLocation = [self indexHTMLFileForVariant:2];
        oldBackgroundWidgetPrefs = newBackgroundWidgetPrefs;
    }
    
    for (XENHPreviewScaledController *controller in viewControllers) {
        if ([controller.containedViewController respondsToSelector:@selector(reloadWebViewToPath:updateMetadata:ignorePreexistingMetadata:)]) {
            XENHEditorWebViewController *webController = (XENHEditorWebViewController*)controller.containedViewController;
            
            int variant = webController.webviewVariant;
            if (variant == 2 && didChangeBackground) {
                [webController reloadWebViewToPath:[self indexHTMLFileForVariant:variant] updateMetadata:YES ignorePreexistingMetadata:NO];
            }
            
            NSLog(@"Reloading... %d", variant);
        }
    }
}

@end
