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

#import "XENHMultiplexWidgetsHeaderView.h"
#import "XENHPResources.h"

@implementation XENHMultiplexWidgetsHeaderView

- (instancetype)initWithVariant:(XENHMultiplexVariant)variant {
    self = [super init];
    
    if (self) {
        [self _configureViews];
        [self _configureForVariant:variant];
    }
    
    return self;
}

- (void)_configureViews {
    // TODO: Load views -> an image and some text
    self.icon = [[UIImageView alloc] initWithFrame:CGRectZero];
    
    [self addSubview:self.icon];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectZero];
    if (@available(iOS 13.0, *)) {
        self.label.textColor = [UIColor secondaryLabelColor];
    } else {
        self.label.textColor = [UIColor darkGrayColor];
    }
    self.label.font = [UIFont systemFontOfSize:16];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.numberOfLines = 0;
    
    [self addSubview:self.label];
}

- (void)_configureForVariant:(XENHMultiplexVariant)variant {
    // Set the image and text content per variant
    switch (variant) {
        case kMultiplexVariantLockscreenBackground:
            self.label.text = [XENHResources localisedStringForKey:@"WIDGETS_LSBACKGROUND_DETAIL"];
            break;
        case kMultiplexVariantLockscreenForeground:
            self.label.text = [XENHResources localisedStringForKey:@"WIDGETS_LSFOREGROUND_DETAIL"];
            break;
        case kMultiplexVariantHomescreenBackground:
            self.label.text = [XENHResources localisedStringForKey:@"WIDGETS_SBBACKGROUND_DETAIL"];
            break;
        case kMultiplexVariantHomescreenForeground:
            self.label.text = [XENHResources localisedStringForKey:@"WIDGETS_SBFOREGROUND_DETAIL"];
            break;
        default:
            break;
    }
    
    self.icon.image = [self _imageForVariant:variant];
}

- (UIImage*)_imageForVariant:(XENHMultiplexVariant)variant {
    NSString *imageName = @"";
    switch (variant) {
        case kMultiplexVariantLockscreenBackground:
        case kMultiplexVariantHomescreenBackground:
            imageName = @"LargeBackgroundWidget";
            break;
        case kMultiplexVariantLockscreenForeground:
        case kMultiplexVariantHomescreenForeground:
            imageName = @"LargeForegroundWidget";
            break;
        default:
            break;
    }
    
    NSString *imagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Editor/%@%@", imageName, [XENHResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        // handle /bootstrap
        imagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/Editor/%@%@", imageName, [XENHResources imageSuffix]];
    }
    
    return [UIImage imageWithContentsOfFile:imagePath];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout subviews.
    CGFloat iconMargin = 20;
    self.icon.frame = CGRectMake(0, 0, 40, 40);
    self.icon.center = CGPointMake(self.frame.size.width/2.0, self.icon.frame.size.height/2.0 + iconMargin);
    
    CGFloat labelMargin = 10;
    CGRect rect = [XENHResources boundedRectForFont:self.label.font andText:self.label.text width:self.frame.size.width - (labelMargin * 2.0)];
    
    self.label.frame = CGRectMake(labelMargin, self.icon.frame.size.height + iconMargin + labelMargin, self.frame.size.width - (labelMargin * 2.0), rect.size.height);
}

@end
