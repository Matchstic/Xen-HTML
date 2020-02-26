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

#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>
#import "XENHTouchPassThroughView.h"
#import "XENHButton.h"
#import "XENHCloseButton.h"

#import "XENHWidgetEditingDelegate.h"

@interface XENHWidgetController : UIViewController <WKNavigationDelegate, XENHTouchPassThroughViewDelegate, WKUIDelegate>

// Internal webviews
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIWebView *legacyWebView;
@property (nonatomic, readwrite) BOOL requiresJITWidgetLoad;

// Widget-specific data
@property (nonatomic, strong) NSString *widgetIndexFile;
@property (nonatomic, strong) NSString *_rawWidgetIndexFile;
@property (nonatomic, strong) NSDictionary *widgetMetadata;
@property (nonatomic, readwrite) BOOL usingLegacyWebView;

// Touch forwarding
@property (nonatomic, strong) UIView *_touchForwardedView;

// Offscreen rendering
@property (nonatomic, strong) UIView *_offscreenRenderingView;
@property (nonatomic, readwrite) BOOL _hasMovedWebViewOnscreen;

// Editing
@property (nonatomic, weak) id<XENHWidgetEditingDelegate> editingDelegate;
@property (nonatomic, readwrite) BOOL isEditing;

// Initialisation
- (instancetype)init;

// Configuration
- (void)configureWithWidgetIndexFile:(NSString*)widgetIndexFile andMetadata:(NSDictionary*)metadata;

// Orientation handling
-(void)rotateToOrientation:(int)orient;

// Pause handling
-(void)setPaused:(BOOL)paused;
-(void)setPaused:(BOOL)paused animated:(BOOL)animated;

// Editing mode (for iWidgets mode)
- (void)setEditing:(BOOL)editing;

// Lifecycle handling
- (void)unloadWidget;
- (void)reloadWidget;
- (void)doJITWidgetLoadIfNecessary;
- (void)didReceiveMemoryWarningExternal;

// Touch forwarding
- (BOOL)isWidgetTrackingTouch;
- (UIView*)hitTestForEvent:(UIEvent *)event;
- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer*)arg1 atLocation:(CGPoint)location;
- (void)forwardTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)forwardTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
