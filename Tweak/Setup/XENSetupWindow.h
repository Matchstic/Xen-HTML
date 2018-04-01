//
//  XENSetupWindow.h
//  
//
//  Created by Matt Clarke on 10/07/2016.
//
//

#import <UIKit/UIKit.h>

@interface UIStatusBar : UIView
- (id)initWithFrame:(CGRect)arg1 showForegroundView:(bool)arg2;
- (void)setStyleRequest:(id)arg1;
- (void)requestStyle:(long long)arg1 animated:(bool)arg2;
- (void)setLegibilityStyle:(long long)arg1;
@end

@interface XENHSetupWindow : UIWindow

@property (nonatomic, strong) UIView *bar;
@property (nonatomic, readwrite) BOOL usingQuickSetup;

+(instancetype)sharedInstance;
//+(void)relayoutXenForSetupFinished;
+(void)finishSetupMode;

@end
