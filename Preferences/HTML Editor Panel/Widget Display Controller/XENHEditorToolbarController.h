//
//  XENHTMLEditorToolbarController.h
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 25/01/2018.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kButtonCancel,
    kButtonModify,
    kButtonAccept,
    kButtonSettings
} XENHEditorToolbarButton;

@protocol XENHEditorToolbarDelegate <NSObject>
- (void)toolbarDidPressButton:(XENHEditorToolbarButton)button;
@end

@interface XENHEditorToolbarController : UIViewController

- (instancetype)initWithDelegate:(id<XENHEditorToolbarDelegate>)delegate;

@end
