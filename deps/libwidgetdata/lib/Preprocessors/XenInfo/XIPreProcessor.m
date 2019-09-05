//
//  XIPreProcessor.m
//  libwidgetdata
//
//  Created by Matt Clarke on 05/09/2019.
//

#import "XIPreProcessor.h"

@implementation XIPreProcessor

- (NSString*)parseScriptNodeContents:(NSString*)contents withAttributes:(NSDictionary*)attributes {
    /* Need to parse the following:
     1. window.location = 'xeninfo:xyz'; OR window.location = 'xeninfo:xyz:param';
        -> Into XenInfo.invokeAction('xyz');
        -> Regex maybe?
        -> For each line starting with 'window.location', containing 'xeninfo' and ending in ';'
        -> Replace with XenInfo.invokeAction('<everything between xeninfo and ;, not inclusive>')
     2. file:///var/mobile/Documents/Artwork.jpg
        -> Into XenInfo.currentArtwork(), returning a base64 image
        -> need to handle any following concatenation of string, and ignore them
        -> replace from 'file:/' up to the following: ', OR ') OR '; OR ", OR ") OR "; BUT NOT \' OR \"
     
     Approach:
     1. Split file on ;\n or ;\r
     2. Per each line, apply above transformations and store in-place
     3. Reconstruct script from split file
     */
    
    return contents;
}

@end
