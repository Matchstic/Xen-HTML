//
//  XENDPreprocessorManager.m
//  Testbed macOS
//
//  Created by Matt Clarke on 12/08/2019.
//  Copyright © 2019 Matt Clarke. All rights reserved.
//

#import "XENDPreprocessorManager.h"
#import "XENDPreProcessor-Protocol.h"
#import "InfoStats2/IS2PreProcessor.h"
#import "XenInfo/XIPreProcessor.h"
#import <ObjectiveGumbo/ObjectiveGumbo.h>

@interface XENDPreprocessorManager ()
@property (nonatomic, strong) NSString *baseDocumentPath;
@property (nonatomic, strong) NSArray* preprocessors;
@end

@implementation XENDPreprocessorManager

+ (instancetype)sharedInstance {
    static XENDPreprocessorManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[XENDPreprocessorManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.preprocessors = [self _createPreprocessors];
    }
    
    return self;
}

- (NSArray*)_createPreprocessors {
    NSMutableArray *array = [NSMutableArray array];
    
    IS2PreProcessor *is2Preprocessor = [[IS2PreProcessor alloc] init];
    [array addObject:is2Preprocessor];
    
    XIPreProcessor *xiPreprocessor = [[XIPreProcessor alloc] init];
    [array addObject:xiPreprocessor];
    
    return array;
}

- (NSString*)parseDocument:(NSString*)filepath {
    self.baseDocumentPath = [filepath stringByDeletingLastPathComponent];
    
    NSError *error;
    NSString *html = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error loading HTML: %@", error);
        return @"";
    }
    
    OGElement *document = (OGElement*)[ObjectiveGumbo parseNodeWithString:html];
    
    if (!document) {
        NSLog(@"Error parsing HTML, no document from ObjectiveGumbo");
        return @"";
    }
    
    // Parse all script sections
    document = [self _parseNodes:document];
    
    return [document html];
}

- (OGElement*)_parseNodes:(OGElement*)document {
    // loop over head and body.
    NSArray *scriptNodes = [document elementsWithTag:GUMBO_TAG_SCRIPT];
    
    for (OGElement *scriptNode in scriptNodes) {
        
        // Check if we need to load from an external file
        NSString *externalFileReference = nil;
        if ([scriptNode.attributes.allKeys containsObject:@"src"])
            externalFileReference = [scriptNode.attributes objectForKey:@"src"];
        
        // Load content
        NSString *content;
        
        if (externalFileReference != nil) {
            // Handle reading from correct file
            NSString *externalFilepath = [NSString stringWithFormat:@"%@/%@", self.baseDocumentPath, externalFileReference];
            
            NSLog(@"DEBUG :: Loading script src from %@", externalFilepath);
            
            content = [NSString stringWithContentsOfFile:externalFilepath encoding:NSUTF8StringEncoding error:nil];
        } else {
            // Read element contents
            for (OGText *textNode in scriptNode.children) {
                if (!textNode.isText)
                    continue;
                
                content = textNode.text;
                break;
            }
        }
        
        // For each preprocessor, do transformations on the script text content
        for (id preprocesor in self.preprocessors) {
            content = [preprocesor parseScriptNodeContents:content withAttributes:scriptNode.attributes];
        }
        
        OGText *textNode = [[OGText alloc] initWithText:content andType:GUMBO_NODE_TEXT];
        scriptNode.children = @[textNode]; // Reset children
        scriptNode.attributes = @{}; // Reset attributes
    }
    
    return document;
}

@end
