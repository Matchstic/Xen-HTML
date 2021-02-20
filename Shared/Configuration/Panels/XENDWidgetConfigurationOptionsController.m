//
//  XENDWidgetConfigurationOptionsController.m
//  Xen HTML
//
//  Created by Matt Clarke on 20/02/2021.
//

#import "XENDWidgetConfigurationOptionsController.h"

@interface XENDWidgetConfigurationOptionsController ()
@property (nonatomic, strong) XENDWidgetConfigurationCell *cell;
@property (nonatomic, weak) XENDWidgetConfigurationBaseTableCell *initiator;
@end

@implementation XENDWidgetConfigurationOptionsController

- (instancetype)initWithCell:(XENDWidgetConfigurationCell*)cell
                   initiator:(XENDWidgetConfigurationBaseTableCell*)initiator {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.cell = cell;
        self.initiator = initiator;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
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
