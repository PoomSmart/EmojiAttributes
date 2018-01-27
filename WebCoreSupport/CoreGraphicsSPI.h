#import <CoreGraphics/CoreGraphics.h>

enum {
    kCGFontRenderingStyleAntialiasing = 1 << 0,
    kCGFontRenderingStyleSmoothing = 1 << 1,
    kCGFontRenderingStyleSubpixelPositioning = 1 << 2,
    kCGFontRenderingStyleSubpixelQuantization = 1 << 3,
    kCGFontRenderingStylePlatformNative = 1 << 9,
    kCGFontRenderingStyleMask = 0x20F,
};
typedef uint32_t CGFontRenderingStyle;

enum {
    kCGFontAntialiasingStyleUnfiltered = 0 << 7,
    kCGFontAntialiasingStyleFilterLight = 1 << 7,
};
typedef uint32_t CGFontAntialiasingStyle;
