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

#import "XENHPickerCell2.h"
#import "XENHResources.h"

@implementation XENHPickerCell2

-(void)_configureViewsIfRequired {
    if (!_filesystemName) {
        _filesystemName = [[UILabel alloc] initWithFrame:CGRectZero];
        _filesystemName.textColor = [UIColor darkTextColor];
        _filesystemName.textAlignment = NSTextAlignmentLeft;
        _filesystemName.font = [UIFont systemFontOfSize:18];
        
        [self.contentView addSubview:_filesystemName];
    }
    
    if (!_author) {
        _author = [[UILabel alloc] initWithFrame:CGRectZero];
        _author.textColor = [UIColor grayColor];
        _author.textAlignment = NSTextAlignmentLeft;
        _author.font = [UIFont systemFontOfSize:14];
        
        [self.contentView addSubview:_author];
    }
    
    if (!_packageName) {
        _packageName = [[UILabel alloc] initWithFrame:CGRectZero];
        _packageName.textColor = [UIColor grayColor];
        _packageName.textAlignment = NSTextAlignmentLeft;
        _packageName.font = [UIFont systemFontOfSize:14];
        
        [self.contentView addSubview:_packageName];
    }
    
    if (!_screenshot) {
        _screenshot = [[UIImageView alloc] initWithFrame:CGRectZero];
        _screenshot.contentMode = UIViewContentModeScaleAspectFill;
        _screenshot.clipsToBounds = YES;
        
        _screenshot.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:_screenshot];
    }
    
    _filesystemName.textColor = [UIColor darkTextColor];
}

- (void)setupForNoWidgetsWithWidgetType:(NSString*)type {
    [self _configureViewsIfRequired];
    
    _filesystemName.textColor = [UIColor grayColor];
    
    _filesystemName.text = [XENHResources localisedStringForKey:@"WIDGET_PICKER_NO_WIDGETS_AVAILABLE"];
    
    // Blank out everything else.
    _author.text = @"";
    _packageName.text = @"";
    self.accessoryType = UITableViewCellAccessoryNone;
    _screenshot.image = nil;
    _screenshot.hidden = YES;
}

-(void)setupWithFilename:(NSString *)filename screenshotFilename:(NSString *)screenshot andAssociatedUrl:(NSString *)url {
    // Setup cell for new incoming data.
    _url = url;
    
    [self _configureViewsIfRequired];
    
    // Configure filename as appropriate.
    NSString *thing = [filename stringByDeletingLastPathComponent];
    if ([thing isEqualToString:@""]) {
        _filesystemName.text = [XENHResources localisedStringForKey:@"WIDGET_PICKER_NONE"];
        
        // Blank out everything else.
        _author.text = @"";
        _packageName.text = @"";
        self.accessoryType = UITableViewCellAccessoryNone;
        _screenshot.image = nil;
        _screenshot.hidden = YES;
        
        return;
    } else {
        filename = [thing lastPathComponent];
        filename = [filename stringByReplacingOccurrencesOfString:@".theme" withString:@""];
        filename = [filename stringByReplacingOccurrencesOfString:@".cydget" withString:@""];
    }
    
    _filesystemName.text = filename;
    
    NSString *loading = [XENHResources localisedStringForKey:@"WIDGET_PICKER_LOADING"];
    
    _author.text = loading;
    
    NSString *inPackageStatic = [XENHResources localisedStringForKey:@"WIDGET_PICKER_PACKAGE_PREFIX"];
    _packageName.text = [NSString stringWithFormat:@"%@ %@", inPackageStatic, loading];
    
    // We now have the URL of this widget. Proceed to ask libpackageinfo for details, and check for a screenshot.
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        NSString *cachedurl = [url copy];
        
        PIPackage *package;
        
        @try {
            package = [PIPackage packageForFile:url];
        } @catch (NSException *e) {
            NSLog(@"Error loading package information! %@", e);
            package = nil;
        }
        
        _package = package;
        
        if (![cachedurl isEqualToString:_url]) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            
            
            // Check if the author needs any changes.
            NSString *authorText = package.author && ![package.author isEqualToString:@""] ? package.author : [XENHResources localisedStringForKey:@"WIDGET_PICKER_UNKNOWN_AUTHOR"];
            
            if ([authorText rangeOfString:@"<"].location != NSNotFound) {
                // Take off the author email.
                NSUInteger location = [authorText rangeOfString:@"<"].location;
                
                authorText = [authorText substringToIndex:location];
            }
            
            _author.text = authorText;
            
            NSString *packageText = package.name && ![package.name isEqualToString:@""] ? package.name : [XENHResources localisedStringForKey:@"WIDGET_PICKER_UNKNOWN_PACKAGE"];
            
            _packageName.text = [NSString stringWithFormat:@"%@ %@", inPackageStatic, packageText];
            
            if (screenshot) {
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    UIImage *img = [UIImage imageWithContentsOfFile:screenshot];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        _screenshot.image = img;
                        _screenshot.hidden = NO;
                        _screenshot.frame = CGRectMake(self.contentView.frame.size.width * 0.8, 10, self.contentView.frame.size.width * 0.2 - 10, self.contentView.frame.size.height - 20);
                        _screenshot.layer.cornerRadius = 2.5;
                    });
                });
                
                self.accessoryType = UITableViewCellAccessoryNone;
            } else {
                _screenshot.image = nil;
                _screenshot.hidden = YES;
                
                self.accessoryType = UITableViewCellAccessoryDetailButton;
            }
        });
    });
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout labels.
    // We can assume that the accessory view and the screenshot image will occupy the same region.
    // So, can define them as a variable of max X.
    
    CGFloat maxX = self.contentView.frame.size.width * (_screenshot.hidden ? 0.85 : 0.8) - 10; // - 10 for margins.
    CGFloat y = 10;
    
    if (!_screenshot.hidden) {
        y += 10;
    }
    
    _filesystemName.frame = CGRectMake(10, y, maxX, 20);
    
    y += _filesystemName.frame.size.height + 5;
    
    _author.frame = CGRectMake(10, y, maxX - 10, 18);
    
    y += _author.frame.size.height;
    
    _packageName.frame = CGRectMake(10, y, maxX, 18);
    
    _screenshot.frame = CGRectMake(self.contentView.frame.size.width * 0.8, 10, self.contentView.frame.size.width * 0.2 - 10, self.contentView.frame.size.height - 20);
    _screenshot.layer.cornerRadius = 2.5;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
