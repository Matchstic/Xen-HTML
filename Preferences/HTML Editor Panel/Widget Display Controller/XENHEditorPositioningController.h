//
//  XENHEditorPositioningController.h
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 25/01/2018.
//

#import <UIKit/UIKit.h>

@protocol XENHEditorPositioningDelegate <NSObject>
- (void)didUpdatePositioningWithX:(CGFloat)x andY:(CGFloat)y;
@end

@interface XENHEditorPositioningController : UIViewController

- (instancetype)initWithDelegate:(id<XENHEditorPositioningDelegate>)delegate shouldSnapToGuides:(BOOL)snapToGuides andPositioningView:(UIView*)posView;

- (void)updatePositioningView:(UIView*)posView;

@end
