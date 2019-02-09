//
//  XENHEditorExistingWidgetsController.m
//  Preferences
//
//  Created by Matt Clarke on 03/06/2018.
//

#import "XENHEditorExistingWidgetsController.h"
#import "XENHEditorWebViewController.h"
#import "XENHPResources.h"

@interface CAFilter : NSObject
+(NSArray*)filterTypes;
+(CAFilter*)filterWithType:(NSString*)type;
+(CAFilter*)filterWithName:(NSString*)name;
@end

@interface XENHEditorExistingWidgetsController ()

@end

@implementation XENHEditorExistingWidgetsController

- (instancetype)initWithVariant:(int)variant andCurrentWidget:(NSString*)currentWidget {
    self = [super init];
    
    if (self) {
        [self _loadExistingWidgetsForVariant:variant withCurrentWidget:currentWidget];
    }
    
    return self;
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.userInteractionEnabled = NO;
    
    // Ensure content is monochrome
    CAFilter* filter = [CAFilter filterWithName:@"colorMonochrome"];
    [filter setValue:[NSNumber numberWithFloat:-0.2] forKey:@"inputBias"];
    [filter setValue:[NSNumber numberWithFloat:1] forKey:@"inputAmount"];
    
    self.view.layer.filters = [NSArray arrayWithObject:filter];
    
    // Fade out a little too
    self.view.alpha = 0.15;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    for (UIViewController *webController in self.childViewControllers) {
        webController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        webController.view.bounds = CGRectMake(0, 0,  self.view.frame.size.width, self.view.frame.size.height);
    }
}

- (NSArray*)_existingWidgetsForVariant:(int)variant withCurrentWidget:(NSString*)currentWidget {
    NSString *key = @"";
    switch (variant) {
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
        
    NSDictionary *locationSettings = [[XENHResources getPreferenceKey:@"widgets"] objectForKey:key];
    NSMutableArray *widgetArray = [[locationSettings objectForKey:@"widgetArray"] mutableCopy];
        
    if (!widgetArray) {
        widgetArray = [NSMutableArray array];
    } else {
        if ([widgetArray containsObject:currentWidget])
            [widgetArray removeObject:currentWidget];
    }
        
    return widgetArray;
}

- (void)_loadExistingWidgetsForVariant:(int)variant withCurrentWidget:(NSString*)currentWidget {
    NSArray *widgetArray = [self _existingWidgetsForVariant:variant withCurrentWidget:currentWidget];
    
    for (NSString *location in widgetArray) {
        XENHEditorWebViewController *webController = [[XENHEditorWebViewController alloc] initWithVariant:variant showNoHTMLLabel:NO];
        
        [webController reloadWebViewToPath:location updateMetadata:YES ignorePreexistingMetadata:NO];
        webController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        webController.view.bounds = CGRectMake(0, 0,  self.view.frame.size.width, self.view.frame.size.height);
        
        [self addChildViewController:webController];
        [self.view addSubview:webController.view];
    }
}

@end
