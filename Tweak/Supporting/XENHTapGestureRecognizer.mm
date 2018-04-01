//
//  XENHTapGestureRecognizer.m
//  
//
//  Created by Matt Clarke on 06/09/2016.
//
//

#import "XENHTapGestureRecognizer.h"
#import "XENHResources.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation XENHTapGestureRecognizer

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
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    self._xenhtml_touches = touches;
    self._xenhtml_event = event;
    
    [super touchesMoved:touches withEvent:event];
    
    if (self._xenhtml_touches.count == 0) {
        self._xenhtml_touches = [self._xenhtml_event allTouches];
    }
    
    self.state = UIGestureRecognizerStateChanged;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self._xenhtml_touches = touches;
    self._xenhtml_event = event;
    
    [super touchesEnded:touches withEvent:event];
    
    if (self._xenhtml_touches.count == 0) {
        self._xenhtml_touches = [self._xenhtml_event allTouches];
    }
    
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self._xenhtml_touches = touches;
    self._xenhtml_event = event;
    
    [super touchesCancelled:touches withEvent:event];
    
    if (self._xenhtml_touches.count == 0) {
        self._xenhtml_touches = [self._xenhtml_event allTouches];
    }
    
    self.state = UIGestureRecognizerStateCancelled;
}

#pragma mark Don't be an asshole to other gestures

- (BOOL)canBePreventedByGestureRecognizer:(id)arg1 {
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(id)arg1 {
    return NO;
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

#pragma mark Overrides for offsets.

/*-(BOOL)_shouldReceiveTouch:(id)arg1 recognizerView:(id)arg2 touchView:(id)arg3 {
    return YES;
}

-(UIView*)view {
    return self.actualView;
}*/

/*-(const struct _UIWebTouchEvent*)lastTouchEvent {
    struct _UIWebTouchEvent* event = const_cast<struct _UIWebTouchEvent*>([super lastTouchEvent]);
    
    CGPoint locationInDocumentCoords = event->locationInDocumentCoordinates;
    
    // Need to offset this.
    locationInDocumentCoords.x = locationInDocumentCoords.x - self.xOffset;
    locationInDocumentCoords.y = locationInDocumentCoords.y - self.yOffset;
    
    event->locationInDocumentCoordinates = locationInDocumentCoords;
    //event->locationInScreenCoordinates = locationInDocumentCoords;
    
    unsigned touchCount = event->touchPointCount;
    
    for (unsigned i = 0; i < touchCount; i++) {
        struct _UIWebTouchPoint& touchPoint = event->touchPoints[i];
        
        CGPoint point = (event->touchPoints[i]).locationInDocumentCoordinates;
        
        // We should offset.
        if (point != 0) {
            point.x = point.x - self.xOffset;
            point.y = point.y - self.yOffset;
        }
        
        //touchPoint.locationInDocumentCoordinates = point;
        
        NSLog(@"GOT POINT, LOCATION: %@", NSStringFromCGPoint(point));
    }
    
    NSLog(@"*********** GOT EVENT, doc-coords: %@", NSStringFromCGPoint(event->locationInDocumentCoordinates));
    
    return const_cast<const struct _UIWebTouchEvent*>(event);
}*/

@end
