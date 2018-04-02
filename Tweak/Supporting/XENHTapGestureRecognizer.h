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

#import <UIKit/UIKit.h>

struct _UIWebTouchPoint {
    CGPoint locationInScreenCoordinates;
    CGPoint locationInDocumentCoordinates;
    unsigned identifier;
    UITouchPhase phase;
};

@interface UIWebTouchEventsGestureRecognizer : UIGestureRecognizer
- (id)initWithTarget:(id)arg1 action:(SEL)arg2 touchDelegate:(id)arg3;
@property (nonatomic, readonly) const struct _UIWebTouchEvent { int type; double timestamp; CGPoint locationInScreenCoordinates; CGPoint locationInDocumentCoordinates; float scale; float rotation; bool inJavaScriptGesture; struct _UIWebTouchPoint *touchPoints; unsigned int touchPointCount; bool isPotentialTap; }*lastTouchEvent;
- (void)touchesBegan:(id)arg1 withEvent:(id)arg2;
- (void)touchesCancelled:(id)arg1 withEvent:(id)arg2;
- (void)touchesEnded:(id)arg1 withEvent:(id)arg2;
- (void)touchesMoved:(id)arg1 withEvent:(id)arg2;

@property (nonatomic, readonly) NSMutableArray *touchIdentifiers;
@property (nonatomic, readonly) NSMutableArray *touchLocations;
@property (nonatomic, readonly) NSMutableArray *touchPhases;
@property (nonatomic, readonly) CGPoint locationInWindow;
@end

@interface UIGestureRecognizer (Private)
- (BOOL)_shouldReceiveTouch:(id)arg1 recognizerView:(id)arg2 touchView:(id)arg3;
@end

@interface XENHTapGestureRecognizer : UIGestureRecognizer

@property (nonatomic, strong) NSSet *_xenhtml_touches;
@property (nonatomic, strong) UIEvent *_xenhtml_event;
@property (nonatomic, strong) UIView *actualView;

// This is offset from (0,0) in the top left corner.
@property (nonatomic, readwrite) CGFloat xOffset;
@property (nonatomic, readwrite) CGFloat yOffset;

@end
