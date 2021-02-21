/*
 Copyright (C) 2021 Matt Clarke
 
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

#import "XENDWidgetConfigurationColorTableCell.h"
#import "../Panels/MSColorPicker/MSColorUtils.h"

@interface XENDWidgetConfigurationColorTableCell ()
@property (nonatomic, strong) UIView *colourWell;
@end

@implementation XENDWidgetConfigurationColorTableCell

- (void)setup {
    if (!self.colourWell) {
        self.colourWell = [[UIView alloc] initWithFrame:CGRectZero];
        
        if (@available(iOS 13.0, *)) {
            self.colourWell.layer.borderColor = [UIColor separatorColor].CGColor;
        } else {
            self.colourWell.layer.borderColor = [UIColor grayColor].CGColor;
        }
        self.colourWell.layer.borderWidth = 1.0;
        
        [self.contentView addSubview:self.colourWell];
    }
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [self update];
}

- (void)update {
    NSString *hexColour = self.cell.value;
    UIColor *colour = MSColorFromHexString(hexColour);
    self.colourWell.backgroundColor = colour ? colour : [UIColor whiteColor];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = self.textLabel.frame.origin.x;
    CGFloat entireWidth = 51;
    CGFloat roundWidth = 32;
    self.colourWell.frame = CGRectMake(self.bounds.size.width - entireWidth - padding, (self.bounds.size.height - roundWidth) / 2, roundWidth, roundWidth);
    self.colourWell.layer.cornerRadius = roundWidth / 2;
}

@end
