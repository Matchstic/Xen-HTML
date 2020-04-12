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
#import "XENHPickerController2.h"
#import "XENHPickerPreviewController2.h"
#import "XENHPickerCell2.h"
#import "XENHPResources.h"
#import "XENHPickerItem.h"

#define REUSE @"picker2"

@interface XENHPickerController2 ()

@end

@implementation XENHPickerController2

-(id)initWithVariant:(XENHPickerVariant)variant andDelegate:(id<XENHPickerDelegate2>)delegate andCurrentSelectedArray:(NSArray*)currentArray {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.variant = variant;
        self.delegate = delegate;
        
        self.currentSelected = currentArray;
        
        [self loadLegacyWidgets];
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
    [self.tableView registerClass:[XENHPickerCell2 class] forCellReuseIdentifier:REUSE];
}

- (NSArray*)_orderAlphabetically:(NSArray*)array {
    return [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (void)loadLegacyWidgets {
    // SBHTML
    if (self.variant == kPickerVariantHomescreenBackground ||
        self.variant == kPickerVariantHomescreenForeground) {
        NSMutableArray *result = [NSMutableArray array];
        
        NSArray *sbhtml = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/SBHTML/" error:nil];
        sbhtml = [self _orderAlphabetically:sbhtml];
        
        for (NSString *thing in sbhtml) {
            NSString *absoluteURL = [NSString stringWithFormat:@"/var/mobile/Library/SBHTML/%@/Wallpaper.html", thing];
            
            XENHPickerItem *item = [[XENHPickerItem alloc] init];
            item.absoluteUrl = absoluteURL;
            item.name = thing;
            
            [result addObject:item];
        }
        
        self.sbhtmlArray = result;
    }
    
    // iWidgets
    {
        NSMutableArray *result = [NSMutableArray array];
        
        NSArray *iwidgets = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/iWidgets/" error:nil];
        iwidgets = [self _orderAlphabetically:iwidgets];
        
        for (NSString *thing in iwidgets) {
            NSString *absoluteURL = [NSString stringWithFormat:@"/var/mobile/Library/iWidgets/%@/Widget.html", thing];
            
            XENHPickerItem *item = [[XENHPickerItem alloc] init];
            item.absoluteUrl = absoluteURL;
            item.name = thing;
            
            [result addObject:item];
        }
        
        self.iwidgetsArray = result;
    }
    
    // LockHTML
    if (self.variant == kPickerVariantLockscreenBackground || self.variant == kPickerVariantLockscreenForeground) {
        NSMutableArray *result = [NSMutableArray array];
        
        NSArray *lockhtml = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/LockHTML/" error:nil];
        lockhtml = [self _orderAlphabetically:lockhtml];
         
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
        
        self.lockHTMLArray = result;
    }
    
    // GroovyLock
    if (self.variant == kPickerVariantLockscreenBackground || self.variant == kPickerVariantLockscreenForeground) {
        NSMutableArray *result = [NSMutableArray array];
        
        NSArray *groovylock = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/GroovyLock/" error:nil];
        groovylock = [self _orderAlphabetically:groovylock];
        
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
        
        self.groovylockArray = result;
    }
    
    if ([self _shouldDisplayCydget]) {
        NSMutableArray *resultFg = [NSMutableArray array];
        NSMutableArray *resultBg = [NSMutableArray array];
        
        NSArray *cydget = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/System/Library/LockCydgets/" error:nil];
        cydget = [self _orderAlphabetically:cydget];
        
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
                
                [resultFg addObject:item];
            }
            
            // And also background
            NSString *backgroundBase = [[cyConfiguration objectForKey:@"Background"] lastPathComponent];
            NSString *backgroundAbsolute = [NSString stringWithFormat:@"/System/Library/LockCydgets/%@/%@", entry, backgroundBase];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:backgroundAbsolute]) {
                XENHPickerItem *item = [[XENHPickerItem alloc] init];
                item.absoluteUrl = backgroundAbsolute;
                item.name = [NSString stringWithFormat:@"Background | %@", entry];
                
                [resultBg addObject:item];
            }
        }
        
        self.cydgetBackgroundArray = resultBg;
        self.cydgetForegroundArray = resultFg;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self _shouldDisplayCydget]) {
         return self.variant == kPickerVariantHomescreenBackground ? 2 : 5;
    } else {
         return self.variant == kPickerVariantHomescreenBackground ? 2 : 3;
    }
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
    NSString *url = [self _urlForIndexPath:indexPath];
    
    NSString *thing = [url stringByDeletingLastPathComponent];
    thing = [thing stringByAppendingString:@"/Screenshot.png"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:thing]) {
        thing = nil;
    }
    
    return thing != nil ? 100.0 : 80.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XENHPickerCell2 *cell = (XENHPickerCell2*)[tableView dequeueReusableCellWithIdentifier:REUSE forIndexPath:indexPath];
    if (!cell) {
        cell = [[XENHPickerCell2 alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE];
    }
    
    // Configure the cell...
    if ([self _itemCountForSection:indexPath.section] > 0) {
        NSString *url = [self _urlForIndexPath:indexPath];
        
        NSString *thing = [url stringByDeletingLastPathComponent];
        thing = [thing stringByAppendingString:@"/Screenshot.png"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:thing]) {
            thing = nil;
        }
        
        [cell setupWithFilename:url screenshotFilename:thing andAssociatedUrl:url];
        
        // Based off the variant, we will also check to see if this cell is currently enabled. If so, we will colour it
        // a light green.
        
        if ([_currentSelected containsObject:url]) {
            cell.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:1.0 blue:238.0/255.0 alpha:1.0];
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
        NSString *url = [self _urlForIndexPath:indexPath];
        
        [_delegate didChooseWidget:url];
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    // We can assume that if this is called, that the cell *definitely* doesn't have a screenshot.
    
    NSString *url = [self _urlForIndexPath:indexPath];
    
    // Segue to the previewer.
    
    XENHPickerPreviewController2 *preview = [[XENHPickerPreviewController2 alloc] initWithURL:url];
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
    switch (self.variant) {
        case kPickerVariantHomescreenBackground:
            switch (section) {
                case 0:
                    return self.sbhtmlArray.count;
                case 1:
                    return self.iwidgetsArray.count;
                    
                default:
                    return 0;
            }
            
        case kPickerVariantLockscreenForeground:
        case kPickerVariantLockscreenBackground:
            switch (section) {
                case 0:
                    return self.lockHTMLArray.count;
                case 1:
                    return self.groovylockArray.count;
                case 2:
                    return self.iwidgetsArray.count;
                case 3:
                    return self.cydgetForegroundArray.count;
                case 4:
                    return self.cydgetBackgroundArray.count;
                    
                default:
                    return 0;
            }
            
        default:
            return 0;
    }
}

- (NSString*)_urlForIndexPath:(NSIndexPath*)indexPath {
    NSString *url = @"";
    
    switch (self.variant) {
        case kPickerVariantHomescreenBackground:
            switch (indexPath.section) {
                case 0:
                    url = [[self.sbhtmlArray objectAtIndex:indexPath.item] absoluteUrl];
                case 1:
                    url = [[self.iwidgetsArray objectAtIndex:indexPath.item] absoluteUrl];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case kPickerVariantLockscreenForeground:
        case kPickerVariantLockscreenBackground:
            switch (indexPath.section) {
                case 0:
                    url = [[self.lockHTMLArray objectAtIndex:indexPath.item] absoluteUrl];
                    break;
                case 1:
                    url = [[self.groovylockArray objectAtIndex:indexPath.item] absoluteUrl];
                    break;
                case 2:
                    url = [[self.iwidgetsArray objectAtIndex:indexPath.item] absoluteUrl];
                    break;
                case 3:
                    url = [[self.cydgetForegroundArray objectAtIndex:indexPath.item] absoluteUrl];
                    break;
                case 4:
                    url = [[self.cydgetBackgroundArray objectAtIndex:indexPath.item] absoluteUrl];
                    break;
                    
                default:
                    break;
            }
        default:
            break;
    }
    
    return url;
}

- (NSString*)_nameForSection:(NSInteger)section {
    NSString *name = @"";
    switch (self.variant) {
        case kPickerVariantHomescreenBackground:
            switch (section) {
                case 0:
                    name = @"SBHTML";
                    break;
                case 1:
                    name = @"iWidgets";
                    break;
                    
                default:
                    break;
            }
            break;
            
        case kPickerVariantLockscreenForeground:
        case kPickerVariantLockscreenBackground:
            switch (section) {
                case 0:
                    name = @"Lock HTML";
                    break;
                case 1:
                    name = @"GroovyLock";
                    break;
                case 2:
                    name = @"iWidgets";
                    break;
                case 3:
                    name = [XENHResources localisedStringForKey:@"WIDGET_PICKER_CYDGET_FOREGROUND"];
                    break;
                case 4:
                    name = [XENHResources localisedStringForKey:@"WIDGET_PICKER_CYDGET_BACKGROUND"];
                    break;
                    
                default:
                    break;
            }
        default:
            break;
    }
    
    return name;
}


@end
