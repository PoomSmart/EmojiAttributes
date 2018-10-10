#import "../PS.h"
#import <unicode/utypes.h>

static CFCharacterSetRef newEmojiSet;

typedef struct USet USet;

extern "C" USet *uset_openEmpty(void);
extern "C" void uset_applyIntPropertyValue(USet *, long long, int32_t, UErrorCode *);
extern "C" void uset_freeze(USet *set);

extern "C" CFCharacterSetRef _CFCreateCharacterSetFromUSet(USet *);

void *(*CreateFallback)(void *, void *, int, int, int, unsigned int);

BOOL override = NO;

%hookf(Boolean, CFCharacterSetIsLongCharacterMember, CFCharacterSetRef theSet, UTF32Char theChar) {
    if (override)
        return %orig;
    return %orig(newEmojiSet, theChar);
}

%hookf(void *, CreateFallback, void *x, void *arg0, int arg1, int arg2, int arg3, unsigned int arg4) {
    override = YES;
    void *r = %orig;
    override = NO;
    return r;
}

%ctor {
    if (isiOS12Up)
        return;
    MSImageRef ref = MSGetImageByName(realPath2(@"/System/Library/Frameworks/CoreText.framework/CoreText"));
    CreateFallback = (void *(*)(void *, void *, int, int, int, unsigned int))MSFindSymbol(ref, "__ZNK12TFontCascade14CreateFallbackEPK8__CTFontPK10__CFString13CTEmojiPolicy");
    if (CreateFallback == NULL) {
        HBLogError(@"[CoreTextHack] Fatal: couldn't find necessarry symbol(s)");
        return;
    }
    USet *set = uset_openEmpty();
    UErrorCode error;
    uset_applyIntPropertyValue(set, 58, 1, &error);
    uset_freeze(set);
    newEmojiSet = (CFCharacterSetRef)CFRetain(_CFCreateCharacterSetFromUSet(set));
    %init;
}

%dtor {
    if (newEmojiSet)
        CFRelease(newEmojiSet);
}