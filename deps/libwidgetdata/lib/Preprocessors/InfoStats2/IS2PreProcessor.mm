//
//  IS2PreProcessor.mm
//  libwidgetdata
//
//  Created by Matt Clarke on 27/12/2018.
//  Copyright © 2018 Matt Clarke. All rights reserved.
//

#import "IS2PreProcessor.h"
#include "Compile.hpp"

@interface IS2PreProcessor ()
@end

@implementation IS2PreProcessor

- (NSString*)parseScriptNodeContents:(NSString*)contents withAttributes:(NSDictionary*)attributes {
    // Ensure that this is Cycript
    BOOL isCycriptType = NO;
    
    if ([attributes.allKeys containsObject:@"type"]) {
        isCycriptType = [attributes[@"type"] isEqualToString:@"text/cycript"];
    }
    
    if (!isCycriptType) return contents;
    
    // Compile cycript to ES5
    std::string result = Compile([contents cStringUsingEncoding:NSUTF8StringEncoding], true, false);
    return [NSString stringWithUTF8String:result.c_str()];
}

@end
