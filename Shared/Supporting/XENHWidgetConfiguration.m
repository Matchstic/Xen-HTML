//
//  XENHWidgetConfiguration.m
//  Xen HTML
//
//  Created by Matt Clarke on 18/05/2020.
//

#import "XENHWidgetConfiguration.h"

#define orient3 [[UIApplication sharedApplication] statusBarOrientation]

#define SCREEN_MAX_LENGTH (MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height))
#define SCREEN_MIN_LENGTH (MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height))

#define SCREEN_HEIGHT (orient3 == 1 || orient3 == 2 ? SCREEN_MAX_LENGTH : SCREEN_MIN_LENGTH)
#define SCREEN_WIDTH (orient3 == 1 || orient3 == 2 ? SCREEN_MIN_LENGTH : SCREEN_MAX_LENGTH)

@interface XENHWidgetConfiguration ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *lastPathComponent;

@end

@implementation XENHWidgetConfiguration

+ (instancetype)defaultConfigurationForPath:(NSString*)path {
    return [[XENHWidgetConfiguration alloc] initWithFilePath:path];
}

+ (instancetype)configurationFromDictionary:(NSDictionary*)dictionary {
    return [[XENHWidgetConfiguration alloc] initWithDictionary:dictionary];
}

- (NSDictionary*)serialise {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    [result setObject:@(self.height) forKey:@"height"];
    [result setObject:@(self.width) forKey:@"width"];
    [result setObject:@(self.x) forKey:@"x"];
    [result setObject:@(self.y) forKey:@"y"];
    [result setObject:@(self.xLandscape) forKey:@"xLandscape"];
    [result setObject:@(self.yLandscape) forKey:@"yLandscape"];
    [result setObject:self.options ? self.options : @{} forKey:@"options"];
    [result setObject:@(self.isFullscreen) forKey:@"isFullscreen"];
    [result setObject:@(self.widgetCanScroll) forKey:@"widgetCanScroll"];
    [result setObject:@(self.useFallback) forKey:@"useFallback"];
    
    return result;
}

#pragma mark - Init

- (instancetype)initWithFilePath:(NSString*)filePath {
    self = [super init];
    
    if (self) {
        self.path = [filePath stringByDeletingLastPathComponent];
        self.lastPathComponent = [filePath lastPathComponent];
        
        [self loadSize];
        [self loadOptions];
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    
    if (self) {
        self.height = [[dictionary objectForKey:@"height"] floatValue];
        self.width = [[dictionary objectForKey:@"width"] floatValue];
        self.x = [[dictionary objectForKey:@"x"] floatValue];
        self.y = [[dictionary objectForKey:@"y"] floatValue];
        
        self.isFullscreen = [[dictionary objectForKey:@"isFullscreen"] boolValue];
        self.widgetCanScroll = [[dictionary objectForKey:@"widgetCanScroll"] boolValue];
        self.useFallback = [[dictionary objectForKey:@"useFallback"] boolValue];
        self.options = [dictionary objectForKey:@"options"];
    }
    
    return self;
}

#pragma mark - Size loading

- (void)loadSize {
    if ([self loadSizeFromConfigJSON])
        return;
    else if ([self loadSizeFromWidgetPlist])
        return;
    else if ([self loadSizeFromWidgetInfoPlist])
        return;
    
    // Load default since the others all failed
    [self loadDefaultSize];
}

- (BOOL)loadSizeFromConfigJSON {
    // Only load from the central widgets location
    if ([self.path rangeOfString:@"/var/mobile/Library/Widgets"].location == NSNotFound)
        return NO;
    
    NSString *configPath = [self.path stringByAppendingString:@"/config.json"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:configPath]) {
        
        // Load from config.json
        NSError *error;
        NSDictionary *config = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:configPath] options:kNilOptions error:&error];
        
        CGFloat (^toReal)(NSString *string, NSString *max, int mode) = ^(NSString *string, NSString *max, int mode) {
            CGFloat result = 0.0;
            CGFloat modeWidth = mode == 0 ? SCREEN_WIDTH : SCREEN_HEIGHT;
            
            if ([string hasSuffix:@"%"]) {
                // Percentage of the screen size
                CGFloat percentage = [[string stringByReplacingOccurrencesOfString:@"%" withString:@""] floatValue];
                result = modeWidth * (percentage / 100.0);
            } else {
                // Exact points
                CGFloat exact = [[string stringByReplacingOccurrencesOfString:@"px" withString:@""] floatValue];
                result = exact;
            }
            
            // Handle max size
            if (max) {
                CGFloat maxSize = [[max stringByReplacingOccurrencesOfString:@"px" withString:@""] floatValue];
                if (maxSize < result) result = maxSize;
            }
            
            return result;
        };
        
        NSDictionary *size = [config objectForKey:@"size"];
        
        if (size) {
            NSString *width = [size objectForKey:@"width"];
            NSString *maxwidth = [size objectForKey:@"max-width"];
            NSString *height = [size objectForKey:@"height"];
            NSString *maxheight = [size objectForKey:@"max-height"];
            
            // Compute width first
            if (width) {
                CGFloat requested = toReal(width, maxwidth, 0);
                self.width = requested;
            } else {
                self.width = SCREEN_WIDTH;
            }
            
            if (height) {
                CGFloat requested = toReal(height, maxheight, 1);
                self.height = requested;
            } else {
                self.height = SCREEN_HEIGHT;
            }
            
            self.x = 0.0;
            self.y = 0.0;
            self.widgetCanScroll = NO;
            
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)loadSizeFromWidgetPlist {
    // Allow loading from the central location, or if we're loading Widget.html
    BOOL allowLoading = [self.path rangeOfString:@"/var/mobile/Library/Widgets"].location != NSNotFound || [self.lastPathComponent isEqualToString:@"Widget.html"];
    
    if (!allowLoading)
        return NO;
    
    NSString *widgetPlistPath = [self.path stringByAppendingString:@"/Widget.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:widgetPlistPath]) {
        self.isFullscreen = NO;
        
        NSDictionary *widgetPlist = [NSDictionary dictionaryWithContentsOfFile:widgetPlistPath];
        NSDictionary *size = [widgetPlist objectForKey:@"size"];
        
        if (size) {
            CGFloat width = [[size objectForKey:@"width"] floatValue];
            self.width = width;
            
            CGFloat height = [[size objectForKey:@"height"] floatValue];
            self.height = height;
        } else {
            self.width = SCREEN_WIDTH;
            self.height = SCREEN_HEIGHT;
        }

        self.x = 0.0;
        self.y = 0.0;
        self.widgetCanScroll = NO;
        
        return YES;
    }
    
    return NO;
}

- (BOOL)loadSizeFromWidgetInfoPlist {
    NSString *widgetInfoPlistPath = [self.path stringByAppendingString:@"/WidgetInfo.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:widgetInfoPlistPath]) {
        // Handle WidgetInfo.plist
        // This can be loaded for ANY HTML widget, which is neat.
        
        NSDictionary *widgetPlist = [NSDictionary dictionaryWithContentsOfFile:widgetInfoPlistPath];
        NSDictionary *size = [widgetPlist objectForKey:@"size"];
        id isFullscreenVal = [widgetPlist objectForKey:@"isFullscreen"];
        
        // Fullscreen.
        self.isFullscreen = (isFullscreenVal ? [isFullscreenVal boolValue] : YES);
        
        if (size && !self.isFullscreen) {
            CGFloat width = [[size objectForKey:@"width"] floatValue];
            self.width = width;
            
            CGFloat height = [[size objectForKey:@"height"] floatValue];
            self.height = height;
        } else {
            self.width = SCREEN_WIDTH;
            self.height = SCREEN_HEIGHT;
        }
        
        // Default widget position
        self.x = 0.0;
        self.y = 0.0;
        
        // Does the widget scroll?
        id allowScroll = [widgetPlist objectForKey:@"widgetCanScroll"];
        self.widgetCanScroll = allowScroll ? [allowScroll boolValue] : NO;
        
        return YES;
    }
    
    return NO;
}

- (void)loadDefaultSize {
    self.isFullscreen = YES;
    self.width = SCREEN_WIDTH;
    self.height = SCREEN_HEIGHT;
    self.x = 0.0;
    self.y = 0.0;
    self.widgetCanScroll = NO;
}

#pragma mark - Widget options

- (void)loadOptions {
    // Default to not using legacy mode
    self.useFallback = NO;
    self.widgetCanScroll = NO;
    
    if ([self loadOptionsPlist])
        return;
    
    [self loadDefaultOptions];
}

+ (BOOL)shouldAllowOptionsPlist:(NSString*)filepath {
    NSString *path = [filepath stringByDeletingLastPathComponent];
    
    NSString *widgetInfoPlistPath = [path stringByAppendingString:@"/WidgetInfo.plist"];
    BOOL isWidgetHTML = [path rangeOfString:@"iWidgets"].location != NSNotFound;
    BOOL isCentralLocation = [path rangeOfString:@"/var/mobile/Library/Widgets"].location != NSNotFound;
    
    return isWidgetHTML || [[NSFileManager defaultManager] fileExistsAtPath:widgetInfoPlistPath] || isCentralLocation;
}

- (BOOL)loadOptionsPlist {
    NSString *widgetInfoPlistPath = [self.path stringByAppendingString:@"/WidgetInfo.plist"];
    BOOL isWidgetHTML = [self.path rangeOfString:@"iWidgets"].location != NSNotFound;
    BOOL isCentralLocation = [self.path rangeOfString:@"/var/mobile/Library/Widgets"].location != NSNotFound;
    
    BOOL allowLoading = isWidgetHTML || [[NSFileManager defaultManager] fileExistsAtPath:widgetInfoPlistPath] || isCentralLocation;
    
    if (!allowLoading) return NO;
    
    NSString *optionsPath = [self.path stringByAppendingString:@"/Options.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:optionsPath]) {
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        
        
        NSArray *optionsPlist = [NSArray arrayWithContentsOfFile:optionsPath];
        
        for (NSDictionary *option in optionsPlist) {
            NSString *name = [option objectForKey:@"name"];
            
            // Options.plist will contain the following types:
            // edit
            // select
            // switch
            
            id value = nil;
            
            NSString *type = [option objectForKey:@"type"];
            if ([type isEqualToString:@"select"]) {
                NSString *defaultKey = [option objectForKey:@"default"];
                
                value = [[option objectForKey:@"options"] objectForKey:defaultKey];
            } else if ([type isEqualToString:@"switch"]) {
                value = [option objectForKey:@"default"];
            } else {
                value = [option objectForKey:@"default"];
            }
            
            [options setValue:value forKey:name];
        }
        
        self.options = options;
        
        return YES;
    }
    
    return NO;
}

- (void)loadDefaultOptions {
    self.options = @{};
}

@end
