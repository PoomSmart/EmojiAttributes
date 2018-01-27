#import "CharacterSet.h"

CFStringRef iOS111Emojis = CFSTR("🤩🤨🤯🤪🤬🤮🤫🤭🧐🧒🧑🧓🧕🧔🤱🧙‍♀️🧙‍♂️🧚‍♀️🧚‍♂️🧛‍♀️🧛‍♂️🧜‍♀️🧜‍♂️🧝‍♀️🧝‍♂️🧞‍♀️🧞‍♂️🧟‍♀️🧟‍♂️🧖‍♀️🧖‍♂️🧗‍♀️🧗‍♂️🧘‍♀️🧘‍♂️🤟🤲🧠🧡🧣🧤🧥🧦🧢🦓🦒🦔🦕🦖🦗🥥🥦🥨🥩🥪🥣🥫🥟🥠🥡🥧🥤🥢🛸🛷🥌🏴󠁧󠁢󠁥󠁮󠁧󠁿🏴󠁧󠁢󠁳󠁣󠁴󠁿🏴󠁧󠁢󠁷󠁬󠁳󠁿⏏️");

CFCharacterSetRef (*CreateCharacterSetForFont)(CFStringRef const);
%hookf(CFCharacterSetRef, CreateCharacterSetForFont, CFStringRef const fontName) {
    if (CFEqual(fontName, CFSTR("AppleColorEmoji")) || CFEqual(fontName, CFSTR(".AppleColorEmojiUI"))) {
#ifdef COMPRESSED
        CFDataRef compressedData = (CFDataRef)dataFromHexString(compressedSet);
        CFDataRef uncompressedData = XTCopyUncompressedBitmapRepresentation(CFDataGetBytePtr(compressedData), CFDataGetLength(compressedData));
        CFRelease(compressedData);
        if (uncompressedData) {
            CFCharacterSetRef ourSet = CFCharacterSetCreateWithBitmapRepresentation(kCFAllocatorDefault, uncompressedData);
            CFRelease(uncompressedData);
            return ourSet;
        }
#else
        CFDataRef legacyUncompressedData = (CFDataRef)dataFromHexString(uncompressedSet);
        CFCharacterSetRef ourLegacySet = CFCharacterSetCreateWithBitmapRepresentation(kCFAllocatorDefault, legacyUncompressedData);
        CFMutableCharacterSetRef mutableLegacySet = CFCharacterSetCreateMutableCopy(kCFAllocatorDefault, ourLegacySet);
        CFCharacterSetAddCharactersInString(mutableLegacySet, iOS111Emojis);
        CFRelease(ourLegacySet);
        CFRelease(legacyUncompressedData);
        return mutableLegacySet;
#endif
    }
    return %orig;
}

%ctor {
    MSImageRef ref = MSGetImageByName(realPath2(@"/System/Library/Frameworks/CoreText.framework/CoreText"));
    CreateCharacterSetForFont = (CFCharacterSetRef (*)(CFStringRef const))MSFindSymbol(ref, "__Z25CreateCharacterSetForFontPK10__CFString");
#ifdef COMPRESSED
    XTCopyUncompressedBitmapRepresentation = (CFDataRef (*)(const UInt8 *, CFIndex))MSFindSymbol(ref, "__Z38XTCopyUncompressedBitmapRepresentationPKhm");
    if (XTCopyUncompressedBitmapRepresentation == NULL || CreateCharacterSetForFont == NULL) {
#else
    if (CreateCharacterSetForFont == NULL) {
#endif
        HBLogError(@"Fatal: couldn't find necessarry symbol(s)");
        return;
    }
    %init;
}
