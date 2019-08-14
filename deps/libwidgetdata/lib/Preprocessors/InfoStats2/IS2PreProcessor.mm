//
//  IS2PreProcessor.mm
//  libwidgetdata
//
//  Created by Matt Clarke on 27/12/2018.
//  Copyright © 2018 Matt Clarke. All rights reserved.
//

#import "IS2PreProcessor.h"
#import <ObjectiveGumbo/ObjectiveGumbo.h>

#include "Compile.hpp"

// Absolute file paths to js libraries (NOT CYCRIPT) to inject
static NSArray *injectLibraries = @[@"/Users/matt/Downloads/test-is2-update/test.js"];

@interface IS2PreProcessor ()
@property (nonatomic, strong) NSString *baseDocumentPath;
@end

@implementation IS2PreProcessor

- (NSString*)parseDocument:(NSString*)filepath {
    self.baseDocumentPath = [filepath stringByDeletingLastPathComponent];
    
    NSError *error;
    NSString *html = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error loading HTML: %@", error);
        return @"";
    }
    
    OGElement *document = (OGElement*)[ObjectiveGumbo parseNodeWithString:html];
    
    if (error) {
        NSLog(@"Error parsing HTML: %@", error);
        return @"";
    }
    
    // Parse Cycript sections -> ES5
    document = [self _parseCycriptNodes:document];
    
    // Inject libraries
    document = [self _injectRuntimeLibraries:document];
    
    return [document html];
}

- (OGElement*)_parseCycriptNodes:(OGElement*)document {
    // loop over head and body.
    NSArray *scriptNodes = [document elementsWithTag:GUMBO_TAG_SCRIPT];
        
    for (OGElement *scriptNode in scriptNodes) {
        // if this node has type="text/cycript", then it needs to be compiled.
        // may be an external file reference to compile - see src attribute
        
        BOOL isCycriptType = NO;
        NSString *externalFileReference = nil;
        
        for (NSString *key in scriptNode.attributes.allKeys) {
            if ([key isEqualToString:@"type"] &&
                [scriptNode.attributes[key] isEqualToString:@"text/cycript"]) {
                isCycriptType = YES;
            }
            
            if ([key isEqualToString:@"src"]) {
                externalFileReference = scriptNode.attributes[key];
            }
        }
        
        if (isCycriptType) {
            NSString *content;
            
            if (externalFileReference != nil) {
                // Handle reading from correct file
                NSString *externalFilepath = [NSString stringWithFormat:@"%@/%@", self.baseDocumentPath, externalFileReference];
                
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
            
            // Compile cycript to ES5
            std::string result = Compile([content cStringUsingEncoding:NSUTF8StringEncoding], true, false);
            
            content = [NSString stringWithUTF8String:result.c_str()];
            
            OGText *textNode = [[OGText alloc] initWithText:content andType:GUMBO_NODE_TEXT];
            scriptNode.children = @[textNode]; // Reset children
            scriptNode.attributes = @{}; // Reset attributes
        }
    }

    return document;
}

- (OGElement*)_injectRuntimeLibraries:(OGElement*)document {
    OGElement *headNode = [[document elementsWithTag:GUMBO_TAG_HEAD] firstObject];
    
    // Find the index of the first <script> element, and move to one index beforehand.
    // Ensures that any injected libraries utilised will be loaded first.
    OGNode *firstScriptNode = [headNode first:[OGUtility tagForGumboTag:GUMBO_TAG_SCRIPT]];
    int index = firstScriptNode != nil ? (int)[headNode.children indexOfObject:firstScriptNode] - 1 : (int)headNode.children.count - 1;
    if (index < 0)
        index = 0;
    
    NSMutableArray *mutableChildren = [headNode.children mutableCopy];
    
    for (NSString *filepath in injectLibraries) {
        NSString *content = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
        
        OGElement *elementNode = [[OGElement alloc] init];
        elementNode.tag = GUMBO_TAG_SCRIPT;
        elementNode.tagNamespace = GUMBO_NAMESPACE_HTML;
        
        OGText *textNode = [[OGText alloc] initWithText:content andType:GUMBO_NODE_TEXT];
        elementNode.children = @[textNode];
        
        [mutableChildren insertObject:elementNode atIndex:index];
    }
    
    headNode.children = mutableChildren; // Set child nodes
    
    return document;
}

@end
