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

@protocol XENHConfigJSDelegate <NSObject>
-(void)textFieldDidChange:(id)value withKey:(NSString*)key;
-(void)switchDidChange:(id)value withKey:(NSString*)key;
@end

@interface XENHConfigJSCell : UITableViewCell <UITextFieldDelegate> {
    NSDictionary *_datum;
}

@property (nonatomic, strong) UISwitch *switchControl;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *commentLabel;
@property (nonatomic, weak) id<XENHConfigJSDelegate> delegate;

-(void)setupWithDatum:(NSDictionary*)datum;

@end
