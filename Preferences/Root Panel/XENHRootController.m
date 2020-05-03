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

#import "XENHRootController.h"
#import "XENHPResources.h"
#import "XENHPHeaderView.h"

@interface XENHRootController ()

@end

@implementation XENHRootController

- (NSString*)plistName {
    return @"Root";
}

-(void)viewWillAppear:(BOOL)view {
    [super viewWillAppear:view];
    
    if (!self.table.tableHeaderView) {
        // Add header view.
        XENHPHeaderView *view = [[XENHPHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 160)];
        [self.table setTableHeaderView:view];
        
        [self.table insertSubview:view atIndex:0];
    }
    
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:@""];
    }
    
    // Add share button.
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareTweak:)]];
    
    [super viewWillAppear:view];
}

-(void)shareTweak:(UIBarButtonItem*)item {
    NSString *message = [XENHResources localisedStringForKey:@"ROOT_SHARE_TEXT"];
    NSURL *url = [NSURL URLWithString:@"https://cydia.saurik.com/api/share#?source=https://xenpublic.incendo.ws/&package=com.matchstic.xenhtml"];
    
    UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:@[message, url] applicationActivities:nil];
    viewController.popoverPresentationController.barButtonItem = item;
    [self.parentController presentViewController:viewController animated:YES completion:nil];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0 || indexPath.section == 1) {
        cell.imageView.image = [cell.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.imageView.tintColor = [[UIApplication sharedApplication] keyWindow].tintColor;
    }
    
    return cell;
}

-(CGFloat)tableView:(id)view heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    switch (indexPath.section) {
        case 0:
        case 1:
            return 150;
            break;
            
        default:
            return [super tableView:view heightForRowAtIndexPath:indexPath];
            break;
    }
}

@end
