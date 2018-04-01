//
//  XENHConfigJSCell.h
//  
//
//  Created by Matt Clarke on 09/09/2016.
//
//

#import <UIKit/UIKit.h>

@protocol XENHConfigJSDelegate <NSObject>
-(void)textFieldDidChange:(id)value withKey:(NSString*)key;
-(void)switchDidChange:(id)value withKey:(NSString*)key;
@end

@interface XENHConfigJSCell : UITableViewCell <UITextFieldDelegate> {
    NSDictionary *_datum;
}

@property (nonatomic, strong) UISwitch *switchControl;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *commentLabel;
@property (nonatomic, weak) id<XENHConfigJSDelegate> delegate;

-(void)setupWithDatum:(NSDictionary*)datum;

@end
