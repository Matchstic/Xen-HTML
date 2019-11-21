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

@property (nonatomic, strong) UIView *headerContainer;
@property (nonatomic, strong) UILabel *headerLabel;

@property (nonatomic, strong) UIView *footerContainer;
@property (nonatomic, strong) UIImageView *footerImageView;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) UILabel *footerExplanation;


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
    if (!self.headerLabel) {
        self.headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.headerLabel.text = [self headerTitle];
        self.headerLabel.textAlignment = NSTextAlignmentCenter;
        if (@available(iOS 13.0, *)) {
            self.headerLabel.textColor = [UIColor labelColor];
        } else {
            self.headerLabel.textColor = [UIColor blackColor];
        }
        self.headerLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightLight];
        self.headerLabel.numberOfLines = 0;
    }
    
    return self.headerLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    } else {
        // Fallback on earlier versions
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self _layoutHeaderViews];
    [self _layoutFooterViews];
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
    if (self.view.frame.size.height < 568) {
        return 50.0;
    } else if (self.view.frame.size.height < 667) {
        return 60.0;
    } else {
        return 70.0;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.view.frame.size.height < 568) {
        return 50.0;
    } else if (self.view.frame.size.height < 667) {
        return 75.0;
    } else {
        return 100.0;
    }
}

-(BOOL)tableView:(UITableView *)tableView shouldDrawTopSeparatorForSection:(NSInteger)section {
    return NO;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (!self.headerContainer) {
        self.headerContainer = [[UIView alloc] initWithFrame:CGRectZero];
        UILabel *label = [self headerView];
        
        [self.headerContainer addSubview:label];
    }
    
    [self _layoutHeaderViews];
    
    return self.headerContainer;
}

- (void)_layoutHeaderViews {
    CGFloat height = [self tableView:self.tableView heightForHeaderInSection:0];
    
    self.headerContainer.frame = CGRectMake(self.headerContainer.frame.origin.x, self.headerContainer.frame.origin.y, self.view.frame.size.width, height);
    self.headerLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 50);
    [self.headerLabel sizeToFit];
    
    self.headerLabel.center = self.headerContainer.center;
}

- (void)_layoutFooterViews {
    // Calculate initial heights
    CGFloat cellHeight = [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat headerHeight = [self tableView:self.tableView heightForHeaderInSection:0];
    CGFloat navHeight = 20.0 + self.navigationController.navigationBar.frame.size.height;
    
    CGFloat availableHeight = self.view.frame.size.height - navHeight - headerHeight - ([self rowsToDisplay] * cellHeight);
    
    self.footerContainer.frame = CGRectMake(self.footerContainer.frame.origin.x, self.footerContainer.frame.origin.y, self.view.frame.size.width, availableHeight);
    self.footerImageView.center = CGPointMake(self.footerContainer.frame.size.width/2, self.footerImageView.frame.size.height/2 + 40);
    
    self.footerLabel.frame = CGRectMake(0, self.footerImageView.frame.size.height + self.footerImageView.frame.origin.y + (self.footerImageView.frame.size.height > 0 ? 20 : 0), self.view.frame.size.width*0.8, 22);
    self.footerLabel.center = CGPointMake(self.footerContainer.frame.size.width/2, self.footerLabel.center.y);
    
    self.footerExplanation.frame = CGRectMake(0, self.footerLabel.frame.size.height + self.footerLabel.frame.origin.y + 10, self.view.frame.size.width*0.8, 100);
    [self.footerExplanation sizeToFit];
    self.footerExplanation.center = CGPointMake(self.footerContainer.frame.size.width/2, self.footerExplanation.center.y);
    
    // Handle oversizing if needed
    self.footerImageView.hidden = NO;
    
    // We now know the heights of *everything*. Now, need to ensure it's all centered if there's less than 40px of space left.
    // Remove icon view if we're really tight on space.
    
    CGFloat remainingSpace = availableHeight - (self.footerExplanation.frame.size.height + self.footerExplanation.frame.origin.y);
    
    if (remainingSpace < 40) { // Margin left by icon.
        if (remainingSpace < -40) {
            // Will need to kill the icon!
            self.footerImageView.hidden = YES;
            
            CGFloat marginWithoutIcon = availableHeight - (self.footerLabel.frame.size.height + 10 + self.footerExplanation.frame.size.height);
            marginWithoutIcon /= 2;
            
            if (marginWithoutIcon > 40) {
                marginWithoutIcon = 40;
            }
            
            self.footerLabel.frame = CGRectMake(self.footerLabel.frame.origin.x, marginWithoutIcon, self.footerLabel.frame.size.width, self.footerLabel.frame.size.height);
            self.footerExplanation.frame = CGRectMake(self.footerExplanation.frame.origin.x, self.footerLabel.frame.size.height + self.footerLabel.frame.origin.y + 10, self.footerExplanation.frame.size.width, self.footerExplanation.frame.size.height);
        } else {
            CGFloat margin = (40 + remainingSpace)/2;
            
            self.footerImageView.center = CGPointMake(self.footerContainer.frame.size.width/2, self.footerImageView.frame.size.height/2 + margin);
            self.footerLabel.frame = CGRectMake(self.footerLabel.frame.origin.x, self.footerImageView.frame.size.height + self.footerImageView.frame.origin.y + (self.footerImageView.frame.size.height > 0 ? 20 : 0), self.footerLabel.frame.size.width, self.footerLabel.frame.size.height);
            self.footerExplanation.frame = CGRectMake(self.footerExplanation.frame.origin.x, self.footerLabel.frame.size.height + self.footerLabel.frame.origin.y + 10, self.footerExplanation.frame.size.width, self.footerExplanation.frame.size.height);
        }
    }
    
    self.footerContainer.frame = CGRectMake(self.footerContainer.frame.origin.x, self.footerContainer.frame.origin.y, self.view.frame.size.width, self.footerExplanation.frame.size.height + self.footerExplanation.frame.origin.y);
}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    if (self.footerContainer)
        self.footerContainer = nil;
    
    self.footerContainer = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Image
    if (self.footerImageView)
        self.footerImageView = nil;
    
    self.footerImageView = [[UIImageView alloc] initWithImage:[self footerImage]];
    self.footerImageView.backgroundColor = [UIColor clearColor];
    
    [self.footerContainer addSubview:self.footerImageView];
    
    // Title
    if (self.footerLabel)
        self.footerLabel = nil;
    
    self.footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.footerLabel.text = [self footerTitle];
    self.footerLabel.textAlignment = NSTextAlignmentCenter;
    if (@available(iOS 13.0, *)) {
        self.footerLabel.textColor = [UIColor labelColor];
    } else {
        self.footerLabel.textColor = [UIColor blackColor];
    }
    self.footerLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    
    [self.footerContainer addSubview:self.footerLabel];
    
    // Explanation
    if (self.footerExplanation)
        self.footerExplanation = nil;
    
    self.footerExplanation = [[UILabel alloc] initWithFrame:CGRectZero];
    self.footerExplanation.text = [self footerBody];
    self.footerExplanation.textAlignment = NSTextAlignmentCenter;
    if (@available(iOS 13.0, *)) {
        self.footerExplanation.textColor = [UIColor labelColor];
    } else {
        self.footerExplanation.textColor = [UIColor blackColor];
    }
    self.footerExplanation.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.footerExplanation.numberOfLines = 0;
    
    [self.footerContainer addSubview:self.footerExplanation];
    

    // Do initial layout
    [self _layoutFooterViews];
    
    return self.footerContainer;
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

@end
