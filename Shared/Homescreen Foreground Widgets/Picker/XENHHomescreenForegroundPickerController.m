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

#import "XENHHomescreenForegroundPickerController.h"
#import "XENHPickerPreviewController.h"
#import "XENHHomescreenForegroundPickerCell.h"
#import "XENHResources.h"
#import "XENHPickerItem.h"
#import "XENHWidgetConfiguration.h"

#import "XENHHomescreenForegroundViewController.h"

#define REUSE @"picker"

@interface XENHHomescreenForegroundPickerController ()

@property (nonatomic, weak) id<XENHHomescreenForegroundPickerDelegate> delegate;
@property (nonatomic, strong) NSArray* currentSelected;

@property (nonatomic, strong) NSArray *universalWidgets;
@property (nonatomic, strong) NSArray *layerWidgets;

@end

@implementation XENHHomescreenForegroundPickerController

-(id)initWithDelegate:(id<XENHHomescreenForegroundPickerDelegate>)delegate andCurrentSelectedArray:(NSArray*)currentArray {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.delegate = delegate;
        self.currentSelected = currentArray;
        
        [self loadLayerWidgets];
        [self loadUniversalWidgets];
    }
    
    return self;
}

- (NSArray*)widgetsFromPath:(NSString*)path {
    NSMutableArray *results = [NSMutableArray array];
    
    NSArray *widgets = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString *result in widgets) {
        NSString *absoluteURL = [NSString stringWithFormat:@"%@/%@/index.html", path, result];
        if (![[NSFileManager defaultManager] fileExistsAtPath:absoluteURL]) continue;
        
        XENHPickerItem *item = [[XENHPickerItem alloc] init];
        item.absoluteUrl = absoluteURL;
        
        // Load config.json if available
        NSString *configPath = [NSString stringWithFormat:@"%@/%@/config.json", path, result];
        NSData *data = [NSData dataWithContentsOfFile:configPath];
        NSDictionary *config;
        
        if (data) {
            NSError *error;
            config = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:configPath] options:kNilOptions error:&error];
        }
        
        if (config) {
            item.name = [config objectForKey:@"name"] ? [config objectForKey:@"name"] : result;
            item.config = config;
        } else {
            item.name = result;
            item.config = config;
        }
        
        [results addObject:item];
    }
    
    return results;
}

- (void)loadLayerWidgets {
    NSMutableArray *results = [NSMutableArray array];
    
    // Layer-specific widgets
    {
#if TARGET_IPHONE_SIMULATOR==0
        NSString *path = @"/var/mobile/Library/Widgets/Homescreen";
#else
        NSString *path = @"/opt/simject/var/mobile/Library/Widgets/Homescreen";
#endif
        [results addObjectsFromArray:[self widgetsFromPath:path]];
    }
    
    // Legacy widgets (SBHTML)
    {
#if TARGET_IPHONE_SIMULATOR==0
        NSString *path = @"/var/mobile/Library/SBHTML";
#else
        NSString *path = @"/opt/simject/var/mobile/Library/SBHTML";
#endif
        NSArray *sbhtml = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        
        for (NSString *thing in sbhtml) {
            NSMutableString *absoluteURL = [[NSString stringWithFormat:@"%@/%@/", path, thing] mutableCopy];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@index.html", absoluteURL]]) {
                [absoluteURL appendString:@"index.html"];
            } else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@Wallpaper.html", absoluteURL]]) {
                [absoluteURL appendString:@"Wallpaper.html"];
            } else {
                continue;
            }
            
            XENHPickerItem *item = [[XENHPickerItem alloc] init];
            item.absoluteUrl = absoluteURL;
            item.name = thing;
            
            [results addObject:item];
        }
    }
    
    self.layerWidgets = [self _orderAlphabetically:results];
}

- (void)loadUniversalWidgets {
    NSMutableArray *results = [NSMutableArray array];
    
    // Universal
    {
#if TARGET_IPHONE_SIMULATOR==0
        NSString *path = @"/var/mobile/Library/Widgets/Universal";
#else
        NSString *path = @"/opt/simject/var/mobile/Library/Widgets/Universal";
#endif
        [results addObjectsFromArray:[self widgetsFromPath:path]];
    }
    
    // iWidgets
    {
#if TARGET_IPHONE_SIMULATOR==0
        NSString *path = @"/var/mobile/Library/iWidgets";
#else
        NSString *path = @"/opt/simject/var/mobile/Library/iWidgets";
#endif
        NSArray *widgets = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        
        for (NSString *result in widgets) {
            NSMutableString *absoluteURL = [[NSString stringWithFormat:@"%@/%@/", path, result] mutableCopy];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@index.html", absoluteURL]]) {
                [absoluteURL appendString:@"index.html"];
            } else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@Widget.html", absoluteURL]]) {
                [absoluteURL appendString:@"Widget.html"];
            } else {
                continue;
            }
            
            XENHPickerItem *item = [[XENHPickerItem alloc] init];
            item.absoluteUrl = absoluteURL;
            item.name = result;
            
            [results addObject:item];
        }
    }
        
    self.universalWidgets = [self _orderAlphabetically:results];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Cancel button.
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:[XENHResources localisedStringForKey:@"WIDGET_PICKER_AVAILABLE_WIDGETS"]];
        
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"CANCEL"] style:UIBarButtonItemStyleDone target:self action:@selector(cancel:)];
        [[self navigationItem] setLeftBarButtonItem:cancel];
    }
}

-(void)cancel:(id)sender {
    // Just hide our modal controller.
    [self.delegate cancelShowingPicker];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // Configure table view's cell class.
    [self.tableView registerClass:[XENHHomescreenForegroundPickerCell class] forCellReuseIdentifier:REUSE];
}

- (NSArray*)_orderAlphabetically:(NSMutableArray*)array {
    return [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        XENHPickerItem *leftItem = (XENHPickerItem*)obj1;
        XENHPickerItem *rightItem = (XENHPickerItem*)obj2;
        
        return [leftItem.name caseInsensitiveCompare:rightItem.name];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Always have one cell stating there is "no available widgets" for a section
    return [self _itemCountForSection:section] > 0 ? [self _itemCountForSection:section] : 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self _itemCountForSection:indexPath.section] == 0) {
        return 44.0;
    }
    
    // Next, check if this cell can have a screenshot. If so, we can give it some more height.
    NSString *url = [self _itemForIndexPath:indexPath].absoluteUrl;
    
    NSString *thing = [url stringByDeletingLastPathComponent];
    thing = [thing stringByAppendingString:@"/Screenshot.png"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:thing]) {
        thing = nil;
    }
    
    return thing != nil ? 100.0 : 80.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XENHHomescreenForegroundPickerCell *cell = (XENHHomescreenForegroundPickerCell*)[tableView dequeueReusableCellWithIdentifier:REUSE forIndexPath:indexPath];
    if (!cell) {
        cell = [[XENHHomescreenForegroundPickerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE];
    }
    
    // Configure the cell...
    if ([self _itemCountForSection:indexPath.section] > 0) {
        XENHPickerItem *item = [self _itemForIndexPath:indexPath];
        
        // Only doing this here for backwards compatibility purposes
        if (!item.screenshotUrl) {
            NSString *screenshotUrl = [item.absoluteUrl stringByDeletingLastPathComponent];
            screenshotUrl = [screenshotUrl stringByAppendingString:@"/Screenshot.png"];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:screenshotUrl]) {
                screenshotUrl = @"";
            }
            
            item.screenshotUrl = screenshotUrl;
        }

        [cell setupWithItem:item];
        
        // Based off the variant, we will also check to see if this cell is currently enabled. If so, we will colour it
        // a light green.
        
        if ([_currentSelected containsObject:item.absoluteUrl]) {
            if (@available(iOS 13.0, *)) {
                if ([UITraitCollection.currentTraitCollection userInterfaceStyle] == UIUserInterfaceStyleDark)
                    cell.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:1.0 blue:238.0/255.0 alpha:0.3];
                else
                    cell.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:1.0 blue:238.0/255.0 alpha:1.0];
            } else {
                cell.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:1.0 blue:238.0/255.0 alpha:1.0];
            }
        } else {
            if (@available(iOS 13.0, *)) {
                cell.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
            } else {
                // Fallback on earlier versions
                cell.backgroundColor = [UIColor whiteColor];
            }
        }
    } else {
        // There's no items in this section, so state it!
        [cell setupForNoWidgetsWithWidgetType:[self _nameForSection:indexPath.section]];
        if (@available(iOS 13.0, *)) {
            cell.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
        } else {
            // Fallback on earlier versions
            cell.backgroundColor = [UIColor whiteColor];
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Select row if its a "real" item, not a placeholder for "no widgets available"
    if ([self _itemCountForSection:indexPath.section] > 0) {
        // Get URL of selected cell.
        NSString *url = [self _itemForIndexPath:indexPath].absoluteUrl;
        
        // See: _handleSettingsButtonPressed, and implement as a method here too!
        // Set widgetURL, and delegate on whatever settings controller is used, since that
        // is used to end the picker flow
        
        // Fetch default metadata for this widget
        NSDictionary *defaultMetadata = [[XENHWidgetConfiguration defaultConfigurationForPath:url] serialise];
        
        UIViewController *settings = [XENHHomescreenForegroundViewController _widgetSettingsControllerWithURL:url currentMetadata:defaultMetadata showCancel:NO  andDelegate:self.delegate];
        [self.navigationController pushViewController:settings animated:YES];
        
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"BACK"]
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:nil
                                                                         action:nil];
        [[self navigationItem] setBackBarButtonItem:newBackButton];
        
        // Later on for editing an existing widget, make sure to strip off the :N as needed
        // before passing to the appropriate settings controller.
        // See XENHWidgetController's configureWithWidgetIndexFile:andMetadata:
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    // We can assume that if this is called, that the cell *definitely* doesn't have a screenshot.
    
    NSString *url = [self _itemForIndexPath:indexPath].absoluteUrl;
    
    // Segue to the previewer.
    
    XENHPickerPreviewController *preview = [[XENHPickerPreviewController alloc] initWithURL:url];
    preview.delegate = self.delegate;
    [self.navigationController pushViewController:preview animated:YES];
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"BACK"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:nil
                                                                     action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
    // Give a delegate to the previewer so it can call "go to settings" from its "Next" button
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self _nameForSection:section];
}

- (NSInteger)_itemCountForSection:(NSInteger)section {
    return section == 0 ? self.layerWidgets.count : self.universalWidgets.count;
}

- (XENHPickerItem*)_itemForIndexPath:(NSIndexPath*)indexPath {
    return indexPath.section == 0 ?
        [self.layerWidgets objectAtIndex:indexPath.item] :
        [self.universalWidgets objectAtIndex:indexPath.item];
}

- (NSString*)_nameForSection:(NSInteger)section {
    return section == 0 ? [XENHResources localisedStringForKey:@"WIDGETS_HOMESCREEN"] : [XENHResources localisedStringForKey:@"WIDGETS_UNIVERSAL"];
}

@end
