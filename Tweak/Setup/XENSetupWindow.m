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
