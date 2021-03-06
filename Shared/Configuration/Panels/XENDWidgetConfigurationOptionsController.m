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

#import "XENDWidgetConfigurationOptionsController.h"

@interface XENDWidgetConfigurationOptionsController ()
@property (nonatomic, strong) XENDWidgetConfigurationCell *cell;
@property (nonatomic, weak) XENDWidgetConfigurationBaseTableCell *initiator;
@property (nonatomic, strong) NSString *comment;
@end

@implementation XENDWidgetConfigurationOptionsController

- (instancetype)initWithCell:(XENDWidgetConfigurationCell*)cell
                   initiator:(XENDWidgetConfigurationBaseTableCell*)initiator
                       title:(NSString*)title {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.title = title;
        self.cell = cell;
        self.initiator = initiator;
        self.comment = [cell.properties objectForKey:@"comment"];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    self.navigationItem.title = self.title;
}

#pragma mark - Table view data source

- (NSDictionary*)optionForRow:(NSInteger)row {
    NSArray *options = [self.cell.properties objectForKey:@"options"];
    return [options objectAtIndex:row];
}

- (NSDictionary*)enabledItem {
    NSArray *options = [self.cell.properties objectForKey:@"options"];
    id selectedItem = self.cell.value;
    
    // Find the currently selected item's title
    NSDictionary *enabledItem = nil;
    for (NSDictionary *item in options) {
        id itemValue = [item objectForKey:@"value"];
        if ([selectedItem isEqual:itemValue]) {
            enabledItem = item;
            break;
        }
    }
    
    return enabledItem;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.comment;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *options = [self.cell.properties objectForKey:@"options"];
    return options ? options.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NSDictionary *item = [self optionForRow:indexPath.row];
    NSDictionary *enabledItem = [self enabledItem];
    NSString *text = [item objectForKey:@"text"];
    
    cell.textLabel.text = text ? text : @"Missing text";
    if ([[enabledItem objectForKey:@"value"] isEqual:[item objectForKey:@"value"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *item = [self optionForRow:indexPath.row];
    id value = [item objectForKey:@"value"];
    
    // Update model
    [self.cell setValue:value];
    [self.initiator update];
    
    // Update checkmarks
    for (int i = 0; i < self.tableView.visibleCells.count; i++) {
        UITableViewCell *cell = self.tableView.visibleCells[i];
        cell.accessoryType = i == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
}

@end
