//
//  XENHHomescreenForegroundViewController.m
//  Tweak
//
//  Created by Matt Clarke on 04/06/2018.
//

#import "XENHHomescreenForegroundViewController.h"
#import "XENHTouchPassThroughView.h"
#import "XENHWidgetController.h"

@interface XENHHomescreenForegroundViewController ()
@end

@implementation XENHHomescreenForegroundViewController

// Overriden
- (instancetype)initWithLayerLocation:(XENHLayerLocation)location {
    return [super initWithLayerLocation:kLocationSBForeground];
}

// Overriden
- (void)loadView {
    // We don't need touch forwarding when being foreground!
    self.view = [[XENHTouchPassThroughView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    
    // After loading, we can assume we're going to page 1 once the user does a first unlock.
    [self updatedNowDisplayingPage:1];
}

// Overriden for correct layout
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Correctly layout widget controllers too!
    for (XENHWidgetController *widgetController in self.multiplexedWidgets.allValues) {
        // Get the controller's metadata.
        
        // We assume each the widget hosted by this controller is placed at (0,0), so we can
        // just shift the controller's view's origin as needed.
        CGFloat xOffsetMultipler = [[widgetController.widgetMetadata objectForKey:@"xOffset"] floatValue];
        CGFloat yOffsetMultipler = [[widgetController.widgetMetadata objectForKey:@"yOffset"] floatValue];
        
        widgetController.view.frame = CGRectMake(xOffsetMultipler * SCREEN_WIDTH, yOffsetMultipler * SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
    }
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Handling of settings changes and user interaction
/////////////////////////////////////////////////////////////////////////////

// Overriden
- (void)noteUserPreferencesDidChange {
    // TODO: Handle preference changes, such as:
    // - Snapping to placement grid
    // - Enabled state
}

- (void)noteUserDidPressAddWidgetButton {
    // TODO: Launch widget picker
}

/////////////////////////////////////////////////////////////////////////////
#pragma mark Handle incoming messages from hooked methods
/////////////////////////////////////////////////////////////////////////////

- (void)updatedNowDisplayingPage:(int)page {
    // TODO: Change paused state of widgets not visible?
}

- (void)updatedContentSize:(CGSize)newContentSize {
    self.view.frame = CGRectMake(0, 0, newContentSize.width, newContentSize.height);
}

- (void)updatedPageCounts:(int)newCount {
    // TODO: handle change of page counts.
    // i.e., unload any widgets outside the new page counts.
}

- (void)updateEditingModeState:(BOOL)newEditingModeState {
    // TODO: Change editing state:
    // - Update 'wiggle' animation on widgets
    // - Add/remove close and option boxes on widgets.
    // - Show/hide add widget button
}

@end
