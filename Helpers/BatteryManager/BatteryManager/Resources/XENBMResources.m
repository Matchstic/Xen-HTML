//
//  XENBMResources.m
//  BatteryManager
//
//  Created by Matt Clarke on 20/05/2019.
//

#import "XENBMResources.h"

void XenHTMLBatteryManagerLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...) {
    // Type to hold information about variable arguments.
    
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    if (![format hasSuffix:@"\n"]) {
        format = [format stringByAppendingString:@"\n"];
    }
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    // End using variable argument list.
    va_end(ap);
    
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    
    NSLog(@"Xen HTML (BatteryManager) :: (%s:%d) %s",
          [fileName UTF8String],
          lineNumber, [body UTF8String]);
}
