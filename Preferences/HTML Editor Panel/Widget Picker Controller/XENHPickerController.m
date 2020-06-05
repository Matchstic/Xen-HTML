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
#import "XENHPickerController.h"
#import "XENHPickerPreviewController.h"
#import "XENHPickerCell.h"
#import "XENHPResources.h"
#import "XENHPickerItem.h"

#define REUSE @"picker2"

@interface XENHPickerController ()

@end

@implementation XENHPickerController

-(id)initWithVariant:(XENHPickerVariant)variant andDelegate:(id<XENHPickerDelegate2>)delegate andCurrentSelectedArray:(NSArray*)currentArray {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.variant = variant;
        self.delegate = delegate;
        
        self.currentSelected = currentArray;
        
        [self loadLayerWidgets];
        [self loadUniversalWidgets];
        [self loadBackgroundWidgets];
    }
    
    return self;
}

-(id)initWithVariant:(XENHPickerVariant)variant andDelegate:(id<XENHPickerDelegate2>)delegate andCurrentSelected:(NSString *)current {
    return [self initWithVariant:variant andDelegate:delegate andCurrentSelectedArray:@[current]];
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
    [_delegate cancelShowingPicker];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // Configure table view's cell class.
    [self.tableView registerClass:[XENHPickerCell class] forCellReuseIdentifier:REUSE];
}

- (NSArray*)_orderAlphabetically:(NSArray*)array {
    return [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        XENHPickerItem *leftItem = (XENHPickerItem*)obj1;
        XENHPickerItem *rightItem = (XENHPickerItem*)obj2;
        
        return [leftItem.name caseInsensitiveCompare:rightItem.name];
    }];
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

- (void)loadUniversalWidgets {
    NSMutableArray *results = [NSMutableArray array];
    
    // Universal
    {
        [results addObjectsFromArray:[self widgetsFromPath:@"/var/mobile/Library/Widgets/Universal"]];
    }
    
    // iWidgets
    {
        NSArray *widgets = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/iWidgets/" error:nil];
        
        for (NSString *result in widgets) {
            NSMutableString *absoluteURL = [[NSString stringWithFormat:@"/var/mobile/Library/iWidgets/%@/", result] mutableCopy];
            
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

- (void)loadBackgroundWidgets {
    BOOL allowBackgrounds = self.variant == kPickerVariantHomescreenBackground || self.variant == kPickerVariantLockscreenBackground;
    if (!allowBackgrounds) return;
    
    NSMutableArray *results = [NSMutableArray array];
    
    // Backgrounds
    {
        [results addObjectsFromArray:[self widgetsFromPath:@"/var/mobile/Library/Widgets/Backgrounds"]];
    }
    
    // Cydget backgrounds, if allowed for backwards compatibility reasons
    if ([self _shouldDisplayCydget]) {
        NSArray *cydget = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/System/Library/LockCydgets/" error:nil];
        
        for (NSString *entry in cydget) {
            // Read plist.
            NSString *plistPath = [NSString stringWithFormat:@"/System/Library/LockCydgets/%@/Info.plist", entry];
            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            NSDictionary *cyConfiguration = [plist objectForKey:@"CYConfiguration"];
            
            // And also background
            NSString *backgroundBase = [[cyConfiguration objectForKey:@"Background"] lastPathComponent];
            NSString *backgroundAbsolute = [NSString stringWithFormat:@"/System/Library/LockCydgets/%@/%@", entry, backgroundBase];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:backgroundAbsolute]) {
                XENHPickerItem *item = [[XENHPickerItem alloc] init];
                item.absoluteUrl = backgroundAbsolute;
                item.name = [NSString stringWithFormat:@"Background | %@", entry];
                
                [results addObject:item];
            }
        }
    }
    
    self.backgroundWidgets = [self _orderAlphabetically:results];
}

- (void)loadLayerWidgets {

    BOOL isLockscreen = self.variant == kPickerVariantLockscreenBackground || self.variant == kPickerVariantLockscreenForeground;
    
    NSMutableArray *results = [NSMutableArray array];
    
    // Layer-specific widgets
    {
        if (isLockscreen)
            [results addObjectsFromArray:[self widgetsFromPath:@"/var/mobile/Library/Widgets/Lockscreen"]];
        else
            [results addObjectsFromArray:[self widgetsFromPath:@"/var/mobile/Library/Widgets/Homescreen"]];
    }
    
    // Legacy folders
    if (isLockscreen) {
        [results addObjectsFromArray:[self legacyLockscreenResults]];
    } else {
        [results addObjectsFromArray:[self legacyHomescreenResults]];
    }
    
    self.layerWidgets = [self _orderAlphabetically:results];
}

- (NSArray*)legacyLockscreenResults {
    NSMutableArray *result = [NSMutableArray array];
    
    // LockHTML
    {
        NSArray *lockhtml = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/LockHTML/" error:nil];
         
         for (NSString *thing in lockhtml) {
             if ([thing isEqualToString:@"LockHTML"]) continue;
             
             NSMutableString *absoluteURL = [[NSString stringWithFormat:@"/var/mobile/Library/LockHTML/%@/", thing] mutableCopy];
             if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@index.html", absoluteURL]]) {
                 [absoluteURL appendString:@"index.html"];
             } else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@LockBackground.html", absoluteURL]]) {
                 [absoluteURL appendString:@"LockBackground.html"];
             } else {
                 continue;
             }
             
             XENHPickerItem *item = [[XENHPickerItem alloc] init];
             item.absoluteUrl = absoluteURL;
             item.name = thing;
             
             [result addObject:item];
         }
    }
    
    // GroovyLock
    {
        NSArray *groovylock = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/GroovyLock/" error:nil];
        
        for (NSString *thing in groovylock) {
            if ([thing isEqualToString:@"GroovyLock"]) continue;
            
            NSMutableString *absoluteURL = [[NSString stringWithFormat:@"/var/mobile/Library/GroovyLock/%@/", thing] mutableCopy];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@index.html", absoluteURL]]) {
                [absoluteURL appendString:@"index.html"];
            } else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@LockBackground.html", absoluteURL]]) {
                [absoluteURL appendString:@"LockBackground.html"];
            } else {
                continue;
            }
            
            XENHPickerItem *item = [[XENHPickerItem alloc] init];
            item.absoluteUrl = absoluteURL;
            item.name = thing;
            
            [result addObject:item];
        }
    }
    
    // Cydget, if allowed
    if ([self _shouldDisplayCydget]) {
        NSArray *cydget = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/System/Library/LockCydgets/" error:nil];
        
        for (NSString *entry in cydget) {
            // Read plist.
            NSString *plistPath = [NSString stringWithFormat:@"/System/Library/LockCydgets/%@/Info.plist", entry];
            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            NSDictionary *cyConfiguration = [plist objectForKey:@"CYConfiguration"];
            
            // Handle Foreground first
            NSString *foregroundBase = [[cyConfiguration objectForKey:@"Homepage"] lastPathComponent];
            NSString *foregroundAbsolute = [NSString stringWithFormat:@"/System/Library/LockCydgets/%@/%@", entry, foregroundBase];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:foregroundAbsolute]) {
                XENHPickerItem *item = [[XENHPickerItem alloc] init];
                item.absoluteUrl = foregroundAbsolute;
                item.name = [NSString stringWithFormat:@"Foreground | %@", entry];
                
                [result addObject:item];
            }
        }
    }
    
    return result;
}

- (NSArray*)legacyHomescreenResults {
    NSMutableArray *result = [NSMutableArray array];
    
    // SBHTML
    {
        NSArray *sbhtml = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/SBHTML/" error:nil];
        
        for (NSString *thing in sbhtml) {
            
            NSMutableString *absoluteURL = [[NSString stringWithFormat:@"/var/mobile/Library/SBHTML/%@/", thing] mutableCopy];
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
            
            [result addObject:item];
        }
    }
    
    return result;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    BOOL allowBackgrounds = self.variant == kPickerVariantHomescreenBackground || self.variant == kPickerVariantLockscreenBackground;
    return allowBackgrounds ? 3 : 2;
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
    XENHPickerItem *item = [self _itemForIndexPath:indexPath];
    
    // Only doing this here for backwards compatibility purposes
    NSString *thing = [item.absoluteUrl stringByDeletingLastPathComponent];
    thing = [thing stringByAppendingString:@"/Screenshot.png"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:thing]) {
        thing = nil;
    }
    
    return thing != nil ? 100.0 : 80.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XENHPickerCell *cell = (XENHPickerCell*)[tableView dequeueReusableCellWithIdentifier:REUSE forIndexPath:indexPath];
    if (!cell) {
        cell = [[XENHPickerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE];
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
        
        [_delegate didChooseWidget:url];
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    // We can assume that if this is called, that the cell *definitely* doesn't have a screenshot.
    
    NSString *url = [self _itemForIndexPath:indexPath].absoluteUrl;
    
    // Segue to the previewer.
    
    XENHPickerPreviewController *preview = [[XENHPickerPreviewController alloc] initWithURL:url];
    [self.navigationController pushViewController:preview animated:YES];
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:[XENHResources localisedStringForKey:@"BACK"]
                                                                    style:UIBarButtonItemStylePlain
                                                                     target:nil
                                                                     action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self _nameForSection:section];
}

- (BOOL)_shouldDisplayCydget {
    return [UIDevice currentDevice].systemVersion.floatValue < 10.0;
}

- (NSInteger)_itemCountForSection:(NSInteger)section {
    switch (section) {
        case 0:
            return self.layerWidgets.count;
        case 1:
            return self.universalWidgets.count;
        case 2:
            return self.backgroundWidgets.count;
            
        default:
            return 0;
    }
}

- (XENHPickerItem*)_itemForIndexPath:(NSIndexPath*)indexPath {
    switch (indexPath.section) {
        case 0:
            return [self.layerWidgets objectAtIndex:indexPath.item];
        case 1:
            return [self.universalWidgets objectAtIndex:indexPath.item];
        case 2:
            return [self.backgroundWidgets objectAtIndex:indexPath.item];
        default:
            return nil;
    }
}

- (NSString*)_nameForSection:(NSInteger)section {
    BOOL isLockscreen = self.variant == kPickerVariantLockscreenBackground || self.variant == kPickerVariantLockscreenForeground;
    
    switch (section) {
        case 0:
            return isLockscreen ? [XENHResources localisedStringForKey:@"WIDGETS_LOCKSCREEN"] : [XENHResources localisedStringForKey:@"WIDGETS_HOMESCREEN"];
        case 1:
            return [XENHResources localisedStringForKey:@"WIDGETS_UNIVERSAL"];
        case 2:
            return [XENHResources localisedStringForKey:@"WIDGETS_BACKGROUND_PICKER"];
        default:
            return @"";
    }
}


@end
