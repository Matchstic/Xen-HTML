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
#import <Preferences/PSViewController.h>
#import "XENHEditorToolbarController.h"
#import "XENHEditorPositioningController.h"
#import "XENHPickerController.h"
#import "XENHFallbackOnlyOptionsController.h"

typedef enum : NSUInteger {
    kEditorVariantLockscreenBackground = 0,
    kEditorVariantLockscreenForeground = 1,
    kEditorVariantHomescreenBackground = 2
} XENHEditorVariant;

@protocol XENHEditorDelegate <NSObject>
-(void)didAcceptChanges:(NSString*)widgetURL withMetadata:(NSDictionary*)metadata isNewWidget:(BOOL)isNewWidget;
@end

@interface XENHEditorViewController : PSViewController <XENHEditorToolbarDelegate, XENHEditorPositioningDelegate, XENHFallbackDelegate>

@property (nonatomic, weak) id<XENHEditorDelegate> delegate;
@property (nonatomic, strong) NSString *widgetURL;
@property (nonatomic, readwrite) BOOL isNewWidget;

- (instancetype)initWithVariant:(XENHEditorVariant)variant widgetURL:(NSString*)widgetURL delegate:(id<XENHEditorDelegate>)delegate isNewWidget:(BOOL)isNewWidget;

@end
