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

#import "XENHTouchPassThroughView.h"
#import "XENHResources.h"

@implementation XENHTouchPassThroughView

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // Allow any "overhanging" views to respond
    if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
        for (UIView *subview in self.subviews.reverseObjectEnumerator) {
            CGPoint subPoint = [subview convertPoint:point fromView:self];
            UIView *result = [subview hitTest:subPoint withEvent:event];
            if (result != nil) {
                return result;
            }
        }
    }
    
    UIView *view = [super hitTest:point withEvent:event];
    if ([view isEqual:self]) {
        view = nil;
    }
    
    return view;
}

- (void)didMoveToWindow {
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewDidMoveToWindow)])
        [self.delegate viewDidMoveToWindow];
}

@end
