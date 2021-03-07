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

#import "XENDWidgetConfigurationMultiController.h"
#import "XENHResources.h"

#import <objc/runtime.h>

@interface XENDWidgetConfigurationMultiController ()
@property (nonatomic, strong) XENDWidgetConfigurationCell *cell;
@property (nonatomic, weak) XENDWidgetConfigurationBaseTableCell *initiator;
@property (nonatomic, strong) NSMutableArray *enabledOptions;
@property (nonatomic, strong) NSMutableArray *disabledOptions;
@end

@implementation XENDWidgetConfigurationMultiController

- (instancetype)initWithCell:(XENDWidgetConfigurationCell*)cell
                   initiator:(XENDWidgetConfigurationBaseTableCell*)initiator
                       title:(NSString*)title {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.title = title;
        self.cell = cell;
        self.initiator = initiator;
        
        // Figure out enabled and disabled options
        NSArray *enabled = cell.value ? cell.value : @[];
        if (![enabled isKindOfClass:[NSArray class]]) enabled = @[];
        
        NSArray *options = [cell.properties objectForKey:@"options"] ? [cell.properties objectForKey:@"options"] : @[];
        
        NSMutableArray *enabledOptions = [@[] mutableCopy];
        NSMutableArray *disabledOptions = [@[] mutableCopy];
        
        for (NSDictionary *item in options) {
            BOOL isEnabled = [enabled containsObject:[item objectForKey:@"value"]];
            if (isEnabled) {
                [enabledOptions addObject:item];
            } else {
                [disabledOptions addObject:item];
            }
        }
        
        // Sort enabled options to match user's ordering
        [enabledOptions sortUsingComparator:^NSComparisonResult(NSDictionary* _Nonnull obj1, NSDictionary* _Nonnull obj2) {
            NSInteger indexA = [enabled indexOfObject:[obj1 objectForKey:@"value"]];
            NSInteger indexB = [enabled indexOfObject:[obj2 objectForKey:@"value"]];
            
            return indexA < indexB ? NSOrderedAscending : NSOrderedDescending;
        }];
        
        // Disabled options ordering matches what is in the options array
        
        // Handle dummy content if needed
        if (enabledOptions.count == 0) {
            [enabledOptions addObject:[self dummyRow:0]];
        }
        
        if (disabledOptions.count == 0) {
            [disabledOptions addObject:[self dummyRow:1]];
        }
        
        self.enabledOptions = enabledOptions;
        self.disabledOptions = disabledOptions;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.navigationItem.title = self.title;
    
    [self.tableView setEditing:YES];
}

#pragma mark - Table view data source

- (NSDictionary*)dummyRow:(NSInteger)section {
    return @{
        @"text": [XENHResources localisedStringForKey:section == 0 ? @"NO_ENABLED_ITEMS" : @"NO_DISABLED_ITEMS"],
        @"dummy": @YES
    };
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.enabledOptions.count : self.disabledOptions.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [XENHResources localisedStringForKey:section == 0 ? @"WIDGET_SETTINGS_ENABLED" : @"WIDGET_SETTINGS_DISABLED"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NSArray *list = indexPath.section == 0 ? self.enabledOptions : self.disabledOptions;
    NSDictionary *item = [list objectAtIndex:indexPath.row];
    
    NSString *text = [item objectForKey:@"text"];
    cell.textLabel.text = text ? text : @"Missing text";
    
    BOOL isDummyRow = [item objectForKey:@"dummy"] != nil;
    
    // Colouration for empty state
    if (isDummyRow) {
        if (@available(iOS 13.0, *)) {
            cell.textLabel.textColor = [UIColor secondaryLabelColor];
        } else {
            cell.textLabel.textColor = [UIColor grayColor];
        }
        
        [cell setEditing:NO];
    } else {
        if (@available(iOS 13.0, *)) {
            cell.textLabel.textColor = [UIColor labelColor];
        } else {
            cell.textLabel.textColor = [UIColor darkTextColor];
        }
        
        [cell setEditing:YES];
    }
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *list = indexPath.section == 0 ? self.enabledOptions : self.disabledOptions;
    NSDictionary *item = [list objectAtIndex:indexPath.row];
    
    if ([item objectForKey:@"dummy"] != nil) return UITableViewCellEditingStyleNone;
    
    return indexPath.section == 0 ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleInsert;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSMutableArray *startList = fromIndexPath.section == 0 ? self.enabledOptions : self.disabledOptions;
    NSMutableArray *endList = toIndexPath.section == 0 ? self.enabledOptions : self.disabledOptions;
    
    NSDictionary *item = [startList objectAtIndex:fromIndexPath.row];
    
    [startList removeObjectAtIndex:fromIndexPath.row];
    [endList insertObject:item atIndex:toIndexPath.row];
    
    [self.tableView reloadData];
    
    [self insertDummyDataIfNeeded:startList :endList :fromIndexPath];
    [self saveCurrentState];
}

- (void)insertDummyDataIfNeeded:(NSMutableArray*)startList :(NSMutableArray*)endList :(NSIndexPath*)fromIndexPath {
    // Handle dummy content
    if (startList.count == 0) {
        // Insert dummy content
        [startList addObject:[self dummyRow:fromIndexPath.section]];
        
        [self.tableView reloadData];
    } else if (endList.count > 0) {
        // Just gained its first item, remove the dummy item
        NSInteger dummyIndex = -1;
        
        for (NSDictionary *item in endList) {
            if ([item objectForKey:@"dummy"] != nil) dummyIndex = [endList indexOfObject:item];
        }
        
        if (dummyIndex != -1) {
            [endList removeObjectAtIndex:dummyIndex];
            [self.tableView reloadData];
        }
    }
}

- (void)saveCurrentState {
    NSMutableArray *orderedState = [@[] mutableCopy];
    
    for (NSDictionary *item in self.enabledOptions) {
        // Skip dummy state
        if ([item objectForKey:@"dummy"]) continue;
        
        [orderedState addObject:[item objectForKey:@"value"]];
    }
    
    [self.cell setValue:orderedState];
    [self.initiator update];
}

- (NSString*)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [XENHResources localisedStringForKey:@"WIDGET_SETTINGS_REMOVE"];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray *startList = indexPath.section == 0 ? self.enabledOptions : self.disabledOptions;
    NSMutableArray *endList = indexPath.section != 0 ? self.enabledOptions : self.disabledOptions;
    
    if (startList.count == 0) return;
    
    NSDictionary *item = [startList objectAtIndex:indexPath.row];
    
    NSInteger newRow = endList.count;
    
    [startList removeObjectAtIndex:indexPath.row];
    [endList insertObject:item atIndex:newRow];
    
    // Update tableView
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newRow inSection:indexPath.section == 0 ? 1 : 0]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    
    // State stuff
    [self insertDummyDataIfNeeded:startList :endList :indexPath];
    [self saveCurrentState];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *list = indexPath.section == 0 ? self.enabledOptions : self.disabledOptions;
    NSDictionary *item = [list objectAtIndex:indexPath.row];
    
    return [item objectForKey:@"dummy"] == nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *list = indexPath.section == 0 ? self.enabledOptions : self.disabledOptions;
    NSDictionary *item = [list objectAtIndex:indexPath.row];
    
    return [item objectForKey:@"dummy"] == nil;
}

@end
