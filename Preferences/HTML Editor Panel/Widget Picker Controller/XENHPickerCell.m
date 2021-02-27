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

#import "XENHPickerCell.h"
#import "XENHPResources.h"

@implementation XENHPickerCell

-(void)_configureViewsIfRequired {
    if (!self.filesystemName) {
        self.filesystemName = [[UILabel alloc] initWithFrame:CGRectZero];
        if (@available(iOS 13.0, *)) {
            self.filesystemName.textColor = [UIColor labelColor];
        } else {
            self.filesystemName.textColor = [UIColor darkTextColor];
        }
        self.filesystemName.textAlignment = NSTextAlignmentLeft;
        self.filesystemName.font = [UIFont systemFontOfSize:18];
        
        [self.contentView addSubview:self.filesystemName];
    }
    
    if (!self.author) {
        self.author = [[UILabel alloc] initWithFrame:CGRectZero];
        if (@available(iOS 13.0, *)) {
            self.author.textColor = [UIColor secondaryLabelColor];
        } else {
            self.author.textColor = [UIColor grayColor];
        }
        self.author.textAlignment = NSTextAlignmentLeft;
        self.author.font = [UIFont systemFontOfSize:14];
        
        [self.contentView addSubview:self.author];
    }
    
    if (!self.screenshot) {
        self.screenshot = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.screenshot.contentMode = UIViewContentModeScaleAspectFill;
        self.screenshot.clipsToBounds = YES;
        
        self.screenshot.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.screenshot];
    }
    
    if (@available(iOS 13.0, *)) {
        self.filesystemName.textColor = [UIColor labelColor];
    } else {
        self.filesystemName.textColor = [UIColor darkTextColor];
    }
}

- (void)setupForNoWidgetsWithWidgetType:(NSString*)type {
    [self _configureViewsIfRequired];
    
    self.filesystemName.text = [XENHResources localisedStringForKey:@"WIDGET_PICKER_NO_WIDGETS_AVAILABLE"];
    
    // Blank out everything else.
    self.author.text = @"";
    self.accessoryType = UITableViewCellAccessoryNone;
    self.screenshot.image = nil;
    self.screenshot.hidden = YES;
}

- (void)setupWithItem:(XENHPickerItem*)item {
    self.url = item.absoluteUrl;
    
    [self _configureViewsIfRequired];
    
    NSString *widgetName = item.name;
    if ([widgetName isEqualToString:@""]) {
        self.filesystemName.text = [XENHResources localisedStringForKey:@"WIDGET_PICKER_NONE"];
        
        // Blank out everything else.
        self.author.text = @"";
        self.accessoryType = UITableViewCellAccessoryNone;
        self.screenshot.image = nil;
        self.screenshot.hidden = YES;
        
        return;
    } else {
        widgetName = [widgetName stringByReplacingOccurrencesOfString:@".theme" withString:@""];
        widgetName = [widgetName stringByReplacingOccurrencesOfString:@".cydget" withString:@""];
    }
    
    self.filesystemName.text = widgetName;
    
    if (item.config && [item.config objectForKey:@"author"]) {
        self.author.text = [item.config objectForKey:@"author"];
    } else {
        self.author.text = [XENHResources localisedStringForKey:@"WIDGET_PICKER_UNKNOWN_AUTHOR"];
    }
    
    if (item.screenshotUrl && item.screenshotUrl.length > 0) {
        XENHPickerCell * __weak weakSelf = self;
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            UIImage *img = [UIImage imageWithContentsOfFile:item.screenshotUrl];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                weakSelf.screenshot.image = img;
                weakSelf.screenshot.hidden = NO;
                weakSelf.screenshot.frame = CGRectMake(weakSelf.contentView.frame.size.width * 0.8, 10, weakSelf.contentView.frame.size.width * 0.2 - 10, weakSelf.contentView.frame.size.height - 20);
                weakSelf.screenshot.layer.cornerRadius = 2.5;
            });
        });
        
        self.accessoryType = UITableViewCellAccessoryNone;
    } else {
        self.screenshot.image = nil;
        self.screenshot.hidden = YES;
        
        self.accessoryType = UITableViewCellAccessoryDetailButton;
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout labels.
    // We can assume that the accessory view and the screenshot image will occupy the same region.
    // So, can define them as a variable of max X.
    
    CGFloat maxX = self.contentView.frame.size.width * (self.screenshot.hidden ? 0.85 : 0.8) - 10; // - 10 for margins.
    CGFloat y = 10;
    
    if (!self.screenshot.hidden) {
        y += 19;
    }
    
    self.filesystemName.frame = CGRectMake(10, y, maxX, 20);
    
    y += self.filesystemName.frame.size.height + 5;
    
    self.author.frame = CGRectMake(10, y, maxX - 10, 18);
    
    self.screenshot.frame = CGRectMake(self.contentView.frame.size.width * 0.8, 10, self.contentView.frame.size.width * 0.2 - 10, self.contentView.frame.size.height - 20);
    self.screenshot.layer.cornerRadius = 2.5;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
