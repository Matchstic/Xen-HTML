//
//  XENSetupBaseTableController.h
//  
//
//  Created by Matt Clarke on 10/07/2016.
//
//

#import <UIKit/UIKit.h>

@interface XENHSetupBaseTableController : UITableViewController {
    NSInteger _currentlyCheckmarkedCell;
}

-(NSString*)headerTitle;
-(NSString*)cellReuseIdentifier;
-(NSInteger)rowsToDisplay;
-(UIImage*)footerImage;
-(NSString*)footerTitle;
-(NSString*)footerBody;
-(NSString*)titleForCellAtIndex:(NSInteger)index;
-(void)userDidSelectCellAtIndex:(NSInteger)index;
-(void)userDidTapNextButton;
-(UIViewController*)controllerToSegueForIndex:(NSInteger)index;
-(BOOL)shouldSegueToNewControllerAfterSelectingCell;
-(BOOL)shouldCheckmarkAfterSelectingCell;
-(BOOL)shouldDisplayNextButton;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
