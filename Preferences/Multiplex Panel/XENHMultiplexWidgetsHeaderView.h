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

typedef enum : NSUInteger {
    kMultiplexVariantLockscreenBackground = 0,
    kMultiplexVariantLockscreenForeground = 1,
    kMultiplexVariantHomescreenBackground = 2,
    kMultiplexVariantHomescreenForeground = 3,
} XENHMultiplexVariant;

@interface XENHMultiplexWidgetsHeaderView : UIView

@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *label;

- (instancetype)initWithVariant:(XENHMultiplexVariant)variant;

@end
