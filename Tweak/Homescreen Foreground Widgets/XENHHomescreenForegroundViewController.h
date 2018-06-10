//
//  XENHHomescreenForegroundViewController.h
//  Tweak
//
//  Created by Matt Clarke on 04/06/2018.
//

#import <UIKit/UIKit.h>
#import "XENHWidgetLayerController.h"

@interface XENHHomescreenForegroundViewController : XENHWidgetLayerController

// Handling of user interaction
- (void)noteUserDidPressAddWidgetButton;

// Handle incoming messages from hooked methods
- (void)updatedNowDisplayingPage:(int)page;
- (void)updatedContentSize:(CGSize)newContentSize;
- (void)updatedPageCounts:(int)newCount;
- (void)updateEditingModeState:(BOOL)newEditingModeState;

@end
