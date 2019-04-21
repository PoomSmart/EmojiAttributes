#import "../PS.h"
#import "WebCoreSupport/CoreGraphicsSPI.h"
#import <CoreText/CoreText.h>
#import <substrate.h>

%config(generator=MobileSubstrate)

double iOSVer = 0;

BOOL (*CTFontIsAppleColorEmoji)(CTFontRef);
extern "C" bool CGFontGetGlyphAdvancesForStyle(CGFontRef, CGAffineTransform *, CGFontRenderingStyle, const CGGlyph *, size_t, CGSize *);

bool *findIsEmoji(void *arg0) {
#if __LP64__
    if (iOSVer >= 9.0)
        return (bool *)((uint8_t *)arg0 + 0x2B);
    else if (iOSVer >= 7.0)
        return (bool *)((uint8_t *)arg0 + 0x8);
    return (bool *)((uint8_t *)arg0 + 0xC);
#else
    if (iOSVer >= 9.0)
        return (bool *)((uint8_t *)arg0 + 0x1F);
    else if (iOSVer >= 6.1)
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

float (*platformWidthForGlyph)(void *, CGGlyph);
%hookf(float, platformWidthForGlyph, void *arg0, CGGlyph code) {
    CTFontRef font = iOSVer >= 7.0 ? FontPlatformData_ctFont((void *)((uint8_t *)arg0 + 0x30)) : FontPlatformData_ctFont((void *)((uint8_t *)arg0 + 0x28));
    if (((CTFontIsAppleColorEmoji && CTFontIsAppleColorEmoji(font)) || (CFEqual(CFBridgingRelease(CTFontCopyPostScriptName(font)), CFSTR("AppleColorEmoji"))))) {
        CGFontRenderingStyle style = kCGFontRenderingStyleAntialiasing | kCGFontRenderingStyleSubpixelPositioning | kCGFontRenderingStyleSubpixelQuantization | kCGFontAntialiasingStyleUnfiltered;
        CGFloat pointSize = iOSVer >= 6.1 ? *(CGFloat *)((uint8_t *)arg0 + 0x38) : *(CGFloat *)((uint8_t *)arg0 + 0x34); // 6.1.6 vs lower
        if (pointSize == 0 && iOSVer != 6.0)
            pointSize = *(CGFloat *)((uint8_t *)arg0 + 0x34); // <= 6.1.5
        if (iOSVer == 6.0)
            pointSize = *(CGFloat *)((uint8_t *)arg0 + 0xE);
        CGSize advance = CGSizeMake(0, 0);
        CGAffineTransform m = CGAffineTransformMakeScale(pointSize, pointSize);
        CGFontRef cgFont = CTFontCopyGraphicsFont(font, NULL);
        if (!CGFontGetGlyphAdvancesForStyle(cgFont, &m, style, &code, 1, &advance))
            advance.width = 0;
        CFRelease(cgFont);
        return advance.width + 4.0;
    }
    return %orig;
}

%end

%ctor {
    if (IS_IOS_BETWEEN_EEX(iOS_6_0, iOS_10_0)) {
        if (isiOS9Up)
            iOSVer = 9.0;
        else if (isiOS7Up)
            iOSVer = 7.0;
        else if (isiOS61Up)
            iOSVer = 6.1;
        else
            iOSVer = 6.0;
        MSImageRef ctref = MSGetImageByName(realPath2(@"/System/Library/Frameworks/CoreText.framework/CoreText"));
        MSImageRef wcref = MSGetImageByName(realPath2(@"/System/Library/PrivateFrameworks/WebCore.framework/WebCore"));
        CTFontIsAppleColorEmoji = (BOOL (*)(CTFontRef))MSFindSymbol(ctref, "_CTFontIsAppleColorEmoji");
        FontPlatformData_ctFont = (CTFontRef (*)(void *))MSFindSymbol(wcref, "__ZNK7WebCore16FontPlatformData6ctFontEv");
        platformWidthForGlyph = (float (*)(void *, CGGlyph))MSFindSymbol(wcref, "__ZNK7WebCore4Font21platformWidthForGlyphEt");
        if (platformWidthForGlyph == NULL)
            platformWidthForGlyph = (float (*)(void *, CGGlyph))MSFindSymbol(wcref, "__ZNK7WebCore14SimpleFontData21platformWidthForGlyphEt");
        platformInit = (void (*)(void *))MSFindSymbol(wcref, "__ZN7WebCore14SimpleFontData12platformInitEv");
        HBLogDebug(@"Found FontPlatformData_ctFont: %d", FontPlatformData_ctFont != NULL);
        HBLogDebug(@"Found platformWidthForGlyph: %d", platformWidthForGlyph != NULL);
        HBLogDebug(@"Found platformInit: %d", platformInit != NULL);;
        %init;
        if (iOSVer < 7.0) {
            %init(iOS6);
            if (iOSVer == 6.0) {
                %init(iOS60);
            }
        }
    }
}
