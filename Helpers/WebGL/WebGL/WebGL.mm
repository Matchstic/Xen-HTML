#line 1 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/WebGL/WebGL/WebGL.xm"
#import "XENWGResources.h"


#define $_MSFindSymbolCallable(image, name) make_sym_callable(MSFindSymbol(image, name))

#pragma mark Haxx for WebGL on the Lockscreen

struct process_name_t {
    unsigned char header[4];
    int32_t flag_1;
    int32_t flag_2;
    int32_t length;
    unsigned char *name;
};

static NSString * const kCAContextSecure = @"secure";

#include <sys/sysctl.h>


static process_name_t* (*CA$Render$Context$process_name)(void *_this);


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


#line 23 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/WebGL/WebGL/WebGL.xm"


__unused static BOOL (*_logos_orig$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE)(void *_this, void *context, const void *var2 ); __unused static BOOL _logos_function$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE(void *_this, void *context, const void *var2 ) {
    
    if (CA$Render$Context$process_name != NULL) {
        
        
        process_name_t *process_name = CA$Render$Context$process_name(context);
        
        
        
        
        if (process_name->length == 115) {
            return YES;
        }
    }

    return _logos_orig$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE(_this, context, var2);
}





static id (*_logos_meta_orig$WebContent$CAContext$remoteContextWithOptions$)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, NSDictionary*); static id _logos_meta_method$WebContent$CAContext$remoteContextWithOptions$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, NSDictionary*); 



static id _logos_meta_method$WebContent$CAContext$remoteContextWithOptions$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSDictionary* options) {
    NSMutableDictionary* overrideOptions = [options mutableCopy];
    
    [overrideOptions setObject:@1 forKey:kCAContextSecure];
    
    return _logos_meta_orig$WebContent$CAContext$remoteContextWithOptions$(self, _cmd, overrideOptions);
}





static inline bool _xenhtml_wg_validate(void *pointer, NSString *name) {
    XENlog(@"DEBUG :: %@ is%@ a valid pointer", name, pointer == NULL ? @" NOT" : @"");
    return pointer != NULL;
}

static __attribute__((constructor)) void _logosLocalCtor_7ea7e065(int __unused argc, char __unused **argv, char __unused **envp) {
    {}
    
    BOOL bb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.backboardd"];
    BOOL webProcess = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.WebKit.WebContent"];
    
    if (bb) {
        CA$Render$Context$process_name = (process_name_t* (*)(void*)) $_MSFindSymbolCallable(NULL, "__ZN2CA6Render7Context12process_nameEv");
        
        if (!_xenhtml_wg_validate((void*)CA$Render$Context$process_name, @"CA::Render::Context::process_name"))
            return;
        
        XENlog(@"DEBUG :: initialising hooks");
        { MSHookFunction((void *)MSFindSymbol(NULL, "__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE"), (void *)&_logos_function$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE, (void **)&_logos_orig$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE);}
    } else if (webProcess) {
        XENlog(@"DEBUG :: initialising hooks");
        
        {Class _logos_class$WebContent$CAContext = objc_getClass("CAContext"); Class _logos_metaclass$WebContent$CAContext = object_getClass(_logos_class$WebContent$CAContext); MSHookMessageEx(_logos_metaclass$WebContent$CAContext, @selector(remoteContextWithOptions:), (IMP)&_logos_meta_method$WebContent$CAContext$remoteContextWithOptions$, (IMP*)&_logos_meta_orig$WebContent$CAContext$remoteContextWithOptions$);}
    }
}
