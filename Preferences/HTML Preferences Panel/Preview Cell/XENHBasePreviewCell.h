//
//  XENHBasePreviewCell.h
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 25/01/2018.
//

#import <Preferences/PSTableCell.h>
#import "XENHResources.h"

@interface XENHBasePreviewCell : PSTableCell <XENHPreviewCellStateDelegate>

- (CGFloat)preferredHeightForWidth:(CGFloat)width;

@end
