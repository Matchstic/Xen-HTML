//
//  XENHMoreReposController.h
//  
//
//  Created by Matt Clarke on 20/09/2016.
//
//

#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@interface XENHMoreReposController : PSListController <UIAlertViewDelegate> {
    NSArray *_items;
    NSString *_selectedRepo;
}

@end
