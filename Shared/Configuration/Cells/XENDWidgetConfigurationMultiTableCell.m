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

#import "XENDWidgetConfigurationMultiTableCell.h"
#import "XENHResources.h"

@implementation XENDWidgetConfigurationMultiTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

- (void)setup {
    NSString *title = self.cell.text;
    
    self.textLabel.text = title;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    [self update];
}

- (void)update {
    NSArray *selected = self.cell.value ? self.cell.value : @[];
    if (![selected isKindOfClass:[NSArray class]]) selected = @[];
    
    NSString *detail = [NSString stringWithFormat:[XENHResources localisedStringForKey:@"WIDGET_SETTINGS_ENABLED_COUNT"], selected.count];
    
    self.detailTextLabel.text = detail;
}

@end
