#line 1 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/BatteryManager/BatteryManager/BatteryManager.xm"
#include <JavaScriptCore/JSContextRef.h>
#include <dlfcn.h>

@interface WKBrowsingContextController : NSObject
- (void *)_pageRef; 
@end

@interface WKContentView : NSObject
@property (nonatomic, readonly) WKBrowsingContextController *browsingContextController;
@end




#define XENlog(args...) XenHTMLBatteryManagerLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);

#if defined __cplusplus
extern "C" {
#endif
    
    void XenHTMLBatteryManagerLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
    
#if defined __cplusplus
};
#endif

void XenHTMLBatteryManagerLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...) {
    
    
    va_list ap;
    
    
    va_start (ap, format);
    
    if (![format hasSuffix:@"\n"]) {
        format = [format stringByAppendingString:@"\n"];
    }
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    
    va_end(ap);
    
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    
    NSLog(@"Xen HTML (BatteryManager) :: (%s:%d) %s",
          [fileName UTF8String],
          lineNumber, [body UTF8String]);
}



static void (*$WKContextPostMessageToInjectedBundle)(void *contextRef, void *messageNameRef, void *messageBodyRef);
static void* (*$WKPageGetContext)(void *pageRef);
static void* (*$WKStringCreateWithUTF8CString)(const char *c_str);
static void* (*$WKMutableDictionaryCreate)(void);
static void (*$WKDictionarySetItem)(void *dict, void *key, void *value);


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

@class WKWebView; 


#line 59 "/Users/matt/iOS/Projects/Xen-HTML/Helpers/BatteryManager/BatteryManager/BatteryManager.xm"
static void (*_logos_orig$SpringBoard$WKWebView$_didFinishLoadForMainFrame)(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST, SEL); static void _logos_method$SpringBoard$WKWebView$_didFinishLoadForMainFrame(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST, SEL); 

#pragma mark DEBUG



static void _logos_method$SpringBoard$WKWebView$_didFinishLoadForMainFrame(_LOGOS_SELF_TYPE_NORMAL WKWebView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$SpringBoard$WKWebView$_didFinishLoadForMainFrame(self, _cmd);
    
    XENlog(@"_didFinishLoadForMainFrame");
    
    
    void* messageName = $WKStringCreateWithUTF8CString("TESTING XH");
    void* messageBody = $WKMutableDictionaryCreate();
    $WKDictionarySetItem(messageBody, $WKStringCreateWithUTF8CString("test"), $WKStringCreateWithUTF8CString("pause"));
    
    
    WKContentView *contentView = MSHookIvar<WKContentView*>(self, "_contentView");
    void *pageRef = [contentView.browsingContextController _pageRef];
    void *contextRef = $WKPageGetContext(pageRef);
    
    $WKContextPostMessageToInjectedBundle(contextRef, messageName, messageBody);
    
    XENlog(@"Sent injected bundle message");
}





static JSGlobalContextRef (*WebFrame$jsContext)(void *_this);
static bool (*WebFrame$isMainFrame)(void *_this);
static CFStringRef (*WTF$String$createCFString)(void *_this);
static void* (*WTF$String$fromUTF8)(const char* literal);
static void* (*WTF$String$constructorLiteral)(void *_this, const char* literal);
static void* (*API$Dictionary$getNumber)(void *_this, void *key);
static void* (*API$Dictionary$getString)(void *_this, void *key);



__unused static void (*_logos_orig$WebContent$lookup$__ZN6WebKit14InjectedBundle17didReceiveMessageERKN3WTF6StringEPN3API6ObjectE)(void* _this, void* messageName, void* messageBody ); __unused static void _logos_function$WebContent$lookup$__ZN6WebKit14InjectedBundle17didReceiveMessageERKN3WTF6StringEPN3API6ObjectE(void* _this, void* messageName, void* messageBody ) {

    _logos_orig$WebContent$lookup$__ZN6WebKit14InjectedBundle17didReceiveMessageERKN3WTF6StringEPN3API6ObjectE(_this, messageName, messageBody);
    
    XENlog(@"UGH: messageName %p, messageBody %p", messageName, messageBody);
    
    void* key = WTF$String$fromUTF8("test");
    void* thing = API$Dictionary$getString(messageBody, key);
    
    XENlog(@"Did recieve an injected bundle message, with test: %p", thing);
    
    
    
}

__unused static void (*_logos_orig$WebContent$lookup$__ZN6WebKit10WebProcess11addWebFrameEyPNS_8WebFrameE)(void* _this, uint64_t frameId, void*  webFrame); __unused static void _logos_function$WebContent$lookup$__ZN6WebKit10WebProcess11addWebFrameEyPNS_8WebFrameE(void* _this, uint64_t frameId, void*  webFrame) {
    _logos_orig$WebContent$lookup$__ZN6WebKit10WebProcess11addWebFrameEyPNS_8WebFrameE(_this, frameId, webFrame);
    
    bool isMainFrame = WebFrame$isMainFrame(webFrame);
    
    XENlog(@"Frame created with ID: %d, isMain: %d", frameId, isMainFrame);
    
    
}



static bool _xenhtml_bm_validate(void *pointer, NSString *name) {
    XENlog(@"DEBUG :: %@ is%@ a valid pointer", name, pointer == NULL ? @" NOT" : @"");
    return pointer != NULL;
}


static __attribute__((constructor)) void _logosLocalCtor_6ea7cce3(int __unused argc, char __unused **argv, char __unused **envp) {
    {}
    
    BOOL sb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"];
    
    if (sb) {
        
        $WKContextPostMessageToInjectedBundle = (void (*)(void*, void*, void*)) MSFindSymbol(NULL, "_WKContextPostMessageToInjectedBundle");
        $WKPageGetContext = (void* (*)(void*)) MSFindSymbol(NULL, "_WKPageGetContext");
        $WKStringCreateWithUTF8CString = (void* (*)(const char*)) MSFindSymbol(NULL, "_WKStringCreateWithUTF8CString");
        $WKMutableDictionaryCreate = (void* (*)(void)) MSFindSymbol(NULL, "_WKMutableDictionaryCreate");
        $WKDictionarySetItem = (void (*)(void*, void*, void*)) MSFindSymbol(NULL, "_WKDictionarySetItem");
        
        if (!_xenhtml_bm_validate((void*)$WKContextPostMessageToInjectedBundle, @"WKContextPostMessageToInjectedBundle"))
            return;
        if (!_xenhtml_bm_validate((void*)$WKPageGetContext, @"WKPageGetContext"))
            return;
        if (!_xenhtml_bm_validate((void*)$WKStringCreateWithUTF8CString, @"WKStringCreateWithUTF8CString"))
            return;
        if (!_xenhtml_bm_validate((void*)$WKMutableDictionaryCreate, @"WKMutableDictionaryCreate"))
            return;
        if (!_xenhtml_bm_validate((void*)$WKDictionarySetItem, @"WKDictionarySetItem"))
            return;
        
        {Class _logos_class$SpringBoard$WKWebView = objc_getClass("WKWebView"); MSHookMessageEx(_logos_class$SpringBoard$WKWebView, @selector(_didFinishLoadForMainFrame), (IMP)&_logos_method$SpringBoard$WKWebView$_didFinishLoadForMainFrame, (IMP*)&_logos_orig$SpringBoard$WKWebView$_didFinishLoadForMainFrame);}
    } else {
        
        WebFrame$jsContext = (JSGlobalContextRef (*)(void*)) MSFindSymbol(NULL, "__ZN6WebKit8WebFrame9jsContextEv");
        WebFrame$isMainFrame = (bool (*)(void*)) MSFindSymbol(NULL, "__ZNK6WebKit8WebFrame11isMainFrameEv");
        
        
        WTF$String$createCFString = (CFStringRef (*)(void*)) MSFindSymbol(NULL, "__ZNK3WTF6String14createCFStringEv");
        WTF$String$fromUTF8 = (void* (*)(const char*)) MSFindSymbol(NULL, "__ZN3WTF6String8fromUTF8EPKh");
        
        API$Dictionary$getNumber = (void* (*)(void*, void*)) MSFindSymbol(NULL, "__ZNK3API10Dictionary3getINS_6NumberIyLNS_6Object4TypeE33EEEEEPT_RKN3WTF6StringE");
        API$Dictionary$getString = (void* (*)(void*, void*)) MSFindSymbol(NULL, "__ZNK3API10Dictionary3getINS_6StringEEEPT_RKN3WTF6StringE");
        
        if (!_xenhtml_bm_validate((void*)WTF$String$createCFString, @"WTF::String::createCFString()"))
            return;
        if (!_xenhtml_bm_validate((void*)WTF$String$fromUTF8, @"WTF::String::fromUTF8"))
            return;
        if (!_xenhtml_bm_validate((void*)API$Dictionary$getNumber, @"API::Dictionary::get<number>(WTF::String)"))
            return;
        if (!_xenhtml_bm_validate((void*)API$Dictionary$getString, @"API::Dictionary::get<string>(WTF::String)"))
            return;
        
        { MSHookFunction((void *)MSFindSymbol(NULL, "__ZN6WebKit14InjectedBundle17didReceiveMessageERKN3WTF6StringEPN3API6ObjectE"), (void *)&_logos_function$WebContent$lookup$__ZN6WebKit14InjectedBundle17didReceiveMessageERKN3WTF6StringEPN3API6ObjectE, (void **)&_logos_orig$WebContent$lookup$__ZN6WebKit14InjectedBundle17didReceiveMessageERKN3WTF6StringEPN3API6ObjectE); MSHookFunction((void *)MSFindSymbol(NULL, "__ZN6WebKit10WebProcess11addWebFrameEyPNS_8WebFrameE"), (void *)&_logos_function$WebContent$lookup$__ZN6WebKit10WebProcess11addWebFrameEyPNS_8WebFrameE, (void **)&_logos_orig$WebContent$lookup$__ZN6WebKit10WebProcess11addWebFrameEyPNS_8WebFrameE);}
    }
}
