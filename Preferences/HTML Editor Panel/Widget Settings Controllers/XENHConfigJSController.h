//
//  XENHConfigJSController.h
//  
//
//  Created by Matt Clarke on 09/09/2016.
//
//

#import <UIKit/UIKit.h>
#import "XENHConfigJSCell.h"

@interface XENHConfigJSController : UITableViewController <XENHConfigJSDelegate> {
    NSArray *_dataSource;
    NSString *_filePath;
}

// Returns YES if there were any issues.
-(BOOL)parseJSONFile:(NSString*)filePath;
-(void)saveData;
// -(void)cancelData; - this is called "implicitly", as not saving data will cancel it.

@end
