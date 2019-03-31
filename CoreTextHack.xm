#import "../PS.h"
#import "CharacterSet.h"
#import "EmojiPresentation.h"
#import <substrate.h>

%config(generator=MobileSubstrate)

%group CharacterSet

static NSData *dataFromHexString(NSString *string) {
    string = [string lowercaseString];
    NSMutableData *data = [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {
        '\0', '\0', '\0'
    };
    NSUInteger i = 0;
    NSUInteger length = string.length;
    while (i < length - 1) {
        char c = [string characterAtIndex:i++];
        if (c == ' ')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

CFCharacterSetRef (*CreateCharacterSetForFont)(CFStringRef const);
CFDataRef (*XTCopyUncompressedBitmapRepresentation)(const UInt8 *, CFIndex);
%hookf(CFCharacterSetRef, CreateCharacterSetForFont, CFStringRef const fontName) {
    if (CFStringEqual(fontName, CFSTR("AppleColorEmoji")) || CFStringEqual(fontName, CFSTR(".AppleColorEmojiUI"))) {
        if (isiOS11Up) {
                CFDataRef compressedData = (__bridge CFDataRef)dataFromHexString(compressedSet);
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
                return ourLegacySet;
        }
    }
    return %orig;
}

%end

%group EmojiPresentation

void (*IsDefaultEmojiPresentation)(void *);
CFMutableCharacterSetRef *DefaultEmojiPresentationSet;
%hookf(void, IsDefaultEmojiPresentation, void *arg0) {
    *DefaultEmojiPresentationSet = CFCharacterSetCreateMutable(kCFAllocatorDefault);
    for (NSString *emoji : emojiPresentation)
        CFCharacterSetAddCharactersInString(*DefaultEmojiPresentationSet, (__bridge CFStringRef)emoji);
    *DefaultEmojiPresentationSet = (CFMutableCharacterSetRef)CFRetain(*DefaultEmojiPresentationSet);
}

%end

%ctor {
    MSImageRef ref = MSGetImageByName(realPath2(@"/System/Library/Frameworks/CoreText.framework/CoreText"));
    CreateCharacterSetForFont = (CFCharacterSetRef (*)(CFStringRef const))MSFindSymbol(ref, "__Z25CreateCharacterSetForFontPK10__CFString");
    XTCopyUncompressedBitmapRepresentation = (CFDataRef (*)(const UInt8 *, CFIndex))MSFindSymbol(ref, "__Z38XTCopyUncompressedBitmapRepresentationPKhm");
    if (XTCopyUncompressedBitmapRepresentation == NULL || CreateCharacterSetForFont == NULL)
        HBLogError(@"[CoreTextHack: CharacterSet] Fatal: couldn't find necessarry symbol(s)");
    else {
        %init(CharacterSet);
    }
    if (IS_IOS_BETWEEN_EEX(iOS_11_0, iOS_12_1)) {
        IsDefaultEmojiPresentation = (void (*)(void *))MSFindSymbol(ref, "__ZZL26IsDefaultEmojiPresentationjEN4$_138__invokeEPv");
        if (IsDefaultEmojiPresentation == NULL)
            IsDefaultEmojiPresentation = (void (*)(void *))MSFindSymbol(ref, "__ZZL26IsDefaultEmojiPresentationjEN4$_128__invokeEPv");
        DefaultEmojiPresentationSet = (CFMutableCharacterSetRef (*))MSFindSymbol(ref, "__ZZL26IsDefaultEmojiPresentationjE28sDefaultEmojiPresentationSet");
        if (IsDefaultEmojiPresentation == NULL || DefaultEmojiPresentationSet == NULL)
            HBLogError(@"[CoreTextHack: EmojiPresentation] Fatal: couldn't find necessarry symbol(s)");
        else {
            %init(EmojiPresentation);
        }
    }
}
