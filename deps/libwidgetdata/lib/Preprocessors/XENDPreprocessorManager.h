//
//  XENDPreprocessorManager.h
//  Testbed macOS
//
//  Created by Matt Clarke on 12/08/2019.
//  Copyright © 2019 Matt Clarke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XENDPreprocessorManager : NSObject

+ (instancetype)sharedInstance;
- (NSString*)parseDocument:(NSString*)filepath;

@end
