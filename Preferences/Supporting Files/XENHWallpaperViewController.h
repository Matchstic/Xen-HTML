//
//  XENHWallpaperViewController.h
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 25/01/2018.
//

#import <UIKit/UIKit.h>

@interface XENHWallpaperViewController : UIViewController

/**
 Initialises a view controller containing the current wallpaper variant.
 @param wallpaperVariant Which wallpaper to use. 0 == Lockscreen, 1 == Homescreen
 */
- (instancetype)initWithVariant:(int)wallpaperVariant;

- (BOOL)isWallpaperImageDark;
- (void)cacheWallpaperImageToFilesystem;

@end
