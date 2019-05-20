#line 1 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/WebGL/WebGL/WebGL.xm"


#define XENlog(args...) XenHTMLWebGLLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);

#if defined __cplusplus
extern "C" {
#endif
    
    void XenHTMLWebGLLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
    
#if defined __cplusplus
};
#endif

void XenHTMLWebGLLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...) {
    
    
    va_list ap;
    
    
    va_start (ap, format);
    
    if (![format hasSuffix:@"\n"]) {
        format = [format stringByAppendingString:@"\n"];
    }
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    
    va_end(ap);
    
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    
    NSLog(@"Xen HTML (WebGL) :: (%s:%d) %s",
          [fileName UTF8String],
          lineNumber, [body UTF8String]);
}

#pragma mark Haxx for WebGL on the Lockscreen


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif




#line 41 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/WebGL/WebGL/WebGL.xm"
__unused static BOOL (*_logos_orig$_ungrouped$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE)(void *_this, void *var1, const void *var2); __unused static BOOL _logos_function$_ungrouped$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE(void *_this, void *var1, const void *var2) {

    











    return YES;
}

static __attribute__((constructor)) void _logosLocalCtor_7c1b35e5(int __unused argc, char __unused **argv, char __unused **envp) {
    { MSHookFunction((void *)MSFindSymbol(NULL, "__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE"), (void *)&_logos_function$_ungrouped$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE, (void **)&_logos_orig$_ungrouped$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE);}
    
    XENlog(@"Reporting for duty!");
}
