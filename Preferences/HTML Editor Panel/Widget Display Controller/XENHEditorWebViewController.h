//
//  XENHEditorWebViewController.h
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 25/01/2018.
//

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
