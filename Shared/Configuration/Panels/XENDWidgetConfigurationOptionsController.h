//
//  XENDWidgetConfigurationOptionsController.h
//  Xen HTML
//
//  Created by Matt Clarke on 20/02/2021.
//

#import <UIKit/UIKit.h>
#import "../XENDWidgetConfigurationDelegate.h"
#import "../Cells/XENDWidgetConfigurationBaseTableCell.h"
#import "../Model/XENDWidgetConfigurationCell.h"

@interface XENDWidgetConfigurationOptionsController : UITableViewController

- (instancetype)initWithCell:(XENDWidgetConfigurationCell*)cell
                   initiator:(XENDWidgetConfigurationBaseTableCell*)initiator;

@end
