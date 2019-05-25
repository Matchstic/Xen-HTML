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

@class CAContext; 


#line 41 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/WebGL/WebGL/WebGL.xm"


__unused static BOOL (*_logos_orig$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE)(void *_this, void *var1, const void *var2); __unused static BOOL _logos_function$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE(void *_this, void *var1, const void *var2) {

    











    return YES;
}



static CAContext * (*_logos_meta_orig$WebContent$CAContext$localContextWithOptions$)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, NSDictionary *); static CAContext * _logos_meta_method$WebContent$CAContext$localContextWithOptions$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, NSDictionary *); static bool (*_logos_orig$WebContent$CAContext$isSecure)(_LOGOS_SELF_TYPE_NORMAL CAContext* _LOGOS_SELF_CONST, SEL); static bool _logos_method$WebContent$CAContext$isSecure(_LOGOS_SELF_TYPE_NORMAL CAContext* _LOGOS_SELF_CONST, SEL); 
 

 

 
static CAContext * _logos_meta_method$WebContent$CAContext$localContextWithOptions$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSDictionary * dict) {
    
    XENlog(@"DEBUG :: CREATING LOCAL CONTEXT WITH OPTIONS: %@", dict);
    
    return _logos_meta_orig$WebContent$CAContext$localContextWithOptions$(self, _cmd, dict);
}

static bool _logos_method$WebContent$CAContext$isSecure(_LOGOS_SELF_TYPE_NORMAL CAContext* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    XENlog(@"DEBUG :: REQUESTING IS SECURE");
    return YES;
}
 

 


static __attribute__((constructor)) void _logosLocalCtor_f6203d4c(int __unused argc, char __unused **argv, char __unused **envp) {
    {}
    
    BOOL bb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.backboardd"];
    
    if (bb) {
        { MSHookFunction((void *)MSFindSymbol(NULL, "__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE"), (void *)&_logos_function$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE, (void **)&_logos_orig$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE);}
    } else {
        {Class _logos_class$WebContent$CAContext = objc_getClass("CAContext"); Class _logos_metaclass$WebContent$CAContext = object_getClass(_logos_class$WebContent$CAContext); MSHookMessageEx(_logos_metaclass$WebContent$CAContext, @selector(localContextWithOptions:), (IMP)&_logos_meta_method$WebContent$CAContext$localContextWithOptions$, (IMP*)&_logos_meta_orig$WebContent$CAContext$localContextWithOptions$);MSHookMessageEx(_logos_class$WebContent$CAContext, @selector(isSecure), (IMP)&_logos_method$WebContent$CAContext$isSecure, (IMP*)&_logos_orig$WebContent$CAContext$isSecure);}
    }
}
