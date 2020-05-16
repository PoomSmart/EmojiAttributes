#import <CoreFoundation/CoreFoundation.h>
#import "Codepoints.h"

#if defined(__BIG_ENDIAN__)
#define __CF_BIG_ENDIAN__ 1
#define __CF_LITTLE_ENDIAN__ 0
#endif

#if defined(__LITTLE_ENDIAN__)
#define __CF_LITTLE_ENDIAN__ 1
#define __CF_BIG_ENDIAN__ 0
#endif

#define CF_INFO_BITS (!!(__CF_BIG_ENDIAN__) * 3)
#define CF_IS_OBJC(typeID, obj) (1)

#define CF_IS_SWIFT(type, obj) (0)

#define WHITE_SPACE_CHARACTER (0x0020)
#define ZERO_WIDTH_JOINER (0x200D)

enum {
    _kCFRuntimeNotATypeID = 0
};

static CFTypeID __kCFStringTypeID = _kCFRuntimeNotATypeID;

enum {
    __kCFFreeContentsWhenDoneMask = 0x020,
    __kCFFreeContentsWhenDone = 0x020,
    __kCFContentsMask = 0x060,
    __kCFHasInlineContents = 0x000,
    __kCFNotInlineContentsNoFree = 0x040,
    __kCFNotInlineContentsDefaultFree = 0x020,
    __kCFNotInlineContentsCustomFree = 0x060,
    __kCFHasContentsAllocatorMask = 0x060,
    __kCFHasContentsAllocator = 0x060,
    __kCFHasContentsDeallocatorMask = 0x060,
    __kCFHasContentsDeallocator = 0x060,
    __kCFIsMutableMask = 0x01,
    __kCFIsMutable = 0x01,
    __kCFIsUnicodeMask = 0x10,
    __kCFIsUnicode = 0x10,
    __kCFHasNullByteMask = 0x08,
    __kCFHasNullByte = 0x08,
    __kCFHasLengthByteMask = 0x04,
    __kCFHasLengthByte = 0x04,
};

struct __notInlineMutable {
    void *buffer;
    CFIndex length;
    CFIndex capacity;
    NSUInteger hasGap : 1;
    NSUInteger isFixedCapacity : 1;
    NSUInteger isExternalMutable : 1;
    NSUInteger capacityProvidedExternally : 1;
#if __LP64__
    unsigned long desiredCapacity : 60;
#else
    unsigned long desiredCapacity : 28;
#endif
    CFAllocatorRef contentsAllocator;
};

typedef struct __CFRuntimeBase {
    uintptr_t _cfisa;
    uint8_t _cfinfo[4];
#if __LP64__
    uint32_t _rc;
#endif
} CFRuntimeBase;

struct __CFString {
    CFRuntimeBase base;
    union {
        struct __inline1 {
            CFIndex length;
        } inline1;
        struct __notInlineImmutable1 {
            void *buffer;
            CFIndex length;
            CFAllocatorRef contentsDeallocator;
        } notInlineImmutable1;
        struct __notInlineImmutable2 {
            void *buffer;
            CFAllocatorRef contentsDeallocator;
        } notInlineImmutable2;
        struct __notInlineMutable notInlineMutable;
    } variants;
};

enum {
    kCFUniCharControlCharacterSet = 1,
    kCFUniCharWhitespaceCharacterSet,
    kCFUniCharWhitespaceAndNewlineCharacterSet,
    kCFUniCharDecimalDigitCharacterSet,
    kCFUniCharLetterCharacterSet,
    kCFUniCharLowercaseLetterCharacterSet,
    kCFUniCharUppercaseLetterCharacterSet,
    kCFUniCharNonBaseCharacterSet,
    kCFUniCharCanonicalDecomposableCharacterSet,
    kCFUniCharDecomposableCharacterSet = kCFUniCharCanonicalDecomposableCharacterSet,
    kCFUniCharAlphaNumericCharacterSet,
    kCFUniCharPunctuationCharacterSet,
    kCFUniCharIllegalCharacterSet,
    kCFUniCharTitlecaseLetterCharacterSet,
    kCFUniCharSymbolAndOperatorCharacterSet,
    kCFUniCharNewlineCharacterSet,

    kCFUniCharCompatibilityDecomposableCharacterSet = 100,
    kCFUniCharHFSPlusDecomposableCharacterSet,
    kCFUniCharStrongRightToLeftCharacterSet,
    kCFUniCharHasNonSelfLowercaseCharacterSet,
    kCFUniCharHasNonSelfUppercaseCharacterSet,
    kCFUniCharHasNonSelfTitlecaseCharacterSet,
    kCFUniCharHasNonSelfCaseFoldingCharacterSet,
    kCFUniCharHasNonSelfMirrorMappingCharacterSet,
    kCFUniCharControlAndFormatterCharacterSet,
    kCFUniCharCaseIgnorableCharacterSet,
    kCFUniCharGraphemeExtendCharacterSet
};

typedef enum {
    kCFStringGraphemeCluster = 1,     /* Unicode Grapheme Cluster (not different from kCFStringComposedCharacterCluster right now) */
    kCFStringComposedCharacterCluster = 2,     /* Compose all non-base (including spacing marks) */
    kCFStringCursorMovementCluster = 3,     /* Cluster suitable for cursor movements */
    kCFStringBackwardDeletionCluster = 4     /* Cluster suitable for backward deletion */
} CFStringCharacterClusterType;

enum {
    kCFUniCharCombiningProperty = 0,
    kCFUniCharBidiProperty
};

enum {
    kCFStringHangulStateL,
    kCFStringHangulStateV,
    kCFStringHangulStateT,
    kCFStringHangulStateLV,
    kCFStringHangulStateLVT,
    kCFStringHangulStateBreak
};

typedef struct {
    CFCharacterSetRef cset;
    uint32_t flags;
    uint32_t rangeStart;
    uint32_t rangeLimit;
    const uint8_t *bitmap;
} CFCharacterSetInlineBuffer;

CF_EXTERN_C_BEGIN
CF_EXPORT void CFCharacterSetInitInlineBuffer(CFCharacterSetRef cset, CFCharacterSetInlineBuffer *buffer);
CF_EXPORT const uint8_t *CFUniCharGetBitmapPtrForPlane(uint32_t charset, uint32_t plane);
CF_EXPORT const void *CFUniCharGetUnicodePropertyDataForPlane(uint32_t propertyType, uint32_t plane);
CF_EXTERN_C_END

enum {
    kCFCharacterSetIsCompactBitmap = (1UL << 0),
    kCFCharacterSetNoBitmapAvailable = (1UL << 1),
    kCFCharacterSetIsInverted = (1UL << 2)
};

#define kCFUniCharBitShiftForByte (3)
#define kCFUniCharBitShiftForMask (7)

#define MAX_CASE_MAPPING_BUF (8)
#define ZERO_WIDTH_JOINER (0x200D)
#define COMBINING_GRAPHEME_JOINER (0x034F)

#define HANGUL_CHOSEONG_START (0x1100)
#define HANGUL_CHOSEONG_END (0x115F)
#define HANGUL_JUNGSEONG_START (0x1160)
#define HANGUL_JUNGSEONG_END (0x11A2)
#define HANGUL_JONGSEONG_START (0x11A8)
#define HANGUL_JONGSEONG_END (0x11F9)

#define HANGUL_SYLLABLE_START (0xAC00)
#define HANGUL_SYLLABLE_END (0xD7AF)

#define HANGUL_JONGSEONG_COUNT (28)

#define MAX_TRANSCODING_LENGTH 4

static uint8_t __CFTranscodingHintLength[] = {
    2, 3, 4, 4, 4, 4, 4, 2, 2, 2, 2, 4, 0, 0, 0, 0
};
