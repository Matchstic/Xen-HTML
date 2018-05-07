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
#import "XENHResources.h"
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
        [self _configureWallpaperForVariant:self.wallpaperVariant];
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

- (UIImage*)_wallpaperImageForVariant:(int)variant {
    NSLog(@"*** Reading user preferences for wallpaper...");
    // Read user settings and load thumbnail images as appropriate
    NSDictionary *userSettings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
    
    id _variantIsProcedural = [userSettings objectForKey:variant == 0 ? @"kSBProceduralWallpaperLockUserSetKey" : @"kSBProceduralWallpaperHomeUserSetKey"];
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
    NSString *wallpaperName = variant == 0 ? @"LockBackground.cpbitmap" : @"HomeBackground.cpbitmap";
    
    NSString *wallpaperPath = [NSString stringWithFormat:@"/var/mobile/Library/SpringBoard/%@", wallpaperName];
    
    NSLog(@"*** Loading from: %@", wallpaperPath);
    
    CFArrayRef CPBitmapCreateImagesFromData(CFDataRef cpbitmap, void*, int, void*);
    CFArrayRef someArrayRef = CPBitmapCreateImagesFromData((__bridge CFDataRef)([NSData dataWithContentsOfFile:wallpaperPath]), NULL, 1, NULL);
    
    NSArray *array = (__bridge NSArray*)someArrayRef;
    
    UIImage *image = [UIImage imageWithCGImage:(__bridge CGImageRef)(array[0])];
    
    return image;
}

@end
