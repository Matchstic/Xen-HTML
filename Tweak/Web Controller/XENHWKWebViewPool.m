/*
 Copyright (C) 2019  Matt Clarke
 
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

#import "XENHWKWebViewPool.h"
#import "PrivateWebKitHeaders.h"
#import "XENHResources.h"

@interface XENHWKWebViewPool ()
@property (nonatomic, strong) NSMutableArray *webViewQueue;
@end

@implementation XENHWKWebViewPool

+ (instancetype)sharedInstance {
    static XENHWKWebViewPool *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.webViewQueue = [@[] mutableCopy];
    }
    
    return self;
}

- (WKWebView*)dequeueWebView {
    // Empty queue case
    if (self.webViewQueue.count == 0)
        return [self _createWebView];
    
    // Dequeue as required
    WKWebView *head = [self.webViewQueue firstObject];
    if (head)
        [self.webViewQueue removeObjectAtIndex:0];
    
    return head;
}

- (void)enqueueWebView:(WKWebView*)webView {
    [webView stopLoading];
    webView.hidden = YES;
    
    // Clear userscripts on this webview, and ensure we're pointing at about:blank
    [webView.configuration.userContentController removeAllUserScripts];
    [webView loadHTMLString:@"" baseURL:[NSURL URLWithString:@"about:blank"]];
    
    // [webView _close];
    
    [self.webViewQueue addObject:webView];
}

- (WKWebView*)_createWebView {
    return [[WKWebView alloc] initWithFrame:CGRectZero configuration:[self _defaultConfiguration]];
}

- (WKWebViewConfiguration*)_defaultConfiguration {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    
    config.userContentController = [[WKUserContentController alloc] init];
    config.requiresUserActionForMediaPlayback = NO;
    
    // Configure some private settings on WKWebView
    WKPreferences *preferences = [[WKPreferences alloc] init];
    [preferences _setAllowFileAccessFromFileURLs:YES];
    [preferences _setFullScreenEnabled:YES];
    [preferences _setOfflineApplicationCacheIsEnabled:YES]; // Local storage is needed for Lock+ etc.
    [preferences _setStandalone:YES];
    [preferences _setTelephoneNumberDetectionIsEnabled:NO];
    [preferences _setTiledScrollingIndicatorVisible:NO];
    
    // Developer tools
    if ([XENHResources developerOptionsEnabled]) {
        [preferences _setDeveloperExtrasEnabled:YES];
        
        [preferences _setResourceUsageOverlayVisible:[XENHResources showResourceUsageInWidgets]];
        [preferences _setCompositingBordersVisible:[XENHResources showCompositingBordersInWidgets]];
    }
    
    config.preferences = preferences;
    
    if ([XENHResources isAtLeastiOSVersion:11 subversion:0]) {
        [config _setWaitsForPaintAfterViewDidMoveToWindow:YES];
    }
    
    return config;
}

@end
