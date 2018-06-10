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
#import "XENHResources.h"

#define REUSE @"picker2"

@interface XENHPickerController2 ()

@end

@implementation XENHPickerController2

-(id)initWithVariant:(int)variant andDelegate:(id<XENHPickerDelegate2>)delegate andCurrentSelectedArray:(NSArray*)currentArray {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        _variant = variant; // 0 = ls bg/fg, 1 = ls widgets, 2 = SBHTML
        _delegate = delegate;
        
        _currentSelected = currentArray;
        
        // Load all arrays for widgets based on variant
        
        if (_variant == 2) {
            // SBHTML array.
            [self _setupSBHTMLArray];
            
            // iWidgets now
            [self _setupiWidgetsArray];
        } else {
            // iWidgets
            [self _setupiWidgetsArray];
            
            // LockHTML
            [self _setupLockHTMLArray];
            
            // GroovyLock.
            [self _setupGroovyLockArray];
            
            if ([self _shouldDisplayCydget]) {
                // Cydget (foreground)
                [self _setupCydgetForegroundArray];
                
                // Cydget (background)
                [self _setupCydgetBackgroundArray];
            }
        }
    }
    
    return self;
}

-(id)initWithVariant:(int)variant andDelegate:(id<XENHPickerDelegate2>)delegate andCurrentSelected:(NSString *)current {
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

- (NSMutableArray*)_orderAlphabetically:(NSMutableArray*)array {
    return [[array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
}

- (void)_setupSBHTMLArray {
    NSMutableArray *sbhtml = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/SBHTML/" error:nil] mutableCopy];
    
    // Order the array alphabetically.
    sbhtml = [self _orderAlphabetically:sbhtml];
    
    for (NSString *thing in sbhtml.copy) {
        int index = (int)[sbhtml indexOfObject:thing];
        NSString *absoluteURL = [NSString stringWithFormat:@"/var/mobile/Library/SBHTML/%@/Wallpaper.html", thing];
        [sbhtml replaceObjectAtIndex:index withObject:absoluteURL];
    }
    
    _sbhtmlArray = sbhtml;
}

- (void)_setupiWidgetsArray {
    NSMutableArray *widgets = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/iWidgets/" error:nil] mutableCopy];
    
    // Order the array alphabetically.
    widgets = [self _orderAlphabetically:widgets];
    
    for (NSString *thing in widgets.copy) {
        int index = (int)[widgets indexOfObject:thing];
        NSString *absoluteURL = [NSString stringWithFormat:@"/var/mobile/Library/iWidgets/%@/Widget.html", thing];
        [widgets replaceObjectAtIndex:index withObject:absoluteURL];
    }
    
    _iwidgetsArray = widgets;
}

- (void)_setupLockHTMLArray {
    NSMutableArray *lockhtml = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/LockHTML/" error:nil] mutableCopy];
    
    // Now, we order the array alphabetically.
    lockhtml = [self _orderAlphabetically:lockhtml];
    
    for (NSString *thing in lockhtml.copy) {
        if ([thing isEqualToString:@"LockHTML"]) {
            // What the actual...?
            [lockhtml removeObject:thing];
        }
        
        int index = (int)[lockhtml indexOfObject:thing];
        
        // Might be a weird one?
        
        NSMutableString *absoluteURL = [[NSString stringWithFormat:@"/var/mobile/Library/LockHTML/%@/", thing] mutableCopy];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@index.html", absoluteURL]]) {
            [absoluteURL appendString:@"index.html"];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@LockBackground.html", absoluteURL]]) {
            [absoluteURL appendString:@"LockBackground.html"];
        } else {
            [lockhtml removeObject:thing];
            continue;
        }
        
        [lockhtml replaceObjectAtIndex:index withObject:absoluteURL];
    }
    
    _lockHTMLArray = lockhtml;
}

- (void)_setupGroovyLockArray {
    NSMutableArray *groovylock = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/GroovyLock/" error:nil] mutableCopy];
    
    // Order the array alphabetically.
    groovylock = [self _orderAlphabetically:groovylock];
    
    for (NSString *thing in groovylock.copy) {
        if ([thing isEqualToString:@"GroovyLock"]) {
            // What the actual...?
            [groovylock removeObject:thing];
        }
        
        int index = (int)[groovylock indexOfObject:thing];
        
        // Might be a weird one.
        
        NSMutableString *absoluteURL = [[NSString stringWithFormat:@"/var/mobile/Library/GroovyLock/%@/", thing] mutableCopy];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@index.html", absoluteURL]]) {
            [absoluteURL appendString:@"index.html"];
        } else if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@LockBackground.html", absoluteURL]]) {
            [absoluteURL appendString:@"LockBackground.html"];
        } else {
            [groovylock removeObject:thing];
            continue;
        }
        
        [groovylock replaceObjectAtIndex:index withObject:absoluteURL];
    }
    
    _groovylockArray = groovylock;
}

- (void)_setupCydgetForegroundArray {
    NSMutableArray *cydgetFore = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/System/Library/LockCydgets/" error:nil] mutableCopy];
    
    // Order the array alphabetically.
    cydgetFore = [self _orderAlphabetically:cydgetFore];
    
    for (NSString *thing in cydgetFore.copy) {
        int index = (int)[cydgetFore indexOfObject:thing];
        
        // Read plist.
        NSString *plistPath = [NSString stringWithFormat:@"/System/Library/LockCydgets/%@/Info.plist", thing];
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        NSDictionary *cyConfiguration = [plist objectForKey:@"CYConfiguration"];
        
        NSString *base = [[cyConfiguration objectForKey:@"Homepage"] lastPathComponent];
        NSString *absolute = [NSString stringWithFormat:@"/System/Library/LockCydgets/%@/%@", thing, base];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:absolute]) {
            [cydgetFore removeObject:thing];
        } else {
            [cydgetFore replaceObjectAtIndex:index withObject:absolute];
        }
    }
    
    _cydgetForegroundArray = cydgetFore;
}

- (void)_setupCydgetBackgroundArray {
    NSMutableArray *cydgetBack = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/System/Library/LockCydgets/" error:nil] mutableCopy];
    
    // Order the array alphabetically.
    cydgetBack = [self _orderAlphabetically:cydgetBack];
    
    for (NSString *thing in cydgetBack.copy) {
        
        int index = (int)[cydgetBack indexOfObject:thing];
        
        // Read plist.
        NSString *plistPath = [NSString stringWithFormat:@"/System/Library/LockCydgets/%@/Info.plist", thing];
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        NSDictionary *cyConfiguration = [plist objectForKey:@"CYConfiguration"];
        
        NSString *base = [[cyConfiguration objectForKey:@"Background"] lastPathComponent];
        NSString *absolute = [NSString stringWithFormat:@"/System/Library/LockCydgets/%@/%@", thing, base];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:absolute]) {
            [cydgetBack removeObject:thing];
        } else {
            [cydgetBack replaceObjectAtIndex:index withObject:absolute];
        }
    }
    
    _cydgetBackgroundArray = cydgetBack;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self _shouldDisplayCydget]) {
         return _variant == 0 ? 5 : 2;
    } else {
         return _variant == 0 ? 3 : 2;
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
            cell.backgroundColor = [UIColor whiteColor];
        }
    } else {
        // There's no items in this section, so state it!
        [cell setupForNoWidgetsWithWidgetType:[self _nameForSection:indexPath.section]];
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Select row if its a "real" item, not a placeholder for "no widgets available"
    if ([self _itemCountForSection:indexPath.section] > 0) {
        // Get URL of selected cell.
        NSString *url = [self _urlForIndexPath:indexPath];
        
        // ~Only allow a single instance of a widget per layer~
        // We now allow multiple instance of the same widget per layer.
        //if (![_currentSelected containsObject:url])
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
    switch (_variant) {
        case 2:
            switch (section) {
                case 0:
                    return _sbhtmlArray.count;
                case 1:
                    return _iwidgetsArray.count;
                    
                default:
                    return 0;
            }
            
        case 0:
            switch (section) {
                case 0:
                    return _lockHTMLArray.count;
                case 1:
                    return _groovylockArray.count;
                case 2:
                    return _iwidgetsArray.count;
                case 3:
                    return _cydgetForegroundArray.count;
                case 4:
                    return _cydgetBackgroundArray.count;
                    
                default:
                    return 0;
            }
            
        default:
            return 0;
    }
}

- (NSString*)_urlForIndexPath:(NSIndexPath*)indexPath {
    NSString *url = @"";
    switch (_variant) {
        case 2:
            switch (indexPath.section) {
                case 0:
                    url = [_sbhtmlArray objectAtIndex:indexPath.item];
                    break;
                case 1:
                    url = [_iwidgetsArray objectAtIndex:indexPath.item];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 0:
            switch (indexPath.section) {
                case 0:
                    url = [_lockHTMLArray objectAtIndex:indexPath.item];
                    break;
                case 1:
                    url = [_groovylockArray objectAtIndex:indexPath.item];
                    break;
                case 2:
                    url = [_iwidgetsArray objectAtIndex:indexPath.item];
                    break;
                case 3:
                    url = [_cydgetForegroundArray objectAtIndex:indexPath.item];
                    break;
                case 4:
                    url = [_cydgetBackgroundArray objectAtIndex:indexPath.item];
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
    switch (_variant) {
        case 2:
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
            
        case 0:
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
