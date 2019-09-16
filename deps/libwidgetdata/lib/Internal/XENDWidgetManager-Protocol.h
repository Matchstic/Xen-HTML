//
//  XENDDataProvider-Protocol.h
//  libwidgetdata
//
//  Created by Matt Clarke on 16/09/2019.
//

@protocol XENDWidgetManagerDelegate <NSObject>
// Call to update the delegate with new data on a topic.
- (void)updateWidgetsWithNewData:(NSDictionary*)data forNamespace:(NSString*)providerNamespace;
@end
