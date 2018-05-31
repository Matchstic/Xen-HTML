//
//  XENHFallbackOnlyOptionsController.h
//  Preferences
//
//  Created by Matt Clarke on 04/05/2018.
//

#import <Preferences/PSListController.h>
#import "XENHFallbackDelegate-Protocol.h"

@interface XENHFallbackOnlyOptionsController : UITableViewController

@property (nonatomic, weak) id<XENHFallbackDelegate> fallbackDelegate;
@property (nonatomic, readwrite) BOOL fallbackState;

- (instancetype)initWithFallbackState:(BOOL)state;

@end
