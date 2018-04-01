//
//  XENHMetadataOptionsController.h
//  
//
//  Created by Matt Clarke on 08/09/2016.
//
//

#import <Preferences/PSListController.h>

@interface XENHMetadataOptionsController : PSListController {
    NSMutableDictionary *_options;
    NSArray *_plist;
}

-(instancetype)initWithOptions:(NSDictionary*)options andPlist:(NSArray*)plist;
-(NSDictionary*)currentOptions;

@end
