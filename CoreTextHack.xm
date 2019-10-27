#import "../PS.h"
#import "CharacterSet.h"
#import "uset.h"
#import <substrate.h>
#include <unicode/utf16.h>

extern "C" CFCharacterSetRef _CFCreateCharacterSetFromUSet(USet *);

%config(generator=MobileSubstrate)

%group CharacterSet

CFCharacterSetRef (*CreateCharacterSetForFont)(CFStringRef const);
CFDataRef (*XTCopyUncompressedBitmapRepresentation)(const UInt8 *, CFIndex);
%hookf(CFCharacterSetRef, CreateCharacterSetForFont, CFStringRef const fontName) {
    if (CFStringEqual(fontName, CFSTR("AppleColorEmoji")) || CFStringEqual(fontName, CFSTR(".AppleColorEmojiUI"))) {
        if (isiOS11Up) {
                CFDataRef compressedData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, compressedSet, compressedSetLength, kCFAllocatorNull);
                CFDataRef uncompressedData = XTCopyUncompressedBitmapRepresentation(CFDataGetBytePtr(compressedData), CFDataGetLength(compressedData));
                CFRelease(compressedData);
                if (uncompressedData) {
                    CFCharacterSetRef ourSet = CFCharacterSetCreateWithBitmapRepresentation(kCFAllocatorDefault, uncompressedData);
                    CFRelease(uncompressedData);
                    return ourSet;
                }
        }
        CFDataRef legacyUncompressedData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, uncompressedSet, uncompressedSetLength, kCFAllocatorNull);
        CFCharacterSetRef ourLegacySet = CFCharacterSetCreateWithBitmapRepresentation(kCFAllocatorDefault, legacyUncompressedData);
        return ourLegacySet;
    }
    return %orig;
}

%end

#if __LP64__

#import "EmojiPresentation.h"

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
    CreateCharacterSetForFont = (CFCharacterSetRef (*)(CFStringRef const))_PSFindSymbolCallable(ct, "__Z25CreateCharacterSetForFontPK10__CFString");
    XTCopyUncompressedBitmapRepresentation = (CFDataRef (*)(const UInt8 *, CFIndex))_PSFindSymbolCallable(ct, "__Z38XTCopyUncompressedBitmapRepresentationPKhm");
    HBLogDebug(@"[CoreTextHack: CharacterSet] CreateCharacterSetForFont found: %d", CreateCharacterSetForFont != NULL);
    HBLogDebug(@"[CoreTextHack: CharacterSet] XTCopyUncompressedBitmapRepresentation found: %d", XTCopyUncompressedBitmapRepresentation != NULL);
    %init(CharacterSet);
#if __LP64__
    unicodeSet = uset_openEmpty();
    for (int i = 0; i < emojiPresentationCount; ++i)
        uset_add(unicodeSet, emojiPresentation[i]);
    uset_freeze(unicodeSet);
    characterSet = _CFCreateCharacterSetFromUSet(unicodeSet);
    CFRetain(characterSet);
    if (IS_IOS_BETWEEN_EEX(iOS_11_0, iOS_12_1)) {
        IsDefaultEmojiPresentation = (void (*)(void *))_PSFindSymbolCallable(ct, "__ZZL26IsDefaultEmojiPresentationjEN4$_138__invokeEPv");
        if (IsDefaultEmojiPresentation == NULL)
            IsDefaultEmojiPresentation = (void (*)(void *))_PSFindSymbolCallable(ct, "__ZZL26IsDefaultEmojiPresentationjEN4$_128__invokeEPv");
        DefaultEmojiPresentationSet = (CFMutableCharacterSetRef (*))_PSFindSymbolReadable(ct, "__ZZL26IsDefaultEmojiPresentationjE28sDefaultEmojiPresentationSet");
        HBLogDebug(@"[CoreTextHack: EmojiPresentation] IsDefaultEmojiPresentation found: %d", IsDefaultEmojiPresentation != NULL);
        HBLogDebug(@"[CoreTextHack: EmojiPresentation] DefaultEmojiPresentationSet found: %d", DefaultEmojiPresentationSet != NULL);
        %init(EmojiPresentation);
    } else if (isiOS12_1Up) {
        IsDefaultEmojiPresentationUSet = (bool (*)(UChar32))_PSFindSymbolCallable(ct, "__Z26IsDefaultEmojiPresentationj");
        HBLogDebug(@"[CoreTextHack: EmojiPresentation] IsDefaultEmojiPresentation (Uset) found: %d", IsDefaultEmojiPresentationUSet != NULL);
        %init(EmojiPresentationUSet);
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