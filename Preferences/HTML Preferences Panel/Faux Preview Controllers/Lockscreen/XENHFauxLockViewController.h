//
//  XENHFauxLockViewController.h
//  
//
//  Created by Matt Clarke on 07/09/2016.
//
//

#import <UIKit/UIKit.h>

@interface SBFLockScreenDateView : UIView
+ (float)defaultHeight;
- (void)_addLabels;
- (void)_updateLabels;
- (id)initForDashBoard:(bool)arg1 withFrame:(CGRect)arg2;
@property(retain, nonatomic) NSDate *date;
@end

@interface SBFLockScreenMetrics : NSObject
+ (CGFloat)dateViewBaselineY;
+ (CGFloat)dateBaselineOffsetFromTime;
+ (UIEdgeInsets)notificationListInsets;
+ (float)dateLabelFontSize;
@end

@interface XENHFauxLockViewController : UIViewController {
    SBFLockScreenDateView *_dateView;
}

- (void)reloadForSettingsChange;

@end
