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

@interface XENHPickerController2 : UITableViewController {
    int _variant;
    id<XENHPickerDelegate2> _delegate;
    NSArray *_sbhtmlArray;
    NSArray *_lockHTMLArray;
    NSArray *_groovylockArray;
    NSArray *_cydgetBackgroundArray;
    NSArray *_cydgetForegroundArray;
    NSArray *_winterboardArray;
    NSArray *_iwidgetsArray;
    
    NSArray *_currentSelected;
}

-(id)initWithVariant:(int)variant andDelegate:(id<XENHPickerDelegate2>)delegate andCurrentSelected:(NSString*)current;
-(id)initWithVariant:(int)variant andDelegate:(id<XENHPickerDelegate2>)delegate andCurrentSelectedArray:(NSArray*)currentArray;

@end
