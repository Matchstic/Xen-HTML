//
//  XENHPreviewScaledController.h
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 26/01/2018.
//

#import <UIKit/UIKit.h>

@interface XENHPreviewScaledController : UIViewController

@property (nonatomic, strong) UIViewController *containedViewController;

- (void)fitToSize;
- (void)setContainedViewController:(UIViewController *)containedViewController previewHeight:(CGFloat)previewHeight;

@end
