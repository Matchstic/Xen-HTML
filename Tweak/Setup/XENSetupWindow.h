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

#import <UIKit/UIKit.h>

@interface UIStatusBar : UIView
- (id)initWithFrame:(CGRect)arg1 showForegroundView:(bool)arg2;
- (void)setStyleRequest:(id)arg1;
- (void)requestStyle:(long long)arg1 animated:(bool)arg2;
- (void)setLegibilityStyle:(long long)arg1;
@end

@interface XENHSetupWindow : UIWindow

@property (nonatomic, strong) UIView *bar;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, readwrite) BOOL usingQuickSetup;

+(instancetype)sharedInstance;
//+(void)relayoutXenForSetupFinished;
+(void)finishSetupMode;

@end
