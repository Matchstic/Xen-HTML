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

#import "XENHPHeaderView.h"
#import "XENHPResources.h"

@implementation XENHPHeaderView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.container = [[UIView alloc] initWithFrame:CGRectZero];
        self.container.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.container];
        
        NSString *imagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Background%@", [XENHResources imageSuffix]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            // Oh for crying out loud CoolStar
            imagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/Background%@", [XENHResources imageSuffix]];
        }
        
        self.background = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imagePath]];
        self.background.backgroundColor = [UIColor clearColor];
        self.background.contentMode = UIViewContentModeScaleAspectFill;
        
        CAGradientLayer *mask = [CAGradientLayer layer];
        mask.locations = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0.0],
                          [NSNumber numberWithFloat:0.25],
                          [NSNumber numberWithFloat:0.5],
                          [NSNumber numberWithFloat:0.85],
                          nil];
        
        mask.colors = [NSArray arrayWithObjects:
                       (__bridge id)[UIColor whiteColor].CGColor,
                       (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.9].CGColor,
                       (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.5].CGColor,
                       (__bridge id)[UIColor clearColor].CGColor,
                       nil];
        
        mask.frame = self.background.bounds;
        
        mask.startPoint = CGPointMake(0, 0);
        mask.endPoint = CGPointMake(0, 1);
        
        self.background.layer.mask = mask;
        
        [self.container addSubview:self.background];
        
        // "XEN" string.
        
        self.tweakName = [[UILabel alloc] initWithFrame:CGRectZero];
        self.tweakName.textColor = [UIColor whiteColor];
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        NSMutableAttributedString* attrStr = [[NSMutableAttributedString alloc] initWithString:@"XEN" attributes:
                                              @{NSParagraphStyleAttributeName:paragraphStyle}];
        [attrStr addAttribute:NSKernAttributeName value:@(23.0) range:NSMakeRange(0, attrStr.length-1)];
        
        self.tweakName.attributedText = attrStr;
        self.tweakName.font = [UIFont systemFontOfSize:46 weight:UIFontWeightThin];
        self.tweakName.backgroundColor = [UIColor clearColor];
        self.tweakName.numberOfLines = 1;
        self.tweakName.textAlignment = NSTextAlignmentCenter;
        
        [self.container addSubview:self.tweakName];
        
        // "HTML" string.
        
        self.tweakSubtitle = [[UILabel alloc] initWithFrame:CGRectZero];
        self.tweakSubtitle.textColor = [UIColor whiteColor];
        
        NSMutableParagraphStyle *paragraphStyle2 = [NSMutableParagraphStyle new];
        paragraphStyle2.alignment = NSTextAlignmentCenter;
        
        NSMutableAttributedString* attrStr2 = [[NSMutableAttributedString alloc] initWithString:@"HTML" attributes:
                                               @{NSParagraphStyleAttributeName:paragraphStyle2}];
        [attrStr2 addAttribute:NSKernAttributeName value:@(8.0) range:NSMakeRange(0, attrStr2.length-1)];
        
        self.tweakSubtitle.attributedText = attrStr2;
        self.tweakSubtitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightLight];
        self.tweakSubtitle.backgroundColor = [UIColor clearColor];
        self.tweakSubtitle.numberOfLines = 1;
        self.tweakSubtitle.textAlignment = NSTextAlignmentCenter;
        
        [self.container addSubview:self.tweakSubtitle];
    }
    
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.background.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height + 70);
    self.background.layer.mask.frame = self.background.bounds;
    
    [self.tweakName sizeToFit];
    self.tweakName.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2 - self.tweakName.frame.size.height/2 + 10);
    
    [self.tweakSubtitle sizeToFit];
    self.tweakSubtitle.center = CGPointMake(self.bounds.size.width/2, self.tweakName.frame.origin.y + self.tweakName.frame.size.height + self.tweakSubtitle.frame.size.height/2);
    
    self.container.frame = self.bounds;
    self.container.clipsToBounds = NO;
    self.clipsToBounds = NO;
}


@end
