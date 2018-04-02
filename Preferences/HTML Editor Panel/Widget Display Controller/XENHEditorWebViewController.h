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

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

typedef enum : NSUInteger {
    kVariantLockscreenBackground = 0,
    kVariantLockscreenForeground = 1,
    kVariantHomescreenBackground = 2
} XENHEditorWebViewVariant;

@interface XENHEditorWebViewController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler>

// Public access for positioning.
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, readwrite) XENHEditorWebViewVariant webviewVariant;

- (instancetype)initWithVariant:(XENHEditorWebViewVariant)webViewVariant showNoHTMLLabel:(BOOL)enableShowNoHTML;

- (void)reloadWebViewToPath:(NSString*)path updateMetadata:(BOOL)shouldSetMetadata ignorePreexistingMetadata:(BOOL)ignorePreexistingMetadata;

// Utility methods.
- (NSDictionary*)getMetadata;
- (void)setMetadata:(NSDictionary*)metadata reloadingWebView:(BOOL)reloadWebView;
- (BOOL)hasHTML;
- (NSString*)getCurrentWidgetURL;

@end
