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

@protocol XENHPickerDelegate2 <NSObject>
-(void)didChooseWidget:(NSString*)filePath;
-(void)cancelShowingPicker;
@end

typedef enum : NSUInteger {
    kPickerVariantLockscreenBackground = 0,
    kPickerVariantLockscreenForeground = 1,
    kPickerVariantHomescreenBackground = 2,
    kPickerVariantHomescreenForeground = 3,
} XENHPickerVariant;

@interface XENHPickerController : UITableViewController

@property (nonatomic, strong) NSArray *universalWidgets;
@property (nonatomic, strong) NSArray *layerWidgets;
@property (nonatomic, strong) NSArray *backgroundWidgets;

@property (nonatomic, readwrite) XENHPickerVariant variant;
@property (nonatomic, weak) id<XENHPickerDelegate2> delegate;
@property (nonatomic, strong) NSArray *currentSelected;

-(id)initWithVariant:(XENHPickerVariant)variant andDelegate:(id<XENHPickerDelegate2>)delegate andCurrentSelected:(NSString*)current;
-(id)initWithVariant:(XENHPickerVariant)variant andDelegate:(id<XENHPickerDelegate2>)delegate andCurrentSelectedArray:(NSArray*)currentArray;

@end
