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




#line 19 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/WebGL/WebGL/WebGL.xm"


__unused static BOOL (*_logos_orig$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE)(void *_this, void *context, const void *var2 ); __unused static BOOL _logos_function$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE(void *_this, void *context, const void *var2 ) {
    
    
    
    process_name_t *process_name = CA$Render$Context$process_name(context);
    
    
    
    
    if (process_name->length == 115) {
        return YES;
    }

    return _logos_orig$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE(_this, context, var2);
}



static inline bool _xenhtml_wg_validate(void *pointer, NSString *name) {
    XENlog(@"DEBUG :: %@ is%@ a valid pointer", name, pointer == NULL ? @" NOT" : @"");
    return pointer != NULL;
}

static __attribute__((constructor)) void _logosLocalCtor_36835025(int __unused argc, char __unused **argv, char __unused **envp) {
    {}
    
    BOOL bb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.backboardd"];
    
    if (bb) {
        CA$Render$Context$process_name = (process_name_t* (*)(void*)) $_MSFindSymbolCallable(NULL, "__ZN2CA6Render7Context12process_nameEv");
        
        if (!_xenhtml_wg_validate((void*)CA$Render$Context$process_name, @"CA::Render::Context::process_name"))
            return;
        
        { MSHookFunction((void *)MSFindSymbol(NULL, "__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE"), (void *)&_logos_function$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE, (void **)&_logos_orig$backboardd$lookup$__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE);}
    }
}
