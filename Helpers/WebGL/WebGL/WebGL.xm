#import "XENWGResources.h"

// This is used for arm64e support w/ PAC and MSFindSymbol
#define $_MSFindSymbolCallable(image, name) make_sym_callable(MSFindSymbol(image, name))

#pragma mark Haxx for WebGL on the Lockscreen

// const char* CA::Render::Context::process_name()
static const char* (*CA$Render$Context$process_name)(void *_this);

%group backboardd

%hookf(BOOL, "__ZN2CA6Render6Update24allowed_in_secure_updateEPNS0_7ContextEPKNS0_9LayerHostE", void *_this, void *context /* CA::Render::Context* */, const void *var2 /* CA::Render::LayerHost */) {

    // BOOL orig = %orig(_this, context, var2);
    
    // XENlog(@"Got process name: %s", CA$Render$Context$process_name(context));
    
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

%end

static inline bool _xenhtml_wg_validate(void *pointer, NSString *name) {
    XENlog(@"DEBUG :: %@ is%@ a valid pointer", name, pointer == NULL ? @" NOT" : @"");
    return pointer != NULL;
}

%ctor {
    %init;
    
    BOOL bb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.backboardd"];
    
    if (bb) {
        CA$Render$Context$process_name = (const char* (*)(void*)) $_MSFindSymbolCallable(NULL, "__ZN2CA6Render7Context12process_nameEv");
        
        if (!_xenhtml_wg_validate((void*)CA$Render$Context$process_name, @"CA::Render::Context::process_name"))
            return;
        
        %init(backboardd);
    } else {
        // %init(WebContent);
    }
}
