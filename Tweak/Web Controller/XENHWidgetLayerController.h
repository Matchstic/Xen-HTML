//
//  XENHMultiplexWidgetController.h
//  Tweak
//
//  Created by Matt Clarke on 30/04/2018.
//

#import <UIKit/UIKit.h>
#import "XENHResources.h"

@interface XENHWidgetLayerController : UIViewController

@property (nonatomic, readonly) XENHLayerLocation layerLocation;
@property (nonatomic, strong) NSMutableDictionary *multiplexedWidgets;
@property (nonatomic, strong) NSDictionary *layerPreferences;

// Initialisation
- (instancetype)initWithLayerLocation:(XENHLayerLocation)location;

// Pause handling of internal widgets array
-(void)setPaused:(BOOL)paused;
-(void)setPaused:(BOOL)paused animated:(BOOL)animated;

// Widget lifecycle handling
- (void)unloadWidgets;
- (void)reloadWidgets:(BOOL)clearWidgets;

// Orientation handling
- (void)rotateToOrientation:(int)orient;

// Handling of settings changes
- (void)noteUserPreferencesDidChange;

// Forwarding of touches through to internal widgets array
- (BOOL)isAnyWidgetTrackingTouch;
- (void)forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
