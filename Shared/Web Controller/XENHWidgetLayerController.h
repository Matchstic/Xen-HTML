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
#import "XENHResources.h"
#import "XENHWidgetLayerContainerView.h"

@interface XENHWidgetLayerController : UIViewController <XENHWidgetLayerContainerViewDelegate>

@property (nonatomic, readonly) XENHLayerLocation layerLocation;
@property (nonatomic, strong) NSMutableDictionary *multiplexedWidgets;
@property (nonatomic, strong) NSMutableArray *orderedMultiplexedWidgets;
@property (nonatomic, strong) NSArray *_touchHandlingWidgets;
@property (nonatomic, strong) NSDictionary *layerPreferences;

// Initialisation
- (instancetype)initWithLayerLocation:(XENHLayerLocation)location;

// Pause handling of internal widgets array
-(void)setPaused:(BOOL)paused;
-(void)setPaused:(BOOL)paused animated:(BOOL)animated;

// Widget lifecycle handling
- (void)unloadWidgets;
- (void)reloadWidgets:(BOOL)clearWidgets;
- (void)reloadWithNewLayerPreferences:(NSDictionary*)preferences oldPreferences:(NSDictionary*)oldPreferences;
- (void)doJITWidgetLoadIfNecessary;
- (void)didReceiveMemoryWarningExternal;

// Orientation handling
- (void)rotateToOrientation:(int)orient;

// Handling of settings changes
- (void)noteUserPreferencesDidChange;

// Forwarding of touches through to internal widgets array
- (BOOL)isAnyWidgetTrackingTouch;
- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer*)arg1 atLocation:(CGPoint)location;
- (void)forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
