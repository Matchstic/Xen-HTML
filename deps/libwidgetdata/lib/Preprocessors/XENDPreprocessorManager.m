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
#import <ObjectiveGumbo/ObjectiveGumbo.h>

@interface XENDPreprocessorManager ()
@property (nonatomic, strong) NSString *baseDocumentPath;
@property (nonatomic, strong) NSArray* preprocessors;
@property (nonatomic, strong) NSArray* injectedLibraries;
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
        self.injectedLibraries = [self _populateInjectedLibraries];
    }
    
    return self;
}

- (NSArray*)_createPreprocessors {
    NSMutableArray *array = [NSMutableArray array];
    
    IS2PreProcessor *preprocessor = [[IS2PreProcessor alloc] init];
    [array addObject:preprocessor];
    
    return array;
}

- (NSArray*)_populateInjectedLibraries {
    NSMutableArray *array = [NSMutableArray array];
    
    [array addObject:@"/Users/matt/Downloads/test-is2-update/test.js"];
    
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
    
    if (error) {
        NSLog(@"Error parsing HTML: %@", error);
        return @"";
    }
    
    // Parse all script sections
    document = [self _parseNodes:document];
    
    // Inject libraries
    document = [self _injectRuntimeLibraries:document];
    
    return [self _fixupHTML:[document html]];
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

- (OGElement*)_injectRuntimeLibraries:(OGElement*)document {
    OGElement *headNode = [[document elementsWithTag:GUMBO_TAG_HEAD] firstObject];
    
    // Find the index of the first <script> element, and move to one index beforehand.
    // Ensures that any injected libraries utilised will be loaded first.
    OGNode *firstScriptNode = [headNode first:[OGUtility tagForGumboTag:GUMBO_TAG_SCRIPT]];
    int index = firstScriptNode != nil ? (int)[headNode.children indexOfObject:firstScriptNode] - 1 : (int)headNode.children.count - 1;
    if (index < 0)
        index = 0;
    
    NSMutableArray *mutableChildren = [headNode.children mutableCopy];
    
    for (NSString *filepath in self.injectedLibraries) {
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

- (NSString*)_fixupHTML:(NSString*)document {
    document = [document stringByReplacingOccurrencesOfString:@"<title />" withString:@"<title></title>"];
    
    return document;
}

@end
