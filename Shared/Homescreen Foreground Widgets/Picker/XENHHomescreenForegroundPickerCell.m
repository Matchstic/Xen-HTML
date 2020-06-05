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

#import "XENHHomescreenForegroundPickerCell.h"
#import "XENHResources.h"

@implementation XENHHomescreenForegroundPickerCell

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
    
    if (!self.packageName) {
        self.packageName = [[UILabel alloc] initWithFrame:CGRectZero];
        if (@available(iOS 13.0, *)) {
            self.packageName.textColor = [UIColor secondaryLabelColor];
        } else {
            self.packageName.textColor = [UIColor grayColor];
        }
        self.packageName.textAlignment = NSTextAlignmentLeft;
        self.packageName.font = [UIFont systemFontOfSize:14];
        
        [self.contentView addSubview:self.packageName];
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
    
    if (@available(iOS 13.0, *)) {
        self.packageName.textColor = [UIColor secondaryLabelColor];
    } else {
        self.packageName.textColor = [UIColor grayColor];
    }
    
    self.filesystemName.text = [XENHResources localisedStringForKey:@"WIDGET_PICKER_NO_WIDGETS_AVAILABLE"];
    
    // Blank out everything else.
    self.author.text = @"";
    self.packageName.text = @"";
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
        self.packageName.text = @"";
        self.accessoryType = UITableViewCellAccessoryNone;
        self.screenshot.image = nil;
        self.screenshot.hidden = YES;
        
        return;
    } else {
        widgetName = [widgetName stringByReplacingOccurrencesOfString:@".theme" withString:@""];
        widgetName = [widgetName stringByReplacingOccurrencesOfString:@".cydget" withString:@""];
    }
    
    self.filesystemName.text = widgetName;
    
    // Author and package name
    
    NSString *loading = [XENHResources localisedStringForKey:@"WIDGET_PICKER_LOADING"];

    BOOL needsAuthorLookup = YES;
    if (item.config && [item.config objectForKey:@"author"]) {
        self.author.text = [item.config objectForKey:@"author"];
        needsAuthorLookup = NO;
    } else {
        self.author.text = loading;
    }
    
    NSString *inPackageStatic = [XENHResources localisedStringForKey:@"WIDGET_PICKER_PACKAGE_PREFIX"];
    self.packageName.text = [NSString stringWithFormat:@"%@ %@", inPackageStatic, loading];
    
    // We now have the URL of this widget. Proceed to ask libpackageinfo for details, and check for a screenshot.
    
    XENHHomescreenForegroundPickerCell * __weak weakSelf = self;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        NSString *cachedurl = [self.url copy];
        
        PIPackage *package;
        
        @try {
            package = [PIPackage packageForFile:self.url];
        } @catch (NSException *e) {
            NSLog(@"Error loading package information! %@", e);
            package = nil;
        }
        
        weakSelf.package = package;
        
        if (![cachedurl isEqualToString:weakSelf.url]) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            
            if (needsAuthorLookup) {
                // Check if the author needs any changes.
                NSString *authorText = package.author && ![package.author isEqualToString:@""] ? package.author : [XENHResources localisedStringForKey:@"WIDGET_PICKER_UNKNOWN_AUTHOR"];
                
                if ([authorText rangeOfString:@"<"].location != NSNotFound) {
                    // Take off the author email.
                    NSUInteger location = [authorText rangeOfString:@"<"].location;
                    
                    authorText = [authorText substringToIndex:location];
                }
                
                weakSelf.author.text = authorText;
            }

            NSString *packageText = package.name && ![package.name isEqualToString:@""] ? package.name : [XENHResources localisedStringForKey:@"WIDGET_PICKER_UNKNOWN_PACKAGE"];
            
            weakSelf.packageName.text = [NSString stringWithFormat:@"%@ %@", inPackageStatic, packageText];
            
            if (item.screenshotUrl && item.screenshotUrl.length > 0) {
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    UIImage *img = [UIImage imageWithContentsOfFile:item.screenshotUrl];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        weakSelf.screenshot.image = img;
                        weakSelf.screenshot.hidden = NO;
                        weakSelf.screenshot.frame = CGRectMake(weakSelf.contentView.frame.size.width * 0.8, 10, weakSelf.contentView.frame.size.width * 0.2 - 10, weakSelf.contentView.frame.size.height - 20);
                        weakSelf.screenshot.layer.cornerRadius = 2.5;
                    });
                });
                
                weakSelf.accessoryType = UITableViewCellAccessoryNone;
            } else {
                weakSelf.screenshot.image = nil;
                weakSelf.screenshot.hidden = YES;
                
                weakSelf.accessoryType = UITableViewCellAccessoryDetailButton;
            }
        });
    });
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout labels.
    // We can assume that the accessory view and the screenshot image will occupy the same region.
    // So, can define them as a variable of max X.
    
    CGFloat maxX = self.contentView.frame.size.width * (self.screenshot.hidden ? 0.85 : 0.8) - 10; // - 10 for margins.
    CGFloat y = 10;
    
    if (!self.screenshot.hidden) {
        y += 10;
    }
    
    self.filesystemName.frame = CGRectMake(10, y, maxX, 20);
    
    y += self.filesystemName.frame.size.height + 5;
    
    self.author.frame = CGRectMake(10, y, maxX - 10, 18);
    
    y += self.author.frame.size.height;
    
    self.packageName.frame = CGRectMake(10, y, maxX, 18);
    
    self.screenshot.frame = CGRectMake(self.contentView.frame.size.width * 0.8, 10, self.contentView.frame.size.width * 0.2 - 10, self.contentView.frame.size.height - 20);
    self.screenshot.layer.cornerRadius = 2.5;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
