#if !__arm64e__

#import "../PS.h"
#import "WebCoreSupport/CoreGraphicsSPI.h"
#import <CoreText/CoreText.h>
#import <HBLog.h>
#import <substrate.h>

%config(generator=MobileSubstrate)

short iOSVer = 0;

CGFontRef cgFont = NULL;

BOOL (*CTFontIsAppleColorEmoji)(CTFontRef);

bool *findIsEmoji(void *arg0) {
#if __LP64__
    if (iOSVer >= 90)
        return (bool *)((uint8_t *)arg0 + 0x2B);
    if (iOSVer >= 70)
        return (bool *)((uint8_t *)arg0 + 0x8);
    return (bool *)((uint8_t *)arg0 + 0xC);
#else
    if (iOSVer >= 90)
        return (bool *)((uint8_t *)arg0 + 0x1F);
    if (iOSVer >= 61)
        return (bool *)((uint8_t *)arg0 + 0x8);
    return (bool *)((uint8_t *)arg0 + 0xC);
#endif
}

CTFontRef (*FontPlatformData_ctFont)(void *);
%hookf(CTFontRef, FontPlatformData_ctFont, void *arg0) {
    bool *isEmoji = findIsEmoji(arg0);
    bool forEmoji = *isEmoji;
    *isEmoji = NO;
    CTFontRef font = %orig;
    *isEmoji = forEmoji;
    return font;
}

%group iOS60

void (*platformInit)(void *);
%hookf(void, platformInit, void *arg0) {
    bool *isEmoji = (bool *)((uint8_t *)arg0 + 0x34);
    bool forEmoji = *isEmoji;
    *isEmoji = NO;
    %orig;
    *isEmoji = forEmoji;
}

%end

%group iOS6

int (*CTFontGetWebKitEmojiRenderMode)(void);
%hookf(int, CTFontGetWebKitEmojiRenderMode) {
    return 0;
}

CGFontRenderingStyle style = kCGFontRenderingStyleAntialiasing | kCGFontRenderingStyleSubpixelPositioning | kCGFontRenderingStyleSubpixelQuantization | kCGFontAntialiasingStyleUnfiltered;

float (*platformWidthForGlyph)(void *, CGGlyph);
%hookf(float, platformWidthForGlyph, void *arg0, CGGlyph code) {
    if (code == 0xFE0F)
        return 0.0;
    CTFontRef font = iOSVer >= 70 ? FontPlatformData_ctFont((void *)((uint8_t *)arg0 + 0x30)) : FontPlatformData_ctFont((void *)((uint8_t *)arg0 + 0x28));
    BOOL isEmojiFont = CTFontIsAppleColorEmoji && CTFontIsAppleColorEmoji(font);
    if (!isEmojiFont) {
        CFStringRef fontName = CTFontCopyPostScriptName(font);
        isEmojiFont = CFStringEqual(fontName, CFSTR("AppleColorEmoji"));
        CFRelease(fontName);
    }
    if (isEmojiFont) {
        CGSize advance = CGSizeMake(0, 0);
        CTFontGetAdvancesForGlyphs(font, kCTFontOrientationHorizontal, &code, &advance, 1);
        return advance.width + 4.0;
    }
    return %orig;
}

%end

%ctor {
    if (IS_IOS_BETWEEN_EEX(iOS_6_0, iOS_10_0)) {
        if (IS_IOS_OR_NEWER(iOS_9_0))
            iOSVer = 90;
        else if (IS_IOS_OR_NEWER(iOS_7_0))
            iOSVer = 70;
        else if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_6_1)
            iOSVer = 61;
        else
            iOSVer = 60;
        MSImageRef wcref = MSGetImageByName(realPath2(@"/System/Library/PrivateFrameworks/WebCore.framework/WebCore"));
#if !__LP64__
        MSImageRef ctref = MSGetImageByName(realPath2(@"/System/Library/Frameworks/CoreText.framework/CoreText"));
        CTFontIsAppleColorEmoji = (BOOL (*)(CTFontRef))MSFindSymbol(ctref, "_CTFontIsAppleColorEmoji");
        CTFontGetWebKitEmojiRenderMode = (int (*)(void))MSFindSymbol(ctref, "_CTFontGetWebKitEmojiRenderMode");
        platformWidthForGlyph = (float (*)(void *, CGGlyph))MSFindSymbol(wcref, "__ZNK7WebCore4Font21platformWidthForGlyphEt");
        if (platformWidthForGlyph == NULL)
            platformWidthForGlyph = (float (*)(void *, CGGlyph))MSFindSymbol(wcref, "__ZNK7WebCore14SimpleFontData21platformWidthForGlyphEt");
        platformInit = (void (*)(void *))MSFindSymbol(wcref, "__ZN7WebCore14SimpleFontData12platformInitEv");
        HBLogDebug(@"Found CTFontGetWebKitEmojiRenderMode: %d", CTFontGetWebKitEmojiRenderMode != NULL);
        HBLogDebug(@"Found platformWidthForGlyph: %d", platformWidthForGlyph != NULL);
        HBLogDebug(@"Found platformInit: %d", platformInit != NULL);
        if (iOSVer < 70) {
            %init(iOS6);
            if (iOSVer == 60) {
                %init(iOS60);
            }
        }
#endif
        FontPlatformData_ctFont = (CTFontRef (*)(void *))MSFindSymbol(wcref, "__ZNK7WebCore16FontPlatformData6ctFontEv");
        HBLogDebug(@"Found FontPlatformData_ctFont: %d", FontPlatformData_ctFont != NULL);
        %init;
    }
}

#endif

#if !__LP64__

%dtor {
    if (cgFont)
        CFRelease(cgFont);
}

#endif