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

#import "XENHWidgetLayerContainerView.h"
#import "XENHTouchForwardingRecognizer.h"
#import "XENHResources.h"
#import <objc/runtime.h>

@implementation XENHWidgetLayerContainerView

- (instancetype)initWithWidgetController:(id)controller {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        // Configure the touch forwarding gesture
        XENHTouchForwardingRecognizer *touchForwarding = [[XENHTouchForwardingRecognizer alloc] initWithWidgetController:controller andIgnoredViewClasses:@[]];
        touchForwarding.safeAreaInsets = UIEdgeInsetsMake([UIApplication sharedApplication].statusBarFrame.size.height + 40.0, 20.0, 20.0, 20.0);
        
        [self addGestureRecognizer:touchForwarding];
    }
    
    return self;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // If we don't hittest anything, allow the touch to go below. Otherwise, return 'self' to
    // ensure the touch forwarding recogniser can kick in.
    
    BOOL anyViewsHittested = NO;
    for (UIView *view in self.subviews) {
        UIView *hittested = [view hitTest:point withEvent:event];
        
        if (hittested != nil) {
            anyViewsHittested = YES;
            break;
        }
    }
    
    return anyViewsHittested == YES ? self : nil;
}

@end
