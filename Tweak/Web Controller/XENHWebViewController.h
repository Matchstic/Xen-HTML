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
#import <WebKit/WebKit.h>

@interface XENHWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, readwrite) int variant;

-(instancetype)initWithBaseString:(NSString*)string;
-(void)rotateToOrientation:(int)orient;
-(void)reloadToNewLocation:(NSString*)newLocation;
-(void)unloadView;
-(void)setPaused:(BOOL)paused;
-(void)setPaused:(BOOL)paused animated:(BOOL)animated;

-(void)_recieveWebTouchGesture:(id)sender;
-(id)_webTouchDelegate;
- (void)_forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)_forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)_forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)_forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

- (void)addGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer;
- (void)removeGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer;

-(CGPoint)currentWebViewPosition;

-(BOOL)isTrackingTouch;

@end
