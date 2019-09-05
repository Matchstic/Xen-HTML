//
//  XENDPreProcessor-Protocol.h
//  libwidgetdata
//
//  Created by Matt Clarke on 05/09/2019.
//

@protocol XENDPreProcessor <NSObject>

- (NSString*)parseScriptNodeContents:(NSString*)contents withAttributes:(NSDictionary*)attributes;

@end
