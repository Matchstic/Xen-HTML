//
//  WKWebView_WidgetData.m
//  libwidgetdata
//
//  Created by Matt Clarke on 12/08/2019.
//

#import "WKWebView_WidgetData.h"
#import "XENDHijackedWebViewDelegate.h"
#import "../Preprocessors/XENDPreprocessorManager.h"
#import "../Internal/XENDWidgetManager.h"

#import <objc/runtime.h>

@implementation WKWebView (WidgetData)

- (void)setHijackedNavigationDelegate:(id)object {
    objc_setAssociatedObject(self, @selector(hijackedNavigationDelegate), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)hijackedNavigationDelegate {
    return objc_getAssociatedObject(self, @selector(hijackedNavigationDelegate));
}

- (void)_setHasInjectedRuntime:(BOOL)value {
    objc_setAssociatedObject(self, @selector(_hasInjectedRuntime), [NSNumber numberWithBool:value], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)_hasInjectedRuntime {
    NSNumber *obj = objc_getAssociatedObject(self, @selector(_hasInjectedRuntime));
    return obj ? [obj boolValue] : NO;
}

//////////////////////////////////////////////////////////////////////////////////////////
// Additions for init
//////////////////////////////////////////////////////////////////////////////////////////

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration injectWidgetData:(BOOL)injectWidgetData {
    
    // Inject runtime stuff if required
    if (injectWidgetData) {
        [[XENDWidgetManager sharedInstance] injectRuntime:configuration.userContentController];
        [self _setHasInjectedRuntime:YES];
    }
    
    return [self initWithFrame:frame configuration:configuration];
}

//////////////////////////////////////////////////////////////////////////////////////////
// Swizzling
//////////////////////////////////////////////////////////////////////////////////////////

+ (void)load {
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        // Swizzle loading file URLs
        SEL originalLoadFileURL = @selector(loadFileURL:allowingReadAccessToURL:);
        SEL newLoadFileURL = @selector(xenhtml_loadFileURL:allowingReadAccessToURL:);
        Method originalMethod = class_getInstanceMethod(self, originalLoadFileURL);
        Method extendedMethod = class_getInstanceMethod(self, newLoadFileURL);
        method_exchangeImplementations(originalMethod, extendedMethod);
        
        // Lifecycle events
        SEL originalStopLoading = @selector(stopLoading);
        SEL newStopLoading = @selector(xenhtml_stopLoading);
        Method originalMethod2 = class_getInstanceMethod(self, originalStopLoading);
        Method extendedMethod2 = class_getInstanceMethod(self, newStopLoading);
        method_exchangeImplementations(originalMethod2, extendedMethod2);
    });
}

- (WKNavigation *)xenhtml_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL {
    NSLog(@"DEBUG :: Call into swizzled loadFileURL");
    
    if (![self _hasInjectedRuntime]) {
        NSLog(@"DEBUG :: Returning original implementation");
        
        // Return the original implementation
        return [self xenhtml_loadFileURL:URL allowingReadAccessToURL:readAccessURL];
    } else {
        NSLog(@"DEBUG :: Beginning pre-processing...");
        
        NSString *filePath = [URL path];
        NSURL *baseUrl = [URL URLByDeletingLastPathComponent];
        
        NSString *preprocessedDocument = [[XENDPreprocessorManager sharedInstance] parseDocument:filePath];
        
        // Setup our hijacked navigation delegate if required
        if (![self hijackedNavigationDelegate]) {
            NSLog(@"DEBUG :: Injecting navigation delegate...");
            
            [self setHijackedNavigationDelegate:[[XENDHijackedWebViewDelegate alloc] initWithOriginalDelegate:self.navigationDelegate]];
            
            self.navigationDelegate = [self hijackedNavigationDelegate];
        }
        
        // Register widget
        [[XENDWidgetManager sharedInstance] registerWebView:self];
        
        NSLog(@"DEBUG :: Finished injection");
        
        return [self loadHTMLString:preprocessedDocument baseURL:baseUrl];
    }
}

- (void)xenhtml_stopLoading {
    NSString *url = [self.URL absoluteString];
    NSLog(@"DEBUG :: Unregistering widget presenting from: %@", url);
    
    [[XENDWidgetManager sharedInstance] deregisterWebView:self];
    
    // Call original stopLoading - not a loop ;P
    [self xenhtml_stopLoading];
}


@end
