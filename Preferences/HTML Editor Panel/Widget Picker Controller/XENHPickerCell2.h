//
//  XENHPickerCell2.h
//  Xen
//
//  Created by Matt Clarke on 26/02/2017.
//
//

#import <UIKit/UIKit.h>

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

@interface XENHPickerCell2 : UITableViewCell {
    PIPackage *_package;
    UILabel *_filesystemName;
    UILabel *_author;
    UILabel *_packageName;
    UIImageView *_screenshot;
    NSString *_url;
}

- (void)setupForNoWidgetsWithWidgetType:(NSString*)type;
-(void)setupWithFilename:(NSString*)filename screenshotFilename:(NSString*)screenshot andAssociatedUrl:(NSString*)url;

@end
