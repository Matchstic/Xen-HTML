//
//  XENHPickerPreviewController2.h
//  Xen
//
//  Created by Matt Clarke on 27/02/2017.
//
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface XENHPickerPreviewController2 : UIViewController {
    NSString *_url;
    NSDictionary *_metadata;
}

@property (nonatomic, strong) WKWebView *webView;

-(instancetype)initWithURL:(NSString*)url;

@end
