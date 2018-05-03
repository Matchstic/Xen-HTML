//
//  XENHMultiplexWidgetsHeaderView.h
//  Preferences
//
//  Created by Matt Clarke on 03/05/2018.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kMultiplexVariantLockscreenBackground = 0,
    kMultiplexVariantLockscreenForeground = 1,
    kMultiplexVariantHomescreenBackground = 2
} XENHMultiplexVariant;

@interface XENHMultiplexWidgetsHeaderView : UIView

@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *label;

- (instancetype)initWithVariant:(XENHMultiplexVariant)variant;

@end
