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

#import "XENHMultiplexWidgetsController.h"
#import "XENHPResources.h"

#define REUSE @"multiplexCell"

@interface XENHMultiplexWidgetsController ()

@end

@implementation XENHMultiplexWidgetsController

- (instancetype)initWithVariant:(XENHMultiplexVariant)variant {
    self = [super init];
    
    if (self) {
        self.headerView = [[XENHMultiplexWidgetsHeaderView alloc] initWithVariant:variant];
        self.variant = variant;
        
        // Load up data source from preferences.
        self.dataSource = [self _loadDataSource];
    }
    
    return self;
}

- (NSMutableArray*)_loadDataSource {
    NSString *key = @"";
    switch (self.variant) {
        case kMultiplexVariantLockscreenBackground:
            key = @"LSBackground";
            break;
        case kMultiplexVariantLockscreenForeground:
            key = @"LSForeground";
            break;
        case kMultiplexVariantHomescreenBackground:
            key = @"SBBackground";
            break;
            
        default:
            break;
    }
    
    NSDictionary *locationSettings = [[XENHResources getPreferenceKey:@"widgets"] objectForKey:key];
    NSArray *widgetArray = [locationSettings objectForKey:@"widgetArray"];
    
    if (!widgetArray) {
        widgetArray = [NSArray array];
    }
    
    return [widgetArray mutableCopy];
}

- (id)specifiers {
    return [NSArray array];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self navigationItem] setTitle:[XENHResources localisedStringForKey:@"WIDGETS_TITLE"]];
    
    [self.table reloadData];
}

-(void)loadView {
    [super loadView];
    
    [self.table registerClass:[UITableViewCell class] forCellReuseIdentifier:REUSE];
    self.table.allowsSelectionDuringEditing = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (int)tableViewStyle {
    return UITableViewStyleGrouped;
}

- (void)viewWillAppear:(BOOL)arg1 {
    [super viewWillAppear:arg1];
    
    [self.table setEditing:YES];
}

#pragma mark - Table view data source

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (id)tableView:(UITableView*)arg1 titleForFooterInSection:(NSInteger)arg2 {
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0)
        return self.dataSource.count > 0 ? self.dataSource.count : 1;
    else
        return 1; // Always want a cell for adding a new widget
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:REUSE];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE];
    }
    
    // Reset the cell
    if (@available(iOS 13.0, *)) {
        cell.textLabel.textColor = [UIColor labelColor];
    } else {
        cell.textLabel.textColor = [UIColor darkTextColor];
    }
    
    cell.showsReorderControl = NO;
    
    // Configure the cell...
    if (indexPath.section == 0) {
        
        // Handle when no widgets available if so required.
        if (indexPath.row == 0 && self.dataSource.count == 0) {
            
            if (@available(iOS 13.0, *)) {
                cell.textLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                cell.textLabel.textColor = [UIColor grayColor];
            }
            
            cell.textLabel.text = [XENHResources localisedStringForKey:@"WIDGETS_NONE_SELECTED"];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            // Alright, grab the name of the widget!
            
            NSString *widgetURL = [self.dataSource objectAtIndex:indexPath.row];
            
            NSString *filename = [[widgetURL stringByDeletingLastPathComponent] lastPathComponent];
            filename = [filename stringByReplacingOccurrencesOfString:@".theme" withString:@""];
            filename = [filename stringByReplacingOccurrencesOfString:@".cydget" withString:@""];
            
            cell.textLabel.text = filename;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell.showsReorderControl = YES;
        }
    } else {
        // Provide the button for adding a new widget
        cell.textLabel.text = [XENHResources localisedStringForKey:@"WIDGETS_ADD_NEW"];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        // Make it the system blue
        cell.textLabel.textColor = [UIApplication sharedApplication].keyWindow.tintColor;
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView*)arg1 heightForFooterInSection:(NSInteger)arg2 {
    return 0.0;
}

-(CGFloat)tableView:(UITableView*)arg1 heightForHeaderInSection:(NSInteger)arg2 {
    if (arg2 == 0) {
        CGFloat tableViewWidth = self.table.frame.size.width;
        CGFloat iconMargin = 20;
        CGFloat iconHeight = 40;
        CGFloat labelMargin = 10;
        UIFont *labelFont = [UIFont systemFontOfSize:16];
        
        NSString *labelText = @"";
        switch (self.variant) {
            case kMultiplexVariantLockscreenBackground:
                labelText = [XENHResources localisedStringForKey:@"WIDGETS_LSBACKGROUND_DETAIL"];
                break;
            case kMultiplexVariantLockscreenForeground:
                labelText = [XENHResources localisedStringForKey:@"WIDGETS_LSFOREGROUND_DETAIL"];
                break;
            case kMultiplexVariantHomescreenBackground:
                labelText = [XENHResources localisedStringForKey:@"WIDGETS_SBBACKGROUND_DETAIL"];
                break;
            default:
                break;
        }
        
        CGRect labelRect = [XENHResources boundedRectForFont:labelFont andText:labelText width:tableViewWidth - (labelMargin * 2.0)];
        
        return iconMargin + iconHeight + labelMargin + labelRect.size.height + iconMargin;
    } else {
        return UITableViewAutomaticDimension;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        // Launch widget picker UI.
        
        XENHPickerController *mc = [[XENHPickerController alloc] initWithVariant:(int)self.variant andDelegate:self andCurrentSelectedArray:self.dataSource];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mc];
        if (IS_IPAD) {
            navController.providesPresentationContextTransitionStyle = YES;
            navController.definesPresentationContext = YES;
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    } else if (indexPath.section == 0 && self.dataSource.count > 0) {
        // Allow editing of this widget
        NSString *widgetURL = [self.dataSource objectAtIndex:indexPath.row];
        
        XENHEditorViewController *editorController = [[XENHEditorViewController alloc] initWithVariant:self.variant widgetURL:widgetURL delegate:self isNewWidget:NO];
        [self.navigationController pushViewController:editorController animated:YES];

    }
}

- (id)tableView:(UITableView*)arg1 detailTextForHeaderInSection:(int)arg2 {
    return nil;
}

- (void)tableView:(UITableView*)arg1 didEndDisplayingCell:(id)arg2 forRowAtIndexPath:(id)arg3 {
    
}

- (int)tableView:(UITableView*)arg1 titleAlignmentForFooterInSection:(int)arg2 {
    return 0;
}
- (int)tableView:(UITableView*)arg1 titleAlignmentForHeaderInSection:(int)arg2 {
    return 0;
}

- (id)tableView:(UITableView*)arg1 viewForFooterInSection:(NSInteger)arg2 {
    return nil;
}

- (id)tableView:(UITableView*)arg1 viewForHeaderInSection:(NSInteger)arg2 {
    if (arg2 == 0) {
        return self.headerView;
    } else {
        return nil;
    }
}

////////////////////////////////////////////////////////////////////////////////////////
// Data source manipulation
////////////////////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    // Handle re-ordering of widgets!
    NSString *widgetToBeMoved = [self.dataSource objectAtIndex:sourceIndexPath.row];
    
    [self.dataSource removeObjectAtIndex:sourceIndexPath.row];
    [self.dataSource insertObject:widgetToBeMoved atIndex:destinationIndexPath.row];
    
    // Save changes, and notify the tweak of changes
    [self _saveWidgetArrayForCurrentVariant:self.dataSource];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 0 && self.dataSource.count > 1);
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    
    if (proposedDestinationIndexPath.section == 1) {
        return [NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0];
    } else {
        return proposedDestinationIndexPath;
    }
}

- (BOOL)tableView:(UITableView*)arg1 canEditRowAtIndexPath:(NSIndexPath*)arg2 {
    return (arg2.section == 0 && self.dataSource.count > 0) || arg2.section == 1;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && self.dataSource.count > 0) {
        return UITableViewCellEditingStyleDelete;
    } else if (indexPath.section == 1) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *toRemoveWidget = [self.dataSource objectAtIndex:indexPath.row];
        
        [self.dataSource removeObjectAtIndex:indexPath.row];
        
        if (self.dataSource.count == 0) {
            // XXX: is this needed to avoid crashing?
            [tableView reloadData];
        } else {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        // Save changes, and notify the tweak of changes
        // i.e., clear metadata and the widget URL
        [self _saveWidgetArrayForCurrentVariant:self.dataSource];
        [self _removeMetadataForWidgetURL:toRemoveWidget];
    }
}

#pragma mark Widget Picker delegate

-(void)didChooseWidget:(NSString *)filePath {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        // nop.
    }];
    
    // We don't animate to the editor for UX reasons.
    XENHEditorViewController *editorController = [[XENHEditorViewController alloc] initWithVariant:self.variant widgetURL:filePath delegate:self isNewWidget:YES];
    [self.navigationController pushViewController:editorController animated:NO];
}

-(void)cancelShowingPicker {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        // nop.
    }];
}

#pragma mark XENHEditorDelegate

- (NSString*)_preferencesKeyForCurrentVariant {
    NSString *key = @"";
    switch (self.variant) {
        case kMultiplexVariantLockscreenBackground:
            key = @"LSBackground";
            break;
        case kMultiplexVariantLockscreenForeground:
            key = @"LSForeground";
            break;
        case kMultiplexVariantHomescreenBackground:
            key = @"SBBackground";
            break;
            
        default:
            break;
    }
    
    return key;
}

- (void)_saveWidgetArrayForCurrentVariant:(NSArray*)widgetArray {
    NSString *key = [self _preferencesKeyForCurrentVariant];
    
    NSMutableDictionary *mutableSettings = [[XENHResources getPreferenceKey:@"widgets"] mutableCopy];
    if (!mutableSettings) {
        mutableSettings = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary *mutableLocationSettings = [[mutableSettings objectForKey:key] mutableCopy];
    if (!mutableLocationSettings)
        mutableLocationSettings = [NSMutableDictionary dictionary];
    
    [mutableLocationSettings setObject:widgetArray forKey:@"widgetArray"];
    
    // Save up.
    [mutableSettings setObject:mutableLocationSettings forKey:key];
    
    [XENHResources setPreferenceKey:@"widgets" withValue:mutableSettings];
}

- (void)_removeMetadataForWidgetURL:(NSString*)widgetURL {
    NSString *key = [self _preferencesKeyForCurrentVariant];
    
    // Load settings
    NSMutableDictionary *mutableSettings = [[XENHResources getPreferenceKey:@"widgets"] mutableCopy];
    if (!mutableSettings) {
        mutableSettings = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary *mutableLocationSettings = [[mutableSettings objectForKey:key] mutableCopy];
    if (!mutableLocationSettings)
        mutableLocationSettings = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *widgetMetadata = [[mutableLocationSettings objectForKey:@"widgetMetadata"] mutableCopy];
    if (!widgetMetadata) {
        widgetMetadata = [NSMutableDictionary dictionary];
    }
    
    // Update metadata dictionary
    [widgetMetadata removeObjectForKey:widgetURL];
    
    // Save out
    [mutableLocationSettings setObject:widgetMetadata forKey:@"widgetMetadata"];
    [mutableSettings setObject:mutableLocationSettings forKey:key];
    [XENHResources setPreferenceKey:@"widgets" withValue:mutableSettings];
}

- (void)_saveWidgetURL:(NSString*)widgetURL withMetadata:(NSDictionary*)metadata isNewWidget:(BOOL)isNewWidget {
    NSString *key = @"";
    switch (self.variant) {
        case kMultiplexVariantLockscreenBackground:
            key = @"LSBackground";
            break;
        case kMultiplexVariantLockscreenForeground:
            key = @"LSForeground";
            break;
        case kMultiplexVariantHomescreenBackground:
            key = @"SBBackground";
            break;
            
        default:
            break;
    }
    
    NSMutableDictionary *mutableSettings = [[XENHResources getPreferenceKey:@"widgets"] mutableCopy];
    if (!mutableSettings) {
        mutableSettings = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary *mutableLocationSettings = [[mutableSettings objectForKey:key] mutableCopy];
    if (!mutableLocationSettings)
        mutableLocationSettings = [NSMutableDictionary dictionary];
    
    // If this widget is already present in the widgetArray key, then just update the metadata.
    // Else, add the widget, then update the metadata.
    
    NSMutableArray *widgetArray = [[mutableLocationSettings objectForKey:@"widgetArray"] mutableCopy];
    if (!widgetArray) {
        widgetArray = [NSMutableArray array];
    }
    
    if (![widgetArray containsObject:widgetURL]) {
        [widgetArray addObject:widgetURL];
        [mutableLocationSettings setObject:widgetArray forKey:@"widgetArray"];
    } else if (isNewWidget) {
        // We have to handle multiple instances of the same widget now.
        // The idea is we count how many instances of the widget already exist, and update our prefix with that!
        
        int count = 0;
        
        for (NSString *location in widgetArray) {
            if ([location containsString:widgetURL] || [location isEqualToString:widgetURL])
                count++;
        }
        
        // Add a prefix to differentiate the widget
        NSString *widgetPrefix = [NSString stringWithFormat:@":%d", count];
        widgetURL = [NSString stringWithFormat:@"%@%@", widgetPrefix, widgetURL];
        
        // Save the widget
        [widgetArray addObject:widgetURL];
        [mutableLocationSettings setObject:widgetArray forKey:@"widgetArray"];
    }
    
    NSMutableDictionary *widgetMetadata = [[mutableLocationSettings objectForKey:@"widgetMetadata"] mutableCopy];
    if (!widgetMetadata) {
        widgetMetadata = [NSMutableDictionary dictionary];
    }
    
    [widgetMetadata setObject:metadata forKey:widgetURL];
    
    // Save up.
    [mutableLocationSettings setObject:widgetMetadata forKey:@"widgetMetadata"];
    [mutableSettings setObject:mutableLocationSettings forKey:key];
    
    [XENHResources setPreferenceKey:@"widgets" withValue:mutableSettings];
}

- (void)didAcceptChanges:(NSString*)widgetURL withMetadata:(NSDictionary*)metadata isNewWidget:(BOOL)isNewWidget {
    [self _saveWidgetURL:widgetURL withMetadata:metadata isNewWidget:isNewWidget];
    
    // Do any extra notifying.
    if (self.variant == kMultiplexVariantHomescreenBackground) {
        // Failsafe to reload SBHTML on metadata-only changes.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.matchstic.xenhtml/sbconfigchanged" object:nil];
        
        CFStringRef toPost = (__bridge CFStringRef)@"com.matchstic.xenhtml/sbconfigchanged";
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
    
    // Reload the data source and table view for any new changes to the widget listing.
    self.dataSource = [self _loadDataSource];
    [self.table reloadData];
}

@end
