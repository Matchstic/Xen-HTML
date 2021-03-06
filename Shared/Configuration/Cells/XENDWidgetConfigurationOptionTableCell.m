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

#import "XENDWidgetConfigurationOptionTableCell.h"

@implementation XENDWidgetConfigurationOptionTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

- (void)setup {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [self update];
}

- (void)update {
    id selectedItem = self.cell.value;
    NSArray *options = [self.cell.properties objectForKey:@"options"];
    
    if (!options) options = @[];
    
    // Find the currently selected item's title
    NSString *detail = @"";
    for (NSDictionary *item in options) {
        id itemValue = [item objectForKey:@"value"];
        if ([selectedItem isEqual:itemValue]) {
            detail = [item objectForKey:@"text"];
            break;
        }
    }
    
    self.detailTextLabel.text = detail;
    self.textLabel.text = self.cell.text;
}

@end
