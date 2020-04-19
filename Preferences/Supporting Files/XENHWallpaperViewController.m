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

#import "XENHWallpaperViewController.h"
#import "XENHPResources.h"
#import <objc/runtime.h>

@interface XENHWallpaperViewController ()

@property (nonatomic, readwrite) int wallpaperVariant;
@property (nonatomic, strong) UIImageView *wallpaperImageView;

@end

@implementation XENHWallpaperViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype)initWithVariant:(int)wallpaperVariant {
    self = [super init];
    
    if (self) {
        // Doesn't break the status bar!
        self.wallpaperVariant = wallpaperVariant;
        //[self _configureWallpaperForVariant:self.wallpaperVariant];
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    [self _configureWallpaperForVariant:self.wallpaperVariant];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.wallpaperImageView.frame = self.view.bounds;
}

- (void)reloadWallpaper {
    [self _configureWallpaperForVariant:self.wallpaperVariant];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)isWallpaperImageDark {
    UIImage *workingImage = self.wallpaperImageView.image;
    
    if (!workingImage) {
        workingImage = [self _wallpaperImageForVariant:self.wallpaperVariant];
    }
    
    // Get average colour, then check luminance.
    CGSize size = {1, 1};
    
    UIGraphicsBeginImageContext(size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(ctx, kCGInterpolationMedium);
    
    [workingImage drawInRect:(CGRect){.size = size} blendMode:kCGBlendModeCopy alpha:1];
    
    uint8_t *data = CGBitmapContextGetData(ctx);
    CGFloat red = data[0] / 255.f, green = data[1] / 255.f, blue = data[0] / 255.f;

    UIGraphicsEndImageContext();
    
    CGFloat brightness = red * 0.3 + green * 0.59 + blue * 0.11;
    
    return brightness < 0.5;
}

- (void)cacheWallpaperImageToFilesystem {
    // Render to img file.
    //UIImage *wallpaperImage = [self _imageWithView:[self.previewController _wallpaperView]];
    UIImage *wallpaperImage = self.wallpaperImageView.image;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [UIImagePNGRepresentation(wallpaperImage) writeToFile:@"/var/mobile/Library/Caches/com.apple.Preferences/xen_wallpaperCache.png" atomically:YES];
    });
}

//////////////////////////////////////////////////////////////////////////////////////////
// Static wallpaper loading
//////////////////////////////////////////////////////////////////////////////////////////

- (void)_configureWallpaperForVariant:(int)variant {
    UIImage *wallpaperStaticImage = [self _wallpaperImageForVariant:self.wallpaperVariant];
    
    // Set image!
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.wallpaperImageView) {
            self.wallpaperImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
            self.wallpaperImageView.clipsToBounds = YES;
            
            [self.view addSubview:self.wallpaperImageView];
        }
        
        self.wallpaperImageView.image = wallpaperStaticImage;
        self.wallpaperImageView.contentMode = UIViewContentModeScaleAspectFill;
    });
}

- (NSDictionary*)userSpringBoardSettings {
    CFPreferencesAppSynchronize(CFSTR("com.apple.springboard"));
    
    CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("com.apple.springboard"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!keyList) {
        NSLog(@"There's been an error getting the key list!");
        return @{};
    }
    
    CFDictionaryRef dictionary = CFPreferencesCopyMultiple(keyList, CFSTR("com.apple.springboard"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    
    return [(__bridge NSDictionary *)dictionary copy];
}

- (UIImage*)_wallpaperImageForVariant:(int)variant {
    NSLog(@"*** Reading user preferences for wallpaper...");
    // Read user settings and load thumbnail images as appropriate
    NSDictionary *userSettings = [self userSpringBoardSettings];
    
    NSNumber *_variantIsProcedural = [userSettings objectForKey:variant == 0 ? @"kSBProceduralWallpaperLockUserSetKey" : @"kSBProceduralWallpaperHomeUserSetKey"];
    BOOL variantIsProcedural = _variantIsProcedural != nil ? [_variantIsProcedural boolValue] : NO;
    
    UIImage *wallpaperStaticImage = nil;
    
    if (variantIsProcedural) {
        NSLog(@"*** Loading procedural!");
        wallpaperStaticImage = [self _proceduralStaticImageForSettings:[userSettings objectForKey:variant == 0 ? @"kSBProceduralWallpaperLockOptionsKey" : @"kSBProceduralWallpaperHomeOptionsKey"]];
    } else {
        NSLog(@"*** Loading static!");
        wallpaperStaticImage = [self _staticImageForVariant:variant];
    }
    
    return wallpaperStaticImage;
}

- (UIImage*)_proceduralStaticImageForSettings:(NSDictionary*)settings {
    NSString *thumbnailImageName = [settings objectForKey:@"thumbnailImageName"];
    
    NSString *imageSuffix = @"";
    
    switch ((int)[UIScreen mainScreen].scale) {
        case 2:
            imageSuffix = @"@2x";
            break;
        case 3:
            imageSuffix = @"@3x";
            break;
            
        default:
            break;
    }
    
    NSString *deviceSize = @"";
    NSString *deviceType = IS_IPAD ? @"~ipad" : @"~iphone";
    
    if (SCREEN_MAX_LENGTH >= 736) {
        deviceSize = @"-736h";
    } else if (SCREEN_MAX_LENGTH >= 667) {
        deviceSize = @"-667h";
    } else if (SCREEN_MAX_LENGTH >= 568) {
        deviceSize = @"-568h";
    } else {
        deviceSize = @"480h";
    }
    
    NSString *thumbnailPath = [NSString stringWithFormat:@"/System/Library/ProceduralWallpaper/ProceduralWallpapers.bundle/%@%@%@%@.png", thumbnailImageName, deviceSize, imageSuffix, deviceType];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
        thumbnailPath = [NSString stringWithFormat:@"/System/Library/ProceduralWallpaper/ProceduralWallpapers.bundle/%@%@%@.png", thumbnailImageName, imageSuffix, deviceType];
    }
    
    NSLog(@"*** Loading from: %@", thumbnailPath);
    
    return [UIImage imageWithContentsOfFile:thumbnailPath];
}

- (UIImage*)_staticImageForVariant:(int)variant {
    
    // Make sure to fallback to LockBackground.cpbitmap if needed
    NSString *wallpaperPath = @"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap";
    
    if (variant != 0) {
        // Load HomeBackground.cpbitmap if possible
        // Handles case of user using the "Set Both" option for a given wallpaper
        NSString *homescreenWallpaperPath = @"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap";
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:homescreenWallpaperPath])
            wallpaperPath = homescreenWallpaperPath;
    }
    
    NSLog(@"*** Loading from: %@", wallpaperPath);
    
    // Make sure this file exists before loading...
    if ([[NSFileManager defaultManager] fileExistsAtPath:wallpaperPath]) {
        CFArrayRef CPBitmapCreateImagesFromData(CFDataRef cpbitmap, void*, int, void*);
        CFArrayRef someArrayRef = CPBitmapCreateImagesFromData((__bridge CFDataRef)([NSData dataWithContentsOfFile:wallpaperPath]), NULL, 1, NULL);
        
        if (someArrayRef) {
            NSArray *array = (__bridge NSArray*)someArrayRef;
            
            UIImage *image = [UIImage imageWithCGImage:(__bridge CGImageRef)(array[0])];
            CFRelease(someArrayRef); // Release memory!
            return image;
        } else {
            // Create a black image of the display size
            CGSize imageSize = [UIScreen mainScreen].bounds.size;
            UIColor *fillColor = [UIColor blackColor];
            
            UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            [fillColor setFill];
            CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            return image;
        }
    } else {
        // Create a black image of the display size
        CGSize imageSize = [UIScreen mainScreen].bounds.size;
        UIColor *fillColor = [UIColor blackColor];
        
        UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [fillColor setFill];
        CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;
    }
}

@end
