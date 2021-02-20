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

#import "XENDWidgetConfigurationPageController.h"
#import "Model/XENDWidgetConfigurationPage.h"

#import "Cells/XENDWidgetConfigurationSwitchTableCell.h"
#import "Cells/XENDWidgetConfigurationNumberTableCell.h"
#import "Cells/XENDWidgetConfigurationTextTableCell.h"
#import "Cells/XENDWidgetConfigurationSliderTableCell.h"

@interface XENDWidgetConfigurationPageController ()
@property (nonatomic, weak) id<XENDWidgetConfigurationDelegate> delegate;
@property (nonatomic, strong) XENDWidgetConfigurationPage *model;
@end

@implementation XENDWidgetConfigurationPageController

- (instancetype)initWithOptions:(NSArray*)options
                       delegate:(id<XENDWidgetConfigurationDelegate>)delegate
                          title:(NSString*)title {
    
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.delegate = delegate;
        
        // Setup model for the dictionary and delegate
        self.model = [[XENDWidgetConfigurationPage alloc] initWithOptions:options delegate:delegate];
        
        self.title = title;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.navigationItem.title = self.title;
    
    // Register cells
    [self.tableView registerClass:[XENDWidgetConfigurationBaseTableCell class] forCellReuseIdentifier:@"unknown"];
    [self.tableView registerClass:[XENDWidgetConfigurationBaseTableCell class] forCellReuseIdentifier:@"page"];
    [self.tableView registerClass:[XENDWidgetConfigurationSwitchTableCell class] forCellReuseIdentifier:@"switch"];
    [self.tableView registerClass:[XENDWidgetConfigurationNumberTableCell class] forCellReuseIdentifier:@"number"];
    [self.tableView registerClass:[XENDWidgetConfigurationTextTableCell class] forCellReuseIdentifier:@"text"];
    [self.tableView registerClass:[XENDWidgetConfigurationSliderTableCell class] forCellReuseIdentifier:@"slider"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.model.groups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    XENDWidgetConfigurationGroup *group = [[self.model groups] objectAtIndex:section];
    return group.cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XENDWidgetConfigurationGroup *group = [[self.model groups] objectAtIndex:indexPath.section];
    XENDWidgetConfigurationCell *modelCell = [group.cells objectAtIndex:indexPath.row];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:modelCell.type forIndexPath:indexPath];
    
    [(XENDWidgetConfigurationBaseTableCell*)cell configure:modelCell];
    
    return cell;
}

// Apply double-height to those cells that need it
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Some cells are double height to account for inputs
    XENDWidgetConfigurationGroup *group = [[self.model groups] objectAtIndex:indexPath.section];
    XENDWidgetConfigurationCell *cell = [group.cells objectAtIndex:indexPath.row];
    
    BOOL isDoubleHeight = [cell.type isEqualToString:@"text"] || [cell.type isEqualToString:@"slider"];
    
    return 44.0 * (isDoubleHeight ? 2 : 1);
}

// Footer for group - a 'comment' type cell in the underlying JSON structure
- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    XENDWidgetConfigurationGroup *group = [self.model.groups objectAtIndex:section];
    return [group.footer isEqualToString:@""] ? nil : group.footer;
}

// Title for group - a 'title' type cell in the underlying JSON structure
- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    XENDWidgetConfigurationGroup *group = [self.model.groups objectAtIndex:section];
    return [group.title isEqualToString:@""] ? nil : group.title;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    XENDWidgetConfigurationGroup *group = [self.model.groups objectAtIndex:indexPath.section];
    XENDWidgetConfigurationCell *cell = [group.cells objectAtIndex:indexPath.row];
    NSString *type = cell.type;
    
    BOOL isSegueAction = [type isEqualToString:@"page"] ||
                            [type isEqualToString:@"location"] ||
                            [type isEqualToString:@"color"] ||
                            [type isEqualToString:@"option"];
    
    if (isSegueAction) {
        // Lookup the page that needs to be pushed, and pass appropriate stuff to it
        UIViewController *controller = nil;
        
        if ([type isEqualToString:@"page"]) {
            // New page, create new instance of current class with the right options
            NSString *title = cell.text;
            NSArray *options = [cell.properties objectForKey:@"options"];
            
            controller = [[XENDWidgetConfigurationPageController alloc] initWithOptions:options
                                                                               delegate:self.delegate
                                                                                  title:title];
        } else if ([type isEqualToString:@"location"]) {
            // TODO: Setup Location controller
        } else if ([type isEqualToString:@"color"]) {
            // TODO: Setup Colour controller
        } else if ([type isEqualToString:@"option"]) {
            // TODO: Setup Option controller
        }
        
        if (controller) {
            [self.navigationController pushViewController:controller animated:YES];
        }
    } else {
        // Do nothing, cell control should handle this
    }
}

@end
