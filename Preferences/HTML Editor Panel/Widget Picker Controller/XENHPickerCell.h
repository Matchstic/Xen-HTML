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
#import "XENHPickerItem.h"

@interface PIPackage : NSObject
@property(nonatomic, readonly) NSString *identifier;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSString *author;
@property(nonatomic, readonly) NSString *version;
@property(nonatomic, readonly) NSDate *installDate;
@property(nonatomic, readonly) NSString *bundlePath;
@property(nonatomic, readonly) NSString *libraryPath;
+ (instancetype)packageForFile:(NSString *)filepath;
@end

@interface PIPackageCache : NSObject
+ (instancetype)sharedCache;
- (PIPackage *)packageForFile:(NSString *)filepath;
@end

@protocol XENHPickerCellDelegate2 <NSObject>
-(void)didClickScreenshotButton:(PIPackage*)package;
@end

@interface XENHPickerCell : UITableViewCell
@property(nonatomic, strong) PIPackage *package;
@property(nonatomic, strong) UILabel *filesystemName;
@property(nonatomic, strong) UILabel *author;
@property(nonatomic, strong) UILabel *packageName;
@property(nonatomic, strong) UIImageView *screenshot;
@property(nonatomic, strong) NSString *url;

- (void)setupForNoWidgetsWithWidgetType:(NSString*)type;
- (void)setupWithItem:(XENHPickerItem*)item;

@end
