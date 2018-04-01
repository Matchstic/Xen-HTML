//
//  XENSetupWindow.m
//  
//
//  Created by Matt Clarke on 10/07/2016.
//
//

#import "XENSetupWindow.h"
#import "XENSetupInitialController.h"
#import "XENHResources.h"
#import <objc/runtime.h>

@interface SpringBoard : NSObject
@end

@interface SpringBoard (SetupEditor)
//-(void)_xenhtml_relayoutAfterSetupContentEditorDisplayed;
//-(void)_xenhtml_releaseSetupUI;
//-(void)_xenhtml_finaliseAfterSetup;
-(void)_xenhtml_relaunchSpringBoardAfterSetup;
@end

static XENHSetupWindow *shared;

@implementation XENHSetupWindow

+(instancetype)sharedInstance {
    if (!shared) {
        static dispatch_once_t p = 0;
        dispatch_once(&p, ^{
            shared = [[XENHSetupWindow alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        });
    }
    
    return shared;
}

+(void)finishSetupMode {
    UIView *black = [[UIView alloc] initWithFrame:shared.bounds];
    black.backgroundColor = [UIColor blackColor];
    black.alpha = 1.0;
    
    [shared insertSubview:black atIndex:0];
    
    shared.backgroundColor = [UIColor clearColor];
    
    [UIView animateWithDuration:0.5 animations:^{
        shared.rootViewController.view.alpha = 0.0;
        shared.rootViewController.view.transform = CGAffineTransformMakeScale(2.0, 2.0);
        shared.bar.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            shared = nil;
            
            /*[(SpringBoard*)[UIApplication sharedApplication] _xenhtml_finaliseAfterSetup];
             [(SpringBoard*)[UIApplication sharedApplication] _xenhtml_releaseSetupUI];*/
            
            [(SpringBoard*)[UIApplication sharedApplication] _xenhtml_relaunchSpringBoardAfterSetup];
        }
    }];
}

/*+(void)relayoutXenForSetupFinished {
    [(SpringBoard*)[UIApplication sharedApplication] _xenhtml_relayoutAfterSetupContentEditorDisplayed];
}*/

// Allows it to render on LS.
- (bool)_shouldCreateContextAsSecure {
    return YES;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.windowLevel = 1081;
        
        self.usingQuickSetup = NO;
        
        // We want a navigation controller
        XENHSetupInitialController *initial = [[XENHSetupInitialController alloc] init];
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:initial];
        [navigation setNavigationBarHidden:YES];
        self.rootViewController = navigation;
        
        [navigation.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [navigation.navigationBar setShadowImage:[UIImage new]];
        
        self.bar = [[objc_getClass("UIStatusBar") alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 20) showForegroundView:YES];
        [(UIStatusBar*)self.bar requestStyle:0 animated:YES];
        [(UIStatusBar*)self.bar setLegibilityStyle:0];
        self.bar.frame = CGRectMake(0, 0, frame.size.width, self.bar.frame.size.height);
        self.bar.tag = 1337;
        
        [self addSubview:self.bar];
    }
    
    return self;
}

@end
