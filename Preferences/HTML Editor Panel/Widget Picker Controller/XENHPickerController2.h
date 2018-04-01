//
//  XENHPickerController2.h
//  Xen
//
//  Created by Matt Clarke on 26/02/2017.
//
//

#import <UIKit/UIKit.h>

@protocol XENHPickerDelegate2 <NSObject>
-(void)didChooseWidget:(NSString*)filePath;
-(void)cancelShowingPicker;
@end

@interface XENHPickerController2 : UITableViewController {
    int _variant;
    id<XENHPickerDelegate2> _delegate;
    NSArray *_sbhtmlArray;
    NSArray *_lockHTMLArray;
    NSArray *_groovylockArray;
    NSArray *_cydgetBackgroundArray;
    NSArray *_cydgetForegroundArray;
    NSArray *_winterboardArray;
    NSArray *_iwidgetsArray;
    
    NSString *_currentSelected;
}

-(id)initWithVariant:(int)variant andDelegate:(id<XENHPickerDelegate2>)delegate andCurrentSelected:(NSString*)current;

@end
