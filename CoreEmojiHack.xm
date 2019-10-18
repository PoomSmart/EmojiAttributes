#import "../PS.h"
#import "EmojiMetadata.h"
#import <substrate.h>

%config(generator=MobileSubstrate)

#if __LP64__

%group EmojiData12Hook

void (*EmojiData12)(void *, CFURLRef const, CFURLRef const);
%hookf(void, EmojiData12, void *arg0, CFURLRef const datPath, CFURLRef const metaDatPath) {
    %orig(arg0, datPath, metaDatPath);
    CFMutableArrayRef *data = (CFMutableArrayRef *)((uintptr_t)arg0 + 0x28);
    int *count = (int *)((uintptr_t)arg0 + 0x32);
    CFArrayRemoveAllValues(*data);
    for (NSString *emoji in Emoji_Data) {
        CFStringRef cfEmoji = CFStringCreateWithCString(kCFAllocatorDefault, [emoji UTF8String], kCFStringEncodingUTF8);
        if (cfEmoji != NULL) {
            CFArrayAppendValue(*data, cfEmoji);
            CFRelease(cfEmoji);
        }
    }
    [Emoji_Data autorelease];
    *count = CFArrayGetCount(*data);
}

%end

#endif

%group EmojiDataHook

void *(*EmojiData)(void *, CFURLRef const, CFURLRef const);
%hookf(void *, EmojiData, void *arg0, CFURLRef const datPath, CFURLRef const metaDatPath) {
    void *orig = %orig(arg0, datPath, metaDatPath);
#if __LP64__
    CFMutableArrayRef *data = (CFMutableArrayRef *)((uintptr_t)arg0 + 0x28);
    int *count = (int *)((uintptr_t)arg0 + 0x32);
#else
    CFMutableArrayRef *data = (CFMutableArrayRef *)((uintptr_t)arg0 + 0x14);
    int *count = (int *)((uintptr_t)arg0 + 0x1A);
#endif
    CFArrayRemoveAllValues(*data);
    for (NSString *emoji in Emoji_Data) {
        CFStringRef cfEmoji = CFStringCreateWithCString(kCFAllocatorDefault, [emoji UTF8String], kCFStringEncodingUTF8);
        if (cfEmoji != NULL) {
            CFArrayAppendValue(*data, cfEmoji);
            CFRelease(cfEmoji);
        }
    }
    [Emoji_Data autorelease];
    *count = CFArrayGetCount(*data);
    return orig;
}

%end

%ctor {
    if (isiOS12_1Up)
        return;
    MSImageRef ref = MSGetImageByName(realPath2(@"/System/Library/PrivateFrameworks/CoreEmoji.framework/CoreEmoji"));
#if __LP64__
    if (isiOS12Up) {
        EmojiData12 = (void (*)(void *, CFURLRef const, CFURLRef const))_PSFindSymbolCallable(ref, "__ZN3CEM9EmojiDataC1EPK7__CFURLS3_");
        %init(EmojiData12Hook);
        return;
    }
#endif
    if (isiOS11Up)
        EmojiData = (void *(*)(void *, CFURLRef const, CFURLRef const))MSFindSymbol(ref, "__ZN3CEM9EmojiDataC1EPK7__CFURLS3_");
    else
        EmojiData = (void *(*)(void *, CFURLRef const, CFURLRef const))MSFindSymbol(ref, "__ZN3CEM9EmojiDataC2EPK7__CFURLS3_");
    %init(EmojiDataHook);
}