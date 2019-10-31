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

enum {
    _kCFRuntimeNotATypeID = 0
};

static CFTypeID __kCFStringTypeID = _kCFRuntimeNotATypeID;

enum {
    __kCFFreeContentsWhenDoneMask = 0x020,
    __kCFFreeContentsWhenDone = 0x020,
    __kCFContentsMask = 0x060,
    __kCFHasInlineContents = 0x000,
    __kCFNotInlineContentsNoFree = 0x040,     // Don't free
    __kCFNotInlineContentsDefaultFree = 0x020,     // Use allocator's free function
    __kCFNotInlineContentsCustomFree = 0x060,     // Use a specially provided free function
    __kCFHasContentsAllocatorMask = 0x060,
    __kCFHasContentsAllocator = 0x060,        // (For mutable strings) use a specially provided allocator
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
    // !!! Bit 0x02 has been freed up
};

struct __notInlineMutable {
    void *buffer;
    CFIndex length;
    CFIndex capacity;           // Capacity in bytes
    NSUInteger hasGap : 1;     // Currently unused
    NSUInteger isFixedCapacity : 1;
    NSUInteger isExternalMutable : 1;
    NSUInteger capacityProvidedExternally : 1;
#if __LP64__
    unsigned long desiredCapacity : 60;
#else
    unsigned long desiredCapacity : 28;
#endif
    CFAllocatorRef contentsAllocator;           // Optional
};                           // The

typedef struct __CFRuntimeBase {
    uintptr_t _cfisa;
    uint8_t _cfinfo[4];
#if __LP64__
    uint32_t _rc;
#endif
} CFRuntimeBase;

struct __CFString {
    CFRuntimeBase base;
    union {     // In many cases the allocated structs are smaller than these
        struct __inline1 {
            CFIndex length;
        } inline1;                                    // Bytes follow the length
        struct __notInlineImmutable1 {
            void *buffer;                    // Note that the buffer is in the same place for all non-inline variants of CFString
            CFIndex length;
            CFAllocatorRef contentsDeallocator;             // Optional; just the dealloc func is used
        } notInlineImmutable1;              // This is the usual not-inline immutable CFString
        struct __notInlineImmutable2 {
            void *buffer;
            CFAllocatorRef contentsDeallocator;             // Optional; just the dealloc func is used
        } notInlineImmutable2;              // This is the not-inline immutable CFString when length is stored with the contents (first byte)
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

    kCFUniCharCompatibilityDecomposableCharacterSet = 100,     // internal character sets begins here
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

void (*CFCharacterSetCompact)(CFMutableCharacterSetRef theSet);

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

static const CFCharacterSetInlineBuffer *__CFStringGetGenderModifierBaseCharacterSet(void) {
    static CFCharacterSetInlineBuffer buffer;
    static dispatch_once_t initOnce;
    dispatch_once(&initOnce, ^{
        CFMutableCharacterSetRef cset = CFCharacterSetCreateMutable(NULL);
        for (int i = 0; i < genderCodepointsCount; ++i) {
            CFCharacterSetAddCharactersInRange(cset, CFRangeMake(genderCodepoints[i], 1));
        }
        if (CFCharacterSetCompact)
            CFCharacterSetCompact(cset);
        CFCharacterSetInitInlineBuffer(cset, &buffer);
    });
    return (const CFCharacterSetInlineBuffer *)&buffer;
}

static const CFCharacterSetInlineBuffer *__CFStringGetProfessionModifierBaseCharacterSet(void) {
    static CFCharacterSetInlineBuffer buffer;
    static dispatch_once_t initOnce;
    dispatch_once(&initOnce, ^{
        CFMutableCharacterSetRef cset = CFCharacterSetCreateMutable(NULL);
        for (int i = 0; i < professionCodepointsCount; ++i) {
            CFCharacterSetAddCharactersInRange(cset, CFRangeMake(professionCodepoints[i], 1));
        }
        if (CFCharacterSetCompact)
            CFCharacterSetCompact(cset);
        CFCharacterSetInitInlineBuffer(cset, &buffer);
    });
    return (const CFCharacterSetInlineBuffer *)&buffer;
}

static const CFCharacterSetInlineBuffer *__CFStringGetFitzpatrickModifierBaseCharacterSet(void) {
    static CFCharacterSetInlineBuffer buffer;
    static dispatch_once_t initOnce;
    dispatch_once(&initOnce, ^{
        CFMutableCharacterSetRef cset = CFCharacterSetCreateMutable(NULL);
        for (int i = 0; i < skinToneCodepointsCount; ++i) {
            CFCharacterSetAddCharactersInRange(cset, CFRangeMake(skinToneCodepoints[i], 1));
        }
        if (CFCharacterSetCompact)
            CFCharacterSetCompact(cset);
        CFCharacterSetInitInlineBuffer(cset, &buffer);
    });
    return (const CFCharacterSetInlineBuffer *)&buffer;
}

CF_INLINE bool CFUniCharIsMemberOfBitmap(UTF16Char theChar, const uint8_t *bitmap) {
    return (bitmap && (bitmap[(theChar) >> kCFUniCharBitShiftForByte] & (((uint32_t)1) << (theChar & kCFUniCharBitShiftForMask))) ? true : false);
}

CF_INLINE bool CFCharacterSetInlineBufferIsLongCharacterMember(const CFCharacterSetInlineBuffer *buffer, UTF32Char character) {
    bool isInverted = ((0 == (buffer->flags & kCFCharacterSetIsInverted)) ? false : true);

    if ((character >= buffer->rangeStart) && (character < buffer->rangeLimit)) {
        if ((character > 0xFFFF) || (0 != (buffer->flags & kCFCharacterSetNoBitmapAvailable)))
            return (CFCharacterSetIsLongCharacterMember(buffer->cset, character) != 0);
        if (NULL == buffer->bitmap) {
            if (0 == (buffer->flags & kCFCharacterSetIsCompactBitmap))
                isInverted = !isInverted;
        } else if (0 == (buffer->flags & kCFCharacterSetIsCompactBitmap)) {
            if (buffer->bitmap[character >> 3] & (1UL << (character & 7)))
                isInverted = !isInverted;
        } else {
            uint8_t value = buffer->bitmap[character >> 8];

            if (value == 0xFF) {
                isInverted = !isInverted;
            } else if (value > 0) {
                const uint8_t *segment = buffer->bitmap + (256 + (32 * (value - 1)));
                character &= 0xFF;
                if (segment[character >> 3] & (1UL << (character % 8)))
                    isInverted = !isInverted;
            }
        }
    }
    return isInverted;
}

inline Boolean __CFStrIsEightBit(CFStringRef str) {
    return (str->base._cfinfo[CF_INFO_BITS] & __kCFIsUnicodeMask) != __kCFIsUnicode;
}

inline bool CFUniCharIsSurrogateHighCharacter(UniChar character) {
    return ((character >= 0xD800UL) && (character <= 0xDBFFUL) ? true : false);
}

inline bool CFUniCharIsSurrogateLowCharacter(UniChar character) {
    return ((character >= 0xDC00UL) && (character <= 0xDFFFUL) ? true : false);
}

inline UTF32Char CFUniCharGetLongCharacterForSurrogatePair(UniChar surrogateHigh, UniChar surrogateLow) {
    return ((surrogateHigh - 0xD800UL) << 10) + (surrogateLow - 0xDC00UL) + 0x0010000UL;
}

static inline bool __CFStringIsGenderModifier(UTF32Char character) {
    return ((character == 0x2640) || (character == 0x2642));
}

static inline bool __CFStringIsBaseForGenderModifier(UTF32Char character) {
    if (((character >= 0x2600) && (character < 0x3000)) || ((character >= 0x1F300) && (character < 0x1FA00))) { // Misc symbols, dingbats, & emoticons
        return CFCharacterSetInlineBufferIsLongCharacterMember(__CFStringGetGenderModifierBaseCharacterSet(), character);
    }
    return false;
}

static inline bool __CFStringIsGenderModifierBaseCluster(CFStringInlineBuffer *buffer, CFRange range) {
    UTF16Char character = CFStringGetCharacterFromInlineBuffer(buffer, range.location);
    UTF32Char baseCharacter = character;
    if (range.length > 1) {
        if (CFUniCharIsSurrogateHighCharacter(character)) {
            UTF16Char otherCharacter = CFStringGetCharacterFromInlineBuffer(buffer, range.location + 1);
            if (CFUniCharIsSurrogateLowCharacter(otherCharacter)) {
                baseCharacter = CFUniCharGetLongCharacterForSurrogatePair(character, otherCharacter);
            }
        }
    }
    return __CFStringIsBaseForGenderModifier(baseCharacter);
}

static inline bool __CFStringIsGenderModifierCluster(CFStringInlineBuffer *buffer, CFRange range) {
    if ((range.length < 1) || (range.length > 2))
        return false;
    UTF16Char character = CFStringGetCharacterFromInlineBuffer(buffer, range.location);
    return (__CFStringIsGenderModifier(character) && ((range.length == 1) || (0xFE0F == CFStringGetCharacterFromInlineBuffer(buffer, range.location + 1)))); // Either modifier is alone or is followed by FEOF
}

static inline bool __CFStringIsBaseForManOrWomanCluster(UTF16Char character) {
    return ((character == 0xDC68) || (character == 0xDC69) || (character == 0xDDD1)); // Low surrogate chars representing MAN (U+1F468) and WOMAN (U+1F469) respectively
}

static inline bool __CFStringIsProfessionBaseCluster(CFStringInlineBuffer *buffer, CFRange range) {
    if (range.length > 1) {
        UTF16Char character = CFStringGetCharacterFromInlineBuffer(buffer, range.location);
        if (CFUniCharIsSurrogateHighCharacter(character)) {
            UTF16Char otherCharacter = CFStringGetCharacterFromInlineBuffer(buffer, range.location + 1);
            if (CFUniCharIsSurrogateLowCharacter(otherCharacter)) {
                return __CFStringIsBaseForManOrWomanCluster(otherCharacter);
            }
        }
    }
    return false;
}

static inline bool __CFStringIsBaseForProfessionModifier(UTF32Char character) {
    if (((character >= 0x2600) && (character < 0x3000)) || ((character >= 0x1F300) && (character < 0x1FA00))) { // Misc symbols, dingbats, & emoticons
        return CFCharacterSetInlineBufferIsLongCharacterMember(__CFStringGetProfessionModifierBaseCharacterSet(), character);
    }
    return false;
}

static inline bool __CFStringIsProfessionModifierCluster(CFStringInlineBuffer *buffer, CFRange range) {
    UTF16Char character = CFStringGetCharacterFromInlineBuffer(buffer, range.location);
    UTF32Char baseCharacter = character;
    if (range.length > 1) {
        if (CFUniCharIsSurrogateHighCharacter(character)) {
            UTF16Char otherCharacter = CFStringGetCharacterFromInlineBuffer(buffer, range.location + 1);
            if (CFUniCharIsSurrogateLowCharacter(otherCharacter)) {
                baseCharacter = CFUniCharGetLongCharacterForSurrogatePair(character, otherCharacter);
            }
        }
    }
    return __CFStringIsBaseForProfessionModifier(baseCharacter);
}

static inline bool __CFStringIsFamilySequenceBaseCharacterHigh(UTF16Char character) {
    return ((character == 0xD83D) || (character == 0xD83E)) ? true : false;
}

static inline bool __CFStringIsFamilySequenceBaseCharacterLow(UTF16Char character) {
    return (((character >= 0xDC66) && (character <= 0xDC69)) || (character == 0xDC8B) || (character == 0xDC41) || (character == 0xDDD1) || (character == 0xDDE8)) ? true : false;
}

static inline bool __CFStringIsFamilySequenceCluster(CFStringInlineBuffer *buffer, CFRange range) {
    UTF16Char character = CFStringGetCharacterFromInlineBuffer(buffer, range.location);
    if (character == 0x2764 || character == 0xFE0F || character == 0x2640 || character == 0x2642 || character == 0xD83E || character == 0xDD1D) // HEART or variant selector or gender selector
        return true;
    if (range.length > 1) {
        if (__CFStringIsFamilySequenceBaseCharacterHigh(character) && __CFStringIsFamilySequenceBaseCharacterLow(CFStringGetCharacterFromInlineBuffer(buffer, range.location + 1)))
            return true;
    }
    return false;
}

#define RI_SURROGATE_HI (0xD83C)
static inline bool __CFStringIsRegionalIndicatorSurrogateLow(UTF16Char character) {
    return (character >= 0xDDE6) && (character <= 0xDDFF) ? true : false;
}

static inline bool __CFStringIsRegionalIndicatorAtIndex(CFStringInlineBuffer *buffer, CFIndex index) {
    return ((CFStringGetCharacterFromInlineBuffer(buffer, index) == RI_SURROGATE_HI) && __CFStringIsRegionalIndicatorSurrogateLow(CFStringGetCharacterFromInlineBuffer(buffer, index + 1))) ? true : false;
}

static inline bool __CFStringIsWavingWhiteFlagCluster(CFStringInlineBuffer *buffer, CFRange range) {
    return ((CFStringGetCharacterFromInlineBuffer(buffer, range.location) == RI_SURROGATE_HI) && (CFStringGetCharacterFromInlineBuffer(buffer, range.location + 1) == 0xDFF3));
}

static inline bool __CFStringIsRainbowCluster(CFStringInlineBuffer *buffer, CFRange range) {
    return ((CFStringGetCharacterFromInlineBuffer(buffer, range.location) == RI_SURROGATE_HI) && (CFStringGetCharacterFromInlineBuffer(buffer, range.location + 1) == 0xDF08));
}

static inline bool __CFStringIsFitzpatrickModifiers(UTF32Char character) {
    return ((character >= 0x1F3FB) && (character <= 0x1F3FF) ? true : false);
}

static inline bool __CFStringIsBaseForFitzpatrickModifiers(UTF32Char character) {
    if (((character >= 0x2600) && (character < 0x3000)) || ((character >= 0x1F300) && (character < 0x1FA00)))
        return (CFCharacterSetInlineBufferIsLongCharacterMember(__CFStringGetFitzpatrickModifierBaseCharacterSet(), character) ? true : false);
    return false;
}
static inline bool __CFStringIsTagSequence(UTF32Char character) { return ((character >= 0xE0020) && (character <= 0xE007F) ? true : false); }

#define MAX_CASE_MAPPING_BUF (8)
#define ZERO_WIDTH_JOINER (0x200D)
#define COMBINING_GRAPHEME_JOINER (0x034F)
// Hangul ranges
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

CF_INLINE uint8_t CFUniCharGetCombiningPropertyForCharacter(UTF16Char character, const uint8_t *bitmap) {
    if (bitmap) {
        uint8_t value = bitmap[(character >> 8)];

        if (value) {
            bitmap = bitmap + 256 + ((value - 1) * 256);
            return bitmap[character % 256];
        }
    }
    return 0;
}

CF_INLINE bool _CFStringIsVirama(UTF32Char character, const uint8_t *combClassBMP) {
    return ((character == COMBINING_GRAPHEME_JOINER) || (CFUniCharGetCombiningPropertyForCharacter(character, (const uint8_t *)((character < 0x10000) ? combClassBMP : CFUniCharGetUnicodePropertyDataForPlane(kCFUniCharCombiningProperty, (character >> 16)))) == 9) ? true : false);
}

CF_INLINE bool _CFStringIsHangulLVT(UTF32Char character) {
    return (((character - HANGUL_SYLLABLE_START) % HANGUL_JONGSEONG_COUNT) ? true : false);
}
