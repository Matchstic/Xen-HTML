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

#import "XENHTouchForwardingRecognizer.h"
#import "XENHResources.h"

#import <objc/runtime.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface UITouch (Private2)
- (CGPoint)_locationInSceneReferenceSpace;
@end

@implementation XENHTouchForwardingRecognizer

- (instancetype)initWithWidgetController:(XENHWidgetLayerController*)widgetController andIgnoredViewClasses:(NSArray*)ignoredViewClasses {
    self = [super initWithTarget:self action:@selector(_handleEvent:)];
    
    if (self) {
        self.widgetController = widgetController;
        self.safeAreaInsets = UIEdgeInsetsZero;
    }
    
    return self;
}

- (void)_handleEvent:(id)sender {}

- (void)reset {
    [super reset];

    self.state = UIGestureRecognizerStatePossible;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self._xenhtml_touches = touches;
    self._xenhtml_event = event;
    
    [super touchesBegan:touches withEvent:event];
    
    if (self._xenhtml_touches.count == 0) {
        self._xenhtml_touches = [self._xenhtml_event allTouches];
    }
    
    self.state = UIGestureRecognizerStateBegan;
    
    [self _processInteraction];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    self._xenhtml_touches = touches;
    self._xenhtml_event = event;
    
    [super touchesMoved:touches withEvent:event];
    
    if (self._xenhtml_touches.count == 0) {
        self._xenhtml_touches = [self._xenhtml_event allTouches];
    }
    
    self.state = UIGestureRecognizerStateChanged;
    
    [self _processInteraction];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self._xenhtml_touches = touches;
    self._xenhtml_event = event;
    
    [super touchesEnded:touches withEvent:event];
    
    if (self._xenhtml_touches.count == 0) {
        self._xenhtml_touches = [self._xenhtml_event allTouches];
    }
    
    self.state = UIGestureRecognizerStateEnded;
    
    [self _processInteraction];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self._xenhtml_touches = touches;
    self._xenhtml_event = event;
    
    [super touchesCancelled:touches withEvent:event];
    
    if (self._xenhtml_touches.count == 0) {
        self._xenhtml_touches = [self._xenhtml_event allTouches];
    }
    
    self.state = UIGestureRecognizerStateCancelled;
    
    [self _processInteraction];
}

- (void)_processInteraction {
    if (!self.widgetController) {
        return; // No point forwarding if no widget enabled.
    }
    
    if (self.state == UIGestureRecognizerStateBegan) {
        [self.widgetController forwardTouchesBegan:self._xenhtml_touches withEvent:self._xenhtml_event];
    } else if (self.state == UIGestureRecognizerStateChanged) {
        [self.widgetController forwardTouchesMoved:self._xenhtml_touches withEvent:self._xenhtml_event];
    } else if (self.state == UIGestureRecognizerStateEnded) {
        [self.widgetController forwardTouchesEnded:self._xenhtml_touches withEvent:self._xenhtml_event];
    } else if (self.state == UIGestureRecognizerStateCancelled) {
        [self.widgetController forwardTouchesCancelled:self._xenhtml_touches withEvent:self._xenhtml_event];
    }
}

#pragma mark Handle other gestures

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer*)arg1 {
    return NO;
}

- (BOOL)_shouldReceiveTouch:(UITouch*)touch recognizerView:(UIView*)arg2 touchView:(UIView*)arg3 {
    return [self shouldReceiveTouch:touch inView:arg3];
}

- (BOOL)_shouldReceiveTouch:(UITouch*)touch forEvent:(id)event recognizerView:(UIView*)arg3 {
    return [self shouldReceiveTouch:touch inView:touch.view];
}

- (BOOL)shouldReceiveTouch:(UITouch*)touch inView:(UIView*)arg3 {
    CGPoint pointInView = [touch _locationInSceneReferenceSpace];
    
    // Handle safe area - insets
    if (pointInView.x < self.safeAreaInsets.left ||
        pointInView.x > self.view.bounds.size.width - self.safeAreaInsets.right ||
        pointInView.y < self.safeAreaInsets.top ||
        pointInView.y > self.view.bounds.size.height - self.safeAreaInsets.bottom) {
        
        // Alright, we're outside the safe area.
        // If there's a preventative gesture in this safe area, then we must give up touch.
        
        BOOL preventingGestures = [self.widgetController canPreventGestureRecognizer:nil atLocation:pointInView];
        
        if (preventingGestures) {
            XENlog(@"Not forwarding touch; outside of the safe area!");
            return NO;
        }
    }
    
    // Handle safe area - views
    if (![[arg3 class] isEqual:objc_getClass("SBRootIconListView")] && // Icons
        !([[arg3 class] isEqual:objc_getClass("SBIconListView")] &&
          [XENHResources isAtLeastiOSVersion:13 subversion:0]) && // Icons (iOS 13)
        ![[arg3 class] isEqual:objc_getClass("SBIconScrollView")] && // Icon scrollview
        ![[arg3 class] isEqual:objc_getClass("IWWidgetsView")] && // iWidgets
        ![[arg3.layer name] isEqualToString:@"RootContent"] && // WKWebView
        ![[arg3 class] isEqual:objc_getClass("UIWebBrowserView")]) // UIWebView
    {
        
        XENlog(@"Not forwarding touch; touchView is not SBRootIconListView (is %@)", [arg3 class]);
        return NO;
    }
    
    return YES;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer*)arg1 {
    // Check if we need to do any gesture prevention for a scrollview.
    UITouch *touch = [[self._xenhtml_event allTouches] anyObject];
    CGPoint pointInView = [touch _locationInSceneReferenceSpace];
    
    return [self.widgetController canPreventGestureRecognizer:arg1 atLocation:pointInView];
}

- (BOOL)cancelsTouchesInView {
    return NO;
}

- (BOOL)delaysTouchesBegan {
    return NO;
}

- (BOOL)delaysTouchesEnded {
    return NO;
}

@end
