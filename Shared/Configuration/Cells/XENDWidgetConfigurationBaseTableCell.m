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

#import "XENDWidgetConfigurationBaseTableCell.h"

@implementation XENDWidgetConfigurationBaseTableCell

- (void)configure:(XENDWidgetConfigurationCell*)modelCell {
    _cell = modelCell;
    [self setup];
    
    self.textLabel.text = [modelCell.text isEqualToString:@""] ? @"Missing Title" : modelCell.text;
    
    // Disclosure - no need for subclasses for this
    NSArray *needsDisclosure = @[
        @"page",
        @"option",
        @"color",
        @"location"
    ];
    
    if ([needsDisclosure containsObject:modelCell.type]) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

- (void)setup {}

@end
