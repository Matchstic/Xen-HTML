//
//  XENHMultiplexWidgetsController.h
//  Preferences
//
//  Created by Matt Clarke on 03/05/2018.
//

#import <Preferences/PSListController.h>
#import "XENHMultiplexWidgetsHeaderView.h"
#import "XENHPickerController2.h"
#import "XENHEditorViewController.h"

@interface XENHMultiplexWidgetsController : PSListController <XENHPickerDelegate2, XENHEditorDelegate>

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) XENHMultiplexWidgetsHeaderView *headerView;
@property (nonatomic, readwrite) XENHMultiplexVariant variant;

- (instancetype)initWithVariant:(XENHMultiplexVariant)variant;

@end
