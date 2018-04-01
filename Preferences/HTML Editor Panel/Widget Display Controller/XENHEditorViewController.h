//
//  XENHEditorViewController.h
//  XenHTMLPrefs
//
//  Created by Matt Clarke on 25/01/2018.
//

#import <UIKit/UIKit.h>
#import <Preferences/PSViewController.h>
#import "XENHEditorToolbarController.h"
#import "XENHEditorPositioningController.h"
#import "XENHPickerController2.h"

typedef enum : NSUInteger {
    kEditorVariantLockscreenBackground = 0,
    kEditorVariantLockscreenForeground = 1,
    kEditorVariantHomescreenBackground = 2
} XENHEditorVariant;

@interface XENHEditorViewController : PSViewController <XENHEditorToolbarDelegate, XENHEditorPositioningDelegate, XENHPickerDelegate2>

- (instancetype)initWithVariant:(XENHEditorVariant)variant;

@end
