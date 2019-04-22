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

#import "XENHButton.h"
#import "XENHResources.h"
#import <objc/runtime.h>

@interface _UIBackdropView : UIView
- (instancetype)initWithStyle:(int)style;
@end

@interface MTMaterialView : UIView
+ (MTMaterialView*)materialViewWithRecipe:(long long)arg1 options:(unsigned long long)arg2;
@end

static CGFloat BUTTON_HEIGHT = 28.0;

@implementation XENHButton

- (id)initWithTitle:(NSString*)title {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        // Setup background view, and title label
        
        
        if (objc_getClass("MTMaterialView") && [objc_getClass("MTMaterialView") respondsToSelector:@selector(materialViewWithRecipe:options:)]) {
            // Fancy times! iOS 11 and up
            self.backgroundView = [objc_getClass("MTMaterialView") materialViewWithRecipe:1 options:2];
            self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.3];
        } else {
            // Fallback to _UIBackdropView
            self.backgroundView = [(_UIBackdropView*)[objc_getClass("_UIBackdropView") alloc] initWithStyle:2060];
        }
        [self addSubview:self.backgroundView];
        
        
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textLabel.font = [UIFont boldSystemFontOfSize:15];
        self.textLabel.text = title;
        self.textLabel.textColor = [UIColor blackColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.alpha = 0.7;
        
        [self.backgroundView addSubview:self.textLabel];
        
        self.highlightOverlayView = [[UIView alloc] initWithFrame:CGRectZero];
        self.highlightOverlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
        self.highlightOverlayView.userInteractionEnabled = NO;
        self.highlightOverlayView.alpha = 0.0;
        
        [self.backgroundView addSubview:self.highlightOverlayView];
        
        // Size to contents
        CGRect rect = [XENHResources boundedRectForFont:self.textLabel.font andText:title width:0];
        
        self.bounds = CGRectMake(0, 0, rect.size.width + (BUTTON_HEIGHT * 0.8), BUTTON_HEIGHT);
        
        self.layer.cornerRadius = BUTTON_HEIGHT / 2.0; // Rounded corners
        self.clipsToBounds = YES;
    }
    
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    [UIView animateWithDuration:0.1 animations:^{
        self.highlightOverlayView.alpha = highlighted ? 1.0 : 0.0;
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.backgroundView.frame = self.bounds;
    self.textLabel.frame = self.backgroundView.bounds;
    self.highlightOverlayView.frame = self.backgroundView.bounds;
}

@end
