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
#import "XENSetupViewController.h"
#import "XENHResources.h"
#import <objc/runtime.h>

static XENHSetupWindow *shared;

@implementation XENHSetupWindow

+(instancetype)sharedInstance {
    if (!shared) {
        static dispatch_once_t p = 0;
        dispatch_once(&p, ^{
            shared = [[XENHSetupWindow alloc] initWithFrame:CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH)];
        });
    }
    
    return shared;
}

+(void)finishSetupMode {
    [XENHResources setPreferenceKey:@"hasDisplayedSetupUI" withValue:@1 andPost:NO];
    
    CGRect existingFrame = shared.rootViewController.view.frame;
    
    [UIView animateWithDuration:0.35 animations:^{
        shared.alpha = 0.0;
        shared.rootViewController.view.frame = CGRectMake(existingFrame.origin.x, SCREEN_HEIGHT, existingFrame.size.width, existingFrame.size.height);
    } completion:^(BOOL finished) {
        if (finished) {
            shared = nil;
        }
    }];
}

// Allow rendering on LS.
- (bool)_shouldCreateContextAsSecure {
    return YES;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        // Properties
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        self.windowLevel = 1081;
        
        // Add the web controller for the Setup UI
        XENSetupViewController *controller = [[XENSetupViewController alloc] init];
        self.rootViewController = controller;
    }
    
    return self;
}

@end
