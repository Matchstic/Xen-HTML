//
//  XENWGResources.h
//  WebGL
//
//  Created by Matt Clarke on 26/05/2019.
//

#import <Foundation/Foundation.h>

#if defined __cplusplus
extern "C" {
#endif
    
    void XenHTMLWebGLLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
    
#if defined __cplusplus
};
#endif

// See: https://gist.github.com/summertriangle-dev/6b0449ce561f756ac82a4bc3de7af30a

#ifndef PTRAUTH_HELPERS_H
#define PTRAUTH_HELPERS_H
// Helpers for PAC archs.

// If the compiler understands __arm64e__, assume it's paired with an SDK that has
// ptrauth.h. Otherwise, it'll probably error if we try to include it so don't.
#if __arm64e__
#include <ptrauth.h>
#endif

// Given a pointer to instructions, sign it so you can call it like a normal fptr.
static void *make_sym_callable(void *ptr) {
#if __arm64e__
    if (!ptr)
        return ptr;
    
    XENlog(@"pointer pre-PAC signing: %p", ptr);
    ptr = ptrauth_sign_unauthenticated(ptrauth_strip(ptr, ptrauth_key_function_pointer), ptrauth_key_function_pointer, 0);
    XENlog(@"pointer after-PAC signing: %p", ptr);
#endif
    return ptr;
}

#endif
