//
//  XENHFallbackOnlyOptionsController.m
//  Preferences
//
//  Created by Matt Clarke on 04/05/2018.
//

#import "XENHFallbackOnlyOptionsController.h"
#import "XENHPResources.h"

#define REUSE @"fallbackCell"

@interface XENHFallbackOnlyOptionsController ()

@end

@implementation XENHFallbackOnlyOptionsController

- (instancetype)initWithFallbackState:(BOOL)state {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.fallbackState = state;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:REUSE];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)view {
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:[XENHResources localisedStringForKey:@"WIDGET_SETTINGS_TITLE"]];
    }
    
    [super viewWillAppear:view];
}

-(void)switchDidChange:(UISwitch*)sender {
    [self.fallbackDelegate fallbackStateDidChange:sender.on];
}

#pragma mark - Table view data source

- (BOOL)_allowLegacyMode {
    NSOperatingSystemVersion version;
    version.majorVersion = 10.0;
    version.minorVersion = 0;
    version.patchVersion = 0;
    
    return ![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [self _allowLegacyMode] ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0 && [self _allowLegacyMode]) {
        return [XENHResources localisedStringForKey:@"WIDGET_SETTINGS_LEGACY_FOOTER"];
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:REUSE forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE];
    }
    
    // Configure the cell...
    if (indexPath.section == 0 && [self _allowLegacyMode]) {
        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchView setOn:self.fallbackState];
        [switchView addTarget:self action:@selector(switchDidChange:) forControlEvents:UIControlEventValueChanged];
        
        cell.accessoryView = switchView;
        
        cell.textLabel.text = [XENHResources localisedStringForKey:@"WIDGET_SETTINGS_LEGACY_MODE"];
        
        if (@available(iOS 13.0, *)) {
            cell.textLabel.textColor = [UIColor labelColor];
        } else {
            cell.textLabel.textColor = [UIColor darkTextColor];
        }
    } else {
        cell.accessoryView = nil;
        
        cell.textLabel.text = [XENHResources localisedStringForKey:@"WIDGET_SETTINGS_NONE"];
        
        if (@available(iOS 13.0, *)) {
            cell.textLabel.textColor = [UIColor placeholderTextColor];
        } else {
            cell.textLabel.textColor = [UIColor grayColor];
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
