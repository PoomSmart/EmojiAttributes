#define COMPRESSED
#import "CharacterSet.h"

CFStringRef iOS111Emojis = CFSTR("🤩🤨🤯🤪🤬🤮🤫🤭🧐🧒🧑🧓🧕🧔🤱🧙‍♀️🧙‍♂️🧚‍♀️🧚‍♂️🧛‍♀️🧛‍♂️🧜‍♀️🧜‍♂️🧝‍♀️🧝‍♂️🧞‍♀️🧞‍♂️🧟‍♀️🧟‍♂️🧖‍♀️🧖‍♂️🧗‍♀️🧗‍♂️🧘‍♀️🧘‍♂️🤟🤲🧠🧡🧣🧤🧥🧦🧢🦓🦒🦔🦕🦖🦗🥥🥦🥨🥩🥪🥣🥫🥟🥠🥡🥧🥤🥢🛸🛷🥌🏴󠁧󠁢󠁥󠁮󠁧󠁿🏴󠁧󠁢󠁳󠁣󠁴󠁿🏴󠁧󠁢󠁷󠁬󠁳󠁿⏏️");
CFStringRef iOS121Emojis = CFSTR("🥰🥵🥶🥳🥴🥺👨‍🦰👨🏻‍🦰👨🏼‍🦰👨🏽‍🦰👨🏾‍🦰👨🏿‍🦰👩‍🦰👩🏻‍🦰👩🏼‍🦰👩🏽‍🦰👩🏾‍🦰👩🏿‍🦰👨‍🦱👨🏻‍🦱👨🏼‍🦱👨🏽‍🦱👨🏾‍🦱👨🏿‍🦱👩‍🦱👩🏻‍🦱👩🏼‍🦱👩🏽‍🦱👩🏾‍🦱👩🏿‍🦱👨‍🦲👨🏻‍🦲👨🏼‍🦲👨🏽‍🦲👨🏾‍🦲👨🏿‍🦲👩‍🦲👩🏻‍🦲👩🏼‍🦲👩🏽‍🦲👩🏾‍🦲👩🏿‍🦲👨‍🦳👨🏻‍🦳👨🏼‍🦳👨🏽‍🦳👨🏾‍🦳👨🏿‍🦳👩‍🦳👩🏻‍🦳👩🏼‍🦳👩🏽‍🦳👩🏾‍🦳👩🏿‍🦳🦸🦸🏻🦸🏼🦸🏽🦸🏾🦸🏿🦸‍♀️🦸🏻‍♀️🦸🏼‍♀️🦸🏽‍♀️🦸🏾‍♀️🦸🏿‍♀️🦸‍♂️🦸🏻‍♂️🦸🏼‍♂️🦸🏽‍♂️🦸🏾‍♂️🦸🏿‍♂️🦹🦹🏻🦹🏼🦹🏽🦹🏾🦹🏿🦹‍♀️🦹🏻‍♀️🦹🏼‍♀️🦹🏽‍♀️🦹🏾‍♀️🦹🏿‍♀️🦹‍♂️🦹🏻‍♂️🦹🏼‍♂️🦹🏽‍♂️🦹🏾‍♂️🦹🏿‍♂️🦵🦵🏻🦵🏼🦵🏽🦵🏾🦵🏿🦶🦶🏻🦶🏼🦶🏽🦶🏾🦶🏿🦴🦷🥽🥼🥾🥿🦝🦙🦛🦘🦡🦢🦚🦜🦞🦟🦠🥭🥬🥯🧂🥮🧁🧭🧱🛹🧳🧨🧧🥎🥏🥍🧿🧩🧸♟🧮🧾🧰🧲🧪🧫🧬🧯🧴🧵🧶🧷🧹🧺🧻🧼🧽♾🏴‍☠️🇺🇳");

CFCharacterSetRef (*CreateCharacterSetForFont)(CFStringRef const);
#define compare(str1, str2) (str1 && CFStringCompare(str1, str2, kCFCompareCaseInsensitive) == kCFCompareEqualTo)
%hookf(CFCharacterSetRef, CreateCharacterSetForFont, CFStringRef const fontName) {
    if (compare(fontName, CFSTR("AppleColorEmoji")) || compare(fontName, CFSTR(".AppleColorEmojiUI"))) {
    if (isiOS10_3Up) {
            CFDataRef compressedData = (CFDataRef)dataFromHexString(compressedSet);
            CFDataRef uncompressedData = XTCopyUncompressedBitmapRepresentation(CFDataGetBytePtr(compressedData), CFDataGetLength(compressedData));
            CFRelease(compressedData);
            if (uncompressedData) {
                CFCharacterSetRef ourSet = CFCharacterSetCreateWithBitmapRepresentation(kCFAllocatorDefault, uncompressedData);
                CFRelease(uncompressedData);
                return ourSet;
            }
    } else {
            CFDataRef legacyUncompressedData = (CFDataRef)dataFromHexString(uncompressedSet);
            CFCharacterSetRef ourLegacySet = CFCharacterSetCreateWithBitmapRepresentation(kCFAllocatorDefault, legacyUncompressedData);
            CFMutableCharacterSetRef mutableLegacySet = CFCharacterSetCreateMutableCopy(kCFAllocatorDefault, ourLegacySet);
            CFCharacterSetAddCharactersInString(mutableLegacySet, iOS111Emojis);
            CFCharacterSetAddCharactersInString(mutableLegacySet, iOS121Emojis);
            CFRelease(ourLegacySet);
            CFRelease(legacyUncompressedData);
            return mutableLegacySet;
        }
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
