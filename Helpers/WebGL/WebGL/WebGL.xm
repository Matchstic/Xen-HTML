#import "XENWGResources.h"

// This is used for arm64e support w/ PAC and MSFindSymbol
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

// process_name_t* CA::Render::Context::process_name()
static process_name_t* (*CA$Render$Context$process_name)(void *_this);

%group backboardd

%hookf(BOOL, "__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE", void *_this, void *context /* CA::Render::Context* */, const void *var2 /* CA::Render::LayerHost */) {
    
    if (CA$Render$Context$process_name != NULL) {
        // 2f is == '/'
        // <78d515ec 01000000 01000000 17000000 2f757372 ...>
        process_name_t *process_name = CA$Render$Context$process_name(context);
        
        // Trying to access 'name' results in a segfault... UaF?
        
        // /System/Library/Frameworks/WebKit.framework/XPCServices/com.apple.WebKit.WebContent.xpc/com.apple.WebKit.WebContent
        if (process_name->length == 115) {
            return YES;
        }
    }

    return %orig(_this, context, var2);
}

%end

// Override CAContext options in the webcontent process
// Want to always ensure that its secure rendering
%group WebContent

%hook CAContext

+ (id)remoteContextWithOptions:(NSDictionary*)options {
    NSMutableDictionary* overrideOptions = [options mutableCopy];
    
    [overrideOptions setObject:@1 forKey:kCAContextSecure];
    
    return %orig(overrideOptions);
}

%end

%end

static inline bool _xenhtml_wg_validate(void *pointer, NSString *name) {
    XENlog(@"DEBUG :: %@ is%@ a valid pointer", name, pointer == NULL ? @" NOT" : @"");
    return pointer != NULL;
}

%ctor {
    %init;
    
    BOOL bb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.backboardd"];
    BOOL webProcess = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.WebKit.WebContent"];
    
    if (bb) {
        CA$Render$Context$process_name = (process_name_t* (*)(void*)) $_MSFindSymbolCallable(NULL, "__ZN2CA6Render7Context12process_nameEv");
        
        if (!_xenhtml_wg_validate((void*)CA$Render$Context$process_name, @"CA::Render::Context::process_name"))
            return;
        
        XENlog(@"DEBUG :: initialising hooks");
        %init(backboardd);
    } else if (webProcess) {
        XENlog(@"DEBUG :: initialising hooks");
        
        %init(WebContent);
    }
}
