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

#import "XENHPickerPreviewController2.h"
#import "XENHResources.h"

@interface WKPreferences (Private)
- (void)_setAllowFileAccessFromFileURLs:(BOOL)arg1;
- (void)_setAntialiasedFontDilationEnabled:(BOOL)arg1;
- (void)_setCompositingBordersVisible:(BOOL)arg1;
- (void)_setCompositingRepaintCountersVisible:(BOOL)arg1;
- (void)_setDeveloperExtrasEnabled:(BOOL)arg1;
- (void)_setDiagnosticLoggingEnabled:(BOOL)arg1;
- (void)_setFullScreenEnabled:(BOOL)arg1;
- (void)_setJavaScriptRuntimeFlags:(unsigned int)arg1;
- (void)_setLogsPageMessagesToSystemConsoleEnabled:(BOOL)arg1;
- (void)_setOfflineApplicationCacheIsEnabled:(BOOL)arg1;
- (void)_setSimpleLineLayoutDebugBordersEnabled:(BOOL)arg1;
- (void)_setStandalone:(BOOL)arg1;
- (void)_setStorageBlockingPolicy:(int)arg1;
- (void)_setTelephoneNumberDetectionIsEnabled:(BOOL)arg1;
- (void)_setTiledScrollingIndicatorVisible:(BOOL)arg1;
- (void)_setVisibleDebugOverlayRegions:(unsigned int)arg1;
@end

@interface WKWebView (IOS9)
- (id)loadFileURL:(id)arg1 allowingReadAccessToURL:(id)arg2;
@end

@interface UIView (iOS11)
@property (nonatomic, readonly) UIEdgeInsets safeAreaInsets;
@end

@interface XENHPickerPreviewController2 ()

@end

@implementation XENHPickerPreviewController2

-(instancetype)initWithURL:(NSString*)url {
    self = [super init];
    
    if (self) {
        _url = url;
        _metadata = [self rawMetadataForHTMLFile:url];
    }
    
    return self;
}

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    // Add web view.
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    
    NSString *source1 = @"var style = document.createElement('style'); \
    style.type = 'text/css'; \
    style.innerText = '*:not(input):not(textarea) { -webkit-user-select: none; -webkit-touch-callout: none; } body { background-color: transparent; }'; \
    var head = document.getElementsByTagName('head')[0];\
    head.appendChild(style);";
    WKUserScript *stopCallouts = [[WKUserScript alloc] initWithSource:source1 injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    
    NSString *source2 = @"var doc = document.documentElement; \
    var meta = document.createElement('meta'); \
    meta.name = 'viewport'; \
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, shrink-to-fit=yes'; \
    var head = document.head; \
    if (!head) { head = document.createElement('head'); doc.appendChild(head); } \
    head.appendChild(meta);";
    WKUserScript *stopScaling = [[WKUserScript alloc] initWithSource:source2 injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    
    NSString *source3 = @"var oImg = document.createElement('img'); \
    oImg.setAttribute('src', 'file:///var/mobile/Library/Caches/com.apple.Preferences/xen_wallpaperCache.png'); \
    oImg.setAttribute('alt', 'na'); \
    oImg.setAttribute('height', '100%'); \
    oImg.setAttribute('width', '100%'); \
    oImg.style.cssText = 'position:fixed;top:0px;left:0px;width:100%;height:100%;z-index:-100'; \
    document.body.appendChild(oImg); \
    document.body.style.WebKitAnimation = '';\
    document.body.style.opacity = 1.0;";
    WKUserScript *wallpaper = [[WKUserScript alloc] initWithSource:source3 injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    
    [userContentController addUserScript:stopCallouts];
    [userContentController addUserScript:stopScaling];
    [userContentController addUserScript:wallpaper];
    
    config.userContentController = userContentController;
    config.requiresUserActionForMediaPlayback = YES;
    
    WKPreferences *preferences = [[WKPreferences alloc] init];
    [preferences _setAllowFileAccessFromFileURLs:YES];
    [preferences _setFullScreenEnabled:YES];
    [preferences _setOfflineApplicationCacheIsEnabled:YES];
    [preferences _setStandalone:YES];
    [preferences _setTelephoneNumberDetectionIsEnabled:NO];
    [preferences _setTiledScrollingIndicatorVisible:NO];
    
    config.preferences = preferences;
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    _webView.userInteractionEnabled = NO;
    _webView.clipsToBounds = YES;
    
    [self.view addSubview:_webView];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Begin loading the webview.
    NSURL *url = [NSURL fileURLWithPath:_url isDirectory:NO];
    if (url) {
        [self.webView loadFileURL:url allowingReadAccessToURL:[NSURL fileURLWithPath:@"/" isDirectory:YES]];
    }
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Layout the webview.
    
    if (!IS_IPAD) {
        // First, we need to know how much of the device's height has been taken up by the navbar and status bar.
        CGFloat missingHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        missingHeight += self.navigationController.navigationBar.frame.size.height;
        
        // Calculate ratio to apply to the width.
        CGFloat ratio = ([UIScreen mainScreen].bounds.size.height - missingHeight) / [UIScreen mainScreen].bounds.size.height;
    
        self.webView.bounds = [UIScreen mainScreen].bounds;
        self.webView.transform = CGAffineTransformMakeScale(ratio, ratio);
    
        self.webView.frame = CGRectMake((self.view.frame.size.width - self.webView.frame.size.width)/2, missingHeight/2, self.webView.frame.size.width, self.webView.frame.size.height);
    } else {
        CGFloat fullheight = [UIScreen mainScreen].bounds.size.height;
        CGFloat currentHeight = self.view.bounds.size.height - self.navigationController.navigationBar.frame.size.height;
        
        CGFloat ratio = currentHeight / fullheight;
        
        self.webView.bounds = [UIScreen mainScreen].bounds;
        self.webView.transform = CGAffineTransformMakeScale(ratio, ratio);
        
        self.webView.frame = CGRectMake((self.view.frame.size.width - self.webView.frame.size.width)/2, self.navigationController.navigationBar.frame.size.height - 10.0, self.webView.frame.size.width, self.webView.frame.size.height);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self navigationItem] setTitle:[XENHResources localisedStringForKey:@"WIDGETS_PREVIEW_HEADER"]];
}

-(void)dealloc {
    [self.webView stopLoading];
    
    [self.webView removeFromSuperview];
    self.webView = nil;
}

-(NSDictionary*)rawMetadataForHTMLFile:(NSString*)filePath {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // First, check if this is an iWidget.
    // If so, we can fill in the size from Widget.plist
    // Also, we can fill in default values from Options.plist if available, and then re-populate with user set values.
    NSString *path = [filePath stringByDeletingLastPathComponent];
    NSString *lastPathComponent = [filePath lastPathComponent];
    
    NSString *widgetPlistPath = [path stringByAppendingString:@"/Widget.plist"];
    NSString *widgetInfoPlistPath = [path stringByAppendingString:@"/WidgetInfo.plist"];
    NSString *optionsPath = [path stringByAppendingString:@"/Options.plist"];
    
    // Only check Widget.plist if we're loading an iWidget
    if ([lastPathComponent isEqualToString:@"Widget.html"] && [[NSFileManager defaultManager] fileExistsAtPath:widgetPlistPath]) {
        [dict setValue:@NO forKey:@"isFullscreen"];
        
        NSDictionary *widgetPlist = [NSDictionary dictionaryWithContentsOfFile:widgetPlistPath];
        NSDictionary *size = [widgetPlist objectForKey:@"size"];
        
        if (size) {
            [dict setValue:[size objectForKey:@"width"] forKey:@"width"];
            [dict setValue:[size objectForKey:@"height"] forKey:@"height"];
        } else {
            [dict setValue:[NSNumber numberWithFloat:SCREEN_WIDTH] forKey:@"width"];
            [dict setValue:[NSNumber numberWithFloat:SCREEN_HEIGHT] forKey:@"height"];
        }
        
        // Ignore the initial position of the widget, as it's fundamentally not compatible with
        // how we do positioning. Plus, I'm lazy and it's close to release day.
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"x"];
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"y"];
        
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:widgetInfoPlistPath]) {
        // Handle WidgetInfo.plist
        // This can be loaded for ANY HTML widget, which is neat.
        
        
        NSDictionary *widgetPlist = [NSDictionary dictionaryWithContentsOfFile:widgetInfoPlistPath];
        NSDictionary *size = [widgetPlist objectForKey:@"size"];
        id isFullscreenVal = [widgetPlist objectForKey:@"isFullscreen"];
        
        // Fullscreen.
        BOOL isFullscreen = (isFullscreenVal ? [isFullscreenVal boolValue] : YES);
        [dict setValue:[NSNumber numberWithBool:isFullscreen] forKey:@"isFullscreen"];
        
        if (size && !isFullscreen) {
            [dict setValue:[size objectForKey:@"width"] forKey:@"width"];
            [dict setValue:[size objectForKey:@"height"] forKey:@"height"];
        } else {
            [dict setValue:[NSNumber numberWithFloat:SCREEN_WIDTH] forKey:@"width"];
            [dict setValue:[NSNumber numberWithFloat:SCREEN_HEIGHT] forKey:@"height"];
        }
        
        // Default widget position
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"x"];
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"y"];
    } else {
        [dict setValue:@YES forKey:@"isFullscreen"];
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"x"];
        [dict setValue:[NSNumber numberWithFloat:0.0] forKey:@"y"];
        [dict setValue:[NSNumber numberWithFloat:SCREEN_WIDTH] forKey:@"width"];
        [dict setValue:[NSNumber numberWithFloat:SCREEN_HEIGHT] forKey:@"height"];
    }
    
    // Next, we handle default options.
    // If Widget.html is being loaded, or WidgetInfo.plist exists, load up the Options.plist and add into metadata.
    
    // TODO: Handle cases where there is ONLY an Options.plist in a non-iWidget.
    
    
    if (([lastPathComponent isEqualToString:@"Widget.html"] || [[NSFileManager defaultManager] fileExistsAtPath:widgetInfoPlistPath]) && [[NSFileManager defaultManager] fileExistsAtPath:optionsPath]) {
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        
        
        NSArray *optionsPlist = [NSArray arrayWithContentsOfFile:optionsPath];
        
        for (NSDictionary *option in optionsPlist) {
            NSString *name = [option objectForKey:@"name"];
            
            /* Options.plist will contain the following types:
             edit
             select
             switch
             */
            
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
        
        [dict setValue:options forKey:@"options"];
    } else {
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [dict setValue:options forKey:@"options"];
    }
    
    return dict;
}

@end
