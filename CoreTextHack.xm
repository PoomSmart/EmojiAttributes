#define COMPRESSED_SET
#import "../PS.h"
#import "CharacterSet.h"
#import "PSEmojiData.h"
#import "uset.h"
#import <substrate.h>
#import <HBLog.h>
#include <unicode/utf16.h>

#define CreateMutableDict(dict) CFDictionaryCreateMutableCopy(kCFAllocatorDefault, CFDictionaryGetCount(dict), dict)

extern "C" CFCharacterSetRef _CFCreateCharacterSetFromUSet(USet *);

%config(generator=MobileSubstrate)

%group CharacterSet

CFCharacterSetRef (*CreateCharacterSetForFont)(CFStringRef const) = NULL;
CFCharacterSetRef (*CreateCharacterSetWithCompressedBitmapRepresentation)(const CFDataRef characterSet) = NULL;
CFDataRef (*XTCopyUncompressedBitmapRepresentation)(const UInt8 *, CFIndex);
%hookf(CFCharacterSetRef, CreateCharacterSetForFont, CFStringRef const fontName) {
    if (CFStringEqual(fontName, CFSTR("AppleColorEmoji")) || CFStringEqual(fontName, CFSTR(".AppleColorEmojiUI"))) {
        if (IS_IOS_OR_NEWER(iOS_11_0)) {
            CFDataRef compressedData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, compressedSet, compressedSetLength, kCFAllocatorNull);
            if (CreateCharacterSetWithCompressedBitmapRepresentation != NULL) {
                CFCharacterSetRef uncompressedSet = CreateCharacterSetWithCompressedBitmapRepresentation(compressedData);
                CFRelease(compressedData);
                return uncompressedSet;
            }
            CFDataRef uncompressedData = XTCopyUncompressedBitmapRepresentation(CFDataGetBytePtr(compressedData), CFDataGetLength(compressedData));
            CFRelease(compressedData);
            if (uncompressedData) {
                CFCharacterSetRef ourSet = CFCharacterSetCreateWithBitmapRepresentation(kCFAllocatorDefault, uncompressedData);
                CFRelease(uncompressedData);
                return ourSet;
            }
        }
        CFDataRef uncompressedData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, uncompressedSet, uncompressedSetLength, kCFAllocatorNull);
        CFCharacterSetRef ourSet = CFCharacterSetCreateWithBitmapRepresentation(kCFAllocatorDefault, uncompressedData);
        return ourSet;
    }
    return %orig(fontName);
}

%end

static CFMutableDictionaryRef ctFontInfo = NULL;

static CFMutableDictionaryRef getCTFontInfo(CFDictionaryRef dict) {
    if (ctFontInfo == NULL) {
        ctFontInfo = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, CFDictionaryGetCount(dict), dict);
        CFDictionaryRef x = (CFDictionaryRef)CFDictionaryGetValue(ctFontInfo, CFSTR("Attrs"));
        CFMutableDictionaryRef attrs = CreateMutableDict(x);
        x = (CFDictionaryRef)CFDictionaryGetValue(attrs, CFSTR("AppleColorEmoji"));
        CFMutableDictionaryRef ace = CreateMutableDict(x);
        x = (CFDictionaryRef)CFDictionaryGetValue(ace, CFSTR("NSCTFontTraitsAttribute"));
        CFMutableDictionaryRef fontTraits = CreateMutableDict(x);
        SInt32 formatValue = 3;
        CFNumberRef formatRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &formatValue);
        CFDictionarySetValue(ace, CFSTR("NSCTFontFormatAttribute"), formatRef);
        CFRelease(formatRef);
        CFDictionarySetValue(ace, CFSTR("NSCTFontFeaturesAttribute"), (__bridge CFArrayRef)@[
            @{
                @"CTFeatureTypeIdentifier": @(701),
                @"CTFeatureTypeNameID": @(256),
                @"CTFeatureTypeSelectors": @[
                    @{
                        @"CTFeatureSelectorIdentifier": @(100),
                        @"CTFeatureSelectorNameID": @(257)
                    },
                    @{
                        @"CTFeatureSelectorIdentifier": @(200),
                        @"CTFeatureSelectorNameID": @(258)
                    }
                ]
            }
        ]);
        CFDictionarySetValue(attrs, CFSTR("AppleColorEmoji"), ace);
        long long symbolicTraitValue = 3221234688;
        CFNumberRef symbolicTraitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &symbolicTraitValue);
        CFDictionarySetValue(fontTraits, CFSTR("NSCTFontSymbolicTrait"), symbolicTraitRef);
        CFRelease(symbolicTraitRef);
        CFDictionarySetValue(ctFontInfo, CFSTR("Attrs"), attrs);
    }
    return ctFontInfo;
}

// %group GetJoinerGlyphs

// uint16_t *(*BaseFontGetJoinerGlyphs)(void *);
// %hookf(uint16_t *, BaseFontGetJoinerGlyphs, void *baseFont) {
//     uint16_t *glyphs = %orig(baseFont);
//     void *p = (void *)((uintptr_t)baseFont + 0x110);
//     const uint16_t *first = (const uint16_t *)p;
//     const uint16_t *second = (const uint16_t *)((uintptr_t)p + 0x8);
//     if (first != NULL)
//         HBLogInfo(@"EmojiAttributes pair first %x", first[0]);
//     if (second != NULL)
//         HBLogInfo(@"EmojiAttributes pair second %x", second[0]);
//     return glyphs;
// }

// %end

%group FontAttributes1

CFDictionaryRef (*CTFontGetPlistFromGSFontCacheB)(CFStringRef, bool);
%hookf(CFDictionaryRef, CTFontGetPlistFromGSFontCacheB, CFStringRef plist, bool directAccess) {
    CFDictionaryRef dict = %orig(plist, directAccess);
    if (CFStringEqual(plist, CFSTR("CTFontInfo.plist")))
        return getCTFontInfo(dict);
    return dict;
}

%end

%group FontAttributes2

CFDictionaryRef (*CTFontGetPlistFromGSFontCache)(CFStringRef);
%hookf(CFDictionaryRef, CTFontGetPlistFromGSFontCache, CFStringRef plist) {
    CFDictionaryRef dict = %orig(plist);
    if (CFStringEqual(plist, CFSTR("CTFontInfo.plist")))
        return getCTFontInfo(dict);
    return dict;
}

%end

#if __LP64__

static USet *unicodeSet = NULL;
static CFCharacterSetRef characterSet = NULL;

%group EmojiPresentation

void (*IsDefaultEmojiPresentation)(void *);
CFMutableCharacterSetRef *DefaultEmojiPresentationSet;

%hookf(void, IsDefaultEmojiPresentation, void *arg0) {
    *DefaultEmojiPresentationSet = (CFMutableCharacterSetRef)characterSet;
}

%end

%group EmojiPresentationUSet

bool (*IsDefaultEmojiPresentationUSet)(UChar32);
%hookf(bool, IsDefaultEmojiPresentationUSet, UChar32 c) {
    return uset_contains(unicodeSet, c);
}

%end

#endif

%ctor {
    MSImageRef ct = MSGetImageByName(realPath2(@"/System/Library/Frameworks/CoreText.framework/CoreText"));
    CreateCharacterSetForFont = (CFCharacterSetRef (*)(CFStringRef const))MSFindSymbol(ct, "__Z25CreateCharacterSetForFontPK10__CFString");
    HBLogDebug(@"[CoreTextHack: CharacterSet] CreateCharacterSetForFont found: %d", CreateCharacterSetForFont != NULL);
    XTCopyUncompressedBitmapRepresentation = (CFDataRef (*)(const UInt8 *, CFIndex))_PSFindSymbolCallable(ct, "__Z38XTCopyUncompressedBitmapRepresentationPKhm");
    HBLogDebug(@"[CoreTextHack: CharacterSet] XTCopyUncompressedBitmapRepresentation found: %d", XTCopyUncompressedBitmapRepresentation != NULL);
    CreateCharacterSetWithCompressedBitmapRepresentation = (CFCharacterSetRef (*)(const CFDataRef))_PSFindSymbolCallable(ct, "__Z52CreateCharacterSetWithCompressedBitmapRepresentationPK8__CFData");
    HBLogDebug(@"[CoreTextHack: CharacterSet] CreateCharacterSetWithCompressedBitmapRepresentation found: %d", CreateCharacterSetWithCompressedBitmapRepresentation != NULL);
    %init(CharacterSet);
    CTFontGetPlistFromGSFontCacheB = (CFDictionaryRef (*)(CFStringRef, bool))MSFindSymbol(ct, "__Z29CTFontGetPlistFromGSFontCachePK10__CFStringb");
    HBLogDebug(@"[CoreTextHack: FontAttributes] CTFontGetPlistFromGSFontCacheB found: %d", CTFontGetPlistFromGSFontCacheB != NULL);
    if (CTFontGetPlistFromGSFontCacheB) {
        %init(FontAttributes1);
    }
    CTFontGetPlistFromGSFontCache = (CFDictionaryRef (*)(CFStringRef))MSFindSymbol(ct, "__Z29CTFontGetPlistFromGSFontCachePK10__CFString");
    HBLogDebug(@"[CoreTextHack: FontAttributes] CTFontGetPlistFromGSFontCache found: %d", CTFontGetPlistFromGSFontCache != NULL);
    if (CTFontGetPlistFromGSFontCache) {
        %init(FontAttributes2);
    }
    // BaseFontGetJoinerGlyphs = (uint16_t *(*)(void *))MSFindSymbol(ct, "__ZNK9TBaseFont15GetJoinerGlyphsEv");
    // HBLogDebug(@"[CoreTextHack: Glyphs] BaseFontGetJoinerGlyphs found: %d", BaseFontGetJoinerGlyphs != NULL);
    // if (BaseFontGetJoinerGlyphs) {
    //     %init(GetJoinerGlyphs);
    // }
#if __LP64__
    unicodeSet = uset_openEmpty();
    for (int i = 0; i < presentationCount; ++i)
        uset_add(unicodeSet, presentation[i]);
    uset_freeze(unicodeSet);
    if (IS_IOS_BETWEEN_EEX(iOS_11_0, iOS_12_1)) {
        characterSet = _CFCreateCharacterSetFromUSet(unicodeSet);
        CFRetain(characterSet);
        IsDefaultEmojiPresentation = (void (*)(void *))MSFindSymbol(ct, "__ZZL26IsDefaultEmojiPresentationjEN4$_138__invokeEPv");
        if (IsDefaultEmojiPresentation == NULL)
            IsDefaultEmojiPresentation = (void (*)(void *))MSFindSymbol(ct, "__ZZL26IsDefaultEmojiPresentationjEN4$_128__invokeEPv");
        DefaultEmojiPresentationSet = (CFMutableCharacterSetRef (*))_PSFindSymbolReadable(ct, "__ZZL26IsDefaultEmojiPresentationjE28sDefaultEmojiPresentationSet");
        HBLogDebug(@"[CoreTextHack: EmojiPresentation] IsDefaultEmojiPresentation found: %d", IsDefaultEmojiPresentation != NULL);
        HBLogDebug(@"[CoreTextHack: EmojiPresentation] DefaultEmojiPresentationSet found: %d", DefaultEmojiPresentationSet != NULL);
        %init(EmojiPresentation);
    } else if (IS_IOS_OR_NEWER(iOS_12_1)) {
        IsDefaultEmojiPresentationUSet = (bool (*)(UChar32))MSFindSymbol(ct, "__Z26IsDefaultEmojiPresentationj");
        HBLogDebug(@"[CoreTextHack: EmojiPresentation] IsDefaultEmojiPresentation (Uset) found: %d", IsDefaultEmojiPresentationUSet != NULL);
        if (IsDefaultEmojiPresentationUSet) {
            %init(EmojiPresentationUSet);
        }
    }
#endif
}

#if __LP64__

%dtor {
    if (characterSet)
        CFRelease(characterSet);
    if (unicodeSet)
        uset_close(unicodeSet);
}

#endif