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
#import "XENHResources.h"
#import <objc/runtime.h>

@implementation XENHWidgetLayerContainerView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.delegate)
        [self.delegate forwardTouchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.delegate)
        [self.delegate forwardTouchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.delegate)
        [self.delegate forwardTouchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.delegate)
        [self.delegate forwardTouchesCancelled:touches withEvent:event];
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // Get a list of hittested views for our subviews
    NSMutableArray *hittestedViews = [NSMutableArray array];
    
    // The first object is now the topmost view.
    for (UIView *view in [self.subviews reverseObjectEnumerator]) {
        CGPoint subPoint = [view convertPoint:point fromView:self];
        UIView *hittested = [view hitTest:subPoint withEvent:event];
        
        if (hittested) {
            if ([[hittested class] isEqual:objc_getClass("UIWebOverflowContentView")]) {
                hittested = [hittested superview];
            } else if ([[hittested class] isEqual:objc_getClass("XENHCloseButton")] ||
                       [[hittested class] isEqual:objc_getClass("XENHButton")]) {
                return hittested;
            } else if (hittested.tag == 1337) {
                return hittested;
            }
            
            if (hittested.userInteractionEnabled)
                [hittestedViews addObject:hittested];
        }
    }
    
    // Check if any of the hittested views are scroll views.
    int count = 0;
    for (UIView *view in hittestedViews) {
        if ([[view class] isEqual:[UIScrollView class]] || [[view class] isEqual:objc_getClass("UIWebOverflowScrollView")])
            count++;
    }
    
    BOOL hasMultipleScrollViews = count > 1;
    
    // Handle the case where we have one view, or no views.
    // i.e., there's no point doing the below checks for these cases, so reduce complexity.
    if (hittestedViews.count == 1) {
        // Allow the only hittested view to take full control of this touch.
        UIView *firstObject = [hittestedViews firstObject];
        
        // Become first responder for keyboard events
        if (![firstObject isFirstResponder])
            [firstObject becomeFirstResponder];
        
        return firstObject;
    } else if (hittestedViews.count == 0) {
        // Pass through touch to anything behind us
        return nil;
    } else if (hasMultipleScrollViews) {
        // if one is already scrolling, forward to it.
        for (UIView *view in hittestedViews) {
            if (![[view class] isEqual:[UIScrollView class]] || [[view class] isEqual:objc_getClass("UIWebOverflowScrollView")])
                continue;
            
            UIScrollView *scrollView = (UIScrollView*)view;
            
            if (scrollView.isDecelerating) {
                return scrollView;
            }
        }
        
        // Let the smallest take the touch exclusively. If there are multiple with the same size,
        // forward simultaneously.
        
        BOOL multipleWithSameSize = NO;
        CGSize smallestSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
        UIView *smallestScrollView;
        
        for (UIView *view in hittestedViews) {
            // We only care about scrollViews!
            if (![[view class] isEqual:[UIScrollView class]] || [[view class] isEqual:objc_getClass("UIWebOverflowScrollView")])
                continue;
            
            CGSize size = view.bounds.size;
            
            BOOL smaller = CGRectContainsRect(CGRectMake(0.0f, 0.0f, smallestSize.width, smallestSize.height),
                                              CGRectMake(0.0f, 0.0f, size.width, size.height));
            
            if (!smaller) {
                // Check for size equality.
                multipleWithSameSize = smallestSize.width == size.width && smallestSize.height == size.height;
                
                if (multipleWithSameSize)
                    break;
            } else {
                smallestScrollView = view;
            }
        }
        
        if (!multipleWithSameSize) {
            return smallestScrollView != nil ? smallestScrollView : self;
        } else {
            // Forward to all!
            return self;
        }
    } else {
        // Forward touches to all the hittestedViews simultaneously.
        return self;
    }
}

@end
