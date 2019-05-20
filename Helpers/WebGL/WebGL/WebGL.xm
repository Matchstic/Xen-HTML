
// Logging
#define XENlog(args...) XenHTMLWebGLLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);

#if defined __cplusplus
extern "C" {
#endif
    
    void XenHTMLWebGLLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
    
#if defined __cplusplus
};
#endif

void XenHTMLWebGLLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...) {
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
    
    NSLog(@"Xen HTML (WebGL) :: (%s:%d) %s",
          [fileName UTF8String],
          lineNumber, [body UTF8String]);
}

#pragma mark Haxx for WebGL on the Lockscreen

%hookf(BOOL, "__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE", void *_this, void *var1, const void *var2) {

    /*
    * WARNING
    *
    * This is horrible, I do not like this.
    * One approach attempted was to hook calls to CA::Render::Context::process_name() from
    * the original implementation of this method. Fun with return values meant this was not working
    * as expected.
    *
    * Therefore... this is now disabling some security mechanism that I don't know all the details of.
    * Not cool, but, whatever for now.
    */

    return YES;
}

%ctor {
    %init;
    
    XENlog(@"Reporting for duty!");
}
