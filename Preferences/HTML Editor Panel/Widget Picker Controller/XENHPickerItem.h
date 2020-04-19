//
//  XENHPickerItem.h
//  Preferences
//
//  Created by Matt Clarke on 12/04/2020.
//

#import <Foundation/Foundation.h>

@interface XENHPickerItem : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *absoluteUrl;
@property (nonatomic, strong) NSString *screenshotUrl;
@property (nonatomic, strong) NSDictionary *config;

@end
