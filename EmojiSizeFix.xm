#import "../PS.h"
#import "WebCoreSupport/CoreGraphicsSPI.h"
#import <CoreText/CoreText.h>

BOOL (*CTFontIsAppleColorEmoji)(CTFontRef);
extern "C" bool CGFontGetGlyphAdvancesForStyle(CGFontRef, CGAffineTransform *, CGFontRenderingStyle, const CGGlyph *, size_t, CGSize *);

bool *findIsEmoji(void *arg0) {
#if __LP64__
    if (isiOS9Up)
        return (bool *)((uint8_t *)arg0 + 0x2B);
    else if (isiOS7Up)
        return (bool *)((uint8_t *)arg0 + 0x8);
    return (bool *)((uint8_t *)arg0 + 0xC);
#else
    if (isiOS9Up)
        return (bool *)((uint8_t *)arg0 + 0x1F);
    else if (isiOS7Up)
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

%group iOS6

float (*platformWidthForGlyph)(void *, CGGlyph);
%hookf(float, platformWidthForGlyph, void *arg0, CGGlyph code) {
    CTFontRef font = isiOS7Up ? FontPlatformData_ctFont((void *)((uint8_t *)arg0 + 0x30)) : FontPlatformData_ctFont((void *)((uint8_t *)arg0 + 0x28));
    if (((CTFontIsAppleColorEmoji && CTFontIsAppleColorEmoji(font)) || (CFEqual(CFBridgingRelease(CTFontCopyPostScriptName(font)), CFSTR("AppleColorEmoji"))))) {
        CGFontRenderingStyle style = kCGFontRenderingStyleAntialiasing | kCGFontRenderingStyleSubpixelPositioning | kCGFontRenderingStyleSubpixelQuantization | kCGFontAntialiasingStyleUnfiltered;
        CGFloat pointSize = *(CGFloat *)((uint8_t *)arg0 + 0x38);
        CGSize advance = CGSizeZero;
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
    if (!isiOS10Up && isiOS6Up) {
        MSImageRef ctref = MSGetImageByName(realPath2(@"/System/Library/Frameworks/CoreText.framework/CoreText"));
        MSImageRef wcref = MSGetImageByName(realPath2(@"/System/Library/PrivateFrameworks/WebCore.framework/WebCore"));
        CTFontIsAppleColorEmoji = (BOOL (*)(CTFontRef))MSFindSymbol(ctref, "_CTFontIsAppleColorEmoji");
        FontPlatformData_ctFont = (CTFontRef (*)(void *))MSFindSymbol(wcref, "__ZNK7WebCore16FontPlatformData6ctFontEv");
        platformWidthForGlyph = (float (*)(void *, CGGlyph))MSFindSymbol(wcref, "__ZNK7WebCore4Font21platformWidthForGlyphEt");
        if (platformWidthForGlyph == NULL)
            platformWidthForGlyph = (float (*)(void *, CGGlyph))MSFindSymbol(wcref, "__ZNK7WebCore14SimpleFontData21platformWidthForGlyphEt");
        HBLogDebug(@"Found FontPlatformData_ctFont: %d", FontPlatformData_ctFont != NULL);
        HBLogDebug(@"Found platformWidthForGlyph: %d", platformWidthForGlyph != NULL);
        %init;
        if (!isiOS7Up) {
            %init(iOS6);
        }
    }
}
