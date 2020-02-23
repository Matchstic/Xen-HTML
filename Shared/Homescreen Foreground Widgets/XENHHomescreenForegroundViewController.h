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
#import "XENHWidgetLayerController.h"
#import "XENHHomescreenForegroundPickerController.h"
#import "XENHWidgetController.h"

@interface XENHHomescreenForegroundViewController : XENHWidgetLayerController <XENHHomescreenForegroundPickerDelegate, XENHWidgetEditingDelegate>

+ (UIViewController*)_widgetSettingsControllerWithURL:(NSString*)widgetURL currentMetadata:(NSDictionary*)currentMetadata showCancel:(BOOL)showCancel andDelegate:(id<XENHHomescreenForegroundPickerDelegate>)delegate;

// Handling of user interaction
- (void)noteUserDidPressAddWidgetButton;

// Handle incoming messages from hooked methods
- (void)updatedPageCounts:(int)newCount;
- (void)updateEditingModeState:(BOOL)newEditingModeState;

- (void)updatePopoverPresentationController:(id)controller;

@end
