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

#import "XENHFauxIconsViewController.h"
#import "XENHPResources.h"
#import <sys/utsname.h>

@interface UIImage (ApplicationIcons)
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2 scale:(double)arg3; //chnage
@end

@interface XENHFauxIconsViewController ()
/*@property (nonatomic, strong) CPDistributedMessagingCenter *c;
@property (nonatomic, strong) UIImageView *imageView;*/
@end

@implementation XENHFauxIconsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.userInteractionEnabled = NO;
    
    self.cachedIcons = [NSMutableDictionary dictionary];
    
    [self _configureIconsForPage:0];
}

- (void)_configureIconsForPage:(int)page {
    NSString *iconStatePlist = @"/var/mobile/Library/SpringBoard/IconState.plist";
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/IconSupport.dylib"]) {
        // Handle icon state from IconSupport
        
        iconStatePlist = @"/var/mobile/Library/SpringBoard/IconSupportState.plist";
    }
    
    NSDictionary *icons = [NSDictionary dictionaryWithContentsOfFile:iconStatePlist];
    
    NSArray *iconArray = [[icons objectForKey:@"iconLists"] objectAtIndex:page];
    
    // Fill up the ui with icons, removing old ones first
    for (UIView *view in _iconViews) {
        [view removeFromSuperview];
    }
    
    _iconViews = [NSMutableArray array];

    for (int i = 0; i < iconArray.count; i++) {
        id identifier = [iconArray objectAtIndex:i];
        
        UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectZero];
        icon.layer.cornerRadius = 12.5;
        icon.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
        
        [self.view addSubview:icon];
        
        @try {
            if ([identifier isKindOfClass:[NSString class]]) {
                if ([self.cachedIcons objectForKey:identifier]) {
                    icon.image = [self.cachedIcons objectForKey:identifier];
                    icon.backgroundColor = [UIColor clearColor];
                } else {
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                        UIImage *image = [UIImage _applicationIconImageForBundleIdentifier:identifier format:0 scale:[UIScreen mainScreen].scale];
                        if (image && identifier && ![identifier isEqualToString:@""])
                            [self.cachedIcons setObject:[image copy] forKey:identifier];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            icon.image = image;
                            icon.backgroundColor = [UIColor clearColor];
                        });
                    });
                }
            }
            
            [_iconViews addObject:icon];
        } @catch (NSException *e) {
            // Holy Batman wtf.
            // Give a lighter colour as fallback for an app icon.
            icon.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.35];
        }
    }
}

// Can be overriden by Boxy 3 or Iconoclasm
- (int)_adjustedColumns {
    return 4;
}

// Can be overriden by Boxy 3 or Iconoclasm
- (int)_adjustedRows {
    CGFloat iconsPerColumn = 0;
    
    // If iPad, 4 in landscape, 5 in portrait.
    if (IS_IPAD) {
        iconsPerColumn = 5;
    } else if (SCREEN_MAX_LENGTH > 568) {
        iconsPerColumn = 6;
    } else if (SCREEN_MAX_LENGTH > 480) {
        iconsPerColumn = 5;
    } else {
        iconsPerColumn = 4;
    }
    
    return iconsPerColumn;
}

- (void)_layoutIconsForPage:(int)page {
    // Layout the icons. First, figure out the left margin, and then the inter-icon margins.
    CGFloat dockHeight = (IS_IPAD ? 124 : 96);
    
    CGFloat iconsPerRow = [self _adjustedColumns];
    CGFloat iconsPerColumn = [self _adjustedRows];
    
    // TODO: Get adjusted insets now
    
    CGFloat iconWidth = (IS_IPAD ? 72 : 60);
    CGFloat marginWidth = self.view.bounds.size.width - (iconWidth*iconsPerRow);
    
    // One full margin is used as the left/right insets.
    marginWidth /= iconsPerRow;
    
    CGFloat leftInset = marginWidth/2;
    
    // Now, handle the vertical margins.
    CGFloat marginHeight = (self.view.bounds.size.height - dockHeight) - (iconWidth*iconsPerColumn);
    marginHeight /= iconsPerColumn;
    
    CGFloat topInset = marginHeight/2 + 20.0;
    
    int row = 0;
    int column = 0;
    
    for (int i = 0; i < _iconViews.count; i++) {
        UIView *icon = [_iconViews objectAtIndex:i];
        
        icon.frame = CGRectMake(leftInset + (column*marginWidth) + (column*iconWidth), topInset + (row*marginHeight) + (row*iconWidth), (IS_IPAD ? 72 : 60), (IS_IPAD ? 72 : 60));
        
        column++;
        
        if (column == iconsPerRow) {
            column = 0;
            row++;
        }
    }
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self _layoutIconsForPage:0];
}

@end
