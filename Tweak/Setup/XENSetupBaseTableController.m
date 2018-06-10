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

#import "XENSetupBaseTableController.h"
#import "XENHResources.h"

@interface XENHSetupBaseTableController ()

@end

@implementation XENHSetupBaseTableController

#pragma mark Overridables

-(NSString*)headerTitle {
    return @"HEADER";
}

-(NSString*)cellReuseIdentifier {
    return @"setupCell";
}

-(NSInteger)rowsToDisplay {
    return 2;
}

-(UIImage*)footerImage {
    return [UIImage new];
}

-(NSString*)footerTitle {
    return @"FOOTER";
}

-(NSString*)footerBody {
    return @"Lorem ipsum";
}

-(NSString*)titleForCellAtIndex:(NSInteger)index {
    return @"CELL";
}

-(void)userDidSelectCellAtIndex:(NSInteger)index {
    // nop
}

-(void)userDidTapNextButton {
    
}

// This will either be the user selected cell, or whatever is currently checkmarked.
-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    return nil;
}

-(BOOL)shouldSegueToNewControllerAfterSelectingCell {
    if ([self shouldDisplayNextButton]) {
        return NO; // Next button handles the segue.
    }
    
    return YES;
}

-(BOOL)shouldCheckmarkAfterSelectingCell {
    if ([self shouldDisplayNextButton]) {
        return YES; // Next button handles the segue.
    }
    
    return NO;
}

-(BOOL)shouldDisplayNextButton {
    return NO;
}

#pragma mark Main code

-(instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _currentlyCheckmarkedCell = -1;
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.showsVerticalScrollIndicator = NO;
        self.tableView.scrollEnabled = NO;
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
    }
    
    return self;
}

-(UILabel*)headerView {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    label.text = [self headerTitle];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:34 weight:UIFontWeightLight];
    label.numberOfLines = 0;
    
    return label;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    if ([self shouldDisplayNextButton]) {
        // We need a "Next" bar item in the top right.
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:
                                                                    [XENHResources localisedStringForKey:@"NEXT"]
                                                                      style:UIBarButtonItemStyleDone
                                                                     target:self
                                                                     action:@selector(userDidTapNextButton:)];
        [newBackButton setEnabled:NO];
        [[self navigationItem] setRightBarButtonItem:newBackButton];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)userDidTapNextButton:(id)sender {
    //[self userDidSelectCellAtIndex:_currentlyCheckmarkedCell];
    [self userDidTapNextButton];
    
    UIViewController *controller = [self controllerToSegueForIndex:_currentlyCheckmarkedCell];
    
    if (controller)
        [[self navigationController] pushViewController:controller animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowsToDisplay];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (SCREEN_MAX_LENGTH < 667) {
        return 60.0;
    } else if (SCREEN_MAX_LENGTH < 568) {
        return 50.0;
    } else {
        return 70.0;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (SCREEN_MAX_LENGTH < 667) {
        return 75.0;
    } else if (SCREEN_MAX_LENGTH < 568) {
        return 50.0;
    } else {
        return 100.0;
    }
}

-(BOOL)tableView:(UITableView *)tableView shouldDrawTopSeparatorForSection:(NSInteger)section {
    return NO;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat height = 0.0;
    
    if (SCREEN_MAX_LENGTH < 568) {
        height = 50.0;
    } else if (SCREEN_MAX_LENGTH < 667) {
        height = 75.0;
    } else {
        height = 100.0;
    }
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, height)];
    UILabel *label = [self headerView];
    [label sizeToFit];
    
    [container addSubview:label];
    label.center = container.center;
    
    return container;
}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    CGFloat cellHeight = [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat headerHeight = [self tableView:tableView heightForHeaderInSection:0];
    CGFloat navHeight = 20.0 + self.navigationController.navigationBar.frame.size.height;
    
    CGFloat availableHeight = SCREEN_HEIGHT - navHeight - headerHeight - ([self rowsToDisplay] * cellHeight);
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, availableHeight)];
    
    // Image
   // NSString *filename = [NSString stringWithFormat:@"/Library/PreferenceBundles/Switch2.bundle/Gestures%@", [objc_getClass("UDLRResources") suffix]];
    //UIImage *image = [UIImage imageWithContentsOfFile:filename];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self footerImage]];
    imageView.backgroundColor = [UIColor clearColor];
    imageView.center = CGPointMake(container.frame.size.width/2, imageView.frame.size.height/2 + 40);
    
    [container addSubview:imageView];
    
    // Title
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, imageView.frame.size.height + imageView.frame.origin.y + (imageView.frame.size.height > 0 ? 20 : 0), self.view.frame.size.width*0.8, 22)];
    title.text = [self footerTitle];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = [UIColor blackColor];
    title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    
    [title sizeToFit];
    
    title.center = CGPointMake(container.frame.size.width/2, title.center.y);
    
    [container addSubview:title];
    
    // Explanation
    UILabel *explanation = [[UILabel alloc] initWithFrame:CGRectMake(0, title.frame.size.height + title.frame.origin.y + 10, self.view.frame.size.width*0.8, 100)];
    explanation.text = [self footerBody];
    explanation.textAlignment = NSTextAlignmentCenter;
    explanation.textColor = [UIColor blackColor];
    explanation.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    explanation.numberOfLines = 0;
    
    [explanation sizeToFit];
    
    explanation.center = CGPointMake(container.frame.size.width/2, explanation.center.y);
    
    [container addSubview:explanation];
    
    // We now know the heights of *everything*. Now, need to ensure it's all centered if there's less than 40px of space left.
    // Remove icon view if we're really tight on space.
    
    CGFloat remainingSpace = availableHeight - (explanation.frame.size.height + explanation.frame.origin.y);
    
    if (remainingSpace < 40) { // Margin left by icon.
        if (remainingSpace < -40) {
            // Will need to kill the icon!
            [imageView removeFromSuperview];
            
            CGFloat marginWithoutIcon = availableHeight - (title.frame.size.height + 10 + explanation.frame.size.height);
            marginWithoutIcon /= 2;
            
            if (marginWithoutIcon > 40) {
                marginWithoutIcon = 40;
            }
            
            title.frame = CGRectMake(title.frame.origin.x, marginWithoutIcon, title.frame.size.width, title.frame.size.height);
            explanation.frame = CGRectMake(explanation.frame.origin.x, title.frame.size.height + title.frame.origin.y + 10, explanation.frame.size.width, explanation.frame.size.height);
        } else {
            CGFloat margin = (40 + remainingSpace)/2;
            
            imageView.center = CGPointMake(container.frame.size.width/2, imageView.frame.size.height/2 + margin);
            title.frame = CGRectMake(title.frame.origin.x, imageView.frame.size.height + imageView.frame.origin.y + (imageView.frame.size.height > 0 ? 20 : 0), title.frame.size.width, title.frame.size.height);
            explanation.frame = CGRectMake(explanation.frame.origin.x, title.frame.size.height + title.frame.origin.y + 10, explanation.frame.size.width, explanation.frame.size.height);
        }
    }
    
    container.frame = CGRectMake(0, 0, self.view.frame.size.width, explanation.frame.size.height + explanation.frame.origin.y);
    
    return container;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self cellReuseIdentifier] forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[self cellReuseIdentifier]];
    }
    
    cell.textLabel.text = [self titleForCellAtIndex:indexPath.row];
    
    if ([self shouldSegueToNewControllerAfterSelectingCell]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == _currentlyCheckmarkedCell) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    cell.textLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self userDidSelectCellAtIndex:indexPath.row];
    
    if ([self shouldSegueToNewControllerAfterSelectingCell]) {
        UIViewController *controller = [self controllerToSegueForIndex:indexPath.row];
        
        if (controller)
            [[self navigationController] pushViewController:controller animated:YES];
    } else if ([self shouldCheckmarkAfterSelectingCell]) {
        _currentlyCheckmarkedCell = indexPath.row;
        [[self navigationItem].rightBarButtonItem setEnabled:YES];
        
        // Display checkmark on cell.
        int index = 0;
        for (UITableViewCell *cell in self.tableView.visibleCells) {
            if (index == (int)indexPath.row) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                break;
            }
            
            index++;
        }
    }
}

-(void)dealloc {
    
}

@end
