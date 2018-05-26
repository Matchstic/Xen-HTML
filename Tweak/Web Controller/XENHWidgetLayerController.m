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
        self.orderedMultiplexedWidgets = [NSMutableArray array];
        
        [self _setupMultiplexedWidgetsForLocation:location];
    }
    
    return self;
}

- (void)dealloc {
    [self unloadWidgets];
}

- (void)loadView {
    self.view = [[XENHWidgetLayerContainerView alloc] initWithWidgetController:self];
    self.view.backgroundColor = [UIColor clearColor];
    
    [(XENHWidgetLayerContainerView*)self.view setDelegate:self];
    
    /*self.view = [[XENHTouchPassThroughView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    
    XENHTouchForwardingRecognizer *touchForwarding = [[XENHTouchForwardingRecognizer alloc] initWithWidgetController:self andIgnoredViewClasses:@[]];
    touchForwarding.safeAreaInsets = UIEdgeInsetsMake([UIApplication sharedApplication].statusBarFrame.size.height + 20.0, 20.0, 0.0, 20.0);
    
    [self.view addGestureRecognizer:touchForwarding];*/
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
        [widgetController configureWithWidgetIndexFile:location andMetadata:metadata2];
        
        // Add as subview
        widgetController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        [self.view addSubview:widgetController.view];
        
        // Store into our dictionary
        [self.multiplexedWidgets setObject:widgetController forKey:location];
        [self.orderedMultiplexedWidgets addObject:widgetController];
    }
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
        self.orderedMultiplexedWidgets = [NSMutableArray array];
        
        [self _setupMultiplexedWidgetsForLocation:self.layerLocation];
    } else {
        for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
            [widgetController reloadWidget];
        }
    }
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

- (void)noteUserPreferencesDidChange {
    NSDictionary *oldPreferences = [self.layerPreferences copy];
    
    self.layerPreferences = [XENHResources widgetPreferencesForLocation:self.layerLocation];
    
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
            [self.orderedMultiplexedWidgets removeObject:widgetController];
        }
    }
    
    // Next, add any NEW widgets in the incoming preferences.
    for (NSString *location in newWidgetLocations) {
        if (![self.multiplexedWidgets.allKeys containsObject:location]) {
            NSDictionary *metadata = [newWidgetMetadata objectForKey:location];
            
            // Configure the widget controller for this new widget
            XENHWidgetController *widgetController = [[XENHWidgetController alloc] init];
            [widgetController configureWithWidgetIndexFile:location andMetadata:metadata];
            
            // Add as subview
            [self.view addSubview:widgetController.view];
            
            // Store into the dictionary
            [self.multiplexedWidgets setObject:widgetController forKey:location];
            [self.orderedMultiplexedWidgets addObject:widgetController];
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
    NSArray *widgetControllersHandlingEvent = [self _widgetControllersHandlingTouchEvent:event];
    XENlog(@"Controllers handling this touch event: %@", widgetControllersHandlingEvent);
    
    self._touchHandlingWidgets = widgetControllersHandlingEvent;
    
    for (XENHWidgetController *widgetController in self._touchHandlingWidgets) {
        [widgetController forwardTouchesBegan:touches withEvent:event];
    }
}

- (void)forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (XENHWidgetController *widgetController in self._touchHandlingWidgets) {
        [widgetController forwardTouchesMoved:touches withEvent:event];
    }
}

- (void)forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (XENHWidgetController *widgetController in self._touchHandlingWidgets) {
        [widgetController forwardTouchesEnded:touches withEvent:event];
    }
}

- (void)forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (XENHWidgetController *widgetController in self._touchHandlingWidgets) {
        [widgetController forwardTouchesCancelled:touches withEvent:event];
    }
}

// When scroll regions are in use, we want to restrict which widgets recieve a forwarded touch.
- (NSArray*)_widgetControllersHandlingTouchEvent:(UIEvent*)event {
    // Arrays used to easily reference objects later on.
    NSMutableArray *hittestedControllers = [NSMutableArray array];
    NSMutableArray *hittestedViews = [NSMutableArray array];
    
    // The first object is now the topmost view.
    for (XENHWidgetController *widgetController in [self.orderedMultiplexedWidgets reverseObjectEnumerator]) {
        UIView *hittested = [widgetController hitTestForEvent:event];
        
        if (hittested) {
            if ([[hittested class] isEqual:objc_getClass("UIWebOverflowContentView")]) {
                hittested = [hittested superview];
            }
            
            // Map the hittested view to the controller's hash for future reference.
            [hittestedControllers addObject:widgetController];
            [hittestedViews addObject:hittested];
        }
    }
    
    // Check if any of the hittested views are scroll views.
    int count = 0;
    for (UIView *view in hittestedViews) {
        if ([[view class] isEqual:[UIScrollView class]] || [[view class] isEqual:objc_getClass("UIWebOverflowScrollView")])
            count++;
    }
    
    // We now conditionally handle scroll views!
    // If none, then forward to all controllers that were hittested.
    BOOL hasMultipleScrollViews = count > 1;
    
    XENlog(@"Scroll count: %d", count);
    
    // Handle the case where we have one view, or no views.
    // i.e., there's no point doing the below checks for these cases, so reduce complexity.
    if (hittestedControllers.count == 1) {
        // Allow the only hittested widget to take full control of this touch.
        return @[ [hittestedControllers firstObject] ];
    } else if (hittestedControllers.count == 0) {
        // Nothing was hittested.
        return @[];
    } else if (hasMultipleScrollViews) {
        // Refactored out : choose which of the multiple scroll views should process this touch.
        return [self _widgetControllers:hittestedControllers withMultipleScrollViews:hittestedViews];
    } else {
        // Allow all hittested widgets to get this touch since none handle scrolling
        return hittestedControllers;
    }
}

- (NSArray*)_widgetControllers:(NSArray*)widgetControllers withMultipleScrollViews:(NSArray*)scrollViews {
    for (UIView *view in scrollViews) {
        if (![[view class] isEqual:[UIScrollView class]] && ![[view class] isEqual:objc_getClass("UIWebOverflowScrollView")])
            continue;
        
        UIScrollView *scrollView = (UIScrollView*)view;
        
        if (scrollView.isDecelerating) {
            XENlog(@"Decelerating!");
            // This one is last interacted with, and is still animating.
            // i.e., the user may still want to interact with it
            int index = (int)[scrollViews indexOfObject:scrollView];
            return @[ [widgetControllers objectAtIndex:index] ];
        }
    }
    
    // Let the smallest take the touch exclusively. If there are multiple with the same size,
    // forward simultaneously.
    
    BOOL multipleWithSameSize = NO;
    CGSize smallestSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
    UIView *smallestScrollView;
    
    for (UIView *view in scrollViews) {
        // We only care about scrollViews!
        if (![[view class] isEqual:[UIScrollView class]] && ![[view class] isEqual:objc_getClass("UIWebOverflowScrollView")])
            continue;
        
        CGSize size = view.frame.size;
        
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
        if (smallestScrollView != nil) {
            // If there's a smaller one, forward to it!
            XENlog(@"Have a smaller one!");
            int index = (int)[scrollViews indexOfObject:smallestScrollView];
            return @[ [widgetControllers objectAtIndex:index] ];
        } else {
            // Edge case that shouldn't happen, but just in case.
            XENlog(@"Edge case");
            return widgetControllers;
        }
    } else {
        // Forward to all!
        XENlog(@"Multiple with same size");
        return widgetControllers;
    }
}

@end
