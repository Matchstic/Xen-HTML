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

#include <sys/sysctl.h>

NSString *proc_pidpath(int);
NSString *proc_pidpath(int pid) {
    
    // First ask the system how big a buffer we should allocate
    int mib[3] = {CTL_KERN, KERN_ARGMAX, 0};

    size_t argmaxsize = sizeof(size_t);
    size_t size;

    int ret = sysctl(mib, 2, &size, &argmaxsize, NULL, 0);

    if (ret != 0) {
        return @"";
    } else if (size == 0) {
        return @"";
    }

    // Then we can get the path information we actually want
    mib[1] = KERN_PROCARGS2;
    mib[2] = (int)pid;

    char *procargv = (char*)malloc(size);

    ret = sysctl(mib, 3, procargv, &size, NULL, 0);

    if (ret != 0) {
        free(procargv);

        return nil;
    }

    // procargv is actually a data structure.
    // The path is at procargv + sizeof(int)
    if (!procargv) {
        return @"";
    } else {
        NSString *path = [[NSString stringWithCString:(procargv + sizeof(int))
                                             encoding:NSASCIIStringEncoding] copy];

        free(procargv);

        return path;
    }
}

// process_name_t* CA::Render::Context::process_name()
static process_name_t* (*CA$Render$Context$process_name)(void *_this);

// const char* CA::Render::Context::process_path()
static int (*CA$Render$Context$process_id)(void *_this);

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
    } else if (CA$Render$Context$process_id != NULL) {
        pid_t pid = CA$Render$Context$process_id(context);

        if (pid > 0) {
            NSString *path = proc_pidpath(pid);
            
            if ([path rangeOfString:@"com.apple.WebKit.WebContent"].location != NSNotFound) {
                return YES;
            }
        }
    }

    return %orig(_this, context, var2);
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
        CA$Render$Context$process_name = (process_name_t* (*)(void*)) $_MSFindSymbolCallable(NULL, "__ZN2CA6Render7Context12process_nameEv");
        CA$Render$Context$process_id = (int (*)(void*)) $_MSFindSymbolCallable(NULL, "__ZNK2CA6Render7Context10process_idEv");
        
        if (!_xenhtml_wg_validate((void*)CA$Render$Context$process_name, @"CA::Render::Context::process_name") &&
            !_xenhtml_wg_validate((void*)CA$Render$Context$process_id, @"CA::Render::Context::process_id"))
            return;
        
        XENlog(@"DEBUG :: initialising hooks");
        %init(backboardd);
    }
}
