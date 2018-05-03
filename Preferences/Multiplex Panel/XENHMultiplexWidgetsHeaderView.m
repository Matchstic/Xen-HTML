//
//  XENHMultiplexWidgetsHeaderView.m
//  Preferences
//
//  Created by Matt Clarke on 03/05/2018.
//

#import "XENHMultiplexWidgetsHeaderView.h"
#import "XENHResources.h"

@implementation XENHMultiplexWidgetsHeaderView

- (instancetype)initWithVariant:(XENHMultiplexVariant)variant {
    self = [super init];
    
    if (self) {
        [self _configureViews];
        [self _configureForVariant:variant];
    }
    
    return self;
}

- (void)_configureViews {
    // TODO: Load views -> an image and some text
    self.icon = [[UIImageView alloc] initWithFrame:CGRectZero];
    
    [self addSubview:self.icon];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectZero];
    self.label.textColor = [UIColor darkGrayColor];
    self.label.font = [UIFont systemFontOfSize:16];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.numberOfLines = 0;
    
    [self addSubview:self.label];
}

- (void)_configureForVariant:(XENHMultiplexVariant)variant {
    // Set the image and text content per variant
    switch (variant) {
        case kMultiplexVariantLockscreenBackground:
            self.label.text = [XENHResources localisedStringForKey:@"Background widgets become part of your wallpaper" value:@"Background widgets become part of your wallpaper"];
            break;
        case kMultiplexVariantLockscreenForeground:
            self.label.text = [XENHResources localisedStringForKey:@"Foreground widgets are fully interactive additions to your Lockscreen" value:@"Foreground widgets are fully interactive additions to your Lockscreen"];
            break;
        case kMultiplexVariantHomescreenBackground:
            self.label.text = [XENHResources localisedStringForKey:@"Background widgets become interactive additions to your wallpaper" value:@"Background widgets become interactive additions to your wallpaper"];
            break;
        default:
            break;
    }
    
    self.icon.image = [self _imageForVariant:variant];
}

- (UIImage*)_imageForVariant:(XENHMultiplexVariant)variant {
    NSString *imageName = @"";
    switch (variant) {
        case kMultiplexVariantLockscreenBackground:
        case kMultiplexVariantHomescreenBackground:
            imageName = @"LargeBackgroundWidget";
            break;
        case kMultiplexVariantLockscreenForeground:
            imageName = @"LargeForegroundWidget";
            break;
        default:
            break;
    }
    
    NSString *imagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Editor/%@%@", imageName, [XENHResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        // handle /bootstrap
        imagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/Editor/%@%@", imageName, [XENHResources imageSuffix]];
    }
    
    return [UIImage imageWithContentsOfFile:imagePath];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout subviews.
    CGFloat iconMargin = 20;
    self.icon.frame = CGRectMake(0, 0, 40, 40);
    self.icon.center = CGPointMake(self.frame.size.width/2.0, self.icon.frame.size.height/2.0 + iconMargin);
    
    CGFloat labelMargin = 10;
    CGRect rect = [XENHResources boundedRectForFont:self.label.font andText:self.label.text width:self.frame.size.width - (labelMargin * 2.0)];
    
    self.label.frame = CGRectMake(labelMargin, self.icon.frame.size.height + iconMargin + labelMargin, self.frame.size.width - (labelMargin * 2.0), rect.size.height);
}

@end
