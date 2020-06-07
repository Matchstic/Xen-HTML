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

#import "XENHWidgetLayerController.h"
#import "XENHWidgetController.h"
#import "XENHTouchPassThroughView.h"
#import <objc/runtime.h>

@interface XENHWidgetLayerController ()

@end

@implementation XENHWidgetLayerController

/////////////////////////////////////////////////////////////////////////////
#pragma mark Initialisation
/////////////////////////////////////////////////////////////////////////////

- (instancetype)initWithLayerLocation:(XENHLayerLocation)location {
    self = [super init];
    
    if (self) {
        _layerLocation = location;
        
        self.multiplexedWidgets = [NSMutableDictionary dictionary];
        
        [self _setupMultiplexedWidgetsForLocation:location];
    }
    
    return self;
}

- (BOOL)_canShowWhileLocked{
        return YES;
}

- (void)dealloc {
    [self unloadWidgets];
}

- (void)loadView {
    self.view = [[XENHWidgetLayerContainerView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.layer.masksToBounds = YES;
    
    [(XENHWidgetLayerContainerView*)self.view setDelegate:self];
}

- (void)_setupMultiplexedWidgetsForLocation:(XENHLayerLocation)location {
    self.layerPreferences = [XENHResources widgetPreferencesForLocation:location];
    
    // Get the widget locations, and associated metadata.
    NSArray *widgetLocations = [self.layerPreferences objectForKey:@"widgetArray"];
    NSDictionary *widgetMetadata = [self.layerPreferences objectForKey:@"widgetMetadata"];
    
    // Load up an appropriate count of XENHWebViewController instances, and configure them.
    [self _loadAllWidgetsFromLocations:widgetLocations andMetadata:widgetMetadata];
}

- (void)_loadAllWidgetsFromLocations:(NSArray*)locations andMetadata:(NSDictionary*)metadata {
    for (NSString *location in locations) {
        NSDictionary *metadata2 = [metadata objectForKey:location];
        
        // Configure the widget controller for this new widget
        XENHWidgetController *widgetController = [[XENHWidgetController alloc] init];
        if ([XENHResources displayState] == YES) {
            // Display is on, no need to JIT load
            widgetController.requiresJITWidgetLoad = NO;
        } else {
            widgetController.requiresJITWidgetLoad = (self.layerLocation == kLocationLSForeground ||
                                                      self.layerLocation == kLocationLSBackground) &&
                                                      [XENHResources hasSeenFirstUnlock];
        }
        [widgetController configureWithWidgetIndexFile:location andMetadata:metadata2];
        
        // Add as subview
        widgetController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        [self.view addSubview:widgetController.view];
        
        // Store into our dictionary
        [self.multiplexedWidgets setObject:widgetController forKey:location];
    }
}

- (void)didReceiveMemoryWarningExternal {
    // Using a different method due to original impl removing hidden views
#if 0
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        [widgetController didReceiveMemoryWarningExternal];
    }
#endif
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Send incoming pause messages to the internal widgets array
/////////////////////////////////////////////////////////////////////////////

-(void)setPaused:(BOOL)paused {
    [self setPaused:paused animated:NO];
}

-(void)setPaused:(BOOL)paused animated:(BOOL)animated {
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        [widgetController setPaused:paused animated:animated];
    }
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Widget lifecycle handling
/////////////////////////////////////////////////////////////////////////////

- (void)unloadWidgets {
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        [widgetController unloadWidget];
    }
}

- (void)reloadWidgets:(BOOL)clearWidgets {
    // We can either clear out the multiplexed widgets dictionary, or just request a reload in-place
    if (clearWidgets) {
        for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
            [widgetController unloadWidget];
            [widgetController.view removeFromSuperview];
        }
        
        self.multiplexedWidgets = [NSMutableDictionary dictionary];
        
        [self _setupMultiplexedWidgetsForLocation:self.layerLocation];
    } else {
        for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
            [widgetController reloadWidget];
        }
    }
}

- (void)doJITWidgetLoadIfNecessary {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
            [widgetController doJITWidgetLoadIfNecessary];
        }
    });
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Orientation handling
/////////////////////////////////////////////////////////////////////////////

- (void)rotateToOrientation:(int)orient {
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        [widgetController rotateToOrientation:orient];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Correctly layout widget controllers too!
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        widgetController.view.frame = self.view.bounds;
    }
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Handling of settings changes
/////////////////////////////////////////////////////////////////////////////

- (void)reloadWithNewLayerPreferences:(NSDictionary*)preferences oldPreferences:(NSDictionary*)oldPreferences {
    self.layerPreferences = preferences;
    
    NSMutableArray *newWidgetLocations = [self.layerPreferences objectForKey:@"widgetArray"];
    NSDictionary *newWidgetMetadata = [self.layerPreferences objectForKey:@"widgetMetadata"];
    
    // First, remove any widgets that have been removed in the new preferences.
    for (NSString *location in [self.multiplexedWidgets.allKeys copy]) {
        if (![newWidgetLocations containsObject:location]) {
            
            // Not present! Remove this widget...
            XENHWidgetController *widgetController = [self.multiplexedWidgets objectForKey:location];
            
            [widgetController unloadWidget];
            [widgetController.view removeFromSuperview];
            
            [self.multiplexedWidgets removeObjectForKey:location];
        }
    }
    
    // Next, add any NEW widgets in the incoming preferences.
    for (NSString *location in newWidgetLocations) {
        if (![self.multiplexedWidgets.allKeys containsObject:location]) {
            NSDictionary *metadata = [newWidgetMetadata objectForKey:location];
            
            // Configure the widget controller for this new widget
            XENHWidgetController *widgetController = [[XENHWidgetController alloc] init];
            
            if ([XENHResources displayState] == YES) {
                // Display is on, no need to JIT load
                widgetController.requiresJITWidgetLoad = NO;
            } else {
                widgetController.requiresJITWidgetLoad = (self.layerLocation == kLocationLSForeground ||
                                                          self.layerLocation == kLocationLSBackground) &&
                                                          [XENHResources hasSeenFirstUnlock];
            }
            [widgetController configureWithWidgetIndexFile:location andMetadata:metadata];
            
            // Add as subview
            [self.view addSubview:widgetController.view];
            
            // Store into the dictionary
            [self.multiplexedWidgets setObject:widgetController forKey:location];
        }
    }
    
    // Now, handle any re-ordering that is needed. We do this by simply going through the new array backwards,
    // forcing each associated widget to the back in turn. The result is the topmost widgets get bubbled up
    // to the topmost position fairly simply.
    for (NSString *location in [newWidgetLocations reverseObjectEnumerator]) {
        XENHWidgetController *widgetController = [self.multiplexedWidgets objectForKey:location];
        
        // Send subview to back.
        [self.view sendSubviewToBack:widgetController.view];
    }
    
    // Finally, re-configure any widgets that have new metadata associated with them.
    NSDictionary *oldWidgetMetadata = [oldPreferences objectForKey:@"widgetMetadata"];
    for (NSString *location in newWidgetMetadata.allKeys) {
        // Grab the new and old metadata
        NSDictionary *newMetadata = [newWidgetMetadata objectForKey:location];
        NSDictionary *oldMetadata = [oldWidgetMetadata objectForKey:location];
        
        // Compare
        if (![newMetadata isEqual:oldMetadata]) {
            // Re-configure if needed
            XENHWidgetController *widgetController = [self.multiplexedWidgets objectForKey:location];
            [widgetController configureWithWidgetIndexFile:location andMetadata:newMetadata];
        }
    }
}

- (void)noteUserPreferencesDidChange {
    NSDictionary *oldPreferences = [self.layerPreferences copy];
    NSDictionary *newPreferences = [XENHResources widgetPreferencesForLocation:self.layerLocation];
    
    [self reloadWithNewLayerPreferences:newPreferences oldPreferences:oldPreferences];
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Forwarding of touches through to internal widgets array
/////////////////////////////////////////////////////////////////////////////

- (BOOL)isAnyWidgetTrackingTouch {
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        if ([widgetController isWidgetTrackingTouch]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer*)arg1 atLocation:(CGPoint)location {
    BOOL anyPrevention = NO;
    
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        if ([widgetController canPreventGestureRecognizer:arg1 atLocation:location]) {
            anyPrevention = YES;
            break;
        }
    }
    
    return anyPrevention;
}

- (void)forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        [widgetController forwardTouchesBegan:touches withEvent:event];
    }
}

- (void)forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        [widgetController forwardTouchesMoved:touches withEvent:event];
    }
}

- (void)forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        [widgetController forwardTouchesEnded:touches withEvent:event];
    }
}

- (void)forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        [widgetController forwardTouchesCancelled:touches withEvent:event];
    }
}

@end
