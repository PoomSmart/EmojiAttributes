#if !__arm64e__

#import "../PS.h"
#import "WebCoreSupport/CoreGraphicsSPI.h"
#import <CoreText/CoreText.h>
#import <substrate.h>

%config(generator=MobileSubstrate)

short iOSVer = 0;

CGFontRef cgFont = NULL;

BOOL (*CTFontIsAppleColorEmoji)(CTFontRef);
extern "C" bool CGFontGetGlyphAdvancesForStyle(CGFontRef, CGAffineTransform *, CGFontRenderingStyle, const CGGlyph *, size_t, CGSize *);

bool *findIsEmoji(void *arg0) {
#if __LP64__
    if (iOSVer >= 90)
        return (bool *)((uint8_t *)arg0 + 0x2B);
    else if (iOSVer >= 70)
        return (bool *)((uint8_t *)arg0 + 0x8);
    return (bool *)((uint8_t *)arg0 + 0xC);
#else
    if (iOSVer >= 90)
        return (bool *)((uint8_t *)arg0 + 0x1F);
    else if (iOSVer >= 61)
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

CGFontRenderingStyle style = kCGFontRenderingStyleAntialiasing | kCGFontRenderingStyleSubpixelPositioning | kCGFontRenderingStyleSubpixelQuantization | kCGFontAntialiasingStyleUnfiltered;

float (*platformWidthForGlyph)(void *, CGGlyph);
%hookf(float, platformWidthForGlyph, void *arg0, CGGlyph code) {
    CTFontRef font = iOSVer >= 70 ? FontPlatformData_ctFont((void *)((uint8_t *)arg0 + 0x30)) : FontPlatformData_ctFont((void *)((uint8_t *)arg0 + 0x28));
    BOOL isEmojiFont = CTFontIsAppleColorEmoji && CTFontIsAppleColorEmoji(font);
    if (!isEmojiFont) {
        CFStringRef fontName = CTFontCopyPostScriptName(font);
        isEmojiFont = CFStringEqual(fontName, CFSTR("AppleColorEmoji"));
        CFRelease(fontName);
    }
    if (isEmojiFont) {
        CGFloat pointSize = iOSVer >= 70 ? *(CGFloat *)((uint8_t *)arg0 + 0x38) : *(CGFloat *)((uint8_t *)arg0 + 0x34);
        CGSize advance = CGSizeMake(0, 0);
        CGAffineTransform m = CGAffineTransformMakeScale(pointSize, pointSize);
        if (cgFont == NULL) {
            cgFont = CTFontCopyGraphicsFont(font, NULL);
            CFRetain(cgFont);
        }
        if (!CGFontGetGlyphAdvancesForStyle(cgFont, &m, style, &code, 1, &advance))
            advance.width = 0;
        return advance.width + 4.0;
    }
    return %orig;
}

%end

%ctor {
    if (IS_IOS_BETWEEN_EEX(iOS_6_0, iOS_10_0)) {
        if (isiOS9Up)
            iOSVer = 90;
        else if (isiOS7Up)
            iOSVer = 70;
        else if (isiOS61Up)
            iOSVer = 61;
        else
            iOSVer = 60;
        MSImageRef wcref = MSGetImageByName(realPath2(@"/System/Library/PrivateFrameworks/WebCore.framework/WebCore"));
#if !__LP64__
        MSImageRef ctref = MSGetImageByName(realPath2(@"/System/Library/Frameworks/CoreText.framework/CoreText"));
        CTFontIsAppleColorEmoji = (BOOL (*)(CTFontRef))MSFindSymbol(ctref, "_CTFontIsAppleColorEmoji");
        platformWidthForGlyph = (float (*)(void *, CGGlyph))MSFindSymbol(wcref, "__ZNK7WebCore4Font21platformWidthForGlyphEt");
        if (platformWidthForGlyph == NULL)
            platformWidthForGlyph = (float (*)(void *, CGGlyph))MSFindSymbol(wcref, "__ZNK7WebCore14SimpleFontData21platformWidthForGlyphEt");
        platformInit = (void (*)(void *))MSFindSymbol(wcref, "__ZN7WebCore14SimpleFontData12platformInitEv");
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