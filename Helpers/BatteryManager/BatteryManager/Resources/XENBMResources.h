//
//  XENBMResources.h
//  BatteryManager
//
//  Created by Matt Clarke on 20/05/2019.
//

#import <Foundation/Foundation.h>

#if defined __cplusplus
extern "C" {
#endif
    
    void XenHTMLBatteryManagerLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
    
#if defined __cplusplus
};
#endif
